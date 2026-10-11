import SwiftUI

struct StrokeView: View {
    let strokes: PreparedStrokes
    let frame: StrokeTimeline.Frame
    let reduceMotion: Bool
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 1024
            context.scaleBy(x: scale, y: scale)

            let box = CGRect(x: 0, y: 0, width: 1024, height: 1024)
            context.stroke(Path(box), with: .color(Color(.systemGray4)), lineWidth: 3)
            var grid = Path()
            for (start, end) in [
                (CGPoint(x: 512, y: 0), CGPoint(x: 512, y: 1024)),
                (CGPoint(x: 0, y: 512), CGPoint(x: 1024, y: 512)),
                (CGPoint(x: 0, y: 0), CGPoint(x: 1024, y: 1024)),
                (CGPoint(x: 1024, y: 0), CGPoint(x: 0, y: 1024))
            ] {
                grid.move(to: start)
                grid.addLine(to: end)
            }
            context.stroke(grid, with: .color(Color(.systemGray4)),
                           style: StrokeStyle(lineWidth: 3, dash: [16, 16]))

            for index in strokes.outlines.indices {
                context.fill(Path(strokes.outlines[index]),
                             with: .color(index < frame.completedCount ? .primary : Color(.systemGray5)))
            }
            if let index = frame.currentIndex {
                let outline = Path(strokes.outlines[index])
                if reduceMotion {
                    context.fill(outline, with: .color(.accentColor))
                } else if index >= frame.completedCount {
                    var clipped = context
                    clipped.clip(to: outline)
                    let median = Path(strokes.medians[index]).trimmedPath(from: 0, to: frame.progress)
                    clipped.stroke(median, with: .color(.accentColor),
                                   style: StrokeStyle(lineWidth: 220, lineCap: .round, lineJoin: .round))
                }
                if differentiateWithoutColor {
                    context.stroke(outline, with: .color(.primary),
                                   style: StrokeStyle(lineWidth: 5, dash: [12, 8]))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 270)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
        .accessibilityHidden(true)
    }
}
