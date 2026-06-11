//
//  PillBadge.swift
//  LintStudioUI
//
//  Shared "pill" styling for badge views
//

import SwiftUI

/// Applies the shared pill treatment used by badge views: compact padding, a
/// tinted translucent background, a matching foreground, and rounded corners.
/// Callers style their own text (font, weight) before applying this.
struct PillBadge: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, BadgeLayout.horizontalPadding)
            .padding(.vertical, BadgeLayout.verticalPadding)
            .background(color.opacity(BadgeLayout.backgroundOpacity))
            .foregroundStyle(color)
            .clipShape(.rect(cornerRadius: BadgeLayout.cornerRadius))
    }
}

extension View {
    /// Styles the view as a badge pill tinted with `color`.
    func pillBadge(color: Color) -> some View {
        modifier(PillBadge(color: color))
    }
}
