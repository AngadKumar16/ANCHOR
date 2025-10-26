import SwiftUI
import CoreData

struct MoodTrackingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoodEntity.date, ascending: false)],
        animation: .default)
    private var moods: FetchedResults<MoodEntity>
    
    @State private var selectedMood: MoodLevel?
    @State private var note: String = ""
    @State private var showingNoteField = false
    @State private var showingHistory = false
    
    // Theme
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Mood Selection
                    moodSelectionView()
                    
                    // Recent Moods
                    recentMoodsView()
                    
                    // Mood History Button
                    Button(action: { showingHistory = true }) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .imageScale(.medium)
                            Text("View Mood History")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ANCHORDesign.Colors.secondary.opacity(0.1))
                        .foregroundColor(ANCHORDesign.Colors.secondary)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    .sheet(isPresented: $showingHistory) {
                        MoodHistoryView()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("How are you feeling?")
            .background(ANCHORDesign.Colors.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !moods.isEmpty {
                        Button(action: { showingHistory = true }) {
                            Label("History", systemImage: "list.bullet")
                                .labelStyle(.iconOnly)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func moodSelectionView() -> some View {
        VStack(spacing: 16) {
            Text("Select your mood")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(ANCHORDesign.Colors.textPrimary)
                .padding(.bottom, 8)
            
            HStack(spacing: 16) {
                ForEach(MoodLevel.allCases) { level in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedMood = level
                            showingNoteField = true
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text(level.emoji)
                                .font(.system(size: 36))
                                .frame(width: 60, height: 60)
                                .background(level.color.opacity(0.15))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(level.color.opacity(selectedMood == level ? 0.8 : 0), lineWidth: 3)
                                )
                            
                            Text(level.description)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(ANCHORDesign.Colors.textPrimary)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding()
            .background(ANCHORDesign.Colors.backgroundCard)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            .padding(.horizontal)
            
            if showingNoteField, let selectedMood = selectedMood {
                VStack(spacing: 16) {
                    Text("Add a note (optional)")
                        .font(.subheadline)
                        .foregroundColor(ANCHORDesign.Colors.textSecondary)
                    
                    TextEditor(text: $note)
                        .frame(minHeight: 100)
                        .padding()
                        .background(ANCHORDesign.Colors.backgroundCard)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(ANCHORDesign.Colors.secondary.opacity(0.2), lineWidth: 1)
                        )
                    
                    HStack(spacing: 16) {
                        Button("Cancel") {
                            withAnimation(.spring()) {
                                self.selectedMood = nil
                                self.note = ""
                                self.showingNoteField = false
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .frame(maxWidth: .infinity)
                        
                        Button("Save") {
                            saveMood(level: selectedMood, note: note.isEmpty ? nil : note)
                            withAnimation(.spring()) {
                                self.note = ""
                                self.showingNoteField = false
                                self.selectedMood = nil
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .frame(maxWidth: .infinity)
                        .disabled(selectedMood == nil)
                    }
                }
                .padding()
                .background(ANCHORDesign.Colors.backgroundCard)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .padding(.horizontal)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    @ViewBuilder
    private func recentMoodsView() -> some View {
        if !moods.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Recent Moods")
                        .font(.headline)
                        .foregroundColor(ANCHORDesign.Colors.textPrimary)
                    Spacer()
                    if moods.count > 3 {
                        Button("See All") {
                            showingHistory = true
                        }
                        .font(.subheadline)
                        .foregroundColor(ANCHORDesign.Colors.primary)
                    }
                }
                .padding(.horizontal)
                
                VStack(spacing: 12) {
                    ForEach(Array(moods.prefix(3).enumerated()), id: \.element) { index, mood in
                        MoodRow(mood: mood)
                            .padding(.horizontal)
                        
                        if index < min(2, moods.count - 1) {
                            Divider()
                                .padding(.leading, 60)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical, 8)
                .background(ANCHORDesign.Colors.backgroundCard)
                .cornerRadius(16)
                .padding(.horizontal)
            }
            .padding(.top, 8)
        } else {
            VStack(spacing: 20) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 50))
                    .foregroundColor(ANCHORDesign.Colors.primary.opacity(0.3))
                
                VStack(spacing: 8) {
                    Text("No mood entries yet")
                        .font(.headline)
                        .foregroundColor(ANCHORDesign.Colors.textPrimary)
                    
                    Text("Select how you're feeling to get started")
                        .font(.subheadline)
                        .foregroundColor(ANCHORDesign.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
            }
            .padding(.vertical, 40)
        }
    }
    
    private func saveMood(level: MoodLevel, note: String?) {
        withAnimation {
            let newMood = MoodEntity(context: viewContext)
            newMood.id = UUID()
            newMood.date = Date()
            newMood.level = level.rawValue
            newMood.note = note
            
            do {
                try viewContext.save()
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            } catch {
                Logger.persistence.error("Failed to save mood: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Previews
struct MoodTrackingView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        // Add sample data
        for i in 0..<5 {
            let mood = MoodEntity(context: context)
            mood.id = UUID()
            mood.date = Calendar.current.date(byAdding: .hour, value: -i, to: Date()) ?? Date()
            mood.level = Int16(Int.random(in: 1...5))
            mood.note = i % 2 == 0 ? "Sample mood entry" : nil
        }
        
        return MoodTrackingView()
            .environment(\.managedObjectContext, context)
    }
}
