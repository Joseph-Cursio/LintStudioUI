//
//  ExportFormat.swift
//  LintStudioUI
//
//  Available export formats for lint reports
//

import SwiftUI

public enum ExportFormat: String, CaseIterable, Identifiable, Sendable {
    case html = "HTML"
    case json = "JSON"
    case csv = "CSV"

    public var id: String { rawValue }

    public var subtitle: String {
        switch self {
        case .html:
            "Interactive report"

        case .json:
            "Machine-readable"

        case .csv:
            "Spreadsheet"
        }
    }

    public var iconName: String {
        switch self {
        case .html:
            "doc.richtext"

        case .json:
            "curlybraces"

        case .csv:
            "tablecells"
        }
    }

    public var fileExtension: String {
        rawValue.lowercased()
    }
}
