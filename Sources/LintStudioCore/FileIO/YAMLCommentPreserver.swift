//
//  YAMLCommentPreserver.swift
//  LintStudioCore
//
//  Extracts and reinserts YAML comments across parse/serialize cycles
//

import Foundation

/// Preserves YAML comments that would otherwise be lost during parsing.
///
/// YAML parsers (including Yams) discard comments. This utility extracts
/// comment lines and their positions from the original file, then reinserts
/// them into the serialized output at matching locations.
public struct YAMLCommentPreserver: Sendable {

    /// A comment line with its original context.
    public struct CommentEntry: Sendable {
        /// The full comment line (including `#` prefix and whitespace).
        public let line: String
        /// The YAML key on the line immediately following this comment, if any.
        public let followingKey: String?

        public init(line: String, followingKey: String?) {
            self.line = line
            self.followingKey = followingKey
        }
    }

    /// The extracted comments from the original YAML content.
    public let comments: [CommentEntry]

    /// The ordering of top-level keys in the original YAML content.
    public let keyOrder: [String]

    /// Extracts comments and key ordering from raw YAML content.
    public init(yamlContent: String) {
        let lines = yamlContent.components(separatedBy: .newlines)
        var extracted: [CommentEntry] = []
        var keys: [String] = []

        for (idx, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Track top-level key order
            if !trimmed.hasPrefix("#") && !trimmed.isEmpty && !line.hasPrefix(" ") {
                if let colonIndex = trimmed.firstIndex(of: ":") {
                    let key = String(trimmed[trimmed.startIndex..<colonIndex])
                        .trimmingCharacters(in: .whitespaces)
                    if !key.isEmpty {
                        keys.append(key)
                    }
                }
            }

            // Extract comment lines
            if trimmed.hasPrefix("#") {
                let followingKey = Self.findFollowingKey(
                    lines: lines,
                    afterIndex: idx
                )
                extracted.append(CommentEntry(line: line, followingKey: followingKey))
            }
        }

        self.comments = extracted
        self.keyOrder = keys
    }

    /// Reinserts preserved comments into serialized YAML output.
    ///
    /// Comments are placed before their associated key. Comments without
    /// a matching key are appended at the end.
    public func reinsertComments(into yamlContent: String) -> String {
        var lines = yamlContent.components(separatedBy: .newlines)
        var insertions: [(index: Int, comment: String)] = []

        for entry in comments {
            if let key = entry.followingKey {
                // Find the line with this key in the output
                if let targetIdx = lines.firstIndex(where: { line in
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    return trimmed.hasPrefix(key + ":") || trimmed.hasPrefix("\"\(key)\":")
                }) {
                    insertions.append((index: targetIdx, comment: entry.line))
                }
            }
        }

        // Insert in reverse order to preserve indices
        for insertion in insertions.sorted(by: { $0.index > $1.index }) {
            lines.insert(insertion.comment, at: insertion.index)
        }

        // Append orphaned comments (no matching key found)
        let insertedComments = Set(insertions.map(\.comment))
        let orphaned = comments.filter { !insertedComments.contains($0.line) }
        if !orphaned.isEmpty {
            lines.append("")
            for entry in orphaned {
                lines.append(entry.line)
            }
        }

        return lines.joined(separator: "\n")
    }

    /// Finds the YAML key on the first non-comment, non-empty line after the given index.
    private static func findFollowingKey(lines: [String], afterIndex: Int) -> String? {
        for idx in (afterIndex + 1)..<lines.count {
            let trimmed = lines[idx].trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            if trimmed.hasPrefix("#") { continue }
            if let colonIndex = trimmed.firstIndex(of: ":") {
                let key = String(trimmed[trimmed.startIndex..<colonIndex])
                    .trimmingCharacters(in: .whitespaces)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                return key.isEmpty ? nil : key
            }
            return nil
        }
        return nil
    }
}
