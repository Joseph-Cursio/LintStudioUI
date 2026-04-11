//
//  UnifiedDiffEngine.swift
//  LintStudioCore
//
//  LCS-based unified diff algorithm with character-level highlighting
//

/// Line-by-line diff engine using Longest Common Subsequence (LCS)
public enum UnifiedDiffEngine {
    public static func computeDiff(before: String, after: String) -> [DiffLine] {
        let oldLines = before.components(separatedBy: .newlines)
        let newLines = after.components(separatedBy: .newlines)

        let lcsTable = buildLCSTable(oldLines, newLines)
        var rawLines = buildDiffLines(oldLines, newLines, lcsTable)

        addInlineHighlights(&rawLines)

        return rawLines
    }

    // MARK: Line-level LCS

    private static func buildLCSTable(_ oldLines: [String], _ newLines: [String]) -> [[Int]] {
        let rowCount = oldLines.count + 1
        let colCount = newLines.count + 1
        var table = Array(repeating: Array(repeating: 0, count: colCount), count: rowCount)

        for idx in 1..<rowCount {
            for jdx in 1..<colCount {
                if oldLines[idx - 1] == newLines[jdx - 1] {
                    table[idx][jdx] = table[idx - 1][jdx - 1] + 1
                } else {
                    table[idx][jdx] = max(table[idx - 1][jdx], table[idx][jdx - 1])
                }
            }
        }
        return table
    }

    private static func buildDiffLines(
        _ oldLines: [String],
        _ newLines: [String],
        _ table: [[Int]]
    ) -> [DiffLine] {
        var result: [DiffLine] = []
        var idx = oldLines.count
        var jdx = newLines.count

        while idx > 0 || jdx > 0 {
            if idx > 0 && jdx > 0 && oldLines[idx - 1] == newLines[jdx - 1] {
                result.append(DiffLine(text: oldLines[idx - 1], kind: .unchanged))
                idx -= 1
                jdx -= 1
            } else if jdx > 0 && (idx == 0 || table[idx][jdx - 1] >= table[idx - 1][jdx]) {
                result.append(DiffLine(text: newLines[jdx - 1], kind: .added))
                jdx -= 1
            } else if idx > 0 {
                result.append(DiffLine(text: oldLines[idx - 1], kind: .removed))
                idx -= 1
            }
        }

        return result.reversed()
    }

    // MARK: Character-level inline highlights

    private static func addInlineHighlights(_ lines: inout [DiffLine]) {
        var idx = 0
        while idx < lines.count {
            var removedStart = idx
            while removedStart < lines.count && lines[removedStart].kind == .removed {
                removedStart += 1
            }
            let removedCount = removedStart - idx

            var addedEnd = removedStart
            while addedEnd < lines.count && lines[addedEnd].kind == .added {
                addedEnd += 1
            }
            let addedCount = addedEnd - removedStart

            if removedCount > 0 && addedCount > 0 {
                let pairCount = min(removedCount, addedCount)
                for pairIdx in 0..<pairCount {
                    let removedLineIdx = idx + pairIdx
                    let addedLineIdx = removedStart + pairIdx
                    let (removedSpans, addedSpans) = characterDiff(
                        old: lines[removedLineIdx].text,
                        new: lines[addedLineIdx].text
                    )
                    lines[removedLineIdx].spans = removedSpans
                    lines[addedLineIdx].spans = addedSpans
                }
                idx = addedEnd
            } else if removedCount > 0 {
                idx = removedStart
            } else {
                idx += 1
            }
        }
    }

    private static func characterDiff(
        old: String,
        new: String
    ) -> (oldSpans: [DiffSpan], newSpans: [DiffSpan]) {
        let oldChars = Array(old)
        let newChars = Array(new)

        let lcsSet = characterLCS(oldChars, newChars)

        let oldSpans = buildSpans(chars: oldChars, lcsIndices: lcsSet.old)
        let newSpans = buildSpans(chars: newChars, lcsIndices: lcsSet.new)

        return (oldSpans, newSpans)
    }

    private static func characterLCS(
        _ oldChars: [Character],
        _ newChars: [Character]
    ) -> (old: Set<Int>, new: Set<Int>) {
        let rowCount = oldChars.count + 1
        let colCount = newChars.count + 1
        var table = Array(repeating: Array(repeating: 0, count: colCount), count: rowCount)

        for idx in 1..<rowCount {
            for jdx in 1..<colCount {
                if oldChars[idx - 1] == newChars[jdx - 1] {
                    table[idx][jdx] = table[idx - 1][jdx - 1] + 1
                } else {
                    table[idx][jdx] = max(table[idx - 1][jdx], table[idx][jdx - 1])
                }
            }
        }

        var oldIndices = Set<Int>()
        var newIndices = Set<Int>()
        var idx = oldChars.count
        var jdx = newChars.count

        while idx > 0 && jdx > 0 {
            if oldChars[idx - 1] == newChars[jdx - 1] {
                oldIndices.insert(idx - 1)
                newIndices.insert(jdx - 1)
                idx -= 1
                jdx -= 1
            } else if table[idx - 1][jdx] > table[idx][jdx - 1] {
                idx -= 1
            } else {
                jdx -= 1
            }
        }

        return (oldIndices, newIndices)
    }

    private static func buildSpans(chars: [Character], lcsIndices: Set<Int>) -> [DiffSpan] {
        guard !chars.isEmpty else { return [] }

        var spans: [DiffSpan] = []
        var currentText = ""
        var currentHighlighted = !lcsIndices.contains(0)

        for (charIdx, char) in chars.enumerated() {
            let isHighlighted = !lcsIndices.contains(charIdx)

            if isHighlighted == currentHighlighted {
                currentText.append(char)
            } else {
                if !currentText.isEmpty {
                    spans.append(DiffSpan(text: currentText, isHighlighted: currentHighlighted))
                }
                currentText = String(char)
                currentHighlighted = isHighlighted
            }
        }

        if !currentText.isEmpty {
            spans.append(DiffSpan(text: currentText, isHighlighted: currentHighlighted))
        }

        return spans
    }
}
