//
//  SummaryCard.swift
//  LintStudioUI
//
//  A card displaying a summary statistic with title, count, and subtitle
//

import SwiftUI

public struct SummaryCard: View {
    public let title: String
    public let count: Int
    public let subtitle: String
    public let color: Color

    public init(title: String, count: Int, subtitle: String, color: Color) {
        self.title = title
        self.count = count
        self.subtitle = subtitle
        self.color = color
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .tracking(0.5)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(count)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(color)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(color.opacity(0.2), lineWidth: 0.5)
        )
    }
}
