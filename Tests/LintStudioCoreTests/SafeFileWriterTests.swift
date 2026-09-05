//
//  SafeFileWriterTests.swift
//  LintStudioCoreTests
//
//  Tests for atomic file writing with backups
//

import Foundation
@testable import LintStudioCore
import Testing

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

    // MARK: - The backup name, now that the clock is injectable

    // `write` stamped the backup with `Date.now` read inline, so nothing could assert on the
    // name and the collision rule below was visible only by reading the code. The clock is now
    // a parameter defaulting to the system clock, and the naming is its own function.

    @Test("a backup carries the instant the writer was given")
    func backupNameUsesTheInjectedInstant() throws {
        let directory = try tempDir()
        defer { try? FileManager.default.removeItem(at: directory) }

        let destination = directory.appendingPathComponent("config.yml")
        try "original".write(to: destination, atomically: true, encoding: .utf8)

        let instant = Date(timeIntervalSince1970: 1_700_000_000)
        try SafeFileWriter.write("updated", to: destination, now: { instant })

        let names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        #expect(names.contains("config.yml.1700000000.backup"), "got \(names)")
    }

    @Test("the name is a function of the destination and the instant")
    func backupNameIsAFunctionOfItsInputs() {
        let destination = URL(fileURLWithPath: "/tmp/config.yml")
        let instant = Date(timeIntervalSince1970: 1_700_000_000)

        #expect(SafeFileWriter.backupName(for: destination, at: instant)
            == "config.yml.1700000000.backup")
        #expect(SafeFileWriter.backupName(for: destination, at: instant)
            == SafeFileWriter.backupName(for: destination, at: instant))
    }

    @Test("two writes inside the same second share one backup")
    func sameSecondWritesCollapseToOneBackup() throws {
        // The stamp has one-second resolution, so this is the documented consequence rather
        // than a bug: the second backup replaces the first, and the older content is lost.
        // Stating it as a test is what the injected clock buys — before, reproducing it meant
        // getting two writes into the same wall-clock second.
        let directory = try tempDir()
        defer { try? FileManager.default.removeItem(at: directory) }

        let destination = directory.appendingPathComponent("config.yml")
        try "first".write(to: destination, atomically: true, encoding: .utf8)

        let instant = Date(timeIntervalSince1970: 1_700_000_000)
        try SafeFileWriter.write("second", to: destination, now: { instant })
        try SafeFileWriter.write("third", to: destination, now: { instant })

        let backups = try FileManager.default.contentsOfDirectory(atPath: directory.path)
            .filter { $0.hasSuffix(".backup") }
        #expect(backups.count == 1)
        let restored = try String(contentsOf: directory.appendingPathComponent(backups[0]), encoding: .utf8)
        #expect(restored == "second", "the surviving backup is the later one")
    }

    @Test("a second apart produces two backups")
    func differentSecondsProduceTwoBackups() throws {
        let directory = try tempDir()
        defer { try? FileManager.default.removeItem(at: directory) }

        let destination = directory.appendingPathComponent("config.yml")
        try "first".write(to: destination, atomically: true, encoding: .utf8)

        let instant = Date(timeIntervalSince1970: 1_700_000_000)
        try SafeFileWriter.write("second", to: destination, now: { instant })
        try SafeFileWriter.write("third", to: destination, now: { instant.addingTimeInterval(1) })

        let backups = try FileManager.default.contentsOfDirectory(atPath: directory.path)
            .filter { $0.hasSuffix(".backup") }
        #expect(backups.count == 2)
    }

}
