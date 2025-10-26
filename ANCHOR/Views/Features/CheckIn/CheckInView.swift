//
//  CheckInView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI
import Utils

struct CheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var checkInStatus: Utils.CheckInStatus
    @State private var moodRating: Double = 5
    @State private var notes: String = ""
    @State private var selectedTags: Set<String> = []
    
    private let moodTags = ["Happy", "Calm", "Anxious", "Sad", "Grateful", "Stressed", "Hopeful", "Tired"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("How are you feeling?")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Mood Rating: \(Int(moodRating))/10")
                            .font(.headline)
                        
                        Slider(value: $moodRating, in: 1...10, step: 1)
                            .accentColor(.blue)
                    }
                }
                
                Section(header: Text("Tags")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                        ForEach(moodTags, id: \.self) { tag in
                            Button(action: {
                                if selectedTags.contains(tag) {
                                    selectedTags.remove(tag)
                                } else {
                                    selectedTags.insert(tag)
                                }
                            }) {
                                Text(tag)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedTags.contains(tag) ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedTags.contains(tag) ? .white : .primary)
                                    .cornerRadius(15)
                            }
                        }
                    }
                }
                
                Section(header: Text("Notes (Optional)")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Check In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        checkInStatus = .notStarted
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCheckIn()
                        checkInStatus = .completed
                        dismiss()
                    }
                    .disabled(notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedTags.isEmpty)
                }
            }
            .onAppear {
                checkInStatus = .inProgress
            }
        }
    }
    
    private func saveCheckIn() {
        // Create a journal entry for the check-in
        let checkInBody = buildCheckInBody()
        let tags = Array(selectedTags)
        
        Task {
            let viewModel = JournalViewModel()
            try? await viewModel.add(title: "Daily Check-in", body: checkInBody, tags: tags)
        }
    }
    
    private func buildCheckInBody() -> String {
        var body = "Mood Rating: \(Int(moodRating))/10"
        
        if !selectedTags.isEmpty {
            body += "\nTags: \(selectedTags.joined(separator: ", "))"
        }
        
        if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            body += "\n\nNotes: \(notes)"
        }
        
        return body
    }
}

#Preview {
    CheckInView(checkInStatus: .constant(.notStarted))
}
