// MARK: - JobDetailView
// ---------------------------------------------------------------
// Displays details of a selected JobApplication and sets the
// macOS window title to "CompanyName JobTitle" (no brackets).
// It also updates dynamically whenever 'job.id' changes,
// so if the user selects a different job, the window title
// will refresh.
// ---------------------------------------------------------------

import SwiftUI
import AppKit
import QuickLook

struct JobDetailView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    
    /// The currently selected job passed in from the parent view.
    let job: JobApplication
    
    /// Holds a reference to the active NSWindow so we can change its title.
    @State private var windowRef: NSWindow?
    
    /// Holds a URL for Quick Look previews.
    @State private var quickLookURL: URL? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                
                // Company name in a large title
                Text(job.companyName)
                    .font(.largeTitle)
                    .bold()

                // Job title in a smaller font size
                Text(job.jobTitle)
                    .font(.title2)

                // Status row with color-coded status text
                HStack {
                    Text("Status: ")
                        .bold()
                    Text(job.status.rawValue)
                        .foregroundColor(job.status.displayColor)
                }

                // Optional link to job posting
                if let link = job.linkToJobString, let url = URL(string: link) {
                    Link("View Job Posting", destination: url)
                }

                // Location
                if !job.location.isEmpty {
                    Text("Location: \(job.location)")
                        .font(.headline)
                }

                // Date of application
                Text("Applied on: \(job.dateOfApplication.formatted(date: .abbreviated, time: .omitted))")

                // Documents section
                if !job.documents.isEmpty {
                    Divider()
                    Text("Documents")
                        .font(.headline)
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

                // -------------------------
                // Job Description
                // -------------------------
                Divider()
                Text("Job Description")
                    .font(.headline)
                if let data = job.jobDescriptionRTFData {
                    // If we have RTF data, display it as RichText
                    RichTextDisplay(attributedString: attributedString(from: data))
                        .frame(minHeight: 60)
                } else {
                    // fallback to plain text
                    Text(job.jobDescription)
                        .padding(4)
                }

                // -------------------------
                // Cover Letter
                // -------------------------
                Divider()
                Text("Cover Letter")
                    .font(.headline)
                if let data = job.coverLetterRTFData {
                    RichTextDisplay(attributedString: attributedString(from: data))
                        .frame(minHeight: 60)
                } else {
                    Text(job.coverLetter)
                }

                // -------------------------
                // Notes
                // -------------------------
                Divider()
                Text("Notes")
                    .font(.headline)
                if let data = job.notesRTFData {
                    RichTextDisplay(attributedString: attributedString(from: data))
                        .frame(minHeight: 60)
                } else if let notes = job.notes {
                    Text(notes)
                        .padding(4)
                } else {
                    Text("No notes provided.")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        // Slight background color and partial opacity for visual styling
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))

        // Basic toolbar with "Edit" and "Favorite" buttons
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

        // Capture NSWindow reference and set the title
        .onAppear {
            if windowRef == nil {
                if let keyWindow = NSApp.windows.first(where: { $0.isKeyWindow }) {
                    windowRef = keyWindow
                }
            }
            updateWindowTitle()
        }

        // Refresh window title if user selects a different job
            // Whenever the selected job's ID changes (i.e., user picks a different job),
        .onChange(of: job.id) { _, _ in
            updateWindowTitle()
        }

        // If user chooses to edit the job, present an EditJobView
        .sheet(isPresented: Binding<Bool>(
            get: { jobStore.isEditingJob },
            set: { if !$0 { jobStore.isEditingJob = false } }
        )) {
            if let jobToEdit = jobStore.selectedJob {
                EditJobView(isPresented: $jobStore.isEditingJob, job: jobToEdit)
                    .environmentObject(jobStore)
                    .environmentObject(docStore)
            }
        }

        // QuickLook preview for documents
        .quickLookPreview($quickLookURL)
    }

    // MARK: - Window Title
    /// Updates the macOS window title to "CompanyName JobTitle"
    private func updateWindowTitle() {
        guard let window = windowRef else { return }
        window.title = "\(job.companyName) \(job.jobTitle)"
    }

    // MARK: - Helpers
    
    /// Cleans up extraneous text or file extensions from a doc filename
    private func cleanFileName(_ filename: String) -> String {
        var cleanedName = filename
        let stringsToRemove = ["Roger Lin", "Position", "2024", "Cover Letter"]
        for stringToRemove in stringsToRemove {
            cleanedName = cleanedName.replacingOccurrences(of: stringToRemove, with: "")
        }
        cleanedName = cleanedName.trimmingCharacters(in: .whitespaces)
        for extensionString in [".pdf", ".docx", ".pages"] {
            if cleanedName.hasSuffix(extensionString) {
                cleanedName = String(cleanedName.dropLast(extensionString.count))
                break
            }
        }
        return cleanedName
    }

    /// Opens the Quick Look preview for a document
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

    /// Reveals the document in Finder
    private func revealInFinder(_ doc: JobDocument) {
        if let fileURL = doc.fileURL {
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        }
    }
}

// MARK: - NewLocationView
/**
 A small sheet to add a brand-new location with name, latitude, and longitude.
 */
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
            TextField("Location Name", text: $newLocationName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Latitude", text: $latitude)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Longitude", text: $longitude)
                .textFieldStyle(RoundedBorderTextFieldStyle())
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
        }
        .padding()
        .frame(width: 300, height: 200)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
    }
}

// MARK: - AddJobView
// -----------------------------------------------------
// Allows adding a new JobApplication with Rich Text
// for job description, cover letter, and notes,
// plus document uploads.
// -----------------------------------------------------
import SwiftUI
import AppKit
import PDFKit

struct AddJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var isPresented: Bool
    @StateObject private var viewModel = JobViewModel()
    
    @State private var importedDocuments: [JobDocument] = []
    @State private var isImporting = false
    
    @State private var locations: [String] = []
    @State private var showAddLocationSheet = false
    @State private var quickLookURL: URL? = nil

    var body: some View {
        VStack {
            Text("Add New Job")
                .font(.title2)
                .padding()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("JOB DETAILS")
                    TextField("Company Name", text: $viewModel.companyName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: viewModel.companyName) { _, _ in
                            viewModel.validateInputs()
                        }
                    TextField("Job Title", text: $viewModel.jobTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: viewModel.jobTitle) {  _, _ in
                            viewModel.validateInputs()
                        }

                    sectionHeader("APPLICATION DETAILS")
                    TextField("Link to Job", text: $viewModel.linkToJob)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Picker("Status", selection: $viewModel.status) {
                        ForEach(JobStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    Picker("Location", selection: $viewModel.location) {
                        ForEach(locations, id: \.self) { location in
                            Text(location)
                        }
                        Text("Add New Location").tag("Add New Location")
                    }
                    .onChange(of: viewModel.location) { _, newValue in
                        if newValue == "Add New Location" {
                            viewModel.location = ""
                            showAddLocationSheet = true
                        }
                    }
                    DatePicker("Application Date", selection: $viewModel.dateOfApplication, displayedComponents: .date)

                    sectionHeader("DOCUMENTS")
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
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                    Button("Upload Documents") {
                        isImporting = true
                    }

                    sectionHeader("JOB DESCRIPTION (Rich Text)")
                    RichTextEditor(attributedText: $viewModel.jobDescriptionRTF)
                        .frame(minHeight: 80)
                        .border(Color.gray, width: 1)

                    sectionHeader("COVER LETTER (Rich Text)")
                    RichTextEditor(attributedText: $viewModel.coverLetterRTF)
                        .frame(minHeight: 80)
                        .border(Color.gray, width: 1)

                    sectionHeader("NOTES (Rich Text)")
                    RichTextEditor(attributedText: $viewModel.notesRTF)
                        .frame(minHeight: 80)
                        .border(Color.gray, width: 1)
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

                Button {
                    viewModel.validateInputs()
                    if viewModel.isInputValid {
                        // Save the imported docs into app support, merge them with docStore
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
                        docStore.mergeDocuments(savedDocs)
                        
                        // Actually add job with RTF data
                        viewModel.addJob(to: jobStore, documents: savedDocs)
                        isPresented = false
                    }
                } label: {
                    Text("Save")
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
        .onAppear {
            locations = Array(Set(jobStore.jobApplications.map { $0.location })).sorted()
        }
        .quickLookPreview($quickLookURL)
    }

    // Helper to display small section headers
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.secondary)
            .padding(.top, 6)
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
        return cleanedName.trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - EditJobView
// -----------------------------------------------------
// Allows editing an existing JobApplication, including
// Rich Text for job description, cover letter, and notes,
// plus uploading additional documents.
// -----------------------------------------------------
struct EditJobView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore

    var job: JobApplication
    @StateObject private var viewModel: JobViewModel

    init(isPresented: Binding<Bool>, job: JobApplication) {
        self._isPresented = isPresented
        // Initialize with existing job
        let vm = JobViewModel(job: job)
        _viewModel = StateObject(wrappedValue: vm)
    }

    @State private var importedDocuments: [JobDocument] = []
    @State private var isImporting = false

    var body: some View {
        VStack {
            Text("Edit Job")
                .font(.title2)
                .padding()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("JOB DETAILS")
                    TextField("Company Name", text: $viewModel.companyName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: viewModel.companyName) { _, _ in
                            viewModel.validateInputs()
                        }
                    TextField("Job Title", text: $viewModel.jobTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: viewModel.jobTitle) { _, _ in
                            viewModel.validateInputs()
                        }

                    sectionHeader("APPLICATION DETAILS")
                    TextField("Link to Job", text: $viewModel.linkToJob)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Picker("Status", selection: $viewModel.status) {
                        ForEach(JobStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    TextField("Location", text: $viewModel.location)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    DatePicker("Application Date", selection: $viewModel.dateOfApplication, displayedComponents: .date)

                    sectionHeader("JOB DESCRIPTION (Rich Text)")
                    RichTextEditor(attributedText: $viewModel.jobDescriptionRTF)
                        .frame(minHeight: 80)
                        .border(Color.gray, width: 1)

                    sectionHeader("COVER LETTER (Rich Text)")
                    RichTextEditor(attributedText: $viewModel.coverLetterRTF)
                        .frame(minHeight: 80)
                        .border(Color.gray, width: 1)

                    sectionHeader("NOTES (Rich Text)")
                    RichTextEditor(attributedText: $viewModel.notesRTF)
                        .frame(minHeight: 80)
                        .border(Color.gray, width: 1)
                    
                    sectionHeader("DOCUMENTS")
                    if !importedDocuments.isEmpty {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(importedDocuments, id: \.id) { doc in
                                    Text(doc.fileName)
                                        .gradientForeground(colors: [.blue, .purple])
                                        .padding(.horizontal, 5)
                                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray))
                                }
                            }
                        }
                    }
                    Button("Upload Documents") {
                        isImporting = true
                    }
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
                    viewModel.validateInputs()
                    if viewModel.isInputValid {
                        // Merge newly imported docs
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
                        // Now combine old + new
                        let totalDocs = job.documents + savedDocs
                        docStore.mergeDocuments(totalDocs)
                        
                        // Build updated job
                        let updatedJob = JobApplication(
                            id: job.id,
                            companyName: viewModel.companyName,
                            jobTitle: viewModel.jobTitle,
                            status: viewModel.status,
                            dateOfApplication: viewModel.dateOfApplication,
                            location: viewModel.location,
                            linkToJobString: viewModel.linkToJob.isEmpty ? nil : viewModel.linkToJob,
                            salary: nil,
                            jobDescription: viewModel.jobDescriptionRTF.string,
                            coverLetter: viewModel.coverLetterRTF.string,
                            notes: viewModel.notesRTF.string,
                            jobDescriptionRTFData: rtfData(from: viewModel.jobDescriptionRTF),
                            coverLetterRTFData: rtfData(from: viewModel.coverLetterRTF),
                            notesRTFData: rtfData(from: viewModel.notesRTF),
                            documents: totalDocs,
                            isFavorite: job.isFavorite
                        )
                        jobStore.editJob(with: updatedJob)
                        isPresented = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(!viewModel.isInputValid)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 600)
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
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.secondary)
            .padding(.top, 6)
    }
}

// MARK: - EnhancedStatsView
// -----------------------------------------------------
// Example stats & visualizations view. The second chart
// is a "GitHub-like" chart in which we highlight any job
// with status == .interview in purple. Other statuses
// could be green (or any color you want).
// -----------------------------------------------------
import SwiftUI
import Charts

struct EnhancedStatsView: View {
    @EnvironmentObject var jobStore: JobStore
    
    var body: some View {
        VStack {
            Text("Stats & Visualizations")
                .font(.title)
                .padding()
            
            // Example 1: Simple bar chart of companies
            Text("Chart #1: Company Frequency")
            let freqData = companyFrequency()
            Chart(freqData) { item in
                BarMark(
                    x: .value("Count", item.count),
                    y: .value("Company", item.name)
                )
                .foregroundStyle(.blue)
            }
            .frame(height: 200)
            .padding(.bottom, 32)
            
            // Example 2: "GitHub Contribution" style squares
            Text("Chart #2: GitHub-like Chart of statuses")
            let dailyData = createDailyStatusData()
            Chart(dailyData) { record in
                RectangleMark(
                    x: .value("Date", record.date),
                    y: .value("Index", 1) // or some grouping
                )
                // Interview = Purple, otherwise green
                .foregroundStyle(record.status == .interview ? Color.purple : Color.green)
                .annotation {
                    Text(record.status.rawValue.prefix(1))
                        .font(.caption2)
                        .foregroundColor(.white)
                }
            }
            .frame(height: 120)
            
            Spacer()
        }
        .padding()
    }
    
    // A simple aggregator for example
    private func companyFrequency() -> [CompanyFreq] {
        let dict = Dictionary(grouping: jobStore.jobApplications, by: { $0.companyName })
        let freq: [CompanyFreq] = dict.map { (key, apps) in
            CompanyFreq(name: key, count: apps.count)
        }
        return freq.sorted { $0.count > $1.count }
    }
    
    // Example "daily status" data for second chart
    private func createDailyStatusData() -> [(date: Date, status: JobStatus)] {
        // For demonstration, we list each job’s date + status
        jobStore.jobApplications.map {
            (date: $0.dateOfApplication, status: $0.status)
        }
        .sorted { $0.date < $1.date }
    }
}
