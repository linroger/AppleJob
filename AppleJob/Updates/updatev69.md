
struct JobDetailView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    let job: JobApplication

    @State private var windowRef: NSWindow?
    @State private var quickLookURL: URL? = nil

    let markdownParser = MarkdownParser() // Initialize MarkdownParser - Step 1.3

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(job.companyName)
                    .font(.largeTitle)
                    .bold()
                Text(job.jobTitle)
                    .font(.title2)
                HStack {
                    Text("Status: ")
                        .bold()
                    Text(job.status.rawValue)
                        .foregroundColor(job.status.displayColor)
                }
                if let link = job.linkToJobString, let url = URL(string: link) {
                    Link("View Job Posting", destination: url)
                        .accessibilityLabel("View job posting link")
                } else {
                    Text("No job link available")
                        .foregroundColor(.secondary)
                }

                // Job Location
                if !job.location.isEmpty {
                    Text("Location: \(job.location)")
                        .font(.headline)
                } else {
                    Text("No location specified")
                        .foregroundColor(.secondary)
                }

                // Application Date
                Text("Applied on: \(job.dateOfApplication.formatted(date: .abbreviated, time: .omitted))")
                if let salary = job.salary {
                    let salaryAsInt = Int(salary) // Convert salary to Int
                    Text("Salary: \(salaryAsInt.formatted(.currency(code: "USD")))")
                        .font(.headline)
                }
                if !job.documents.isEmpty {
                    Divider()
                    Text("Documents")
                        .font(.headline)
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(job.documents, id: \.id) { doc in
                                let currentDoc = doc // Capture doc for use in closures
                                Button {
                                    openQuickLook(currentDoc)
                                } label: {
                                    HStack {
                                        Image(systemName: "doc.text")
                                            .foregroundColor(.primary)
                                        Text(cleanFileName(currentDoc.fileName))
                                            .gradientForeground(colors: [.blue, .purple])
                                    }
                                }
                                    .buttonStyle(.bordered)
                                }
                                .contextMenu {
                                    Button("Reveal in Finder") {
                                        revealInFinder(currentDoc)
                                    }
                                    Button("Delete Document") {
                                        docStore.deleteDocument(currentDoc)
                                    }
                                    Divider()
                                    Button("Edit Metadata") {
                                        docStore.beginEditMetadata(for: currentDoc)
                                    }
                                }
                            }
                        }
                    }
                }

                if !job.jobDescription.isEmpty {
                    Divider()
                    Text("Job Description")
                        .font(.headline)

                    // Use MarkdownParser to parse jobDescription
                    let attributedString = markdownParser.parse(job.jobDescription) // Step 1.3: Directly use the returned NSAttributedString
                    Text(AttributedString(attributedString)) // Convert NSAttributedString to SwiftUI AttributedString
                        .padding(4)
                }
                if !job.coverLetter.isEmpty {
                    Divider()
                    Text("Cover Letter")
                        .font(.headline)
                    Text(job.coverLetter)
                        .padding(4)
                }
                Divider()
                Text("Notes")
                    .font(.headline)
                if let notes = job.notes, !notes.isEmpty {
                    Text(notes)
                        .padding(4)
                } else {
                    Text("No notes provided.")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
        .toolbar {
            ToolbarItemGroup {
                Button {
                    jobStore.isEditingJob = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                Button {
                    jobStore.toggleFavorite(for: job.id)
                } label: {
                    Image(systemName: job.isFavorite ? "heart.fill" : "heart")
                }
            }
        }
        .onAppear {
            if windowRef == nil {
                if let keyWindow = NSApp.windows.first(where: { $0.isKeyWindow }) {
                    windowRef = keyWindow
                }
            }
            updateWindowTitle()
        }
        .onChange(of: job.id) { _, _ in
            updateWindowTitle()
        }
        .quickLookPreview($quickLookURL)
    }

    func updateWindowTitle() {
        guard let window = windowRef else { return }
        window.title = "\(job.companyName) \(job.jobTitle)"
    }

    func cleanFileName(_ filename: String) -> String {
        var cleanedName = filename
        let stringsToRemove = ["Roger Lin", "Position", "2024", "Cover Letter"]
        for s in stringsToRemove {
            cleanedName = cleanedName.replacingOccurrences(of: s, with: "")
        }
        let exts = [".pdf", ".docx", ".pages", ".rtf", ".txt"]
        for e in exts {
            if cleanedName.hasSuffix(e) {
                cleanedName = String(cleanedName.dropLast(e.count))
                break
            }
        }
        return cleanedName.trimmingCharacters(in: .whitespaces)
    }

    func openQuickLook(_ doc: JobDocument) {
        if let fileURL = doc.fileURL {
            quickLookURL = fileURL
        } else {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(doc.fileName)
            do {
                try doc.fileData.write(to: tempURL)
                quickLookURL = tempURL
            } catch {
                print("Failed to open Quick Look: \(error)")
            }
        }
    }

    func revealInFinder(_ doc: JobDocument) {
        if let fileURL = doc.fileURL {
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        }
    }
}
