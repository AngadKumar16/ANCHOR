//
//  JournalEntryView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI
import PhotosUI

struct JournalEntryView: View {
    @EnvironmentObject var journalVM: JournalViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var entryText: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var selectedMood: MoodType = .neutral
    @State private var entryDate: Date = Date()
    @State private var isAnalyzing = false
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var showingDatePicker = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var attachedImages: [UIImage] = []
    @State private var error: Error?
    
    let entry: JournalEntryModel?
    
    enum MoodType: String, CaseIterable {
        case veryHappy = "😄"
        case happy = "😊" 
        case neutral = "😐"
        case sad = "😔"
        case verySad = "😢"
        
        var description: String {
            switch self {
            case .veryHappy: return "Very Happy"
            case .happy: return "Happy"
            case .neutral: return "Neutral"
            case .sad: return "Sad"
            case .verySad: return "Very Sad"
            }
        }
        
        var sentimentValue: Int {
            switch self {
            case .veryHappy: return 2
            case .happy: return 1
            case .neutral: return 0
            case .sad: return -1
            case .verySad: return -2
            }
        }
    }
    
    private let availableTags = [
        "Grateful", "Anxious", "Happy", "Sad", "Motivated", "Tired",
        "Hopeful", "Stressed", "Calm", "Excited", "Worried", "Peaceful"
    ]
    
    private var isEditMode: Bool {
        entry != nil
    }
    
    private var navigationTitle: String {
        if isEditMode {
            return DateFormatter.localizedString(from: entryDate, dateStyle: .medium, timeStyle: .none)
        } else {
            return "New Entry"
        }
    }
    
    init(entry: JournalEntryModel? = nil) {
        self.entry = entry
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    dateTimeSection
                    titleSection
                    contentSection
                    moodSection
                    tagsSection
                    attachmentsSection
                }
                .padding()
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Share button (only in edit mode)
                        if isEditMode {
                            Button(action: {
                                showingShareSheet = true
                            }) {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                        
                        // Save button
                        Button(action: saveEntry) {
                            if isAnalyzing {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                        .scaleEffect(0.8)
                                    Text("Saving...")
                                }
                            } else {
                                Text("Save")
                                    .fontWeight(.semibold)
                            }
                        }
                        .disabled(entryText.isEmpty || isAnalyzing)
                    }
                }
                
                // Delete button (only in edit mode)
                ToolbarItemGroup(placement: .bottomBar) {
                    if isEditMode {
                        Spacer()
                        Button("Delete Entry") {
                            showingDeleteAlert = true
                        }
                        .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            setupInitialValues()
        }
        .onChange(of: selectedPhotos) { oldValue, newPhotos in
            loadSelectedPhotos(newPhotos)
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerSheet(selectedDate: $entryDate)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(entry: createEntryForSharing())
        }
        .alert("Delete Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteEntry()
            }
        } message: {
            Text("Are you sure you want to delete this journal entry? This action cannot be undone.")
        }
    }
    
    // MARK: - View Components
    
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date & Time")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button(action: { showingDatePicker.toggle() }) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    
                    Text(entryDate, style: .date)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text("at")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(entryDate, style: .time)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(selectedDate: $entryDate)
            }
        }
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title (Optional)")
                .font(.headline)
                .foregroundColor(.secondary)
            
            TextField("Give your entry a title...", text: $title)
                .textFieldStyle(.roundedBorder)
                .font(.body)
        }
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Thoughts")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(minHeight: 250)
                
                if entryText.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Write about your day, feelings, thoughts, or anything on your mind...")
                            .foregroundColor(.secondary)
                        Text("This is your private space to reflect and process.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                TextEditor(text: $entryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.clear)
                    .font(.body)
            }
        }
    }
    
    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How are you feeling?")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(MoodType.allCases, id: \.self) { mood in
                        MoodButton(
                            mood: mood,
                            isSelected: selectedMood == mood,
                            action: { selectedMood = mood }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(availableTags, id: \.self) { tag in
                    TagButton(
                        tag: tag,
                        isSelected: selectedTags.contains(tag),
                        action: { toggleTag(tag) }
                    )
                }
            }
        }
    }
    
    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attachments (Optional)")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                // Photo Picker
                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: 3,
                    matching: .images
                ) {
                    HStack {
                        Image(systemName: "photo")
                        Text("Add Photo")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(20)
                }
                
                // Voice Note Button (Placeholder)
                Button(action: {
                    // TODO: Implement voice recording
                }) {
                    HStack {
                        Image(systemName: "mic")
                        Text("Voice Note")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(20)
                }
                .disabled(true) // Disabled for now
                
                Spacer()
            }
            
            // Display attached images
            if !attachedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(attachedImages.enumerated()), id: \.offset) { index, image in
                            AttachedImageView(image: image) {
                                attachedImages.remove(at: index)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
    
    // MARK: - Sharing
    
    private func createEntryForSharing() -> JournalEntryModel {
        // Create a new JournalEntryModel with current values
        let entry = JournalEntryModel(
            id: self.entry?.id ?? UUID(),
            date: entryDate,
            title: title.isEmpty ? nil : title,
            body: entryText,
            sentiment: Double(selectedMood.sentimentValue),
            tags: Array(selectedTags)
        )
        return entry
    }
    
    // MARK: - Supporting Views
    
    private func setupInitialValues() {
        if let entry = entry {
            title = entry.title ?? ""
            entryText = entry.body
            selectedTags = Set(entry.tags)
            entryDate = entry.date
            
            // Map sentiment to mood
            switch entry.sentiment {
            case 2: selectedMood = .veryHappy
            case 1: selectedMood = .happy
            case 0: selectedMood = .neutral
            case -1: selectedMood = .sad
            case -2: selectedMood = .verySad
            default: selectedMood = .neutral
            }
        }
    }
    
    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    private func loadSelectedPhotos(_ photos: [PhotosPickerItem]) {
        Task {
            for photo in photos {
                if let data = try? await photo.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        attachedImages.append(image)
                    }
                }
            }
            await MainActor.run {
                selectedPhotos = []
            }
        }
    }
    
    private func saveEntry() {
        guard !entryText.isEmpty else { return }
        
        isAnalyzing = true
        
        Task {
            do {
                if let existingEntry = entry {
                    // Convert JournalEntryModel to JournalEntry
                    let journalEntry = try JournalEntry(
                        id: existingEntry.id,
                        createdAt: existingEntry.date,
                        updatedAt: Date(),
                        title: title.isEmpty ? nil : title,
                        body: entryText,
                        bodyFormat: "plain",
                        sentiment: existingEntry.sentiment,
                        tags: selectedTags,
                        isLocked: false,
                        version: 1
                    )
                    try await journalVM.updateEntry(
                        journalEntry,
                        title: title.isEmpty ? nil : title,
                        body: entryText,
                        tags: selectedTags
                    )
                } else {
                    // Create new entry with current date
                    try await journalVM.createEntry(
                        title: title.isEmpty ? nil : title,
                        body: entryText,
                        tags: selectedTags
                    )
                }
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
            
            await MainActor.run {
                isAnalyzing = false
            }
        }
    }
    
    private func deleteEntry() {
        guard let entry = entry else { return }
        
        Task {
            // Convert to JournalEntry
            let journalEntry = try JournalEntry(
                id: entry.id,
                createdAt: entry.date,
                updatedAt: Date(),
                title: entry.title,
                body: entry.body,
                bodyFormat: "plain",
                sentiment: entry.sentiment,
                tags: Set(entry.tags),
                isLocked: false,
                version: 1
            )
            try? await journalVM.delete(entries: [journalEntry])
            await MainActor.run {
                dismiss()
            }
        }
    }
}

// MARK: - Supporting Views

private struct MoodButton: View {
    let mood: JournalEntryView.MoodType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(mood.rawValue)
                    .font(.system(size: 32))
                
                Text(mood.description)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 70, height: 70)
            .background(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
            .foregroundColor(isSelected ? .blue : .primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

private struct TagButton: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

private struct AttachedImageView: View {
    let image: UIImage
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipped()
                .cornerRadius(8)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .offset(x: 8, y: -8)
        }
    }
}

private struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker(
                    "Entry Date & Time",
                    selection: $selectedDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Set Date & Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let entry: JournalEntryModel
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let title = entry.title ?? "Journal Entry"
        let date = DateFormatter.localizedString(from: entry.date, dateStyle: .full, timeStyle: .short)
        let mood = moodDescription(for: Int(entry.sentiment))
        let tags = entry.tags.isEmpty ? "" : "\n\nTags: " + entry.tags.joined(separator: ", ")
        
        let content = """
        \(title)
        \(date)
        Mood: \(mood)
        
        \(entry.body)\(tags)
        
        ---
        Shared from ANCHOR Journal
        """
        
        let activityVC = UIActivityViewController(activityItems: [content], applicationActivities: nil)
        
        // Safely handle activity types
        var excludedTypes: [UIActivity.ActivityType] = []
        
        // Check for iOS 15+ specific types
        if #available(iOS 15.0, *) {
            excludedTypes.append(contentsOf: [
                .addToReadingList,
                .assignToContact,
                .saveToCameraRoll
            ])
        } else {
            // Fallback for earlier iOS versions
            excludedTypes.append(contentsOf: [
                .init("com.apple.UIKit.activity.AddToReadingList"),
                .init("com.apple.UIKit.activity.AssignToContact"),
                .init("com.apple.UIKit.activity.SaveToCameraRoll")
            ].compactMap { $0 })
        }
        
        activityVC.excludedActivityTypes = excludedTypes
        
        return activityVC
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    
    private func moodDescription(for sentiment: Int) -> String {
        switch sentiment {
        case 2: return "😄 Very Happy"
        case 1: return "😊 Happy"
        case 0: return "😐 Neutral"
        case -1: return "😔 Sad"
        case -2: return "😢 Very Sad"
        default: return "😐 Neutral"
        }
    }
}

#Preview("New Entry") {
    NavigationStack {
        JournalEntryView()
            .environmentObject(JournalViewModel())
    }
}

#Preview("Edit Entry") {
    NavigationStack {
        JournalEntryView(entry: JournalEntryModel(
            id: UUID(),
            date: Date(),
            title: "Sample Entry",
            body: "This is a sample journal entry for preview purposes.",
            sentiment: 1,
            tags: ["Happy", "Grateful"]
        ))
        .environmentObject(JournalViewModel())
    }
}
