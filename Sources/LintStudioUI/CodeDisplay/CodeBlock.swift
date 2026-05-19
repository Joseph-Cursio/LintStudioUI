//
//  CodeBlock.swift
//  LintStudioUI
//
//  A code snippet block with a colored sidebar indicator
//

import SwiftUI

public struct CodeBlock: View {
    private enum Layout {
        static let sidebarWidth: CGFloat = 4
        static let textPadding: CGFloat = 12
        static let cornerRadius: CGFloat = 4
        static let borderWidth: CGFloat = 1
        static let borderOpacity = 0.3
    }

    public let code: String
    public let isError: Bool

    public var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(isError ? Color.red : Color.green)
                .frame(width: Layout.sidebarWidth)

            Text(code)
                .font(.system(.body, design: .monospaced))
                .padding(Layout.textPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.textBackgroundColor))
        }
        .clipShape(.rect(cornerRadius: Layout.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(borderColor, lineWidth: Layout.borderWidth)
        )
    }

    private var borderColor: Color {
        isError
            ? Color.red.opacity(Layout.borderOpacity)
            : Color.green.opacity(Layout.borderOpacity)
    }

    public init(code: String, isError: Bool) {
        self.code = code
        self.isError = isError
    }
}
