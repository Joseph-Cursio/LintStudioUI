//
//  SafeFileWriterTests.swift
//  LintStudioCoreTests
//
//  Tests for atomic file writing with backups
//

import Testing
import Foundation
@testable import LintStudioCore

@MainActor
@Suite("SafeFileWriter Tests")
struct SafeFileWriterTests {

    private func tempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SafeFileWriterTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test("Writes file content correctly")
    func writesContent() throws {
        let dir = try tempDir()
        let file = dir.appendingPathComponent("test.yml")

        try SafeFileWriter.write("key: value\n", to: file, createBackup: false)

        let content = try String(contentsOf: file, encoding: .utf8)
        #expect(content == "key: value\n")

        try FileManager.default.removeItem(at: dir)
    }

    @Test("Creates backup when overwriting")
    func createsBackup() throws {
        let dir = try tempDir()
        let file = dir.appendingPathComponent("config.yml")

        try "original".write(to: file, atomically: true, encoding: .utf8)
        try SafeFileWriter.write("updated", to: file, createBackup: true)

        let updated = try String(contentsOf: file, encoding: .utf8)
        #expect(updated == "updated")

        let backups = try FileManager.default.contentsOfDirectory(atPath: dir.path)
            .filter { $0.hasSuffix(".backup") }
        #expect(backups.count == 1)

        let backupContent = try String(
            contentsOf: dir.appendingPathComponent(backups[0]),
            encoding: .utf8
        )
        #expect(backupContent == "original")

        try FileManager.default.removeItem(at: dir)
    }

    @Test("Skips backup when file does not exist")
    func noBackupForNewFile() throws {
        let dir = try tempDir()
        let file = dir.appendingPathComponent("new.yml")

        try SafeFileWriter.write("content", to: file, createBackup: true)

        let files = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        let backups = files.filter { $0.hasSuffix(".backup") }
        #expect(backups.isEmpty)

        try FileManager.default.removeItem(at: dir)
    }

    @Test("Skips backup when createBackup is false")
    func noBackupWhenDisabled() throws {
        let dir = try tempDir()
        let file = dir.appendingPathComponent("config.yml")

        try "original".write(to: file, atomically: true, encoding: .utf8)
        try SafeFileWriter.write("updated", to: file, createBackup: false)

        let files = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        let backups = files.filter { $0.hasSuffix(".backup") }
        #expect(backups.isEmpty)

        try FileManager.default.removeItem(at: dir)
    }

    @Test("No temp files left behind after write")
    func noTempFilesRemain() throws {
        let dir = try tempDir()
        let file = dir.appendingPathComponent("config.yml")

        try SafeFileWriter.write("content", to: file, createBackup: false)

        let files = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        let temps = files.filter { $0.hasSuffix(".tmp") }
        #expect(temps.isEmpty)

        try FileManager.default.removeItem(at: dir)
    }
}
