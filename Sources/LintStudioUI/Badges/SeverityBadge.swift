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

    public init(severity: S) {
        self.severity = severity
    }

    public var body: some View {
        Text(severity.rawValue.uppercased())
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(severityColor.opacity(0.2))
            .foregroundStyle(severityColor)
            .clipShape(.rect(cornerRadius: 4))
    }

    private var severityColor: Color {
        if severity.isError { return .red }
        if severity.isInfo { return .blue }
        return .orange
    }
}
