//
//  ExportFormat.swift
//  LintStudioUI
//
//  Available export formats for lint reports
//

import SwiftUI

public enum ExportFormat: String, CaseIterable, Identifiable, Sendable {
    case csv = "CSV"
    case html = "HTML"
    case json = "JSON"

    public var id: String { rawValue }

    public var subtitle: String {
        switch self {
        case .csv:
            "Spreadsheet"

        case .html:
            "Interactive report"

        case .json:
            "Machine-readable"
        }
    }

    public var iconName: String {
        switch self {
        case .csv:
            "tablecells"

        case .html:
            "doc.richtext"

        case .json:
            "curlybraces"
        }
    }

    public var fileExtension: String {
        rawValue.lowercased()
    }
}
