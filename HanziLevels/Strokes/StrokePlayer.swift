import Foundation
import Observation

@MainActor
@Observable
final class StrokePlayer {
    let timeline: StrokeTimeline
    private(set) var isPlaying = false
    private(set) var reduceMotion = false
    private(set) var selectedStroke: Int?
    private var elapsed: TimeInterval = 0
    private var startedAt: Date?

    init(timeline: StrokeTimeline) { self.timeline = timeline }

    func frame(at date: Date) -> StrokeTimeline.Frame {
        if reduceMotion {
            return .init(completedCount: timeline.durations.count, currentIndex: selectedStroke,
                         progress: 1, isComplete: selectedStroke == nil)
        }
        return timeline.frame(at: elapsedTime(at: date))
    }

    func start(reduceMotion: Bool, at date: Date = .now) {
        self.reduceMotion = reduceMotion
        replay(at: date)
    }

    func playOrPause(at date: Date = .now) {
        if reduceMotion {
            guard !timeline.durations.isEmpty else { return }
            selectedStroke = ((selectedStroke ?? -1) + 1) % timeline.durations.count
        } else if isPlaying {
            pause(at: date)
        } else {
            if timeline.frame(at: elapsed).isComplete { elapsed = 0 }
            startedAt = date
            isPlaying = true
        }
    }

    func replay(at date: Date = .now) {
        elapsed = 0
        selectedStroke = nil
        startedAt = reduceMotion ? nil : date
        isPlaying = !reduceMotion && !timeline.durations.isEmpty
    }

    func pause(at date: Date = .now) {
        elapsed = min(timeline.totalDuration, elapsedTime(at: date))
        startedAt = nil
        isPlaying = false
    }

    func finish() {
        guard !reduceMotion else { return }
        elapsed = timeline.totalDuration
        startedAt = nil
        isPlaying = false
    }

    func setReduceMotion(_ enabled: Bool, at date: Date = .now) {
        guard enabled != reduceMotion else { return }
        pause(at: date)
        reduceMotion = enabled
        selectedStroke = nil
        // Changing the accessibility preference never starts an animation.
        elapsed = timeline.totalDuration
    }

    private func elapsedTime(at date: Date) -> TimeInterval {
        elapsed + (startedAt.map { max(0, date.timeIntervalSince($0)) } ?? 0)
    }
}
