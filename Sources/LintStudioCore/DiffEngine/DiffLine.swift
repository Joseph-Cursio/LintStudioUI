//
//  DiffLine.swift
//  LintStudioCore
//
//  Represents a single line in a unified diff
//

/// A single line in a unified diff, with optional character-level spans
public struct DiffLine: Sendable {
    public enum Kind: Sendable {
        case added
        case removed
        case unchanged
    }

    public let text: String
    public let kind: Kind
    /// Character-level spans for inline highlighting (empty = no inline diff)
    public var spans: [DiffSpan]

    public init(text: String, kind: Kind, spans: [DiffSpan] = []) {
        self.text = text
        self.kind = kind
        self.spans = spans
    }

    public var prefix: String {
        switch kind {
        case .added: "+"
        case .removed: "\u{2212}"
        case .unchanged: " "
        }
    }
}
