//
//  DiffLine+Color.swift
//  LintStudioUI
//
//  SwiftUI Color extensions for DiffLine rendering
//

import LintStudioCore
import SwiftUI

public extension DiffLine {
    /// The row background color for this line's diff kind.
    var backgroundColor: Color {
        switch kind {
        case .added:
            Color.green.opacity(0.12)

        case .removed:
            Color.red.opacity(0.12)

        case .unchanged:
            .clear
        }
    }

    /// The inline character-highlight color for this line's diff kind.
    var highlightColor: Color {
        switch kind {
        case .added:
            Color.green.opacity(0.3)

        case .removed:
            Color.red.opacity(0.3)

        case .unchanged:
            .clear
        }
    }

    /// The color of the gutter prefix glyph for this line's diff kind.
    var prefixColor: Color {
        switch kind {
        case .added:
            .green

        case .removed:
            .red

        case .unchanged:
            .secondary
        }
    }
}
