import Foundation
import CoreGraphics

/// Only immutable copies of CGPaths cross the actor boundary. No mutable path is retained.
struct PreparedStrokes: @unchecked Sendable {
    let outlines: [CGPath]
    let medians: [CGPath]
    let timeline: StrokeTimeline

    init(strokes: StrokeSet, expectedCount: Int) throws {
        try strokes.validate(expectedCount: expectedCount)
        guard expectedCount > 0 else { throw SVGPathParser.ParseError.invalidPath }
        outlines = try strokes.strokes.map {
            try Task.checkCancellation()
            return try SVGPathParser.parse($0)
        }
        var paths: [CGPath] = []
        var lengths: [Double] = []
        for points in strokes.medians {
            try Task.checkCancellation()
            guard points.count >= 2 else { throw SVGPathParser.ParseError.invalidPath }
            let path = CGMutablePath()
            let first = CGPoint(x: points[0][0], y: points[0][1])
            path.move(to: SVGPathParser.point(first))
            var length = 0.0
            for index in 1..<points.count {
                let previous = points[index - 1]
                let next = points[index]
                length += hypot(next[0] - previous[0], next[1] - previous[1])
                path.addLine(to: SVGPathParser.point(CGPoint(x: next[0], y: next[1])))
            }
            guard length.isFinite, length > 0, let immutable = path.copy() else {
                throw SVGPathParser.ParseError.invalidPath
            }
            paths.append(immutable)
            lengths.append(length)
        }
        medians = paths
        timeline = StrokeTimeline(medianLengths: lengths)
    }
}
