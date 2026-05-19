//
//  LintRule.swift
//  LintStudioCore
//
//  Protocol for lint rules
//

/// A lint rule that can be evaluated against source code.
public protocol LintRule {
    /// The category type this rule is classified by.
    associatedtype CategoryType: LintCategory

    /// A stable unique identifier for the rule.
    var identifier: String { get }
    /// The human-readable name of the rule.
    var name: String { get }
    /// A description of what the rule checks for.
    var ruleDescription: String { get }
    /// The category this rule belongs to.
    var category: CategoryType { get }
    /// Whether the rule is currently enabled.
    var isEnabled: Bool { get }
    /// Whether the rule supports automatic correction.
    var supportsAutocorrection: Bool { get }
}
