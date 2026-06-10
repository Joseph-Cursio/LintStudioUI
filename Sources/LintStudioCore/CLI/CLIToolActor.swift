//
//  CLIToolActor.swift
//  LintStudioCore
//
//  Tool-agnostic command-line execution service. Locates a developer tool
//  binary, runs it with a timeout, and captures stdout/stderr/exit status.
//  Shared across the LintStudio family of apps (SwiftLint, SwiftFormat, …);
//  each app keeps its own argument building and output parsing on top.
//
//  Error policy follows Realm SwiftLint's exit-code conventions (see
//  `successExitCodes`): a run that *ranks* and emits output is a success even
//  when it reports findings; only a genuine execution failure throws.
//

import Foundation

// MARK: - Result

/// The outcome of a single CLI invocation.
public nonisolated struct CLIToolResult: Sendable {
    /// Raw standard-output bytes.
    public let stdout: Data
    /// Raw standard-error bytes.
    public let stderr: Data
    /// The process termination status (0 = success for most tools).
    public let exitCode: Int32
    /// Whether the run was killed because it exceeded the timeout.
    public let didTimeout: Bool

    public init(stdout: Data, stderr: Data, exitCode: Int32, didTimeout: Bool) {
        self.stdout = stdout
        self.stderr = stderr
        self.exitCode = exitCode
        self.didTimeout = didTimeout
    }

    /// stdout decoded as UTF-8 (empty string if undecodable).
    public var stdoutString: String { String(data: stdout, encoding: .utf8) ?? "" }
    /// stderr decoded as UTF-8 (empty string if undecodable).
    public var stderrString: String { String(data: stderr, encoding: .utf8) ?? "" }
}

// MARK: - Errors

/// Errors surfaced while locating or running a CLI tool.
public enum CLIToolError: LocalizedError, Sendable {
    /// The tool binary could not be found in any search path (or the shell
    /// reported "command not found", exit 127).
    case notFound(tool: String, installMessage: String?)
    /// The tool ran but exited with a status outside its success set.
    case executionFailed(message: String)
    /// The run exceeded its timeout.
    case timedOut(tool: String, seconds: UInt64)

    public var errorDescription: String? {
        switch self {
        case .notFound(let tool, let installMessage):
            return installMessage ?? "\(tool) not found."
        case .executionFailed(let message):
            return message
        case .timedOut(let tool, let seconds):
            return "\(tool) command timed out after \(seconds) seconds."
        }
    }
}

// MARK: - Injection seams

/// Runs the tool with the given arguments, returning `(stdout, stderr, exitCode)`.
/// Injected in tests to return canned fixtures without launching a process.
public typealias CLIToolCommandRunner = @Sendable (_ arguments: [String], _ stdin: Data?) async throws -> (Data, Data, Int32)

/// Checks whether a file exists at a path. Injected in tests.
public typealias CLIToolFileExists = @Sendable (String) async -> Bool

// MARK: - Implementation

/// Executes a developer CLI tool, generalizing the path-detection + run +
/// capture + timeout mechanics previously duplicated in each app's tool actor.
///
/// What stays in each app: the binary name, argument construction, and output
/// parsing. What lives here: finding the binary, launching it (direct, with an
/// optional `/bin/zsh` PATH-resolving fallback for sandboxed apps), enforcing a
/// timeout, and deciding success/failure from the exit code per SwiftLint's
/// convention.
public actor CLIToolActor {
    /// Shell exit code for "command not found".
    private static let commandNotFoundExitCode: Int32 = 127

    private let toolName: String
    private let searchPaths: [String]
    private let installMessage: String?
    private let timeoutSeconds: UInt64
    private let allowShellFallback: Bool
    private let successExitCodes: Set<Int32>
    private let fileExists: CLIToolFileExists
    private let commandRunner: CLIToolCommandRunner?

    private var cachedPath: URL?

    /// Standard Homebrew/system install locations for a given tool name.
    public static func defaultSearchPaths(for tool: String) -> [String] {
        [
            "/opt/homebrew/bin/\(tool)", // Apple Silicon Homebrew (most common)
            "/usr/local/bin/\(tool)",    // Intel Homebrew
            "/usr/bin/\(tool)"           // System installation
        ]
    }

    /// - Parameters:
    ///   - toolName: binary name, e.g. `"swiftlint"`. Used for shell fallback,
    ///     default search paths, and error messages.
    ///   - searchPaths: absolute candidate paths, most-preferred first.
    ///   - installMessage: shown in `.notFound`; each app supplies its own.
    ///   - timeoutSeconds: per-invocation timeout.
    ///   - allowShellFallback: if direct execution can't locate the binary, run
    ///     via `/bin/zsh -c` so the shell's PATH resolves it (needed by some
    ///     sandboxed apps). When false, an unlocatable binary throws `.notFound`.
    ///   - successExitCodes: exit codes treated as a successful run. Defaults to
    ///     SwiftLint's convention — `0` (clean) and `2` (ran, reported serious
    ///     violations). Tools with different conventions (e.g. SwiftFormat's `1`
    ///     in `--lint` mode) pass their own set.
    ///   - fileExists: path-existence check (injectable for tests).
    ///   - commandRunner: full execution override (injectable for tests).
    public init(
        toolName: String,
        searchPaths: [String]? = nil,
        installMessage: String? = nil,
        timeoutSeconds: UInt64 = 300,
        allowShellFallback: Bool = false,
        successExitCodes: Set<Int32> = [0, 2],
        fileExists: CLIToolFileExists? = nil,
        commandRunner: CLIToolCommandRunner? = nil
    ) {
        self.toolName = toolName
        self.searchPaths = searchPaths ?? Self.defaultSearchPaths(for: toolName)
        self.installMessage = installMessage
        self.timeoutSeconds = timeoutSeconds
        self.allowShellFallback = allowShellFallback
        self.successExitCodes = successExitCodes
        self.fileExists = fileExists ?? { FileManager.default.fileExists(atPath: $0) }
        self.commandRunner = commandRunner
    }

    // MARK: Public API

    /// Locates the tool binary, caching the result. Throws `.notFound` if no
    /// candidate path exists.
    public func detectPath() async throws -> URL {
        if let cachedPath, await fileExists(cachedPath.path) {
            return cachedPath
        }
        cachedPath = nil

        for path in searchPaths where await fileExists(path) {
            let url = URL(fileURLWithPath: path)
            cachedPath = url
            return url
        }
        throw CLIToolError.notFound(tool: toolName, installMessage: installMessage)
    }

    /// Runs the tool with `arguments`, optionally writing `stdin`, and returns
    /// the captured streams. Applies the exit-code policy: `.timedOut` on
    /// timeout, `.notFound` on exit 127, `.executionFailed` on any exit code
    /// outside `successExitCodes`; otherwise returns the result.
    @discardableResult
    public func run(arguments: [String], stdin: Data? = nil) async throws -> CLIToolResult {
        let result: CLIToolResult
        if let commandRunner {
            let (stdout, stderr, exitCode) = try await commandRunner(arguments, stdin)
            result = CLIToolResult(stdout: stdout, stderr: stderr, exitCode: exitCode, didTimeout: false)
        } else if let binary = await resolvePath() {
            result = try await runDirect(binary: binary, arguments: arguments, stdin: stdin)
        } else if allowShellFallback {
            result = try await runViaShell(arguments: arguments, stdin: stdin)
        } else {
            throw CLIToolError.notFound(tool: toolName, installMessage: installMessage)
        }

        return try validate(result)
    }

    // MARK: - Exit-code policy

    private func validate(_ result: CLIToolResult) throws -> CLIToolResult {
        if result.didTimeout {
            throw CLIToolError.timedOut(tool: toolName, seconds: timeoutSeconds)
        }
        if result.exitCode == Self.commandNotFoundExitCode {
            throw CLIToolError.notFound(tool: toolName, installMessage: installMessage)
        }
        if !successExitCodes.contains(result.exitCode) {
            let stderr = result.stderrString.trimmingCharacters(in: .whitespacesAndNewlines)
            let detail = stderr.isEmpty ? "exit code \(result.exitCode)" : stderr
            throw CLIToolError.executionFailed(message: "\(toolName) failed: \(detail)")
        }
        return result
    }

    // MARK: - Path resolution

    private func resolvePath() async -> URL? {
        try? await detectPath()
    }

    // MARK: - Direct execution

    private func runDirect(binary: URL, arguments: [String], stdin: Data?) async throws -> CLIToolResult {
        let process = Process()
        process.executableURL = binary
        process.arguments = arguments
        process.environment = Self.buildEnvironment(base: ProcessInfo.processInfo.environment)
        return try await launch(process, stdin: stdin)
    }

    // MARK: - Shell fallback

    private func runViaShell(arguments: [String], stdin: Data?) async throws -> CLIToolResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", Self.buildShellCommand(command: toolName, arguments: arguments)]
        process.environment = Self.buildEnvironment(base: ProcessInfo.processInfo.environment)
        return try await launch(process, stdin: stdin)
    }

    // MARK: - Process launching

    private func launch(_ process: Process, stdin: Data?) async throws -> CLIToolResult {
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        let inputPipe = stdin.map { _ in Pipe() }
        if let inputPipe {
            process.standardInput = inputPipe
        }

        // Bridge the exit to `await` via the termination handler instead of the
        // blocking `process.waitUntilExit()` below. Set before `run()` so the
        // signal is never missed, even for a process that exits immediately.
        let exitSignal = ProcessExitSignal()
        process.terminationHandler = { finished in
            exitSignal.resume(finished.terminationStatus)
        }

        do {
            try process.run()
        } catch {
            throw CLIToolError.executionFailed(
                message: "Failed to launch \(toolName): \(error.localizedDescription)"
            )
        }

        if let inputPipe, let stdin {
            inputPipe.fileHandleForWriting.write(stdin)
            inputPipe.fileHandleForWriting.closeFile()
        }

        // On timeout, kill the process: that closes its pipes, which unblocks
        // the (uncancellable) blocking reads below. Cancelling the timeout task
        // when the process finishes on its own makes `value` report `false`.
        let timeoutNs = timeoutSeconds * 1_000_000_000
        let timeoutTask = Task { () -> Bool in
            do {
                try await Task.sleep(nanoseconds: timeoutNs)
            } catch {
                return false
            }
            await Self.terminate(process)
            return true
        }

        async let stdoutRead = outputPipe.fileHandleForReading.readDataToEndOfFile()
        async let stderrRead = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let stdout = await stdoutRead
        let stderr = await stderrRead
        // Await termination via the handler-backed signal rather than
        // `process.waitUntilExit()`: that blocking call can wedge forever on a
        // cooperative thread even after the pipes reach EOF and the child has
        // been reaped, a hang the timeout below can't rescue (it only unblocks
        // the reads). Reproduces reliably under many rapid back-to-back runs.
        let exitCode = await exitSignal.value

        timeoutTask.cancel()
        let didTimeout = await timeoutTask.value

        return CLIToolResult(
            stdout: stdout,
            stderr: stderr,
            exitCode: didTimeout ? -1 : exitCode,
            didTimeout: didTimeout
        )
    }

    private static func terminate(_ process: Process) async {
        process.terminate()
        try? await Task.sleep(nanoseconds: 100_000_000)
        if process.isRunning {
            kill(process.processIdentifier, SIGKILL)
        }
    }

    // MARK: - Environment & shell helpers

    /// Prepends the Homebrew bin directories to `PATH` so a tool installed via
    /// Homebrew is found even when the inherited environment is minimal.
    public static func buildEnvironment(base: [String: String]) -> [String: String] {
        var environment = base
        if let currentPath = environment["PATH"], !currentPath.contains("/opt/homebrew/bin") {
            environment["PATH"] = "/opt/homebrew/bin:/usr/local/bin:\(currentPath)"
        } else if environment["PATH"] == nil {
            environment["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        }
        return environment
    }

    /// Joins a command and arguments into a single shell-safe string.
    public static func buildShellCommand(command: String, arguments: [String]) -> String {
        ([command] + arguments).map(escapeShellArgument).joined(separator: " ")
    }

    /// Wraps a value in single quotes if it contains shell-significant characters.
    public static func escapeShellArgument(_ value: String) -> String {
        if value.contains(" ") || value.contains("'") || value.contains("\"") {
            let escaped = value.replacingOccurrences(of: "'", with: "'\"'\"'")
            return "'\(escaped)'"
        }
        return value
    }
}

// MARK: - Exit signal

/// A one-shot bridge from `Process.terminationHandler` (a C-style callback) to
/// async `await`. It exists to replace `Process.waitUntilExit()`, whose blocking
/// wait can wedge indefinitely on a Swift-concurrency cooperative thread even
/// after the child has exited and its pipes have reached EOF — a hang that
/// surfaces under many rapid back-to-back invocations and which the run timeout
/// cannot rescue (the timeout only kills the child to unblock the pipe reads).
///
/// Tolerates the resume arriving before or after the `value` access: the
/// terminated status is latched until a waiter parks, and a parked waiter is
/// resumed the instant the status arrives.
private final class ProcessExitSignal: @unchecked Sendable {
    private let lock = NSLock()
    nonisolated(unsafe) private var status: Int32?
    nonisolated(unsafe) private var waiter: CheckedContinuation<Int32, Never>?

    /// Records the process's exit status, resuming a parked waiter if present.
    /// Called once, from the termination handler (on an arbitrary thread).
    nonisolated func resume(_ exitStatus: Int32) {
        lock.lock()
        if let parked = waiter {
            waiter = nil
            lock.unlock()
            parked.resume(returning: exitStatus)
        } else {
            status = exitStatus
            lock.unlock()
        }
    }

    /// The process's exit status, awaited — returning immediately if it has
    /// already terminated.
    nonisolated var value: Int32 {
        get async {
            await withCheckedContinuation { continuation in
                lock.lock()
                if let status {
                    lock.unlock()
                    continuation.resume(returning: status)
                } else {
                    waiter = continuation
                    lock.unlock()
                }
            }
        }
    }
}
