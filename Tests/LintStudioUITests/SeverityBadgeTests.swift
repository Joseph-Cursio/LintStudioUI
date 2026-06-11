//
//  SeverityBadgeTests.swift
//  LintStudioUITests
//
//  Tests for SeverityBadge's severity-to-color mapping.
//

import LintStudioCore
@testable import LintStudioUI
import SwiftUI
import Testing

@MainActor
@Suite("SeverityBadge Tests")
struct SeverityBadgeTests {

    /// Minimal LintSeverity fixture covering the error/info/other branches.
    private enum Severity: String, LintSeverity {
        case error
        case warning
        case info

        var displayName: String { rawValue.capitalized }
        var isError: Bool { self == .error }
        var isInfo: Bool { self == .info }
    }

    @Test("Error severities render red")
    func errorIsRed() {
        #expect(SeverityBadge(severity: Severity.error).severityColor == Color.red)
    }

    @Test("Info severities render blue")
    func infoIsBlue() {
        #expect(SeverityBadge(severity: Severity.info).severityColor == Color.blue)
    }

    @Test("Other severities fall back to orange")
    func otherIsOrange() {
        #expect(SeverityBadge(severity: Severity.warning).severityColor == Color.orange)
    }

    @Test("Error takes precedence even if a severity were also info")
    func errorWinsOverInfo() {
        // isError is checked before isInfo, so an error-and-info severity is red.
        struct ErrorAndInfo: LintSeverity {
            let rawValue = "fatal"
            var displayName: String { "Fatal" }
            var isError: Bool { true }
            var isInfo: Bool { true }
        }
        #expect(SeverityBadge(severity: ErrorAndInfo()).severityColor == Color.red)
    }
}
