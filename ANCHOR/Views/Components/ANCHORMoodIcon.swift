//
//  ANCHORMoodIcon.swift
//  ANCHOR
//
//  Created by Cascade on 8/14/25.
//

import SwiftUI

struct ANCHORMoodIcon: View {
    let mood: MoodType
    let size: CGFloat

    init(mood: MoodType, size: CGFloat = 44) {
        self.mood = mood
        self.size = size
    }

    var body: some View {
        Image(systemName: mood.iconName)
            .font(.system(size: size * 0.5))
            .foregroundColor(mood.color)
            .frame(width: size, height: size)
            .background(mood.color.opacity(0.15))
            .clipShape(Circle())
    }
    
    // MARK: - MoodType Enum
    enum MoodType: String, CaseIterable, Identifiable {
        case veryHappy = "Very Happy"
        case happy = "Happy"
        case neutral = "Neutral"
        case sad = "Sad"
        case verySad = "Very Sad"

        var id: String { self.rawValue }

        var iconName: String {
            switch self {
            case .veryHappy: return "face.smiling.fill"
            case .happy: return "face.smiling"
            case .neutral: return "person.fill"
            case .sad: return "face.dashed"
            case .verySad: return "face.dashed.fill"
            }
        }

        var color: Color {
            switch self {
            case .veryHappy: return .green
            case .happy: return .yellow
            case .neutral: return .gray
            case .sad: return .blue
            case .verySad: return .purple
            }
        }
    }
}

// MARK: - Previews
struct ANCHORMoodIcon_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack(spacing: 20) {
                ANCHORMoodIcon(mood: .happy)
                ANCHORMoodIcon(mood: .sad, size: 60)
                ANCHORMoodIcon(mood: .verySad, size: 80)
            }
            HStack(spacing: 20) {
                ForEach(ANCHORMoodIcon.MoodType.allCases) { mood in
                    ANCHORMoodIcon(mood: mood, size: 40)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
}
