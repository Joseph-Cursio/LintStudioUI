//
//  ExportFormatTests.swift
//  LintStudioUITests
//
//  Tests for ExportFormat's metadata.
//

@testable import LintStudioUI
import Testing

@MainActor
@Suite("ExportFormat Tests")
struct ExportFormatTests {

    @Test("All three formats are present and stable")
    func allCases() {
        #expect(ExportFormat.allCases == [.csv, .html, .json])
    }

    @Test("id matches the raw value")
    func identifiable() {
        for format in ExportFormat.allCases {
            #expect(format.id == format.rawValue)
        }
    }

    @Test(
        "Each format reports the expected subtitle",
        arguments: [
            (ExportFormat.csv, "Spreadsheet"),
            (ExportFormat.html, "Interactive report"),
            (ExportFormat.json, "Machine-readable")
        ]
    )
    func subtitle(format: ExportFormat, expected: String) {
        #expect(format.subtitle == expected)
    }

    @Test(
        "Each format reports the expected SF Symbol",
        arguments: [
            (ExportFormat.csv, "tablecells"),
            (ExportFormat.html, "doc.richtext"),
            (ExportFormat.json, "curlybraces")
        ]
    )
    func iconName(format: ExportFormat, expected: String) {
        #expect(format.iconName == expected)
    }

    @Test(
        "fileExtension is the lowercased raw value",
        arguments: [
            (ExportFormat.csv, "csv"),
            (ExportFormat.html, "html"),
            (ExportFormat.json, "json")
        ]
    )
    func fileExtension(format: ExportFormat, expected: String) {
        #expect(format.fileExtension == expected)
    }
}
