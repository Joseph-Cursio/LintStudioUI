//
//  GitServiceActor.swift
//  LintStudioCore
//
//  Tool-agnostic git command execution service for branch diff and version
//  control operations. Shared across the LintStudio family of apps.
//

import Foundation

// MARK: - Protocol

public protocol GitServiceProtocol: Sendable {
    func isGitRepository(at path: URL) async throws -> Bool
    func getCurrentBranch(at repoPath: URL) async throws -> String
    func listBranches(at repoPath: URL) async throws -> [String]
    func listTags(at repoPath: URL) async throws -> [String]
    func showFile(at repoPath: URL, branch: String, filePath: String) async throws -> String
    func diffFile(at repoPath: URL, fromRef: String, toRef: String, filePath: String) async throws -> String
}

// MARK: - Errors

public enum GitServiceError: LocalizedError, Sendable {
    case notARepository
    case branchNotFound(String)
    case fileNotFound(branch: String, path: String)
    case executionFailed(message: String)
    case timeout

    public var errorDescription: String? {
        switch self {
        case .notARepository:
            return "The specified directory is not a git repository."
        case .branchNotFound(let branch):
            return "Branch '\(branch)' not found."
        case .fileNotFound(let branch, let path):
            return "File '\(path)' not found on branch '\(branch)'."
        case .executionFailed(let message):
            return "Git command failed: \(message)"
        case .timeout:
            return "Git command timed out after 30 seconds."
        }
    }
}

// MARK: - Implementation

public actor GitServiceActor: GitServiceProtocol {
    private static let timeoutSeconds: UInt64 = 30

    /// All git invocations run through the shared CLI runner. Git is just
    /// another developer tool: a fixed binary, a 30s timeout, and exit `0` as
    /// the only success code (none of the commands used here rely on git's
    /// `--exit-code` conventions).
    private let cliTool: CLIToolActor

    public init() {
        cliTool = CLIToolActor(
            toolName: "git",
            searchPaths: ["/usr/bin/git"],
            timeoutSeconds: Self.timeoutSeconds,
            successExitCodes: [0]
        )
    }

    public func isGitRepository(at path: URL) async throws -> Bool {
        do {
            let output = try await runGit(at: path, arguments: ["rev-parse", "--is-inside-work-tree"])
            return output.trimmingCharacters(in: .whitespacesAndNewlines) == "true"
        } catch {
            return false
        }
    }

    public func getCurrentBranch(at repoPath: URL) async throws -> String {
        try await ensureGitRepo(at: repoPath)
        let output = try await runGit(at: repoPath, arguments: ["rev-parse", "--abbrev-ref", "HEAD"])
        let branch = output.trimmingCharacters(in: .whitespacesAndNewlines)
        if branch.isEmpty {
            throw GitServiceError.executionFailed(message: "Could not determine current branch.")
        }
        return branch
    }

    public func listBranches(at repoPath: URL) async throws -> [String] {
        try await ensureGitRepo(at: repoPath)
        let output = try await runGit(at: repoPath, arguments: ["branch", "--format=%(refname:short)"])
        return output
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    public func listTags(at repoPath: URL) async throws -> [String] {
        try await ensureGitRepo(at: repoPath)
        let output = try await runGit(at: repoPath, arguments: ["tag", "--list"])
        return output
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    public func showFile(at repoPath: URL, branch: String, filePath: String) async throws -> String {
        try await ensureGitRepo(at: repoPath)
        do {
            return try await runGit(at: repoPath, arguments: ["show", "\(branch):\(filePath)"])
        } catch let error as GitServiceError {
            if case .executionFailed(let msg) = error,
               msg.contains("does not exist") || msg.contains("not exist") || msg.contains("fatal: path") {
                throw GitServiceError.fileNotFound(branch: branch, path: filePath)
            }
            throw error
        }
    }

    public func diffFile(at repoPath: URL, fromRef: String, toRef: String, filePath: String) async throws -> String {
        try await ensureGitRepo(at: repoPath)
        return try await runGit(at: repoPath, arguments: ["diff", fromRef, toRef, "--", filePath])
    }

    // MARK: - Private

    private func ensureGitRepo(at path: URL) async throws {
        let isRepo = try await isGitRepository(at: path)
        if !isRepo {
            throw GitServiceError.notARepository
        }
    }

    /// Runs git inside `repoPath` (via git's own `-C` flag) and returns stdout.
    /// Translates the generic `CLIToolError` into the git-specific error space
    /// callers expect.
    private func runGit(at repoPath: URL, arguments: [String]) async throws -> String {
        do {
            let result = try await cliTool.run(arguments: ["-C", repoPath.path] + arguments)
            return result.stdoutString
        } catch let error as CLIToolError {
            throw Self.mapError(error)
        }
    }

    private nonisolated static func mapError(_ error: CLIToolError) -> GitServiceError {
        switch error {
        case .timedOut:
            return .timeout
        case .notFound(_, let installMessage):
            return .executionFailed(message: installMessage ?? "git not found.")
        case .executionFailed(let message):
            // CLIToolActor prefixes with "git failed: "; strip it so the
            // surfaced message stays the raw git stderr, matching prior output
            // and keeping showFile's "does not exist" detection working.
            let prefix = "git failed: "
            let detail = message.hasPrefix(prefix) ? String(message.dropFirst(prefix.count)) : message
            return .executionFailed(message: detail)
        }
    }
}
