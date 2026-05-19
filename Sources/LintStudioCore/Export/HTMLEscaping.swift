//
//  HTMLEscaping.swift
//  LintStudioCore
//
//  HTML entity escaping utility
//

/// HTML entity escaping for safe string interpolation in HTML output
public enum HTMLEscaping {
    /// Escapes HTML-significant characters (`&`, `<`, `>`, `"`) as entities.
    /// - Parameter text: The raw string to escape.
    /// - Returns: A string safe for interpolation into HTML.
    nonisolated public static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
