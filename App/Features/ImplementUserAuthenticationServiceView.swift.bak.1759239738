import SwiftUI

// Auto-generated View for feature: Implement user authentication service
struct ImplementUserAuthenticationServiceView: View {
    @StateObject private var viewModel = ImplementUserAuthenticationServiceViewModel()

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
struct ImplementUserAuthenticationServiceView_Preview: PreviewProvider {
    static var previews: some View {
        ImplementUserAuthenticationServiceView()
            .previewDevice("iPhone 14")
    }
}
#endif
