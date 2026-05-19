//
//  CSVEscapingTests.swift
//  LintStudioCoreTests
//
//  Tests for CSV field escaping
//

@testable import LintStudioCore
import Testing

@MainActor
@Suite("CSVEscaping Tests")
struct CSVEscapingTests {
    @Test("Plain text is returned unchanged")
    func plainText() {
        #expect(CSVEscaping.escape("hello") == "hello")
    }

    @Test("Text with commas is quoted")
    func textWithCommas() {
        #expect(CSVEscaping.escape("a,b") == "\"a,b\"")
    }

    @Test("Text with double quotes is escaped and quoted")
    func textWithDoubleQuotes() {
        #expect(CSVEscaping.escape("say \"hi\"") == "\"say \"\"hi\"\"\"")
    }

    @Test("Text with newlines is quoted")
    func textWithNewlines() {
        #expect(CSVEscaping.escape("line1\nline2") == "\"line1\nline2\"")
    }

    @Test("Empty string is returned unchanged")
    func emptyString() {
        #expect(CSVEscaping.escape("") == "")
    }

    @Test("Text with commas and quotes is escaped and quoted")
    func textWithCommasAndQuotes() {
        let result = CSVEscaping.escape("a,\"b\"")
        #expect(result == "\"a,\"\"b\"\"\"")
    }
}
