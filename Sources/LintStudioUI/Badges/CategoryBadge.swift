//
//  CategoryBadge.swift
//  LintStudioUI
//
//  A badge displaying a lint rule category
//

import LintStudioCore
import SwiftUI

public struct CategoryBadge<C: LintCategory>: View {
    public let category: C
    public let color: Color

    public var body: some View {
        Text(category.displayName)
            .font(.caption2)
            .padding(.horizontal, BadgeLayout.horizontalPadding)
            .padding(.vertical, BadgeLayout.verticalPadding)
            .background(color.opacity(BadgeLayout.backgroundOpacity))
            .foregroundStyle(color)
            .clipShape(.rect(cornerRadius: BadgeLayout.cornerRadius))
    }

    public init(category: C, color: Color) {
        self.category = category
        self.color = color
    }
}
