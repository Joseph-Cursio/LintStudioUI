//
//  UnifiedDiffContentView.swift
//  LintStudioUI
//
//  Line-by-line unified diff view with GitHub-style green/red highlighting
//

import LintStudioCore
import SwiftUI

public struct UnifiedDiffContentView: View {
    private enum Layout {
        static let legendSpacing: CGFloat = 16
        static let swatchSpacing: CGFloat = 4
        static let swatchCornerRadius: CGFloat = 2
        static let swatchSize: CGFloat = 12
        static let legendVerticalPadding: CGFloat = 8
        static let linesVerticalPadding: CGFloat = 4
        static let swatchOpacity = 0.12
    }

    public let before: String
    public let after: String
    public var beforeLabel: String
    public var afterLabel: String

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                diffLegend
                Divider()
                diffLinesList
            }
        }
    }

    private var diffLegend: some View {
        HStack(spacing: Layout.legendSpacing) {
            HStack(spacing: Layout.swatchSpacing) {
                RoundedRectangle(cornerRadius: Layout.swatchCornerRadius)
                    .fill(Color.red.opacity(Layout.swatchOpacity))
                    .frame(width: Layout.swatchSize, height: Layout.swatchSize)
                Text(beforeLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: Layout.swatchSpacing) {
                RoundedRectangle(cornerRadius: Layout.swatchCornerRadius)
                    .fill(Color.green.opacity(Layout.swatchOpacity))
                    .frame(width: Layout.swatchSize, height: Layout.swatchSize)
                Text(afterLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, Layout.legendVerticalPadding)
    }

    private var diffLinesList: some View {
        let diffLines = UnifiedDiffEngine.computeDiff(
            before: before,
            after: after
        )

        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(diffLines.enumerated()), id: \.offset) { _, line in
                DiffLineView(line: line)
            }
        }
        .padding(.vertical, Layout.linesVerticalPadding)
    }

    public init(
        before: String,
        after: String,
        beforeLabel: String = "Before",
        afterLabel: String = "After"
    ) {
        self.before = before
        self.after = after
        self.beforeLabel = beforeLabel
        self.afterLabel = afterLabel
    }
}
