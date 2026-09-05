//
//  UnifiedDiffContentView.swift
//  LintStudioUI
//
//  Line-by-line unified diff view with GitHub-style green/red highlighting
//

import LintStudioCore
import SwiftUI

public struct UnifiedDiffContentView: View {
    public let before: String
    public let after: String
    public var beforeLabel: String
    public var afterLabel: String

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                DiffLegend(beforeLabel: beforeLabel, afterLabel: afterLabel)
                Divider()
                DiffLinesList(before: before, after: after)
            }
        }
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

/// The red/green swatch key above the diff.
///
/// Extracted from a computed `some View` property on `UnifiedDiffContentView`. As its own
/// `View` it gets its own identity, so SwiftUI can leave it alone when only the diff body
/// changes — which is the whole of the `Computed Property View` rule's argument.
private struct DiffLegend: View {
    let beforeLabel: String
    let afterLabel: String

    private enum Layout {
        static let legendSpacing: CGFloat = 16
        static let swatchSpacing: CGFloat = 4
        static let swatchCornerRadius: CGFloat = 2
        static let swatchSize: CGFloat = 12
        static let verticalPadding: CGFloat = 8
        static let swatchOpacity = 0.12
    }

    var body: some View {
        HStack(spacing: Layout.legendSpacing) {
            swatch(color: .red, label: beforeLabel)
            swatch(color: .green, label: afterLabel)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, Layout.verticalPadding)
    }

    private func swatch(color: Color, label: String) -> some View {
        HStack(spacing: Layout.swatchSpacing) {
            RoundedRectangle(cornerRadius: Layout.swatchCornerRadius)
                .fill(color.opacity(Layout.swatchOpacity))
                .frame(width: Layout.swatchSize, height: Layout.swatchSize)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

/// The diff itself, one row per line.
private struct DiffLinesList: View {
    let before: String
    let after: String

    private enum Layout {
        static let verticalPadding: CGFloat = 4
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(UnifiedDiffEngine.computeDiff(before: before, after: after).enumerated()),
                    id: \.offset) { _, line in
                DiffLineView(line: line)
            }
        }
        .padding(.vertical, Layout.verticalPadding)
    }
}
