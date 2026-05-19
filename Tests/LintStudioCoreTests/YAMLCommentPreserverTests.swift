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

    @Test("Appends orphaned comments at the end")
    func orphanedComments() {
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

        // Both comments are orphaned since their keys aren't in the output
        #expect(result.contains("# Trailing note"))
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
