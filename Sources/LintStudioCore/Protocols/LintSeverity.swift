//
//  LintSeverity.swift
//  LintStudioCore
//
//  Protocol for lint rule severities
//

public protocol LintSeverity: Hashable {
    var rawValue: String { get }
    var displayName: String { get }
    var isError: Bool { get }
    var isInfo: Bool { get }
}

public extension LintSeverity {
    /// Default: most severities are not info-level
    var isInfo: Bool { false }
}
