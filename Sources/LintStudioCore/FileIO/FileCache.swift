//
//  FileCache.swift
//  LintStudioCore
//
//  A small, tool-agnostic file cache rooted in an app-support subdirectory.
//  Shared across the LintStudio family of apps; callers layer their own
//  domain-typed accessors (rules, tool version, etc.) on top.
//

import Foundation

public struct FileCache: Sendable {
    /// The directory all cached files live in.
    public let directory: URL

    /// - Parameters:
    ///   - appIdentifier: subdirectory name under Application Support (e.g. the app name).
    ///   - cacheDirectory: an explicit directory override (used for test isolation).
    nonisolated public init(appIdentifier: String, cacheDirectory: URL? = nil) {
        if let cacheDirectory {
            directory = cacheDirectory
        } else {
            let appSupport = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            directory = appSupport.appendingPathComponent(appIdentifier, isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    nonisolated public func fileURL(_ name: String) -> URL {
        directory.appendingPathComponent(name)
    }

    nonisolated public func fileExists(_ name: String) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(name).path)
    }

    // MARK: - Codable

    /// Decodes a cached JSON value, or returns nil when the file is absent.
    nonisolated public func loadCodable<T: Decodable>(_: T.Type, from name: String) throws -> T? {
        let url = fileURL(name)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
    }

    /// Encodes a value to pretty-printed, key-sorted JSON.
    nonisolated public func saveCodable(_ value: some Encodable, to name: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(value).write(to: fileURL(name))
    }

    // MARK: - String

    /// Reads a cached string (whitespace-trimmed), or nil when the file is absent.
    nonisolated public func loadString(from name: String) throws -> String? {
        let url = fileURL(name)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try String(contentsOf: url, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated public func saveString(_ string: String, to name: String) throws {
        try string.write(to: fileURL(name), atomically: true, encoding: .utf8)
    }

    // MARK: - Removal

    /// Removes a cached file if it exists (no-op otherwise).
    nonisolated public func removeFile(_ name: String) throws {
        let url = fileURL(name)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}
