import SwiftUI
import SwiftData

class NoteStore: ObservableObject {
    @Published var notes: [Note] = []
    @Published var currentNote: String = ""
    @Published var isEditingNote: Bool = false
    @Published var editingNoteID: UUID?
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadNotes()
    }
    
    private func loadNotes() {
        let descriptor = FetchDescriptor<SwiftDataNote>(sortBy: [SortDescriptor(\.order)])
        do {
            let swiftDataNotes = try modelContext.fetch(descriptor)
            notes = swiftDataNotes.map { $0.toNote() }
        } catch {
            print("Error fetching notes: \(error)")
        }
    }
    
    @discardableResult
    func addNote(content: String) -> Note {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Note(id: UUID(), content: "", creationDate: Date(), lastModifiedDate: Date(), order: 0)
        }
        
        let orderValue = notes.isEmpty ? 0 : notes.map { $0.order }.min()! - 1
        let newNote = SwiftDataNote(content: content, order: orderValue)
        modelContext.insert(newNote)
        let uiNote = newNote.toNote()
        notes.insert(uiNote, at: 0)
        currentNote = ""
        saveContext()
        return uiNote
    }
    
    func updateNote(id: UUID, content: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let descriptor = FetchDescriptor<SwiftDataNote>(predicate: #Predicate { $0.id == id })
        do {
            if let noteToUpdate = try modelContext.fetch(descriptor).first {
                noteToUpdate.content = content
                noteToUpdate.lastModifiedDate = Date()
                if let index = notes.firstIndex(where: { $0.id == id }) {
                    notes[index] = noteToUpdate.toNote()
                }
                saveContext()
            }
        } catch {
            print("Error updating note: \(error)")
        }
        isEditingNote = false
        editingNoteID = nil
    }
    
    func deleteNote(id: UUID) {
        let descriptor = FetchDescriptor<SwiftDataNote>(predicate: #Predicate { $0.id == id })
        do {
            if let noteToDelete = try modelContext.fetch(descriptor).first {
                modelContext.delete(noteToDelete)
                notes.removeAll { $0.id == id }
                saveContext()
            }
        } catch {
            print("Error deleting note: \(error)")
        }
    }
    
    func copyNoteToClipboard(id: UUID) {
        if let note = notes.first(where: { $0.id == id }) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(note.content, forType: .string)
        }
    }
    
    func pasteFromClipboard() {
        if let pastedString = NSPasteboard.general.string(forType: .string) {
            currentNote = pastedString
        }
    }
    
    func beginEditingNote(id: UUID) {
        editingNoteID = id
        isEditingNote = true
        if let note = notes.first(where: { $0.id == id }) {
            currentNote = note.content
        }
    }
    
    func reorderNotes(from sourceIndices: IndexSet, to destinationIndex: Int) {
        notes.move(fromOffsets: sourceIndices, toOffset: destinationIndex)
        for i in 0..<notes.count {
            notes[i].order = i
        }
        updateNotesOrder()
    }
    
    func importNotes(from url: URL) {
        do {
            let markdown = try String(contentsOf: url)
            let notesText = markdown.components(separatedBy: "---\n\n")
            for noteText in notesText {
                let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    addNote(content: trimmed)
                }
            }
        } catch {
            print("Error importing notes: \(error)")
        }
    }
    
    private func updateNotesOrder() {
        for note in notes {
            let descriptor = FetchDescriptor<SwiftDataNote>(predicate: #Predicate { $0.id == note.id })
            do {
                if let noteToUpdate = try modelContext.fetch(descriptor).first {
                    noteToUpdate.order = note.order
                }
            } catch {
                print("Error updating note order: \(error)")
            }
        }
        saveContext()
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
