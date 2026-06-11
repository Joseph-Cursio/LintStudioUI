//
//  SeverityBadge.swift
//  LintStudioUI
//
//  A badge displaying a lint severity level
//

import LintStudioCore
import SwiftUI

public struct SeverityBadge<S: LintSeverity>: View {
    public let severity: S

    public var body: some View {
        Text(severity.rawValue.uppercased())
            .font(.caption2)
            .fontWeight(.semibold)
            .pillBadge(color: severityColor)
    }

    var severityColor: Color {
        if severity.isError {
            return .red
        }
        if severity.isInfo {
            return .blue
        }
        return .orange
    }

    public init(severity: S) {
        self.severity = severity
    }
}
