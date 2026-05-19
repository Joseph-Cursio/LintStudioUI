//
//  DiffLine+Color.swift
//  LintStudioUI
//
//  SwiftUI Color extensions for DiffLine rendering
//

import LintStudioCore
import SwiftUI

public extension DiffLine {
    private enum Palette {
        static let backgroundOpacity = 0.12
        static let highlightOpacity = 0.3
    }

    /// The row background color for this line's diff kind.
    var backgroundColor: Color {
        switch kind {
        case .added:
            Color.green.opacity(Palette.backgroundOpacity)

        case .removed:
            Color.red.opacity(Palette.backgroundOpacity)

        case .unchanged:
            .clear
        }
    }

    /// The inline character-highlight color for this line's diff kind.
    var highlightColor: Color {
        switch kind {
        case .added:
            Color.green.opacity(Palette.highlightOpacity)

        case .removed:
            Color.red.opacity(Palette.highlightOpacity)

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
