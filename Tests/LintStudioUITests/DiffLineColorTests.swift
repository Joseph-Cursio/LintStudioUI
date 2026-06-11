//
//  DiffLineColorTests.swift
//  LintStudioUITests
//
//  Tests for the DiffLine color mappings used by the diff renderer.
//

import LintStudioCore
@testable import LintStudioUI
import SwiftUI
import Testing

@MainActor
@Suite("DiffLine+Color Tests")
struct DiffLineColorTests {

    private func line(_ kind: DiffLine.Kind) -> DiffLine {
        DiffLine(text: "x", kind: kind)
    }

    // MARK: - Background

    @Test("Added lines get a translucent green row background")
    func addedBackground() {
        #expect(line(.added).backgroundColor == Color.green.opacity(0.12))
    }

    @Test("Removed lines get a translucent red row background")
    func removedBackground() {
        #expect(line(.removed).backgroundColor == Color.red.opacity(0.12))
    }

    @Test("Unchanged lines have a clear background")
    func unchangedBackground() {
        #expect(line(.unchanged).backgroundColor == Color.clear)
    }

    // MARK: - Inline highlight

    @Test("Added lines highlight inline changes in green")
    func addedHighlight() {
        #expect(line(.added).highlightColor == Color.green.opacity(0.3))
    }

    @Test("Removed lines highlight inline changes in red")
    func removedHighlight() {
        #expect(line(.removed).highlightColor == Color.red.opacity(0.3))
    }

    @Test("Unchanged lines have a clear highlight")
    func unchangedHighlight() {
        #expect(line(.unchanged).highlightColor == Color.clear)
    }

    // MARK: - Gutter prefix

    @Test("Gutter prefix glyph is green for added, red for removed, secondary otherwise")
    func prefixColor() {
        #expect(line(.added).prefixColor == Color.green)
        #expect(line(.removed).prefixColor == Color.red)
        #expect(line(.unchanged).prefixColor == Color.secondary)
    }
}
