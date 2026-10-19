import SwiftUI

@MainActor
struct StrokePlaybackView: View {
    let characterID: String
    let strokes: PreparedStrokes
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var player: StrokePlayer
    @State private var hasStarted = false

    init(characterID: String, strokes: PreparedStrokes) {
        self.characterID = characterID
        self.strokes = strokes
        _player = State(initialValue: StrokePlayer(timeline: strokes.timeline))
    }

    var body: some View {
        TimelineView(.animation(paused: !player.isPlaying)) { timeline in
            let frame = player.frame(at: timeline.date)
            VStack(spacing: 16) {
                StrokeView(strokes: strokes, frame: frame, reduceMotion: player.reduceMotion)
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(spacing: 12) { controls }
                } else {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) { controls }
                        VStack(spacing: 12) { controls }
                    }
                }
                Text(strokeLabel(frame))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Stroke order for \(characterID)")
                    .accessibilityValue(player.accessibilityStatus(at: timeline.date))
                if player.reduceMotion {
                    Text("Tap Play to highlight the next stroke.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            .onChange(of: frame.isComplete) { _, complete in
                if complete && player.isPlaying {
                    player.finish()
                    announceStatus()
                }
            }
        }
        .onAppear {
            if !hasStarted {
                hasStarted = true
                player.start(reduceMotion: reduceMotion)
                if scenePhase != .active { player.pause() }
            }
        }
        .onDisappear { player.pause() }
        .onChange(of: reduceMotion) { _, enabled in
            player.setReduceMotion(enabled)
            announceStatus()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { player.pause() }
        }
    }

    @ViewBuilder
    private var controls: some View {
        Button(player.isPlaying ? "Pause" : "Play", systemImage: player.isPlaying ? "pause.fill" : "play.fill") {
            player.playOrPause()
            announceStatus()
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .fixedSize(horizontal: false, vertical: true)
        .frame(minHeight: 44)
        .accessibilityValue(player.accessibilityStatus())
        .accessibilityHint(player.reduceMotion ? "Highlights the next stroke of \(characterID)." : "Controls stroke order playback for \(characterID).")

        Button("Replay", systemImage: "arrow.counterclockwise") {
            player.replay()
            announceStatus()
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .fixedSize(horizontal: false, vertical: true)
        .frame(minHeight: 44)
        .accessibilityHint(player.reduceMotion ? "Clears the highlight. Play starts with the first stroke." : "Starts again from the first stroke.")
    }

    private func strokeLabel(_ frame: StrokeTimeline.Frame) -> String {
        if let current = frame.currentIndex { return "Stroke \(current + 1) of \(strokes.outlines.count)" }
        let count = strokes.outlines.count
        return "\(count) \(count == 1 ? "stroke" : "strokes")"
    }

    private func announceStatus() {
        AccessibilityNotification.Announcement("\(characterID). \(player.accessibilityStatus())").post()
    }
}
