//
//  HTMLEscapingTests.swift
//  LintStudioCoreTests
//
//  Tests for HTML entity escaping
//

@testable import LintStudioCore
import Testing

@MainActor
@Suite("HTMLEscaping Tests")
struct HTMLEscapingTests {

    @Test("Escapes ampersands")
    func escapesAmpersands() {
        #expect(HTMLEscaping.escape("A & B") == "A &amp; B")
    }

    @Test("Escapes less-than signs")
    func escapesLessThan() {
        #expect(HTMLEscaping.escape("<div>") == "&lt;div&gt;")
    }

    @Test("Escapes double quotes")
    func escapesDoubleQuotes() {
        #expect(HTMLEscaping.escape("say \"hello\"") == "say &quot;hello&quot;")
    }

    @Test("Leaves plain text unchanged")
    func leavesPlainTextUnchanged() {
        #expect(HTMLEscaping.escape("hello world") == "hello world")
    }

    @Test("Handles empty string")
    func handlesEmptyString() {
        #expect(HTMLEscaping.escape("") == "")
    }

    @Test("Escapes multiple special characters in sequence")
    func escapesMultipleSpecialChars() {
        let input = "<a href=\"foo&bar\">"
        let expected = "&lt;a href=&quot;foo&amp;bar&quot;&gt;"
        #expect(HTMLEscaping.escape(input) == expected)
    }
}
