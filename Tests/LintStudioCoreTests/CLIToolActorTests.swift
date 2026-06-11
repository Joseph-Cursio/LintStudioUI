//
//  CLIToolActorTests.swift
//  LintStudioCoreTests
//
//  Tests for CLIToolActor — path detection, the SwiftLint-modeled exit-code
//  policy, stdin passthrough, real-process execution, and timeout handling.
//

import Foundation
@testable import LintStudioCore
import Testing

@Suite("CLIToolActor Tests")
struct CLIToolActorTests {

    // MARK: - Helpers

    /// A command runner that records the arguments/stdin it was given and
    /// returns a canned result.
    private nonisolated final class RunnerSpy: @unchecked Sendable {
        var receivedArguments: [String] = []
        var receivedStdin: Data?
    }

    private func runner(
        stdout: String = "",
        stderr: String = "",
        exitCode: Int32 = 0,
        spy: RunnerSpy? = nil
    ) -> CLIToolCommandRunner {
        { arguments, stdin in
            spy?.receivedArguments = arguments
            spy?.receivedStdin = stdin
            return (Data(stdout.utf8), Data(stderr.utf8), exitCode)
        }
    }

    // MARK: - Path detection

    @Test("detectPath returns the first existing candidate")
    func detectPathReturnsFirstExisting() async throws {
        let actor = CLIToolActor(
            toolName: "faketool",
            searchPaths: ["/nope/faketool", "/opt/homebrew/bin/faketool"],
            fileExists: { $0 == "/opt/homebrew/bin/faketool" }
        )
        let url = try await actor.detectPath()
        #expect(url.path == "/opt/homebrew/bin/faketool")
    }

    @Test("detectPath throws .notFound when no candidate exists")
    func detectPathThrowsWhenMissing() async {
        let actor = CLIToolActor(
            toolName: "faketool",
            searchPaths: ["/nope/faketool"],
            installMessage: "install faketool please",
            fileExists: { _ in false }
        )
        await #expect(throws: CLIToolError.self) {
            try await actor.detectPath()
        }
    }

    // MARK: - Exit-code policy (SwiftLint convention)

    @Test("exit 0 is a success")
    func exitZeroSucceeds() async throws {
        let actor = CLIToolActor(toolName: "swiftlint", commandRunner: runner(stdout: "clean", exitCode: 0))
        let result = try await actor.run(arguments: [])
        #expect(result.exitCode == 0)
        #expect(result.stdoutString == "clean")
    }

    @Test("exit 2 (serious violations) is a success per SwiftLint convention")
    func exitTwoSucceeds() async throws {
        let actor = CLIToolActor(toolName: "swiftlint", commandRunner: runner(stdout: "violations", exitCode: 2))
        let result = try await actor.run(arguments: [])
        #expect(result.exitCode == 2)
        #expect(result.didTimeout == false)
    }

    @Test("exit 127 maps to .notFound")
    func exit127MapsToNotFound() async {
        let actor = CLIToolActor(toolName: "swiftlint", commandRunner: runner(stderr: "command not found", exitCode: 127))
        await #expect(throws: CLIToolError.self) {
            try await actor.run(arguments: [])
        }
    }

    @Test("an exit code outside the success set throws .executionFailed with stderr detail")
    func nonSuccessThrowsExecutionFailed() async {
        let actor = CLIToolActor(toolName: "swiftlint", commandRunner: runner(stderr: "boom", exitCode: 70))
        do {
            _ = try await actor.run(arguments: [])
            Issue.record("Expected .executionFailed")
        } catch let error as CLIToolError {
            guard case .executionFailed(let message) = error else {
                Issue.record("Expected .executionFailed, got \(error)")
                return
            }
            #expect(message.contains("boom"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("custom successExitCodes lets SwiftFormat's exit 1 count as success")
    func customSuccessExitCodes() async throws {
        let actor = CLIToolActor(
            toolName: "swiftformat",
            successExitCodes: [0, 1],
            commandRunner: runner(stdout: "linted", exitCode: 1)
        )
        let result = try await actor.run(arguments: [])
        #expect(result.exitCode == 1)
    }

    // MARK: - stdin passthrough

    @Test("stdin is forwarded to the command runner")
    func stdinForwarded() async throws {
        let spy = RunnerSpy()
        let actor = CLIToolActor(toolName: "swiftformat", commandRunner: runner(spy: spy))
        let payload = Data("let x = 1".utf8)
        _ = try await actor.run(arguments: ["stdin"], stdin: payload)
        #expect(spy.receivedArguments == ["stdin"])
        #expect(spy.receivedStdin == payload)
    }

    // MARK: - Real process execution

    @Test("runs a real binary directly and captures stdout")
    func realDirectExecution() async throws {
        let actor = CLIToolActor(
            toolName: "echo",
            searchPaths: ["/bin/echo"],
            successExitCodes: [0]
        )
        let result = try await actor.run(arguments: ["hello"])
        #expect(result.stdoutString.trimmingCharacters(in: .whitespacesAndNewlines) == "hello")
        #expect(result.exitCode == 0)
    }

    @Test("real binary exiting nonzero outside success set throws .executionFailed")
    func realDirectFailure() async {
        let actor = CLIToolActor(
            toolName: "false",
            searchPaths: ["/usr/bin/false"],
            successExitCodes: [0]
        )
        await #expect(throws: CLIToolError.self) {
            try await actor.run(arguments: [])
        }
    }

    /// Regression: `workingDirectory` must set the launched process's cwd. Tools
    /// like SwiftLint resolve their config (and its `excluded:` paths) relative to
    /// the cwd, not the path arguments — without this the launched macOS app runs
    /// SwiftLint from `/`, misses the workspace `.swiftlint.yml`, and lints
    /// excluded dependency trees. `pwd` prints the cwd, so it pins the behavior.
    @Test("workingDirectory launches the process in that directory")
    func workingDirectoryIsHonored() async throws {
        let fileManager = FileManager.default
        let tempDir = try fileManager.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: URL(fileURLWithPath: NSTemporaryDirectory()),
            create: true
        )
        defer { try? fileManager.removeItem(at: tempDir) }

        let actor = CLIToolActor(
            toolName: "pwd",
            searchPaths: ["/bin/pwd"],
            successExitCodes: [0]
        )
        let result = try await actor.run(arguments: [], workingDirectory: tempDir)
        let trimmed = result.stdoutString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let printed = URL(fileURLWithPath: trimmed)
        #expect(printed.resolvingSymlinksInPath().path == tempDir.resolvingSymlinksInPath().path)
    }

    /// Regression: many real subprocesses launched at once must all complete.
    /// The previous `process.waitUntilExit()` blocked a Swift-concurrency
    /// cooperative thread per run; once concurrent runs exceeded the pool width
    /// (≈ core count) they could deadlock with the child already exited. Each
    /// run emits a few KB so the output pipes carry real data. If the hang
    /// returns, this test never finishes (and the suite times out) rather than
    /// failing an assertion — that's the intended alarm.
    @Test("many concurrent real runs all complete without wedging")
    func concurrentRealRunsDoNotDeadlock() async throws {
        let runCount = 24 // comfortably above the 8–12 core cooperative-pool width
        let results = try await withThrowingTaskGroup(of: Int.self) { group in
            for _ in 0..<runCount {
                group.addTask {
                    let actor = CLIToolActor(
                        toolName: "seq",
                        searchPaths: ["/usr/bin/seq"],
                        successExitCodes: [0]
                    )
                    let result = try await actor.run(arguments: ["1", "5000"])
                    // 1…5000, one per line — confirms the full pipe was drained.
                    return result.stdoutString.split(separator: "\n").count
                }
            }
            var counts: [Int] = []
            for try await count in group { counts.append(count) }
            return counts
        }
        #expect(results.count == runCount)
        #expect(results.allSatisfy { $0 == 5000 })
    }

    // MARK: - Timeout

    @Test("a run exceeding the timeout throws .timedOut")
    func timeoutThrows() async {
        let actor = CLIToolActor(
            toolName: "sleep",
            searchPaths: ["/bin/sleep"],
            timeoutSeconds: 1,
            successExitCodes: [0]
        )
        do {
            _ = try await actor.run(arguments: ["10"])
            Issue.record("Expected .timedOut")
        } catch let error as CLIToolError {
            guard case .timedOut = error else {
                Issue.record("Expected .timedOut, got \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - Static helpers

    @Test("defaultSearchPaths covers Homebrew and system locations")
    func defaultSearchPaths() {
        let paths = CLIToolActor.defaultSearchPaths(for: "swiftlint")
        #expect(paths == [
            "/opt/homebrew/bin/swiftlint",
            "/usr/local/bin/swiftlint",
            "/usr/bin/swiftlint"
        ])
    }

    @Test("buildEnvironment prepends Homebrew bin to an existing PATH")
    func buildEnvironmentPrependsPath() {
        let environment = CLIToolActor.buildEnvironment(base: ["PATH": "/usr/bin"])
        #expect(environment["PATH"] == "/opt/homebrew/bin:/usr/local/bin:/usr/bin")
    }

    @Test("buildEnvironment supplies a PATH when none is set")
    func buildEnvironmentSuppliesDefaultPath() {
        let environment = CLIToolActor.buildEnvironment(base: [:])
        #expect(environment["PATH"] == "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin")
    }

    @Test("buildEnvironment leaves an already-Homebrew PATH untouched")
    func buildEnvironmentIdempotent() {
        let existing = "/opt/homebrew/bin:/usr/bin"
        let environment = CLIToolActor.buildEnvironment(base: ["PATH": existing])
        #expect(environment["PATH"] == existing)
    }

    @Test("escapeShellArgument quotes values with spaces")
    func escapeShellArgumentQuotesSpaces() {
        #expect(CLIToolActor.escapeShellArgument("a b") == "'a b'")
        #expect(CLIToolActor.escapeShellArgument("plain") == "plain")
    }

    @Test("buildShellCommand joins escaped command and arguments")
    func buildShellCommandJoins() {
        let command = CLIToolActor.buildShellCommand(command: "swiftlint", arguments: ["--path", "My Project"])
        #expect(command == "swiftlint --path 'My Project'")
    }
}
