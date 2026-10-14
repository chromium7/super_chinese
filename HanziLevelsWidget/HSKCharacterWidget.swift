import SwiftUI
import WidgetKit

@main
struct HSKCharacterWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetSettings.kind, provider: CharacterProvider()) { entry in
            CharacterWidgetView(entry: entry)
        }
        .configurationDisplayName("HSK Character")
        .description("Learn a character from your current HSK level. Changes every eight hours.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
