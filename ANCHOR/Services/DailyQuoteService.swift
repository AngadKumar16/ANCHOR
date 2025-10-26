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
    
    @Published private(set) var currentQuote: DailyQuote
    
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
        DailyQuote(text: "The only impossible journey is the one you never begin.", author: "Tony Robbins"),
        DailyQuote(text: "The wound is the place where the Light enters you.", author: "Rumi"),
        DailyQuote(text: "Healing is an art. It takes time, it takes practice. It takes love.", author: "Maza Dohta"),
        DailyQuote(text: "You are not a drop in the ocean. You are the entire ocean in a drop.", author: "Rumi"),
        DailyQuote(text: "The journey of a thousand miles begins with one step.", author: "Lao Tzu"),
        DailyQuote(text: "What lies behind us and what lies before us are tiny matters compared to what lies within us.", author: "Ralph Waldo Emerson"),
        DailyQuote(text: "The only way to make sense out of change is to plunge into it, move with it, and join the dance.", author: "Alan Watts"),
        DailyQuote(text: "Healing takes courage, and we all have courage, even if we have to dig a little to find it.", author: "Tori Amos"),
        DailyQuote(text: "The secret of change is to focus all of your energy, not on fighting the old, but on building the new.", author: "Socrates"),
        DailyQuote(text: "You are never too old to set another goal or to dream a new dream.", author: "C.S. Lewis"),
        DailyQuote(text: "The human capacity for burden is like bamboo – far more flexible than you'd ever believe at first glance.", author: "Jodi Picoult"),
        DailyQuote(text: "Healing is not about changing who you are, but reclaiming who you've always been.", author: "Anonymous"),
        DailyQuote(text: "Every new beginning comes from some other beginning's end.", author: "Seneca"),
        DailyQuote(text: "The oak fought the wind and was broken, the willow bent when it must and survived.", author: "Robert Jordan"),
        DailyQuote(text: "Healing is an inside job that sometimes needs an outside guide.", author: "Anonymous"),
        DailyQuote(text: "You don't have to see the whole staircase, just take the first step.", author: "Martin Luther King Jr."),
        DailyQuote(text: "The soul always knows what to do to heal itself. The challenge is to silence the mind.", author: "Caroline Myss"),
        DailyQuote(text: "Healing is not an overnight process. It is a daily cleansing of pain, it is a daily healing of your life.", author: "Leon Brown"),
        DailyQuote(text: "The greatest healing therapy is friendship and love.", author: "Hubert H. Humphrey"),
        DailyQuote(text: "Healing comes from gathering wisdom from past actions and letting go of negativity through self-forgiveness.", author: "Byron Pulsifer"),
        DailyQuote(text: "The art of healing comes from nature, not from the physician. Therefore, the physician must start from nature, with an open mind.", author: "Paracelsus"),
        DailyQuote(text: "Healing is a matter of time, but it is sometimes also a matter of opportunity.", author: "Hippocrates"),
        DailyQuote(text: "The only real battle in life is between hanging on and letting go.", author: "Shannon L. Alder"),
        DailyQuote(text: "Healing is an art. It takes time, it takes practice. It takes love.", author: "Maza Dohta"),
        DailyQuote(text: "The greatest healing therapy is friendship and love.", author: "Hubert H. Humphrey"),
        DailyQuote(text: "Healing may not be so much about getting better, as about letting go of everything that isn't you.", author: "Rachel Naomi Remen"),
        DailyQuote(text: "The soul always knows what to do to heal itself. The challenge is to silence the mind.", author: "Caroline Myss"),
        DailyQuote(text: "Healing is not an overnight process. It is a daily cleansing of pain, it is a daily healing of your life.", author: "Leon Brown"),
        DailyQuote(text: "The greatest healing therapy is friendship and love.", author: "Hubert H. Humphrey"),
        DailyQuote(text: "Healing comes from gathering wisdom from past actions and letting go of negativity through self-forgiveness.", author: "Byron Pulsifer"),
        DailyQuote(text: "The art of healing comes from nature, not from the physician. Therefore, the physician must start from nature, with an open mind.", author: "Paracelsus"),
        DailyQuote(text: "Healing is a matter of time, but it is sometimes also a matter of opportunity.", author: "Hippocrates"),
        DailyQuote(text: "The only real battle in life is between hanging on and letting go.", author: "Shannon L. Alder"),
        DailyQuote(text: "Healing is an art. It takes time, it takes practice. It takes love.", author: "Maza Dohta"),
        DailyQuote(text: "The greatest healing therapy is friendship and love.", author: "Hubert H. Humphrey"),
        DailyQuote(text: "Healing may not be so much about getting better, as about letting go of everything that isn't you.", author: "Rachel Naomi Remen"),
        DailyQuote(text: "The soul always knows what to do to heal itself. The challenge is to silence the mind.", author: "Caroline Myss"),
        DailyQuote(text: "Healing is not an overnight process. It is a daily cleansing of pain, it is a daily healing of your life.", author: "Leon Brown"),
        DailyQuote(text: "The greatest healing therapy is friendship and love.", author: "Hubert H. Humphrey"),
        DailyQuote(text: "Healing comes from gathering wisdom from past actions and letting go of negativity through self-forgiveness.", author: "Byron Pulsifer"),
        DailyQuote(text: "The art of healing comes from nature, not from the physician. Therefore, the physician must start from nature, with an open mind.", author: "Paracelsus"),
        DailyQuote(text: "Healing is a matter of time, but it is sometimes also a matter of opportunity.", author: "Hippocrates"),
        DailyQuote(text: "The only real battle in life is between hanging on and letting go.", author: "Shannon L. Alder"),
        DailyQuote(text: "Healing is an art. It takes time, it takes practice. It takes love.", author: "Maza Dohta"),
        DailyQuote(text: "The greatest healing therapy is friendship and love.", author: "Hubert H. Humphrey"),
        DailyQuote(text: "Healing may not be so much about getting better, as about letting go of everything that isn't you.", author: "Rachel Naomi Remen"),
        DailyQuote(text: "The soul always knows what to do to heal itself. The challenge is to silence the mind.", author: "Caroline Myss"),
        DailyQuote(text: "Healing is not an overnight process. It is a daily cleansing of pain, it is a daily healing of your life.", author: "Leon Brown"),
        DailyQuote(text: "The greatest healing therapy is friendship and love.", author: "Hubert H. Humphrey"),
        DailyQuote(text: "Healing comes from gathering wisdom from past actions and letting go of negativity through self-forgiveness.", author: "Byron Pulsifer"),
        DailyQuote(text: "The art of healing comes from nature, not from the physician. Therefore, the physician must start from nature, with an open mind.", author: "Paracelsus"),
        DailyQuote(text: "Healing is a matter of time, but it is sometimes also a matter of opportunity.", author: "Hippocrates"),
        DailyQuote(text: "The only real battle in life is between hanging on and letting go.", author: "Shannon L. Alder"),
        DailyQuote(text: "Healing is an art. It takes time, it takes practice. It takes love.", author: "Maza Dohta"),
        DailyQuote(text: "The greatest healing therapy is friendship and love.", author: "Hubert H. Humphrey"),
        DailyQuote(text: "Healing may not be so much about getting better, as about letting go of everything that isn't you.", author: "Rachel Naomi Remen"),
        DailyQuote(text: "The soul always knows what to do to heal itself. The challenge is to silence the mind.", author: "Caroline Myss"),
        DailyQuote(text: "Healing is not an overnight process. It is a daily cleansing of pain, it is a daily healing of your life.", author: "Leon Brown"),
        DailyQuote(text: "The greatest healing therapy is friendship and love.", author: "Hubert H. Humphrey"),
        DailyQuote(text: "Healing comes from gathering wisdom from past actions and letting go of negativity through self-forgiveness.", author: "Byron Pulsifer"),
        DailyQuote(text: "The art of healing comes from nature, not from the physician. Therefore, the physician must start from nature, with an open mind.", author: "Paracelsus"),
        DailyQuote(text: "Healing is a matter of time, but it is sometimes also a matter of opportunity.", author: "Hippocrates"),
        DailyQuote(text: "The only real battle in life is between hanging on and letting go.", author: "Shannon L. Alder"),
        DailyQuote(text: "Healing is an art. It takes time, it takes practice. It takes love.", author: "Maza Dohta"),
        DailyQuote(text: "The greatest healing therapy is friendship and love.", author: "Hubert H. Humphrey"),
        DailyQuote(text: "Healing may not be so much about getting better, as about letting go of everything that isn't you.", author: "Rachel Naomi Remen"),
        DailyQuote(text: "The soul always knows what to do to heal itself. The challenge is to silence the mind.", author: "Caroline Myss"),
        DailyQuote(text: "Healing is not an overnight process. It is a daily cleansing of pain, it is a daily healing of your life.", author: "Leon Brown"),
        DailyQuote(text: "The greatest healing therapy is friendship and love.", author: "Hubert H. Humphrey"),
        DailyQuote(text: "Healing comes from gathering wisdom from past actions and letting go of negativity through self-forgiveness.", author: "Byron Pulsifer"),
        DailyQuote(text: "The art of healing comes from nature, not from the physician. Therefore, the physician must start from nature, with an open mind.", author: "Paracelsus"),
        DailyQuote(text: "Healing is a matter of time, but it is sometimes also a matter of opportunity.", author: "Hippocrates"),
        DailyQuote(text: "The only real battle in life is between hanging on and letting go.", author: "Shannon L. Alder"),
        DailyQuote(text: "Healing is an art. It takes time, it takes practice. It takes love.", author: "Maza Dohta"),
        DailyQuote(text: "The greatest healing therapy is friendship and love.", author: "Hubert H. Humphrey"),
        DailyQuote(text: "Healing may not be so much about getting better, as about letting go of everything that isn't you.", author: "Rachel Naomi Remen"),
        DailyQuote(text: "The soul always knows what to do to heal itself. The challenge is to silence the mind.", author: "Caroline Myss"),
        DailyQuote(text: "Healing is not an overnight process. It is a daily cleansing of pain, it is a daily healing of your life.", author: "Leon Brown"),
        DailyQuote(text: "The greatest healing therapy is friendship and love.", author: "Hubert H. Humphrey"),
        DailyQuote(text: "Healing comes from gathering wisdom from past actions and letting go of negativity through self-forgiveness.", author: "Byron Pulsifer"),
        DailyQuote(text: "The art of healing comes from nature, not from the physician. Therefore, the physician must start from nature, with an open mind.", author: "Paracelsus"),
        DailyQuote(text: "Healing is a matter of time, but it is sometimes also a matter of opportunity.", author: "Hippocrates"),
        DailyQuote(text: "The only real battle in life is between hanging on and letting go.", author: "Shannon L. Alder"),
        DailyQuote(text: "Healing is an art. It takes time, it takes practice. It takes love.", author: "Maza Dohta"),
        DailyQuote(text: "The greatest healing therapy is friendship and love.", author: "Hubert H. Humphrey"),
        DailyQuote(text: "Healing may not be so much about getting better, as about letting go of everything that isn't you.", author: "Rachel Naomi Remen"),
        DailyQuote(text: "The soul always knows what to do to heal itself. The challenge is to silence the mind.", author: "Caroline Myss"),
        DailyQuote(text: "Healing is not an overnight process. It is a daily cleansing of pain, it is a daily healing of your life.", author: "Leon Brown"),
        DailyQuote(text: "The greatest healing therapy is friendship and love.", author: "Hubert H. Humphrey"),
        DailyQuote(text: "Healing comes from gathering wisdom from past actions and letting go of negativity through self-forgiveness.", author: "Byron Pulsifer"),
        DailyQuote(text: "The art of healing comes from nature, not from the physician. Therefore, the physician must start from nature, with an open mind.", author: "Paracelsus"),
        DailyQuote(text: "Healing is a matter of time, but it is sometimes also a matter of opportunity.", author: "Hippocrates"),
        DailyQuote(text: "The only real battle in life is between hanging on and letting go.", author: "Shannon L. Alder"),
        DailyQuote(text: "Healing is an art. It takes time, it takes practice. It takes love.", author: "Maza Dohta"),
        DailyQuote(text: "The greatest healing therapy is friendship and love.", author: "Hubert H. Humphrey"),
        DailyQuote(text: "Healing may not be so much about getting better, as about letting go of everything that isn't you.", author: "Rachel Naomi Remen"),
        DailyQuote(text: "The soul always knows what to do to heal itself. The challenge is to silence the mind.", author: "Caroline Myss"),
        DailyQuote(text: "Healing is not an overnight process. It is a daily cleansing of pain, it is a daily healing of your life.", author: "Leon Brown"),
        DailyQuote(text: "The greatest healing therapy is friendship and love.", author: "Hubert H. Humphrey"),
        DailyQuote(text: "Healing comes from gathering wisdom from past actions and letting go of negativity through self-forgiveness.", author: "Byron Pulsifer"),
        DailyQuote(text: "The art of healing comes from nature, not from the physician. Therefore, the physician must start from nature, with an open mind.", author: "Paracelsus"),
        DailyQuote(text: "Healing is a matter of time, but it is sometimes also a matter of opportunity.", author: "Hippocrates"),
        DailyQuote(text: "The only real battle in life is between hanging on and letting go.", author: "Shannon L. Alder")
    ]

    
    private init() {
        // Initialize with today's quote
        self.currentQuote = getQuoteForToday()
    }
    
    private func getQuoteForToday() -> DailyQuote {
        // Use the day of the year to get a consistent quote for each day
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let quoteIndex = dayOfYear % self.quotes.count
        return self.quotes[quoteIndex]
    }

    
    func refreshQuote() {
        // Get a random quote that's different from the current one
        var newQuote: DailyQuote
        repeat {
            newQuote = quotes.randomElement() ?? currentQuote
        } while newQuote.text == currentQuote.text && quotes.count > 1
        
        currentQuote = newQuote
    }
    
    // For backward compatibility
    func getTodaysQuote() -> DailyQuote {
        return currentQuote
    }
}
