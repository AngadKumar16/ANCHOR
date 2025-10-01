import SwiftUI

// Auto-generated View for feature: Rich text formatting for entries
struct RichTextFormattingForEntriesView: View {
    @StateObject private var viewModel = RichTextFormattingForEntriesViewModel()

    var body: some View {
        NavigationView {
            VStack {
                Text(viewModel.title)
                    .font(.largeTitle)
                    .padding(.top)

                if viewModel.items.isEmpty {
                    VStack {
                        Text("No items yet")
                            .foregroundColor(.secondary)
                        ProgressView()
                            .padding(.top, 8)
                    }
                } else {
                    List(viewModel.items, id: \.self) { item in
                        Text(item)
                    }
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await viewModel.load()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh")
                }
            }
            .padding()
        }
    }
}

#if DEBUG
struct RichTextFormattingForEntriesView_Preview: PreviewProvider {
    static var previews: some View {
        RichTextFormattingForEntriesView()
            .previewDevice("iPhone 14")
    }
}
#endif
