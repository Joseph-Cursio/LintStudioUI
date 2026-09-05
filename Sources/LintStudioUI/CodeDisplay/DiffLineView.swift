//
//  DiffLineView.swift
//  LintStudioUI
//
//  View for rendering a single diff line with optional character-level highlighting
//

import LintStudioCore
import SwiftUI

public struct DiffLineView: View {
    private enum Layout {
        static let prefixColumnWidth: CGFloat = 20
        static let horizontalPadding: CGFloat = 12
    }

    public let line: DiffLine

    public var body: some View {
        HStack(spacing: 0) {
            Text(line.prefix)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.bold)
                .foregroundStyle(line.prefixColor)
                .frame(width: Layout.prefixColumnWidth, alignment: .center)

            DiffLineContent(line: line)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.vertical, 1)
        .background(line.backgroundColor)
    }


    public init(line: DiffLine) {
        self.line = line
    }
}

/// One diff line's text, either as highlighted spans or as a plain run.
///
/// Extracted from an `@ViewBuilder` computed property on `DiffLineView`. As its own `View` the
/// branch gets its own identity, so SwiftUI is not re-evaluating both arms of the choice
/// through the parent's body.
private struct DiffLineContent: View {
    let line: DiffLine

    var body: some View {
        if line.spans.isEmpty {
            Text(line.text.isEmpty ? " " : line.text)
                .font(.system(.body, design: .monospaced))
        } else {
            HStack(spacing: 0) {
                ForEach(Array(line.spans.enumerated()), id: \.offset) { _, span in
                    Text(span.text)
                        .font(.system(.body, design: .monospaced))
                        .background(span.isHighlighted ? line.highlightColor : .clear)
                }
            }
        }
    }
}
