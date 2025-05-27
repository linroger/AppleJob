
import SwiftUI
import MarkdownKit
import AppKit
import QuickLook

struct JobDetailView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @StateObject var viewModel: JobViewModel
    let job: JobApplication

    @State private var windowRef: NSWindow?
    @State private var quickLookURL: URL? = nil
    @State private var selectedSkill: String? = nil
    @State private var showAddAliasView = false
    @State private var skillForAlias: String = ""

    let markdownParser = MarkdownParser()

    init(job: JobApplication) {
        self.job = job
        _viewModel = StateObject(wrappedValue: JobViewModel(job: job, availableSkills: JobStore().availableSkills))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Job Header
                Text(job.companyName)
                    .font(.largeTitle)
                    .bold()
                Text(job.jobTitle)
                    .font(.title2)

                // Job Details
                HStack {
                    Text("Status: ").bold()
                    Text(job.status.rawValue)
                        .foregroundColor(job.status.displayColor)
                }

                HStack {
                    Text("Job Type: ").bold()
                    Text(job.jobType.displayName)
                }

                // Link
                if let link = job.linkToJobString, let url = URL(string: link) {
                    Link("View Job Posting", destination: url)
                }

                // Location
                if !job.location.isEmpty {
                    Text("Location: \(job.location)")
                        .font(.headline)
                }

                // Application Date
                Text("Applied on: \(job.dateOfApplication.formatted(date: .abbreviated, time: .omitted))")

                // Salary
                if let salary = job.salary {
                    let salaryAsInt = Int(salary)
                    Text("Salary: \(salaryAsInt.formatted(.currency(code: "USD")))")
                        .font(.headline)
                }

                // Documents Section
                if !job.documents.isEmpty {
                    Divider()
                    Text("Documents").font(.headline)
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(job.documents, id: \.id) { doc in
                                Button {
                                    openQuickLook(doc)
                                } label: {
                                    HStack {
                                        Image(systemName: "doc.text")
                                            .foregroundColor(.primary)
                                        Text(cleanFileName(doc.fileName))
                                            .gradientForeground(colors: [.blue, .purple])
                                    }
                                    .buttonStyle(.bordered)
                                }
                                .contextMenu {
                                    Button("Reveal in Finder") {
                                        revealInFinder(doc)
                                    }
                                    Button("Delete Document") {
                                        docStore.deleteDocument(doc)
                                    }
                                    Divider()
                                    Button("Edit Metadata") {
                                        docStore.beginEditMetadata(for: doc)
                                    }
                                }
                            }
                        }
                    }
                }

                // Skills Section
                if !job.desiredSkillNames.isEmpty {
                    Divider()
                    Text("Desired Skills").font(.headline)
                    HStack {
                        ForEach(job.desiredSkillNames, id: \.self) { skillName in
                            Button {
                                selectedSkill = (selectedSkill == skillName) ? nil : skillName
                            } label: {
                                Text(skillName)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        selectedSkill == skillName
                                        ? Color.blue.opacity(0.8)
                                        : Color.gray.opacity(0.3)
                                    )
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            .contextMenu {
                                Button("Add Alias") {
                                    skillForAlias = skillName
                                    showAddAliasView = true
                                }
                            }
                        }
                    }
                }

                // Job Description Section
                if !job.jobDescription.isEmpty {
                    Divider()
                    Text("Job Description").font(.headline)

                    // Markdown parsing for jobDescription
                    let parsedDescription = markdownParser.parse(job.jobDescription)
                    Text(AttributedString(parsedDescription))
                        .padding(4)
                }

                // Cover Letter Section
                if !job.coverLetter.isEmpty {
                    Divider()
                    Text("Cover Letter").font(.headline)
                    Text(job.coverLetter)
                        .padding(4)
                }

                // Notes Section
                Divider()
                Text("Notes").font(.headline)
                if let notes = job.notes, !notes.isEmpty {
                    // 1) Show the raw text
                    Text(notes)

                    // 2) Parse the notes via markdown
                    let parsedNotes = markdownParser.parse(notes)
                    Text(AttributedString(parsedNotes))
                        .padding(4)
                } else {
                    Text("No notes provided.")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            // Allow text selection throughout the VStack
            .textSelection(.enabled)
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
            setupWindow()
        }
        .onChange(of: job.id) { _, _ in
            updateWindowTitle()
        }
        .quickLookPreview($quickLookURL)
        .sheet(isPresented: $showAddAliasView) {
            if !skillForAlias.isEmpty {
                AddAliasView(isPresented: $showAddAliasView, skillName: skillForAlias)
                    .environmentObject(jobStore)
            }
        }
    }

    // MARK: - Helper Functions

    func setupWindow() {
        // Try to get a reference to the NSWindow
        if windowRef == nil {
            if let keyWindow = NSApp.windows.first(where: { $0.isKeyWindow }) {
                windowRef = keyWindow
            }
        }
        updateWindowTitle()
        // Re-parse skill data
        jobStore.parseJobDescriptionsForAllSkills()
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



struct SwiftUIComboBox: NSViewRepresentable {
    @Binding var text: String
    var items: [String]
    var placeholder: String = ""
    var onSelection: ((String) -> Void)?

    func makeNSView(context: Context) -> NSComboBox {
        let comboBox = NSComboBox()
        comboBox.delegate = context.coordinator
        comboBox.placeholderString = placeholder
        comboBox.completes = true // Enable autocompletion
        comboBox.usesDataSource = true
        comboBox.dataSource = context.coordinator // Set the coordinator as the data source
        comboBox.reloadData() // Initial data load
        return comboBox
    }

    func updateNSView(_ nsView: NSComboBox, context: Context) {
        nsView.stringValue = text
        nsView.placeholderString = placeholder
        nsView.removeAllItems()
        nsView.addItems(withObjectValues: items)
        nsView.reloadData() // Refresh data on updates

        if !text.isEmpty && !items.contains(text) && !nsView.stringValue.isEmpty {
            nsView.stringValue = text // Ensure the typed text remains if it's a new value
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSComboBoxDelegate, NSComboBoxDataSource {
        let parent: SwiftUIComboBox

        init(_ parent: SwiftUIComboBox) {
            self.parent = parent
        }

        // MARK: - NSComboBox Delegate Methods
        func comboBoxSelectionDidChange(_ notification: Notification) {
            guard let comboBox = notification.object as? NSComboBox else { return }
            parent.text = comboBox.stringValue
            parent.onSelection?(comboBox.stringValue) // Call the onSelection closure if needed
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let comboBox = obj.object as? NSComboBox else { return }
            parent.text = comboBox.stringValue
        }


        // MARK: - NSComboBox Data Source Methods

        func numberOfItems(in comboBox: NSComboBox) -> Int {
            return parent.items.count
        }

        func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
            return parent.items[index]
        }

        func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
            return parent.items.firstIndex(of: string) ?? NSNotFound
        }

        func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
            if string.isEmpty { return nil }
            return parent.items.first { $0.lowercased().hasPrefix(string.lowercased()) }
        }

    }
}


//
//  AddJobView+EditJobView.swift
//  AppleJob
//
//  Created by Roger Lin on 1/26/25.
//

//
//  AddJobView+EditJobView+NewLocationView.swift
//  AppleJob
//
//  Created by Roger Lin on 1/26/25.
//

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()

        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .underWindowBackground

        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        //
    }
}


/**
 A sheet to create a new job entry. If the user came from a custom URL,
 we can pre-populate the fields from `jobStore.incomingJobData`.
 */

//
//  AddJobView+EditJobView+NewLocationView.swift
//  AppleJob
//
//  Created by Roger Lin on 1/26/25.
//
import SwiftUI
import MapKit

/*****************************************************
 *               ADD JOB VIEW
 *****************************************************/

/// A sheet to create a new job entry. If the user came from a custom URL,
/// we can pre-populate the fields from `jobStore.incomingJobData`.
/// A sheet to create a new job entry. If the user came from a custom URL,
/// we can pre-populate the fields from `jobStore.incomingJobData`.
struct AddJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var isPresented: Bool

    @StateObject private var viewModel: JobViewModel = JobViewModel()
    @State private var importedDocuments: [JobDocument] = []
    @State private var locations: [String] = CityCoordinateDictionary.keys.sorted()
    @State private var showAddLocationSheet = false
    @State private var isImporting = false
    @State private var quickLookURL: URL? = nil

    /// Added to fix “no member 'windowRef'” compile error:
    @State private var windowRef: NSWindow? = nil

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    var body: some View {
        VStack {
            Text("Add New Job")
                .font(.title2)
                .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("JOB DETAILS")

                    // COMPANY NAME
                    TextField("Company Name", text: $viewModel.companyName)
                        .modifier(TranslucentTextFieldStyle())
                        .onChange(of: viewModel.companyName) { _, _ in
                            viewModel.validateInputs()
                        }

                    // JOB TITLE
                    TextField("Job Title", text: $viewModel.jobTitle)
                        .modifier(TranslucentTextFieldStyle())
                        .onChange(of: viewModel.jobTitle) { _, _ in
                            viewModel.validateInputs()
                        }

                    sectionHeader("APPLICATION DETAILS")

                    // JOB TYPE
                    Picker("Job Type", selection: $viewModel.jobType) {
                        ForEach(JobType.allCases, id: \.self) { jobType in
                            Text(jobType.displayName).tag(jobType)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())

                    // LINK TO JOB
                    TextField("Link to Job", text: $viewModel.linkToJob)
                        .modifier(TranslucentTextFieldStyle())

                    // SALARY
                    TextField(
                        "Salary",
                        value: $viewModel.salaryDouble,
                        format: .currency(code: "USD")
                    )
                    .modifier(TranslucentTextFieldStyle())
                    .onChange(of: viewModel.salaryString) { _, newValue in
                        viewModel.updateSalary(fromString: newValue)
                    }

                    // LOCATION
                    Picker("Location", selection: $viewModel.location) {
                        ForEach(locations, id: \.self) { location in
                            Text(location).tag(location)
                        }
                        Text("Add New Location").tag("Add New Location")
                    }
                    .pickerStyle(DefaultPickerStyle())
                    .onChange(of: viewModel.location) { _, newValue in
                        if newValue == "Add New Location" {
                            viewModel.location = ""
                            showAddLocationSheet = true
                        }
                    }

                    // DATE
                    DatePicker("Application Date", selection: $viewModel.dateOfApplication, displayedComponents: .date)

                    // STATUS
                    Picker("Status", selection: $viewModel.status) {
                        ForEach(JobStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }

                    Divider()
                    Text("Documents").font(.headline)

                    // DOCUMENT PREVIEW SCROLLER
                    if !importedDocuments.isEmpty {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(importedDocuments, id: \.id) { doc in
                                    Button {
                                        openQuickLook(doc)
                                    } label: {
                                        HStack {
                                            Image(systemName: "doc.text")
                                                .foregroundColor(.primary)
                                            Text(cleanFileName(doc.fileName))
                                                .gradientForeground(colors: [.blue, .purple])
                                        }
                                        .buttonStyle(.bordered)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                    }
                                }
                            }
                        }
                    }

                    Button("Upload Documents") {
                        isImporting = true
                    }

                    Divider()
                    Text("Desired Skills").font(.headline)

                    // ComboBox for Desired Skills
                    SwiftUIComboBox(
                        text: $viewModel.desiredSkillText,
                        items: viewModel.availableSkillSuggestions,
                        placeholder: "Type to add skills..."
                    ) { selectedSkill in
                        viewModel.addSelectedSkill(skillName: selectedSkill, jobStore: jobStore)
                    }
                    .onReceive(
                        viewModel.$desiredSkillText.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
                    ) { _ in
                        viewModel.updateSkillSuggestions(availableSkills: jobStore.availableSkills)
                    }

                    // Selected Skills Tags
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(viewModel.selectedDesiredSkills, id: \.self) { skill in
                                HStack {
                                    Text(skill)
                                    Button(action: {
                                        viewModel.removeSelectedSkill(skillName: skill)
                                    }) {
                                        Image(systemName: "x.circle.fill")
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.3))
                                .clipShape(Capsule())
                            }
                        }
                    }

                    sectionHeader("JOB DESCRIPTION")
                    TextEditor(text: $viewModel.jobDescription)
                        .modifier(TranslucentTextEditorStyle())
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 200)
                        // --------------------------
                        // KEY UPDATES HERE:
                        // --------------------------
                        .onChange(of: viewModel.jobDescription) { _, newValue in
                            let lines = newValue.components(separatedBy: .newlines)
                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                .filter { !$0.isEmpty }

                            // 0) If the first line is not a URL and jobTitle is empty, treat that line as jobTitle.
                            if let firstLine = lines.first, viewModel.jobTitle.isEmpty {
                                if !firstLine.lowercased().hasPrefix("http") {
                                    viewModel.jobTitle = firstLine
                                }
                            }

                            // 1) If linkToJob is empty, find any line that starts with "http"
                            if viewModel.linkToJob.isEmpty {
                                for line in lines {
                                    if line.lowercased().hasPrefix("http") {
                                        viewModel.linkToJob = line
                                        break
                                    }
                                }
                            }

                            // 2) Check existing job applications for a matching company name
                            //    EXCEPT for "UChicago"
                            if viewModel.companyName.isEmpty {
                                for existingApp in jobStore.jobApplications {
                                    let cmpName = existingApp.companyName
                                    // Skip "UChicago"
                                    if cmpName.lowercased() == "uchicago" {
                                        continue
                                    }
                                    // If jobDescription text includes an existing company's name
                                    // (case-insensitive), set companyName
                                    if newValue.localizedCaseInsensitiveContains(cmpName) {
                                        viewModel.companyName = cmpName
                                        break
                                    }
                                }
                            }
                        }

                    sectionHeader("COVER LETTER")
                    TextEditor(text: $viewModel.coverLetter)
                        .modifier(TranslucentTextEditorStyle())
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 200)

                    sectionHeader("NOTES")
                    TextEditor(text: $viewModel.notes)
                        .modifier(TranslucentTextEditorStyle())
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 200)
                }
                .padding()
                .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
            }

            HStack {
                Button(role: .cancel) {
                    isPresented = false
                } label: {
                    Text("Cancel")
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Spacer()

                Button("Save") {
                    viewModel.validateInputs()
                    if viewModel.isInputValid {
                        let finalDocs = storeImportedDocuments()
                        docStore.mergeDocuments(finalDocs)
                        viewModel.addJob(to: jobStore, documents: finalDocs)
                        isPresented = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(!viewModel.isInputValid)
            }
            .padding()
        }
        // Main background for the entire AddJobView
        .frame(minWidth: 500, minHeight: 600)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf, .plainText, .rtf, .image],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    if let data = try? Data(contentsOf: url) {
                        var creation = Date()
                        var modified = Date()
                        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path) {
                            if let cdate = attrs[.creationDate] as? Date {
                                creation = cdate
                            }
                            if let mdate = attrs[.modificationDate] as? Date {
                                modified = mdate
                            }
                        }
                        let doc = JobDocument(
                            fileName: url.lastPathComponent,
                            fileData: data,
                            fileURL: url,
                            creation: creation,
                            lastModified: modified
                        )
                        if !importedDocuments.contains(doc) {
                            importedDocuments.append(doc)
                        }
                    }
                }
            case .failure(let error):
                print("Import error: \(error)")
            }
        }
        .sheet(isPresented: $showAddLocationSheet) {
            NewLocationView(
                locations: $locations,
                selectedLocation: $viewModel.location,
                isPresented: $showAddLocationSheet
            )
        }
        .quickLookPreview($quickLookURL)
        .onAppear {
            if let incoming = jobStore.incomingJobData {
                if viewModel.jobTitle.isEmpty {
                    viewModel.jobTitle = incoming["jobTitle"] as? String ?? ""
                }
                if viewModel.linkToJob.isEmpty {
                    viewModel.linkToJob = incoming["url"] as? String ?? ""
                }
                if viewModel.jobDescription.isEmpty {
                    viewModel.jobDescription = incoming["jobDescription"] as? String ?? ""
                }
                jobStore.incomingJobData = nil
            }
            viewModel.availableSkillSuggestions = jobStore.availableSkills.map { $0.name }.sorted()
        }
        .onReceive(jobStore.$availableSkills) { updatedSkills in
            viewModel.updateSkillSuggestions(availableSkills: updatedSkills)
        }
        .background(WindowAccessor { window in
            self.windowRef = window
            window?.isMovableByWindowBackground = true
        })
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .textCase(.uppercase)
    }

    private func storeImportedDocuments() -> [JobDocument] {
        var savedDocs: [JobDocument] = []
        for d in importedDocuments {
            if let originalURL = d.fileURL,
               let savedURL = DocumentStore.saveDocumentToAppSupport(originalURL: originalURL, fileName: d.fileName) {
                let newDoc = JobDocument(
                    fileName: d.fileName,
                    fileData: d.fileData,
                    fileURL: savedURL,
                    creation: d.creationDate,
                    lastModified: d.lastModifiedDate
                )
                savedDocs.append(newDoc)
            } else {
                savedDocs.append(d)
            }
        }
        return savedDocs
    }

    private func openQuickLook(_ doc: JobDocument) {
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

    private func cleanFileName(_ filename: String) -> String {
        var cleanedName = filename
        cleanedName = cleanedName.replacingOccurrences(of: "_", with: " ")
        cleanedName = cleanedName.replacingOccurrences(of: "-", with: " ")
        cleanedName = cleanedName.replacingOccurrences(of: "\\d", with: "", options: .regularExpression)
        let toRemove = ["Roger Lin", "Position", "2024", "Cover Letter"]
        for remove in toRemove {
            cleanedName = cleanedName.replacingOccurrences(of: remove, with: "")
        }
        cleanedName = cleanedName.trimmingCharacters(in: .whitespaces)
        for extn in [".pdf", ".docx", ".pages"] {
            if cleanedName.hasSuffix(extn) {
                cleanedName = String(cleanedName.dropLast(extn.count))
                break
            }
        }
        return cleanedName.trimmingCharacters(in: .whitespaces)
    }
}


struct TranslucentTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    PastelGradientBackground()
                    Color.clear.background(Material.ultraThin)
                }
                .opacity(0.5)
            )
            .overlay(RoundedRectangle(cornerRadius: 5)
                .strokeBorder(.tertiary, lineWidth: 0.5))
    }
}

struct TranslucentTextEditorStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(6)
            .background(
                ZStack {
                    PastelGradientBackground()
                    Color.clear.background(Material.ultraThin)
                }
                .opacity(0.5)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            )
            .overlay(RoundedRectangle(cornerRadius: 5)
                .strokeBorder(.tertiary, lineWidth: 0.5))

    }
}


/// A view displaying a pastel gradient background that we only use
/// behind individual TextFields and TextEditors for a frosted effect.
struct PastelGradientBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.94, green: 0.85, blue: 1.0).opacity(0.7),  // Soft Lavender
                Color(red: 0.88, green: 0.95, blue: 0.90).opacity(0.7), // Mint Green
                Color(red: 1.0,  green: 0.94, blue: 0.9).opacity(0.7)    // Pale Yellow
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct WindowAccessor: NSViewRepresentable {
    @State var window: NSWindow? = nil
    let configure: (NSWindow?) -> Void

    init(configure: @escaping (NSWindow?) -> Void) {
        self.configure = configure
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.window = view.window
            configure(window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        configure(window)
    }
}

struct SwiftUIComboBox: NSViewRepresentable {
    @Binding var text: String
    var items: [String]
    var placeholder: String = ""
    var onSelection: ((String) -> Void)?

    func makeNSView(context: Context) -> NSComboBox {
        let comboBox = NSComboBox()
        comboBox.delegate = context.coordinator
        comboBox.placeholderString = placeholder
        comboBox.completes = true // Enable autocompletion
        comboBox.usesDataSource = true
        comboBox.dataSource = context.coordinator // Set the coordinator as the data source
        comboBox.reloadData() // Initial data load
        return comboBox
    }

    func updateNSView(_ nsView: NSComboBox, context: Context) {
        nsView.stringValue = text
        nsView.placeholderString = placeholder
        nsView.removeAllItems()
        nsView.addItems(withObjectValues: items)
        nsView.reloadData() // Refresh data on updates

        if !text.isEmpty && !items.contains(text) && !nsView.stringValue.isEmpty {
            nsView.stringValue = text // Ensure the typed text remains if it's a new value
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSComboBoxDelegate, NSComboBoxDataSource {
        let parent: SwiftUIComboBox

        init(_ parent: SwiftUIComboBox) {
            self.parent = parent
        }

        // MARK: - NSComboBox Delegate Methods
        func comboBoxSelectionDidChange(_ notification: Notification) {
            guard let comboBox = notification.object as? NSComboBox else { return }
            parent.text = comboBox.stringValue
            parent.onSelection?(comboBox.stringValue) // Call the onSelection closure if needed
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let comboBox = obj.object as? NSComboBox else { return }
            parent.text = comboBox.stringValue
        }


        // MARK: - NSComboBox Data Source Methods

        func numberOfItems(in comboBox: NSComboBox) -> Int {
            return parent.items.count
        }

        func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
            return parent.items[index]
        }

        func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
            return parent.items.firstIndex(of: string) ?? NSNotFound
        }

        func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
            if string.isEmpty { return nil }
            return parent.items.first { $0.lowercased().hasPrefix(string.lowercased()) }
        }

    }
}

// MARK: - NewLocationView
// -----------------------------------------------------
/**
 A small sheet to add a brand-new location with name, latitude, and longitude.
 This view is used to create a new job entry.
 If the Safari extension passes data, we can pre-populate the fields here in the ViewModel
 or by referencing jobStore.incomingJobData.
 */

/*****************************************************
 *               NEW LOCATION VIEW
 *****************************************************/

/// A small sheet to add a brand-new location with name, latitude, and longitude.

struct NewLocationView: View {
    @Binding var locations: [String]
    @Binding var selectedLocation: String
    @Binding var isPresented: Bool

    @State private var newLocationName: String = ""
    @State private var latitude: String = ""
    @State private var longitude: String = ""

    var body: some View {
        VStack {
            Text("Add a New Location")
                .font(.headline)

            // LOCATION NAME
            TextField("Location Name", text: $newLocationName)
                .modifier(TranslucentGradientBackground())
                .overlay(RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(Color.gray.opacity(0.5), lineWidth: 1))

            // LATITUDE
            TextField("Latitude", text: $latitude)
                .modifier(TranslucentGradientBackground())
                .overlay(RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(Color.gray.opacity(0.5), lineWidth: 1))

            // LONGITUDE
            TextField("Longitude", text: $longitude)
                .modifier(TranslucentGradientBackground())
                .overlay(RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(Color.gray.opacity(0.5), lineWidth: 1))

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Spacer()

                Button("Add") {
                    guard let lat = Double(latitude),
                          let lon = Double(longitude),
                          !newLocationName.isEmpty else { return }
                    if !locations.contains(newLocationName) {
                        locations.append(newLocationName)
                    }
                    selectedLocation = newLocationName
                    let newCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    CityCoordinateDictionary[newLocationName] = newCoordinate
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            .padding()
        }
        .frame(width: 300, height: 250)
        .background(
            Color(nsColor: .windowBackgroundColor).opacity(0.8)
        )
        .background(
            WindowAccessor { window in
                window?.isMovableByWindowBackground = true
            }
        )
    }
}

// MARK: - TranslucentGradientBackground ViewModifier
struct TranslucentGradientBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    LinearGradient(
                        colors: [
                            Color.pink.opacity(0.3),
                            Color.blue.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .blur(radius: 5)
                    .background(.ultraThinMaterial)
                }
                .clipShape(RoundedRectangle(cornerRadius: 5))
            )
    }
}



// MARK: - EditJobView
// MARK: - EditJobView
/*****************************************************
 *               EDIT JOB VIEW
 *****************************************************/

struct EditJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var isPresented: Bool
    @StateObject private var viewModel: JobViewModel
    @State private var importedDocuments: [JobDocument] = []
    @State private var isImporting = false
    @State private var locations: [String] = CityCoordinateDictionary.keys.sorted()
    @State private var showAddLocationSheet = false
    @State private var quickLookURL: URL? = nil

    init(isPresented: Binding<Bool>, job: JobApplication) {
        self._isPresented = isPresented
        _viewModel = StateObject(wrappedValue: JobViewModel(job: job, availableSkills: JobStore().availableSkills))
        self._importedDocuments = State(initialValue: job.documents)
    }

    var body: some View {
        VStack {
            Text("Edit Job")
                .font(.title2)
                .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("Job Details")

                    // COMPANY NAME
                    TextField("Company Name", text: $viewModel.companyName)
                        .modifier(TranslucentTextFieldStyle())
                        .background(
                            ZStack {
                                PastelGradientBackground()
                                Color.clear.background(Material.ultraThin) // Wrap Material.thin in a background
                            }
                            .opacity(0.5)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(.tertiary, lineWidth: 0.5)
                        )
                        .onChange(of: viewModel.companyName) { _, _ in
                            viewModel.validateInputs()
                        }


                    // JOB TITLE
                    TextField("Job Title", text: $viewModel.jobTitle)
                        .modifier(TranslucentTextFieldStyle())
                        .background(
                            ZStack {
                                PastelGradientBackground()
                                Color.clear.background(Material.ultraThin) // Wrap Material.thin in a background
                            }
                            .opacity(0.5)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(.tertiary, lineWidth: 0.5)
                        )
                        .onChange(of: viewModel.jobTitle) { _, _ in
                            viewModel.validateInputs()
                        }

                    sectionHeader("Application Details")

                    // JOB TYPE
                    Picker("Job Type", selection: $viewModel.jobType) {
                        ForEach(JobType.allCases, id: \.self) { jobType in
                            Text(jobType.displayName).tag(jobType)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())


                    // LINK TO JOB
                    TextField("Link to Job", text: $viewModel.linkToJob)
                        .modifier(TranslucentTextFieldStyle())
                        .background(
                            ZStack {
                                PastelGradientBackground()
                                Color.clear.background(Material.ultraThin) // Wrap Material.thin in a background
                            }
                            .opacity(0.5)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        )
                        .overlay(RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(.tertiary, lineWidth: 0.5))

                    // SALARY
                                       TextField(
                                           "Salary",
                                           value: $viewModel.salaryDouble,
                                           format: .currency(code: Locale.current.currency?.identifier ?? "USD")
                                       )
                                                      .background(
                                           ZStack {
                                               PastelGradientBackground()
                                               Color.clear.background(Material.ultraThin) // Wrap Material.thin in a background
                                           }
                                           .opacity(0.5)
                                           .clipShape(RoundedRectangle(cornerRadius: 5))
                                       )
                                       .overlay(RoundedRectangle(cornerRadius: 5)
                                           .strokeBorder(.tertiary, lineWidth: 0.5))
                                       .modifier(TranslucentTextFieldStyle())
                                                           .onChange(of: viewModel.salaryString) {_, newValue in
                                                               viewModel.updateSalary(fromString: newValue)
                                                           }



                    // STATUS
                    Picker("Status", selection: $viewModel.status) {
                        ForEach(JobStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }

                    // DATE
                    DatePicker("Application Date", selection: $viewModel.dateOfApplication, displayedComponents: .date)

                    // LOCATION
                    Picker("Location", selection: $viewModel.location) {
                        ForEach(locations, id: \.self) { loc in
                            Text(loc).tag(loc)
                        }
                        Text("Add New Location").tag("Add New Location")
                    }
                    .onChange(of: viewModel.location) { _, newValue in
                        if newValue == "Add New Location" {
                            viewModel.location = ""
                            showAddLocationSheet = true
                        }
                    }

                    sectionHeader("Documents")
                    if !importedDocuments.isEmpty {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(importedDocuments, id: \.id) { doc in
                                    documentView(for: doc)
                                }
                            }
                        }
                    }
                    Button("Upload Documents") {
                        isImporting = true
                    }

                    Divider()
                    Text("Desired Skills").font(.headline)

                    // COMBOBOX FOR DESIRED SKILLS
                    SwiftUIComboBox(
                        text: $viewModel.desiredSkillText,
                        items: viewModel.availableSkillSuggestions,
                        placeholder: "Type to add skills..."
                    ) { selectedSkill in
                        viewModel.addSelectedSkill(skillName: selectedSkill, jobStore: jobStore)
                    }
                    .onReceive(viewModel.$desiredSkillText.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)) { _ in
                        viewModel.updateSkillSuggestions(availableSkills: jobStore.availableSkills)
                    }

                    // SELECTED SKILLS TAGS
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(viewModel.selectedDesiredSkills, id: \.self) { skill in
                                HStack {
                                    Text(skill)
                                    Button(action: {
                                        viewModel.removeSelectedSkill(skillName: skill)
                                    }, label: {
                                        Image(systemName: "x.circle.fill")
                                    })
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.3))
                                .clipShape(Capsule())
                            }
                        }
                    }


                    sectionHeader("Job Description")
                    TextEditor(text: $viewModel.jobDescription)
                        .modifier(TranslucentTextEditorStyle())
                        .background(
                            ZStack {
                                PastelGradientBackground()
                                Color.clear.background(Material.ultraThin) // Wrap Material.thin in a background
                            }
                            .opacity(0.5)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        )
                        .overlay(RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(.tertiary, lineWidth: 0.5))
                        .frame(minHeight: 100)

                    sectionHeader("Cover Letter")
                    TextEditor(text: $viewModel.coverLetter)
                        .modifier(TranslucentTextEditorStyle())
                        .background(
                            ZStack {
                                PastelGradientBackground()
                                Color.clear.background(Material.ultraThin) // Wrap Material.thin in a background
                            }
                            .opacity(0.5)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        )
                        .overlay(RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(.tertiary, lineWidth: 0.5))
                        .frame(minHeight: 100)

                    sectionHeader("Notes")
                    TextEditor(text: $viewModel.notes)
                        .modifier(TranslucentTextEditorStyle())
                        .background(
                            ZStack {
                                PastelGradientBackground()
                                Color.clear.background(Material.ultraThin) // Wrap Material.thin in a background
                            }
                            .opacity(0.5)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        )
                        .overlay(RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(.tertiary, lineWidth: 0.5))
                        .frame(minHeight: 100)
                }
                .padding()
            }

            HStack {
                Button(role: .cancel) {
                    isPresented = false
                } label: {
                    Text("Cancel")
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Spacer()

                Button("Save") {
                    saveJob()
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(!viewModel.isInputValid)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 600)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf, .plainText, .rtf, .image],
            allowsMultipleSelection: true
        ) { handleImportedFiles(result: $0) }
        .sheet(isPresented: $showAddLocationSheet) {
            NewLocationView(
                locations: $locations,
                selectedLocation: $viewModel.location,
                isPresented: $showAddLocationSheet
            )
        }
        .onAppear {
            loadLocations()
            viewModel.availableSkillSuggestions = jobStore.availableSkills.map {$0.name}.sorted()
        }
        .onReceive(jobStore.$availableSkills) { updatedSkills in
            viewModel.updateSkillSuggestions(availableSkills: updatedSkills)
        }
        .quickLookPreview($quickLookURL)
        .background(WindowAccessor { window in
            window?.isMovableByWindowBackground = true
        })
    }

    private func saveJob() {
        viewModel.validateInputs()
        guard viewModel.isInputValid else { return }

        guard let originalJob = jobStore.selectedJob else { return } // Ensure selectedJob is not nil

        let updatedJob = JobApplication(
            id: originalJob.id,
            companyName: viewModel.companyName,
            jobTitle: viewModel.jobTitle,
            status: viewModel.status,
            dateOfApplication: viewModel.dateOfApplication,
            location: viewModel.location,
            linkToJobString: viewModel.linkToJob.isEmpty ? nil : viewModel.linkToJob,
            salary: viewModel.salaryDouble,
            jobDescription: viewModel.jobDescription,
            coverLetter: viewModel.coverLetter,
            notes: viewModel.notes.isEmpty ? nil : viewModel.notes,
            documents: importedDocuments,
            isFavorite: originalJob.isFavorite,
            jobType: viewModel.jobType,
            desiredSkillNames: viewModel.selectedDesiredSkills
        )
        jobStore.editJob(with: updatedJob)
        isPresented = false
    }


    private func handleImportedFiles(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                guard let data = try? Data(contentsOf: url) else { continue }
                let doc = JobDocument(
                    fileName: url.lastPathComponent,
                    fileData: data,
                    fileURL: url,
                    creation: Date(),
                    lastModified: Date()
                )
                if !importedDocuments.contains(doc) {
                    importedDocuments.append(doc)
                }
            }
        case .failure(let error):
            print("Failed to import files: \(error)")
        }
    }

    private func loadLocations() {
        locations = CityCoordinateDictionary.keys.sorted()
    }

    private func documentView(for doc: JobDocument) -> some View {
        HStack {
            Image(systemName: "doc.text")
                .foregroundColor(.primary)
            Text(cleanFileName(doc.fileName))
                .gradientForeground(colors: [.blue, .purple])
        }
        .buttonStyle(.bordered)
        .contextMenu {
            Button("Reveal in Finder") {
                if let fileURL = doc.fileURL {
                    NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                }
            }
            Button("Delete Document") {
                if let idx = importedDocuments.firstIndex(where: { $0.id == doc.id }) {
                    importedDocuments.remove(at: idx)
                }
            }
        }
    }

    private func cleanFileName(_ filename: String) -> String {
        filename
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .textCase(.uppercase)
            .padding(.bottom, 5)
    }
}

/// A simpler gradient background for the EditJobView's outer area—
/// but here we only want the system background, so we no longer
/// fill the entire view with a gradient. The text inputs themselves
/// hold the pastel gradient behind a blur.
struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [.purple.opacity(0.4), .blue.opacity(0.4)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct AddAliasView: View {
    @EnvironmentObject var jobStore: JobStore
    @Binding var isPresented: Bool
    let skillName: String
    @State private var displayName: String = ""
    @State private var aliasText: String = ""
    @State private var skillAliases: [String] = []


    var body: some View {
        VStack {
            Text("Add Aliases for \(skillName)")
                .font(.title2)
                .padding()

            Form {
                Section {
                    TextField("Displayed Name", text: $displayName)
                        .disabled(true) // Display name is fixed
                } header: {
                    Text("Displayed Name")
                }

                Section {
                    TextField("Aliases (comma-separated)", text: $aliasText)
                } header: {
                    Text("Aliases")
                }
            }
            .padding()


            HStack {
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                Button("Save") {
                    saveAliases()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            .padding()

        }
        .onAppear {
            displayName = skillName
            if let skill = jobStore.availableSkills.first(where: {$0.name == skillName}) {
                aliasText = skill.aliases.joined(separator: ", ")
            }
        }
        .frame(width: 400, height: 300)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
        .background(WindowAccessor { window in
            window?.isMovableByWindowBackground = true
        })
    }

    func saveAliases() {
        let aliases = aliasText.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter {!$0.isEmpty}

        if let skillIndex = jobStore.availableSkills.firstIndex(where: { $0.name == skillName }) {
            let updatedSkill = DesiredSkill(id: jobStore.availableSkills[skillIndex].id, name: skillName, aliases: aliases)
            jobStore.updateSkill(updatedSkill)
        } else {
            let newSkill = DesiredSkill(name: skillName, aliases: aliases)
            jobStore.addSkill(newSkill)
        }
    }
}
