import SwiftUI

struct MoodRow: View {
    let mood: MoodEntity
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: mood.date)
    }
    
    private var moodLevel: MoodLevel {
        MoodLevel(rawValue: mood.level) ?? .okay
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Mood Emoji
            Text(moodLevel.emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(moodLevel.color.opacity(0.15))
                .clipShape(Circle())
            
            // Mood Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(moodLevel.description)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(moodLevel.color)
                    
                    Spacer()
                    
                    Text(formattedDate)
                        .font(.caption2)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                if let note = mood.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
            
            // Navigation chevron
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(AppTheme.secondary.opacity(0.5))
                .padding(.leading, 4)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Previews
struct MoodRow_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        // Sample mood with note
        let moodWithNote = MoodEntity(context: context)
        moodWithNote.id = UUID()
        moodWithNote.date = Date()
        moodWithNote.level = 4 // Good
        moodWithNote.note = "Had a great day with friends!"
        
        // Sample mood without note
        let moodWithoutNote = MoodEntity(context: context)
        moodWithoutNote.id = UUID()
        moodWithoutNote.date = Date().addingTimeInterval(-3600)
        moodWithoutNote.level = 2 // Bad
        moodWithoutNote.note = nil
        
        return Group {
            // Light mode
            VStack(spacing: 16) {
                MoodRow(mood: moodWithNote)
                MoodRow(mood: moodWithoutNote)
            }
            .padding()
            .previewDisplayName("Light Mode")
            .preferredColorScheme(.light)
            
            // Dark mode
            VStack(spacing: 16) {
                MoodRow(mood: moodWithNote)
                MoodRow(mood: moodWithoutNote)
            }
            .padding()
            .previewDisplayName("Dark Mode")
            .preferredColorScheme(.dark)
        }
        .background(AppTheme.background)
        .previewLayout(.sizeThatFits)
    }
}
