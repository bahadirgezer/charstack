import SwiftData
import SwiftUI

@main
struct CharstackApp: App {
    /// The shared SwiftData model container for the entire app.
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainerSetup.createProductionContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
