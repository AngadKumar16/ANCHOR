//
//  ANCHORApp.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/8/25.
//

import SwiftUI

@main
struct ANCHORApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var persistence = PersistenceController.shared
    
    // Add thread checking
    init() {
        #if DEBUG
        // Enable Core Data concurrency debugging
        UserDefaults.standard.set(true, forKey: "-com.apple.CoreData.ConcurrencyDebug")
        
        // Enable Core Data SQL debug logging
        UserDefaults.standard.set(3, forKey: "com.apple.CoreData.SQLDebug")
        
        // Enable Core Data validation
        UserDefaults.standard.set(true, forKey: "-com.apple.CoreData.Validation.preserveValidationErrors")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(\.managedObjectContext, persistence.viewContext)
                .environmentObject(persistence)
        }
    }
}
