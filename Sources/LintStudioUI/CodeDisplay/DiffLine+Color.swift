//
//  DiffLine+Color.swift
//  LintStudioUI
//
//  SwiftUI Color extensions for DiffLine rendering
//

import SwiftUI
import LintStudioCore

extension DiffLine {
    public var backgroundColor: Color {
        switch kind {
        case .added: Color.green.opacity(0.12)
        case .removed: Color.red.opacity(0.12)
        case .unchanged: .clear
        }
    }

    public var highlightColor: Color {
        switch kind {
        case .added: Color.green.opacity(0.3)
        case .removed: Color.red.opacity(0.3)
        case .unchanged: .clear
        }
    }

    public var prefixColor: Color {
        switch kind {
        case .added: .green
        case .removed: .red
        case .unchanged: .secondary
        }
    }
}
