//
//  StatisticBadge.swift
//  LintStudioUI
//
//  A badge displaying a labeled statistic value
//

import SwiftUI

public struct StatisticBadge: View {
    private enum Layout {
        static let spacing: CGFloat = 4
    }

    public let label: String
    public let value: String
    public let color: Color

    public var body: some View {
        VStack(spacing: Layout.spacing) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    public init(label: String, value: String, color: Color) {
        self.label = label
        self.value = value
        self.color = color
    }
}
