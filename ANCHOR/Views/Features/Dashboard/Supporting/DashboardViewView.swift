import SwiftUI

struct DashboardViewView: View {
    @StateObject private var vm = DashboardViewViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                Text("DashboardView").font(.largeTitle)
                TextField("Title", text: $vm.draftTitle)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                TextEditor(text: $vm.draftBody)
                    .frame(minHeight: 120)
                    .padding()
                
                HStack {
                    Button("Save") { 
                        Task { 
                            await vm.saveDraft() 
                        } 
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                    
                    Button("Reload") { 
                        Task { 
                            await vm.loadAll() 
                        } 
                    }
                }
                
                List(vm.items, id: \.title) { item in
                    VStack(alignment: .leading) {
                        Text(item.title).bold()
                        if let body = item.body, !body.isEmpty {
                            Text(body)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .toolbar { 
                ToolbarItem(placement: .navigationBarTrailing) { 
                    Button(action: { 
                        Task { 
                            await vm.loadAll() 
                        } 
                    }) { 
                        Image(systemName: "arrow.clockwise") 
                    } 
                } 
            }
        }
    }
}

#if DEBUG
struct DashboardViewView_Previews: PreviewProvider {
    static var previews: some View { DashboardViewView() }
}
#endif
