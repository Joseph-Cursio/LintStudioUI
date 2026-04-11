//
//  GroupHeader.swift
//  LintStudioUI
//
//  A group header with title, count, and proportional bar
//

import SwiftUI

public struct GroupHeader: View {
    public let title: String
    public let count: Int
    public let maxCount: Int

    public init(title: String, count: Int, maxCount: Int) {
        self.title = title
        self.count = count
        self.maxCount = maxCount
    }

    public var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .lineLimit(1)

            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(NSColor.separatorColor))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(width: barWidth(in: geometry.size.width), height: 6)
                }
                .frame(height: geometry.size.height)
            }
            .frame(width: 80, height: 14)
        }
    }

    private var barColor: Color {
        let ratio = maxCount > 0 ? Double(count) / Double(maxCount) : 0
        if ratio > 0.7 { return .red }
        if ratio > 0.3 { return .orange }
        return .yellow
    }

    private func barWidth(in totalWidth: CGFloat) -> CGFloat {
        guard maxCount > 0 else { return 0 }
        let proportion = CGFloat(count) / CGFloat(maxCount)
        return max(proportion * totalWidth, 3)
    }
}
