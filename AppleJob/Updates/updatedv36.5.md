//
//  AppleJob.swift
//  AppleJob
//
//  Created by Roger Lin on [Date].
//  Updated with requested features, chart fixes, persistent time range selection,
//  improved context menus, and a single-column stacked bar chart using Apple’s approach.
//
// -----------------------------------------------------
//  MARK: - Imports
// -----------------------------------------------------
import SwiftUI
import AppKit
import UniformTypeIdentifiers
import PDFKit
import MapKit
import Charts
import Quartz
import QuickLook
import QuickLookUI
import RichTextKit
import SwiftSoup

// -----------------------------------------------------
// MARK: - RICH TEXT SUPPORT VIEWS
// -----------------------------------------------------
// These helper views allow for RTF-based editing and display
// using NSTextView in SwiftUI (macOS). If you are on iOS,
// switch to UIViewRepresentable and UITextView accordingly.
//
struct RichTextEditor: NSViewRepresentable {
    @Binding var attributedText: NSAttributedString
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.isRichText = true
        textView.isEditable = true
        textView.allowsUndo = true
        textView.delegate = context.coordinator
        textView.font = NSFont.systemFont(ofSize: 13.0)  // default font
        textView.textStorage?.setAttributedString(attributedText)
        return textView
    }
    
    func updateNSView(_ nsView: NSTextView, context: Context) {
        // If the SwiftUI @State changes externally, update NSTextView
        if nsView.attributedString() != attributedText {
            nsView.textStorage?.setAttributedString(attributedText)
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditor
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            // Push changes back to SwiftUI
            parent.attributedText = textView.attributedString()
        }
    }
}

/// A simple read-only display for rich text (RTF or other NSAttributedString)
struct RichTextDisplay: NSViewRepresentable {
    let attributedString: NSAttributedString
    
    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textStorage?.setAttributedString(attributedString)
        return textView
    }
    
    func updateNSView(_ nsView: NSTextView, context: Context) {
        nsView.textStorage?.setAttributedString(attributedString)
    }
}

// Utility to convert NSAttributedString <-> RTF Data
func rtfData(from attributedString: NSAttributedString) -> Data? {
    let range = NSRange(location: 0, length: attributedString.length)
    return try? attributedString.data(from: range, documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
}

func attributedString(from rtfData: Data) -> NSAttributedString {
    (try? NSAttributedString(
        data: rtfData,
        options: [
            .documentType: NSAttributedString.DocumentType.rtf,
            .characterEncoding: String.Encoding.utf8.rawValue
        ],
        documentAttributes: nil
    )) ?? NSAttributedString(string: "")
}

// -----------------------------------------------------
// MARK: - JobStatus
// -----------------------------------------------------
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
        case .interview:  return .purple   // was .orange
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
// Updated to include optional RTF Data for jobDescription, coverLetter, notes
//
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

    // --------------------------
    // RTF Data for Rich Text
    // --------------------------
    var jobDescriptionRTFData: Data?
    var coverLetterRTFData: Data?
    var notesRTFData: Data?

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
        jobDescriptionRTFData: Data? = nil,
        coverLetterRTFData: Data? = nil,
        notesRTFData: Data? = nil,
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
        self.jobDescriptionRTFData = jobDescriptionRTFData
        self.coverLetterRTFData = coverLetterRTFData
        self.notesRTFData = notesRTFData
        self.documents = documents
        self.isFavorite = isFavorite
    }

    // MARK: - Codable Implementation
    // ------------------------------------------------
    // Coding/Decoding
    // ------------------------------------------------
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
        
        // Plain text fallback
        self.jobDescription = try container.decode(String.self, forKey: .jobDescription)
        self.coverLetter    = try container.decode(String.self, forKey: .coverLetter)
        self.notes          = try? container.decode(String.self, forKey: .notes)
        
        // Attempt to decode new RTF fields (if present), otherwise nil
        self.jobDescriptionRTFData = try? container.decode(Data.self, forKey: .jobDescriptionRTFData)
        self.coverLetterRTFData    = try? container.decode(Data.self, forKey: .coverLetterRTFData)
        self.notesRTFData          = try? container.decode(Data.self, forKey: .notesRTFData)

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
        
        // Plain text
        try container.encode(jobDescription, forKey: .jobDescription)
        try container.encode(coverLetter, forKey: .coverLetter)
        try container.encode(notes, forKey: .notes)

        // RTF data
        try container.encode(jobDescriptionRTFData, forKey: .jobDescriptionRTFData)
        try container.encode(coverLetterRTFData, forKey: .coverLetterRTFData)
        try container.encode(notesRTFData, forKey: .notesRTFData)
        
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
        // The new RTF fields
        case jobDescriptionRTFData
        case coverLetterRTFData
        case notesRTFData
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
 A model for an uploaded document. Preserves file creation & last modified metadata.
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

/// An example initializer could be:
/// .init(city: "New York City, NY", monthKey: "Jan 2023", count: 2, date: someDate)
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
            dateOfApplication: Date(),  // new date
            location: job.location,
            linkToJobString: job.linkToJobString,
            salary: job.salary,
            jobDescription: job.jobDescription,
            coverLetter: job.coverLetter,
            notes: job.notes,
            jobDescriptionRTFData: job.jobDescriptionRTFData,
            coverLetterRTFData: job.coverLetterRTFData,
            notesRTFData: job.notesRTFData,
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

// -----------------------------------------------------
// MARK: - DocumentStore
// -----------------------------------------------------
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
            try FileManager.default.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
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

// -----------------------------------------------------
// MARK: - ImportExportHelper
// -----------------------------------------------------
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

// -----------------------------------------------------
// MARK: - JobViewModel
// -----------------------------------------------------
class JobViewModel: ObservableObject {
    @Published var companyName: String = ""
    @Published var jobTitle: String = ""
    @Published var status: JobStatus = .interested
    @Published var dateOfApplication: Date = Date()
    @Published var location: String = ""
    @Published var linkToJob: String = ""
    
    // Plain text fallback
    @Published var jobDescription: String = ""
    @Published var coverLetter: String = ""
    @Published var notes: String = ""
    
    // Rich text storages for new RTF approach
    @Published var jobDescriptionRTF: NSAttributedString = NSAttributedString(string: "")
    @Published var coverLetterRTF: NSAttributedString = NSAttributedString(string: "")
    @Published var notesRTF: NSAttributedString = NSAttributedString(string: "")

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
        
        // Plain text fallback
        jobDescription = job.jobDescription
        coverLetter = job.coverLetter
        notes = job.notes ?? ""
        
        // RTF data (if any) -> NSAttributedString
        if let data = job.jobDescriptionRTFData {
            jobDescriptionRTF = attributedString(from: data)
        } else {
            jobDescriptionRTF = NSAttributedString(string: jobDescription)
        }
        if let data = job.coverLetterRTFData {
            coverLetterRTF = attributedString(from: data)
        } else {
            coverLetterRTF = NSAttributedString(string: coverLetter)
        }
        if let data = job.notesRTFData {
            notesRTF = attributedString(from: data)
        } else {
            notesRTF = NSAttributedString(string: notes)
        }

        validateInputs()
    }

    func validateInputs() {
        DispatchQueue.main.async {
            self.isInputValid = !(self.companyName.isEmpty || self.jobTitle.isEmpty)
        }
    }

    func addJob(to store: JobStore, documents: [JobDocument]) {
        guard isInputValid else { return }
        // Convert NSAttributedString -> RTF data
        let jobDescRTFData  = rtfData(from: jobDescriptionRTF)
        let coverLetRTFData = rtfData(from: coverLetterRTF)
        let notesRTFData    = rtfData(from: notesRTF)
        
        let newJob = JobApplication(
            companyName: companyName,
            jobTitle: jobTitle,
            status: status,
            dateOfApplication: dateOfApplication,
            location: location,
            linkToJobString: linkToJob.isEmpty ? nil : linkToJob,
            salary: nil,
            
            // plain text fallback
            jobDescription: jobDescriptionRTF.string,
            coverLetter: coverLetterRTF.string,
            notes: notesRTF.string,
            
            // RTF data
            jobDescriptionRTFData: jobDescRTFData,
            coverLetterRTFData: coverLetRTFData,
            notesRTFData: notesRTFData,
            
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
        jobDescriptionRTF = NSAttributedString(string: "")
        coverLetterRTF = NSAttributedString(string: "")
        notesRTF = NSAttributedString(string: "")
        validateInputs()
    }
}

// -----------------------------------------------------
// MARK: - Main App
// -----------------------------------------------------
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
        .onOpenURL(perform: handleIncomingURL)
        .commands {
            fileMenuCommands
            editMenuCommands
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "applejob" else { return }
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let jsonParam = components.queryItems?.first(where: { $0.name == "json" })?.value,
           let jsonDecoded = jsonParam.removingPercentEncoding?.data(using: .utf8) {
            do {
                if let dict = try JSONSerialization.jsonObject(with: jsonDecoded, options: []) as? [String: Any] {
                    handleIncomingJobData(dict)
                }
            } catch {
                print("Error parsing job data from extension: \(error)")
            }
        }
    }

    // Parse the dictionary we got from SafariWebExtensionHandler, then insert a new job
    private func handleIncomingJobData(_ dict: [String: Any]) {
        let newJob = buildJobFromDictionary(dict)
        jobStore.addJob(newJob)
    }

    private func buildJobFromDictionary(_ dict: [String: Any]) -> JobApplication {
        let jobTitle = dict["title"] as? String ?? "Untitled" // Adjust key as per API response
        let company = dict["company"] as? String ?? "(Unknown)"
        let link = dict["url"] as? String
        let jobDescription = dict["description"] as? String ?? ""
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
            jobDescriptionRTFData: nil,
            coverLetterRTFData: nil,
            notesRTFData: nil,
            documents: [],
            isFavorite: false
        )
    }


    // ----------------------------------------------------
    // Additional Menus & Commands
    // ----------------------------------------------------
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

    // ------------------------------------------------------
    // Updated Edit Menu Commands to include Document actions
    // ------------------------------------------------------
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
enum ViewSection: String, CaseIterable {
    case jobDetails = "Job Details"
    case stats = "Stats"
    case documents = "Documents"
}

// MARK: - ContentView
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

// MARK: - DocumentMetadataEditView
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
/**
 Replaces the background fill with Apple’s native primary background color
 so it does NOT dim or turn gray when app is inactive.
 */
// MARK: - SidebarItemView
// -----------------------------------------------
// This view shows each JobApplication in the Jobs sidebar
// with a "pill" that uses the status color. The background
// fill is adjusted so it doesn't dim on inactivity.
// -----------------------------------------------
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
                    jobStore.toggleFavorite(for: selectedJob.id)
                }
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

// MARK: - DocumentsSidebarView
// -----------------------------------------------
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
            Color.black.opacity(0.02)
                .blur(radius: 1.0)
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
        // Sheet for editing an existing category
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
        // QuickLook preview for selected document
        .quickLookPreview($docStore.quickLookURL)
    }

    // All documents without a category, sorted by lastModifiedDate (latest first)
    private var uncategorizedDocuments: [JobDocument] {
        docStore.documents
            .filter { $0.categoryID == nil }
            .sorted { $0.lastModifiedDate > $1.lastModifiedDate }
    }

    // Called by .onMove to reorder categories
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
// MARK: - DocumentsMainView
// -----------------------------------------------
// Shows either:
//   • A prompt if no docs exist
//   • A "Select a document" message if none is selected
//   • The selected doc's PDF view if present
//
// Dynamically sets the macOS window title to the doc's name
// instead of "AppleJob" or a static title.
// -----------------------------------------------
import SwiftUI
import AppKit // Required for NSApp, NSWindow
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
            // Update window title initially
            updateWindowTitle(doc: docStore.selectedDocument)
        }
        // Listen for changes in selectedDocument; update the title
        .onChange(of: docStore.selectedDocument) { _, newDoc in
            updateWindowTitle(doc: newDoc)
        }
        // Presents a sheet to edit metadata if user requests
        .sheet(isPresented: $docStore.isEditingMetadata) {
            if let docToEdit = docStore.documentToEdit {
                DocumentMetadataEditView(doc: docToEdit)
                    .environmentObject(docStore)
            }
        }
        .quickLookPreview($quickLookURL)
    }

    /// Shows an NSOpenPanel to select documents
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

    /// Update the window title to the cleaned file name or "Documents"
    private func updateWindowTitle(doc: JobDocument?) {
        guard let window = windowRef else { return }
        if let doc = doc {
            window.title = cleanFileName(doc.fileName)
        } else {
            window.title = "Documents"
        }
    }

    /// Example function removing certain file extensions / strings
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


// MARK: - JobDetailView
// ---------------------------------------------------------------
// Displays details of a selected JobApplication and sets the
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
  

    // MARK: - JobDetailView
    // ---------------------------------------------------------------
    // Displays details of a selected JobApplication and sets the
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
// Displays details of a selected JobApplication and sets the
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
                
                // ---------------------------------------------------------------
                // Job Description
                // Check if RTF data exists. If so, display the formatted text,
                // otherwise fall back to plain text. Same pattern for cover letter
                // and notes below.
                // ---------------------------------------------------------------
                if job.jobDescriptionRTFData != nil || !job.jobDescription.isEmpty {
                    Divider()
                    Text("Job Description")
                        .font(.headline)
                    
                    if let rtfData = job.jobDescriptionRTFData, !rtfData.isEmpty {
                        // Display rich text
                        RichTextDisplay(attributedString: attributedString(from: rtfData))
                            .padding(4)
                    } else {
                        // Fallback to plain text
                        Text(job.jobDescription)
                            .padding(4)
                    }
                }
                
                // Cover Letter
                if job.coverLetterRTFData != nil || !job.coverLetter.isEmpty {
                    Divider()
                    Text("Cover Letter")
                        .font(.headline)
                    
                    if let rtfData = job.coverLetterRTFData, !rtfData.isEmpty {
                        RichTextDisplay(attributedString: attributedString(from: rtfData))
                            .padding(4)
                    } else {
                        Text(job.coverLetter)
                            .padding(4)
                    }
                }
                
                // Notes
                Divider()
                Text("Notes")
                    .font(.headline)
                
                if let rtfData = job.notesRTFData, !rtfData.isEmpty {
                    RichTextDisplay(attributedString: attributedString(from: rtfData))
                        .padding(4)
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
        .onChange(of: job.id) { oldValue , newValue in
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
                    .onChange(of: viewModel.location) { _ , newValue in
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
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                }
                            }
                        }
                    }
                    Button("Upload Documents") {
                        isImporting = true
                    }

                    sectionHeader("JOB DESCRIPTION (Rich Text)")
                    RichTextEditor(attributedText: $viewModel.jobDescriptionRTF)
                        .font(.body)
                        .frame(minHeight: 80)
                        .cornerRadius(5)

                    sectionHeader("COVER LETTER (Rich Text)")
                    RichTextEditor(attributedText: $viewModel.coverLetterRTF)
                        .font(.body)
                        .frame(minHeight: 80)
                        .cornerRadius(5)

                    sectionHeader("NOTES (Rich Text)")
                    RichTextEditor(attributedText: $viewModel.notesRTF)
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
        // Initialize with existing job
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
                        .onChange(of: viewModel.companyName) {  _, _ in
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
                        ForEach(locations, id: \.self) { loc in
                            Text(loc)
                        }
                        Text("Add New Location").tag("Add New Location")
                    }
                    .onChange(of: viewModel.location) { _ , newValue in
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
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .contextMenu {
                                        Button("Reveal in Finder") {
                                            revealInFinder(doc)
                                        }
                                        Button("Edit Document Info") {
                                                if let doc = docStore.selectedDocument {
                                                    docStore.beginEditMetadata(for: doc)
                                                }
                                            }
                                            .disabled(docStore.selectedDocument == nil)

                                        Menu("Move to Category") {
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
                                        Button("Delete Document") {
                                            if let idx = importedDocuments.firstIndex(where: { $0.id == doc.id }) {
                                                importedDocuments.remove(at: idx)
                                                docStore.deleteDocument(doc)
                                            }
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
                                    lastModified: d.lastModifiedDate,
                                    fileSize: d.fileSize,
                                    wordCount: d.wordCount,
                                    categoryID: d.categoryID
                                )
                                savedDocs.append(newDoc)
                            } else {
                                savedDocs.append(d)
                            }
                        }
                        docStore.mergeDocuments(savedDocs)
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
                            documents: savedDocs,
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
        for extn in [".pdf", ".docx", ".pages"] {
            if cleanedName.hasSuffix(extn) {
                cleanedName = String(cleanedName.dropLast(extn.count))
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


// MARK: - EnhancedStatsView
/**
 The Stats & Analytics View:
   • A persistent time range for bar+line charts
   • A year picker without thousand separators
   • Charts made wide enough to fill horizontal space
   • Properly stacked city charts
   • Pie charts with legends on the right
   • Single-column vertically stacked bar chart now uses Swift Charts recommended approach:
       .foregroundStyle(by: .value("City", item.city))
       .chartForegroundStyleScale(...) if desired
 */
struct EnhancedStatsView: View {
    @EnvironmentObject var jobStore: JobStore

    // The map region
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 50)
    )

    // city pins
    @State private var cityPins: [CityPin] = []

    // year-based data for GitHub style
    @State private var yearContributionData: [Contribution] = []
    @State private var appsContributionData: [Contribution] = []

    // persistent time range selection
    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case sixmonth = "Six Months"
        case year = "Year"
        var id: String { rawValue }
    }

    @AppStorage("StatsViewTimeRange") private var selectedTimeRangeRaw: String = TimeRange.month.rawValue
    @State private var selectedTimeRange: TimeRange = .month

    // year picker
    @AppStorage("StatsViewSelectedYear") private var selectedYearForCharts: Int = {
        let current = Calendar.current.component(.year, from: Date())
        return min(max(current, 2021), 2025)
    }()

    // bar+line chart data
    @State private var barLineData: [DailyApps] = []

    // monthly city data
    @State private var monthlyCityData: [MonthlyCityData] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                mapSection
                statsRowSection

                // year picker
                yearPickerSection

                // GitHub style
                githubChartsSection

                // time range segmented
                timeRangePickerSection

                // bar+line
                barLineChartsSection

                // horizontally stacked
                horizontallyStackedBarChartSection

                // single column vertically stacked bar chart
                singleColumnVerticallyStackedBarChartSection

                // top 20
                top20CompaniesBarSection

                citiesByFrequencySection
                companiesByFrequencySection

                pieChartsSection
            }
            .padding()
        }
        .onAppear {
            if let tr = TimeRange(rawValue: selectedTimeRangeRaw) {
                selectedTimeRange = tr
            } else {
                selectedTimeRange = .month
            }
            computeCityPins()
            computeYearContribution()
            computeAppsContribution()
            computeBarLineData()
            computeMonthlyCityData()
        }
        .onChange(of: selectedTimeRange) { _ , newVal in
            selectedTimeRangeRaw = newVal.rawValue
            computeBarLineData()
        }
        .onChange(of: selectedYearForCharts) {  _, _ in
            computeYearContribution()
            computeAppsContribution()
            computeMonthlyCityData()
        }
        .navigationTitle("Stats & Analytics")
    }

    // MARK: - Map
    // MARK: - Map
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Applications Map")
                .font(.headline)
            
            Map {
                ForEach(cityPins) { cityPin in
                    // Add a descriptive label for accessibility
                    Annotation("City: \(cityPin.city)", coordinate: cityPin.coordinate) {
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
            .mapStyle(.standard) // Optional: Standard map style
            .frame(height: 500)
            .cornerRadius(5)
        }
    }

    // MARK: - Stats Row
    private var statsRowSection: some View {
        let totalApps = jobStore.jobApplications.count
        let appliedCount = jobStore.jobApplications.filter { $0.status == .applied }.count
        let interestedCount = jobStore.jobApplications.filter { $0.status == .interested }.count
        let interviewCount = jobStore.jobApplications.filter { $0.status == .interview }.count
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
                    Text("Interviews")
                    Text("\(interviewCount)")
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
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity

            )
            .padding(.vertical, 8)
        }
    }

    // MARK: - Year Picker
    private var yearPickerSection: some View {
        HStack {
            Text("Select Year:")
            Picker("Year", selection: $selectedYearForCharts) {
                ForEach(2021...2025, id: \.self) { yr in
                    // remove thousands separators
                    Text(verbatim:"\(yr)").tag(yr)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - GitHub-Style
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
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .frame(height: 180)

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
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .frame(height: 180)
            } else {
                Text("Contribution chart requires macOS 13.0+.")
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Time Range
    private var timeRangePickerSection: some View {
        HStack {
            Text("Select Time Range:")
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Bar+Line
    private var barLineChartsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Applications Frequency (Last 12 Months / Range)")
                .font(.headline)
            if #available(macOS 13.0, *) {
                            VStack(alignment: .leading) {
                                // Bar
                                Chart(barLineData) { dayItem in
                                    BarMark(
                                        x: .value("Date", dayItem.date),
                                        y: .value("Applications", dayItem.count)
                                    )
                                }
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: .month)) {
                                        AxisGridLine()
                                        AxisTick()
                                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                                    }
                                }
                                .frame(height: 300)
                            }
            } else {
                Text("Charts require macOS 13.0+.")
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity

        )

    }

    // MARK: - Horizontally Stacked
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
                        .position(by: .value("City", item.city))
                        .foregroundStyle(by: .value("City", item.city))
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic) {
                            AxisValueLabel()
                        }
                    }
                    .chartYAxis {
                        AxisMarks()
                    }
                    .frame(height: 300)

            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity

            )
                 }
        else {
            Text("Stacked bar chart requires macOS 13.0+.")
        }
    }

    // MARK: - Single Column Vertically Stacked
    @ViewBuilder
    private var singleColumnVerticallyStackedBarChartSection: some View {
        if #available(macOS 13.0, *) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Applications by City - Single Column Vertically Stacked Bar Chart")
                    .font(.headline)
                    Chart(monthlyCityDataFilteredForSelectedYear()) { item in
                        // We rely on the Swift Charts approach for stacking
                        BarMark(
                            x: .value("Month", item.monthKey),
                            y: .value("Count", item.count)
                        )
                        .foregroundStyle(by: .value("City", item.city))
                    }
                    // Optional: chartForegroundStyleScale for custom color mapping
                    // .chartForegroundStyleScale([
                    //     "New York City, NY": .pink,
                    //     "San Francisco, CA": .blue,
                    //     "Remote": .green
                    // ])
                    .chartXAxis {
                        AxisMarks()
                    }
                    .chartYAxis {
                        AxisMarks()
                    }
                    .frame(height: 300)

            
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
                   }
        else {
            Text("Stacked bar chart requires macOS 13.0+.")
        }
    }

    // MARK: - Top 20
    private var top20CompaniesBarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top 20 Companies by Application Frequency (All Years)")
                .font(.headline)
            if #available(macOS 13.0, *) {
                        Chart(buildTop20CompanyFreq()) { item in
                            BarMark(
                                x: .value("Company", item.name),
                                y: .value("Count", item.count)
                            )
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic)
                        }
                        .chartYAxis {
                            AxisMarks()
                        }
                        .frame(height: 180)


            } else {
                Text("Bar chart requires macOS 13.0+.")
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity

        )
       }

    // MARK: - Cities By Frequency
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
                                .frame(width: 100)
                                .gradientForeground(colors: [.blue, .purple])
                                .multilineTextAlignment(.center)
                            Text("\(item.count)")
                                .font(.title3)
                        }
                        .padding(6)
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity

                )
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Companies By Frequency
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
                                .frame(width: 100)
                                .gradientForeground(colors: [.blue, .purple])
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 100)
                            Text("\(item.count)")
                                .font(.title3)
                        }
                        .padding(6)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity

                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Pie Charts
    // MARK: - Pie Charts
    @ViewBuilder
    private var pieChartsSection: some View {
        if #available(macOS 13.0, *) {
            VStack(alignment: .center, spacing: 16) {
                Text("Application Shares (Pie Charts)")
                    .font(.headline)

                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(alignment: .center, spacing: 32) {
                        // Pie Chart by Month
                        VStack {
                            Text("Share by Month (\(selectedYearForCharts))")
                                .font(.subheadline)

                            Chart(monthlyShareData()) { item in
                                SectorMark(
                                    angle: .value("Count", item.count),
                                    innerRadius: .ratio(0.5)
                                )
                                .foregroundStyle(by: .value("Month", item.monthKey))
                                .annotation(position: .overlay) { // Labels placed on the segments
                                    if item.count > 0 {
                                        Text("\(item.monthKey)\n\(item.count)")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .chartLegend(position: .bottom) // Move legend below the chart
                            .frame(width: 400, height: 400)
                        }

                        // Pie Chart by City
                        VStack {
                            Text("Share by City (\(selectedYearForCharts))")
                                .font(.subheadline)

                            Chart(cityShareData()) { item in
                                SectorMark(
                                    angle: .value("Count", item.count),
                                    innerRadius: .ratio(0.5)
                                )
                                .foregroundStyle(by: .value("City", item.city))
                                .annotation(position: .overlay) { // Labels placed on the segments
                                    if item.count > 0 {
                                        Text("\(item.city)\n\(item.count)")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .chartLegend(position: .bottom) // Move legend below the chart
                            .frame(width: 400, height: 400)
                        }

                        // Pie Chart by Year
                        VStack {
                            Text("Share by Year")
                                .font(.subheadline)

                            Chart(yearlyShareData()) { item in
                                SectorMark(
                                    angle: .value("Count", item.count),
                                    innerRadius: .ratio(0.5)
                                )
                                .foregroundStyle(by: .value("Year", item.year))
                                .annotation(position: .overlay) { // Labels placed on the segments
                                    if item.count > 0 {
                                        Text("\(item.year)\n\(item.count)")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .chartLegend(position: .bottom) // Move legend below the chart
                            .frame(width: 400, height: 400)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            Text("Pie charts require macOS 13.0+.")
        }
    }

    // MARK: - Data Computations
    private func computeCityPins() {
        var cityCount: [String: Int] = [:]
        for job in jobStore.jobApplications {
            cityCount[job.location, default: 0] += 1
        }
        cityPins = cityCount.map { (city, ct) in
            let coord = CityCoordinateDictionary[city] ?? CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795)
            return CityPin(city: city, coordinate: coord, count: ct)
        }
    }

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

    private func computeBarLineData() {
        let now = Date()
        let cal = Calendar.current
        var earliestDate: Date?

        switch selectedTimeRange {
        case .week:
            earliestDate = cal.date(byAdding: .day, value: -7, to: now)
        case .month:
            earliestDate = cal.date(byAdding: .month, value: -1, to: now)
        case .sixmonth:
            earliestDate = cal.date(byAdding: .month, value: -6, to: now)
        case .year:
            earliestDate = cal.date(byAdding: .year, value: -1, to: now)
        }

        guard let start = earliestDate else {
            barLineData = []
            return
        }
        var dailyCount: [Date: Int] = [:]
        let filtered = jobStore.jobApplications.filter { $0.dateOfApplication >= start }
        for job in filtered {
            let day = cal.startOfDay(for: job.dateOfApplication)
            dailyCount[day, default: 0] += 1
        }
        let sortedKeys = dailyCount.keys.sorted()
        barLineData = sortedKeys.map { d in
            DailyApps(date: d, count: dailyCount[d] ?? 0)
        }
    }

    private func computeMonthlyCityData() {
        guard let startOfYear = Calendar.current.date(
            from: DateComponents(year: selectedYearForCharts, month: 1, day: 1)),
              let endOfYear = Calendar.current.date(
                from: DateComponents(year: selectedYearForCharts, month: 12, day: 31))
        else {
            monthlyCityData = []
            return
        }
        let cal = Calendar.current
        var months: [Date] = []
        var cursor = startOfYear
        while cursor <= endOfYear {
            months.append(cursor)
            if let nxt = cal.date(byAdding: .month, value: 1, to: cursor) {
                cursor = nxt
            } else {
                break
            }
        }
        let allApps = jobStore.jobApplications.filter {
            $0.dateOfApplication >= startOfYear && $0.dateOfApplication <= endOfYear
        }
        var temp: [MonthlyCityData] = []
        for monthStart in months {
            let comps = cal.dateComponents([.year, .month], from: monthStart)
            let mKey = "\(monthName(comps.month)) \(comps.year!)"
            guard let nextMonth = cal.date(byAdding: .month, value: 1, to: monthStart) else { continue }
            let appsInMonth = allApps.filter {
                $0.dateOfApplication >= monthStart && $0.dateOfApplication < nextMonth
            }
            let cityCount = Dictionary(grouping: appsInMonth, by: { $0.location }).mapValues { $0.count }
            for (city, ct) in cityCount {
                temp.append(MonthlyCityData(
                    monthKey: mKey,
                    city: city,
                    count: ct,
                    date: monthStart
                ))
            }
        }
        temp.sort { $0.date < $1.date }
        monthlyCityData = temp
    }

    private func monthlyCityDataFilteredForSelectedYear() -> [MonthlyCityData] {
        monthlyCityData
    }

    private func monthlyShareData() -> [MonthlyCityData] {
        let groups = Dictionary(grouping: monthlyCityDataFilteredForSelectedYear()) { $0.monthKey }
        let results = groups.map { (monthKey, records) -> MonthlyCityData in
            let sum = records.reduce(0) { $0 + $1.count }
            return MonthlyCityData(monthKey: monthKey, city: "", count: sum, date: Date())
        }
        return results.sorted { $0.monthKey < $1.monthKey }
    }
    private func yearlyShareData() -> [YearlyData] {
        let applications = jobStore.jobApplications
        let groupedByYear = Dictionary(grouping: applications, by: { Calendar.current.component(.year, from: $0.dateOfApplication) })
        return groupedByYear.map { (year, apps) in
            YearlyData(year: String(year), count: apps.count)
        }.sorted { $0.year < $1.year }
    }

    struct YearlyData: Identifiable {
        let id = UUID()
        let year: String
        let count: Int
    }
    private func cityShareData() -> [MonthlyCityData] {
        let groups = Dictionary(grouping: monthlyCityDataFilteredForSelectedYear()) { $0.city }
        let results = groups.map { (city, records) -> MonthlyCityData in
            let sum = records.reduce(0) { $0 + $1.count }
            return MonthlyCityData(monthKey: "", city: city, count: sum, date: Date())
        }
        return results.sorted { $0.count > $1.count }
    }

    private func buildTop20CompanyFreq() -> [CompanyFreq] {
        var freq: [String: Int] = [:]
        for app in jobStore.jobApplications {
            freq[app.companyName, default: 0] += 1
        }
        let sorted = freq.sorted { $0.value > $1.value }
        return sorted.prefix(20).map { CompanyFreq(name: $0.key, count: $0.value) }
    }

    private func cityFreqList() -> [(city: String, count: Int)] {
        let allCities = jobStore.jobApplications.map { $0.location }
        let freq = Dictionary(grouping: allCities, by: { $0 }).mapValues { $0.count }
        let arr = freq.map { ($0.key, $0.value) }
        return arr.sorted { $0.1 > $1.1 }
    }

    private func companyFreqList() -> [(name: String, count: Int)] {
        let allCompanies = jobStore.jobApplications.map { $0.companyName }
        let freq = Dictionary(grouping: allCompanies, by: { $0 }).mapValues { $0.count }
        let arr = freq.map { ($0.key, $0.value) }
        return arr.sorted { $0.1 > $1.1 }
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

    private func weekday(for date: Date) -> Int {
        Calendar.current.component(.weekday, from: date)
    }

    private func shortWeekdaySymbol(_ weekday: Int) -> String? {
        let symbols = Calendar.current.shortWeekdaySymbols
        guard weekday - 1 >= 0, weekday - 1 < symbols.count else { return nil }
        return symbols[weekday - 1]
    }

    private func topCompanyName() -> String {
        let all = jobStore.jobApplications.map { $0.companyName }
        let freq = Dictionary(grouping: all, by: { $0 }).mapValues { $0.count }
        let sorted = freq.sorted { $0.value > $1.value }
        return sorted.first?.key ?? "N/A"
    }

    private func topCity() -> (name: String, count: Int) {
        let all = jobStore.jobApplications.map { $0.location }
        let freq = Dictionary(grouping: all, by: { $0 }).mapValues { $0.count }
        let sorted = freq.sorted { $0.value > $1.value }
        if let first = sorted.first {
            return (first.key, first.value)
        }
        return ("N/A", 0)
    }

    private func monthName(_ m: Int?) -> String {
        guard let m = m else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        if let date = Calendar.current.date(from: DateComponents(year: selectedYearForCharts, month: m, day: 1)) {
            return formatter.string(from: date)
        }
        return ""
    }
}





