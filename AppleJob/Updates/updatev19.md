//
//  AppleJob.swift
//  AppleJob
//
//  Created by Roger Lin on [Date].
//
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

enum Sort: String, CaseIterable {
    case title = "Job Title"
    case company = "Company Name"
    case recentlyApplied = "Recently Applied"
}

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

struct DocumentCategory: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var isExpanded: Bool = true

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

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

extension View {
    /**
     Applies a linear gradient fill to text, giving a more vivid look.
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

/**
 Manages the user's job applications, selection, and sorting. Published so SwiftUI updates on changes.
 */
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

/**
 Manages all documents (PDF, images, etc.), their categories, and the selected doc.
 */
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
            guard let data = try? Data(contentsOf: url) else { continue }
            let doc = JobDocument(fileName: url.lastPathComponent, fileData: data)
            if !documents.contains(doc) {
                documents.append(doc)
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
        var newDoc = JobDocument(
            fileName: "\(document.fileName)-copy",
            fileData: document.fileData,
            fileURL: document.fileURL
        )
        newDoc.categoryID = document.categoryID
        documents.append(newDoc)
        saveDocuments()
    }

    func deleteDocument(_ document: JobDocument) {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents.remove(at: index)
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
}

/**
 Simplifies file import/export for backups, documents, etc.
 */
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

/**
 A specialized view model for job creation and editing, providing field validation.
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

enum ViewSection: String, CaseIterable {
    case jobDetails = "Job Details"
    case stats = "Stats"
    case documents = "Documents"
}

/**
 The main container view with a sidebar (jobs, stats, documents)
 and a main content area that changes based on selection.
 */
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

/**
 A sidebar for job applications with search, add, edit, and delete options.
 */
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

/**
 A sidebar listing documents in "All Documents" plus categories, with drag-and-drop,
 highlight for selected doc, and a context menu for category assignment or deletion.
 */
struct DocumentsSidebarView: View {
    @EnvironmentObject var docStore: DocumentStore

    var body: some View {
        List(selection: $docStore.selectedDocument) {
            Section {
                DisclosureGroup("All Documents") {
                    ForEach(uncategorizedDocuments, id: \.id) { doc in
                        documentSidebarItem(doc)
                    }
                    .onMove(perform: moveDocsInAllDocs)
                }
                .font(.headline)
            }
            ForEach($docStore.categories, id: \.id) { $category in
                DisclosureGroup(isExpanded: $category.isExpanded) {
                    ForEach(docsForCategory(category.id), id: \.id) { doc in
                        documentSidebarItem(doc)
                    }
                    .onMove { indices, newOffset in
                        // Handle document rearrangement within the category if needed
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
        let isSelected = (docStore.selectedDocument == doc)
        return HStack {
            Image(systemName: "doc.text")
                .foregroundColor(.blue)
            Text(cleanFileName(doc.fileName))
                .foregroundColor(isSelected ? .white : .primary)
            Spacer()
        }
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .contextMenu {
            Button("Reveal in Finder") {
                revealInFinder(doc)
            }
            Button("Delete Document", role: .destructive) {
                docStore.deleteDocument(doc)
            }
        }
        .onTapGesture {
            docStore.selectedDocument = doc
        }
        .onDrag {
            NSItemProvider(object: doc.id.uuidString as NSString)
        }
        .onDrop(of: [.text], delegate: DocumentDropDelegate(docStore: docStore,
                                                            targetCategoryID: doc.categoryID,
                                                            document: doc))
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

    private func moveDocsInAllDocs(from source: IndexSet, to destination: Int) {
        var docs = uncategorizedDocuments
        docs.move(fromOffsets: source, toOffset: destination)
        // Update the order in the main documents array if necessary
        // Note: Implement reordering logic if needed
    }
}

struct DocumentDropDelegate: DropDelegate {
    let docStore: DocumentStore
    let targetCategoryID: UUID?
    let document: JobDocument

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [.text])
    }

    func dropEntered(info: DropInfo) { }

    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.text]).first else {
            return false
        }
        itemProvider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { data, error in
            guard let uuidString = data as? String, let docID = UUID(uuidString: uuidString) else { return }
            DispatchQueue.main.async {
                if let foundDoc = docStore.documents.first(where: { $0.id == docID }) {
                    // Assign or unassign document based on the target category
                    if let catID = targetCategoryID {
                        if let category = docStore.categories.first(where: { $0.id == catID }) {
                            docStore.assignDocument(foundDoc, to: category)
                        }
                    } else {
                        docStore.unassignDocument(foundDoc)
                    }
                }
            }
        }
        return true
    }
}

/**
 A sheet where the user can name a new category. Pressing "Save" creates it.
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

/**
 The main area for the Documents section. If a doc is selected, we show an embedded PDFKit view,
 removing the old "Preview Document" button so the PDF is always displayed inline.
 */
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
                PDFInlineViewer(fileData: doc.fileData)
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

/**
 A SwiftUI representable that displays a PDFKit PDFView inline,
 used specifically by `DocumentsMainView`.
 */
struct PDFInlineViewer: NSViewRepresentable {
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

/**
 Shows the details of a selected job: company, title, status, docs, jobDescription, etc.
 Maintains QuickLook usage for documents in horizontal scroll.
 */
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
                // Link to job posting
                if let link = job.linkToJobString, let url = URL(string: link) {
                    Link("View Job Posting", destination: url)
                }
                // Location
                if !job.location.isEmpty {
                    Text("Location: \(job.location)")
                        .font(.headline)
                }
                // Application date
                Text("Applied on: \(job.dateOfApplication.formatted(date: .abbreviated, time: .omitted))")
                // Documents
                if !job.documents.isEmpty {
                    Divider()
                    Text("#### Documents")
                        .font(.headline)
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(job.documents, id: \.id) { doc in
                                Button(action: {
                                    openQuickLook(doc)
                                }) {
                                    VStack {
                                        Image(systemName: "doc.text")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 50, height: 50)
                                            .foregroundColor(.blue)
                                        Text(cleanFileName(doc.fileName))
                                            .font(.caption)
                                            .lineLimit(1)
                                            .foregroundColor(.primary)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(nsColor: .windowBackgroundColor))
                                            .shadow(radius: 2)
                                    )
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
                // Job Description
                if !job.jobDescription.isEmpty {
                    Divider()
                    Text("#### Job Description")
                        .font(.headline)
                    Text(job.jobDescription)
                        .padding(4)
                }
                // Cover Letter
                if !job.coverLetter.isEmpty {
                    Divider()
                    Text("#### Cover Letter")
                        .font(.headline)
                    Text(job.coverLetter)
                }
                // Notes
                Divider()
                Text("#### Notes")
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
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(doc.fileName)
        do {
            try doc.fileData.write(to: tempURL)
            quickLookURL = tempURL
        } catch {
            print("Failed to open Quick Look: \(error)")
        }
    }

    private func revealInFinder(_ doc: JobDocument) {
        if let fileURL = doc.fileURL {
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        }
    }
}

/**
 A sheet to add a new job, letting the user fill out details and upload documents.
 */
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
        .quickLookPreview($quickLookURL)
    }

    private func openQuickLook(_ doc: JobDocument) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(doc.fileName)
        do {
            try doc.fileData.write(to: tempURL)
            quickLookURL = tempURL
        } catch {
            print("Failed to open Quick Look: \(error)")
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

/**
 A sheet to edit an existing job. Similar to AddJobView but pre-populated.
 */
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
        .quickLookPreview($quickLookURL)
    }

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

    private func openQuickLook(_ doc: JobDocument) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(doc.fileName)
        do {
            try doc.fileData.write(to: tempURL)
            quickLookURL = tempURL
        } catch {
            print("Failed to open Quick Look: \(error)")
        }
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

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .textCase(.uppercase)
    }
}

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

/**
 Displays job application stats. Now includes:
   • A map with city pins
   • GitHub-Style charts (with tooltips)
   • Time range picker
   • Bar + line charts (with tooltips)
   • Stacked bar chart for last 12 months by city (with tooltips)
 */
struct EnhancedStatsView: View {
    @EnvironmentObject var jobStore: JobStore
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 50)
    )
    @State private var cityPins: [CityPin] = []
    @State private var yearContributionData: [Contribution] = []
    @State private var appsContributionData: [Contribution] = []

    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case sixmonth = "Six Months"
        case year = "Year"
        var id: String { rawValue }
    }
    @State private var selectedTimeRange: TimeRange = .month
    @State private var barLineData: [DailyApps] = []
    @State private var monthlyCityData: [MonthlyCityData] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                mapSection
                statsRowSection
                githubChartsSection
                timeRangePickerSection
                barLineChartsSection
                stackedBarChartSection
                top20CompaniesBarSection
                citiesByFrequencySection
                companiesByFrequencySection
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

    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Applications Map")
                .font(.headline)
            Map(coordinateRegion: $region) {
                ForEach(cityPins) { cityPin in
                    Annotation(coordinate: cityPin.coordinate) {
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
            }
            .frame(height: 500)
            .cornerRadius(5)
        }
    }

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

    private var githubChartsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("GitHub-Style Contribution Charts")
                .font(.headline)
            if #available(macOS 13.0, *) {
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
                .chartOverlay { proxy in
                    // Handle hover or selection if needed
                    GeometryReader { geo in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .onHover { hovering in
                                // Implement hover interaction if needed
                            }
                    }
                }
                .frame(height: 180)
                .padding(.horizontal, 10)

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
                .chartOverlay { _ in
                    // Implement overlay if needed
                }
                .frame(height: 180)
                .padding(.horizontal, 10)
            } else {
                Text("Contribution chart requires macOS 13.0+.")
            }
        }
    }

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

    private var barLineChartsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Applications Frequency")
                .font(.headline)
            if #available(macOS 13.0, *) {
                ScrollView(.horizontal) {
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
                        .frame(width: max(CGFloat(barLineData.count * 50), 800))
                        .padding(.bottom, 49)
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
                    }
                    .padding(.horizontal, 16)
                }
                .frame(minHeight: 400)
                .frame(width: max(CGFloat(barLineData.count * 50), 800))
                .padding(.bottom, 49)
            } else {
                Text("Charts require macOS 13.0+.")
            }
        }
    }

    /**
     A stacked bar chart for the last 12 months, each bar is a month, stacked by city.
     */
    @ViewBuilder
    private var stackedBarChartSection: some View {
        if #available(macOS 13.0, *) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Applications by City (Stacked Bar, Last 12 Months)")
                    .font(.headline)
                Chart(monthlyCityData) { item in
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
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .onHover { hovering in
                                // Implement hover interaction if needed
                            }
                    }
                }
                .frame(minHeight: 300)
            }
        } else {
            Text("Stacked bar chart requires macOS 13.0+.")
        }
    }

    private var top20CompaniesBarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top 20 Companies by Application Frequency")
                .font(.headline)
            if #available(macOS 13.0, *) {
                ScrollView(.horizontal) {
                    let topCompanies = buildTop20CompanyFreq()
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
                    .frame(height: 400)
                    .frame(width: max(CGFloat(topCompanies.count * 60), 800))
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 32)
            } else {
                Text("Bar chart requires macOS 13.0+.")
            }
        }
    }

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

    private func buildTop20CompanyFreq() -> [CompanyFreq] {
        var freq: [String: Int] = [:]
        for app in jobStore.jobApplications {
            freq[app.companyName, default: 0] += 1
        }
        let sorted = freq.sorted { $0.value > $1.value }
        let top20 = sorted.prefix(20)
        return top20.map { CompanyFreq(name: $0.key, count: $0.value) }
    }

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

    private func computeMonthlyCityData() {
        let now = Date()
        let cal = Calendar.current
        var months: [Date] = []
        for i in 0..<12 {
            if let m = cal.date(byAdding: .month, value: -i, to: now),
               let startOfMonth = cal.dateInterval(of: .month, for: m)?.start {
                months.append(startOfMonth)
            }
        }
        months.sort()
        monthlyCityData.removeAll()
        let allApps = jobStore.jobApplications
        for monthStart in months {
            let comps = cal.dateComponents([.year, .month], from: monthStart)
            let mKey = "\(monthName(comps.month)) \(comps.year!)"
            guard let nextMonth = cal.date(byAdding: .month, value: 1, to: monthStart) else { continue }
            let appsInMonth = allApps.filter { $0.dateOfApplication >= monthStart && $0.dateOfApplication < nextMonth }
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
    }

    private func monthName(_ m: Int?) -> String {
        guard let m = m else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let comps = DateComponents(calendar: Calendar.current, year: 2023, month: m, day: 1)
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
}
