//
//  GroupHeaderTests.swift
//  LintStudioUITests
//
//  Tests for GroupHeader's proportional bar color and width.
//

@testable import LintStudioUI
import SwiftUI
import Testing

@MainActor
@Suite("GroupHeader Tests")
struct GroupHeaderTests {

    private func header(count: Int, maxCount: Int) -> GroupHeader {
        GroupHeader(title: "Rule", count: count, maxCount: maxCount)
    }

    // MARK: - barColor

    @Test("Ratio above 0.7 is red")
    func highRatioIsRed() {
        #expect(header(count: 8, maxCount: 10).barColor == Color.red)
    }

    @Test("Ratio above 0.3 (but not 0.7) is orange")
    func mediumRatioIsOrange() {
        #expect(header(count: 5, maxCount: 10).barColor == Color.orange)
    }

    @Test("Ratio at or below 0.3 is yellow")
    func lowRatioIsYellow() {
        #expect(header(count: 2, maxCount: 10).barColor == Color.yellow)
    }

    @Test("A zero maxCount yields a zero ratio and is yellow")
    func zeroMaxIsYellow() {
        #expect(header(count: 0, maxCount: 0).barColor == Color.yellow)
    }

    // MARK: - barWidth

    @Test("Width is proportional to the count/maxCount ratio")
    func proportionalWidth() {
        #expect(header(count: 5, maxCount: 10).barWidth(in: 80) == 40)
    }

    @Test("A tiny proportion is clamped to the minimum bar width")
    func clampsToMinimum() {
        #expect(header(count: 1, maxCount: 1000).barWidth(in: 80) == 3)
    }

    @Test("A zero maxCount produces zero width")
    func zeroMaxIsZeroWidth() {
        #expect(header(count: 5, maxCount: 0).barWidth(in: 80) == 0)
    }
}
