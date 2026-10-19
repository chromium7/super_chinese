import SwiftUI

struct EmptyLibraryView: View {
    let title: String
    let systemImage: String
    let description: String

    var body: some View {
        ScrollView {
            ContentUnavailableView {
                Label(title, systemImage: systemImage)
            } description: {
                Text(description)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
