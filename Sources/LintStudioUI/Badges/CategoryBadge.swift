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
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(.rect(cornerRadius: 4))
    }

    public init(category: C, color: Color) {
        self.category = category
        self.color = color
    }
}
