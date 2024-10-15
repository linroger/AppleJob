//
//  AppleJob.swift
//  A comprehensive, single-file SwiftUI-based macOS app.
//  Shows job applications, documents, categories, stats, embedded PDF, Quick Look, etc.
//
//  This file demonstrates:
//    - Models (JobApplication, JobDocument, DocumentCategory, etc.)
//    - Stores (JobStore, DocumentStore, etc.)
//    - SwiftUI Views for listing jobs & docs in a sidebar and showing details
//    - SwiftUI-based PDFKit usage
//    - Categories with drag-and-drop
//    - Stats with a map view, top city, top company, etc.
//    - Thorough code documentation for learning purposes.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers
import PDFKit
import MapKit
import Charts
import Quartz
import QuickLook
import QuickLookUI

// MARK: - Models

/// `JobStatus` enumerates the different states a job application can be in.
enum JobStatus: String, CaseIterable, Codable {
    case interested = "Interested"
    case applied = "Applied"
    case interview = "Interview"
    case offer = "Offer"
    case rejection = "Rejection"

    /// Provides a SwiftUI Color for each status, used in UI elements.
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

/// Sorting options for the list of job applications (title, company, etc.).
enum Sort: String, CaseIterable {
    case title = "Job Title"
    case company = "Company Name"
    case recentlyApplied = "Recently Applied"
}

/// The primary data model for a job application.
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

    /**
     Initializes a new `JobApplication`.

     - Parameters:
       - id: The UUID identifier. Defaults to a new UUID.
       - companyName: The company name (e.g., "Apple").
       - jobTitle: The job title (e.g., "iOS Developer").
       - status: A `JobStatus` such as `.applied`. Defaults to `.interested`.
       - dateOfApplication: The date the user applied. Defaults to current date.
       - location: The job's location (e.g., "New York, NY").
       - linkToJobString: A URL link string to the job posting, optional.
       - salary: Optional salary figure.
       - jobDescription: Text describing the job details.
       - coverLetter: The user's cover letter text.
       - notes: Any notes the user wants to keep about the job.
       - documents: An array of associated documents (`JobDocument`).
       - isFavorite: Whether the user has favorited this job.
     */
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

    // For decoding older versions that might have used a rawValue for status.
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
}

/// Represents a document uploaded by the user. Could be a resume, cover letter, or any file.
struct JobDocument: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var fileName: String
    var fileData: Data

    var dateOfApplication: Date
    var lastModifiedDate: Date
    var fileSize: Int
    var wordCount: Int
    var categoryID: UUID?  // Ties this document to an optional category.

    /// Creates a brand new `JobDocument` from raw file data.
    init(id: UUID = UUID(), fileName: String, fileData: Data) {
        self.id = id
        self.fileName = fileName
        self.fileData = fileData
        self.dateOfApplication = Date()
        self.lastModifiedDate = Date()
        self.fileSize = fileData.count
        self.wordCount = 0
        self.categoryID = nil
    }

    /// Decoding with support for older versions that might not have all fields.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.fileName = try container.decode(String.self, forKey: .fileName)
        self.fileData = try container.decode(Data.self, forKey: .fileData)
        self.dateOfApplication = try container.decodeIfPresent(Date.self, forKey: .dateOfApplication) ?? Date()
        self.lastModifiedDate = try container.decodeIfPresent(Date.self, forKey: .lastModifiedDate) ?? Date()
        self.fileSize = try container.decodeIfPresent(Int.self, forKey: .fileSize) ?? 0
        self.wordCount = try container.decodeIfPresent(Int.self, forKey: .wordCount) ?? 0
        self.categoryID = try container.decodeIfPresent(UUID.self, forKey: .categoryID)
    }
    enum CodingKeys: String, CodingKey {
        case id
        case fileName
        case fileData
        case dateOfApplication
        case lastModifiedDate
        case fileSize
        case wordCount
        case categoryID
    }
}

/// Represents a named category for grouping documents in the sidebar.
struct DocumentCategory: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var isExpanded: Bool = true

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

/// For stats: a data structure that shows a company’s name and the count of job apps for that company.
struct CompanyFreq: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
}

/// For stats: represents a city with coordinate location and number of job apps there.
struct CityPin: Identifiable {
    let id = UUID()
    let city: String
    let coordinate: CLLocationCoordinate2D
    let count: Int
}

/// A dictionary to help find lat/long for certain known city names.
fileprivate var CityCoordinateDictionary: [String: CLLocationCoordinate2D] = [
    "New York City, NY": CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
    "Los Angeles, CA":   CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
    "Chicago, IL":       CLLocationCoordinate2D(latitude: 41.8781, longitude: -87.6298),
    "Global":            CLLocationCoordinate2D(latitude: 34.149884, longitude: -118.056932)
    // ... (other entries omitted for brevity)
]

/// For GitHub-like charts, represents a date and a count of items (like job apps).
struct Contribution: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
}

/// For bar/line charts, represents how many apps were applied on a given day.
struct DailyApps: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

// MARK: - View Extensions

extension View {
    /**
     A convenience modifier that applies a linear gradient fill to the text.
     This is used for styling text with a gradient, giving it a more vivid look.

     - Parameter colors: Array of `Color`s to use in the gradient.
     - Returns: A modified `View` with gradient-based text coloring.
     */
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

// MARK: - Observable Objects (Stores)

/// Stores and manages the user’s job applications and current selection.
class JobStore: ObservableObject {
    /// The array of all job applications.
    @Published var jobApplications: [JobApplication] = []

    /// Tracks which job is currently selected in the sidebar.
    @Published var selectedJob: JobApplication? = nil

    /// Whether the user is adding a new job (controls a sheet).
    @Published var isAddingNewJob = false

    /// Whether the user is editing the currently selected job.
    @Published var isEditingJob = false

    /// The current sorting option for job applications.
    @Published var sorting: Sort = .recentlyApplied

    init() {
        // Attempt to load saved jobs from UserDefaults on startup.
        loadJobs()
    }

    /// Adds a new job application and saves the list.
    func addJob(_ job: JobApplication) {
        jobApplications.append(job)
        sortJobs(by: sorting)
        saveJobs()
    }

    /// Edits an existing job application (by ID) with updated info and saves.
    func editJob(with updatedJob: JobApplication) {
        if let index = jobApplications.firstIndex(where: { $0.id == updatedJob.id }) {
            jobApplications[index] = updatedJob
            sortJobs(by: sorting)
            saveJobs()
        }
    }

    /// Deletes a job application by ID and saves.
    func deleteJob(for id: UUID) {
        if let index = jobApplications.firstIndex(where: { $0.id == id }) {
            jobApplications.remove(at: index)
            if selectedJob?.id == id {
                selectedJob = nil
            }
            saveJobs()
        }
    }

    /// Duplicates an existing job application, with a new creation date.
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

    /// Updates the status (applied, interview, etc.) for a job, by ID.
    func updateJobStatus(_ id: UUID, to status: JobStatus) {
        if let index = jobApplications.firstIndex(where: { $0.id == id }) {
            jobApplications[index].status = status
            saveJobs()
        }
    }

    /// Toggles whether a job is a "favorite" (by ID).
    func toggleFavorite(for id: UUID) {
        if let index = jobApplications.firstIndex(where: { $0.id == id }) {
            jobApplications[index].isFavorite.toggle()
            saveJobs()
        }
    }

    /// Edits the notes field for a job (by ID).
    func editJobNotes(with notes: String, for id: UUID) {
        if let index = jobApplications.firstIndex(where: { $0.id == id }) {
            jobApplications[index].notes = notes.isEmpty ? nil : notes
            saveJobs()
        }
    }

    /// Sort the jobApplications array by the user’s chosen sorting method.
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

    /// Saves the current array of jobs to UserDefaults (as JSON).
    func saveJobs() {
        do {
            let data = try JSONEncoder().encode(jobApplications)
            UserDefaults.standard.set(data, forKey: "jobs")
        } catch {
            print("Failed to save jobs: \(error.localizedDescription)")
        }
    }

    /// Attempts to load any previously saved jobs from UserDefaults.
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

    /**
     Imports a backup from a JSON file at the given URL.
     Overwrites the entire list of job applications if successful.
     */
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

    /**
     Exports the current job list as JSON to the given URL.
     */
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

/// Manages the user's uploaded documents, categories, and currently selected doc.
class DocumentStore: ObservableObject {
    @Published var documents: [JobDocument] = []
    @Published var selectedDocument: JobDocument? = nil

    // Categories for grouping documents in the sidebar.
    @Published var categories: [DocumentCategory] = []

    // Track a sheet for creating a new category.
    @Published var isCreatingNewCategory = false
    @Published var newCategoryName: String = "Category Name"

    // For Quick Look previews in the detail or stats view.
    @Published var quickLookURL: URL? = nil

    init() {
        loadDocuments()
        loadCategories()
    }

    /// Uploads documents from a set of file URLs. Stores them in memory.
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

    /// Downloads the currently selected document to a location the user chooses.
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

    /// Duplicates the given document in memory.
    func duplicateDocument(_ document: JobDocument) {
        var newDoc = JobDocument(
            fileName: "\(document.fileName)-copy",
            fileData: document.fileData
        )
        newDoc.categoryID = document.categoryID
        documents.append(newDoc)
        saveDocuments()
    }

    /// Deletes the given document from memory.
    func deleteDocument(_ document: JobDocument) {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents.remove(at: index)
        }
        if selectedDocument?.id == document.id {
            selectedDocument = nil
        }
        saveDocuments()
    }

    /// Merges a set of new docs into the store, avoiding duplicates.
    func mergeDocuments(_ newDocs: [JobDocument]) {
        for doc in newDocs {
            if !documents.contains(doc) {
                documents.append(doc)
            }
        }
        saveDocuments()
    }

    /// Saves the documents array to UserDefaults (as JSON).
    func saveDocuments() {
        do {
            let data = try JSONEncoder().encode(documents)
            UserDefaults.standard.set(data, forKey: "documents")
        } catch {
            print("Failed to save documents: \(error.localizedDescription)")
        }
    }

    /// Loads documents from UserDefaults if available.
    func loadDocuments() {
        guard let savedData = UserDefaults.standard.data(forKey: "documents") else { return }
        do {
            let loadedDocs = try JSONDecoder().decode([JobDocument].self, from: savedData)
            documents = loadedDocs
        } catch {
            print("Failed to load documents: \(error.localizedDescription)")
        }
    }

    // MARK: - Categories

    /// Saves the categories array to UserDefaults.
    func saveCategories() {
        do {
            let data = try JSONEncoder().encode(categories)
            UserDefaults.standard.set(data, forKey: "documentCategories")
        } catch {
            print("Failed to save categories: \(error.localizedDescription)")
        }
    }

    /// Loads categories from UserDefaults if present.
    func loadCategories() {
        guard let savedData = UserDefaults.standard.data(forKey: "documentCategories") else { return }
        do {
            let loaded = try JSONDecoder().decode([DocumentCategory].self, from: savedData)
            categories = loaded
        } catch {
            print("Failed to load categories: \(error.localizedDescription)")
        }
    }

    /// Creates a new document category with the given name.
    func createNewCategory(name: String) {
        guard !name.isEmpty else { return }
        let newCat = DocumentCategory(name: name)
        categories.append(newCat)
        saveCategories()
    }

    /// Assigns the specified document to the specified category.
    func assignDocument(_ doc: JobDocument, to category: DocumentCategory) {
        if let idx = documents.firstIndex(where: { $0.id == doc.id }) {
            documents[idx].categoryID = category.id
            saveDocuments()
        }
    }

    /// Removes the category assignment from a document, making it uncategorized.
    func unassignDocument(_ doc: JobDocument) {
        if let idx = documents.firstIndex(where: { $0.id == doc.id }) {
            documents[idx].categoryID = nil
            saveDocuments()
        }
    }
}

/// Provides file import/export options for backups and documents.
@MainActor
class ImportExportHelper: NSObject, ObservableObject {
    @Published var isImporting = false
    @Published var isExporting = false

    /// Opens a panel to import a JSON backup of jobs.
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

    /// Opens a panel to export the jobs as a JSON file.
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

    /// Opens a panel to import multiple documents (PDF, text, images, etc.).
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

    /// Opens a panel to export documents, presumably as a .zip file.
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

// MARK: - View Model for Creating/Editing Jobs

/**
 A view model that backs the `AddJobView` and `EditJobView`,
 providing fields for the job's data plus validation logic.
 */
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

    /// Basic init for a brand-new job.
    init() {
        validateInputs()
    }

    /// Init from an existing `JobApplication`.
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

    /// Checks whether required fields (companyName, jobTitle) are non-empty.
    func validateInputs() {
        DispatchQueue.main.async {
            self.isInputValid = !(self.companyName.isEmpty || self.jobTitle.isEmpty)
        }
    }

    /// Creates and adds a new job to the store, given an array of documents.
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

    /// Resets the VM fields after saving or if user cancels.
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

// MARK: - Main App Entry

/**
 The main app struct, which SwiftUI uses to launch the macOS application.
 */
@main
struct AppleJobApp: App {
    @StateObject private var jobStore = JobStore()
    @StateObject private var docStore = DocumentStore()
    @StateObject private var importExportHelper = ImportExportHelper()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Provide these objects to child views down the hierarchy via SwiftUI's environment
                .environmentObject(jobStore)
                .environmentObject(docStore)
                .environmentObject(importExportHelper)
        }
        .commands {
            fileMenuCommands
            editMenuCommands
        }
    }

    // MARK: File Menu

    /// Commands for the "File" menu (import/export, etc.).
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

    // MARK: Edit Menu

    /// Commands for the "Edit" menu (new job, edit job, duplicate, etc.).
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

            Divider()

            // Create category from Edit menu
            Button("Create New Category") {
                docStore.newCategoryName = "Category Name"
                docStore.isCreatingNewCategory = true
            }
        }
    }

    // MARK: Export Helper

    /**
     Exports all documents in `docStore` as a ZIP archive to the user’s chosen URL.
     Uses the `Process` class to call the `/usr/bin/zip` command-line tool on macOS.
     */
    private func exportAllDocumentsToZip(url: URL) {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("temp_documents_\(UUID())")

        do {
            // Create a temporary directory
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

            // Write each doc's data to a file in the temp dir
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

    /**
     Uses the `/usr/bin/zip` command to recursively zip files in a directory.
     */
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

// MARK: - ContentView

/**
 A top-level content view with a sidebar for navigation (jobs, stats, documents)
 and a main content area that changes based on the selected section.
 */
struct ContentView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @EnvironmentObject var importExportHelper: ImportExportHelper

    /// The user's selected section (Jobs, Stats, or Documents).
    @State private var selectedSection: ViewSection = .jobDetails

    /// The text used for searching in the job list sidebar.
    @State private var searchText: String = ""

    /// Tracks dark mode on/off. We manually toggle it in the toolbar button.
    @State private var isDarkMode: Bool = false

    /// For showing a popover with document info in the documents section.
    @State private var showDocInfoPopover = false

    var body: some View {
        NavigationView {
            // The left panel (sidebar).
            sidebar
                .frame(minWidth: 250)
                .background(
                    Color.black.opacity(0.03)
                        .blur(radius: 5)
                )

            // The right panel (main content).
            mainContent
        }
        // Force dark or light mode depending on `isDarkMode`
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .toolbar {
            ToolbarItemGroup {
                // A segmented picker to choose which main section we show.
                Picker("View Section", selection: $selectedSection) {
                    ForEach(ViewSection.allCases, id: \.self) { section in
                        Text(section.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)

                Spacer()

                // If we are in the Documents section, show doc-related toolbar items
                if selectedSection == .documents {
                    // Button to upload new documents
                    Button {
                        let openPanel = NSOpenPanel()
                        openPanel.allowedContentTypes = [.pdf, .image, .plainText, .rtf]
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

                    // Button to download the selected document
                    Button {
                        docStore.downloadSelectedDocument()
                    } label: {
                        Label("Download", systemImage: "square.and.arrow.down")
                    }

                    // Button to show a small popover about the doc
                    Button {
                        showDocInfoPopover.toggle()
                    } label: {
                        Label("Info", systemImage: "info.circle")
                    }
                    .popover(isPresented: $showDocInfoPopover) {
                        DocumentInfoPopover(document: docStore.selectedDocument)
                    }
                }

                // A button to toggle between dark and light mode
                Button {
                    isDarkMode.toggle()
                } label: {
                    Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                }
            }
        }
    }

    /// The left-hand sidebar content, which depends on the selected section.
    @ViewBuilder
    private var sidebar: some View {
        switch selectedSection {
        case .jobDetails, .stats:
            // If in jobDetails or stats, we show the JobSidebarView plus a search bar.
            JobSidebarView(searchText: $searchText)
        case .documents:
            // If in documents, show the DocumentsSidebarView.
            DocumentsSidebarView()
        }
    }

    /// The main content area, changing based on which section is selected.
    @ViewBuilder
    private var mainContent: some View {
        switch selectedSection {
        case .jobDetails:
            if let job = jobStore.selectedJob {
                // If a job is selected, show its detail panel
                JobDetailView(job: job)
            } else {
                // Otherwise, show a placeholder.
                Text("Select a job to view details")
                    .foregroundColor(.secondary)
            }
        case .stats:
            // Show the EnhancedStatsView
            EnhancedStatsView()
        case .documents:
            // Show the main documents view (embedded PDF if selected doc).
            DocumentsMainView()
        }
    }
}

/// Lists all possible sections in the app: Job Details, Stats, Documents.
enum ViewSection: String, CaseIterable {
    case jobDetails = "Job Details"
    case stats = "Stats"
    case documents = "Documents"
}

// MARK: - Document Info Popover

/**
 A small popover that shows info about the selected document’s metadata (name, size, etc.).
 */
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

// MARK: - JobSidebarView

/**
 A sidebar list for job applications, supporting search, add, edit, and delete.
 */
struct JobSidebarView: View {
    @EnvironmentObject var jobStore: JobStore

    /// A binding to the text the user types in the search bar.
    @Binding var searchText: String

    var body: some View {
        List(selection: $jobStore.selectedJob) {
            ForEach(filteredJobs, id: \.id) { job in
                SidebarItemView(
                    job: job,
                    isSelected: Binding(
                        get: { jobStore.selectedJob == job },
                        set: { newValue in
                            if newValue {
                                jobStore.selectedJob = job
                            } else if jobStore.selectedJob == job {
                                jobStore.selectedJob = nil
                            }
                        }
                    )
                )
                .tag(job)
            }
            .onDelete(perform: deleteJobs)
        }
        .listStyle(SidebarListStyle())
        .searchable(text: $searchText)
        .navigationTitle("Applications")
        .toolbar {
            // A toolbar button to add a new job (opens a sheet).
            ToolbarItem(placement: .navigation) {
                Button {
                    jobStore.isAddingNewJob = true
                } label: {
                    Label("New", systemImage: "plus")
                }
            }
        }
        // A sheet to add a new job
        .sheet(isPresented: $jobStore.isAddingNewJob) {
            AddJobView(isPresented: $jobStore.isAddingNewJob)
                .environmentObject(jobStore)
                .environmentObject(DocumentStore())
        }
        // Another sheet to edit the currently selected job
        .sheet(isPresented: $jobStore.isEditingJob) {
            if let job = jobStore.selectedJob {
                EditJobView(isPresented: $jobStore.isEditingJob, job: job)
                    .environmentObject(jobStore)
                    .environmentObject(DocumentStore())
            }
        }
    }

    /// Filters the job list according to the user’s search text (company name, job title, location).
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

    /// Allows deletion of multiple selected jobs.
    private func deleteJobs(at offsets: IndexSet) {
        for index in offsets {
            let job = filteredJobs[index]
            jobStore.deleteJob(for: job.id)
        }
    }
}

/**
 A single row in the job sidebar listing, showing company name, job title, and status badge.
 */
struct SidebarItemView: View {
    @EnvironmentObject var jobStore: JobStore
    let job: JobApplication
    @Binding var isSelected: Bool

    var body: some View {
        HStack {
            // Show company name and job title
            VStack(alignment: .leading) {
                Text(job.companyName)
                    .font(.headline)
                Text(job.jobTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()

            // Show a small badge with the job status
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
            // Various context menu items: Edit, Duplicate, Update Status, etc.
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
                    Button {
                        jobStore.updateJobStatus(job.id, to: status)
                    } label: {
                        Text(status.rawValue)
                    }
                }
            }
            Divider()
            Button {
                jobStore.toggleFavorite(for: job.id)
            } label: {
                Label(job.isFavorite ? "Remove from Favorites" : "Add to Favorites", systemImage: job.isFavorite ? "heart.fill" : "heart")
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
        // Tapping the row toggles selection
        .onTapGesture {
            isSelected.toggle()
        }
    }
}

// MARK: - DocumentsSidebarView

/**
 The sidebar for managing documents, showing an “All Documents” section plus categories.
 Drag-and-drop is supported for reassigning docs to categories.
 */
struct DocumentsSidebarView: View {
    @EnvironmentObject var docStore: DocumentStore
    @State private var isShowingContextMenu = false

    var body: some View {
        List(selection: $docStore.selectedDocument) {
            // First section: “All Documents” (uncategorized)
            Section {
                DisclosureGroup("All Documents") {
                    ForEach(uncategorizedDocuments, id: \.id) { doc in
                        documentSidebarItem(doc)
                    }
                    // If you want to allow reordering
                    .onMove(perform: moveDocsInAllDocs)
                }
                .font(.headline)
                .foregroundColor(.primary)
            }

            // Then show each category
            ForEach($docStore.categories, id: \.id) { $category in
                DisclosureGroup(isExpanded: $category.isExpanded) {
                    ForEach(docsForCategory(category.id), id: \.id) { doc in
                        documentSidebarItem(doc)
                    }
                    .onMove { indices, newOffset in
                        // Reorder logic if needed
                    }
                } label: {
                    Text(category.name)
                        .font(.headline)
                }
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Documents")
        .toolbar {
            // A toolbar button to create a new category
            ToolbarItem(placement: .navigation) {
                Button {
                    docStore.newCategoryName = "Category Name"
                    docStore.isCreatingNewCategory = true
                } label: {
                    Label("New Category", systemImage: "folder.badge.plus")
                }
            }
        }
        // Context menu for blank areas
        .contextMenu {
            Button("Create New Category") {
                docStore.newCategoryName = "Category Name"
                docStore.isCreatingNewCategory = true
            }
        }
        // A sheet to actually name and create the category
        .sheet(isPresented: $docStore.isCreatingNewCategory) {
            NewCategorySheet()
                .environmentObject(docStore)
        }
        // For Quick Look usage in the docs
        .quickLookPreview($docStore.quickLookURL)
    }

    /// The list of documents that are uncategorized (no categoryID).
    private var uncategorizedDocuments: [JobDocument] {
        docStore.documents.filter { $0.categoryID == nil }
    }

    /// Returns all docs that match a given category ID.
    private func docsForCategory(_ catID: UUID) -> [JobDocument] {
        docStore.documents.filter { $0.categoryID == catID }
    }

    /// For each doc in the sidebar, show a single row with the doc’s cleaned name.
    private func documentSidebarItem(_ doc: JobDocument) -> some View {
        HStack {
            Text(cleanFileName(doc.fileName))
                .lineLimit(1)
            Spacer()
        }
        .contentShape(Rectangle())
        .contextMenu {
            // Context menu for doc operations: download, duplicate, remove from category, etc.
            Button("Download") {
                docStore.selectedDocument = doc
                docStore.downloadSelectedDocument()
            }
            Button("Duplicate") {
                docStore.duplicateDocument(doc)
            }
            Button("Remove from Category") {
                docStore.unassignDocument(doc)
            }
            Divider()
            Button(role: .destructive) {
                docStore.deleteDocument(doc)
            } label: {
                Text("Delete")
            }
        }
        // Tapping sets the doc as selected
        .onTapGesture {
            docStore.selectedDocument = doc
        }
        // Providing a drag item for drag-and-drop
        .onDrag {
            return NSItemProvider(object: doc.id.uuidString as NSString)
        }
        // Handling dropping *onto* this doc to reassign categories
        .onDrop(of: [.text], delegate: DocumentDropDelegate(docStore: docStore, targetCategoryID: doc.categoryID, document: doc))
    }

    /// Called when user reorders docs in “All Documents.” Implementation is optional.
    private func moveDocsInAllDocs(from source: IndexSet, to destination: Int) {
        // For demonstration, do nothing or reorder if you prefer
    }

    /// Strips known phrases and file extensions from doc filenames for display.
    private func cleanFileName(_ filename: String) -> String {
        var cleanedName = filename
        let stringsToRemove = ["Roger Lin", "Position", "2024", "Cover Letter"]
        for stringToRemove in stringsToRemove {
            cleanedName = cleanedName.replacingOccurrences(of: stringToRemove, with: "")
        }
        cleanedName = cleanedName.trimmingCharacters(in: .whitespaces)
        let fileExtensionsToRemove = [".pdf", ".docx", ".pages"]
        for fileExtension in fileExtensionsToRemove {
            if cleanedName.hasSuffix(fileExtension) {
                cleanedName = String(cleanedName.dropLast(fileExtension.count))
                break
            }
        }
        return cleanedName
    }
}

/// A custom `DropDelegate` for reassigning docs to categories when dropping them.
struct DocumentDropDelegate: DropDelegate {
    let docStore: DocumentStore
    let targetCategoryID: UUID?
    let document: JobDocument

    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: [.text])
    }
    func dropEntered(info: DropInfo) { }

    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.text]).first else {
            return false
        }
        itemProvider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { data, error in
            guard let uuidString = data as? String, let docID = UUID(uuidString: uuidString) else { return }
            DispatchQueue.main.async {
                if let doc = docStore.documents.first(where: { $0.id == docID }) {
                    // If dropping onto a doc with categoryID X => interpret as "assign doc to category X".
                    if let catID = targetCategoryID {
                        docStore.assignDocument(doc, to: DocumentCategory(id: catID, name: ""))
                    } else {
                        // If dropping onto an uncategorized doc, remove doc's category assignment
                        docStore.unassignDocument(doc)
                    }
                }
            }
        }
        return true
    }
}

// MARK: - NewCategorySheet

/**
 A sheet that allows the user to type a name for a new document category.
 */
struct NewCategorySheet: View {
    @EnvironmentObject var docStore: DocumentStore
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            TextField("Category Name", text: $docStore.newCategoryName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            HStack {
                Button("Cancel", role: .cancel) {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Spacer()

                Button("Save") {
                    docStore.createNewCategory(name: docStore.newCategoryName)
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            .padding()
        }
        .frame(width: 300, height: 150)
        .padding()
    }
}

// MARK: - DocumentsMainView

/**
 The main content view for the Documents section.
 If no docs exist, shows an "Upload" button.
 If a doc is selected, shows an embedded PDFKit view plus a "Preview Document" button that triggers QuickLook.
 */
struct DocumentsMainView: View {
    @EnvironmentObject var docStore: DocumentStore

    /// For QuickLook previews specifically in this view.
    @State private var quickLookURL: URL? = nil

    var body: some View {
        ZStack {
            if docStore.documents.isEmpty {
                // If no documents exist at all
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
                // If a doc is selected, show a PDFKit view plus a QuickLook button
                VStack {
                    // This button triggers a QuickLook popup, if the user wants it
                    Button("Preview Document") {
                        openQuickLook(doc)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()

                    // Show a PDFKit scroller with the doc's content
                    PDFKitRepresentedView(fileData: doc.fileData)
                }
            } else {
                // If we have docs, but none is selected
                Text("Select a document to view.")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        // Provide a QuickLook preview environment (like in the job detail)
        .quickLookPreview($quickLookURL)
    }

    /// Presents a file-open panel for uploading documents from the local disk.
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

    /// Opens a QuickLook preview by writing the doc data to a temp file.
    private func openQuickLook(_ doc: JobDocument) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(doc.fileName)
        do {
            try doc.fileData.write(to: tempURL)
            quickLookURL = tempURL
        } catch {
            print("Failed to open Quick Look: \(error)")
        }
    }
}

/**
 A SwiftUI representable that embeds a PDFView inside an NSScrollView, used to show PDF documents on macOS.
 */
struct PDFKitRepresentedView: NSViewRepresentable {
    let fileData: Data

    /// Create and return an NSScrollView containing a PDFView that displays `fileData`.
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

    /// When the data changes, update the PDFView's document accordingly.
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let pdfView = nsView.documentView as? PDFView {
            let newDoc = PDFDocument(data: fileData)
            if pdfView.document != newDoc {
                pdfView.document = newDoc
            }
        }
    }
}

// MARK: - JobDetailView

/**
 The main detail view for a selected job, showing company info, status, location, documents, etc.
 Also supports QuickLook preview for documents, but used in a horizontal scroll of doc buttons.
 */
struct JobDetailView: View {
    @EnvironmentObject var jobStore: JobStore
    let job: JobApplication

    /// For QuickLook preview of documents from the job detail.
    @State private var quickLookURL: URL? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Company + Title
                Text(job.companyName)
                    .font(.largeTitle)
                    .bold()
                Text(job.jobTitle)
                    .font(.title2)

                // Status row
                HStack {
                    Text("Status: ")
                        .bold()
                    Text(job.status.rawValue)
                        .foregroundColor(job.status.displayColor)
                }

                // Link to job if provided
                if let link = job.linkToJobString, let url = URL(string: link) {
                    Link("View Job Posting", destination: url)
                }

                // Show the job’s location
                if !job.location.isEmpty {
                    Text("Location: \(job.location)")
                        .font(.headline)
                }

                // Show the application date
                Text("Applied on: \(job.dateOfApplication.formatted(date: .abbreviated, time: .omitted))")

                // If the job has associated documents, show them in a horizontal scroller
                if !job.documents.isEmpty {
                    Divider()
                    Text("Documents")
                        .font(.headline)
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(job.documents, id: \.id) { doc in
                                // Button to open doc in QuickLook
                                Button(action: {
                                    openQuickLook(doc)
                                }) {
                                    HStack {
                                        Image(systemName: "doc.text")
                                            .foregroundColor(.primary)
                                        Text(cleanFileName(doc.fileName))
                                            .gradientForeground(colors: [.blue, .purple])
                                    }
                                }
                            }
                        }
                    }
                }

                // Job description if available
                if !job.jobDescription.isEmpty {
                    Divider()
                    Text("Job Description")
                        .font(.headline)
                    Text(job.jobDescription)
                        .padding(4)
                }

                // Cover letter if available
                if !job.coverLetter.isEmpty {
                    Divider()
                    Text("Cover Letter")
                        .font(.headline)
                    Text(job.coverLetter)
                }

                // Notes
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
        // A small toolbar with Edit and Favorite toggles
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
        // QuickLook preview environment for doc items
        .quickLookPreview($quickLookURL)
    }

    /// Removes certain known phrases and file extensions to prettify displayed names.
    private func cleanFileName(_ filename: String) -> String {
        var cleanedName = filename
        let stringsToRemove = ["Roger Lin", "Position", "2024", "Cover Letter"]
        for stringToRemove in stringsToRemove {
            cleanedName = cleanedName.replacingOccurrences(of: stringToRemove, with: "")
        }
        cleanedName = cleanedName.trimmingCharacters(in: .whitespaces)
        let fileExtensionsToRemove = [".pdf", ".docx", ".pages"]
        for fileExtension in fileExtensionsToRemove {
            if cleanedName.hasSuffix(fileExtension) {
                cleanedName = String(cleanedName.dropLast(fileExtension.count))
                break
            }
        }
        return cleanedName
    }

    /// Writes doc data to a temp file, then sets the QuickLook URL.
    private func openQuickLook(_ doc: JobDocument) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(doc.fileName)
        do {
            try doc.fileData.write(to: tempURL)
            quickLookURL = tempURL
        } catch {
            print("Failed to open quicklook: \(error)")
        }
    }
}

// MARK: - AddJobView

/**
 A sheet that appears to create a new job (JobApplication).
 */
struct AddJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore

    /// Whether this sheet is presented or not (two-way binding).
    @Binding var isPresented: Bool

    /// A dedicated view model to handle the job’s fields and validation.
    @StateObject private var viewModel = JobViewModel()

    /// Documents uploaded specifically during job creation.
    @State private var importedDocuments: [JobDocument] = []

    /// Whether we’re currently showing a FileImporter for doc upload.
    @State private var isImporting = false

    /// All known location strings from existing jobs, used in a Picker for location.
    @State private var locations: [String] = []

    /// Whether we’re showing a “Add New Location” mini-sheet.
    @State private var showAddLocationSheet = false

    /// For QuickLook preview of newly imported docs (optional).
    @State private var quickLookURL: URL? = nil

    var body: some View {
        VStack {
            Text("Add New Job")
                .font(.title2)
                .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("JOB DETAILS")
                    // Company Name
                    TextField("Company Name", text: $viewModel.companyName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        // On macOS 14, Apple changed onChange. For older OS, it's fine as is.
                        .onChange(of: viewModel.companyName) { _ in
                            viewModel.validateInputs()
                        }

                    // Job Title
                    TextField("Job Title", text: $viewModel.jobTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: viewModel.jobTitle) { _ in
                            viewModel.validateInputs()
                        }

                    sectionHeader("APPLICATION DETAILS")
                    // Link to job
                    TextField("Link to Job", text: $viewModel.linkToJob)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    // Job Status
                    Picker("Status", selection: $viewModel.status) {
                        ForEach(JobStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }

                    // Location
                    Picker("Location", selection: $viewModel.location) {
                        ForEach(locations, id: \.self) { location in
                            Text(location)
                        }
                        Text("Add New Location").tag("Add New Location")
                    }
                    // If user picks "Add New Location," show a location-creation sheet
                    .onChange(of: viewModel.location) { _, newValue in
                        if newValue == "Add New Location" {
                            viewModel.location = ""
                            showAddLocationSheet = true
                        }
                    }

                    // DatePicker for the date of application
                    DatePicker("Application Date", selection: $viewModel.dateOfApplication, displayedComponents: .date)

                    sectionHeader("DOCUMENTS")
                    // If user has imported docs, show them in a horizontal scroller
                    if !importedDocuments.isEmpty {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(importedDocuments, id: \.id) { doc in
                                    Button(action: {
                                        openQuickLook(doc)
                                    }) {
                                        HStack {
                                            Image(systemName: "doc.text")
                                                .foregroundColor(.primary)
                                            Text(cleanFileName(doc.fileName))
                                                .gradientForeground(colors: [.blue, .purple])
                                        }
                                        .padding(8)
                                    }
                                    .buttonStyle(.bordered)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                    // A button to upload more documents
                    Button("Upload Documents") {
                        isImporting = true
                    }

                    // Job Description
                    sectionHeader("JOB DESCRIPTION")
                    TextEditor(text: $viewModel.jobDescription)
                        .font(.body)
                        .frame(minHeight: 80)
                        .cornerRadius(5)

                    // Cover Letter
                    sectionHeader("COVER LETTER")
                    TextEditor(text: $viewModel.coverLetter)
                        .font(.body)
                        .frame(minHeight: 80)
                        .cornerRadius(5)

                    // Notes
                    sectionHeader("NOTES")
                    TextEditor(text: $viewModel.notes)
                        .font(.body)
                        .frame(minHeight: 80)
                        .cornerRadius(5)
                }
                .padding()
            }

            // The bottom bar with Cancel and Save
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
                    // Validate, then create the job with merged documents
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
        // A fileImporter for uploading multiple docs
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
        // If user wants to add a new location
        .sheet(isPresented: $showAddLocationSheet) {
            NewLocationView(
                locations: $locations,
                selectedLocation: $viewModel.location,
                isPresented: $showAddLocationSheet
            )
        }
        // On appear, gather a set of known locations from existing jobs
        .onAppear {
            locations = Array(Set(jobStore.jobApplications.map { $0.location })).sorted()
        }
        // Provide QuickLook preview for newly added docs
        .quickLookPreview($quickLookURL)
    }

    /// Writes the doc data to a temp file and triggers QuickLook.
    private func openQuickLook(_ doc: JobDocument) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(doc.fileName)
        do {
            try doc.fileData.write(to: tempURL)
            quickLookURL = tempURL
        } catch {
            print("Failed to open Quick Look: \(error)")
        }
    }

    /// Strips known phrases and file extensions from doc filenames for display.
    private func cleanFileName(_ filename: String) -> String {
        var cleanedName = filename
        let stringsToRemove = ["Roger Lin", "Position", "2024", "Cover Letter"]
        for stringToRemove in stringsToRemove {
            cleanedName = cleanedName.replacingOccurrences(of: stringToRemove, with: "")
        }
        cleanedName = cleanedName.trimmingCharacters(in: .whitespaces)
        let fileExtensionsToRemove = [".pdf", ".docx", ".pages"]
        for fileExtension in fileExtensionsToRemove {
            if cleanedName.hasSuffix(fileExtension) {
                cleanedName = String(cleanedName.dropLast(fileExtension.count))
                break
            }
        }
        return cleanedName
    }

    /// A helper for drawing section headers in the form, e.g. "JOB DETAILS".
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .textCase(.uppercase)
    }
}

// MARK: - EditJobView

/**
 A sheet that appears to edit an existing job.
 Similar to AddJobView but initialized with an existing `JobApplication`.
 */
struct EditJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore

    /// Whether this sheet is shown.
    @Binding var isPresented: Bool

    /// A specialized view model with the job's existing data.
    @StateObject private var viewModel: JobViewModel

    /// Documents that we have imported specifically for this job.
    @State private var importedDocuments: [JobDocument] = []

    /// Whether the user is currently picking documents from the filesystem.
    @State private var isImporting = false

    /// A list of known locations from all jobs, used in a location picker.
    @State private var locations: [String] = []

    /// If user wants to add a brand-new location
    @State private var showAddLocationSheet = false

    /// For QuickLook preview of newly imported docs while editing
    @State private var quickLookURL: URL? = nil

    /**
     Custom init that takes the job to edit, sets up a JobViewModel from that job,
     and pre-populates `importedDocuments` with the job’s existing docs.
     */
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
                    // The same fields as in AddJobView, but pre-filled with job data
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
                    // If docs exist, show them in a horizontal scroller
                    if !importedDocuments.isEmpty {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(importedDocuments, id: \.id) { doc in
                                    Button(action: {
                                        openQuickLook(doc)
                                    }) {
                                        HStack {
                                            Image(systemName: "doc.text")
                                                .foregroundColor(.primary)
                                            Text(cleanFileName(doc.fileName))
                                                .gradientForeground(colors: [.blue, .purple])
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }

                    Button("Upload Documents") {
                        isImporting = true
                    }

                    // Job Description
                    sectionHeader("JOB DESCRIPTION")
                    TextEditor(text: $viewModel.jobDescription)
                        .font(.body)
                        .frame(minHeight: 80)
                        .cornerRadius(5)

                    // Cover Letter
                    sectionHeader("COVER LETTER")
                    TextEditor(text: $viewModel.coverLetter)
                        .font(.body)
                        .frame(minHeight: 80)
                        .cornerRadius(5)

                    // Notes
                    sectionHeader("NOTES")
                    TextEditor(text: $viewModel.notes)
                        .font(.body)
                        .frame(minHeight: 80)
                        .cornerRadius(5)
                }
                .padding()
            }

            // Bottom bar with Cancel / Save
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
        // Load known location strings
        .onAppear {
            locations = Array(Set(jobStore.jobApplications.map { $0.location })).sorted()
        }
        // QuickLook for newly imported docs
        .quickLookPreview($quickLookURL)
    }

    /// Called when user taps "Save," merges new docs, updates the job in the store.
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

    /// Writes doc data to a temp file, triggers QuickLook on that file.
    private func openQuickLook(_ doc: JobDocument) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(doc.fileName)
        do {
            try doc.fileData.write(to: tempURL)
            quickLookURL = tempURL
        } catch {
            print("Failed to open Quick Look: \(error)")
        }
    }

    /// Strips known phrases and file extensions from doc filenames for display.
    private func cleanFileName(_ filename: String) -> String {
        var cleanedName = filename
        let stringsToRemove = ["Roger Lin", "Position", "2024", "Cover Letter"]
        for stringToRemove in stringsToRemove {
            cleanedName = cleanedName.replacingOccurrences(of: stringToRemove, with: "")
        }
        cleanedName = cleanedName.trimmingCharacters(in: .whitespaces)
        let fileExtensionsToRemove = [".pdf", ".docx", ".pages"]
        for fileExtension in fileExtensionsToRemove {
            if cleanedName.hasSuffix(fileExtension) {
                cleanedName = String(cleanedName.dropLast(fileExtension.count))
                break
            }
        }
        return cleanedName
    }

    /// A convenience method for section headers.
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .textCase(.uppercase)
    }
}

// MARK: - NewLocationView

/**
 A small sheet that allows users to add a brand-new location by specifying name, latitude, and longitude.
 */
struct NewLocationView: View {
    /// The list of known locations. We'll append the new one to this list if valid.
    @Binding var locations: [String]
    /// The currently selected location in the parent view. We'll update this if the user adds a new one.
    @Binding var selectedLocation: String
    /// Whether this sheet is shown.
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

                    // Also store the lat/long in CityCoordinateDictionary for the map
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

// MARK: - EnhancedStatsView

/**
 Displays various stats about the job applications, including:
 - A map with city pins
 - Basic counts (total apps, applied, interested, top city, top company)
 - GitHub-like charts
 - Horizontal scroll containers for city/company frequency
 */
struct EnhancedStatsView: View {
    @EnvironmentObject var jobStore: JobStore

    /// A region for the map to focus on initially.
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 50)
    )

    /// A list of city pins, each with a city name, coordinate, and count.
    @State private var cityPins: [CityPin] = []

    /// For GitHub-like charts
    @State private var yearContributionData: [Contribution] = []
    @State private var appsContributionData: [Contribution] = []

    /// For bar/line charts, we define a time range and data accordingly.
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
                citiesByFrequencySection
                companiesByFrequencySection
            }
            .padding()
        }
        .onAppear {
            // Compute data once the view appears
            computeCityPins()
            computeYearContribution()
            computeAppsContribution()
            computeBarLineData()
        }
        .navigationTitle("Stats & Analytics")
    }

    // MARK: - Map Section
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Applications Map")
                .font(.headline)

            // The old approach, for macOS < 14. If you want the new approach, see code examples in prior messages.
            Map(coordinateRegion: $region,
                annotationItems: cityPins) { cityPin in
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

    // MARK: - Stats Row
    private var statsRowSection: some View {
        let totalApps = jobStore.jobApplications.count
        let appliedCount = jobStore.jobApplications.filter { $0.status == .applied }.count
        let interestedCount = jobStore.jobApplications.filter { $0.status == .interested }.count
        let distinctCities = Set(jobStore.jobApplications.map { $0.location }).count
        let topCompany = topCompanyName()
        let topCityData = topCity()
        let gradient = LinearGradient(colors: [.blue, .pink], startPoint: .leading, endPoint: .trailing)

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 32) {
                VStack {
                    Text("Total Apps")
                    Text("\(totalApps)")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(gradient)
                }
                VStack {
                    Text("Applied")
                    Text("\(appliedCount)")
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
                VStack {
                    Text("Top City" )
                    // Show city name and count on the same line or different lines, as desired
                    Text("\(topCityData.name)")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(gradient)
                    Text("\(topCityData.count)")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(gradient)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - GitHub Charts
    private var githubChartsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("GitHub-Style Contribution Charts")
                .font(.headline)
            if #available(macOS 13.0, *) {
                // A chart that draws a rectangular grid for each day of the year
                Chart(yearContributionData) { item in
                    RectangleMark(
                        x: .value("WeekOfYear", item.date, unit: .weekOfYear),
                        y: .value("DayOfWeek", weekday(for: item.date))
                    )
                    .foregroundStyle(by: .value("Count", item.count))
                }
                .chartForegroundStyleScale(range: Gradient(colors: chartColors))
                .frame(height: 180)

                // Another chart for the last 6 months
                Chart(appsContributionData) { item in
                    RectangleMark(
                        x: .value("WeekOfYear", item.date, unit: .weekOfYear),
                        y: .value("DayOfWeek", weekday(for: item.date))
                    )
                    .foregroundStyle(by: .value("Count", item.count))
                }
                .chartForegroundStyleScale(range: Gradient(colors: chartColors))
                .frame(height: 180)
            } else {
                Text("Contribution chart requires macOS 13.0+.")
            }
        }
    }

    // MARK: - Time Range Picker
    private var timeRangePickerSection: some View {
        HStack {
            Picker("Select Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            // onChange for macOS 14 can have old/new values
            .onChange(of: selectedTimeRange) { _, _ in
                computeBarLineData()
            }
        }
    }

    // MARK: - Bar + Line Charts
    private var barLineChartsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Applications Frequency")
                .font(.headline)

            if #available(macOS 13.0, *) {
                // For demonstration, a bar chart followed by a line chart
                GeometryReader { geo in
                    VStack(alignment: .leading, spacing: 24) {
                        Chart(barLineData) { dayItem in
                            BarMark(
                                x: .value("Date", dayItem.date),
                                y: .value("Applications", dayItem.count)
                            )
                        }
                        .frame(height: 160)

                        Chart(barLineData) { dayItem in
                            LineMark(
                                x: .value("Date", dayItem.date),
                                y: .value("Applications", dayItem.count)
                            )
                        }
                        .frame(height: 160)
                    }
                    .frame(width: geo.size.width)
                }
                .frame(minHeight: 320)
            } else {
                Text("Charts require macOS 13.0+.")
            }
        }
    }

    // MARK: - Top 20 Companies
    private var top20CompaniesBarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top 20 Companies by Frequency")
                .font(.headline)
            // Placeholder for a more advanced bar chart
            Text("(You could show a bar chart or listing of top 20 here.)")
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Additional Horizontal Scroll Lists

    private var citiesByFrequencySection: some View {
        let cityCounts = cityFreqList()
        return VStack(alignment: .leading, spacing: 12) {
            Text("Cities By Frequency")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 24) {
                    ForEach(cityCounts, id: \.city) { item in
                        VStack {
                            Text(item.city)
                                .font(.headline)
                                .gradientForeground(colors: [.blue, .purple])
                                .multilineTextAlignment(.center)
                            Text("\(item.count)")
                                .font(.title3)
                        }
                        .padding(6)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var companiesByFrequencySection: some View {
        let companies = companyFreqList()
        return VStack(alignment: .leading, spacing: 12) {
            Text("Companies By Frequency")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 24) {
                    ForEach(companies, id: \.name ) { item in
                        VStack {
                            Text(item.name + "\n")
                                .font(.headline)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .gradientForeground(colors: [.blue, .purple])
                            Text("\(item.count)")
                                .font(.title3)
                        }
                        .padding(6)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Helper Methods

    /// Creates an array of city pins from the job store’s applications.
    private func computeCityPins() {
        var cityCount: [String: Int] = [:]
        for job in jobStore.jobApplications {
            let cityName = job.location
            cityCount[cityName, default: 0] += 1
        }
        cityPins = cityCount.map { (city, count) in
            let coord = CityCoordinateDictionary[city] ?? CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795)
            return CityPin(city: city, coordinate: coord, count: count)
        }
    }

    /// For demonstration, we fill `yearContributionData` with random data for a year's worth of days.
    private func computeYearContribution() {
        var data: [Contribution] = []
        let now = Date()
        for i in 0..<365 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: now)!
            data.append(Contribution(date: date, count: Int.random(in: 0...5)))
        }
        yearContributionData = data
    }

    /// For demonstration, we fill `appsContributionData` with random data for 6 months.
    private func computeAppsContribution() {
        var data: [Contribution] = []
        let now = Date()
        for i in 0..<180 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: now)!
            data.append(Contribution(date: date, count: Int.random(in: 0...3)))
        }
        appsContributionData = data
    }

    /// Recomputes `barLineData` based on the user's chosen time range (week, month, year).
    private func computeBarLineData() {
        var data: [DailyApps] = []
        let now = Date()
        let calendar = Calendar.current

        func isWithinRange(_ date: Date) -> Bool {
            switch selectedTimeRange {
            case .week:
                return date >= calendar.date(byAdding: .day, value: -7, to: now)!
            case .month:
                return date >= calendar.date(byAdding: .month, value: -1, to: now)!
            case .year:
                return date >= calendar.date(byAdding: .year, value: -1, to: now)!
            }
        }

        let filtered = jobStore.jobApplications.filter { isWithinRange($0.dateOfApplication) }
        var dayCount: [Date: Int] = [:]
        for job in filtered {
            let day = calendar.startOfDay(for: job.dateOfApplication)
            dayCount[day, default: 0] += 1
        }
        for (day, count) in dayCount {
            data.append(DailyApps(date: day, count: count))
        }
        data.sort { $0.date < $1.date }
        barLineData = data
    }

    /// Returns the company name with the highest frequency in the job store.
    private func topCompanyName() -> String {
        let companies = jobStore.jobApplications.map { $0.companyName }
        let freq = Dictionary(grouping: companies, by: { $0 }).mapValues { $0.count }
        let sorted = freq.sorted { $0.value > $1.value }
        return sorted.first?.key ?? "N/A"
    }

    /// Returns the top city (location) and how many jobs are in that city.
    private func topCity() -> (name: String, count: Int) {
        let cities = jobStore.jobApplications.map { $0.location }
        let freq = Dictionary(grouping: cities, by: { $0 }).mapValues { $0.count }
        let sorted = freq.sorted { $0.value > $1.value }
        if let top = sorted.first {
            return (top.key, top.value)
        } else {
            return ("N/A", 0)
        }
    }

    /// Returns a sorted list of (city, count) for the app’s city frequencies.
    private func cityFreqList() -> [(city: String, count: Int)] {
        let cities = jobStore.jobApplications.map { $0.location }
        let freq = Dictionary(grouping: cities, by: { $0 }).mapValues { $0.count }
        return freq.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }

    /// Returns a sorted list of (companyName, count) for the app’s company frequencies.
    private func companyFreqList() -> [(name: String, count: Int)] {
        let companies = jobStore.jobApplications.map { $0.companyName }
        let freq = Dictionary(grouping: companies, by: { $0 }).mapValues { $0.count }
        return freq.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }

    /// For macOS 13+ charts, we can define a gradient for the chart colors.
    @available(macOS 13.0, *)
    private var chartColors: [Color] {
        [Color.gray.opacity(0.1), .blue, .green, .yellow, .orange, .red]
    }

    /// Returns an Int representing the day of week (1=Sunday, 2=Monday, ...).
    private func weekday(for date: Date) -> Int {
        Calendar.current.component(.weekday, from: date)
    }

    /// For the chart Y-axis, we might label each integer with a short day name (Sun, Mon, etc.).
    private func shortWeekdaySymbol(_ day: Int) -> String? {
        let symbols = Calendar.current.shortWeekdaySymbols
        if day >= 1 && day <= 7 {
            return symbols[day - 1]
        }
        return nil
    }
}
