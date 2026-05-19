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
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.red.opacity(0.12))
                    .frame(width: 12, height: 12)
                Text(beforeLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 12, height: 12)
                Text(afterLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
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
        .padding(.vertical, 4)
    }
}
