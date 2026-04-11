//
//  DiffLineView.swift
//  LintStudioUI
//
//  View for rendering a single diff line with optional character-level highlighting
//

import SwiftUI
import LintStudioCore

public struct DiffLineView: View {
    public let line: DiffLine

    public init(line: DiffLine) {
        self.line = line
    }

    public var body: some View {
        HStack(spacing: 0) {
            Text(line.prefix)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.bold)
                .foregroundStyle(line.prefixColor)
                .frame(width: 20, alignment: .center)

            lineContent
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 1)
        .background(line.backgroundColor)
    }

    @ViewBuilder
    private var lineContent: some View {
        if let spans = line.spans, !spans.isEmpty {
            HStack(spacing: 0) {
                ForEach(Array(spans.enumerated()), id: \.offset) { _, span in
                    Text(span.text)
                        .font(.system(.body, design: .monospaced))
                        .background(span.isHighlighted ? line.highlightColor : .clear)
                }
            }
        } else {
            Text(line.text.isEmpty ? " " : line.text)
                .font(.system(.body, design: .monospaced))
        }
    }
}
