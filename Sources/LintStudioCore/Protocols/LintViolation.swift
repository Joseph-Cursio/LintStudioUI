//
//  LintViolation.swift
//  LintStudioCore
//
//  Protocol for lint violations
//

import Foundation

public protocol LintViolation: Identifiable, Sendable {
    associatedtype SeverityType: LintSeverity
    var identifier: UUID { get }
    var ruleIdentifier: String { get }
    var filePath: String { get }
    var line: Int { get }
    var column: Int? { get }
    var severity: SeverityType { get }
    var message: String { get }
}
