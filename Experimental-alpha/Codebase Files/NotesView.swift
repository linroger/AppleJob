import SwiftUI
import MarkdownUI
import SwiftData
import UniformTypeIdentifiers

extension View {
    func gradientForeground(colors: [Color]) -> some View {
        self.overlay(
            LinearGradient(gradient: Gradient(colors: colors), startPoint: .leading, endPoint: .trailing)
                .mask(self)
        )
    }
}

struct NotesSidebar: View {
    var noteStore: NoteStore
    @State private var searchText = ""
    @State private var draggedNote: Note?
    @Binding var selectedNoteID: UUID?
    
    var body: some View {
        VStack(alignment: .leading) {
            List {
                if noteStore.notes.isEmpty {
                    Text("No notes available")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(filteredNotes) { note in
                        noteListItem(note: note)
                            .listRowBackground(getRowBackground(for: note))
                            .onTapGesture { selectedNoteID = note.id }
                            .onDrag {
                                self.draggedNote = note
                                return NSItemProvider(object: note.id.uuidString as NSString)
                            }
                            .onDrop(of: [.text], isTargeted: nil) { providers in
                                handleDrop(for: note)
                            }
                    }
                }
            }
            .listStyle(.sidebar)
            .contextMenu {
                Button("New Note") { 
                    noteStore.currentNote = "" 
                    selectedNoteID = nil
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    noteStore.currentNote = ""
                    selectedNoteID = nil
                }) {
                    Label("New Note", systemImage: "square.and.pencil")
                }
            }
        }
        .onAppear {
            // Create a sample note if needed
            if noteStore.notes.isEmpty {
                let sampleNote = noteStore.addNote(content: "# Welcome to Notes\nThis is your first note. You can use markdown formatting.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.selectedNoteID = sampleNote.id
                }
            }
        }
    }
    
    private func noteListItem(note: Note) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(extractTitle(from: note.content))
                .font(.headline)
                .lineLimit(1)
                .gradientForeground(colors: [.blue, .purple])
            Text(generatePreview(from: note.content, excludingTitle: true))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .padding(.bottom, 4)
        }
        .contextMenu {
            Button("Edit Note") { noteStore.beginEditingNote(id: note.id) }
            Button("New Note") { noteStore.currentNote = "" }
            Button("Copy Note") { noteStore.copyNoteToClipboard(id: note.id) }
            Button("Delete Note") { noteStore.deleteNote(id: note.id) }
        }
    }
    
    private func handleDrop(for note: Note) -> Bool {
        // Safety checks
        guard !noteStore.notes.isEmpty,
              let draggedNote = self.draggedNote else { return false }
        
        // Make sure both notes exist in our data store
        guard let sourceIndex = noteStore.notes.firstIndex(where: { $0.id == draggedNote.id }),
              let destinationIndex = noteStore.notes.firstIndex(where: { $0.id == note.id }) else { return false }
              
        // Don't reorder if dropping on self
        guard sourceIndex != destinationIndex else { return false }
        
        // Calculate new position and reorder
        let reorderIndex = destinationIndex > sourceIndex ? destinationIndex + 1 : destinationIndex
        noteStore.reorderNotes(from: IndexSet(integer: sourceIndex), to: reorderIndex)
        return true
    }
    
    private func getRowBackground(for note: Note) -> some View {
        let isSelected = selectedNoteID == note.id
        let fillColor: AnyShapeStyle = isSelected ?
            AnyShapeStyle(LinearGradient(gradient: Gradient(colors: [.pink.opacity(0.2), .purple.opacity(0.2)]), startPoint: .leading, endPoint: .trailing)) :
            AnyShapeStyle(Color.clear)
        return RoundedRectangle(cornerRadius: 8).fill(fillColor).padding(.vertical, 2)
    }
    
    private func extractTitle(from content: String) -> String {
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.first?.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression) ?? "Untitled Note"
    }
    
    private func generatePreview(from content: String, excludingTitle: Bool) -> String {
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        if excludingTitle && lines.count > 1 {
            return lines[1...].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var filteredNotes: [Note] {
        if noteStore.notes.isEmpty {
            return []
        }
        
        if searchText.isEmpty {
            return noteStore.notes
        } else {
            let searchTermLowercased = searchText.lowercased()
            return noteStore.notes.filter { 
                $0.content.lowercased().contains(searchTermLowercased)
            }
        }
    }
}

struct NotesView: View {
    @EnvironmentObject var noteStore: NoteStore
    @AppStorage("showFullNoteCards") private var showFullNoteCards = false
    @State private var draggedNote: Note?
    @State private var searchText = ""
    @State private var dividerPosition: CGFloat = 0.3
    @Binding var selectedNoteID: UUID?
    @State private var isInitialized = false
    
    // Initialize with optional binding, defaulting to internal state if not provided
    init(selectedNoteID: Binding<UUID?> = .constant(nil)) {
        self._selectedNoteID = selectedNoteID
    }
    
    var body: some View {
        VStack {
            if noteStore.notes.isEmpty {
                // Empty state view
                VStack {
                    Text("No notes yet")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("Create a new note to get started")
                        .foregroundColor(.secondary)
                        
                    Button("Create New Note") {
                        let newNote = noteStore.addNote(content: "# Welcome to Notes\nThis is your first note.")
                        selectedNoteID = newNote.id
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredNotes) { note in
                            NoteCardView(note: note, isSelected: selectedNoteID == note.id)
                                .onTapGesture { selectedNoteID = note.id }
                                .onDrag {
                                    self.draggedNote = note
                                    return NSItemProvider(object: note.id.uuidString as NSString)
                                }
                                .onDrop(of: [.text], isTargeted: nil) { providers in
                                    handleDrop(for: note)
                                }
                                .contextMenu {
                                    Button("Edit Note") { noteStore.beginEditingNote(id: note.id) }
                                    Button("New Note") { noteStore.currentNote = ""; selectedNoteID = nil }
                                    Button("Copy Note") { noteStore.copyNoteToClipboard(id: note.id) }
                                    Button("Delete Note") { noteStore.deleteNote(id: note.id) }
                                }
                        }
                    }
                    .padding()
                }
            }
            
            GeometryReader { geometry in
                Color.clear
                    .frame(height: 6)
                    .background(Color(NSColor.separatorColor).opacity(0.5))
                    .overlay(
                        Rectangle()
                            .fill(Color.gray.opacity(0.01))
                            .frame(height: 12)
                            .onHover { hovering in
                                hovering ? NSCursor.resizeUpDown.push() : NSCursor.pop()
                            }
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let availableHeight = geometry.size.height
                                        dividerPosition = max(0.1, min(0.9, 1.0 - (value.location.y / availableHeight)))
                                    }
                            )
                    )
            }
            .frame(height: 6)
            
            noteInputSection
                .frame(height: max(100, 300 * (1.0 - dividerPosition)))
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    if let index = noteStore.notes.firstIndex(where: { $0.id == selectedNoteID }) {
                        selectedNoteID = noteStore.notes[max(0, index - 1)].id
                    }
                }) {
                    Image(systemName: "chevron.up")
                }
                .disabled(selectedNoteID == nil || noteStore.notes.first?.id == selectedNoteID)
            }
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    if let index = noteStore.notes.firstIndex(where: { $0.id == selectedNoteID }) {
                        selectedNoteID = noteStore.notes[min(noteStore.notes.count - 1, index + 1)].id
                    }
                }) {
                    Image(systemName: "chevron.down")
                }
                .disabled(selectedNoteID == nil || noteStore.notes.last?.id == selectedNoteID)
            }
            ToolbarItem(placement: .navigation) {
                Button(action: { exportNotes() }) {
                    Label("Export Notes", systemImage: "square.and.arrow.up")
                }
            }
            ToolbarItem(placement: .navigation) {
                Button(action: { NSApp.sendAction(Selector(("showSettings:")), to: nil, from: nil) }) {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .onAppear {
            // Initialize if needed
            if !isInitialized {
                // Create initial note if the store is empty
                if noteStore.notes.isEmpty {
                    let newNote = noteStore.addNote(content: "# Welcome to Notes\nThis is your first note in the app. You can format notes with markdown.")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedNoteID = newNote.id
                    }
                } 
                // Auto-select first note if none selected
                else if selectedNoteID == nil && !noteStore.notes.isEmpty {
                    selectedNoteID = noteStore.notes.first?.id
                }
                
                isInitialized = true
            }
            
            // When the view appears, ensure selected note is highlighted
            if let noteId = selectedNoteID {
                // Check that the note still exists
                if noteStore.notes.contains(where: { $0.id == noteId }) {
                    // Reaffirm selection
                    selectedNoteID = noteId
                } else if !noteStore.notes.isEmpty {
                    // Select first note if selected note no longer exists
                    selectedNoteID = noteStore.notes.first?.id
                }
            }
        }
    }
    
    private func handleDrop(for note: Note) -> Bool {
        // Safety checks
        guard !noteStore.notes.isEmpty,
              let draggedNote = self.draggedNote else { return false }
        
        // Make sure both notes exist in our data store
        guard let sourceIndex = noteStore.notes.firstIndex(where: { $0.id == draggedNote.id }),
              let destinationIndex = noteStore.notes.firstIndex(where: { $0.id == note.id }) else { return false }
              
        // Don't reorder if dropping on self
        guard sourceIndex != destinationIndex else { return false }
        
        // Calculate new position and reorder
        let reorderIndex = destinationIndex > sourceIndex ? destinationIndex + 1 : destinationIndex
        noteStore.reorderNotes(from: IndexSet(integer: sourceIndex), to: reorderIndex)
        return true
    }
    
    private var noteInputSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text(noteStore.isEditingNote ? "Edit Note" : "New Note")
                    .font(.headline)
                Spacer()
                Button(action: { noteStore.pasteFromClipboard() }) {
                    Label("Paste", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.borderless)
                Button(action: { noteStore.currentNote = "" }) {
                    Label("Clear", systemImage: "xmark.circle")
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 4)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $noteStore.currentNote)
                    .padding(8)
                    .background(.ultraThinMaterial.opacity(0.25))
                    .cornerRadius(8)
                    .font(.system(size: 14))
                    .lineSpacing(1.5)
                    .foregroundColor(.primary)
                if noteStore.currentNote.isEmpty {
                    Text("Enter your notes here...")
                        .foregroundColor(.gray)
                        .padding(16)
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
                        let newNote = noteStore.addNote(content: noteStore.currentNote)
                        selectedNoteID = newNote.id
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
    
    private func exportNotes() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType(filenameExtension: "md") ?? .plainText]
        savePanel.nameFieldStringValue = "notes.md"
        savePanel.canCreateDirectories = true
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                var markdown = "# Notes Export\n\n"
                for note in noteStore.notes {
                    let title = extractTitle(from: note.content)
                    markdown += "## \(title)\n\n\(removeTitle(from: note.content))\n\n---\n\n"
                }
                do {
                    try markdown.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    print("Error exporting notes: \(error)")
                }
            }
        }
    }
    
    private func extractTitle(from content: String) -> String {
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.first?.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression) ?? "Untitled Note"
    }
    
    private func removeTitle(from content: String) -> String {
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.count > 1 ? lines[1...].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines) : ""
    }
    
    private var filteredNotes: [Note] {
        if noteStore.notes.isEmpty {
            return []
        }
        
        if searchText.isEmpty {
            return noteStore.notes
        } else {
            let searchTermLowercased = searchText.lowercased()
            return noteStore.notes.filter { 
                $0.content.lowercased().contains(searchTermLowercased)
            }
        }
    }
}

struct NoteCardView: View {
    let note: Note
    let isSelected: Bool
    @EnvironmentObject var noteStore: NoteStore
    @AppStorage("showFullNoteCards") private var showFullNoteCards = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let noteTitle = extractTitle(from: note.content)
            let contentWithoutTitle = removeTitle(from: note.content)
            
            HStack {
                Text(noteTitle)
                    .font(.title2)
                    .gradientForeground(colors: [.pink, .purple])
                Spacer()
                Text(formattedDate(note.lastModifiedDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button(action: { noteStore.copyNoteToClipboard(id: note.id) }) {
                    Image(systemName: "doc.on.doc").font(.caption)
                }
                .buttonStyle(.borderless)
                Button(action: { noteStore.beginEditingNote(id: note.id) }) {
                    Image(systemName: "pencil").font(.caption)
                }
                .buttonStyle(.borderless)
            }
            
            Divider()
            
            if showFullNoteCards {
                Markdown(contentWithoutTitle)
                    .markdownTheme(.gitHub)
                    .markdownTextStyle(\.text) { FontSize(12) }
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                let truncatedContent = truncateLines(from: contentWithoutTitle, lineCount: 5)
                Markdown(truncatedContent)
                    .markdownTheme(.gitHub)
                    .markdownTextStyle(\.text) { FontSize(12) }
                    .frame(maxWidth: .infinity, alignment: .leading)
                if contentWithoutTitle != truncatedContent {
                    Button("Show More") { showFullNoteCards.toggle() }
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ?
                    LinearGradient(gradient: Gradient(colors: [Color(NSColor.textBackgroundColor), Color.pink.opacity(0.07)]), startPoint: .topLeading, endPoint: .bottomTrailing) :
                    LinearGradient(gradient: Gradient(colors: [Color(NSColor.textBackgroundColor), Color(NSColor.textBackgroundColor)]), startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .cornerRadius(8)
        .shadow(radius: 1)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func extractTitle(from content: String) -> String {
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.first?.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression) ?? "Untitled Note"
    }
    
    private func removeTitle(from content: String) -> String {
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.count > 1 ? lines[1...].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines) : ""
    }
    
    private func truncateLines(from content: String, lineCount: Int) -> String {
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.count > lineCount ? lines.prefix(lineCount).joined(separator: "\n") : content
    }
}

// Safe wrapper to ensure proper initialization of NotesView
struct NotesViewWrapper: View {
    @Binding var selectedNoteID: UUID?
    var noteStore: NoteStore
    @Environment(\.isSearching) private var isSearching
    
    // Get search text from environment
    @AppStorage("notesSearchText") private var notesSearchText = ""
    
    var body: some View {
        NotesView(selectedNoteID: $selectedNoteID)
            .environmentObject(noteStore)
            .id("NotesViewContent")
            .onAppear {
                // Safety check - ensure we have data
                if noteStore.notes.isEmpty {
                    print("Creating sample note because store was empty")
                    let newNote = noteStore.addNote(content: "# Welcome to Notes\nThis is your first note.")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedNoteID = newNote.id
                    }
                }
            }
    }
}
