import SwiftData
import SwiftUI

@MainActor
struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: HistoryStore.newestFirst) private var entries: [HistoryEntry]
    @State private var confirmsClear = false
    @State private var showsError = false

    var body: some View {
        List {
            ForEach(entries) { entry in
                HistoryRow(entry: entry)
            }
            .onDelete { offsets in
                do {
                    try HistoryStore.delete(offsets.map { entries[$0] }, in: context)
                } catch {
                    showsError = true
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if entries.isEmpty {
                ContentUnavailableView("No history yet", systemImage: "clock",
                                       description: Text("Words and characters you open will appear here."))
            }
        }
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear History", role: .destructive) { confirmsClear = true }
                    .disabled(entries.isEmpty)
                    .confirmationDialog("Clear History?", isPresented: $confirmsClear, titleVisibility: .visible) {
                        Button("Clear History", role: .destructive) {
                            do { try HistoryStore.clear(in: context) }
                            catch { showsError = true }
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("This removes all recently viewed words and characters from this device.")
                    }
            }
        }
        .alert("History could not be updated", isPresented: $showsError) {
        } message: {
            Text("Your history has not been changed. Please try again.")
        }
    }
}
