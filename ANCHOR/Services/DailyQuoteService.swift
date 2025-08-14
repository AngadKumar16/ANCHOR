//
//  DailyQuoteService.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import Foundation

struct DailyQuote {
    let text: String
    let author: String
}

class DailyQuoteService: ObservableObject {
    static let shared = DailyQuoteService()
    
    private let quotes = [
        DailyQuote(text: "One day at a time.", author: "AA Motto"),
        DailyQuote(text: "Progress, not perfection.", author: "Anonymous"),
        DailyQuote(text: "You are stronger than you think.", author: "Anonymous"),
        DailyQuote(text: "Recovery is not a destination, it's a journey.", author: "Anonymous"),
        DailyQuote(text: "Every moment is a fresh beginning.", author: "T.S. Eliot"),
        DailyQuote(text: "The only way out is through.", author: "Robert Frost"),
        DailyQuote(text: "You have been assigned this mountain to show others it can be moved.", author: "Mel Robbins"),
        DailyQuote(text: "Healing isn't about erasing the past, it's about choosing your future.", author: "Anonymous"),
        DailyQuote(text: "Your current situation is not your final destination.", author: "Anonymous"),
        DailyQuote(text: "Rock bottom became the solid foundation on which I rebuilt my life.", author: "J.K. Rowling"),
        DailyQuote(text: "The comeback is always stronger than the setback.", author: "Anonymous"),
        DailyQuote(text: "You are not your mistakes. You are not your struggles.", author: "Anonymous"),
        DailyQuote(text: "Courage doesn't always roar. Sometimes it's the quiet voice saying 'I will try again tomorrow.'", author: "Mary Anne Radmacher"),
        DailyQuote(text: "Recovery is about progression, not perfection.", author: "Anonymous"),
        DailyQuote(text: "The strongest people are not those who show strength in front of us, but those who win battles we know nothing about.", author: "Anonymous"),
        DailyQuote(text: "Your story isn't over yet.", author: "Anonymous"),
        DailyQuote(text: "Take it one breath at a time.", author: "Anonymous"),
        DailyQuote(text: "You didn't come this far to only come this far.", author: "Anonymous"),
        DailyQuote(text: "Recovery is giving yourself permission to live.", author: "Anonymous"),
        DailyQuote(text: "The only impossible journey is the one you never begin.", author: "Tony Robbins")
    ]
    
    private init() {}
    
    func getTodaysQuote() -> DailyQuote {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % quotes.count
        return quotes[index]
    }
    
    func getRandomQuote() -> DailyQuote {
        return quotes.randomElement() ?? quotes[0]
    }
}
