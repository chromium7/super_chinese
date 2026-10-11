import XCTest
import CoreGraphics

final class StrokeTests: XCTestCase {
    private func directory() throws -> URL {
        try XCTUnwrap(Bundle(for: Self.self).resourceURL?.appendingPathComponent("Data", isDirectory: true))
    }

    func testEveryBundledStrokeProducesNativeGeometryWithMatchingMedians() throws {
        let directory = try directory()
        let characters = try JSONDecoder().decode([Hanzi].self, from: Data(contentsOf: directory.appendingPathComponent("characters.v1.json")))
        let records = try JSONDecoder().decode([String: StrokeSet].self, from: Data(contentsOf: directory.appendingPathComponent("strokes.v1.json")))
        var strokeCount = 0
        for character in characters {
            let strokes = try XCTUnwrap(records[character.id])
            let prepared = try PreparedStrokes(strokes: strokes, expectedCount: character.strokeCount)
            XCTAssertEqual(prepared.outlines.count, character.strokeCount)
            XCTAssertEqual(prepared.medians.count, character.strokeCount)
            for path in prepared.outlines {
                XCTAssertFalse(path.isEmpty, character.id)
                XCTAssertGreaterThan(path.boundingBoxOfPath.width * path.boundingBoxOfPath.height, 0, character.id)
            }
            for path in prepared.medians { XCTAssertFalse(path.isEmpty, character.id) }
            XCTAssertTrue(prepared.timeline.durations.allSatisfy { $0.isFinite && $0 > 0.220 })
            strokeCount += prepared.outlines.count
        }
        XCTAssertEqual(characters.count, 213)
        XCTAssertEqual(strokeCount, 1640)
    }

    func testParserFlipsAndScalesEveryCurvePoint() throws {
        let path = try SVGPathParser.parse("M 0 900 L 1024 900 Q 512 388 1024 -124 C 0 900 512 388 0 -124 Z", canvasSide: 270)
        var points: [CGPoint] = []
        var types: [CGPathElementType] = []
        path.applyWithBlock { pointer in
            let element = pointer.pointee
            types.append(element.type)
            let count: Int
            switch element.type {
            case .moveToPoint, .addLineToPoint: count = 1
            case .addQuadCurveToPoint: count = 2
            case .addCurveToPoint: count = 3
            case .closeSubpath: count = 0
            @unknown default: count = 0
            }
            for index in 0..<count { points.append(element.points[index]) }
        }
        XCTAssertEqual(types, [.moveToPoint, .addLineToPoint, .addQuadCurveToPoint, .addCurveToPoint, .closeSubpath])
        XCTAssertEqual(points, [CGPoint(x: 0, y: 0), CGPoint(x: 270, y: 0),
                                CGPoint(x: 135, y: 135), CGPoint(x: 270, y: 270),
                                CGPoint(x: 0, y: 0), CGPoint(x: 135, y: 135), CGPoint(x: 0, y: 270)])
    }

    func testParserSupportsRelativeRepeatedArgumentsAndSVGNumbers() throws {
        let compact = try SVGPathParser.parse("m.5,9e2 10-10 l5 5 5-5 q1 2 3 4 1 2 3 4 c1 2 3 4 5 6 z l1 2")
        let absolute = try SVGPathParser.parse("M .5 900 L 10.5 890 L 15.5 895 L 20.5 890 Q 21.5 892 23.5 894 Q 24.5 896 26.5 898 C 27.5 900 29.5 902 31.5 904 Z L 1.5 902")
        XCTAssertEqual(compact, absolute)
    }

    func testParserRejectsUnsupportedIncompleteAndNonfinitePaths() {
        for source in ["", "M 0 0", "L 1 1", "M 0", "M 0 0 L 1", "M 0 0 Q 1 2 3",
                       "M 0 0 C 1 2 3 4 5", "M 0 0 H 4", "M 0 0 L 1e 2", "M 0 0 L 1e999 2",
                       "M 0 0 L NaN 2", "M 0 0 L 1 2 Z 3 4", "M 0 0 L 1 2 garbage"] {
            XCTAssertThrowsError(try SVGPathParser.parse(source), source)
        }
        XCTAssertThrowsError(try SVGPathParser.parse("M0 0L1 1", canvasSide: 0))
    }

    func testPreparationRejectsCountMismatchesAndUnusableMedians() {
        let outline = "M0 0L10 10L20 0Z"
        XCTAssertThrowsError(try PreparedStrokes(strokes: .init(strokes: [outline], medians: []), expectedCount: 1))
        for median in [[[0.0, 0.0]], [[0, 0], [0, 0]], [[0, 0], [Double.infinity, 1]]] {
            XCTAssertThrowsError(try PreparedStrokes(strokes: .init(strokes: [outline], medians: [median]), expectedCount: 1))
        }
    }

    func testTimelineUsesMedianLengthAndInterstrokePause() {
        let timeline = StrokeTimeline(medianLengths: [200, 400])
        XCTAssertEqual(timeline.durations[0], 0.400, accuracy: 0.000001)
        XCTAssertEqual(timeline.durations[1], 0.580, accuracy: 0.000001)
        XCTAssertEqual(timeline.totalDuration, 1.120, accuracy: 0.000001)
        XCTAssertEqual(timeline.frame(at: -1), .init(completedCount: 0, currentIndex: 0, progress: 0, isComplete: false))
        XCTAssertEqual(timeline.frame(at: 0.2).progress, 0.5, accuracy: 0.000001)
        let gap = timeline.frame(at: timeline.durations[0] + 0.07)
        XCTAssertEqual(gap, .init(completedCount: 1, currentIndex: 0, progress: 1, isComplete: false))
        let second = timeline.frame(at: timeline.durations[0] + 0.14)
        XCTAssertEqual(second.currentIndex, 1)
        XCTAssertEqual(second.completedCount, 1)
        XCTAssertEqual(second.progress, 0, accuracy: 0.000001)
        XCTAssertEqual(timeline.frame(at: timeline.totalDuration), .init(completedCount: 2, currentIndex: nil, progress: 1, isComplete: true))
        XCTAssertTrue(timeline.frame(at: 1000).isComplete)
    }

    @MainActor
    func testPlayerAutoStartPauseResumeReplayAndEndRestart() {
        let player = StrokePlayer(timeline: StrokeTimeline(medianLengths: [200, 400]))
        let start = Date(timeIntervalSince1970: 1000)
        player.start(reduceMotion: false, at: start)
        XCTAssertTrue(player.isPlaying)
        player.playOrPause(at: start.addingTimeInterval(0.2))
        XCTAssertFalse(player.isPlaying)
        XCTAssertEqual(player.frame(at: start.addingTimeInterval(100)).progress, 0.5, accuracy: 0.000001)
        player.playOrPause(at: start.addingTimeInterval(100))
        XCTAssertEqual(player.frame(at: start.addingTimeInterval(100.1)).progress, 0.75, accuracy: 0.000001)
        player.replay(at: start.addingTimeInterval(200))
        XCTAssertEqual(player.frame(at: start.addingTimeInterval(200)).progress, 0)
        XCTAssertTrue(player.frame(at: start.addingTimeInterval(202)).isComplete)
        player.finish()
        XCTAssertFalse(player.isPlaying)
        XCTAssertNil(player.frame(at: start.addingTimeInterval(300)).currentIndex)
        player.playOrPause(at: start.addingTimeInterval(300))
        XCTAssertTrue(player.isPlaying)
        XCTAssertEqual(player.frame(at: start.addingTimeInterval(300)).currentIndex, 0)
        // Leaving the screen/background uses the same pause path, preserving elapsed time.
        player.pause(at: start.addingTimeInterval(300.1))
        XCTAssertEqual(player.frame(at: start.addingTimeInterval(400)).progress, 0.25, accuracy: 0.000001)
    }

    @MainActor
    func testReduceMotionShowsCompletedCharacterAndStepsOncePerTap() {
        let player = StrokePlayer(timeline: StrokeTimeline(medianLengths: [200, 400]))
        player.start(reduceMotion: true)
        XCTAssertFalse(player.isPlaying)
        XCTAssertEqual(player.frame(at: .now).completedCount, 2)
        XCTAssertNil(player.selectedStroke)
        player.playOrPause()
        XCTAssertEqual(player.selectedStroke, 0)
        player.playOrPause()
        XCTAssertEqual(player.selectedStroke, 1)
        XCTAssertEqual(player.frame(at: .distantFuture).currentIndex, 1)
        player.playOrPause()
        XCTAssertEqual(player.selectedStroke, 0)
        XCTAssertFalse(player.isPlaying)
        player.replay()
        XCTAssertNil(player.selectedStroke)
        XCTAssertEqual(player.frame(at: .now).completedCount, 2)
        player.setReduceMotion(false)
        XCTAssertFalse(player.isPlaying)
        XCTAssertTrue(player.frame(at: .now).isComplete)
        player.playOrPause()
        XCTAssertTrue(player.isPlaying)
        player.setReduceMotion(true)
        XCTAssertFalse(player.isPlaying)
        XCTAssertEqual(player.frame(at: .now).completedCount, 2)
        XCTAssertNil(player.selectedStroke)
    }

    @MainActor
    func testPreparedGeometryIsCachedAndPlaybackFailureKeepsSearchAvailable() async throws {
        let source = try directory()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.copyItem(at: source, to: directory)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("strokes.v1.json")
        var records = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        records["学"] = ["strokes": ["invalid path"], "medians": "invalid"]
        try JSONSerialization.data(withJSONObject: records).write(to: url)
        let library = Library()
        await library.load(directory: directory)
        let first = try await library.preparedStrokes(for: "生")
        let second = try await library.preparedStrokes(for: "生")
        XCTAssertTrue(first.outlines[0] === second.outlines[0])
        do {
            _ = try await library.preparedStrokes(for: "学")
            XCTFail("Malformed playback must fail locally.")
        } catch {
            XCTAssertEqual(library.state, .ready)
            XCTAssertNotNil(library.character(id: "学"))
            XCTAssertEqual(library.searchWords("xuesheng", level: 1).map(\.id), ["学生"])
        }
    }

    func testCancelledPreparationDoesNotReturnGeometry() async throws {
        let cache = StrokePathCache()
        let strokes = StrokeSet(strokes: ["M0 0L10 10L20 0Z"], medians: [[[0, 0], [10, 10]]])
        let record = try JSONEncoder().encode(strokes)
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await cache.prepare(characterID: "test", record: record, expectedCount: 1)
        }
        do {
            _ = try await task.value
            XCTFail("Cancelled preparation must throw.")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
    }
}
