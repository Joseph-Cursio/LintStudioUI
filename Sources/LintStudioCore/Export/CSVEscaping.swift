//
//  CSVEscaping.swift
//  LintStudioCore
//
//  CSV field escaping utility
//

/// CSV field escaping for safe value encoding
public enum CSVEscaping {
    public static func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
