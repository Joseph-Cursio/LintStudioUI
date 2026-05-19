//
//  CSVEscaping.swift
//  LintStudioCore
//
//  CSV field escaping utility
//

/// CSV field escaping for safe value encoding
public enum CSVEscaping {
    /// Escapes a value for safe inclusion as a CSV field.
    /// - Parameter value: The raw field value.
    /// - Returns: The value quoted and escaped if it contains a comma, quote, or newline.
    nonisolated public static func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
