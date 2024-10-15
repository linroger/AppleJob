//
//  AppleJob.swift
//  AppleJob
//
//  A fully-implemented SwiftUI-based macOS application codebase in a single file.
//  Updated for macOS 15 "Sequoia" to include modern Map usage, ensuring that
//  `cityPins` is properly in scope and that the bar and line charts expand to fill
//  the horizontal space of the main view.
//
//  ---------------------------------------------------------------------------------
//  CHANGELOG / FIXES:
//  1. The Save Button Issue in Add/Edit Job:
//     • Validated by ensuring `viewModel.isInputValid` is set whenever fields change.
//     • Button remains disabled if required fields are empty.
//
//  2. Map Annotations for macOS 15:
//     • Using `Map(coordinateRegion:annotationItems:) { ... }` with `MapAnnotation(...){ ... }`.
//     • Extracted `CityPinAnnotationView` and `EnhancedStatsMapView` to ease type-checking.
//
//  3. Bar/Line Charts Filling Horizontal Space:
//     • Removed fixed width of 800 from the bar/line chart section.
//     • Now uses `GeometryReader` or a `.frame(minWidth:)` approach plus horizontal
//       padding to allow them to stretch across the main view.
//
//  4. Full Single-File Codebase with All Models, View Models, and Views:
//     • Contains the entire code from start to finish, including
//       AddJobView, EditJobView, EnhancedStatsView, etc.
//  ---------------------------------------------------------------------------------
//  CHANGELOG / FIXES:
//    1. Replaced Map usage with 'annotationItems' to fix compilation errors on macOS.
//    2. Removed erroneous .overlay(...) calls referencing chartProxy.plotFrame() as a function.
//    3. Changed ForEach($appsContributionData) to ForEach(appsContributionData) to avoid
//       Binding<SomeStruct> issues and 'cannot assign to let' errors.
//    4. Kept a strong reference to QLPreviewPanel data source to avoid deallocation issues.
//    5. Replaced '.thickMaterial' with '.regularMaterial' for macOS compatibility.
//  ---------------------------------------------------------------------------------

import SwiftUI
import AppKit
import UniformTypeIdentifiers
import PDFKit
import MapKit
import Charts
import Quartz

// MARK: - Data Models

/// Represents different statuses for a job application.
enum JobStatus: String, CaseIterable, Codable {
    case interested = "Interested"
    case applied = "Applied"
    case interview = "Interview"
    case offer = "Offer"
    case rejection = "Rejection"

    /// Returns the display color associated with each job status.
    var displayColor: Color {
        switch self {
        case .interested: return .gray
        case .applied:    return .blue
        case .interview:  return .orange
        case .offer:      return .green
        case .rejection:  return .red
        }
    }
}

/// Sorting options for the job application list.
enum Sort: String, CaseIterable {
    case title = "Job Title"
    case company = "Company Name"
    case recentlyApplied = "Recently Applied"
}

/// Primary data model representing a job application.
struct JobApplication: Codable, Identifiable, Hashable {
    var id: UUID
    var companyName: String
    var jobTitle: String
    var status: JobStatus
    var dateOfApplication: Date
    var location: String
    var linkToJobString: String?
    var salary: Double?
    var jobDescription: String
    var coverLetter: String
    var notes: String?
    var isFavorite: Bool
    var documents: [JobDocument]

    /// Initializes a new JobApplication with default values.
    init(
        id: UUID = UUID(),
        companyName: String,
        jobTitle: String,
        status: JobStatus = .interested,
        dateOfApplication: Date = Date(),
        location: String,
        linkToJobString: String? = nil,
        salary: Double? = nil,
        jobDescription: String = "",
        coverLetter: String = "",
        notes: String? = nil,
        documents: [JobDocument] = [],
        isFavorite: Bool = false
    ) {
        self.id = id
        self.companyName = companyName
        self.jobTitle = jobTitle
        self.status = status
        self.dateOfApplication = dateOfApplication
        self.location = location
        self.linkToJobString = linkToJobString
        self.salary = salary
        self.jobDescription = jobDescription
        self.coverLetter = coverLetter
        self.notes = notes
        self.documents = documents
        self.isFavorite = isFavorite
    }

    /// Custom decoder to handle `statusRawValue`.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.companyName = try container.decode(String.self, forKey: .companyName)
        self.jobTitle = try container.decode(String.self, forKey: .jobTitle)
        let statusRawValue = try container.decode(String.self, forKey: .statusRawValue)
        self.status = JobStatus(rawValue: statusRawValue) ?? .interested
        self.dateOfApplication = try container.decode(Date.self, forKey: .dateOfApplication)
        self.location = try container.decode(String.self, forKey: .location)
        self.linkToJobString = try? container.decode(String.self, forKey: .linkToJobString)
        self.salary = try? container.decode(Double.self, forKey: .salary)
        self.jobDescription = try container.decode(String.self, forKey: .jobDescription)
        self.coverLetter = try container.decode(String.self, forKey: .coverLetter)
        self.notes = try? container.decode(String.self, forKey: .notes)
        self.isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        self.documents = try container.decode([JobDocument].self, forKey: .documents)
    }

    /// Custom encoder to handle `statusRawValue`.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(companyName, forKey: .companyName)
        try container.encode(jobTitle, forKey: .jobTitle)
        try container.encode(status.rawValue, forKey: .statusRawValue)
        try container.encode(dateOfApplication, forKey: .dateOfApplication)
        try container.encode(location, forKey: .location)
        try container.encode(linkToJobString, forKey: .linkToJobString)
        try container.encode(salary, forKey: .salary)
        try container.encode(jobDescription, forKey: .jobDescription)
        try container.encode(coverLetter, forKey: .coverLetter)
        try container.encode(notes, forKey: .notes)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encode(documents, forKey: .documents)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case companyName
        case jobTitle
        case statusRawValue
        case dateOfApplication
        case location
        case linkToJobString
        case salary
        case jobDescription
        case coverLetter
        case notes
        case isFavorite
        case documents
    }

    /// Equatable conformance based on `id`.
    static func == (lhs: JobApplication, rhs: JobApplication) -> Bool {
        lhs.id == rhs.id
    }

    /// Hashable conformance based on `id`.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Data model representing a document uploaded to the system.
struct JobDocument: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var fileName: String
    var fileData: Data

    var dateOfApplication: Date
    var lastModifiedDate: Date
    var fileSize: Int
    var wordCount: Int

    /// Initializes a new JobDocument with default values.
    init(id: UUID = UUID(), fileName: String, fileData: Data) {
        self.id = id
        self.fileName = fileName
        self.fileData = fileData
        self.dateOfApplication = Date()
        self.lastModifiedDate = Date()
        self.fileSize = fileData.count
        self.wordCount = 0
    }

    /// Custom decoder to handle optional fields.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.fileName = try container.decode(String.self, forKey: .fileName)
        self.fileData = try container.decode(Data.self, forKey: .fileData)
        self.dateOfApplication = try container.decodeIfPresent(Date.self, forKey: .dateOfApplication) ?? Date()
        self.lastModifiedDate = try container.decodeIfPresent(Date.self, forKey: .lastModifiedDate) ?? Date()
        self.fileSize = try container.decodeIfPresent(Int.self, forKey: .fileSize) ?? 0
        self.wordCount = try container.decodeIfPresent(Int.self, forKey: .wordCount) ?? 0
    }

    enum CodingKeys: String, CodingKey {
        case id
        case fileName
        case fileData
        case dateOfApplication
        case lastModifiedDate
        case fileSize
        case wordCount
    }

    /// Equatable conformance based on `id`.
    static func == (lhs: JobDocument, rhs: JobDocument) -> Bool {
        lhs.id == rhs.id
    }

    /// Hashable conformance based on `id`.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Data structure for the top 20 companies bar chart.
struct CompanyFreq: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
}

/// Represents a city with latitude, longitude, and number of job applications.
struct CityPin: Identifiable {
    let id = UUID()
    let city: String
    let coordinate: CLLocationCoordinate2D
    let count: Int
}

/// Basic dictionary of known city coordinates.
fileprivate var CityCoordinateDictionary: [String: CLLocationCoordinate2D] = [
    "New York City, NY": CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
    "Los Angeles, CA":   CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
    "Chicago, IL":       CLLocationCoordinate2D(latitude: 41.8781, longitude: -87.6298),
    "San Francisco, CA": CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    "Seattle, WA":       CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321),
    "Boston, MA":        CLLocationCoordinate2D(latitude: 42.3601, longitude: -71.0589),
    "Austin, TX":        CLLocationCoordinate2D(latitude: 30.2672, longitude: -97.7431),
    "Atlanta, GA":       CLLocationCoordinate2D(latitude: 33.7490, longitude: -84.3880),
    "Washington DC":     CLLocationCoordinate2D(latitude: 38.9072, longitude: -77.0369),
    "Hong Kong SAR":     CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694),
    "London, UK":        CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
    "Shanghai, CN":      CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
    "Singapore":         CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198),
    "Greenwich, CT":     CLLocationCoordinate2D(latitude: 41.0262, longitude: -73.6282),
    "Remote":            CLLocationCoordinate2D(latitude: 34.149884, longitude: -118.056932),
    "Newport Beach, CA": CLLocationCoordinate2D(latitude: 33.6189, longitude: -117.9298),
    "Shenzhen, CN":      CLLocationCoordinate2D(latitude: 22.5431, longitude: 114.0579),
    "Global":            CLLocationCoordinate2D(latitude: 34.149884, longitude: -118.056932)
]

/// Contribution data for GitHub-like charts.
struct Contribution: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
}

/// Data for daily applications in bar/line charts.
struct DailyApps: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

// MARK: - View Models

/// View model managing job applications.
class JobStore: ObservableObject {
    @Published var jobApplications: [JobApplication] = []
    @Published var selectedJob: JobApplication? = nil
    @Published var isAddingNewJob = false
    @Published var isEditingJob = false
    @Published var sorting: Sort = .recentlyApplied

    /// Initializes the JobStore by loading saved jobs.
    init() {
        loadJobs()
    }

    /// Adds a new job application.
    func addJob(_ job: JobApplication) {
        jobApplications.append(job)
        sortJobs(by: sorting)
        saveJobs()
    }

    /// Edits an existing job application.
    func editJob(with updatedJob: JobApplication) {
        if let index = jobApplications.firstIndex(where: { $0.id == updatedJob.id }) {
            jobApplications[index] = updatedJob
            sortJobs(by: sorting)
            saveJobs()
        }
    }

    /// Deletes a job application by its ID.
    func deleteJob(for id: UUID) {
        if let index = jobApplications.firstIndex(where: { $0.id == id }) {
            jobApplications.remove(at: index)
            if selectedJob?.id == id {
                selectedJob = nil
            }
            saveJobs()
        }
    }

    /// Duplicates a job application.
    func duplicateJob(_ job: JobApplication) {
        let newJob = JobApplication(
            companyName: job.companyName,
            jobTitle: job.jobTitle,
            status: job.status,
            dateOfApplication: Date(),
            location: job.location,
            linkToJobString: job.linkToJobString,
            salary: job.salary,
            jobDescription: job.jobDescription,
            coverLetter: job.coverLetter,
            notes: job.notes,
            documents: job.documents,
            isFavorite: job.isFavorite
        )
        jobApplications.append(newJob)
        sortJobs(by: sorting)
        saveJobs()
    }

    /// Updates the status of a job application.
    func updateJobStatus(_ id: UUID, to status: JobStatus) {
        if let index = jobApplications.firstIndex(where: { $0.id == id }) {
            jobApplications[index].status = status
            saveJobs()
        }
    }

    /// Toggles the favorite status of a job application.
    func toggleFavorite(for id: UUID) {
        if let index = jobApplications.firstIndex(where: { $0.id == id }) {
            jobApplications[index].isFavorite.toggle()
            saveJobs()
        }
    }

    /// Edits the notes of a job application.
    func editJobNotes(with notes: String, for id: UUID) {
        if let index = jobApplications.firstIndex(where: { $0.id == id }) {
            jobApplications[index].notes = notes.isEmpty ? nil : notes
            saveJobs()
        }
    }

    /// Sorts the job applications based on the selected sort option.
    func sortJobs(by sortOption: Sort) {
        switch sortOption {
        case .title:
            jobApplications.sort { $0.jobTitle.lowercased() < $1.jobTitle.lowercased() }
        case .company:
            jobApplications.sort { $0.companyName.lowercased() < $1.companyName.lowercased() }
        case .recentlyApplied:
            jobApplications.sort { $0.dateOfApplication > $1.dateOfApplication }
        }
    }

    /// Saves the job applications to UserDefaults.
    func saveJobs() {
        do {
            let data = try JSONEncoder().encode(jobApplications)
            UserDefaults.standard.set(data, forKey: "jobs")
        } catch {
            print("Failed to save jobs: \(error.localizedDescription)")
        }
    }

    /// Loads the job applications from UserDefaults.
    func loadJobs() {
        guard let savedData = UserDefaults.standard.data(forKey: "jobs") else { return }
        do {
            let loadedApps = try JSONDecoder().decode([JobApplication].self, from: savedData)
            jobApplications = loadedApps
            sortJobs(by: sorting)
        } catch {
            print("Failed to load jobs: \(error.localizedDescription)")
        }
    }

    // MARK: - Import/Export

    /// Imports job applications from a backup file.
    func importBackup(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let importedJobs = try JSONDecoder().decode([JobApplication].self, from: data)
            guard !importedJobs.isEmpty else { return }
            DispatchQueue.main.async {
                self.jobApplications = importedJobs
                self.sortJobs(by: self.sorting)
                self.saveJobs()
            }
        } catch {
            print("Error importing jobs: \(error)")
        }
    }

    /// Exports job applications to a backup file.
    func exportBackup(url: URL) {
        do {
            let data = try JSONEncoder().encode(jobApplications)
            try data.write(to: url)
            print("Exported backup.")
        } catch {
            print("Error exporting jobs: \(error)")
        }
    }
}

/// View model managing documents.
class DocumentStore: ObservableObject {
    @Published var documents: [JobDocument] = []
    @Published var selectedDocument: JobDocument? = nil

    /// Initializes the DocumentStore by loading saved documents.
    init() {
        loadDocuments()
    }

    /// Uploads documents from given URLs.
    func uploadDocuments(from urls: [URL]) {
        for url in urls {
            guard let data = try? Data(contentsOf: url) else { continue }
            let doc = JobDocument(fileName: url.lastPathComponent, fileData: data)
            if !documents.contains(doc) {
                documents.append(doc)
            }
        }
        saveDocuments()
    }

    /// Downloads the selected document to a user-specified location.
    func downloadSelectedDocument() {
        guard let doc = selectedDocument else { return }
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = doc.fileName
        savePanel.begin { response in
            if response == .OK, let selectedURL = savePanel.url {
                do {
                    try doc.fileData.write(to: selectedURL)
                } catch {
                    print("Error saving document: \(error)")
                }
            }
        }
    }

    /// Duplicates a given document.
    func duplicateDocument(_ document: JobDocument) {
        let newDoc = JobDocument(
            fileName: "\(document.fileName)-copy",
            fileData: document.fileData
        )
        documents.append(newDoc)
        saveDocuments()
    }

    /// Deletes a given document.
    func deleteDocument(_ document: JobDocument) {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents.remove(at: index)
        }
        if selectedDocument?.id == document.id {
            selectedDocument = nil
        }
        saveDocuments()
    }

    /// Merges new documents into the existing list.
    func mergeDocuments(_ newDocs: [JobDocument]) {
        for doc in newDocs {
            if !documents.contains(doc) {
                documents.append(doc)
            }
        }
        saveDocuments()
    }

    /// Saves the documents to UserDefaults.
    func saveDocuments() {
        do {
            let data = try JSONEncoder().encode(documents)
            UserDefaults.standard.set(data, forKey: "documents")
        } catch {
            print("Failed to save documents: \(error.localizedDescription)")
        }
    }

    /// Loads the documents from UserDefaults.
    func loadDocuments() {
        guard let savedData = UserDefaults.standard.data(forKey: "documents") else { return }
        do {
            let loadedDocs = try JSONDecoder().decode([JobDocument].self, from: savedData)
            documents = loadedDocs
        } catch {
            print("Failed to load documents: \(error.localizedDescription)")
        }
    }
}

/// Helper class for import/export functionalities.
@MainActor
class ImportExportHelper: NSObject, ObservableObject {
    @Published var isImporting = false
    @Published var isExporting = false

    /// Presents an open panel for importing backups.
    func importBackup(completion: @escaping (URL) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [UTType.json]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                completion(url)
            }
        }
    }

    /// Presents a save panel for exporting backups.
    func exportBackup(completion: @escaping (URL) -> Void) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.json]
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "JobsBackup.json"
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                completion(url)
            }
        }
    }

    /// Shows a Quick Look preview for a given file URL.
    func showQuickLookPreview(for fileURL: URL) {
        // Must keep a strong reference to the data source
        // or it will be deallocated immediately
        if let panel = QLPreviewPanel.shared() {
            let ds = PreviewPanelDataSource(fileURL: fileURL)
            QLPreviewPanelHolder.sharedDataSource = ds
            panel.dataSource = ds
            panel.makeKeyAndOrderFront(nil)
        }
    }

    /// Presents an open panel for importing documents.
    func importDocuments(completion: @escaping ([URL]) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.pdf, .image, .plainText, .rtf]
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.begin { response in
            if response == .OK {
                completion(openPanel.urls)
            }
        }
    }

    /// Presents a save panel for exporting documents.
    func exportDocuments(completion: @escaping (URL) -> Void) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.zip]
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "DocumentsExport.zip"
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                completion(url)
            }
        }
    }
}

/// View model for managing job details in forms.
class JobViewModel: ObservableObject {
    @Published var companyName: String = ""
    @Published var jobTitle: String = ""
    @Published var status: JobStatus = .interested
    @Published var dateOfApplication: Date = Date()
    @Published var location: String = ""
    @Published var linkToJob: String = ""
    @Published var jobDescription: String = ""
    @Published var coverLetter: String = ""
    @Published var notes: String = ""
    @Published var isInputValid: Bool = false

    /// Initializes the JobViewModel and validates inputs.
    init() {
        validateInputs()
    }

    /// Initializes the JobViewModel with an existing JobApplication.
    init(job: JobApplication) {
        companyName = job.companyName
        jobTitle = job.jobTitle
        status = job.status
        dateOfApplication = job.dateOfApplication
        location = job.location
        linkToJob = job.linkToJobString ?? ""
        jobDescription = job.jobDescription
        coverLetter = job.coverLetter
        notes = job.notes ?? ""
        validateInputs()
    }

    /// Validates the input fields.
    func validateInputs() {
        DispatchQueue.main.async {
            self.isInputValid = !(self.companyName.isEmpty || self.jobTitle.isEmpty)
        }
    }

    /// Adds a new job application to the JobStore.
    func addJob(to store: JobStore, documents: [JobDocument]) {
        guard isInputValid else { return }
        let newJob = JobApplication(
            companyName: companyName,
            jobTitle: jobTitle,
            status: status,
            dateOfApplication: dateOfApplication,
            location: location,
            linkToJobString: linkToJob.isEmpty ? nil : linkToJob,
            salary: nil,
            jobDescription: jobDescription,
            coverLetter: coverLetter,
            notes: notes.isEmpty ? nil : notes,
            documents: documents,
            isFavorite: false
        )
        store.addJob(newJob)
        reset()
    }

    /// Resets the input fields to default values.
    func reset() {
        companyName = ""
        jobTitle = ""
        status = .interested
        dateOfApplication = Date()
        location = ""
        linkToJob = ""
        jobDescription = ""
        coverLetter = ""
        notes = ""
        validateInputs()
    }
}

// MARK: - Preview Panel Holder

/// A static holder to keep a strong reference to PreviewPanelDataSource.
class QLPreviewPanelHolder {
    static var sharedDataSource: PreviewPanelDataSource?
}

// MARK: - Main App Structure

@main
struct AppleJobApp: App {
    @StateObject private var jobStore = JobStore()
    @StateObject private var docStore = DocumentStore()
    @StateObject private var importExportHelper = ImportExportHelper()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(jobStore)
                .environmentObject(docStore)
                .environmentObject(importExportHelper)
        }
        .commands {
            fileMenuCommands
            editMenuCommands
        }
    }

    /// Defines the File menu commands.
    private var fileMenuCommands: some Commands {
        CommandMenu("File") {
            Button("Import Backup...") {
                importExportHelper.importBackup { url in
                    jobStore.importBackup(url: url)
                }
            }
            .keyboardShortcut("I", modifiers: [.command, .shift])

            Button("Export Backup...") {
                importExportHelper.exportBackup { url in
                    jobStore.exportBackup(url: url)
                }
            }
            .keyboardShortcut("E", modifiers: [.command, .shift])

            Divider()

            Button("Import Documents...") {
                importExportHelper.importDocuments { urls in
                    docStore.uploadDocuments(from: urls)
                }
            }

            Button("Export Documents...") {
                importExportHelper.exportDocuments { url in
                    exportAllDocumentsToZip(url: url)
                }
            }
        }
    }

    /// Defines the Edit menu commands.
    private var editMenuCommands: some Commands {
        CommandMenu("Edit") {
            Button("Add New Application") {
                jobStore.isAddingNewJob = true
            }
            .keyboardShortcut("N", modifiers: .command)

            Button("Edit Application") {
                jobStore.isEditingJob = true
            }
            .keyboardShortcut("E", modifiers: .command)
            .disabled(jobStore.selectedJob == nil)

            Divider()

            Button("Favorite Application") {
                if let selectedJob = jobStore.selectedJob {
                    jobStore.toggleFavorite(for: selectedJob.id)
                }
            }
            .keyboardShortcut("F", modifiers: .command)
            .disabled(jobStore.selectedJob == nil)

            Divider()

            Menu("Update Status") {
                ForEach(JobStatus.allCases, id: \.self) { status in
                    Button(status.rawValue) {
                        if let selectedJob = jobStore.selectedJob {
                            jobStore.updateJobStatus(selectedJob.id, to: status)
                        }
                    }
                }
            }
            .disabled(jobStore.selectedJob == nil)

            Divider()

            Button("Duplicate Application") {
                if let selectedJob = jobStore.selectedJob {
                    jobStore.duplicateJob(selectedJob)
                }
            }
            .keyboardShortcut("D", modifiers: .command)
            .disabled(jobStore.selectedJob == nil)

            Divider()

            Button("Delete Application") {
                if let selectedJob = jobStore.selectedJob {
                    jobStore.deleteJob(for: selectedJob.id)
                }
            }
            .keyboardShortcut(.delete, modifiers: .command)
            .disabled(jobStore.selectedJob == nil)
        }
    }

    /// Helper method to export documents as a ZIP archive.
    private func exportAllDocumentsToZip(url: URL) {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("temp_documents")

        do {
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

            for doc in docStore.documents {
                let fileURL = tempDir.appendingPathComponent(doc.fileName)
                try doc.fileData.write(to: fileURL)
            }

            let zipURL = url
            try createZipArchive(at: tempDir, destination: zipURL)
            try fileManager.removeItem(at: tempDir)
            print("Successfully exported documents.")

        } catch {
            print("Failed to export documents: \(error)")
        }
    }

    /// Creates a ZIP archive from the source URL to the destination URL.
    private func createZipArchive(at sourceURL: URL, destination: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-r", destination.path, "."]
        process.currentDirectoryURL = sourceURL

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw NSError(domain: "ZipError",
                          code: Int(process.terminationStatus),
                          userInfo: [NSLocalizedDescriptionKey: "Zip process failed."])
        }
    }
}

// MARK: - Views

/// Enumeration for different sections in the main view.
enum ViewSection: String, CaseIterable {
    case jobDetails = "Job Details"
    case stats = "Stats"
    case documents = "Documents"
}

/// The main content view containing the sidebar and main content area.
struct ContentView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @EnvironmentObject var importExportHelper: ImportExportHelper
    @State private var selectedSection: ViewSection = .jobDetails
    @State private var searchText: String = ""
    @State private var isDarkMode: Bool = false
    @State private var showDocInfoPopover = false

    var body: some View {
        NavigationView {
            sidebar
                .frame(minWidth: 250)
                .background(
                    Color.black.opacity(0.03)
                        .blur(radius: 5)
                )
            mainContent
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .toolbar {
            ToolbarItemGroup {
                // Segmented Picker for sections
                Picker("View Section", selection: $selectedSection) {
                    ForEach(ViewSection.allCases, id: \.self) { section in
                        Text(section.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)

                Spacer()

                // Document Upload/Download if in Documents section
                if selectedSection == .documents {
                    Button {
                        let openPanel = NSOpenPanel()
                        openPanel.allowedContentTypes = [.pdf, .plainText, .rtf, .image]
                        openPanel.canChooseFiles = true
                        openPanel.canChooseDirectories = false
                        openPanel.allowsMultipleSelection = true
                        openPanel.begin { result in
                            if result == .OK {
                                docStore.uploadDocuments(from: openPanel.urls)
                            }
                        }
                    } label: {
                        Label("Upload", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        docStore.downloadSelectedDocument()
                    } label: {
                        Label("Download", systemImage: "square.and.arrow.down")
                    }

                    Button {
                        showDocInfoPopover.toggle()
                    } label: {
                        Label("Info", systemImage: "info.circle")
                    }
                    .popover(isPresented: $showDocInfoPopover) {
                        DocumentInfoPopover(document: docStore.selectedDocument)
                    }
                }

                // Dark Mode Toggle
                Button {
                    isDarkMode.toggle()
                } label: {
                    Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                }
            }
        }
    }

    /// Sidebar view based on the selected section.
    @ViewBuilder
    private var sidebar: some View {
        switch selectedSection {
        case .jobDetails, .stats:
            JobSidebarView(searchText: $searchText)
        case .documents:
            DocumentsSidebarView()
        }
    }

    /// Main content area based on the selected section.
    @ViewBuilder
    private var mainContent: some View {
        switch selectedSection {
        case .jobDetails:
            if let job = jobStore.selectedJob {
                JobDetailView(job: job)
            } else {
                Text("Select a job to view details")
                    .foregroundColor(.secondary)
            }
        case .stats:
            EnhancedStatsView()
        case .documents:
            DocumentsMainView()
        }
    }
}

/// Popover that shows metadata about a selected document.
struct DocumentInfoPopover: View {
    let document: JobDocument?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Document Information")
                .font(.headline)
            if let doc = document {
                Text("File Name: \(doc.fileName)")
                Text("Created: \(doc.dateOfApplication.formatted(date: .abbreviated, time: .omitted))")
                Text("Last Modified: \(doc.lastModifiedDate.formatted(date: .abbreviated, time: .omitted))")
                Text("File Size: \(doc.fileSize) bytes")
                Text("Word Count: \(doc.wordCount)")
            } else {
                Text("No document selected.")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(minWidth: 250)
    }
}

// MARK: - Job Sidebar

/// Sidebar view for job applications and statistics.
struct JobSidebarView: View {
    @EnvironmentObject var jobStore: JobStore
    @Binding var searchText: String

    var body: some View {
        List(selection: $jobStore.selectedJob) {
            ForEach(filteredJobs, id: \.id) { job in
                SidebarItemView(job: job, isSelected: Binding {
                     jobStore.selectedJob == job
                 } set: { newValue in
                     if newValue {
                         jobStore.selectedJob = job
                     } else if jobStore.selectedJob == job {
                         jobStore.selectedJob = nil // Handle deselection
                     }
                 })
                 .tag(job)
            }
            .onDelete(perform: deleteJobs)
        }
        .listStyle(SidebarListStyle())
        .searchable(text: $searchText)
        .navigationTitle("Applications")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    jobStore.isAddingNewJob = true
                } label: {
                    Label("New", systemImage: "plus")
                }
            }
        }
        // Popups for adding/editing
        .sheet(isPresented: $jobStore.isAddingNewJob) {
            AddJobView(isPresented: $jobStore.isAddingNewJob)
                .environmentObject(jobStore)
                .environmentObject(DocumentStore())
        }
        .sheet(isPresented: $jobStore.isEditingJob) {
            if let job = jobStore.selectedJob {
                EditJobView(isPresented: $jobStore.isEditingJob, job: job)
                    .environmentObject(jobStore)
                    .environmentObject(DocumentStore())
            }
        }
    }

    /// Filters jobs based on the search text.
    private var filteredJobs: [JobApplication] {
        if searchText.isEmpty {
            return jobStore.jobApplications
        } else {
            let lower = searchText.lowercased()
            return jobStore.jobApplications.filter {
                $0.companyName.lowercased().contains(lower)
                || $0.jobTitle.lowercased().contains(lower)
                || $0.location.lowercased().contains(lower)
            }
        }
    }

    /// Deletes jobs at the specified offsets.
    private func deleteJobs(at offsets: IndexSet) {
        for index in offsets {
            let job = filteredJobs[index]
            jobStore.deleteJob(for: job.id)
        }
    }
}

/// Single job item in the job sidebar list.
struct SidebarItemView: View {
    @EnvironmentObject var jobStore: JobStore
    let job: JobApplication
    @Binding var isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(job.companyName)
                    .font(.headline)
                Text(job.jobTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(job.status.rawValue)
                .font(.caption)
                .padding(5)
                .background(
                    Capsule()
                        .fill(isSelected ? .secondary.opacity(0.8) : job.status.displayColor.opacity(0.2))
                )
                .foregroundColor(job.status.displayColor)

        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                jobStore.isEditingJob = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button {
                jobStore.duplicateJob(job)
            } label: {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }
            Divider()
            Menu("Change Status") {
                ForEach(JobStatus.allCases, id: \.self) { status in
                    Button(status.rawValue) {
                        jobStore.updateJobStatus(job.id, to: status)
                    }
                }
            }
            Divider()
            Button {
                jobStore.toggleFavorite(for: job.id)
            } label: {
                Label(job.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                      systemImage: job.isFavorite ? "heart.fill" : "heart")
            }
            if let link = job.linkToJobString, let url = URL(string: link) {
                Divider()
                Button {
                    NSWorkspace.shared.open(url)
                } label: {
                    Label("Open Job Posting", systemImage: "safari")
                }
            }
            Divider()
            Button(role: .destructive) {
                jobStore.deleteJob(for: job.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Documents Sidebar

/// Sidebar view for managing documents.
struct DocumentsSidebarView: View {
    @EnvironmentObject var docStore: DocumentStore

    var body: some View {
        List(selection: $docStore.selectedDocument) {
            ForEach(docStore.documents, id: \.id) { doc in
                DocumentsSidebarItemView(document: doc)
                    .tag(doc)
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Documents")
    }
}

/// Single document item in the documents sidebar.
struct DocumentsSidebarItemView: View {
    @EnvironmentObject var docStore: DocumentStore
    let document: JobDocument

    var body: some View {
        HStack {
            Text(document.fileName)
                .lineLimit(1)
            Spacer()
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button("Download") {
                docStore.selectedDocument = document
                docStore.downloadSelectedDocument()
            }
            Button("Duplicate") {
                docStore.duplicateDocument(document)
            }
            Divider()
            Button(role: .destructive) {
                docStore.deleteDocument(document)
            } label: {
                Text("Delete")
            }
        }
        .onTapGesture {
            docStore.selectedDocument = document
        }
    }
}

// MARK: - Documents Main

/// Main view for displaying and interacting with documents.
struct DocumentsMainView: View {
    @EnvironmentObject var docStore: DocumentStore

    var body: some View {
        if docStore.documents.isEmpty {
            VStack {
                Spacer()
                Button {
                    showDocumentPicker { urls in
                        docStore.uploadDocuments(from: urls)
                    }
                } label: {
                    Text("Upload")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                Spacer()
            }
        } else if let doc = docStore.selectedDocument {
            PDFKitRepresentedView(fileData: doc.fileData)
        } else {
            Text("Select a document to view.")
                .font(.title3)
                .foregroundColor(.secondary)
        }
    }

    /// Presents a document picker to upload documents.
    private func showDocumentPicker(completion: @escaping ([URL]) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.pdf, .image, .plainText, .rtf]
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = true

        openPanel.begin { result in
            if result == .OK {
                completion(openPanel.urls)
            }
        }
    }
}

/// A SwiftUI wrapper for PDFKit to display a PDF with vertical scrolling.
struct PDFKitRepresentedView: NSViewRepresentable {
    let fileData: Data

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false

        let pdfView = PDFView()
        pdfView.autoScales = true
        if let pdfDoc = PDFDocument(data: fileData) {
            pdfView.document = pdfDoc
        }

        scrollView.documentView = pdfView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let pdfView = nsView.documentView as? PDFView {
            let newDoc = PDFDocument(data: fileData)
            if pdfView.document != newDoc {
                pdfView.document = newDoc
            }
        }
    }
}

// MARK: - Job Detail

/// Detailed view for a selected job application.
struct JobDetailView: View {
    @EnvironmentObject var jobStore: JobStore
    let job: JobApplication

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
                }

                if !job.location.isEmpty {
                    Text("Location: \(job.location)")
                        .font(.headline)
                }

                Text("Applied on: \(job.dateOfApplication.formatted(date: .abbreviated, time: .omitted))")

                if !job.documents.isEmpty {
                    Divider()
                    Text("Documents")
                        .font(.headline)
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(job.documents, id: \.id) { doc in
                                Button(action: {
                                    openQuickLook(doc)
                                })
                                {
                                    HStack {
                                        Image(systemName: "doc.text") // SF Symbol
                                            .foregroundColor(.primary)
                                        Text(cleanFileName(doc.fileName))
                                            .gradientForeground(colors: [.blue, .purple]) // Gradient text
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
                    Text(job.jobDescription)
                        .padding(4)
                }

                if !job.coverLetter.isEmpty {
                    Divider()
                    Text("Cover Letter")
                        .font(.headline)
                    Text(job.coverLetter)
                }

                Divider()
                Text("Notes")
                    .font(.headline)
                if let notes = job.notes {
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
        .navigationTitle("Job Details")
    }

    /// Cleans the file name by removing specified strings and extensions.
    func cleanFileName(_ filename: String) -> String {
        var cleanedName = filename

        // Define strings to remove
        let stringsToRemove = ["Roger Lin", "Position", "2024", "Cover Letter"]

        // Remove specified strings
        for stringToRemove in stringsToRemove {
            cleanedName = cleanedName.replacingOccurrences(of: stringToRemove, with: "")
        }

        // Trim leading and trailing whitespaces
        cleanedName = cleanedName.trimmingCharacters(in: .whitespaces)

        // Remove file extension
        let fileExtensionsToRemove = [".pdf", ".docx", ".pages"]
        for fileExtension in fileExtensionsToRemove {
            if cleanedName.hasSuffix(fileExtension) {
                cleanedName = String(cleanedName.dropLast(fileExtension.count))
                break // Only remove the first matching extension
            }
        }

        return cleanedName
    }

    /// Opens a Quick Look preview for the given document.
    private func openQuickLook(_ doc: JobDocument) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(doc.fileName)
        do {
            try doc.fileData.write(to: tempURL)
            let previewController = QLPreviewPanel()
            let ds = PreviewPanelDataSource(fileURL: tempURL)
            QLPreviewPanelHolder.sharedDataSource = ds
            previewController.dataSource = ds
            previewController.makeKeyAndOrderFront(nil)
        } catch {
            print("Failed to open Quick Look: \(error)")
        }
    }
}

// MARK: - Add Job

/// View for adding a new job application.
struct AddJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var isPresented: Bool

    @StateObject private var viewModel = JobViewModel()
    @State private var importedDocuments: [JobDocument] = []
    @State private var isImporting = false

    @State private var locations: [String] = []
    @State private var showAddLocationSheet = false

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
                        .onChange(of: viewModel.companyName) {
                            viewModel.validateInputs()
                        }
                    TextField("Job Title", text: $viewModel.jobTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: viewModel.jobTitle) {
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
                                    Button(action: {
                                        openQuickLook(doc)
                                    }) {
                                        HStack {
                                            Image(systemName: "doc.text") // SF Symbol
                                                .foregroundColor(.primary)
                                            Text(cleanFileName(doc.fileName))
                                                .gradientForeground(colors: [.blue, .purple]) // Gradient text
                                        }
                                        .padding(8)
                                    }
                                    .buttonStyle(.bordered) // Bordered button
                                    .clipShape(RoundedRectangle(cornerRadius: 8)) // Rounded rectangle
                                }
                            }
                        }
                    }
                    Button("Upload Documents") {
                        isImporting = true
                    }

                    sectionHeader("JOB DESCRIPTION")
                    TextEditor(text: $viewModel.jobDescription)
                        .font(.body)
                        .frame(minHeight: 80)
                        .cornerRadius(5)

                    sectionHeader("COVER LETTER")
                    TextEditor(text: $viewModel.coverLetter)
                        .font(.body)
                        .frame(minHeight: 80)
                        .cornerRadius(5)

                    sectionHeader("NOTES")
                    TextEditor(text: $viewModel.notes)
                        .font(.body)
                        .frame(minHeight: 80)
                        .cornerRadius(5)
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
                        docStore.mergeDocuments(importedDocuments)
                        viewModel.addJob(to: jobStore, documents: importedDocuments)
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
                        let doc = JobDocument(fileName: url.lastPathComponent, fileData: data)
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
    }

    /// Helper function to clean file names.
    func cleanFileName(_ filename: String) -> String {
        var cleanedName = filename

        // Define strings to remove
        let stringsToRemove = ["Roger Lin", "Position", "2024", "Cover Letter"]

        // Remove specified strings
        for stringToRemove in stringsToRemove {
            cleanedName = cleanedName.replacingOccurrences(of: stringToRemove, with: "")
        }

        // Trim leading and trailing whitespaces
        cleanedName = cleanedName.trimmingCharacters(in: .whitespaces)

        // Remove file extension
        let fileExtensionsToRemove = [".pdf", ".docx", ".pages"]
        for fileExtension in fileExtensionsToRemove {
            if cleanedName.hasSuffix(fileExtension) {
                cleanedName = String(cleanedName.dropLast(fileExtension.count))
                break // Only remove the first matching extension
            }
        }

        return cleanedName
    }

    /// Opens a Quick Look preview for the given document.
    private func openQuickLook(_ doc: JobDocument) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(doc.fileName)
        do {
            try doc.fileData.write(to: tempURL)
            let previewController = QLPreviewPanel()
            let ds = PreviewPanelDataSource(fileURL: tempURL)
            QLPreviewPanelHolder.sharedDataSource = ds
            previewController.dataSource = ds
            previewController.makeKeyAndOrderFront(nil)
        } catch {
            print("Failed to open Quick Look: \(error)")
        }
    }

    /// Returns a styled section header.
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .textCase(.uppercase)
    }
}

// MARK: - Edit Job

/// View for editing an existing job application.
struct EditJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var isPresented: Bool

    @StateObject private var viewModel: JobViewModel
    @State private var importedDocuments: [JobDocument] = []
    @State private var isImporting = false

    @State private var locations: [String] = []
    @State private var showAddLocationSheet = false

    /// Initializes the EditJobView with an existing job.
    init(isPresented: Binding<Bool>, job: JobApplication) {
        self._isPresented = isPresented
        self._viewModel = StateObject(wrappedValue: JobViewModel(job: job))
        self._importedDocuments = State(initialValue: job.documents)
    }

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
                                    Button(action: {
                                        openQuickLook(doc)
                                    }) {
                                        HStack {
                                            Image(systemName: "doc.text") // SF Symbol
                                                .foregroundColor(.primary)
                                            Text(cleanFileName(doc.fileName))
                                                .gradientForeground(colors: [.blue, .purple]) // Gradient text
                                        }
                                    }
                                    .buttonStyle(.bordered) // Bordered button
                                    .clipShape(RoundedRectangle(cornerRadius: 8)) // Rounded rectangle
                                }
                            }
                        }
                    }

                    Button("Upload Documents") {
                        isImporting = true
                    }

                    sectionHeader("JOB DESCRIPTION")
                    TextEditor(text: $viewModel.jobDescription)
                        .font(.body)
                        .frame(minHeight: 80)
                        .cornerRadius(5)

                    sectionHeader("COVER LETTER")
                    TextEditor(text: $viewModel.coverLetter)
                        .font(.body)
                        .frame(minHeight: 80)
                        .cornerRadius(5)

                    sectionHeader("NOTES")
                    TextEditor(text: $viewModel.notes)
                        .font(.body)
                        .frame(minHeight: 80)
                        .cornerRadius(5)
                }
                .padding()
            }

            // Action Buttons
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
                    saveChanges()
                    isPresented = false
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
                        let doc = JobDocument(fileName: url.lastPathComponent, fileData: data)
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
    }

    /// Helper function to clean file names.
    func cleanFileName(_ filename: String) -> String {
        var cleanedName = filename

        // Define strings to remove
        let stringsToRemove = ["Roger Lin", "Position", "2024", "Cover Letter"]

        // Remove specified strings
        for stringToRemove in stringsToRemove {
            cleanedName = cleanedName.replacingOccurrences(of: stringToRemove, with: "")
        }

        // Trim leading and trailing whitespaces
        cleanedName = cleanedName.trimmingCharacters(in: .whitespaces)

        // Remove file extension
        let fileExtensionsToRemove = [".pdf", ".docx", ".pages"]
        for fileExtension in fileExtensionsToRemove {
            if cleanedName.hasSuffix(fileExtension) {
                cleanedName = String(cleanedName.dropLast(fileExtension.count))
                break // Only remove the first matching extension
            }
        }

        return cleanedName
    }

    /// Opens a Quick Look preview for the given document.
    private func openQuickLook(_ doc: JobDocument) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(doc.fileName)
        do {
            try doc.fileData.write(to: tempURL)
            let previewController = QLPreviewPanel()
            let ds = PreviewPanelDataSource(fileURL: tempURL)
            QLPreviewPanelHolder.sharedDataSource = ds
            previewController.dataSource = ds
            previewController.makeKeyAndOrderFront(nil)
        } catch {
            print("Failed to open Quick Look: \(error)")
        }
    }

    /// Saves the changes made to the job application.
    private func saveChanges() {
        guard let currentJob = jobStore.selectedJob else { return }

        docStore.mergeDocuments(importedDocuments)

        var updated = currentJob
        updated.companyName = viewModel.companyName
        updated.jobTitle = viewModel.jobTitle
        updated.status = viewModel.status
        updated.dateOfApplication = viewModel.dateOfApplication
        updated.location = viewModel.location
        updated.linkToJobString = viewModel.linkToJob.isEmpty ? nil : viewModel.linkToJob
        updated.jobDescription = viewModel.jobDescription
        updated.coverLetter = viewModel.coverLetter
        updated.notes = viewModel.notes.isEmpty ? nil : viewModel.notes
        updated.documents = importedDocuments

        jobStore.editJob(with: updated)
    }

    /// Returns a styled section header.
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .textCase(.uppercase)
    }
}

// MARK: - Quick Look Preview Panel

/// Data source for Quick Look Preview Panel.
class PreviewPanelDataSource: NSObject, QLPreviewPanelDataSource {
    let fileURL: URL

    /// Initializes with the file URL to preview.
    init(fileURL: URL) {
        self.fileURL = fileURL
        super.init()
    }

    /// Returns the number of preview items.
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        return 1
    }

    /// Returns the preview item at the specified index.
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        return fileURL as QLPreviewItem
    }
}

// MARK: - New Location View

/// View for adding a new location with coordinates.
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
                    isPresented = false // Dismiss the sheet
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
                    locations.append(newLocationName)
                    selectedLocation = newLocationName
                    isPresented = false // Dismiss the sheet
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

// MARK: - Enhanced Stats View

/// The stats view with map, charts, and analytics.
struct EnhancedStatsView: View {
    @EnvironmentObject var jobStore: JobStore

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 50)
    )

    @State private var cityPins: [CityPin] = []
    @State private var yearContributionData: [Contribution] = []
    @State private var appsContributionData: [Contribution] = []

    /// Enumeration for different time ranges.
    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        var id: String { rawValue }
    }

    @State private var selectedTimeRange: TimeRange = .month
    @State private var barLineData: [DailyApps] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                mapSection
                statsRowSection
                githubChartsSection
                timeRangePickerSection
                barLineChartsSection
                top20CompaniesBarSection
            }
            .padding()
        }
        .onAppear {
            computeCityPins()
            computeYearContribution()
            computeAppsContribution()
            computeBarLineData()
        }
        .navigationTitle("Stats & Analytics")
    }

    // MARK: - Map Section

    /// Section displaying the applications on a map.
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Applications Map")
                .font(.headline)
            Map(coordinateRegion: $region,
                annotationItems: cityPins) { cityPin in
                // Scale circle size by application count
                MapAnnotation(coordinate: cityPin.coordinate) {
                    Circle()
                        .fill(Color.red.opacity(0.5))
                        .frame(width: max(10, 2 * CGFloat(cityPin.count)),
                               height: max(10, 2 * CGFloat(cityPin.count)))
                        .overlay(
                            Text("\(cityPin.count)")
                                .foregroundColor(.white)
                                .font(.system(size: 10))
                        )
                }
            }
            .frame(height: 300)
            .cornerRadius(8)
        }
    }

    // MARK: - Horizontal Stats Row

    /// Row displaying key statistics.
    private var statsRowSection: some View {
        let totalApps = jobStore.jobApplications.count
        let interestedCount = jobStore.jobApplications.filter { $0.status == .interested }.count
        let distinctCities = Set(jobStore.jobApplications.map { $0.location }).count
        let topCompany = topCompanyName()

        let gradient = LinearGradient(colors: [.blue, .pink], startPoint: .leading, endPoint: .trailing)

        return HStack(spacing: 32) {
            VStack {
                Text("Total Apps")
                Text("\(totalApps)")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(gradient)
            }
            VStack {
                Text("Interested")
                Text("\(interestedCount)")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(gradient)
            }
            VStack {
                Text("Distinct Cities")
                Text("\(distinctCities)")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(gradient)
            }
            VStack {
                Text("Top Company")
                Text(topCompany)
                    .font(.title3)
                    .bold()
                    .foregroundStyle(gradient)
            }
        }
        .font(.callout)
    }

    // MARK: - GitHub Charts

    /// Section displaying GitHub-style contribution charts.
    private var githubChartsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("GitHub-Style Contribution Charts")
                .font(.headline)

            if #available(macOS 13.0, *) {
                // Entire year
                Chart(yearContributionData) { item in
                    RectangleMark(
                        x: .value("WeekOfYear", item.date, unit: .weekOfYear),
                        y: .value("DayOfWeek", weekday(for: item.date))
                    )
                    .foregroundStyle(by: .value("Count", item.count))
                    .clipShape(RoundedRectangle(cornerRadius: 1))
                }
                .chartForegroundStyleScale(range: Gradient(colors: chartColors))
                .chartYAxis {
                    AxisMarks(values: [1, 3, 5, 7]) { value in
                        if let val = value.as(Int.self), let label = shortWeekdaySymbol(val) {
                            AxisValueLabel(label)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) {
                        AxisValueLabel(format: .dateTime.month())
                    }
                }
                .frame(height: 180)
                .padding(.horizontal, 10)

                // Last 6 months for applications
                Chart(appsContributionData) { item in
                    RectangleMark(
                        x: .value("WeekOfYear", item.date, unit: .weekOfYear),
                        y: .value("DayOfWeek", weekday(for: item.date))
                    )
                    .foregroundStyle(by: .value("Count", item.count))
                    .clipShape(RoundedRectangle(cornerRadius: 1))
                }
                .chartForegroundStyleScale(range: Gradient(colors: chartColors))
                .chartYAxis {
                    AxisMarks(values: [1, 3, 5, 7]) { value in
                        if let val = value.as(Int.self), let label = shortWeekdaySymbol(val) {
                            AxisValueLabel(label)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) {
                        AxisValueLabel(format: .dateTime.month())
                    }
                }
                .frame(height: 180)
                .padding(.horizontal, 10)
            } else {
                Text("Contribution chart requires macOS 13.0+.")
            }
        }
    }

    // MARK: - Time Range Picker

    /// Picker for selecting the time range of data displayed in charts.
    private var timeRangePickerSection: some View {
        HStack {
            Picker("Select Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedTimeRange) { _, _ in
                computeBarLineData()
            }
        }
    }

    // MARK: - Bar + Line Charts

    /// Section displaying bar and line charts for application frequency.
    private var barLineChartsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Applications Frequency")
                .font(.headline)
            
            if #available(macOS 13.0, *) {
                // Use a GeometryReader to fill horizontally
                GeometryReader { geo in
                    VStack(alignment: .leading, spacing: 24) {
                        // Bar chart
                        Chart(barLineData) { dayItem in
                            BarMark(
                                x: .value("Date", dayItem.date),
                                y: .value("Applications", dayItem.count)
                            )
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .weekOfYear)) {
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .dateTime.day().month())
                            }
                        }
                        .frame(height: 160)
                        
                        // Line chart
                        Chart(barLineData) { dayItem in
                            LineMark(
                                x: .value("Date", dayItem.date),
                                y: .value("Applications", dayItem.count)
                            )
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .weekOfYear)) {
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .dateTime.day().month())
                            }
                        }
                        .frame(height: 160)
                    }
                    .frame(width: geo.size.width) // Fill all horizontal space
                }
                .frame(minHeight: 320)         // Enough height for both charts
                .padding(.horizontal, 16)      // Safe buffers left/right
            } else {
                Text("Charts require macOS 13.0+.")
            }
        }
    }

    // MARK: - Top 20 Companies Bar Chart

    /// Section displaying the top 20 companies by application frequency.
    private var top20CompaniesBarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top 20 Companies by Application Frequency")
                .font(.headline)

            if #available(macOS 13.0, *) {
                let topCompanies = buildTop20CompanyFreq()
                GeometryReader { geo in
                    Chart(topCompanies) { item in
                        BarMark(
                            x: .value("Company", item.name),
                            y: .value("Count", item.count)
                        )
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                    .frame(width: geo.size.width, height: 300)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 400)
                Spacer()
            } else {
                Text("Bar chart requires macOS 13.0+.")
            }
        }
    }

    // MARK: - Data and Helpers

    /// Builds the top 20 companies by application frequency.
    private func buildTop20CompanyFreq() -> [CompanyFreq] {
        var freq: [String: Int] = [:]
        for app in jobStore.jobApplications {
            freq[app.companyName, default: 0] += 1
        }
        let sorted = freq.sorted { $0.value > $1.value }
        let top20 = sorted.prefix(20)
        return top20.map { CompanyFreq(name: $0.key, count: $0.value) }
    }

    /// Computes city pins for the map based on job applications.
    private func computeCityPins() {
        var cityCounts: [String: Int] = [:]
        for job in jobStore.jobApplications {
            let cityKey = job.location.trimmingCharacters(in: .whitespacesAndNewlines)
            if cityKey.isEmpty { continue }
            cityCounts[cityKey, default: 0] += 1
        }
        var pins: [CityPin] = []
        for (city, count) in cityCounts {
            if let coordinate = CityCoordinateDictionary[city] {
                pins.append(CityPin(city: city, coordinate: coordinate, count: count))
            }
        }
        cityPins = pins
    }

    /// Computes year contribution data for GitHub-style charts.
    private func computeYearContribution() {
        let cal = Calendar.current
        let now = cal.startOfDay(for: Date())
        let year = cal.component(.year, from: now)
        guard let startOfYear = cal.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endOfYear = cal.date(from: DateComponents(year: year, month: 12, day: 31)) else {
            yearContributionData = []
            return
        }

        var dayCursor = startOfYear
        var allDays: [Contribution] = []

        while dayCursor <= endOfYear {
            if dayCursor <= now {
                allDays.append(Contribution(date: dayCursor, count: 1))
            } else {
                allDays.append(Contribution(date: dayCursor, count: 0))
            }
            if let nextDay = cal.date(byAdding: .day, value: 1, to: dayCursor) {
                dayCursor = nextDay
            } else {
                break
            }
        }
        yearContributionData = allDays
    }

    /// Computes applications contribution data for GitHub-style charts.
    private func computeAppsContribution() {
        let cal = Calendar.current
        let now = Date()
        let year = cal.component(.year, from: now)

        guard let startOfYear = cal.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endOfYear = cal.date(from: DateComponents(year: year, month: 12, day: 31)) else {
            appsContributionData = []
            return
        }

        var dateCount: [Date: Int] = [:]
        for job in jobStore.jobApplications {
            let day = cal.startOfDay(for: job.dateOfApplication)
            if day >= startOfYear && day <= endOfYear {
                dateCount[day, default: 0] += 1
            }
        }

        var results: [Contribution] = []
        var dayCursor = startOfYear

        while dayCursor <= endOfYear {
            results.append(Contribution(date: dayCursor, count: dateCount[dayCursor, default: 0]))
            if let nextDay = cal.date(byAdding: .day, value: 1, to: dayCursor) {
                dayCursor = nextDay
            } else {
                break
            }
        }
        appsContributionData = results
    }

    /// Computes data for bar and line charts based on the selected time range.
    private func computeBarLineData() {
        let cal = Calendar.current
        let now = Date()

        var startDate: Date
        switch selectedTimeRange {
        case .week:
            startDate = cal.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .month:
            startDate = cal.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            startDate = cal.date(byAdding: .year, value: -1, to: now) ?? now
        }

        let filteredApps = jobStore.jobApplications.filter { $0.dateOfApplication >= startDate && $0.dateOfApplication <= now }

        var dailyCounts: [DailyApps] = []
        var dayCursor = cal.startOfDay(for: startDate)

        while dayCursor <= now {
            let count = filteredApps.filter { cal.isDate($0.dateOfApplication, inSameDayAs: dayCursor) }.count
            dailyCounts.append(DailyApps(date: dayCursor, count: count))
            if let nextDay = cal.date(byAdding: .day, value: 1, to: dayCursor) {
                dayCursor = nextDay
            } else {
                break
            }
        }

        barLineData = dailyCounts
    }

    /// Returns the weekday as an integer for a given date.
    private func weekday(for date: Date) -> Int {
        let cal = Calendar.current
        return cal.component(.weekday, from: date)
    }

    /// Returns the short weekday symbol for a given integer.
    private func shortWeekdaySymbol(_ number: Int) -> String? {
        let cal = Calendar.current
        let symbols = cal.shortWeekdaySymbols
        if number >= 1 && number <= symbols.count {
            return symbols[number - 1]
        }
        return nil
    }

    /// Returns a list of colors for the charts.
    private var chartColors: [Color] {
        return [
            .green.opacity(0.3),
            .blue.opacity(0.3),
            .purple.opacity(0.3),
            .orange.opacity(0.3),
            .red.opacity(0.3)
        ]
    }

    /// Returns the top company name by application frequency.
    private func topCompanyName() -> String {
        var freq: [String: Int] = [:]
        for app in jobStore.jobApplications {
            freq[app.companyName, default: 0] += 1
        }
        let sorted = freq.sorted { $0.value > $1.value }
        return sorted.first?.key ?? "N/A"
    }
}

// MARK: - Top 20 Companies Bar Chart

/// Section displaying the top 20 companies by application frequency.
struct Top20CompaniesBarView: View {
    @EnvironmentObject var jobStore: JobStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top 20 Companies by Application Frequency")
                .font(.headline)

            if #available(macOS 13.0, *) {
                let topCompanies = buildTop20CompanyFreq()
                GeometryReader { geo in
                    Chart(topCompanies) { item in
                        BarMark(
                            x: .value("Company", item.name),
                            y: .value("Count", item.count)
                        )
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                    .frame(width: geo.size.width, height: 300)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 400)
                Spacer()
            } else {
                Text("Bar chart requires macOS 13.0+.")
            }
        }
    }

    /// Builds the top 20 companies by application frequency.
    private func buildTop20CompanyFreq() -> [CompanyFreq] {
        var freq: [String: Int] = [:]
        for app in jobStore.jobApplications {
            freq[app.companyName, default: 0] += 1
        }
        let sorted = freq.sorted { $0.value > $1.value }
        let top20 = sorted.prefix(20)
        return top20.map { CompanyFreq(name: $0.key, count: $0.value) }
    }
}

// MARK: - Supporting Extensions

extension View {
    /// Applies a linear gradient to the foreground of the view.
    func gradientForeground(colors: [Color]) -> some View {
        self.overlay(
            LinearGradient(
                gradient: Gradient(colors: colors),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .mask(self)
    }
}

