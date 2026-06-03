//
//  FileCacheTests.swift
//  LintStudioCoreTests
//
//  Tests for the tool-agnostic FileCache.
//

import Foundation
@testable import LintStudioCore
import Testing

@MainActor
@Suite("FileCache Tests")
struct FileCacheTests {

    private struct Sample: Codable, Equatable {
        let name: String
        let count: Int
    }

    private func isolatedCache() -> FileCache {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileCacheTests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        return FileCache(appIdentifier: "FileCacheTests", cacheDirectory: tempDir)
    }

    @Test("Codable round-trips through the cache")
    func codableRoundTrip() throws {
        let cache = isolatedCache()
        let value = Sample(name: "alpha", count: 3)
        try cache.saveCodable(value, to: "sample.json")
        let loaded = try cache.loadCodable(Sample.self, from: "sample.json")
        #expect(loaded == value)
    }

    @Test("Loading an absent Codable file returns nil")
    func absentCodableReturnsNil() throws {
        let cache = isolatedCache()
        let loaded = try cache.loadCodable(Sample.self, from: "missing.json")
        #expect(loaded == nil)
    }

    @Test("String round-trips and is whitespace-trimmed")
    func stringRoundTrip() throws {
        let cache = isolatedCache()
        try cache.saveString("  1.2.3\n", to: "version.txt")
        let loaded = try cache.loadString(from: "version.txt")
        #expect(loaded == "1.2.3")
    }

    @Test("Loading an absent string file returns nil")
    func absentStringReturnsNil() throws {
        let cache = isolatedCache()
        let loaded = try cache.loadString(from: "missing.txt")
        #expect(loaded == nil)
    }

    @Test("removeFile deletes an existing file and no-ops otherwise")
    func removeFile() throws {
        let cache = isolatedCache()
        try cache.saveString("x", to: "doomed.txt")
        #expect(cache.fileExists("doomed.txt"))
        try cache.removeFile("doomed.txt")
        #expect(cache.fileExists("doomed.txt") == false)
        // Second removal is a no-op, not an error.
        try cache.removeFile("doomed.txt")
    }
}
