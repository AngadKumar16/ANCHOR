import UIKit
import os.log

class AppDelegate: NSObject, UIApplicationDelegate {
    private let logger = OSLog(subsystem: "com.angadkumar16.ANCHOR", category: "AppDelegate")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Setup any third-party services here
        setupAppearance()
        return true
    }
    
    private func setupAppearance() {
        // Customize the appearance of UI elements
        UINavigationBar.appearance().tintColor = UIColor(ANCHORDesign.Colors.primary)
        UISwitch.appearance().onTintColor = UIColor(ANCHORDesign.Colors.primary)
    }
    
    // Add other app lifecycle methods as needed
    func applicationWillTerminate(_ application: UIApplication) {
        // Save any pending changes
        saveContext()
    }
    
    private func saveContext() {
        let context = PersistenceController.shared.container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                os_log("❌ Error saving context: %{public}@", 
                      log: logger, 
                      type: .error, 
                      nsError.localizedDescription)
            }
        }
    }
}
