//
//  DiffSpan.swift
//  LintStudioCore
//
//  A span within a diff line, either highlighted (changed) or normal
//

/// A span within a line, either highlighted (changed) or normal
public struct DiffSpan: Sendable {
    public let text: String
    public let isHighlighted: Bool

    public init(text: String, isHighlighted: Bool) {
        self.text = text
        self.isHighlighted = isHighlighted
    }
}
