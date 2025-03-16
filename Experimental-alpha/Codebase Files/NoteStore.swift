import SwiftUI
import SwiftData

// This is a dedicated store to manage the notes feature
class NoteStore: ObservableObject {
    @Published var notes: [Note] = []
    @Published var currentNote: String = ""
    @Published var isEditingNote: Bool = false
    @Published var editingNoteID: UUID?
    @Published var contextMenuSelectedNoteID: UUID?
    
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
    
    func addNote(content: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Generate order value - new notes go at the top by default with lowest order value
        let orderValue = notes.isEmpty ? 0 : notes.map { $0.order }.min()! - 1
        
        // Create the note
        let newNote = SwiftDataNote(
            content: content,
            order: orderValue
        )
        
        // Save to database
        modelContext.insert(newNote)
        
        // Update in-memory collection
        notes.insert(newNote.toNote(), at: 0)
        
        // Clear the input field
        currentNote = ""
        
        saveContext()
    }
    
    func updateNote(id: UUID, content: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Find and update the note in SwiftData
        let descriptor = FetchDescriptor<SwiftDataNote>(predicate: #Predicate { $0.id == id })
        do {
            let foundNotes = try modelContext.fetch(descriptor)
            if let noteToUpdate = foundNotes.first {
                noteToUpdate.content = content
                noteToUpdate.lastModifiedDate = Date()
                
                // Update in-memory collection
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
        // Find and delete the note from SwiftData
        let descriptor = FetchDescriptor<SwiftDataNote>(predicate: #Predicate { $0.id == id })
        do {
            let foundNotes = try modelContext.fetch(descriptor)
            if let noteToDelete = foundNotes.first {
                modelContext.delete(noteToDelete)
                
                // Remove from in-memory collection
                notes.removeAll { $0.id == id }
                
                saveContext()
            }
        } catch {
            print("Error deleting note: \(error)")
        }
    }
    
    func copyNoteToClipboard(id: UUID) {
        if let note = notes.first(where: { $0.id == id }) {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(note.content, forType: .string)
        }
    }
    
    func pasteFromClipboard() {
        let pasteboard = NSPasteboard.general
        if let pastedString = pasteboard.string(forType: .string) {
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
        // Reorder in-memory collection
        notes.move(fromOffsets: sourceIndices, toOffset: destinationIndex)
        
        // Update order values to match new positions
        for i in 0..<notes.count {
            notes[i].order = i
        }
        
        // Update in SwiftData
        updateNotesOrder()
    }
    
    private func updateNotesOrder() {
        // Update order values in SwiftData to match in-memory collection
        for note in notes {
            let descriptor = FetchDescriptor<SwiftDataNote>(predicate: #Predicate { $0.id == note.id })
            do {
                let foundNotes = try modelContext.fetch(descriptor)
                if let noteToUpdate = foundNotes.first {
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