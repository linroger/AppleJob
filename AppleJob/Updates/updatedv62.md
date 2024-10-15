
import SwiftUI
import AppKit
import UniformTypeIdentifiers
import PDFKit
import MapKit
import Charts
import Quartz
import QuickLook
import QuickLookUI
import MarkdownKit // Import MarkdownKit - Step 1.2

/**
 The AppDelegate handles custom URLs:
 We rely on application(_:open:) to capture applejob:// URLs.
 */
class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        print("AppDelegate: application(_:open:) called with URL: \(urls)")
        guard let url = urls.first else { return }
        NotificationCenter.default.post(name: .didOpenCustomURL, object: url)
    }
}

extension Notification.Name {
    static let didOpenCustomURL = Notification.Name("didOpenCustomURL")
}

/**
 Represents the status of a job application.
 */
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
        case .interview:  return .purple
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

/**
 Enum for job type. 
 */
enum JobType: String, CaseIterable, Codable {
    case internship = "Internship"
    case fullTime = "Full Time"
    case offCycleInternship = "Off-Cycle Internship"
}

/**
 A model representing a single job application.

 We keep plain text for jobDescription, coverLetter, and notes.
 Added:
   - foundSkillIDs to track discovered skills
   - jobType to store whether it's an internship, full time, or off-cycle
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

    var jobDescription: String
    var coverLetter: String
    var notes: String?

    var isFavorite: Bool
    var documents: [JobDocument]

    /// Store discovered skills by their UUID
    var foundSkillIDs: [UUID]

    /// Store job type: internship, full time, or off-cycle
    var jobType: JobType

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
        isFavorite: Bool = false,
        foundSkillIDs: [UUID] = [],
        jobType: JobType = .fullTime
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
        self.foundSkillIDs = foundSkillIDs
        self.jobType = jobType
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
        self.coverLetter    = try container.decode(String.self, forKey: .coverLetter)
        self.notes          = try? container.decode(String.self, forKey: .notes)

        self.isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        self.documents  = try container.decode([JobDocument].self, forKey: .documents)

        self.foundSkillIDs = (try? container.decode([UUID].self, forKey: .foundSkillIDs)) ?? []

        // jobType
        if let jobTypeRaw = try? container.decode(String.self, forKey: .jobTypeRaw) {
            self.jobType = JobType(rawValue: jobTypeRaw) ?? .fullTime
        } else {
            self.jobType = .fullTime
        }
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
        try container.encode(foundSkillIDs, forKey: .foundSkillIDs)
        try container.encode(jobType.rawValue, forKey: .jobTypeRaw)
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
        case foundSkillIDs
        case jobTypeRaw
    }

    static func == (lhs: JobApplication, rhs: JobApplication) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/**
 A model for uploaded documents. Preserves file metadata and data.
 */
struct JobDocument: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var fileName: String
    var fileURL: URL?
    var fileData: Data

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
    "Century City, CA":  CLLocationCoordinate2D(latitude: 34.0618409, longitude: -118.415054),
    "Las Vegas, NV":     CLLocationCoordinate2D(latitude: 36.1188, longitude: -115.1776),
    "Westport, CT":      CLLocationCoordinate2D(latitude: 41.126426, longitude: -73.329076),
    "Miami, FL":         CLLocationCoordinate2D(latitude: 25.7619089, longitude: -80.1912006),
    "Menlo Park, CA":    CLLocationCoordinate2D(latitude: 37.4519671, longitude: -122.177992),
    "Dallas, TX":        CLLocationCoordinate2D(latitude: 32.7762719, longitude: -96.7968559),
    "Global":            CLLocationCoordinate2D(latitude: 34.149884, longitude: -118.056932)
]

struct MonthlyCityData: Identifiable {
    let id = UUID()
    let monthKey: String
    let city: String
    let count: Int
    let date: Date
}

struct YearlyData: Identifiable {
    let id = UUID()
    let year: String
    let count: Int
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

/**
 Manages a collection of JobApplication items, including load/save from UserDefaults.
 */
class JobStore: ObservableObject {
    @Published var jobApplications: [JobApplication] = []
    @Published var selectedJob: JobApplication? = nil
    @Published var isAddingNewJob = false
    @Published var isEditingJob = false
    @Published var sorting: Sort = .recentlyApplied
    @Published var incomingJobData: [String: Any]? = nil

    // For multi-selection in the sidebar
    @Published var selectedJobIDs: Set<JobApplication.ID> = []

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
            isFavorite: job.isFavorite,
            foundSkillIDs: job.foundSkillIDs,
            jobType: job.jobType
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

    func setJobType(for jobIDs: Set<UUID>, to type: JobType) {
        for id in jobIDs {
            if let index = jobApplications.firstIndex(where: { $0.id == id }) {
                jobApplications[index].jobType = type
            }
        }
        saveJobs()
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
 Manages a collection of JobDocument items, as well as categories.
 */
class DocumentStore: ObservableObject {
    @Published var documents: [JobDocument] = []
    @Published var selectedDocument: JobDocument? = nil

    @Published var categories: [DocumentCategory] = []
    @Published var isCreatingNewCategory = false
    @Published var newCategoryName: String = "Category Name"

    @Published var quickLookURL: URL? = nil

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
 Skill struct for "Desired Skills." 
 Aliases remain hidden in all views except AddAliasView. 
 */
struct Skill: Identifiable, Codable, Equatable {
    let id: UUID
    var displayName: String
    var aliases: [String]

    init(id: UUID = UUID(), displayName: String, aliases: [String] = []) {
        self.id = id
        self.displayName = displayName
        self.aliases = aliases
    }
}

/**
 Manages all desired skills, including the logic to parse job descriptions
 for each skill or alias, and updates each job’s foundSkillIDs accordingly.
 */
class SkillsStore: ObservableObject {
    @Published var skills: [Skill] = [] {
        didSet {
            saveSkills()
        }
    }

    init() {
        loadSkills()
    }

    func addSkill(_ displayName: String, jobStore: JobStore) -> Skill {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return Skill(id: UUID(), displayName: "")
        }
        // see if skill exists
        if let existing = skills.first(where: { $0.displayName.lowercased() == trimmed.lowercased() }) {
            parseAllJobs(for: existing, jobStore: jobStore)
            return existing
        }
        let newSkill = Skill(displayName: trimmed)
        skills.append(newSkill)
        parseAllJobs(for: newSkill, jobStore: jobStore)
        return newSkill
    }

    func addAliases(_ aliasesText: String, to skill: Skill, jobStore: JobStore) {
        guard let index = skills.firstIndex(where: { $0.id == skill.id }) else { return }
        let splitted = aliasesText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var currentAliases = Set(skills[index].aliases.map { $0.lowercased() })
        for alias in splitted {
            currentAliases.insert(alias.lowercased())
        }
        skills[index].aliases = currentAliases.map { $0 }
        parseAllJobs(for: skills[index], jobStore: jobStore)
    }

    func parseAllJobs(for skill: Skill, jobStore: JobStore) {
        let name = skill.displayName.lowercased()
        let aliases = skill.aliases.map { $0.lowercased() }

        for i in 0..<jobStore.jobApplications.count {
            let desc = jobStore.jobApplications[i].jobDescription.lowercased()
            let skillFound = desc.contains(name) || aliases.contains(where: { desc.contains($0) })
            if skillFound {
                if !jobStore.jobApplications[i].foundSkillIDs.contains(skill.id) {
                    jobStore.jobApplications[i].foundSkillIDs.append(skill.id)
                }
            } else {
                if let idx = jobStore.jobApplications[i].foundSkillIDs.firstIndex(of: skill.id) {
                    jobStore.jobApplications[i].foundSkillIDs.remove(at: idx)
                }
            }
        }
        jobStore.saveJobs()
    }

    func saveSkills() {
        do {
            let data = try JSONEncoder().encode(skills)
            UserDefaults.standard.set(data, forKey: "skills")
        } catch {
            print("Failed to save skills: \(error.localizedDescription)")
        }
    }

    func loadSkills() {
        guard let data = UserDefaults.standard.data(forKey: "skills") else { return }
        do {
            let loadedSkills = try JSONDecoder().decode([Skill].self, from: data)
            self.skills = loadedSkills
        } catch {
            print("Failed to load skills: \(error.localizedDescription)")
        }
    }

    func skill(forID id: UUID) -> Skill? {
        skills.first(where: { $0.id == id })
    }

    func frequencyOfSkill(_ skill: Skill, in jobStore: JobStore) -> Int {
        jobStore.jobApplications.filter { $0.foundSkillIDs.contains(skill.id) }.count
    }
}

/**
 A view model used for AddJobView and EditJobView. 
 Also auto-detects a "http" line to set linkToJob if the user hasn't manually overwritten it.
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
    @Published var salaryString: String = ""
    @Published var salaryDouble: Double? = nil

    @Published var isInputValid: Bool = false

    private var userOverwroteJobLink: Bool = false

    init() {
        validateInputs()
    }

    init(job: JobApplication) {
        companyName = job.companyName
        jobTitle = job.jobTitle
        status = job.status
        dateOfApplication = job.dateOfApplication
        location = job.location
        salaryDouble = job.salary
        salaryString = formatSalaryAsInteger(job.salary)
        linkToJob = job.linkToJobString ?? ""
        jobDescription = job.jobDescription
        coverLetter = job.coverLetter
        notes = job.notes ?? ""

        if let salary = job.salary {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
            salaryString = formatter.string(from: NSNumber(value: salary)) ?? ""
        } else {
            salaryString = ""
        }

        validateInputs()
    }

    func validateInputs() {
        DispatchQueue.main.async {
            self.isInputValid = !(self.companyName.isEmpty || self.jobTitle.isEmpty)
        }
    }

    private func formatSalaryAsInteger(_ value: Double?) -> String {
        guard let value = value else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? ""
    }

       // Parse a formatted string back into a Double
    private func parseSalary(_ value: String) -> Double? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        return formatter.number(from: value)?.doubleValue
    }

       // Update salaryString and salaryDouble when the user edits the field
    func updateSalary(fromString newValue: String) {
        salaryString = newValue
        salaryDouble = parseSalary(newValue)
    }

    func setJobLinkManually(_ newValue: String) {
        linkToJob = newValue
        userOverwroteJobLink = true
    }

    func parseForURLInDescription() {
        guard !userOverwroteJobLink else { return }
        let lines = jobDescription.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("http") {
                linkToJob = trimmed
                break
            }
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
            salary: salaryDouble,
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
        salaryString = ""
        userOverwroteJobLink = false
        validateInputs()
    }
}

@main
// --------------------------------------------------
// MARK: - Helper Classes & Observables (ImportExportHelper, JobViewModel, etc.)
// --------------------------------------------------
// All same as your original snippet, omitted here for brevity.
// ...

// --------------------------------------------------
// MARK: - The Main App + handleIncomingURL Modification
// --------------------------------------------------
struct AppleJobApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var jobStore = JobStore()
    @StateObject private var docStore = DocumentStore()
    @StateObject private var importExportHelper = ImportExportHelper()
    @StateObject private var skillsStore = SkillsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(jobStore)
                .environmentObject(docStore)
                .environmentObject(importExportHelper)
                .environmentObject(skillsStore)
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

    private func handleIncomingURL(_ url: URL) {
        print("handleIncomingURL: URL received: \(url)")
        guard url.scheme == "applejob" else { return }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        guard let host = components.host else { return }

        if host == "x-callback-url" {
            let path = components.path
            if path.isEmpty { return }
            let action = path.dropFirst()
            switch action {
            case "add-job":
                handleAddJobAction(queryItems: components.queryItems)
            case "open-stats":
                handleOpenStatsAction(queryItems: components.queryItems)
            default:
                break
            }
        } else if host == "addjob" {
            handleLegacyAddJob(components: components)
        }
    }

    private func handleOpenStatsAction(queryItems: [URLQueryItem]?) {
        print("handleOpenStatsAction: Action not implemented yet.")
    }

    private func handleLegacyAddJob(components: URLComponents) {
        print("handleLegacyAddJob: Handling legacy add-job URL.")
    }

    private func handleAddJobAction(queryItems: [URLQueryItem]?) {
        print("handleAddJobAction: Handling add-job action")
        guard let rawBase64 = queryItems?.first(where: { $0.name == "jsonBase64" })?.value else { return }
        DispatchQueue.main.async {
            guard let decodedData = Data(base64Encoded: rawBase64) else { return }
            do {
                let jobData = try JSONDecoder().decode([String: String].self, from: decodedData)
                let title   = jobData["jobTitle"] ?? ""
                let urlString = jobData["URL"] ?? ""
                let desc    = jobData["jobDescription"] ?? ""
                self.jobStore.incomingJobData = [
                    "jobTitle": title,
                    "url": urlString,
                    "jobDescription": desc
                ]
                self.jobStore.isAddingNewJob = true
            } catch {
                print("JSON decoding error: \(error)")
            }
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

            Divider()
            Menu("Document") {
                Button("Edit Document Info") {
                    if let doc = docStore.selectedDocument {
            Menu("Set Job Type") {
                ForEach(JobType.allCases, id: \.self) { type in
                    Button(type.rawValue) {
                        // For all selected job IDs, set job type
                        docStore.beginEditMetadata(for: doc)
                        jobStore.setJobType(for: jobStore.selectedJobIDs, to: type)
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
            throw NSError(domain: "ZipError", code: Int(process.terminationStatus), userInfo: nil)
        }
    }
}

enum ViewSection: String, CaseIterable {
    case jobDetails = "Job Details"
    case stats = "Stats"
// --------------------------------------------------
// MARK: - ContentView
// --------------------------------------------------
    case documents = "Documents"
}

struct ContentView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @EnvironmentObject var importExportHelper: ImportExportHelper
    @State private var selectedSection: ViewSection = .jobDetails
    @EnvironmentObject var skillsStore: SkillsStore
    @State private var searchText: String = ""
    @State private var isDarkMode: Bool = false
    @State private var showDocInfoPopover = false
    @State private var isDirectlyPresentingAddJobView = false // ADD THIS STATE VARIABLE

    var body: some View {
        NavigationView {
            sidebar
            // Left Pane
                .frame(minWidth: 250)
                .background(
                    Color.black.opacity(0.03)
                        .blur(radius: 3)
                )
            mainContent
            JobListView()
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
            // Right Pane
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
        .sheet(isPresented: $jobStore.isAddingNewJob) {
            AddJobView(isPresented: $jobStore.isAddingNewJob)
                .environmentObject(jobStore)
                .environmentObject(docStore)
                .onAppear {
                    print("ContentView: Presenting AddJobView sheet because jobStore.isAddingNewJob is \(jobStore.isAddingNewJob)")
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
            if let selected = jobStore.selectedJob {
                JobDetailView(job: selected)
                    .id(job.id)
            } else {
                Text("Select a job to view details")
                    .foregroundColor(.secondary)
                Text("Select a job to view details.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        case .stats:
            EnhancedStatsView()
        case .documents:
            DocumentsMainView()
        }
    }
}

// --------------------------------------------------
// MARK: - JobListView
// Allows multiple selection, with a context menu to set job type
// --------------------------------------------------
/**
 An example struct that matches the JSON-LD for a "JobPosting" object.
 You can tweak field names as needed to match your data.
 */
struct FullLDJobPosting: Decodable {
    let context: String?
    let type: String?
    let datePosted: String?
    let description: String?
    let employmentType: [String]?
    let hiringOrganization: HiringOrganization?
    let identifier: IdentifierValue?
    let jobLocation: LocationData?
    let educationRequirements: String?
    let experienceRequirements: String?
    let industry: String?
    let qualifications: String?
    let responsibilities: String?
    let skills: String?
    let validThrough: String?
    let title: String?
    let url: String?

    // We map "@context" -> context, "@type" -> type, etc.
    enum CodingKeys: String, CodingKey {
        case context = "@context"
        case type = "@type"
        case datePosted
        case description
        case employmentType
        case hiringOrganization
        case identifier
        case jobLocation
        case educationRequirements
        case experienceRequirements
        case industry
        case qualifications
        case responsibilities
        case skills
        case validThrough
        case title
        case url
    }
}

/**
 For "hiringOrganization": { "@type":"Organization", "name":"Deloitte US"...}
 */
struct HiringOrganization: Decodable {
    let type: String?
    let name: String?
    let sameAs: String?

    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case name
        case sameAs
    }

    enum ViewSection: String, CaseIterable {
        case jobDetails = "Job Details"
        case stats = "Stats"
        case documents = "Documents"
    }
}

/**
 For "identifier": { "@type":"PropertyValue", "name":12345, "value":12345 }
 */
struct IdentifierValue: Decodable {
    let type: String?
    let name: String?
    let value: String?

    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case name
        case value
    }
}

/**
 For "jobLocation": { "@type":"Place", "address":{ ... } }
 */
struct LocationData: Decodable {
    let type: String?
    let address: AddressData?

    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case address
    }
}

struct AddressData: Decodable {
    let streetAddress: String?
    let addressLocality: String?
    let addressRegion: String?
    let postalCode: String?
    let addressCountry: String?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case streetAddress
        case addressLocality
        case addressRegion
        case postalCode
        case addressCountry
        case type = "@type"
    }
}




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
                    .tag(job.id)
                        get: { jobStore.selectedJob == job },
                        set: { newValue in
                            if newValue { jobStore.selectedJob = job }
                            else if jobStore.selectedJob == job {
                                jobStore.selectedJob = nil
            }
        }
                    )
        .listStyle(.inset)
                )
                .tag(job)
            }
            .onDelete(perform: deleteJobs)
        }
        .onChange(of: jobStore.selectedJobIDs) { newValue in
        .listStyle(SidebarListStyle())
        .searchable(text: $searchText)
        .navigationTitle("Applications")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
            // If exactly 1 is selected, set jobStore.selectedJob to that job
            if newValue.count == 1, let firstID = newValue.first {
                jobStore.selectedJob = jobStore.jobApplications.first(where: { $0.id == firstID })
            } else {
                // If multiple or none, set selectedJob to nil or keep if it's included
                if let currentSelected = jobStore.selectedJob, newValue.contains(currentSelected.id) {
                    // keep the same
                } else {
                    jobStore.selectedJob = nil
                }
            }
        }
    }
}

// --------------------------------------------------
// MARK: - JobDetailView
// Displays job details, including jobType and found skills
// --------------------------------------------------
struct JobDetailView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var skillsStore: SkillsStore

    let job: JobApplication

    @State private var highlightedSkillID: UUID? = nil
    @State private var showAddAliasSheet = false
    @State private var aliasSkill: Skill? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(job.companyName) - \(job.jobTitle)")
                .font(.title)
                .padding(.top)

            // Show Job Type
            Text("Job Type: \(job.jobType.rawValue)")
                .font(.headline)

            // Possibly show job description, etc.
            Text("Description:")
                .bold()
            ScrollView {
                Text(job.jobDescription)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 100)

            // Desired Skills
            if !job.foundSkillIDs.isEmpty {
                Text("Desired Skills Found:")
                    .font(.headline)
                    .padding(.top, 8)

                HStack {
                    ForEach(job.foundSkillIDs, id: \.self) { skillID in
                        if let skill = skillsStore.skill(forID: skillID) {
                            // Only display skill.displayName, ignoring aliases
                            SkillTagView(
                                skill: skill,
                                isHighlighted: (skillID == highlightedSkillID),
                                onTap: {
                                    if highlightedSkillID == skillID {
                                        highlightedSkillID = nil
                                    } else {
                                        highlightedSkillID = skillID
                                    }
                                },
                                onAddAlias: {
                                    aliasSkill = skill
                                    showAddAliasSheet = true
                                }
                            )
                        }
                    }
                }
            }
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showAddAliasSheet) {
            if let skill = aliasSkill {
                AddAliasView(skill: skill)
            }
        }
    }
}

struct SkillTagView: View {
    let skill: Skill
    let isHighlighted: Bool
    let onTap: () -> Void
    let onAddAlias: () -> Void

    var body: some View {
        Text(skill.displayName.capitalized)
            .padding(6)
            .background(isHighlighted ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
            .cornerRadius(8)
            .foregroundColor(isHighlighted ? .blue : .primary)
            .onTapGesture {
                onTap()
            }
            .contextMenu {
                Button("Add Alias") {
                    onAddAlias()
                }
            }
    }
}

// --------------------------------------------------
// MARK: - StatsView
// Shows various stats, including skill frequency
// --------------------------------------------------
struct StatsView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var skillsStore: SkillsStore

    var body: some View {
        VStack {
            Text("Job Application Stats")
                .font(.largeTitle)
            Divider()
            Text("Common Desired Skills")
                .font(.title2)
            desiredSkillsChart()
        }
        .padding()
    }

    private func desiredSkillsChart() -> some View {
        let skillCounts = skillsStore.skills.map { skill in
            (skill: skill, count: skillsStore.frequencyOfSkill(skill, in: jobStore))
        }.sorted { $0.count > $1.count }

        if skillCounts.isEmpty {
            return AnyView(Text("No desired skills found yet."))
        } else {
            return AnyView(
                Chart(skillCounts, id: \.skill.id) { item in
                    BarMark(
                        x: .value("Skill", item.skill.displayName),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 300)
                .padding()
            )
        }
    }
}

// --------------------------------------------------
// MARK: - AddJobView
// Uses NSComboBox for skill, no placeholder references to doc, windowRef, etc.
// --------------------------------------------------
struct AddJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @EnvironmentObject var skillsStore: SkillsStore

    @StateObject private var viewModel = JobViewModel()
    @State private var importedDocuments: [JobDocument] = []
    @State private var isImporting = false
    @State private var locations: [String] = CityCoordinateDictionary.keys.sorted()
    @State private var showAddLocationSheet = false
    @State private var quickLookURL: URL? = nil

    // For skill adding
    @State private var newSkillString: String = ""
    @State private var skillItems: [String] = []
    @State private var jobSkills: [Skill] = []

    var body: some View {
        VStack {
            Text("Add New Job")
                .font(.title2)
                .padding()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("JOB DETAILS")
                    TextField("Company Name", text: $viewModel.companyName)
                        .background(Material.thick).cornerRadius(5)
                        .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.tertiary, lineWidth: 0.5))
                        .controlSize(.large)
                        .onChange(of: viewModel.companyName) { _,_ in viewModel.validateInputs() }
                    TextField("Job Title", text: $viewModel.jobTitle)
                        .background(Material.thick).cornerRadius(5)
                        .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.tertiary, lineWidth: 0.5))
                        .controlSize(.large)
                        .onChange(of: viewModel.jobTitle) { _,_ in viewModel.validateInputs() }

                    sectionHeader("APPLICATION DETAILS")
                    TextField("Link to Job", text: $viewModel.linkToJob, onCommit: {
                        viewModel.setJobLinkManually(viewModel.linkToJob)
                    })
                    .background(Material.thick).cornerRadius(5)
                    .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.tertiary, lineWidth: 0.5))
                    .controlSize(.large)

                    Picker("Status", selection: $viewModel.status) {
                        ForEach(JobStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    TextField("Salary", text: $viewModel.salaryString)
                        .background(Material.thick).cornerRadius(5)
                        .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.tertiary, lineWidth: 0.5))
                        .controlSize(.large)
                        .onChange(of: viewModel.salaryString) { newVal in
                            viewModel.updateSalary(fromString: newVal)
                        }

                    DatePicker("Application Date", selection: $viewModel.dateOfApplication, displayedComponents: .date)

                    Menu("Location") {
                        TextField("Enter Location", text: $viewModel.location)
                            .controlSize(.large)

                        Divider()
                        ForEach(locations, id: \.self) { loc in
                            Button(loc) {
                                viewModel.location = loc
                            }
                        }
                        Divider()
                        Button("Add New Location") {
                            showAddLocationSheet = true
                        }
                    }
                    .background(Material.thick).cornerRadius(5)
                    .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.tertiary, lineWidth: 0.5))
                    .controlSize(.large)

                    // Desired Skills
                    sectionHeader("DESIRED SKILLS")
                    HStack {
                        ComboBoxRepresentable(text: $newSkillString, items: skillItems)
                            .frame(width: 200)
                        Button("Add Skill") {
                            let skill = skillsStore.addSkill(newSkillString, jobStore: jobStore)
                            if !jobSkills.contains(where: { $0.id == skill.id }) {
                                jobSkills.append(skill)
                            }
                            newSkillString = ""
                        }
                    }
                    FlowLayoutView(tags: jobSkills.map { $0.displayName })

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
                        .background(Material.thick).cornerRadius(5)
                        .controlSize(.large)
                        .font(.body)
                        .lineSpacing(5)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .scrollContentBackground(.hidden)
                        .onChange(of: viewModel.jobDescription) { _ in
                            viewModel.parseForURLInDescription()
                        }

                    sectionHeader("COVER LETTER")
                    TextEditor(text: $viewModel.coverLetter)
                        .background(Material.thick).cornerRadius(5)
                        .controlSize(.large)
                        .font(.body)
                        .lineSpacing(5)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .scrollContentBackground(.hidden)

                    sectionHeader("NOTES")
                    TextEditor(text: $viewModel.notes)
                        .background(Material.thick).cornerRadius(5)
                        .controlSize(.large)
                        .font(.body)
                        .lineSpacing(5)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .scrollContentBackground(.hidden)
                }
                .padding()
            }
            HStack {
                Button(role: .cancel) {
                    jobStore.isAddingNewJob = false
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

                        // Add job
                        viewModel.addJob(to: jobStore, documents: savedDocs)
                        jobStore.isAddingNewJob = false
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
            locations = CityCoordinateDictionary.keys.sorted()
            skillItems = skillsStore.skills.map { $0.displayName }
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

/**
 A SwiftUI wrapper around NSComboBox.
 */
struct ComboBoxRepresentable: NSViewRepresentable {
    @Binding var text: String
    var items: [String]

    func makeNSView(context: Context) -> NSComboBox {
        let comboBox = NSComboBox(frame: .zero)
        comboBox.isEditable = true
        comboBox.usesDataSource = false
        comboBox.removeAllItems()
        comboBox.addItems(withObjectValues: items)
        comboBox.delegate = context.coordinator
        comboBox.target = context.coordinator
        comboBox.action = #selector(Coordinator.comboBoxDidChange(_:))
        return comboBox
    }

    func updateNSView(_ nsView: NSComboBox, context: Context) {
        nsView.removeAllItems()
        nsView.addItems(withObjectValues: items)
        nsView.stringValue = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSComboBoxDelegate {
        let parent: ComboBoxRepresentable

        init(_ parent: ComboBoxRepresentable) {
            self.parent = parent
        }

        @objc func comboBoxDidChange(_ sender: NSComboBox) {
            parent.text = sender.stringValue
        }

        func comboBoxSelectionDidChange(_ notification: Notification) {
            if let comboBox = notification.object as? NSComboBox {
                parent.text = comboBox.stringValue
            }
        }
    }
}

/**
 Renders tags in a flow layout.
 */
struct FlowLayoutView: View {
    let tags: [String]
    let spacing: CGFloat = 8

    var body: some View {
        var totalWidth: CGFloat = 0
        var totalHeight: CGFloat = 0

        return GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(tags.indices, id: \.self) { index in
                    self.item(for: tags[index])
                        .alignmentGuide(.leading, computeValue: { d in
                            if (abs(totalWidth - d.width) > geometry.size.width) {
                                totalWidth = 0
                                totalHeight -= (d.height + spacing)
                            }
                            let result = totalWidth
                            totalWidth -= d.width + spacing
                            return result
                        })
                        .alignmentGuide(.top, computeValue: { _ in
                            let result = totalHeight
                            return result
                        })
                }
            }
        }
        .frame(height: 50)
    }

    func item(for text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(4)
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
                .controlSize(.large)
            TextField("Latitude", text: $latitude)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .controlSize(.large)
            TextField("Longitude", text: $longitude)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .controlSize(.large)
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

// --------------------------------------------------
// MARK: - AddAliasView
// Only place where skill aliases are shown
// --------------------------------------------------
struct AddAliasView: View {
    @EnvironmentObject var skillsStore: SkillsStore
    @EnvironmentObject var jobStore: JobStore

    let skill: Skill

    @State private var displayName: String = ""
    @State private var aliasText: String = ""

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Text("Add Alias for Skill")
                .font(.headline)
            Form {
                HStack {
                    Text("Displayed Name")
                    TextField("Skill Name", text: $displayName)
                }
                HStack {
                    Text("Aliases")
                    TextField("Comma-separated aliases", text: $aliasText)
                }
            }
            HStack {
                Spacer()
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                Button("Save") {
                    updateSkill()
                }
            }
        }
        .padding()
        .onAppear {
            self.displayName = skill.displayName
        }
    }

    func updateSkill() {
        // update displayName
        if let idx = skillsStore.skills.firstIndex(where: { $0.id == skill.id }) {
            skillsStore.skills[idx].displayName = displayName
        }
        // add new aliases
        skillsStore.addAliases(aliasText, to: skill, jobStore: jobStore)
        presentationMode.wrappedValue.dismiss()
    }
}
