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
    /// - Throws: File system errors from copy, write, or move operations.
    nonisolated public static func write(
        _ content: String,
        to destination: URL,
        createBackup: Bool = true
    ) throws {
        let fileManager = FileManager.default

        // Create backup if requested and file exists
        if createBackup && fileManager.fileExists(atPath: destination.path) {
            let timestamp = Int(Date.now.timeIntervalSince1970)
            let backupName = "\(destination.lastPathComponent).\(timestamp).backup"
            let backupURL = destination
                .deletingLastPathComponent()
                .appendingPathComponent(backupName)

            if fileManager.fileExists(atPath: backupURL.path) {
                try fileManager.removeItem(at: backupURL)
            }
            try fileManager.copyItem(at: destination, to: backupURL)
        }

        // Write to temp file with UUID to avoid conflicts
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
}
