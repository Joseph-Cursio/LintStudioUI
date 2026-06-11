//
//  DiffLineColorTests.swift
//  LintStudioCoreTests
//
//  Rendering colors for DiffLine: row background, inline character highlight,
//  and gutter-prefix glyph. These exercise the DiffLine+Color extension that
//  lives in the LintStudioUI target.
//
//  Relocated from SwiftLintRuleStudio, which had copied LintStudioUI's whole
//  UnifiedDiffEngine test suite. The engine tests already live in this package;
//  this color coverage did not exist anywhere else, so it moves here next to the
//  type it tests rather than being lost.
//

import LintStudioCore
import LintStudioUI
import SwiftUI
import Testing

@MainActor
@Suite("DiffLine Colors")
struct DiffLineColorTests {

    // MARK: - Row background

    @Test("Added line has green background")
    func addedLineBackground() {
        let line = DiffLine(text: "new", kind: .added)
        #expect(line.backgroundColor != .clear)
    }

    @Test("Removed line has red background")
    func removedLineBackground() {
        let line = DiffLine(text: "old", kind: .removed)
        #expect(line.backgroundColor != .clear)
    }

    @Test("Unchanged line has clear background")
    func unchangedLineBackground() {
        let line = DiffLine(text: "same", kind: .unchanged)
        #expect(line.backgroundColor == .clear)
    }

    // MARK: - Inline highlight

    @Test("Added line highlight color is non-clear")
    func addedHighlightColor() {
        let line = DiffLine(text: "new", kind: .added)
        #expect(line.highlightColor != .clear)
    }

    @Test("Removed line highlight color is non-clear")
    func removedHighlightColor() {
        let line = DiffLine(text: "old", kind: .removed)
        #expect(line.highlightColor != .clear)
    }

    @Test("Unchanged line highlight color is clear")
    func unchangedHighlightColor() {
        let line = DiffLine(text: "same", kind: .unchanged)
        #expect(line.highlightColor == .clear)
    }

    // MARK: - Gutter prefix glyph

    @Test("Added line prefix color is green")
    func addedPrefixColor() {
        let line = DiffLine(text: "new", kind: .added)
        #expect(line.prefixColor == .green)
    }

    @Test("Removed line prefix color is red")
    func removedPrefixColor() {
        let line = DiffLine(text: "old", kind: .removed)
        #expect(line.prefixColor == .red)
    }

    @Test("Unchanged line prefix color is secondary")
    func unchangedPrefixColor() {
        let line = DiffLine(text: "same", kind: .unchanged)
        #expect(line.prefixColor == .secondary)
    }
}
