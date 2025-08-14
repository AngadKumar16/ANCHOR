//
//  ANCHORApp.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/8/25.
//

import SwiftUI

@main
struct ANCHORApp: App {
    
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
