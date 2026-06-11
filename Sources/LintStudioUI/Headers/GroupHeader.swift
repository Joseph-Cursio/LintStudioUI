//
//  GroupHeader.swift
//  LintStudioUI
//
//  A group header with title, count, and proportional bar
//

import SwiftUI

public struct GroupHeader: View {
    private enum Layout {
        static let spacing: CGFloat = 8
        static let barCornerRadius: CGFloat = 3
        static let barHeight: CGFloat = 6
        static let barTrackWidth: CGFloat = 80
        static let barContainerHeight: CGFloat = 14
        static let minBarWidth: CGFloat = 3
        static let highRatioThreshold = 0.7
        static let mediumRatioThreshold = 0.3
    }

    public let title: String
    public let count: Int
    public let maxCount: Int

    public var body: some View {
        HStack(spacing: Layout.spacing) {
            Text(title)
                .font(.headline)
                .lineLimit(1)

            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: Layout.barCornerRadius)
                        .fill(Color(NSColor.separatorColor))
                        .frame(height: Layout.barHeight)

                    RoundedRectangle(cornerRadius: Layout.barCornerRadius)
                        .fill(barColor)
                        .frame(width: barWidth(in: geometry.size.width), height: Layout.barHeight)
                }
                .frame(height: geometry.size.height)
            }
            .frame(width: Layout.barTrackWidth, height: Layout.barContainerHeight)
        }
    }

    var barColor: Color {
        let ratio = maxCount > 0 ? Double(count) / Double(maxCount) : 0
        if ratio > Layout.highRatioThreshold {
            return .red
        }
        if ratio > Layout.mediumRatioThreshold {
            return .orange
        }
        return .yellow
    }

    public init(title: String, count: Int, maxCount: Int) {
        self.title = title
        self.count = count
        self.maxCount = maxCount
    }

    func barWidth(in totalWidth: CGFloat) -> CGFloat {
        guard maxCount > 0 else {
            return 0
        }
        let proportion = CGFloat(count) / CGFloat(maxCount)
        return max(proportion * totalWidth, Layout.minBarWidth)
    }
}
