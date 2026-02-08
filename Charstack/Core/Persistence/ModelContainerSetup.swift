import Foundation
import SwiftData

/// Configures and creates the SwiftData `ModelContainer` for the app.
///
/// Provides both the production container (on-disk persistence) and a
/// testing container (in-memory, no persistence) for unit tests.
enum ModelContainerSetup {
    /// All SwiftData model types registered in the app's schema.
    static let modelTypes: [any PersistentModel.Type] = [
        CharstackTask.self
    ]

    /// The schema definition for the current version of the data model.
    static let schema = Schema(modelTypes)

    /// Creates the production `ModelContainer` with on-disk persistence.
    ///
    /// - Returns: A configured `ModelContainer` for use in the app.
    /// - Throws: If the container cannot be created (e.g., disk error).
    static func createProductionContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            "Charstack",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// Creates an in-memory `ModelContainer` for testing and previews.
    ///
    /// Data stored in this container does not persist between launches.
    ///
    /// - Returns: An in-memory `ModelContainer`.
    /// - Throws: If the container cannot be created.
    static func createTestingContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            "CharstackTest",
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
