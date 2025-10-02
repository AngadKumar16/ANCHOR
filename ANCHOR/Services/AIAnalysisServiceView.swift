import SwiftUI

struct AIAnalysisServiceView: View {
    @StateObject private var vm = AIAnalysisServiceViewModel()
    @State private var draft: String = ""

    var body: some View {
        NavigationView {
            VStack {
                Text("AIAnalysisService").font(.largeTitle)
                TextField("Title", text: $vm.draftTitle).textFieldStyle(.roundedBorder).padding()
                TextEditor(text: $vm.draftBody).frame(minHeight:120).padding()
                HStack {
                    Button("Save") { Task { await vm.saveDraft() } }.buttonStyle(.borderedProminent())
                    Button("Reload") { Task { await vm.loadAll() } }
                }
                List(vm.items, id: \.id) { it in
                    VStack(alignment: .leading) {
                        Text(it.title).bold()
                        if let b = it.body { Text(b).font(.subheadline).foregroundColor(.secondary) }
                    }
                }
                Spacer()
            }
            .padding()
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button(action: { Task { await vm.loadAll() } }) { Image(systemName: "arrow.clockwise") } } }
        }
    }
}

#if DEBUG
struct AIAnalysisServiceView_Previews: PreviewProvider {
    static var previews: some View { AIAnalysisServiceView() }
}
#endif
