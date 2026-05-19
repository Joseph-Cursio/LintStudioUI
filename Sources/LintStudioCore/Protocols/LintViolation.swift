//
//  LintViolation.swift
//  LintStudioCore
//
//  Protocol for lint violations
//

import Foundation

/// A single violation reported by a lint rule.
public protocol LintViolation {
    /// The severity type this violation is classified by.
    associatedtype SeverityType: LintSeverity

    /// A stable unique identifier for this violation instance.
    var identifier: UUID { get }
    /// The identifier of the rule that produced this violation.
    var ruleIdentifier: String { get }
    /// The path of the file the violation was found in.
    var filePath: String { get }
    /// The 1-based line number of the violation.
    var line: Int { get }
    /// The 1-based column number of the violation, if known.
    var column: Int? { get }
    /// The severity of the violation.
    var severity: SeverityType { get }
    /// A human-readable description of the violation.
    var message: String { get }
}
