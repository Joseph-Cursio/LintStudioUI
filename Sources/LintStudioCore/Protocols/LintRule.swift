//
//  LintRule.swift
//  LintStudioCore
//
//  Protocol for lint rules
//

public protocol LintRule: Identifiable, Sendable {
    associatedtype CategoryType: LintCategory
    var identifier: String { get }
    var name: String { get }
    var ruleDescription: String { get }
    var category: CategoryType { get }
    var isEnabled: Bool { get }
    var supportsAutocorrection: Bool { get }
}
