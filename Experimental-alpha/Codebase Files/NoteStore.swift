import SwiftUI
import SwiftData

class NoteStore: ObservableObject {
    // Use private storage for the notes array
    private var _notes: [Note] = []
    
    // Published property for UI updates
    @Published var currentNote: String = ""
    @Published var isEditingNote: Bool = false
    @Published var editingNoteID: UUID?
    
    // Instead of directly accessing notes array, use this computed property
    var notes: [Note] {
        get { _notes }
    }
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadNotes()
        
        // Add a sample note if no notes exist
        DispatchQueue.main.async { [weak self] in
            if self?.notes.isEmpty == true {
                print("NoteStore: Creating initial note")
                let _ = self?.addNote(content: "# Welcome to Notes\nThis is your first note. You can format text using markdown.")
            }
        }
    }
    
    private func loadNotes() {
        do {
            let descriptor = FetchDescriptor<SwiftDataNote>(sortBy: [SortDescriptor(\.order)])
            let swiftDataNotes = try modelContext.fetch(descriptor)
            _notes = swiftDataNotes.map { $0.toNote() }
            
            // If no notes exist, create a sample note
            if _notes.isEmpty {
                let sampleNote = SwiftDataNote(
                    content: "# Welcome to Notes\nThis is your first note. You can use markdown formatting in your notes.",
                    order: 0
                )
                modelContext.insert(sampleNote)
                _notes.append(sampleNote.toNote())
                try modelContext.save()
            }
        } catch {
            print("Error fetching notes: \(error)")
            // Create a fallback empty array to prevent crashes
            _notes = []
        }
        
        // Notify observers that something changed
        objectWillChange.send()
    }
    
    @discardableResult
    func addNote(content: String) -> Note {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Note(id: UUID(), content: "", creationDate: Date(), lastModifiedDate: Date(), order: 0)
        }
        
        // Calculate new order value safely
        let orderValue: Int
        if _notes.isEmpty {
            orderValue = 0
        } else {
            orderValue = (_notes.map { $0.order }.min() ?? 0) - 1
        }
        
        let newNote = SwiftDataNote(content: content, order: orderValue)
        modelContext.insert(newNote)
        let uiNote = newNote.toNote()
        _notes.insert(uiNote, at: 0)
        currentNote = ""
        saveContext()
        
        // Notify observers that something changed
        objectWillChange.send()
        
        return uiNote
    }
    
    func updateNote(id: UUID, content: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let descriptor = FetchDescriptor<SwiftDataNote>(predicate: #Predicate { $0.id == id })
        do {
            if let noteToUpdate = try modelContext.fetch(descriptor).first {
                noteToUpdate.content = content
                noteToUpdate.lastModifiedDate = Date()
                if let index = _notes.firstIndex(where: { $0.id == id }) {
                    _notes[index] = noteToUpdate.toNote()
                }
                saveContext()
                
                // Notify observers
                objectWillChange.send()
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
                _notes.removeAll { $0.id == id }
                saveContext()
                
                // Notify observers
                objectWillChange.send()
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
        guard !_notes.isEmpty && destinationIndex <= _notes.count else { return }
        
        // Safely reorder notes
        _notes.move(fromOffsets: sourceIndices, toOffset: destinationIndex)
        
        // Update order values
        for i in 0..<_notes.count {
            _notes[i].order = i
        }
        
        // Persist changes
        updateNotesOrder()
        
        // Notify observers
        objectWillChange.send()
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
        guard !_notes.isEmpty else { return }
        
        var hasChanges = false
        
        for note in _notes {
            let descriptor = FetchDescriptor<SwiftDataNote>(predicate: #Predicate { $0.id == note.id })
            do {
                if let noteToUpdate = try modelContext.fetch(descriptor).first {
                    // Only update if order has changed
                    if noteToUpdate.order != note.order {
                        noteToUpdate.order = note.order
                        hasChanges = true
                    }
                }
            } catch {
                print("Error updating note order: \(error)")
            }
        }
        
        // Only save if we made changes
        if hasChanges {
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
