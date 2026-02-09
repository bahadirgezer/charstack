import Foundation
import SwiftData

/// Provides sample data and container factories for SwiftUI previews.
///
/// All preview data is in-memory and does not persist between sessions.
/// Use `PreviewData.container` for `@Previewable` model container injection.
@MainActor
enum PreviewData {

    /// Creates a fresh in-memory ModelContainer pre-populated with sample tasks.
    static var container: ModelContainer {
        do {
            let container = try ModelContainerSetup.createTestingContainer()
            let context = container.mainContext

            for task in sampleTasks {
                context.insert(task)
            }
            try context.save()
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }

    /// A representative set of tasks across all regions and buckets.
    static var sampleTasks: [CharstackTask] {
        let today = Date()
        return [
            // Morning tasks
            CharstackTask(
                title: "Review quarterly report",
                region: .morning,
                bucket: .must,
                plannedDate: today,
                sortOrder: 0
            ),
            CharstackTask(
                title: "Reply to team emails",
                region: .morning,
                bucket: .complementary,
                plannedDate: today,
                sortOrder: 0
            ),
            CharstackTask(
                title: "Update project board",
                region: .morning,
                bucket: .complementary,
                plannedDate: today,
                sortOrder: 1
            ),
            CharstackTask(
                title: "Water office plants",
                region: .morning,
                bucket: .misc,
                plannedDate: today,
                sortOrder: 0
            ),
            CharstackTask(
                title: "Organize desk",
                notes: "Clear out old papers and file important documents",
                region: .morning,
                bucket: .misc,
                plannedDate: today,
                sortOrder: 1
            ),

            // Afternoon tasks
            CharstackTask(
                title: "Finish API integration",
                notes: "Complete the REST endpoints for the user service",
                region: .afternoon,
                bucket: .must,
                plannedDate: today,
                sortOrder: 0
            ),
            CharstackTask(
                title: "Write unit tests",
                region: .afternoon,
                bucket: .complementary,
                plannedDate: today,
                sortOrder: 0
            ),
            CharstackTask(
                title: "Code review PR #42",
                region: .afternoon,
                bucket: .misc,
                plannedDate: today,
                sortOrder: 0
            ),

            // Evening tasks
            CharstackTask(
                title: "Plan tomorrow's tasks",
                region: .evening,
                bucket: .must,
                plannedDate: today,
                sortOrder: 0
            ),
            CharstackTask(
                title: "Read architecture chapter",
                region: .evening,
                bucket: .complementary,
                plannedDate: today,
                sortOrder: 0
            ),

            // Completed task (morning)
            CharstackTask(
                title: "Morning standup",
                region: .morning,
                bucket: .misc,
                status: .done,
                plannedDate: today,
                sortOrder: 2,
                completedAt: today
            ),

            // Backlog tasks
            CharstackTask(
                title: "Research CI/CD options",
                notes: "Compare GitHub Actions, Bitrise, and Xcode Cloud",
                region: .backlog,
                bucket: .unassigned,
                status: .deferred,
                plannedDate: today.addingDays(-1),
                sortOrder: 0
            ),
            CharstackTask(
                title: "Update app icons",
                region: .backlog,
                bucket: .unassigned,
                status: .deferred,
                plannedDate: today.addingDays(-2),
                sortOrder: 1
            ),
        ]
    }

    /// A single sample task for isolated component previews.
    static var singleTask: CharstackTask {
        CharstackTask(
            title: "Sample task",
            notes: "This is a sample task for previews",
            region: .morning,
            bucket: .must,
            plannedDate: Date(),
            sortOrder: 0
        )
    }

    /// A completed sample task for previews.
    static var completedTask: CharstackTask {
        CharstackTask(
            title: "Completed task",
            region: .morning,
            bucket: .complementary,
            status: .done,
            plannedDate: Date(),
            sortOrder: 0,
            completedAt: Date()
        )
    }
}
