//
//  LintCategory.swift
//  LintStudioCore
//
//  Protocol for lint rule categories
//

public protocol LintCategory: Hashable {
    var rawValue: String { get }
    var displayName: String { get }
}
