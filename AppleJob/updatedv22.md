//
//  AppleJob.swift
//  AppleJob
//
//  Created by Roger Lin on [Date].
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

// MARK: - JobStatus
enum JobStatus: String, CaseIterable, Codable {
    case interested = "Interested"
    case applied = "Applied"
    case interview = "Interview"
    case offer = "Offer"
    case rejection = "Rejection"

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

// MARK: - Sort
enum Sort: String, CaseIterable {
    case title = "Job Title"
    case company = "Company Name"
    case recentlyApplied = "Recently Applied"
}

// MARK: - JobApplication Model
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

    static func == (lhs: JobApplication, rhs: JobApplication) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - JobDocument
struct JobDocument: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var fileName: String
    var fileURL: URL?
    var fileData: Data
    var dateOfApplication: Date
    var lastModifiedDate: Date
    var fileSize: Int
    var wordCount: Int
    var categoryID: UUID?

    init(id: UUID = UUID(), fileName: String, fileData: Data, fileURL: URL? = nil) {
        self.id = id
        self.fileName = fileName
        self.fileURL = fileURL
        self.fileData = fileData
        self.dateOfApplication = Date()
        self.lastModifiedDate = Date()
        self.fileSize = fileData.count
        self.wordCount = 0
        self.categoryID = nil
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.fileName = try container.decode(String.self, forKey: .fileName)
        self.fileData = try container.decode(Data.self, forKey: .fileData)
        self.fileURL = try? container.decode(URL.self, forKey: .fileURL)
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
        case fileURL
        case dateOfApplication
        case lastModifiedDate
        case fileSize
        case wordCount
        case categoryID
    }
}

// MARK: - DocumentCategory
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
]

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

struct MonthlyCityData: Identifiable {
    let id = UUID()
    let monthKey: String
    let city: String
    let count: Int
    let date: Date
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
class JobStore: ObservableObject {
    @Published var jobApplications: [JobApplication] = []
    @Published var selectedJob: JobApplication? = nil
    @Published var isAddingNewJob = false
    @Published var isEditingJob = false
    @Published var sorting: Sort = .recentlyApplied

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

    func editJobNotes(with notes: String, for id: UUID) {
        if let index = jobApplications.firstIndex(where: { $0.id == id }) {
            jobApplications[index].notes = notes.isEmpty ? nil : notes
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

// MARK: - DocumentStore
class DocumentStore: ObservableObject {
    @Published var documents: [JobDocument] = []
    @Published var selectedDocument: JobDocument? = nil

    @Published var categories: [DocumentCategory] = []
    @Published var isCreatingNewCategory = false
    @Published var newCategoryName: String = "Category Name"

    @Published var quickLookURL: URL? = nil

    init() {
        loadDocuments()
        loadCategories()
    }

    func uploadDocuments(from urls: [URL]) {
        for url in urls {
            do {
                let data = try Data(contentsOf: url)
                if let savedURL = DocumentStore.saveDocumentToAppSupport(originalURL: url, fileName: url.lastPathComponent) {
                    let doc = JobDocument(fileName: url.lastPathComponent, fileData: data, fileURL: savedURL)
                    if !documents.contains(doc) {
                        documents.append(doc)
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
        guard let savedURL = DocumentStore.saveDocumentToAppSupport(originalURL: document.fileURL ?? URL(fileURLWithPath: ""), fileName: document.fileName) else {
            print("Failed to save duplicated document.")
            return
        }
        var newDoc = JobDocument(
            fileName: "\(document.fileName)-copy",
            fileData: document.fileData,
            fileURL: savedURL
        )
        newDoc.categoryID = document.categoryID
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

    static func saveDocumentToAppSupport(originalURL: URL, fileName: String) -> URL? {
        guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let documentsDirectory = appSupportURL.appendingPathComponent("Documents", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: documentsDirectory, withIntermediateDirectories: true, attributes: nil)
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
@MainActor
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
            jobDescription: jobDescription,
            coverLetter: coverLetter,
            notes: notes.isEmpty ? nil : notes,
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

// MARK: - Main App Struct
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
            Button("Create New Category") {
                docStore.newCategoryName = "Category Name"
                docStore.isCreatingNewCategory = true
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
enum ViewSection: String, CaseIterable {
    case jobDetails = "Job Details"
    case stats = "Stats"
    case documents = "Documents"
}

// MARK: - ContentView
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
            ToolbarItemGroup (placement: .principal){
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
struct JobSidebarView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var searchText: String

    var body: some View {
        List(selection: $jobStore.selectedJob) {
            ForEach(filteredJobs, id: \.id) { job in
                SidebarItemView(job: job, isSelected: Binding(
                    get: { jobStore.selectedJob == job },
                    set: { newValue in
                        if newValue {
                            jobStore.selectedJob = job
                        } else if jobStore.selectedJob == job {
                            jobStore.selectedJob = nil
                        }
                    }
                ))
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
        .sheet(isPresented: $jobStore.isAddingNewJob) {
            AddJobView(isPresented: $jobStore.isAddingNewJob)
                .environmentObject(jobStore)
                .environmentObject(docStore)
        }
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

// MARK: - SidebarItemView
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
                        .fill(isSelected ? .primary.opacity(0.8) : job.status.displayColor.opacity(0.2))
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
        .onTapGesture {
            isSelected.toggle()
        }
    }
}

// MARK: - DocumentsSidebarView
struct DocumentsSidebarView: View {
    @EnvironmentObject var docStore: DocumentStore

    var body: some View {
        List(selection: $docStore.selectedDocument) {
            Section {
                DisclosureGroup {
                    ForEach(uncategorizedDocuments, id: \.id) { doc in
                        documentSidebarItem(doc)
                    }
                }
                label: { Text("All Documents").font(.headline) }
            }
            ForEach($docStore.categories, id: \.id) { $category in
                DisclosureGroup(isExpanded: $category.isExpanded) {
                    ForEach(docsForCategory(category.id), id: \.id) { doc in
                        documentSidebarItem(doc)
                    }
                } label: {
                    Text(category.name).font(.headline)
                }
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Documents")
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
        .contextMenu {
            Button("Create New Category") {
                docStore.newCategoryName = "Category Name"
                docStore.isCreatingNewCategory = true
            }
        }
        .sheet(isPresented: $docStore.isCreatingNewCategory) {
            NewCategorySheet().environmentObject(docStore)
        }
        .quickLookPreview($docStore.quickLookURL)
    }

    private var uncategorizedDocuments: [JobDocument] {
        docStore.documents.filter { $0.categoryID == nil }
    }

    private func docsForCategory(_ catID: UUID) -> [JobDocument] {
        docStore.documents.filter { $0.categoryID == catID }
    }

    private func documentSidebarItem(_ doc: JobDocument) -> some View {
        Label {
            Text(cleanFileName(doc.fileName))
        } icon: {
            Image(systemName: "doc.text")
                .foregroundColor(.blue)
        }
        .contextMenu {
            Button("Reveal in Finder") {
                revealInFinder(doc)
            }
            Button("Delete Document") {
                docStore.deleteDocument(doc)
            }
        }
        .tag(doc)
    }

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

    private func revealInFinder(_ doc: JobDocument) {
        if let fileURL = doc.fileURL {
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        }
    }
}

// MARK: - NewCategorySheet
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
struct DocumentsMainView: View {
    @EnvironmentObject var docStore: DocumentStore

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
                PDFInlineViewer(fileURL: doc.fileURL, fileData: doc.fileData)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
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
}

// MARK: - PDFInlineViewer
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

// MARK: - JobDetailView
struct JobDetailView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    let job: JobApplication
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
                                Button(action: {
                                    openQuickLook(doc)
                                }) {
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
        .quickLookPreview($quickLookURL)
    }

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

    private func revealInFinder(_ doc: JobDocument) {
        if let fileURL = doc.fileURL {
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        }
    }
}

// MARK: - AddJobView
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
                    .onChange(of: viewModel.location) { newValue in
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
                                        .padding(8)
                                    }
                                    .buttonStyle(.bordered)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
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
                        var savedDocuments: [JobDocument] = []
                        for doc in importedDocuments {
                            if let originalURL = doc.fileURL,
                               let savedURL = DocumentStore.saveDocumentToAppSupport(originalURL: originalURL, fileName: doc.fileName) {
                                let savedDoc = JobDocument(fileName: doc.fileName, fileData: doc.fileData, fileURL: savedURL)
                                savedDocuments.append(savedDoc)
                            } else {
                                savedDocuments.append(doc)
                            }
                        }
                        docStore.mergeDocuments(savedDocuments)
                        viewModel.addJob(to: jobStore, documents: savedDocuments)
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
                        let doc = JobDocument(fileName: url.lastPathComponent, fileData: data, fileURL: url)
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
        let fileExtensions = [".pdf", ".docx", ".pages"]
        for extensionString in fileExtensions {
            if cleanedName.hasSuffix(extensionString) {
                cleanedName = String(cleanedName.dropLast(extensionString.count))
                break
            }
        }
        cleanedName = cleanedName.trimmingCharacters(in: .whitespaces)
        return cleanedName
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .textCase(.uppercase)
    }
}

// MARK: - EditJobView
struct EditJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var isPresented: Bool
    @StateObject private var viewModel: JobViewModel
    @State private var importedDocuments: [JobDocument] = []
    @State private var isImporting = false
    @State private var locations: [String] = []
    @State private var showAddLocationSheet = false
    @State private var quickLookURL: URL? = nil

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
                    .onChange(of: viewModel.location) { newValue in
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
                                        .padding(8)
                                    }
                                    .buttonStyle(.bordered)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .contextMenu {
                                        Button("Reveal in Finder") {
                                            revealInFinder(doc)
                                        }
                                        Button("Delete Document") {
                                            if let idx = importedDocuments.firstIndex(where: { $0.id == doc.id }) {
                                                importedDocuments.remove(at: idx)
                                                docStore.deleteDocument(doc)
                                            }
                                        }
                                    }
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
                        var savedDocuments: [JobDocument] = []
                        for doc in importedDocuments {
                            if let originalURL = doc.fileURL,
                               let savedURL = DocumentStore.saveDocumentToAppSupport(originalURL: originalURL, fileName: doc.fileName) {
                                let savedDoc = JobDocument(fileName: doc.fileName, fileData: doc.fileData, fileURL: savedURL)
                                savedDoc.categoryID = doc.categoryID
                                savedDocuments.append(savedDoc)
                            } else {
                                savedDocuments.append(doc)
                            }
                        }
                        docStore.mergeDocuments(savedDocuments)
                        let updatedJob = JobApplication(
                            id: viewModel.companyName == jobStore.selectedJob?.companyName ? jobStore.selectedJob?.id ?? UUID() : UUID(),
                            companyName: viewModel.companyName,
                            jobTitle: viewModel.jobTitle,
                            status: viewModel.status,
                            dateOfApplication: viewModel.dateOfApplication,
                            location: viewModel.location,
                            linkToJobString: viewModel.linkToJob.isEmpty ? nil : viewModel.linkToJob,
                            salary: nil,
                            jobDescription: viewModel.jobDescription,
                            coverLetter: viewModel.coverLetter,
                            notes: viewModel.notes.isEmpty ? nil : viewModel.notes,
                            documents: savedDocuments,
                            isFavorite: jobStore.selectedJob?.isFavorite ?? false
                        )
                        jobStore.editJob(with: updatedJob)
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
                        let doc = JobDocument(fileName: url.lastPathComponent, fileData: data, fileURL: url)
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

    private func revealInFinder(_ doc: JobDocument) {
        if let fileURL = doc.fileURL {
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
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
        let fileExtensions = [".pdf", ".docx", ".pages"]
        for extensionString in fileExtensions {
            if cleanedName.hasSuffix(extensionString) {
                cleanedName = String(cleanedName.dropLast(extensionString.count))
                break
            }
        }
        cleanedName = cleanedName.trimmingCharacters(in: .whitespaces)
        return cleanedName
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .textCase(.uppercase)
    }
}

// MARK: - NewLocationView
struct NewLocationView: View {
    @Binding var locations: [String]
    @Binding var selectedLocation: String
    @Binding var isPresented: Bool
    @State private var newLocationName: String = ""

    var body: some View {
        VStack {
            Text("Add Location")
                .font(.title2)
                .padding(.top)
            TextField("Location", text: $newLocationName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            HStack {
                Button("Cancel", role: .cancel) {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                .tint(.red)
                Spacer()
                Button("Save") {
                    let trimmed = newLocationName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty && !locations.contains(trimmed) {
                        locations.append(trimmed)
                        locations.sort()
                        selectedLocation = trimmed
                    }
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            .padding()
        }
        .frame(width: 300)
    }
}

//
// MARK: - EnhancedStatsView
//
/**
 Displays job application stats. Now includes:
   • A map with city pins
   • GitHub-Style charts (with tooltips)
   • Year picker (2021–2025)
   • Bar + line charts (with time range)
   • Applications by City - Horizontally Stacked Bar Chart
   • Applications by City - Single Column Vertically Stacked Bar Chart
   • A top 20 companies bar chart
   • Pie charts for monthly and city shares
 */
struct EnhancedStatsView: View {
    @EnvironmentObject var jobStore: JobStore

    // The region for our map.
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 50)
    )

    // Data for city pins
    @State private var cityPins: [CityPin] = []

    // Data for "GitHub-Style" year-based contributions
    @State private var yearContributionData: [Contribution] = []
    @State private var appsContributionData: [Contribution] = []

    // Let users pick a year from 2021...2025 (for the contribution charts, stacked bars, pie charts).
    @State private var selectedYearForCharts: Int = {
        // default to current year, or 2023 if you prefer
        let currentYear = Calendar.current.component(.year, from: Date())
        return min(max(currentYear, 2021), 2025)
    }()

    // Time range for the bar+line chart only
    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case sixmonth = "Six Months"
        case year = "Year"
        var id: String { rawValue }
    }
    @State private var selectedTimeRange: TimeRange = .month

    // For bar + line chart data (time range)
    @State private var barLineData: [DailyApps] = []

    // For the monthly city data over the last 12 months
    @State private var monthlyCityData: [MonthlyCityData] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // 1) Map
                mapSection

                // 2) Horizontal stats row
                statsRowSection

                // 3) Year picker for the big charts
                yearPickerSection

                // 4) GitHub-Style Contribution Charts (using selected year)
                githubChartsSection

                // 5) Time range for bar + line
                timeRangePickerSection

                // 6) Bar+Line Charts (always full width, horizontally scrollable)
                barLineChartsSection

                // 7) Applications by City - Horizontally Stacked Bar Chart
                horizontallyStackedBarChartSection

                // 8) Applications by City - Single Column Vertically Stacked Bar Chart
                singleColumnVerticallyStackedBarChartSection

                // 9) Top 20 Companies bar chart (full width)
                top20CompaniesBarSection

                // 10) Cities By Frequency (horizontal scroll)
                citiesByFrequencySection

                // 11) Companies By Frequency (horizontal scroll)
                companiesByFrequencySection

                // 12) Pie Charts (monthly share + city share) in a horizontal stack
                pieChartsSection
            }
            .padding()
        }
        .onAppear {
            computeCityPins()
            computeYearContribution()
            computeAppsContribution()
            computeBarLineData()
            computeMonthlyCityData()
        }
        .navigationTitle("Stats & Analytics")
    }

    // MARK: - 1) Map
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
            .frame(height: 500)
            .cornerRadius(5)
        }
    }

    // MARK: - 2) Stats Row
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
                    Text("Top City")
                    Text("\(topCityData.name)")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(gradient)
                    Text("\(topCityData.count)")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(gradient)
                }
                .font(.callout)
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - 3) Year Picker
    private var yearPickerSection: some View {
        HStack {
            Text("Select Year:")
            Picker("Year", selection: $selectedYearForCharts) {
                ForEach(2021...2025, id: \.self) { yr in
                    Text("\(yr)").tag(yr)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedYearForCharts) { _ in
                // Recompute the year-based contributions, monthly city data, pie chart data, etc.
                computeYearContribution()
                computeAppsContribution()
                computeMonthlyCityData()
            }
        }
    }

    // MARK: - 4) GitHub-Style Contribution Charts
    private var githubChartsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("GitHub-Style Contribution Charts")
                .font(.headline)
            if #available(macOS 13.0, *) {
                // First chart: simplified daily progress
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
                .padding(.horizontal, 16)

                // Second chart: real application counts
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
                .padding(.horizontal, 16)

            } else {
                Text("Contribution chart requires macOS 13.0+.")
            }
        }
    }

    // MARK: - 5) Time Range Picker
    private var timeRangePickerSection: some View {
        HStack {
            Picker("Select Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedTimeRange) { _ in
                computeBarLineData()
            }
        }
    }

    // MARK: - 6) Bar + Line Charts
    private var barLineChartsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Applications Frequency")
                .font(.headline)
            if #available(macOS 13.0, *) {
                ScrollView(.horizontal) {
                    GeometryReader { geo in
                        VStack(alignment: .leading, spacing: 24) {
                            // Bar Chart
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
                            .frame(height: 200)

                            // Line Chart
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
                            .frame(height: 200)
                        }
                        .padding(.vertical, 16)
                        .frame(width: geo.size.width) // fill the entire available width
                    }
                    .frame(height: 450) // overall height for both charts
                }
                .padding(.horizontal, 16)

            } else {
                Text("Charts require macOS 13.0+.")
            }
        }
    }

    // MARK: - 7) Horizontally Stacked Bar Chart
    @ViewBuilder
    private var horizontallyStackedBarChartSection: some View {
        if #available(macOS 13.0, *) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Applications by City - Horizontally Stacked Bar Chart")
                    .font(.headline)
                Chart(monthlyCityDataFilteredForSelectedYear()) { item in
                    BarMark(
                        x: .value("Month", item.monthKey),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(by: .value("City", item.city))
                    .position(by: .value("City", item.city))
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) {
                        AxisValueLabel()
                    }
                }
                .chartYAxis {
                    AxisMarks()
                }
                .frame(minHeight: 300)
                .padding(.horizontal, 16)
            }
        } else {
            Text("Stacked bar chart requires macOS 13.0+.")
        }
    }

    // MARK: - 8) Single Column Vertically Stacked Bar Chart
    @ViewBuilder
    private var singleColumnVerticallyStackedBarChartSection: some View {
        if #available(macOS 13.0, *) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Applications by City - Single Column Vertically Stacked Bar Chart")
                    .font(.headline)

                // We'll pivot the data so that each month is a single column,
                // and the height is the sum of city counts stacked vertically.
                Chart(monthlyCityDataFilteredForSelectedYear()) { item in
                    BarMark(
                        x: .value("Month", item.monthKey),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(by: .value("City", item.city))
                    .position(by: .value("City", item.city))
                }
                .chartXAxis {
                    AxisMarks()
                }
                .chartYAxis {
                    AxisMarks()
                }
                .frame(minHeight: 300)
                .padding(.horizontal, 16)
            }
        } else {
            Text("Stacked bar chart requires macOS 13.0+.")
        }
    }

    // MARK: - 9) Top 20 Companies Bar
    private var top20CompaniesBarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top 20 Companies by Application Frequency")
                .font(.headline)
            if #available(macOS 13.0, *) {
                ScrollView(.horizontal) {
                    GeometryReader { geo in
                        Chart(buildTop20CompanyFreq()) { item in
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
                        .frame(width: geo.size.width, height: 400)
                    }
                    .frame(height: 400)
                }
                .padding(.horizontal, 16)
            } else {
                Text("Bar chart requires macOS 13.0+.")
            }
        }
    }

    // MARK: - 10) Cities By Frequency
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
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 100)
                            Text("\(item.count)")
                                .font(.title3)
                        }
                        .padding(6)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - 11) Companies By Frequency
    private var companiesByFrequencySection: some View {
        let companies = companyFreqList()
        return VStack(alignment: .leading, spacing: 12) {
            Text("Companies By Frequency")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 24) {
                    ForEach(companies, id: \.name) { item in
                        VStack {
                            Text(item.name)
                                .font(.headline)
                                .gradientForeground(colors: [.blue, .purple])
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 100)
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

    // MARK: - 12) Pie Charts
    @ViewBuilder
    private var pieChartsSection: some View {
        if #available(macOS 13.0, *) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Application Shares (Pie Charts)")
                    .font(.headline)

                HStack(alignment: .center, spacing: 32) {
                    // Pie chart for monthly share
                    VStack {
                        Text("Share by Month (\(selectedYearForCharts))")
                            .font(.subheadline)
                        Chart(monthlyShareData()) { item in
                            SectorMark(
                                angle: .value("Count", item.count),
                                innerRadius: .ratio(0.5)
                            )
                            .foregroundStyle(by: .value("Month", item.monthKey))
                            .annotation(position: .overlay) {
                                if item.count > 0 {
                                    Text("\(item.monthKey)\n\(item.count)")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .frame(width: 250, height: 250)
                    }

                    // Pie chart for city share
                    VStack {
                        Text("Share by City (\(selectedYearForCharts))")
                            .font(.subheadline)
                        Chart(cityShareData()) { item in
                            SectorMark(
                                angle: .value("Count", item.count),
                                innerRadius: .ratio(0.5)
                            )
                            .foregroundStyle(by: .value("City", item.city))
                            .annotation(position: .overlay) {
                                if item.count > 0 {
                                    Text("\(item.city) \n\(item.count)")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .frame(width: 250, height: 250)
                    }
                }
                .padding(.horizontal, 16)
            }
        } else {
            Text("Pie charts require macOS 13.0+.")
        }
    }

    // MARK: - Data Computation

    /** Build city pins to show on the map. */
    private func computeCityPins() {
        var cityCount: [String: Int] = [:]
        for job in jobStore.jobApplications {
            let c = job.location
            cityCount[c, default: 0] += 1
        }
        cityPins = cityCount.map { (city, ct) in
            let coord = CityCoordinateDictionary[city] ?? CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795)
            return CityPin(city: city, coordinate: coord, count: ct)
        }
    }

    /**
     Compute the "yearContributionData": a daily array of up to 365 or 366 items,
     each assigned count=1 if day <= today, else 0, for the selected year.
     */
    private func computeYearContribution() {
        let cal = Calendar.current
        guard let startOfYear = cal.date(from: DateComponents(year: selectedYearForCharts, month: 1, day: 1)),
              let endOfYear = cal.date(from: DateComponents(year: selectedYearForCharts, month: 12, day: 31)) else {
            yearContributionData = []
            return
        }
        let now = Date()
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

    /**
     Compute the "appsContributionData": for the selected year, how many apps
     were filed each day?
     */
    private func computeAppsContribution() {
        let cal = Calendar.current
        guard let startOfYear = cal.date(from: DateComponents(year: selectedYearForCharts, month: 1, day: 1)),
              let endOfYear = cal.date(from: DateComponents(year: selectedYearForCharts, month: 12, day: 31)) else {
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

    /** Build top 20 companies. */
    private func buildTop20CompanyFreq() -> [CompanyFreq] {
        var freq: [String: Int] = [:]
        for app in jobStore.jobApplications {
            freq[app.companyName, default: 0] += 1
        }
        let sorted = freq.sorted { $0.value > $1.value }
        let top20 = sorted.prefix(20)
        return top20.map { CompanyFreq(name: $0.key, count: $0.value) }
    }

    /**
     For the bar+line charts, filter by the selectedTimeRange (week, month, six-month, year).
     */
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
            case .sixmonth:
                return date >= calendar.date(byAdding: .month, value: -6, to: now)!
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
        for (day, ct) in dayCount {
            data.append(DailyApps(date: day, count: ct))
        }
        data.sort { $0.date < $1.date }
        barLineData = data
    }

    /**
     For monthly city data, gather all job applications for the selected year.
     Then group them by month + city.
     */
    private func computeMonthlyCityData() {
        guard let startOfYear = Calendar.current.date(from: DateComponents(year: selectedYearForCharts, month: 1, day: 1)),
              let endOfYear = Calendar.current.date(from: DateComponents(year: selectedYearForCharts, month: 12, day: 31)) else {
            monthlyCityData = []
            return
        }
        let cal = Calendar.current
        var allMonths: [Date] = []
        var cursor = startOfYear
        while cursor <= endOfYear {
            allMonths.append(cursor)
            if let nextMonth = cal.date(byAdding: .month, value: 1, to: cursor) {
                cursor = nextMonth
            } else {
                break
            }
        }
        monthlyCityData.removeAll()
        let allApps = jobStore.jobApplications.filter {
            $0.dateOfApplication >= startOfYear && $0.dateOfApplication <= endOfYear
        }
        for monthStart in allMonths {
            let comps = cal.dateComponents([.year, .month], from: monthStart)
            let mKey = "\(monthName(comps.month)) \(comps.year!)"
            guard let nextMonth = cal.date(byAdding: .month, value: 1, to: monthStart) else { continue }
            let appsInMonth = allApps.filter {
                $0.dateOfApplication >= monthStart && $0.dateOfApplication < nextMonth
            }
            let cityCount = Dictionary(grouping: appsInMonth, by: { $0.location }).mapValues { $0.count }
            for (city, ct) in cityCount {
                monthlyCityData.append(MonthlyCityData(
                    monthKey: mKey,
                    city: city,
                    count: ct,
                    date: monthStart
                ))
            }
        }
        // Sort by date ascending for consistency
        monthlyCityData.sort { $0.date < $1.date }
    }

    /** Filter monthlyCityData to only the relevant year. (We do this again just in case.) */
    private func monthlyCityDataFilteredForSelectedYear() -> [MonthlyCityData] {
        monthlyCityData
    }

    /** For pie chart: monthly share of apps in the selected year. */
    private func monthlyShareData() -> [MonthlyCityData] {
        let groupedByMonth = Dictionary(grouping: monthlyCityDataFilteredForSelectedYear()) { $0.monthKey }
            .mapValues { records -> Int in
                records.reduce(0) { $0 + $1.count }
            }
        // Convert to array of MonthlyCityData, ignoring city since we'll just store the total in 'count'.
        return groupedByMonth.map { monthKey, totalCount in
            // We'll reuse 'city' field just as an empty string, or we can define a new struct if needed.
            MonthlyCityData(monthKey: monthKey, city: "", count: totalCount, date: Date())
        }
        .sorted { $0.monthKey < $1.monthKey }
    }

    /** For pie chart: city share of apps in the selected year. */
    private func cityShareData() -> [MonthlyCityData] {
        let groupedByCity = Dictionary(grouping: monthlyCityDataFilteredForSelectedYear()) { $0.city }
            .mapValues { records -> Int in
                records.reduce(0) { $0 + $1.count }
            }
        return groupedByCity.map { city, totalCount in
            MonthlyCityData(monthKey: "", city: city, count: totalCount, date: Date())
        }
        .sorted { $0.count > $1.count }
    }

    // MARK: - Helper Functions
    private func monthName(_ m: Int?) -> String {
        guard let m = m else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let comps = DateComponents(calendar: Calendar.current, year: selectedYearForCharts, month: m, day: 1)
        if let date = Calendar.current.date(from: comps) {
            return formatter.string(from: date)
        }
        return ""
    }

    private func weekday(for date: Date) -> Int {
        let cal = Calendar.current
        return cal.component(.weekday, from: date)
    }

    private func shortWeekdaySymbol(_ weekday: Int) -> String? {
        let symbols = Calendar.current.shortWeekdaySymbols
        if weekday - 1 >= 0, weekday - 1 < symbols.count {
            return symbols[weekday - 1]
        }
        return nil
    }

    private func topCompanyName() -> String {
        let companies = jobStore.jobApplications.map { $0.companyName }
        let freq = Dictionary(grouping: companies, by: { $0 }).mapValues { $0.count }
        let sorted = freq.sorted { $0.value > $1.value }
        return sorted.first?.key ?? "N/A"
    }

    private func topCity() -> (name: String, count: Int) {
        let allCities = jobStore.jobApplications.map { $0.location }
        let freq = Dictionary(grouping: allCities, by: { $0 }).mapValues { $0.count }
        let sorted = freq.sorted { $0.value > $1.value }
        if let first = sorted.first {
            return (first.key, first.value)
        }
        return ("N/A", 0)
    }

    private func cityFreqList() -> [(city: String, count: Int)] {
        let allCities = jobStore.jobApplications.map { $0.location }
        let freq = Dictionary(grouping: allCities, by: { $0 }).mapValues { $0.count }
        return freq.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }

    private func companyFreqList() -> [(name: String, count: Int)] {
        let allCompanies = jobStore.jobApplications.map { $0.companyName }
        let freq = Dictionary(grouping: allCompanies, by: { $0 }).mapValues { $0.count }
        return freq.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }

    @available(macOS 13.0, *)
    private var chartColors: [Color] {
        [
            Color.green.opacity(0.2),
            Color.green.opacity(0.3),
            Color.green.opacity(0.4),
            Color.green.opacity(0.5),
            Color.green.opacity(0.6),
            Color.green.opacity(0.7),
            Color.green.opacity(0.8),
            Color.green
        ]
    }
}
