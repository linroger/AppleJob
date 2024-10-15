//
//  AppleJobApp.swift
//  AppleJob
//
//  Created by Roger Lin on [Date].
//  Updated to integrate with a new Safari app extension, removing older RTF code.
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

// -----------------------------------------------------
// MARK: - AppDelegate
// -----------------------------------------------------
/**
 AppDelegate class that listens for custom URL scheme invocations (applejob://).
 Safari extension will invoke applejob://?json=... after extracting job data.
 */
class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        NotificationCenter.default.post(name: .didOpenCustomURL, object: url)
    }
}

// -----------------------------------------------------
// MARK: - Notification.Name Extension
// -----------------------------------------------------
extension Notification.Name {
    static let didOpenCustomURL = Notification.Name("didOpenCustomURL")
}

// -----------------------------------------------------
// MARK: - JobStatus
// -----------------------------------------------------
/**
 Represents the status of a job application.
 */
enum JobStatus: String, CaseIterable, Codable {
    case interested = "Interested"
    case applied = "Applied"
    case interview = "Interview"
    case offer = "Offer"
    case rejection = "Rejection"

    // Changed interview color to purple
    var displayColor: Color {
        switch self {
        case .interested: return .gray
        case .applied:    return .blue
        case .interview:  return .purple
        case .offer:      return .green
        case .rejection:  return .red
        }
    }
}

// -----------------------------------------------------
// MARK: - Sort
// -----------------------------------------------------
enum Sort: String, CaseIterable {
    case title = "Job Title"
    case company = "Company Name"
    case recentlyApplied = "Recently Applied"
}

// -----------------------------------------------------
// MARK: - JobApplication
// -----------------------------------------------------
/**
 A model representing a single job application.
 
// Updated to include optional RTF Data for jobDescription, coverLetter, notes
//
 Removed older RTF fields. We only keep plain text for jobDescription, coverLetter, and notes.
 */
struct JobApplication: Codable, Identifiable, Hashable {
    var id: UUID
    var companyName: String
    var jobTitle: String
    var status: JobStatus
    var dateOfApplication: Date
    var location: String
    var linkToJobString: String?
    var salary: Double?

    // Original text fields
    var jobDescription: String
    var coverLetter: String
    var notes: String?

    var isFavorite: Bool
    var documents: [JobDocument]

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

    // MARK: - Codable Implementation
    // MARK: - Codable
    // ------------------------------------------------
    // Coding/Decoding
    // ------------------------------------------------
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.companyName = try container.decode(String.self, forKey: .companyName)
        self.jobTitle = try container.decode(String.self, forKey: .jobTitle)

        // status stored as a rawValue
        let statusRawValue = try container.decode(String.self, forKey: .statusRawValue)
        self.status = JobStatus(rawValue: statusRawValue) ?? .interested
        
        self.dateOfApplication = try container.decode(Date.self, forKey: .dateOfApplication)
        self.location = try container.decode(String.self, forKey: .location)
        self.linkToJobString = try? container.decode(String.self, forKey: .linkToJobString)
        self.salary = try? container.decode(Double.self, forKey: .salary)

        self.jobDescription = try container.decode(String.self, forKey: .jobDescription)
        self.coverLetter    = try container.decode(String.self, forKey: .coverLetter)
        self.notes          = try? container.decode(String.self, forKey: .notes)

        self.isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        self.documents  = try container.decode([JobDocument].self, forKey: .documents)
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

    static func == (lhs: JobApplication, rhs: JobApplication) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// -----------------------------------------------------
// MARK: - JobDocument
// -----------------------------------------------------
/**
 A model for uploaded documents. Preserves file metadata and data.
 */
struct JobDocument: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var fileName: String
    var fileURL: URL?
    var fileData: Data

    // Original metadata
    var creationDate: Date
    var lastModifiedDate: Date

    var fileSize: Int
    var wordCount: Int
    var categoryID: UUID?

    init(
        id: UUID = UUID(),
        fileName: String,
        fileData: Data,
        fileURL: URL? = nil,
        creation: Date = Date(),
        lastModified: Date = Date(),
        fileSize: Int? = nil,
        wordCount: Int? = nil,
        categoryID: UUID? = nil
    ) {
        self.id = id
        self.fileName = fileName
        self.fileURL = fileURL
        self.fileData = fileData
        self.creationDate = creation
        self.lastModifiedDate = lastModified
        self.fileSize = fileSize ?? fileData.count
        self.wordCount = wordCount ?? 0
        self.categoryID = categoryID
    }

    // Coding/Decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.fileName = try container.decode(String.self, forKey: .fileName)
        self.fileData = try container.decode(Data.self, forKey: .fileData)
        self.fileURL = try? container.decode(URL.self, forKey: .fileURL)
        self.creationDate = try container.decodeIfPresent(Date.self, forKey: .creationDate) ?? Date()
        self.lastModifiedDate = try container.decodeIfPresent(Date.self, forKey: .lastModifiedDate) ?? Date()
        self.fileSize = try container.decodeIfPresent(Int.self, forKey: .fileSize) ?? fileData.count
        self.wordCount = try container.decodeIfPresent(Int.self, forKey: .wordCount) ?? 0
        self.categoryID = try container.decodeIfPresent(UUID.self, forKey: .categoryID)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case fileName
        case fileData
        case fileURL
        case creationDate
        case lastModifiedDate
        case fileSize
        case wordCount
        case categoryID
    }
}

// -----------------------------------------------------
// MARK: - DocumentCategory
// -----------------------------------------------------
struct DocumentCategory: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var isExpanded: Bool = true

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

// MARK: - CompanyFreq, CityPin, Contribution, DailyApps, MonthlyCityData
// -----------------------------------------------------
struct CompanyFreq: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
}

struct CityPin: Identifiable {
    let id = UUID()
    let city: String
    let coordinate: CLLocationCoordinate2D
    let count: Int
}

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
// MARK: - View Models & Data Stores
]

/// An example initializer could be:
/// .init(city: "New York City, NY", monthKey: "Jan 2023", count: 2, date: someDate)
// -----------------------------------------------------
struct MonthlyCityData: Identifiable {
    let id = UUID()
    let monthKey: String
    let city: String
    let count: Int
    let date: Date
}

struct Contribution: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
}

struct DailyApps: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

// MARK: - Gradient Foreground Modifier
extension View {
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

// MARK: - JobStore
/**
 Manages a collection of JobApplication items, including load/save from UserDefaults.
 */
class JobStore: ObservableObject {
    @Published var jobApplications: [JobApplication] = []
    @Published var selectedJob: JobApplication? = nil
    @Published var isAddingNewJob = false
    @Published var isEditingJob = false
    @Published var sorting: Sort = .recentlyApplied

    // This dictionary gets set when the Safari extension passes data
    // via our custom URL scheme: applejob://?json=...
    @Published var incomingJobData: [String: Any]? = nil

    init() {
        loadJobs()
    }

    func addJob(_ job: JobApplication) {
        jobApplications.append(job)
        sortJobs(by: sorting)
        saveJobs()
    }

    func editJob(with updatedJob: JobApplication) {
        if let index = jobApplications.firstIndex(where: { $0.id == updatedJob.id }) {
            jobApplications[index] = updatedJob
            sortJobs(by: sorting)
            saveJobs()
        }
    }

    func deleteJob(for id: UUID) {
        if let index = jobApplications.firstIndex(where: { $0.id == id }) {
            jobApplications.remove(at: index)
            if selectedJob?.id == id {
                selectedJob = nil
            }
            saveJobs()
        }
    }

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

    func updateJobStatus(_ id: UUID, to status: JobStatus) {
        if let index = jobApplications.firstIndex(where: { $0.id == id }) {
            jobApplications[index].status = status
            saveJobs()
        }
    }

    func toggleFavorite(for id: UUID) {
        if let index = jobApplications.firstIndex(where: { $0.id == id }) {
            jobApplications[index].isFavorite.toggle()
            saveJobs()
        }
    }

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

    func saveJobs() {
        do {
            let data = try JSONEncoder().encode(jobApplications)
            UserDefaults.standard.set(data, forKey: "jobs")
        } catch {
            print("Failed to save jobs: \(error.localizedDescription)")
        }
    }

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

    // Called after the Safari extension provides a backup JSON file (not required here).
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

    // Called if the user wants to export job data to a JSON file (not required here).
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


// -----------------------------------------------------
// MARK: - DocumentStore
/**
 Manages a collection of JobDocument items, as well as categories.
 */
class DocumentStore: ObservableObject {
    @Published var documents: [JobDocument] = []
    @Published var selectedDocument: JobDocument? = nil

    @Published var categories: [DocumentCategory] = []
    @Published var isCreatingNewCategory = false
    @Published var newCategoryName: String = "Category Name"

    @Published var quickLookURL: URL? = nil

    // For editing metadata in a sheet
    @Published var isEditingMetadata = false
    @Published var documentToEdit: JobDocument? = nil

    init() {
        loadDocuments()
        loadCategories()
    }

    // Upload documents from URLs
    func uploadDocuments(from urls: [URL]) {
        for url in urls {
            do {
                let data = try Data(contentsOf: url)
                var creation = Date()
                var modified = Date()

                // Attempt to read file’s creation/modification dates
                if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) {
                    if let cdate = attributes[.creationDate] as? Date {
                        creation = cdate
                    }
                    if let mdate = attributes[.modificationDate] as? Date {
                        modified = mdate
                    }
                }

                if let savedURL = DocumentStore.saveDocumentToAppSupport(
                    originalURL: url,
                    fileName: url.lastPathComponent
                ) {
                    let newDoc = JobDocument(
                        fileName: url.lastPathComponent,
                        fileData: data,
                        fileURL: savedURL,
                        creation: creation,
                        lastModified: modified
                    )
                    if !documents.contains(newDoc) {
                        documents.append(newDoc)
                    }
                } else {
                    print("Failed to save document to app support directory.")
                }
            } catch {
                print("Error reading document: \(error)")
            }
        }
        saveDocuments()
    }

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

    func duplicateDocument(_ document: JobDocument) {
        guard let savedURL = DocumentStore.saveDocumentToAppSupport(
            originalURL: document.fileURL ?? URL(fileURLWithPath: ""),
            fileName: document.fileName
        ) else {
            print("Failed to save duplicated document.")
            return
        }
        let newDoc = JobDocument(
            fileName: "\(document.fileName)-copy",
            fileData: document.fileData,
            fileURL: savedURL,
            creation: document.creationDate,
            lastModified: document.lastModifiedDate,
            fileSize: document.fileSize,
            wordCount: document.wordCount,
            categoryID: document.categoryID
        )
        documents.append(newDoc)
        saveDocuments()
    }

    func deleteDocument(_ document: JobDocument) {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents.remove(at: index)
            if let fileURL = document.fileURL {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                } catch {
                    print("Failed to delete file at \(fileURL): \(error)")
                }
            }
        }
        if selectedDocument?.id == document.id {
            selectedDocument = nil
        }
        saveDocuments()
    }

    func mergeDocuments(_ newDocs: [JobDocument]) {
        for doc in newDocs {
            if !documents.contains(doc) {
                documents.append(doc)
            }
        }
        saveDocuments()
    }

    func saveDocuments() {
        do {
            let data = try JSONEncoder().encode(documents)
            UserDefaults.standard.set(data, forKey: "documents")
        } catch {
            print("Failed to save documents: \(error.localizedDescription)")
        }
    }

    func loadDocuments() {
        guard let savedData = UserDefaults.standard.data(forKey: "documents") else { return }
        do {
            let loadedDocs = try JSONDecoder().decode([JobDocument].self, from: savedData)
            documents = loadedDocs
        } catch {
            print("Failed to load documents: \(error.localizedDescription)")
        }
    }

    func saveCategories() {
        do {
            let data = try JSONEncoder().encode(categories)
            UserDefaults.standard.set(data, forKey: "documentCategories")
        } catch {
            print("Failed to save categories: \(error.localizedDescription)")
        }
    }

    func loadCategories() {
        guard let savedData = UserDefaults.standard.data(forKey: "documentCategories") else { return }
        do {
            let loaded = try JSONDecoder().decode([DocumentCategory].self, from: savedData)
            categories = loaded
        } catch {
            print("Failed to load categories: \(error.localizedDescription)")
        }
    }

    func createNewCategory(name: String) {
        guard !name.isEmpty else { return }
        let newCat = DocumentCategory(name: name)
        categories.append(newCat)
        saveCategories()
    }

    func assignDocument(_ doc: JobDocument, to category: DocumentCategory) {
        if let idx = documents.firstIndex(where: { $0.id == doc.id }) {
            documents[idx].categoryID = category.id
            saveDocuments()
        }
    }

    func unassignDocument(_ doc: JobDocument) {
        if let idx = documents.firstIndex(where: { $0.id == doc.id }) {
            documents[idx].categoryID = nil
            saveDocuments()
        }
    }

    func beginEditMetadata(for doc: JobDocument) {
        self.documentToEdit = doc
        self.isEditingMetadata = true
    }

    // Where we physically store docs in Application Support
    static func saveDocumentToAppSupport(originalURL: URL, fileName: String) -> URL? {
        guard let appSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first else {
            return nil
        }
        let documentsDirectory = appSupportURL.appendingPathComponent("Documents", isDirectory: true)
        do {
            try FileManager.default.createDirectory(
                at: documentsDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            print("Failed to create Documents directory: \(error)")
            return nil
        }
        let uniqueFileName = UUID().uuidString + "_" + fileName
        let destinationURL = documentsDirectory.appendingPathComponent(uniqueFileName)
        do {
            try FileManager.default.copyItem(at: originalURL, to: destinationURL)
            return destinationURL
        } catch {
            print("Failed to copy file to Documents directory: \(error)")
            return nil
        }
    }
}

// MARK: - ImportExportHelper
class ImportExportHelper: NSObject, ObservableObject {
    @Published var isImporting = false
    @Published var isExporting = false

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

// MARK: - JobViewModel
/**
 A view model used for AddJobView and EditJobView. Plain text only.
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

    init() {
        validateInputs()
    }

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

    func validateInputs() {
        DispatchQueue.main.async {
            self.isInputValid = !(self.companyName.isEmpty || self.jobTitle.isEmpty)
        }
    }

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
            
            // plain text fallback
            jobDescription: jobDescription,
            coverLetter: coverLetter,
            notes: notes,
            documents: documents,
            isFavorite: false
        )
        store.addJob(newJob)
        reset()
    }

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

// -----------------------------------------------------
// MARK: - Main App
// -----------------------------------------------------
@main
struct AppleJobApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var jobStore = JobStore()
    @StateObject private var docStore = DocumentStore()
    @StateObject private var importExportHelper = ImportExportHelper()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(jobStore)
                .environmentObject(docStore)
                .environmentObject(importExportHelper)
                // Listen for our custom URL scheme applejob://?json=...
                .onReceive(NotificationCenter.default.publisher(for: .didOpenCustomURL)) { notification in
                    if let url = notification.object as? URL {
                        handleIncomingURL(url)
                    }
                }
        }
        .commands {
            fileMenuCommands
            editMenuCommands
        }
    }

    // ------------------------------------------------
    // MARK: - Handle Incoming URL
    // ------------------------------------------------
    /**
     This is the crucial piece that processes applejob://?json={...}
     from the Safari extension. We parse the JSON and set `jobStore.incomingJobData`,
     then open the AddJobView with that data.
     */
    private func handleIncomingURL(_ url: URL) {
        // We only care about applejob:// scheme
        guard url.scheme == "applejob" else { return }

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let jsonParam = components.queryItems?.first(where: { $0.name == "json" })?.value,
           let jsonDecoded = jsonParam.removingPercentEncoding?.data(using: .utf8) {
            do {
                if let dict = try JSONSerialization.jsonObject(with: jsonDecoded, options: []) as? [String: Any] {
                    // Store the dictionary in jobStore for reference if needed
                    jobStore.incomingJobData = dict
                    // Programmatically open the AddJobView
                    jobStore.isAddingNewJob = true
                }
            } catch {
                print("Error parsing job data from Safari app extension: \(error)")
            }
        }
    }

    // Used to transform the [String: Any] from the Safari extension into a new JobApplication
    private func buildJobFromDictionary(_ dict: [String: Any]) -> JobApplication {
        let jobTitle = dict["jobTitle"] as? String ?? "Untitled"
        let company = dict["companyName"] as? String ?? "(Unknown)"
        let link = dict["url"] as? String
        let jobDescription = dict["jobDescription"] as? String ?? ""
        return JobApplication(
            companyName: company,
            jobTitle: jobTitle,
            status: .interested,
            dateOfApplication: Date(),
            location: "",
            linkToJobString: link,
            jobDescription: jobDescription,
            coverLetter: "",
            notes: nil,
            documents: [],
            isFavorite: false
        )
    }

    // ------------------------------------------------
    // MARK: - File & Edit Menus
    // ------------------------------------------------
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

    private var editMenuCommands: some Commands {
        CommandMenu("Edit") {
            // Existing job/application commands
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

            // Document categories
            // Create category (for documents)
            Button("Create New Category") {
                docStore.newCategoryName = "Category Name"
                docStore.isCreatingNewCategory = true
            }

            // ------------------------------------------------
            // New Document Commands: Move To Category, Edit Info
            // ------------------------------------------------
            Divider()
            Menu("Document") {
                Button("Edit Document Info") {
                    if let doc = docStore.selectedDocument {
                        docStore.beginEditMetadata(for: doc)
        }
    }
                .disabled(docStore.selectedDocument == nil)

                Menu("Move to Category") {
    // For exporting documents as a zip file
                    ForEach(docStore.categories, id: \.id) { cat in
                        Button(cat.name) {
                            if let doc = docStore.selectedDocument {
                                docStore.assignDocument(doc, to: cat)
                            }
                        }
                    }
                    Button("Unassign (All Documents)") {
                        if let doc = docStore.selectedDocument {
                            docStore.unassignDocument(doc)
                        }
                    }
                }
                .disabled(docStore.selectedDocument == nil)
            }
        }
    }

    private func exportAllDocumentsToZip(url: URL) {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("temp_documents_\(UUID())")
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

// MARK: - ViewSection
// -----------------------------------------------------
enum ViewSection: String, CaseIterable {
    case jobDetails = "Job Details"
    case stats = "Stats"
    case documents = "Documents"
}

// MARK: - ContentView
// -----------------------------------------------------
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
                        .blur(radius: 3)
                )
            mainContent
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                Picker("View Section", selection: $selectedSection) {
                    ForEach(ViewSection.allCases, id: \.self) { section in
                        Text(section.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
                Spacer()

                if selectedSection == .documents {
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
                            .environmentObject(docStore)
                    }
                }

                Button {
                    isDarkMode.toggle()
                } label: {
                    Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                }
            }
        }
    }

    @ViewBuilder
    private var sidebar: some View {
        switch selectedSection {
        case .jobDetails, .stats:
            JobSidebarView(searchText: $searchText)
        case .documents:
            DocumentsSidebarView()
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch selectedSection {
        case .jobDetails:
            if let job = jobStore.selectedJob {
                JobDetailView(job: job)
                    .id(job.id)
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
// MARK: - DocumentInfoPopover
struct DocumentInfoPopover: View {
    let document: JobDocument?
    @EnvironmentObject var docStore: DocumentStore

    @State private var showEditMetadataSheet = false
// -----------------------------------------------------
    var body: some View {
// MARK: - Supporting View Enums
// -----------------------------------------------------
        VStack(alignment: .leading, spacing: 8) {
enum ViewSection: String, CaseIterable {
            Text("Document Information")
                .font(.headline)
            if let doc = document {
    case jobDetails = "Job Details"
                Text("File Name: \(doc.fileName)")
                Text("Created: \(doc.creationDate.formatted(date: .abbreviated, time: .omitted))")
    case stats = "Stats"
                Text("Last Modified: \(doc.lastModifiedDate.formatted(date: .abbreviated, time: .omitted))")
                Text("File Size: \(doc.fileSize) bytes")
    case documents = "Documents"
                Text("Word Count: \(doc.wordCount)")

                Divider()
                Button("Edit Metadata") {
                    docStore.beginEditMetadata(for: doc)
                    showEditMetadataSheet = true
                }
                .sheet(isPresented: $showEditMetadataSheet) {
                    if let docToEdit = docStore.documentToEdit {
                        DocumentMetadataEditView(doc: docToEdit)
                            .environmentObject(docStore)
}
                }
            } else {
                Text("No document selected.")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(minWidth: 250)
    }
}

// MARK: - DocumentMetadataEditView
// -----------------------------------------------------
struct DocumentMetadataEditView: View {
    @EnvironmentObject var docStore: DocumentStore
    @Environment(\.presentationMode) var presentationMode

    @State var doc: JobDocument

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edit Document Metadata")
                .font(.headline)
            TextField("File Name", text: $doc.fileName)
                .textFieldStyle(.roundedBorder)
            DatePicker("Creation Date", selection: $doc.creationDate, displayedComponents: .date)
            DatePicker("Last Modified Date", selection: $doc.lastModifiedDate, displayedComponents: .date)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    presentationMode.wrappedValue.dismiss()
                }
                Button("Save") {
                    if let idx = docStore.documents.firstIndex(where: { $0.id == doc.id }) {
                        docStore.documents[idx].fileName = doc.fileName
                        docStore.documents[idx].creationDate = doc.creationDate
                        docStore.documents[idx].lastModifiedDate = doc.lastModifiedDate
                        docStore.saveDocuments()
                    }
                    presentationMode.wrappedValue.dismiss()
                    docStore.isEditingMetadata = false
                }
            }
            .padding(.top, 12)
        }
        .padding()
        .frame(minWidth: 400)
    }
}

// MARK: - JobSidebarView
// -----------------------------------------------------
struct JobSidebarView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var searchText: String

    var body: some View {
        List(selection: $jobStore.selectedJob) {
            ForEach(filteredJobs, id: \.id) { job in
                SidebarItemView(
                    job: job,
                    isSelected: Binding(
                        get: { jobStore.selectedJob == job },
                        set: { newValue in
                            if newValue { jobStore.selectedJob = job }
                            else if jobStore.selectedJob == job {
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
            ToolbarItem(placement: .navigation) {
                Button {
                    jobStore.isAddingNewJob = true
                } label: {
                    Label("New", systemImage: "plus")
                }
            }
        }
        // Sheet for adding new job
        .sheet(isPresented: $jobStore.isAddingNewJob) {
            AddJobView(isPresented: $jobStore.isAddingNewJob)
                .environmentObject(jobStore)
                .environmentObject(docStore)
        }
        // Sheet for editing job
        .sheet(isPresented: $jobStore.isEditingJob) {
            if let job = jobStore.selectedJob {
                EditJobView(isPresented: $jobStore.isEditingJob, job: job)
                    .environmentObject(jobStore)
                    .environmentObject(docStore)
            }
        }
    }

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

    private func deleteJobs(at offsets: IndexSet) {
        for index in offsets {
            let job = filteredJobs[index]
            jobStore.deleteJob(for: job.id)
        }
    }
}

// -----------------------------------------------------
// MARK: - SidebarItemView
/**
 Replaces the background fill with Apple’s native primary background color
 so it does NOT dim or turn gray when app is inactive.
 */
// MARK: - SidebarItemView
// -----------------------------------------------
// This view shows each JobApplication in the Jobs sidebar
// with a "pill" that uses the status color. The background
// fill is adjusted so it doesn't dim on inactivity.
// -----------------------------------------------------
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

            // The status pill (capsule) with the job status
            Text(job.status.rawValue)
                .font(.caption)
                .padding(5)
                .background(
                    Capsule()
                        // If selected, fill with selectedTextBackgroundColor (lighter),
                        // otherwise use status.displayColor with a partial opacity
                        .fill(
                        isSelected
                        ? Color(nsColor: .selectedTextBackgroundColor).opacity(0.6)
                        : job.status.displayColor.opacity(0.2)
                    )
                )
                .foregroundColor(job.status.displayColor)
        }
        // Allows the entire row to be clickable
        .contentShape(Rectangle())

        // Right-click context menu for job
        .contextMenu {
            
            Button("Add New Application") {
                jobStore.isAddingNewJob = true
            }
            Button("Duplicate Application") {
                jobStore.duplicateJob(job)
            }
            Button("Edit Application Info") {
                jobStore.isEditingJob = true
            }
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



            Divider()
            Button("Favorite Application") {
                if let selectedJob = jobStore.selectedJob {
                jobStore.toggleFavorite(for: job.id)
            }
            Divider()
            Button("Delete Application", role: .destructive) {
                jobStore.deleteJob(for: job.id)
            }
                      Button("Delete Application") {
                if let selectedJob = jobStore.selectedJob {
                    jobStore.deleteJob(for: selectedJob.id)
                }
            }
            .keyboardShortcut(.delete, modifiers: .command)
            .disabled(jobStore.selectedJob == nil)
        }

        // Tap to toggle selection
        .onTapGesture {
            isSelected.toggle()
        }
    }
}

// -----------------------------------------------------
// MARK: - DocumentsSidebarView
// -----------------------------------------------------
// This updated view allows reordering categories,
// assigns documents to categories, and has a more
// transparent background with minimal blur.
// -----------------------------------------------
// MARK: - DocumentsSidebarView
// -----------------------------------------------
// This updated view allows reordering categories,
// assigns documents to categories, supports editing
// category names, and has a more transparent background
// with minimal blur.
// -----------------------------------------------
struct DocumentsSidebarView: View {
    @EnvironmentObject var docStore: DocumentStore

    // State for editing an existing category
    @State private var isEditingCategory: Bool = false
    @State private var categoryToEdit: DocumentCategory? = nil
    @State private var categoryNameForEdit: String = ""

    var body: some View {
        // A List with selection bound to the selectedDocument in docStore
        List(selection: $docStore.selectedDocument) {
            // Section for "All Documents" / uncategorized
            Section {
                DisclosureGroup {
                    ForEach(uncategorizedDocuments, id: \.id) { doc in
                        documentSidebarItem(doc)
                            // Slightly reduce indentation
                            .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 0))
                    }
                } label: {
                    Text("All Documents")
                        .font(.headline)
                }
            }

            // For each category, show a DisclosureGroup
            // Categories
            ForEach($docStore.categories, id: \.id) { $category in
                DisclosureGroup(isExpanded: $category.isExpanded) {
                    ForEach(docsForCategory(category.id), id: \.id) { doc in
                        documentSidebarItem(doc)
                            .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 0))
                    }
                } label: {
                    Text(category.name)
                        .font(.headline)
                }
                .contextMenu {
                    Button("Edit Category") {
                        categoryToEdit = category
                        categoryNameForEdit = category.name
                        isEditingCategory = true
                    }
                    Button("Delete Category", role: .destructive) {
                        // Move all docs in this category to "All Documents"
                        for docIndex in docStore.documents.indices {
                            if docStore.documents[docIndex].categoryID == category.id {
                                docStore.documents[docIndex].categoryID = nil
                            }
                        }
                        docStore.saveDocuments()

                        // Remove the category
                        if let catIndex = docStore.categories.firstIndex(where: { $0.id == category.id }) {
                            docStore.categories.remove(at: catIndex)
                            docStore.saveCategories()
                        }
                    }
                }
            }
            .onMove(perform: moveCategories)
        }
        .listStyle(SidebarListStyle())
        .background(
            Color.black.opacity(0.02).blur(radius: 1.0)
        )
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    docStore.newCategoryName = "Category Name"
                    docStore.isCreatingNewCategory = true
                } label: {
                    Label("New Category", systemImage: "folder.badge.plus")
                }
            }
        }
        // Context menu for blank space in the sidebar
        .contextMenu {
            Button("Create New Category") {
                docStore.newCategoryName = "Category Name"
                docStore.isCreatingNewCategory = true
            }
        }
        // Sheet to create a new category
        .sheet(isPresented: $docStore.isCreatingNewCategory) {
            NewCategorySheet()
                .environmentObject(docStore)
        }
        // Sheet for editing category
        .sheet(isPresented: $isEditingCategory) {
            VStack {
                TextField("Category Name", text: $categoryNameForEdit)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                HStack {
                    Button("Cancel", role: .cancel) {
                        isEditingCategory = false
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    Spacer()
                    Button("Save") {
                        if let catToEdit = categoryToEdit,
                           let idx = docStore.categories.firstIndex(where: { $0.id == catToEdit.id }) {
                            docStore.categories[idx].name = categoryNameForEdit
                            docStore.saveCategories()
                        }
                        isEditingCategory = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
                .padding()
            }
            .frame(width: 300, height: 150)
            .padding()
        }
        .quickLookPreview($docStore.quickLookURL)
    }

    private var uncategorizedDocuments: [JobDocument] {
        docStore.documents
            .filter { $0.categoryID == nil }
            .sorted { $0.lastModifiedDate > $1.lastModifiedDate }
    }

    private func moveCategories(from offsets: IndexSet, to destination: Int) {
        docStore.categories.move(fromOffsets: offsets, toOffset: destination)
        docStore.saveCategories()
    }

    // Return documents for a specific category, sorted (latest first)
    private func docsForCategory(_ catID: UUID) -> [JobDocument] {
        docStore.documents
            .filter { $0.categoryID == catID }
            .sorted { $0.lastModifiedDate > $1.lastModifiedDate }
    }

    // Helper to build a row for each document
    @ViewBuilder
    private func documentSidebarItem(_ doc: JobDocument) -> some View {
        Label {
            Text(cleanFileName(doc.fileName))
                .font(.system(size: 12))
        } icon: {
            // Slightly larger doc icon
            Image(systemName: "doc.text")
                .font(.system(size: 18))
                .foregroundColor(.blue)
        }
        .contextMenu {
            Button("Duplicate Document") {
                docStore.duplicateDocument(doc)
            }
            Divider()
            Menu("Move to Category...") {
                ForEach(docStore.categories, id: \.id) { category in
                    Button(category.name) {
                        docStore.assignDocument(doc, to: category)
                    }
                }
            }
            Button("Create New Category") {
                docStore.newCategoryName = "Category Name"
                docStore.isCreatingNewCategory = true
            }
            Divider()
            Button("Edit Document Info") {
                docStore.beginEditMetadata(for: doc)
            }
            Button("Delete Document", role: .destructive) {
                docStore.deleteDocument(doc)
            }
        }
        .tag(doc)
    }

    // Removes certain repeated substrings or file extensions from the displayed file name
    private func cleanFileName(_ filename: String) -> String {
        var cleanedName = filename
        let stringsToRemove = ["Roger Lin", "Position", "2024", "Cover Letter"]
        for stringToRemove in stringsToRemove {
            cleanedName = cleanedName.replacingOccurrences(of: stringToRemove, with: "")
        }
        cleanedName = cleanedName.trimmingCharacters(in: .whitespaces)
        let fileExtensions = [".pdf", ".docx", ".pages", ".rtf", ".txt"]
        for ext in fileExtensions {
            if cleanedName.hasSuffix(ext) {
                cleanedName = String(cleanedName.dropLast(ext.count))
                break
            }
        }
        return cleanedName
    }
}

// -----------------------------------------------------
// MARK: - NewCategorySheet
// -----------------------------------------------------
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

// -----------------------------------------------------
// MARK: - DocumentsMainView
// MARK: - DocumentsMainView
// -----------------------------------------------
// Shows either:
//   • A prompt if no docs exist
//   • A "Select a document" message if none is selected
//   • The selected doc's PDF view if present
//
// Dynamically sets the macOS window title to the doc's name
// instead of "AppleJob" or a static title.
// -----------------------------------------------------
import PDFKit

// MARK: - DocumentsMainView
// ---------------------------------------------------------------
// Now sets the macOS window title to the CLEANED file name if
// docStore.selectedDocument is available. Otherwise defaults
// to "Documents" when none is selected.
// ---------------------------------------------------------------
struct DocumentsMainView: View {
    @EnvironmentObject var docStore: DocumentStore

    /// Store a reference to the active NSWindow so we can change its title
    @State private var windowRef: NSWindow?
    @State private var quickLookURL: URL? = nil

    var body: some View {
        ZStack {
            if docStore.documents.isEmpty {
                VStack {
                    Spacer()
                    Button("Upload") {
                        showDocumentPicker { urls in
                            docStore.uploadDocuments(from: urls)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    Spacer()
                }
            }
            else if docStore.selectedDocument == nil {
                Text("Select a document to view.")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            else if let doc = docStore.selectedDocument {
                // Display PDF or any inline viewer
                PDFInlineViewer(fileURL: doc.fileURL, fileData: doc.fileData)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // Capture the NSWindow when this view appears
        .onAppear {
            if windowRef == nil {
                // Attempt to find the key window (active window)
                if let keyWindow = NSApp.windows.first(where: { $0.isKeyWindow }) {
                    self.windowRef = keyWindow
                }
            }
            updateWindowTitle(doc: docStore.selectedDocument)
        }
        .onChange(of: docStore.selectedDocument) { _, newDoc in
            updateWindowTitle(doc: newDoc)
        }
        .sheet(isPresented: $docStore.isEditingMetadata) {
            if let docToEdit = docStore.documentToEdit {
                DocumentMetadataEditView(doc: docToEdit)
                    .environmentObject(docStore)
            }
        }
        .quickLookPreview($quickLookURL)
    }

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

    private func updateWindowTitle(doc: JobDocument?) {
        guard let window = windowRef else { return }
        if let doc = doc {
            window.title = cleanFileName(doc.fileName)
        } else {
            window.title = "Documents"
        }
    }

    private func cleanFileName(_ filename: String) -> String {
        var cleanedName = filename
        let stringsToRemove = ["Roger Lin", "Position", "2024", "Cover Letter"]
        for removal in stringsToRemove {
            cleanedName = cleanedName.replacingOccurrences(of: removal, with: "")
        }
        let fileExtensions = [".pdf", ".docx", ".pages", ".rtf", ".txt"]
        for ext in fileExtensions {
            if cleanedName.hasSuffix(ext) {
                cleanedName = String(cleanedName.dropLast(ext.count))
                break
            }
        }
        return cleanedName.trimmingCharacters(in: .whitespaces)
    }
}

// -----------------------------------------------------
// MARK: - PDFInlineViewer
// -----------------------------------------------------
struct PDFInlineViewer: NSViewRepresentable {
    let fileURL: URL?
    let fileData: Data

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        if let pdfDoc = PDFDocument(data: fileData) {
            pdfView.document = pdfDoc
        }
        return pdfView
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        guard let currentDoc = nsView.document else {
            nsView.document = PDFDocument(data: fileData)
            return
        }
        let existingData = currentDoc.dataRepresentation() ?? Data()
        if existingData != fileData {
            nsView.document = PDFDocument(data: fileData)
        }
    }
}

// -----------------------------------------------------
// MARK: - DocumentInfoPopover
// -----------------------------------------------------
struct DocumentInfoPopover: View {
    let document: JobDocument?
    @EnvironmentObject var docStore: DocumentStore
    @State private var showEditMetadataSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Document Information")
                .font(.headline)
            if let doc = document {
                Text("File Name: \(doc.fileName)")
                Text("Created: \(doc.creationDate.formatted(date: .abbreviated, time: .omitted))")
                Text("Last Modified: \(doc.lastModifiedDate.formatted(date: .abbreviated, time: .omitted))")
                Text("File Size: \(doc.fileSize) bytes")
                Text("Word Count: \(doc.wordCount)")

                Divider()
                Button("Edit Metadata") {
                    docStore.beginEditMetadata(for: doc)
                    showEditMetadataSheet = true
                }
                .sheet(isPresented: $showEditMetadataSheet) {
                    if let docToEdit = docStore.documentToEdit {
                        DocumentMetadataEditView(doc: docToEdit)
                            .environmentObject(docStore)
                    }
                }
            } else {
                Text("No document selected.")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(minWidth: 250)
    }
}

// -----------------------------------------------------
// MARK: - DocumentMetadataEditView
// -----------------------------------------------------
struct DocumentMetadataEditView: View {
    @EnvironmentObject var docStore: DocumentStore
    @Environment(\.presentationMode) var presentationMode
    @State var doc: JobDocument

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edit Document Metadata")
                .font(.headline)
            TextField("File Name", text: $doc.fileName)
                .textFieldStyle(.roundedBorder)
            DatePicker("Creation Date", selection: $doc.creationDate, displayedComponents: .date)
            DatePicker("Last Modified Date", selection: $doc.lastModifiedDate, displayedComponents: .date)
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    presentationMode.wrappedValue.dismiss()
                }
                Button("Save") {
                    if let idx = docStore.documents.firstIndex(where: { $0.id == doc.id }) {
                        docStore.documents[idx].fileName = doc.fileName
                        docStore.documents[idx].creationDate = doc.creationDate
                        docStore.documents[idx].lastModifiedDate = doc.lastModifiedDate
                        docStore.saveDocuments()
                    }
                    presentationMode.wrappedValue.dismiss()
                    docStore.isEditingMetadata = false
                }
            }
            .padding(.top, 12)
        }
        .padding()
        .frame(minWidth: 400)
    }
}

// -----------------------------------------------------
// MARK: - EnhancedStatsView Placeholder
// -----------------------------------------------------
/**
 Placeholder for your stats. Not strictly relevant to the Safari extension integration.
 */
struct EnhancedStatsView: View {
    var body: some View {
        Text("Stats Go Here")
            .font(.title)
            .foregroundColor(.secondary)
    }
}

// -----------------------------------------------------
// MARK: - JobDetailView
    // ---------------------------------------------------------------
    // Displays details of a selected JobApplication and sets the
// -----------------------------------------------------
/**
    // macOS window title to "[CompanyName] [JobTitle]" rather than
    // a static "Job Details" or .navigationTitle(...) text.
    // ---------------------------------------------------------------


    // MARK: - JobDetailView
    // ---------------------------------------------------------------
    // Displays details of a selected JobApplication and sets the
    // macOS window title to "CompanyName JobTitle" (no brackets).
    // It also updates dynamically whenever 'job.id' changes,
    // so if the user selects a different job, the window title
    // will refresh.
    // ---------------------------------------------------------------
// MARK: - JobDetailView
// ---------------------------------------------------------------
 Displays details for the selected JobApplication. 
// macOS window title to "CompanyName JobTitle" (no brackets).
// It also updates dynamically whenever 'job.id' changes,
// so if the user selects a different job, the window title
// will refresh.
// ---------------------------------------------------------------
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

                // Show job description
                // Job Description
                // Check if RTF data exists. If so, display the formatted text,
                // otherwise fall back to plain text. Same pattern for cover letter
                // and notes below.
                // ---------------------------------------------------------------
                if job.jobDescriptionRTFData != nil || !job.jobDescription.isEmpty {
                    Divider()
                    Text("Job Description")
                        .font(.headline)
                    Text(job.jobDescription)
                        .padding(4)
                }
                
                // Show cover letter
                if !job.coverLetter.isEmpty {
                    Divider()
                    Text("Cover Letter")
                        .font(.headline)
                    Text(job.coverLetter)
                        .padding(4)
                }

                // Show notes
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
        
        // We do not use .navigationTitle here, because we manually set the NSWindow title.
        
        // On appear, capture the NSWindow reference and set the title
        .onAppear {
            if windowRef == nil {
                if let keyWindow = NSApp.windows.first(where: { $0.isKeyWindow }) {
                    windowRef = keyWindow
                }
            }
            updateWindowTitle()
        }
        
        // Whenever the selected job's ID changes (i.e., user picks a different job),
        // refresh the window title to the new job's title.
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

        // QuickLook preview for documents
    private func revealInFinder(_ doc: JobDocument) {
        guard let fileURL = doc.fileURL else { return }
        .quickLookPreview($quickLookURL)
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
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
// -----------------------------------------------------
// MARK: - AddJobView
        if let fileURL = doc.fileURL {
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
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
    // Modify AddJobView
// MARK: - AddJobView
struct AddJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore

    @StateObject private var viewModel = JobViewModel()
    @Binding var isPresented: Bool
    @StateObject private var viewModel: JobViewModel

    init(isPresented: Binding<Bool>, jobData: [String: Any]? = nil) {
        self._isPresented = isPresented
        // Use a factory method to initialize the ViewModel
        self._viewModel = StateObject(wrappedValue: AddJobView.createViewModel(with: jobData))
    }

    @State private var importedDocuments: [JobDocument] = []
    @State private var isImporting = false
    @State private var locations: [String] = []
    @State private var showAddLocationSheet = false
    @State private var quickLookURL: URL? = nil



    var body: some View {
        VStack {
            Text("Add New Job")
                .font(.title2)
            TextField("Company Name", text: $viewModel.companyName)
            TextField("Job Title", text: $viewModel.jobTitle)
            TextField("Location", text: $viewModel.location)
            TextField("Link to Job", text: $viewModel.linkToJob)
            TextField("Job Description", text: $viewModel.jobDescription, axis: .vertical)
                .lineLimit(3, reservesSpace: true)
            TextField("Cover Letter", text: $viewModel.coverLetter, axis: .vertical)
                .lineLimit(3, reservesSpace: true)
            TextField("Notes", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3, reservesSpace: true)

            HStack {
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                Button("Add") {
                    // If we have any data from the Safari extension, 
                    // we can incorporate it here automatically if desired.
                    viewModel.addJob(to: jobStore, documents: [])
                    isPresented = false
                }
                .disabled(!viewModel.isInputValid)
            }
        }
        .padding()
        .onAppear {
            // If the user triggered this from the Safari extension,
            // jobStore.incomingJobData might have data to pre-populate
            if let incoming = jobStore.incomingJobData {
                // Pre-fill the fields if they are empty
                if viewModel.companyName.isEmpty {
                    viewModel.companyName = incoming["companyName"] as? String ?? ""
                }
                if viewModel.jobTitle.isEmpty {
                    viewModel.jobTitle = incoming["jobTitle"] as? String ?? ""
                }
                if viewModel.jobDescription.isEmpty {
                    viewModel.jobDescription = incoming["jobDescription"] as? String ?? ""
                }
                if viewModel.linkToJob.isEmpty {
                    viewModel.linkToJob = incoming["url"] as? String ?? ""
                }
            }
        }
    }
}

// -----------------------------------------------------
// MARK: - EditJobView
// -----------------------------------------------------
/**
 This view is used to modify an existing job entry.
 */
struct EditJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore

    @StateObject private var viewModel: JobViewModel
    @Binding var isPresented: Bool

    init(isPresented: Binding<Bool>, job: JobApplication) {
        self._isPresented = isPresented
        self._viewModel = StateObject(wrappedValue: JobViewModel(job: job))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Job")
                .font(.title)
            TextField("Company Name", text: $viewModel.companyName)
            TextField("Job Title", text: $viewModel.jobTitle)
            TextField("Location", text: $viewModel.location)
            TextField("Link to Job", text: $viewModel.linkToJob)
            TextField("Job Description", text: $viewModel.jobDescription, axis: .vertical)
                .lineLimit(3, reservesSpace: true)
            TextField("Cover Letter", text: $viewModel.coverLetter, axis: .vertical)
                .lineLimit(3, reservesSpace: true)
            TextField("Notes", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3, reservesSpace: true)

            HStack {
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                Button("Save") {
                    guard viewModel.isInputValid else { return }
                    // Create a new updated job
                    if let selectedJob = jobStore.selectedJob {
                        let updatedJob = JobApplication(
                            id: selectedJob.id,
                            companyName: viewModel.companyName,
                            jobTitle: viewModel.jobTitle,
                            status: viewModel.status,
                            dateOfApplication: viewModel.dateOfApplication,
                            location: viewModel.location,
                            linkToJobString: viewModel.linkToJob.isEmpty ? nil : viewModel.linkToJob,
                            jobDescription: viewModel.jobDescription,
                            coverLetter: viewModel.coverLetter,
                            notes: viewModel.notes,
                            documents: selectedJob.documents,
                            isFavorite: selectedJob.isFavorite
                        )
                        jobStore.editJob(with: updatedJob)
                    }
                    isPresented = false
                }
                .disabled(!viewModel.isInputValid)
            }
        }
        .padding()
    }
}
