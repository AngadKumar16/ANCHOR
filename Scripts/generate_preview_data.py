#!/usr/bin/env python3

"""
ANCHOR Preview Data Generator
This script generates realistic preview/demo data for the ANCHOR mental health app
including journal entries, risk assessments, and user profile data.
"""

import json
import sqlite3
import os
import sys
from datetime import datetime, timedelta
import random
import uuid
from pathlib import Path

# Configuration
SCRIPT_DIR = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent
OUTPUT_DIR = PROJECT_DIR / "PreviewData"

# Sample data for generating realistic content
JOURNAL_TITLES = [
    "Morning Reflections",
    "Feeling Grateful Today",
    "Challenging Day at Work",
    "Weekend Recovery",
    "Meeting with Therapist",
    "Family Time",
    "Meditation Session",
    "Anxiety Management",
    "Progress Check-in",
    "New Coping Strategy",
    "Celebrating Small Wins",
    "Difficult Conversation",
    "Self-Care Sunday",
    "Therapy Homework",
    "Mindfulness Practice"
]

JOURNAL_BODIES = [
    "Today I woke up feeling more optimistic than usual. I've been practicing the breathing exercises from my therapist and they really seem to help with my morning anxiety. I'm grateful for having tools to manage my mental health.",
    
    "Had a really challenging day at work today. My manager was being particularly demanding and I felt overwhelmed. But instead of reaching for unhealthy coping mechanisms, I took a 10-minute walk and did some deep breathing. Small victories count.",
    
    "Spent quality time with my family today. It reminded me why I'm working so hard on my recovery. My kids deserve the best version of me, and I'm committed to being present for them.",
    
    "Therapy session went well today. We talked about identifying triggers and developing healthier response patterns. I'm learning that recovery is a process, not a destination.",
    
    "Feeling grateful for my support system today. Called my sponsor and we had a great conversation about staying accountable. It's amazing how much better I feel after connecting with someone who understands.",
    
    "Practiced mindfulness meditation for 15 minutes this morning. It's becoming easier to observe my thoughts without judgment. This practice is really helping me stay centered throughout the day.",
    
    "Had some cravings today but I used my coping strategies. Called a friend, went for a walk, and reminded myself of my goals. The craving passed and I feel stronger for having worked through it.",
    
    "Celebrated 30 days of sobriety today! It feels incredible to have made it this far. Each day is still a choice, but I'm getting better at making the right one.",
    
    "Attended a support group meeting tonight. Hearing other people's stories reminds me that I'm not alone in this journey. We're all working toward the same goal of healing and growth.",
    
    "Feeling anxious about an upcoming presentation at work. Instead of catastrophizing, I'm trying to focus on what I can control: preparation, self-care, and using my coping skills.",
    
    "Had a setback today but I'm trying not to be too hard on myself. Recovery isn't linear, and I'm learning to treat myself with the same compassion I'd show a friend.",
    
    "Spent time in nature today and it was incredibly grounding. There's something about being outdoors that puts things in perspective and reminds me of what's truly important.",
    
    "Working on forgiveness - both for others and for myself. It's one of the hardest parts of recovery, but I know it's essential for my healing and growth.",
    
    "Feeling proud of how I handled a stressful situation today. Six months ago, I would have reacted very differently. Growth is happening, even when it's hard to see.",
    
    "Reflecting on my journey so far. There have been ups and downs, but overall I can see how much I've grown. I'm becoming the person I want to be, one day at a time."
]

JOURNAL_TAGS = [
    ["Grateful", "Positive"],
    ["Anxious", "Work", "Coping"],
    ["Family", "Motivation"],
    ["Therapy", "Growth"],
    ["Support", "Accountability"],
    ["Mindfulness", "Meditation"],
    ["Cravings", "Strength"],
    ["Milestone", "Celebration"],
    ["Community", "Support"],
    ["Anxiety", "Work"],
    ["Setback", "Self-Compassion"],
    ["Nature", "Grounding"],
    ["Forgiveness", "Healing"],
    ["Growth", "Progress"],
    ["Reflection", "Journey"]
]

RISK_REASONS = [
    "Feeling overwhelmed with work stress and family responsibilities",
    "Experiencing strong cravings after seeing old friends",
    "Having trouble sleeping and feeling emotionally unstable",
    "Dealing with relationship conflicts and feeling isolated",
    "Financial stress is causing significant anxiety",
    "Feeling depressed and having difficulty with daily activities",
    "Experiencing physical symptoms of anxiety and panic",
    "Struggling with negative thought patterns and self-doubt",
    "Feeling triggered by environmental factors",
    "Having difficulty managing emotions after a difficult conversation"
]

def create_output_directory():
    """Create output directory if it doesn't exist"""
    OUTPUT_DIR.mkdir(exist_ok=True)
    print(f"📁 Created output directory: {OUTPUT_DIR}")

def generate_journal_entries(count=15):
    """Generate realistic journal entries"""
    entries = []
    base_date = datetime.now() - timedelta(days=60)
    
    for i in range(count):
        # Create entries with realistic spacing (not every day)
        days_offset = random.randint(1, 5)
        entry_date = base_date + timedelta(days=i * days_offset)
        
        # Select random content
        title_idx = random.randint(0, len(JOURNAL_TITLES) - 1)
        body_idx = random.randint(0, len(JOURNAL_BODIES) - 1)
        tags_idx = random.randint(0, len(JOURNAL_TAGS) - 1)
        
        entry = {
            "id": str(uuid.uuid4()),
            "title": JOURNAL_TITLES[title_idx],
            "body": JOURNAL_BODIES[body_idx],
            "tags": JOURNAL_TAGS[tags_idx],
            "createdAt": entry_date.isoformat(),
            "updatedAt": entry_date.isoformat(),
            "sentiment": random.choice(["positive", "neutral", "negative"]),
            "sentimentScore": round(random.uniform(0.1, 0.9), 2)
        }
        entries.append(entry)
    
    return sorted(entries, key=lambda x: x["createdAt"], reverse=True)

def generate_risk_assessments(count=8):
    """Generate realistic risk assessments"""
    assessments = []
    base_date = datetime.now() - timedelta(days=45)
    
    for i in range(count):
        # Create assessments with realistic spacing
        days_offset = random.randint(3, 10)
        assessment_date = base_date + timedelta(days=i * days_offset)
        
        # Generate realistic risk scores (mostly low to moderate)
        risk_score = random.choices(
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            weights=[5, 8, 10, 12, 15, 12, 8, 5, 3, 2]  # Weighted toward lower scores
        )[0]
        
        assessment = {
            "id": str(uuid.uuid4()),
            "score": risk_score,
            "reason": random.choice(RISK_REASONS),
            "createdAt": assessment_date.isoformat(),
            "riskLevel": "low" if risk_score <= 3 else "moderate" if risk_score <= 6 else "high"
        }
        assessments.append(assessment)
    
    return sorted(assessments, key=lambda x: x["createdAt"], reverse=True)

def generate_user_profile():
    """Generate a realistic user profile"""
    sobriety_start = datetime.now() - timedelta(days=random.randint(30, 365))
    
    profile = {
        "id": str(uuid.uuid4()),
        "displayName": "Demo User",
        "sobrietyStartDate": sobriety_start.isoformat(),
        "currentStreak": (datetime.now() - sobriety_start).days,
        "longestStreak": (datetime.now() - sobriety_start).days + random.randint(0, 30),
        "totalJournalEntries": 15,
        "totalRiskAssessments": 8,
        "createdAt": (datetime.now() - timedelta(days=90)).isoformat(),
        "updatedAt": datetime.now().isoformat(),
        "preferences": {
            "dailyReminders": True,
            "weeklyReports": True,
            "shareAnalytics": False
        }
    }
    
    return profile

def generate_preview_data():
    """Generate all preview data"""
    print("🎯 Generating ANCHOR Preview Data")
    print("=" * 40)
    
    # Create output directory
    create_output_directory()
    
    # Generate data
    print("📝 Generating journal entries...")
    journal_entries = generate_journal_entries()
    
    print("⚠️  Generating risk assessments...")
    risk_assessments = generate_risk_assessments()
    
    print("👤 Generating user profile...")
    user_profile = generate_user_profile()
    
    # Create comprehensive preview data structure
    preview_data = {
        "metadata": {
            "generatedAt": datetime.now().isoformat(),
            "version": "1.0",
            "description": "Preview data for ANCHOR mental health app",
            "totalEntries": len(journal_entries),
            "totalAssessments": len(risk_assessments)
        },
        "userProfile": user_profile,
        "journalEntries": journal_entries,
        "riskAssessments": risk_assessments
    }
    
    # Save as JSON
    json_file = OUTPUT_DIR / "anchor_preview_data.json"
    with open(json_file, 'w', encoding='utf-8') as f:
        json.dump(preview_data, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Saved JSON data: {json_file}")
    
    # Generate Swift code for easy integration
    swift_file = OUTPUT_DIR / "PreviewData.swift"
    generate_swift_preview_code(preview_data, swift_file)
    
    # Generate summary report
    generate_summary_report(preview_data)
    
    print("\n🎉 Preview data generation complete!")
    print(f"📁 Output directory: {OUTPUT_DIR}")
    print(f"📊 Generated {len(journal_entries)} journal entries")
    print(f"📊 Generated {len(risk_assessments)} risk assessments")
    print(f"📊 Generated user profile with {user_profile['currentStreak']} day streak")

def generate_swift_preview_code(data, output_file):
    """Generate Swift code for easy integration into Xcode previews"""
    swift_code = '''//
//  PreviewData.swift
//  ANCHOR
//
//  Generated by generate_preview_data.py
//

import Foundation

struct PreviewData {
    static let shared = PreviewData()
    
    // MARK: - User Profile
    static let sampleUserProfile = UserProfileModel(
        id: UUID(),
        displayName: "Demo User",
        sobrietyStartDate: Calendar.current.date(byAdding: .day, value: -''' + str(data['userProfile']['currentStreak']) + ''', to: Date()) ?? Date(),
        createdAt: Date()
    )
    
    // MARK: - Journal Entries
    static let sampleJournalEntries: [JournalEntryModel] = [
'''
    
    # Add sample journal entries
    for i, entry in enumerate(data['journalEntries'][:5]):  # Limit to 5 for preview
        swift_code += f'''        JournalEntryModel(
            id: UUID(),
            title: "{entry['title']}",
            body: "{entry['body'][:100]}...",
            tags: {entry['tags']},
            createdAt: Date(),
            sentiment: "{entry['sentiment']}",
            sentimentScore: {entry['sentimentScore']}
        ){"," if i < 4 else ""}
'''
    
    swift_code += '''    ]
    
    // MARK: - Risk Assessments
    static let sampleRiskAssessments: [RiskAssessmentModel] = [
'''
    
    # Add sample risk assessments
    for i, assessment in enumerate(data['riskAssessments'][:3]):  # Limit to 3 for preview
        swift_code += f'''        RiskAssessmentModel(
            id: UUID(),
            score: {assessment['score']},
            reason: "{assessment['reason'][:50]}...",
            createdAt: Date()
        ){"," if i < 2 else ""}
'''
    
    swift_code += '''    ]
}

// MARK: - Preview Extensions
extension JournalEntryModel {
    static var preview: JournalEntryModel {
        PreviewData.sampleJournalEntries.first!
    }
}

extension RiskAssessmentModel {
    static var preview: RiskAssessmentModel {
        PreviewData.sampleRiskAssessments.first!
    }
}

extension UserProfileModel {
    static var preview: UserProfileModel {
        PreviewData.sampleUserProfile
    }
}
'''
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(swift_code)
    
    print(f"✅ Generated Swift preview code: {output_file}")

def generate_summary_report(data):
    """Generate a summary report of the generated data"""
    report_file = OUTPUT_DIR / "generation_report.txt"
    
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("ANCHOR Preview Data Generation Report\n")
        f.write("=" * 50 + "\n\n")
        f.write(f"Generated: {data['metadata']['generatedAt']}\n")
        f.write(f"Version: {data['metadata']['version']}\n\n")
        
        f.write("Data Summary:\n")
        f.write("-" * 20 + "\n")
        f.write(f"Journal Entries: {len(data['journalEntries'])}\n")
        f.write(f"Risk Assessments: {len(data['riskAssessments'])}\n")
        f.write(f"User Streak: {data['userProfile']['currentStreak']} days\n\n")
        
        f.write("Journal Entry Tags Distribution:\n")
        f.write("-" * 35 + "\n")
        tag_counts = {}
        for entry in data['journalEntries']:
            for tag in entry['tags']:
                tag_counts[tag] = tag_counts.get(tag, 0) + 1
        
        for tag, count in sorted(tag_counts.items(), key=lambda x: x[1], reverse=True):
            f.write(f"{tag}: {count}\n")
        
        f.write("\nRisk Assessment Distribution:\n")
        f.write("-" * 30 + "\n")
        risk_levels = {"low": 0, "moderate": 0, "high": 0}
        for assessment in data['riskAssessments']:
            risk_levels[assessment['riskLevel']] += 1
        
        for level, count in risk_levels.items():
            f.write(f"{level.title()}: {count}\n")
        
        f.write("\nFiles Generated:\n")
        f.write("-" * 20 + "\n")
        f.write("- anchor_preview_data.json (Complete data set)\n")
        f.write("- PreviewData.swift (Swift integration code)\n")
        f.write("- generation_report.txt (This report)\n")
        
        f.write("\nUsage Instructions:\n")
        f.write("-" * 20 + "\n")
        f.write("1. Copy PreviewData.swift to your Xcode project\n")
        f.write("2. Use PreviewData.sampleJournalEntries in SwiftUI previews\n")
        f.write("3. Import JSON data for testing or demo purposes\n")
        f.write("4. Modify data as needed for specific test scenarios\n")
    
    print(f"✅ Generated summary report: {report_file}")

if __name__ == "__main__":
    try:
        generate_preview_data()
    except KeyboardInterrupt:
        print("\n❌ Generation cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error generating preview data: {e}")
        sys.exit(1)