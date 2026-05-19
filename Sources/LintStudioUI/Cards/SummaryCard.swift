//
//  SummaryCard.swift
//  LintStudioUI
//
//  A card displaying a summary statistic with title, count, and subtitle
//

import SwiftUI

public struct SummaryCard: View {
    private enum Layout {
        static let contentSpacing: CGFloat = 4
        static let valueSpacing: CGFloat = 6
        static let padding: CGFloat = 12
        static let minHeight: CGFloat = 60
        static let cornerRadius: CGFloat = 10
        static let titleTracking: CGFloat = 0.5
        static let borderWidth: CGFloat = 0.5
        static let backgroundOpacity = 0.08
        static let borderOpacity = 0.2
    }

    public let title: String
    public let count: Int
    public let subtitle: String
    public let color: Color

    public var body: some View {
        VStack(alignment: .leading, spacing: Layout.contentSpacing) {
            Text(title)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .tracking(Layout.titleTracking)

            HStack(alignment: .firstTextBaseline, spacing: Layout.valueSpacing) {
                Text("\(count)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(color)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Layout.padding)
        .frame(maxWidth: .infinity, minHeight: Layout.minHeight, alignment: .leading)
        .background(color.opacity(Layout.backgroundOpacity))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .strokeBorder(color.opacity(Layout.borderOpacity), lineWidth: Layout.borderWidth)
        )
    }

    public init(title: String, count: Int, subtitle: String, color: Color) {
        self.title = title
        self.count = count
        self.subtitle = subtitle
        self.color = color
    }
}
