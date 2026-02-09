import SwiftData
import SwiftUI

/// A sheet for editing a task's title and notes.
///
/// Extracted from RegionFocusView to be shared with BacklogView.
struct TaskEditSheet: View {
    let task: CharstackTask
    let onSave: (_ title: String, _ notes: String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editedTitle: String
    @State private var editedNotes: String

    init(task: CharstackTask, onSave: @escaping (_ title: String, _ notes: String?) -> Void) {
        self.task = task
        self.onSave = onSave
        _editedTitle = State(initialValue: task.title)
        _editedNotes = State(initialValue: task.notes ?? "")
    }

    private var isTitleValid: Bool {
        !editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Task title", text: $editedTitle)
                }
                Section("Notes") {
                    TextField("Optional notes", text: $editedNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let notes = editedNotes.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(
                            editedTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                            notes.isEmpty ? nil : notes
                        )
                        dismiss()
                    }
                    .disabled(!isTitleValid)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    TaskEditSheet(
        task: PreviewData.singleTask,
        onSave: { _, _ in }
    )
    .modelContainer(PreviewData.container)
}
