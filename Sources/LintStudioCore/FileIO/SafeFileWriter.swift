//
//  SafeFileWriter.swift
//  LintStudioCore
//
//  Atomic file writing with optional timestamped backups
//

import Foundation

/// Writes files atomically via a temp file + move, with optional backup.
public enum SafeFileWriter {
    /// Writes content to a file atomically, optionally creating a timestamped backup first.
    ///
    /// The write is performed by writing to a UUID-named temp file in the same directory,
    /// then moving it to the final location. This prevents partial writes on crash or power loss.
    ///
    /// - Parameters:
    ///   - content: The string content to write.
    ///   - destination: The file URL to write to.
    ///   - createBackup: If true and the destination already exists, a timestamped
    ///     `.backup` copy is created before overwriting.
    ///   - now: The clock that names the backup. Defaults to the system clock, so no existing
    ///     call site changes. The instant is *observable* — it goes into the backup's filename,
    ///     and `backupName(for:at:)` is what a test can assert on — so this is the one piece of
    ///     nondeterminism here worth injecting. The temp file's `UUID()` is not: nothing reads
    ///     that name, it exists only so two concurrent writes do not collide, and injecting it
    ///     would buy indirection and no testability.
    /// - Throws: File system errors from copy, write, or move operations.
    nonisolated public static func write(
        _ content: String,
        to destination: URL,
        createBackup: Bool = true,
        // The seam itself, and the one place in this type that reads a clock. The rule is
        // right that this default reads ambient time — that is what a default is for.
        // swiftprojectlint:disable:next non-injected-nondeterminism
        now: @Sendable () -> Date = { Date() }
    ) throws {
        let fileManager = FileManager.default

        // Create backup if requested and file exists
        if createBackup, fileManager.fileExists(atPath: destination.path) {
            let backupURL = destination
                .deletingLastPathComponent()
                .appendingPathComponent(backupName(for: destination, at: now()))

            if fileManager.fileExists(atPath: backupURL.path) {
                try fileManager.removeItem(at: backupURL)
            }
            try fileManager.copyItem(at: destination, to: backupURL)
        }

        // Deliberately not injected. This name exists so two concurrent writes do not collide
        // and is gone by the end of the call — nothing reads it, no test asserts on it, and a
        // provider here would buy indirection and no testability. Contrast the backup name
        // above, which survives the call and is therefore worth controlling.
        // swiftprojectlint:disable:next non-injected-nondeterminism
        let tempName = "\(destination.lastPathComponent).\(UUID().uuidString).tmp"
        let tempURL = destination
            .deletingLastPathComponent()
            .appendingPathComponent(tempName)

        try content.write(to: tempURL, atomically: true, encoding: .utf8)

        // Move temp file to final location
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: tempURL, to: destination)
    }

    /// The name a backup of `destination` taken at `instant` is given.
    ///
    /// Lifted out of `write` so the naming can be asserted on directly. It also states the
    /// collision rule that was previously only visible by reading the surrounding code: the
    /// stamp has one-second resolution, so two writes inside the same second name the same
    /// backup, and the second overwrites the first.
    nonisolated public static func backupName(for destination: URL, at instant: Date) -> String {
        "\(destination.lastPathComponent).\(Int(instant.timeIntervalSince1970)).backup"
    }
}
