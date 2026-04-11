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
}
