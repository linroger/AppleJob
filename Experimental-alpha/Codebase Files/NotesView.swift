import SwiftUI
import MarkdownUI
import SwiftData

struct NotesView: View {
    @EnvironmentObject var noteStore: NoteStore
    @State private var draggedNote: Note?
    
    var body: some View {
        VStack(spacing: 0) {
            notesScrollView
            
            Divider()
                .padding(.vertical, 8)
            
            noteInputSection
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // Notes list in scrolling format
    private var notesScrollView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(noteStore.notes) { note in
                    NoteCard(note: note)
                        .onDrag {
                            self.draggedNote = note
                            return NSItemProvider(object: note.id.uuidString as NSString)
                        }
                        .onDrop(of: [.text], 
                                isTargeted: nil,
                                perform: { providers in
                            guard let draggedNote = self.draggedNote else { return false }
                            
                            // Get source and destination indices
                            let sourceIndex = noteStore.notes.firstIndex { $0.id == draggedNote.id }!
                            let destinationIndex = noteStore.notes.firstIndex { $0.id == note.id }!
                            
                            // Only reorder if actually moving
                            if sourceIndex != destinationIndex {
                                noteStore.reorderNotes(from: IndexSet(integer: sourceIndex), 
                                                       to: destinationIndex > sourceIndex ? destinationIndex + 1 : destinationIndex)
                            }
                            
                            return true
                        })
                        .contextMenu {
                            Button("Edit Note") {
                                noteStore.beginEditingNote(id: note.id)
                            }
                            
                            Button("Copy Note") {
                                noteStore.copyNoteToClipboard(id: note.id)
                            }
                            
                            Button("Delete Note") {
                                noteStore.deleteNote(id: note.id)
                            }
                        }
                }
            }
            .padding()
        }
        .background(Color(NSColor.textBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
    
    // Note input section at the bottom
    private var noteInputSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text(noteStore.isEditingNote ? "Edit Note" : "New Note")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    noteStore.pasteFromClipboard()
                }) {
                    Label("Paste", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.borderless)
                
                Button(action: {
                    noteStore.currentNote = ""
                }) {
                    Label("Clear", systemImage: "xmark.circle")
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 4)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $noteStore.currentNote)
                    .padding(4)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .frame(minHeight: 100, maxHeight: 200)
                
                if noteStore.currentNote.isEmpty {
                    Text("Enter your notes here...")
                        .foregroundColor(.gray)
                        .padding(8)
                        .allowsHitTesting(false)
                }
            }
            
            HStack {
                Spacer()
                
                if noteStore.isEditingNote {
                    Button("Cancel") {
                        noteStore.isEditingNote = false
                        noteStore.editingNoteID = nil
                        noteStore.currentNote = ""
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Update") {
                        if let id = noteStore.editingNoteID {
                            noteStore.updateNote(id: id, content: noteStore.currentNote)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(noteStore.currentNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } else {
                    Button("Save") {
                        noteStore.addNote(content: noteStore.currentNote)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(noteStore.currentNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// Individual note card
struct NoteCard: View {
    let note: Note
    @EnvironmentObject var noteStore: NoteStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formattedDate(note.creationDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    noteStore.copyNoteToClipboard(id: note.id)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor))
                .opacity(0.5)
            
            Markdown(note.content)
                .markdownTheme(.gitHub)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#if DEBUG
struct NotesView_Previews: PreviewProvider {
    static var previews: some View {
        NotesView()
            .environmentObject(previewNoteStore())
    }
    
    static func previewNoteStore() -> NoteStore {
        // Create a mock ModelContext for previews
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: SwiftDataNote.self, configurations: config)
        let store = NoteStore(modelContext: container.mainContext)
        
        // Add sample notes
        store.notes = [
            Note(id: UUID(), content: "# Important Note\nThis is a sample note with *markdown* support.", creationDate: Date(), lastModifiedDate: Date(), order: 0),
            Note(id: UUID(), content: "## Meeting Notes\n1. First item\n2. Second item\n3. Third item", creationDate: Date().addingTimeInterval(-86400), lastModifiedDate: Date().addingTimeInterval(-86400), order: 1),
            Note(id: UUID(), content: "Remember to **finish the report** by Friday!", creationDate: Date().addingTimeInterval(-172800), lastModifiedDate: Date().addingTimeInterval(-172800), order: 2)
        ]
        
        return store
    }
}
#endif