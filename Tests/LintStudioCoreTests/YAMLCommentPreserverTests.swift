//
//  YAMLCommentPreserverTests.swift
//  LintStudioCoreTests
//
//  Tests for YAML comment extraction and reinsertion
//

import Foundation
@testable import LintStudioCore
import Testing

@MainActor
@Suite("YAMLCommentPreserver Tests")
struct YAMLCommentPreserverTests {
    @Test("Extracts comments from YAML content")
    func extractsComments() {
        let yaml = """
        # Global settings
        disabled_rules:
          - force_cast
        # Opt-in rules section
        opt_in_rules:
          - empty_count
        """
        let preserver = YAMLCommentPreserver(yamlContent: yaml)

        #expect(preserver.comments.count == 2)
        #expect(preserver.comments[0].line == "# Global settings")
        #expect(preserver.comments[0].followingKey == "disabled_rules")
        #expect(preserver.comments[1].line == "# Opt-in rules section")
        #expect(preserver.comments[1].followingKey == "opt_in_rules")
    }

    @Test("Extracts top-level key order")
    func extractsKeyOrder() {
        let yaml = """
        disabled_rules:
          - force_cast
        opt_in_rules:
          - empty_count
        excluded:
          - Pods
        """
        let preserver = YAMLCommentPreserver(yamlContent: yaml)

        #expect(preserver.keyOrder == ["disabled_rules", "opt_in_rules", "excluded"])
    }

    @Test("Reinserts comments before their associated keys")
    func reinsertsComments() {
        let original = """
        # Global settings
        disabled_rules:
          - force_cast
        # Opt-in rules
        opt_in_rules:
          - empty_count
        """
        let preserver = YAMLCommentPreserver(yamlContent: original)

        let serialized = """
        disabled_rules:
          - force_cast
        opt_in_rules:
          - empty_count
        """
        let result = preserver.reinsertComments(into: serialized)

        #expect(result.contains("# Global settings\ndisabled_rules:"))
        #expect(result.contains("# Opt-in rules\nopt_in_rules:"))
    }

    @Test("Handles YAML with no comments")
    func noComments() {
        let yaml = """
        disabled_rules:
          - force_cast
        """
        let preserver = YAMLCommentPreserver(yamlContent: yaml)

        #expect(preserver.comments.isEmpty)

        let result = preserver.reinsertComments(into: yaml)
        #expect(result == yaml)
    }

    @Test("Handles empty YAML content")
    func emptyContent() {
        let preserver = YAMLCommentPreserver(yamlContent: "")

        #expect(preserver.comments.isEmpty)
        #expect(preserver.keyOrder.isEmpty)
    }

    @Test("Discards orphaned comments instead of appending them")
    func orphanedCommentsDiscarded() {
        let original = """
        # This comment has no matching key
        disabled_rules:
          - force_cast
        # Trailing note
        """
        let preserver = YAMLCommentPreserver(yamlContent: original)

        let serialized = """
        opt_in_rules:
          - empty_count
        """
        let result = preserver.reinsertComments(into: serialized)

        // Both source comments anchor to keys absent from the output, so they
        // are dropped rather than appended — the output is left untouched.
        #expect(result.contains("# This comment has no matching key") == false)
        #expect(result.contains("# Trailing note") == false)
        #expect(result == serialized)
    }

    @Test("Dropping an orphaned comment leaves the trailing layout intact")
    func orphanedCommentDoesNotCorruptTrailingLayout() {
        let original = """
        # Built-in rules we deliberately disable
        disabled_rules:
          - todo
        """
        let preserver = YAMLCommentPreserver(yamlContent: original)

        // `disabled_rules` is absent from the serialized output; its comment
        // must not be appended after a blank line at end-of-file.
        let serialized = "opt_in_rules:\n  - empty_count\n"
        let result = preserver.reinsertComments(into: serialized)

        #expect(result == serialized)
        #expect(result.hasSuffix("\n"))
        #expect(result.contains("# Built-in rules we deliberately disable") == false)
    }

    @Test("Preserves inline comment whitespace")
    func preservesWhitespace() {
        let yaml = """
          # Indented comment
        rules:
          - force_cast
        """
        let preserver = YAMLCommentPreserver(yamlContent: yaml)

        #expect(preserver.comments[0].line == "  # Indented comment")
    }
}
