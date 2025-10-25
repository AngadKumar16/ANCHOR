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
                            Text("View Mood History")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .sheet(isPresented: $showingHistory) {
                        MoodHistoryView()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("How are you feeling?")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !moods.isEmpty {
                        Button(action: { showingHistory = true }) {
                            Label("History", systemImage: "list.bullet")
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
                .font(.headline)
                .padding(.bottom, 8)
            
            HStack(spacing: 16) {
                ForEach(MoodLevel.allCases) { level in
                    Button(action: {
                        withAnimation {
                            selectedMood = level
                            showingNoteField = true
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text(level.emoji)
                                .font(.system(size: 40))
                                .frame(width: 60, height: 60)
                                .background(level.color.opacity(0.2))
                                .clipShape(Circle())
                            
                            Text(level.description)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .padding(.horizontal)
            
            if showingNoteField, let selectedMood = selectedMood {
                VStack(spacing: 16) {
                    Text("Add a note (optional)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $note)
                        .frame(minHeight: 80)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    HStack(spacing: 16) {
                        Button("Cancel") {
                            withAnimation {
                                self.selectedMood = nil
                                self.note = ""
                                self.showingNoteField = false
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        
                        Button("Save") {
                            saveMood(level: selectedMood, note: note.isEmpty ? nil : note)
                            self.note = ""
                            self.showingNoteField = false
                            self.selectedMood = nil
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedMood == nil)
                    }
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(16)
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
                    Spacer()
                    if moods.count > 3 {
                        Button("See All") {
                            showingHistory = true
                        }
                        .font(.subheadline)
                    }
                }
                .padding(.horizontal)
                
                VStack(spacing: 12) {
                    ForEach(moods.prefix(3)) { mood in
                        MoodRow(mood: mood)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.top, 8)
        } else {
            VStack(spacing: 16) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 50))
                    .foregroundColor(.blue.opacity(0.5))
                Text("No mood entries yet")
                    .font(.headline)
                Text("Select how you're feeling to get started")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
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
            newMood.moodLevel = level
            newMood.note = note
            
            do {
                try viewContext.save()
            } catch {
                Logger.persistence.error("Failed to save mood: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Subviews

struct MoodRow: View {
    let mood: MoodEntity
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: mood.date)
    }
    
    var body: some View {
        HStack {
            Text(mood.moodLevel.emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(mood.moodLevel.color.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(mood.moodLevel.description)
                        .font(.subheadline)
                        .foregroundColor(mood.moodLevel.color)
                    
                    Spacer()
                    
                    Text(formattedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if let note = mood.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .opacity(0.5)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
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
