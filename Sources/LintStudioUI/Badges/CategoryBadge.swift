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
            .pillBadge(color: color)
    }

    public init(category: C, color: Color) {
        self.category = category
        self.color = color
    }
}
