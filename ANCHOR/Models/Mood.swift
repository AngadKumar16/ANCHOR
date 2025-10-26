import Foundation
import CoreData
import SwiftUI
import os.log

enum MoodLevel: Int16, CaseIterable, Identifiable {
    case terrible = 1
    case bad = 2
    case okay = 3
    case good = 4
    case great = 5
    
    var id: Int16 { self.rawValue }
    
    var emoji: String {
        switch self {
        case .terrible: return "😩"
        case .bad: return "😕"
        case .okay: return "😐"
        case .good: return "🙂"
        case .great: return "😊"
        }
    }
    
    var description: String {
        switch self {
        case .terrible: return "Terrible"
        case .bad: return "Not Great"
        case .okay: return "Okay"
        case .good: return "Good"
        case .great: return "Great!"
        }
    }
    
    var color: Color {
        switch self {
        case .terrible: return .red
        case .bad: return .orange
        case .okay: return .yellow
        case .good: return .green
        case .great: return .blue
        }
    }
}

@objc(MoodEntity)
public class MoodEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var level: Int16
    @NSManaged public var note: String?
    
    var moodLevel: MoodLevel {
        get { MoodLevel(rawValue: level) ?? .okay }
        set { level = newValue.rawValue }
    }
}

extension MoodEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MoodEntity> {
        return NSFetchRequest<MoodEntity>(entityName: "MoodEntity")
    }
    
    static func create(in context: NSManagedObjectContext, level: MoodLevel, note: String? = nil) -> MoodEntity {
        let mood = MoodEntity(context: context)
        mood.id = UUID()
        mood.date = Date()
        mood.moodLevel = level
        mood.note = note
        return mood
    }
    
    static func fetchRecent(in context: NSManagedObjectContext, limit: Int = 30) -> [MoodEntity] {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MoodEntity.date, ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            os_log("Failed to fetch moods: %{public}@", log: .default, type: .error, error.localizedDescription)
            return []
        }
    }
    
    static func fetchForDateRange(in context: NSManagedObjectContext, from startDate: Date, to endDate: Date) -> [MoodEntity] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MoodEntity.date, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            os_log("Failed to fetch moods for date range: %{public}@", log: .default, type: .error, error.localizedDescription)
            return []
        }
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension MoodEntity {
    static var preview: MoodEntity {
        let context = PersistenceController.preview.container.viewContext
        let mood = MoodEntity(context: context)
        mood.id = UUID()
        mood.date = Date()
        mood.moodLevel = .good
        mood.note = "Feeling good today!"
        return mood
    }
    
    static var previews: [MoodEntity] {
        let context = PersistenceController.preview.container.viewContext
        var moods: [MoodEntity] = []
        
        for i in 0..<7 {
            let mood = MoodEntity(context: context)
            mood.id = UUID()
            mood.date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            mood.level = Int16(Int.random(in: 1...5))
            mood.note = i % 2 == 0 ? "Sample mood entry" : nil
            moods.append(mood)
        }
        
        return moods
    }
}
#endif
