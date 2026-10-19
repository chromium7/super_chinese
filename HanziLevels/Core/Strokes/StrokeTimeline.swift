import Foundation

struct StrokeTimeline: Sendable {
    struct Frame: Equatable {
        let completedCount: Int
        let currentIndex: Int?
        let progress: Double
        let isComplete: Bool
    }

    let durations: [TimeInterval]
    let totalDuration: TimeInterval
    private let starts: [TimeInterval]

    init(medianLengths: [Double]) {
        durations = medianLengths.map { (220 + $0 * 0.9) / 1000 }
        var cursor = 0.0
        var starts: [TimeInterval] = []
        for (index, duration) in durations.enumerated() {
            starts.append(cursor)
            cursor += duration
            if index < durations.count - 1 { cursor += 0.140 }
        }
        self.starts = starts
        totalDuration = cursor
    }

    func frame(at elapsed: TimeInterval) -> Frame {
        let elapsed = max(0, elapsed)
        for index in durations.indices {
            let end = starts[index] + durations[index]
            if elapsed < end {
                return Frame(completedCount: index, currentIndex: index,
                             progress: max(0, (elapsed - starts[index]) / durations[index]), isComplete: false)
            }
            if index < durations.count - 1, elapsed < starts[index + 1] {
                // Keep the just-finished stroke label during the inter-stroke pause.
                return Frame(completedCount: index + 1, currentIndex: index, progress: 1, isComplete: false)
            }
        }
        return Frame(completedCount: durations.count, currentIndex: nil, progress: 1, isComplete: true)
    }
}
