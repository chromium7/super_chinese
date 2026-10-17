import Foundation
import WidgetKit

struct CharacterProvider: TimelineProvider {
    func placeholder(in context: Context) -> CharacterEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping (CharacterEntry) -> Void) {
        guard !context.isPreview else { completion(.sample); return }
        load { level, characters in
            let now = Date()
            completion(CharacterEntry(date: now, level: level,
                                      character: CharacterRotation.character(at: now, from: characters)))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CharacterEntry>) -> Void) {
        load { level, characters in
            let now = Date()
            let entries = CharacterRotation.dates(startingAt: now).map { date in
                CharacterEntry(date: date, level: level,
                               character: CharacterRotation.character(at: date, from: characters))
            }
            let refresh = characters.isEmpty ? now.addingTimeInterval(60 * 60)
                : CharacterRotation.nextChange(after: entries.last?.date ?? now)
            completion(Timeline(entries: entries, policy: .after(refresh)))
        }
    }

    private func load(completion: @escaping (Int, [Hanzi]) -> Void) {
        // File decoding stays off the extension's main thread.
        DispatchQueue.global(qos: .userInitiated).async {
            let level = WidgetSettings.currentLevel
            let characters = (try? WidgetCharacterCatalog.load(
                level: level, directory: Bundle.main.resourceURL?.appendingPathComponent("Data", isDirectory: true)
            )) ?? []
            completion(level, characters)
        }
    }
}
