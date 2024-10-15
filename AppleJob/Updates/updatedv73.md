
```swift
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

 */
/**
 The AppDelegate handles custom URLs:
 We rely on application(_:open:) to capture applejob:// URLs.
 */
class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        print("AppDelegate: application(_:open:) called with URL: \(urls)") // ADD THIS PRINT
        guard let url = urls.first else { return }
        NotificationCenter.default.post(name: .didOpenCustomURL, object: url)
    }
}



extension Notification.Name {
    static let didOpenCustomURL = Notification.Name("didOpenCustomURL")
}

/**
 Represents the type of job application.
 */
enum JobType: String, CaseIterable, Codable, CaseNameDisplayable {
    case internship = "Internship"
    case fullTime = "Full Time"
    case offCycleInternship = "Off-Cycle Internship"
    case none = "None" // Default value if no type is selected

    var displayName: String {
        return self.caseNameForDisplay()
    }
}

protocol CaseNameDisplayable: RawRepresentable, CaseIterable where RawValue == String, AllCases: Collection {
    func caseNameForDisplay() -> String
}

extension CaseNameDisplayable {
    func caseNameForDisplay() -> String {
        return self.rawValue // Changed from RawValue to self.rawValue
    }
}


/**
 Represents the status of a job application.
 */
enum JobStatus: String, CaseIterable, Codable, CaseNameDisplayable {
    case interested = "Interested"
    case applied = "Applied"
    case interview = "Interview"
    case offer = "Offer"
    case rejection = "Rejection"

    var displayName: String {
        return self.caseNameForDisplay()
    }

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

enum Sort: String, CaseIterable, CaseNameDisplayable {
    case title = "Job Title"
    case company = "Company Name"
    case recentlyApplied = "Recently Applied"

    var displayName: String {
        return self.caseNameForDisplay()
    }
}

/**
 Represents a desired skill with potential aliases.
 */
struct DesiredSkill: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String // Displayed name
    var aliases: [String] // Aliases for parsing

    init(id: UUID = UUID(), name: String, aliases: [String] = []) {
        self.id = id
        self.name = name
        self.aliases = aliases
    }
}


/**
 A model representing a single job application.

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

    var jobDescription: String
    var coverLetter: String
    var notes: String?

    var isFavorite: Bool
    var documents: [JobDocument]
    var jobType: JobType // NEW: Job Type
    var desiredSkillNames: [String] // NEW: Array of desired skill names

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
        jobType: JobType = .none, // Initialize jobType
        desiredSkillNames: [String] = [] // Initialize desiredSkillNames
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
        self.jobType = jobType // Assign jobType
        self.desiredSkillNames = desiredSkillNames // Assign desiredSkillNames
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
        self.jobType    = try container.decodeIfPresent(JobType.self, forKey: .jobType) ?? .none // Decode JobType
        self.desiredSkillNames = try container.decodeIfPresent([String].self, forKey: .desiredSkillNames) ?? [] // Decode desiredSkillNames
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
        try container.encode(jobType, forKey: .jobType) // Encode JobType
        try container.encode(desiredSkillNames, forKey: .desiredSkillNames) // Encode desiredSkillNames
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
        case jobType // CodingKey for JobType
        case desiredSkillNames // CodingKey for desiredSkillNames
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
    @Published var availableSkills: [DesiredSkill] = [] // NEW: Store available skills

    init() {
        loadJobs()
        loadSkills() // Load skills on initialization
    }

    func addJob(_ job: JobApplication) {
        jobApplications.append(job)
        sortJobs(by: sorting)
        saveJobs()
        parseJobDescriptionsForAllSkills() // Re-parse descriptions after adding a job
    }

    func editJob(with updatedJob: JobApplication) {
        if let index = jobApplications.firstIndex(where: { $0.id == updatedJob.id }) {
            jobApplications[index] = updatedJob
            sortJobs(by: sorting)
            saveJobs()
            parseJobDescriptionsForAllSkills() // Re-parse descriptions after editing a job
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
            jobType: job.jobType, // Duplicate job type
            desiredSkillNames: job.desiredSkillNames // Duplicate desired skills
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

    func updateJobType(_ id: UUID, to jobType: JobType) {
        if let index = jobApplications.firstIndex(where: { $0.id == id }) {
            jobApplications[index].jobType = jobType
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
        saveSkills() // Save skills whenever jobs are saved (or periodically as needed)
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
                self.parseJobDescriptionsForAllSkills() // Re-parse after import
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

    // MARK: - Desired Skills Management

    func addSkill(_ skill: DesiredSkill) {
        if !availableSkills.contains(where: {$0.name == skill.name}) {
            availableSkills.append(skill)
            saveSkills()
            parseJobDescriptionsForSkill(skill) // Parse job descriptions immediately after adding
        }
    }

    func updateSkill(_ skill: DesiredSkill) {
        if let index = availableSkills.firstIndex(where: { $0.id == skill.id }) {
            availableSkills[index] = skill
            saveSkills()
            parseJobDescriptionsForSkill(skill) // Re-parse job descriptions after updating aliases
        }
    }

    func deleteSkill(_ skill: DesiredSkill) {
        if let index = availableSkills.firstIndex(where: { $0.id == skill.id }) {
            availableSkills.remove(at: index)
            saveSkills()
            // Optionally, remove skill from JobApplication's desiredSkillNames and desiredSkillsMatches if needed.
        }
    }

    func saveSkills() {
        do {
            let data = try JSONEncoder().encode(availableSkills)
            UserDefaults.standard.set(data, forKey: "desiredSkills")
        } catch {
            print("Failed to save desired skills: \(error.localizedDescription)")
        }
    }

    func loadSkills() {
        guard let savedData = UserDefaults.standard.data(forKey: "desiredSkills") else { return }
        do {
            availableSkills = try JSONDecoder().decode([DesiredSkill].self, from: savedData)
        } catch {
            print("Failed to load desired skills: \(error.localizedDescription)")
        }
    }


    func parseJobDescriptionsForAllSkills() {
        for skill in availableSkills {
            parseJobDescriptionsForSkill(skill)
        }
    }

    func parseJobDescriptionsForSkill(_ skill: DesiredSkill) {
        for index in jobApplications.indices {
            var currentJob = jobApplications[index]
            let description = currentJob.jobDescription.lowercased()
            var skillNamesFound: [String] = []

            if currentJob.desiredSkillNames.contains(skill.name) || currentJob.desiredSkillNames.isEmpty { // Parse all job descriptions for each skill.
                let skillsToSearch = [skill.name] + skill.aliases
                for skillNameToSearch in skillsToSearch {
                    if description.contains(skillNameToSearch.lowercased()) {
                        if !skillNamesFound.contains(skill.name) {
                             skillNamesFound.append(skill.name) // Use the main skill name for display
                        }
                        break // Stop searching aliases after finding one match
                    }
                }

                let currentSkillSet = Set(currentJob.desiredSkillNames)
                let foundSkillSet = Set(skillNamesFound)

                if currentSkillSet != foundSkillSet { // Update only if there's a change
                    currentJob.desiredSkillNames = Array(foundSkillSet)
                    jobApplications[index] = currentJob // Update the job in the array
                }

            }
        }
        saveJobs() // Save after parsing and updating
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
    @Published var salaryString: String = "" // String for UI input/output
    @Published var salaryDouble: Double? = nil // Numeric value for calculations
    @Published var jobType: JobType = .none // Job Type
    @Published var desiredSkillText: String = "" // For NSComboBox input
    @Published var selectedDesiredSkills: [String] = [] // For storing selected skills
    @Published var availableSkillSuggestions: [String] = [] // Suggestions for NSComboBox
    @Published var isAddingAlias = false
    @Published var skillToAddAlias: String? = nil

    @Published var isInputValid: Bool = false

    init() {
        validateInputs()
    }


    init(job: JobApplication, availableSkills: [DesiredSkill]) { // Modify init to accept availableSkills
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
        jobType = job.jobType // Initialize jobType
        selectedDesiredSkills = job.desiredSkillNames // Initialize from job
        self.availableSkillSuggestions = availableSkills.map {$0.name}.sorted()
        validateInputs()
    }

    init() {
        validateInputs()
    }

    func validateInputs() {
        DispatchQueue.main.async {
            self.isInputValid = !(self.companyName.isEmpty || self.jobTitle.isEmpty)
        }
    }
    // Format salary as an integer (e.g., $50,000)
    func formatSalaryAsInteger(_ value: Double?) -> String {
        guard let value = value else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        formatter.maximumFractionDigits = 0 // No decimals for integer formatting
        return formatter.string(from: NSNumber(value: value)) ?? ""
    }

    // Parse a formatted string back into a Double
    func parseSalary(_ value: String) -> Double? {
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

    func updateSkillSuggestions(availableSkills: [DesiredSkill]) {
        availableSkillSuggestions = availableSkills.map { $0.name }
            .filter { $0.lowercased().contains(desiredSkillText.lowercased()) }
            .sorted() // Filter suggestions based on input and sort alphabetically
    }


    func addSelectedSkill(skillName: String, jobStore: JobStore) {
        if !selectedDesiredSkills.contains(skillName) {
            selectedDesiredSkills.append(skillName)
            desiredSkillText = "" // Clear the input after adding a skill
            if !jobStore.availableSkills.contains(where: {$0.name == skillName}) { // Add new skill to available skills
                let newSkill = DesiredSkill(name: skillName)
                jobStore.addSkill(newSkill)
            }
            updateSkillSuggestions(availableSkills: jobStore.availableSkills) // Refresh suggestions
        }
    }

    func removeSelectedSkill(skillName: String) {
        selectedDesiredSkills.removeAll { $0 == skillName }
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
            salary: salaryDouble, // Step 2.7: Use salaryDouble
            jobDescription: jobDescription,
            coverLetter: coverLetter,
            notes: notes,
            documents: documents,
            isFavorite: false,
            jobType: jobType, // Save job type
            desiredSkillNames: selectedDesiredSkills // Save selected skills
        )
        store.addJob(newJob)
        reset()
    }

    func updateJob(with originalJob: JobApplication, in store: JobStore, documents: [JobDocument]) {
        guard isInputValid else { return }
        let updatedJob = JobApplication(
            id: originalJob.id,
            companyName: companyName,
            jobTitle: jobTitle,
            status: status,
            dateOfApplication: dateOfApplication,
            location: location,
            linkToJobString: linkToJob.isEmpty ? nil : linkToJob,
            salary: salaryDouble, // Use salaryDouble
            jobDescription: jobDescription,
            coverLetter: coverLetter,
            notes: notes,
            documents: documents,
            isFavorite: originalJob.isFavorite,
            jobType: jobType, // Save job type
            desiredSkillNames: selectedDesiredSkills // Save selected skills
        )
        store.editJob(with: updatedJob)
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
        salaryString = "" // Step 2.9: Reset salaryString
        jobType = .none // Reset job type
        selectedDesiredSkills = [] // Reset selected skills
        validateInputs()
    }
}

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
                .onReceive(NotificationCenter.default.publisher(for: .didOpenCustomURL)) { notification in
                    print("AppleJobApp: Notification received: \(notification)")
                    if let url = notification.object as? URL {
                        handleIncomingURL(url)
                    }
                }
        }
        .commands {
            fileMenuCommands
            editMenuCommands
        }
        .windowStyle(.hiddenTitleBar) // Makes main window hidden title bar.
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




    // -------------- handleIncomingURL --------------
    /**
     Now we decode the Base64 JSON on the main thread, parse it, and
     set jobStore.incomingJobData + jobStore.isAddingNewJob = true
     so AddJobView will appear with fields auto-filled.
     */
    private func handleIncomingURL(_ url: URL) {
        print("handleIncomingURL: URL received: \(url)")
        guard url.scheme == "applejob" else {
            print("handleIncomingURL: Scheme is not applejob, returning")
            return
        }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("handleIncomingURL: URLComponents failed, returning")
            return
        }

        guard let host = components.host else {
            print("handleIncomingURL: Host is missing, returning")
            return
        }

        if host == "x-callback-url" { // Check for x-callback-url base path
            let path = components.path // Directly access the path
            if path.isEmpty {
                print("handleIncomingURL: x-callback-url path missing, returning")
                return
            }

            let action = path.dropFirst() // Remove leading "/"
            print("handleIncomingURL: x-callback-url action: \(action)")

            switch action {
            case "add-job": // Handle the "add-job" action
                handleAddJobAction(queryItems: components.queryItems)
            case "open-stats": // Example for another potential action
                handleOpenStatsAction(queryItems: components.queryItems)
            default:
                print("handleIncomingURL: Unknown x-callback-url action: \(action)")
            }
        } else if host == "addjob" { // Keep handling the old "addjob" host for backward compatibility (optional)
            handleLegacyAddJob(components: components) // Separate legacy handling into a function
        } else {
            print("handleIncomingURL: Unknown host: \(host)")
        }
    }

    private func handleOpenStatsAction(queryItems: [URLQueryItem]?) {
        print("handleOpenStatsAction: Action not implemented yet.")
        // Add logic here if needed in the future
    }

    private func handleLegacyAddJob(components: URLComponents) {
        print("handleLegacyAddJob: Handling legacy add-job URL.")
        // Add logic here if needed in the future
    }

    // --- New Functions to Handle Actions ---

    /**
     Handles the "add-job" x-callback-url action.
     Expects parameters to be passed as query items, including jsonBase64.
     */
    private func handleAddJobAction(queryItems: [URLQueryItem]?) {
        print("handleAddJobAction: Handling add-job action")
        guard let rawBase64 = queryItems?.first(where: { $0.name == "jsonBase64" })?.value else {
            print("handleAddJobAction: jsonBase64 parameter missing")
            return
        }
        print("handleAddJobAction: Found jsonBase64 parameter: \(rawBase64)")
        DispatchQueue.main.async {
            guard let decodedData = Data(base64Encoded: rawBase64) else {
                print("handleAddJobAction: Base64 decoding failed")
                print("Base64 String was: \(rawBase64)")
                return
            }
            do {
                let jobData = try JSONDecoder().decode([String: String].self, from: decodedData)
                print("handleAddJobAction: JSON decoding successful: \(jobData)")

                // Extract fields:
                let title   = jobData["jobTitle"] ?? ""
                let urlString = jobData["URL"] ?? ""
                let desc    = jobData["jobDescription"] ?? ""

                // Store them in the jobStore:
                jobStore.incomingJobData = [
                    "jobTitle": title,
                    "url": urlString,
                    "jobDescription": desc
                ]
                // Trigger AddJobView:
                jobStore.isAddingNewJob = true
                print("handleAddJobAction: Set jobStore.isAddingNewJob = true")

            } catch {
                print("handleAddJobAction: JSON decoding error: \(error)")
                if let jsonString = String(data: decodedData, encoding: .utf8) {
                    print("Data that failed to decode: \(jsonString)")
                } else {
                    print("Data that failed to decode could not be converted to string")
                }
            }
        }
    }
}


enum ViewSection: String, CaseIterable, CaseNameDisplayable {
    case jobDetails = "Job Details"
    case stats = "Stats"
    case documents = "Documents"

    var displayName: String {
        return self.caseNameForDisplay()
    }
}

struct ContentView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @EnvironmentObject var importExportHelper: ImportExportHelper
    @State private var selectedSection: ViewSection = .jobDetails
    @State private var searchText: String = ""
    @State private var isDarkMode: Bool = false
    @State private var showDocInfoPopover = false
    @State private var isDirectlyPresentingAddJobView = false

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
                .onAppear {
                    print("JobSidebarView: Presenting AddJobView sheet because jobStore.isAddingNewJob is \(jobStore.isAddingNewJob)")
                }
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
                    Capsule().fill(
                        isSelected
                            ? Color(nsColor: .selectedTextBackgroundColor).opacity(0.6)
                            : job.status.displayColor.opacity(0.2)
                    )
                )
                .foregroundColor(job.status.displayColor)
        }
        .contentShape(Rectangle())
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
            Button("Favorite Application") {
                if let selectedJob = jobStore.selectedJob {
                    jobStore.toggleFavorite(for: selectedJob.id)
                }
            }
            Divider()
            Button("Delete Application", role: .destructive) {
                jobStore.deleteJob(for: job.id)
            }
            Divider()
            Menu("Set Job Type") {
                ForEach(JobType.allCases, id: \.self) { jobType in
                    Button(jobType.displayName) {
                        jobStore.updateJobType(job.id, to: jobType)
                    }
                }
            }
        }
        .onTapGesture {
            isSelected.toggle()
        }
    }
}



struct JobDetailView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @StateObject var viewModel: JobViewModel
    let job: JobApplication

    @State private var windowRef: NSWindow? = nil
    @State private var quickLookURL: URL? = nil
    @State private var selectedSkill: String? = nil
    @State private var showAddAliasView = false
    @State private var skillForAlias: String = ""

    let markdownParser = MarkdownParser() // Initialize MarkdownParser - Step 1.3

    init(job: JobApplication) {
        self.job = job
        _viewModel = StateObject(wrappedValue: JobViewModel(job: job, availableSkills: JobStore().availableSkills)) // Initialize ViewModel with job
    }

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
                HStack {
                    Text("Job Type: ")
                        .bold()
                    Text(job.jobType.displayName)
                }
                if let link = job.linkToJobString, let url = URL(string: link) {
                    Link("View Job Posting", destination: url)
                }
                if !job.location.isEmpty {
                    Text("Location: \(job.location)")
                        .font(.headline)
                }
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

                if !job.desiredSkillNames.isEmpty {
                    Divider()
                    Text("Desired Skills")
                        .font(.headline)
                    HStack {
                        ForEach(job.desiredSkillNames, id: \.self) { skillName in
                            Button {
                                selectedSkill = (selectedSkill == skillName) ? nil : skillName
                            } label: {
                                Text(skillName)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(selectedSkill == skillName ? Color.blue.opacity(0.8) : Color.gray.opacity(0.3))
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Add Alias") {
                                    skillForAlias = skillName
                                    showAddAliasView = true
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
            jobStore.parseJobDescriptionsForAllSkills() // Re-parse descriptions on appear
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
        .background(WindowAccessor { window in
            self.windowRef = window // Capture window here
        })
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
                        .controlSize(.large)
                        .onChange(of: viewModel.companyName) { _, _ in
                            viewModel.validateInputs()
                        }

                    // JOB TITLE
                    TextField("Job Title", text: $viewModel.jobTitle)
                        .modifier(TranslucentTextFieldStyle())
                        .controlSize(.large)
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
                        .controlSize(.large)

                    // SALARY
                    TextField(
                        "Salary",
                        text: $viewModel.salaryString
                    )
                    .modifier(TranslucentTextFieldStyle())
                    .controlSize(.large)
                    .onChange(of: viewModel.salaryString) { newValue in
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

                    // BUTTON TO IMPORT DOCUMENTS
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


                    sectionHeader("JOB DESCRIPTION")
                    TextEditor(text: $viewModel.jobDescription)
                        .modifier(TranslucentTextEditorStyle())
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 200)
                        .onChange(of: viewModel.jobDescription) { newValue in
                            // 1) Find any line that starts with "http" (if linkToJob is empty)
                            if viewModel.linkToJob.isEmpty {
                                let lines = newValue.components(separatedBy: .newlines)
                                for line in lines {
                                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if trimmed.lowercased().hasPrefix("http") {
                                        viewModel.linkToJob = trimmed
                                        break
                                    }
                                }
                            }
                            // 2) Check existing job applications for a matching company name
                            if viewModel.companyName.isEmpty {
                                for existingApp in jobStore.jobApplications {
                                    if newValue.localizedCaseInsensitiveContains(existingApp.companyName) {
                                        viewModel.companyName = existingApp.companyName
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
            viewModel.availableSkillSuggestions = jobStore.availableSkills.map {$0.name}.sorted()
        }
        .onReceive(jobStore.$availableSkills) { updatedSkills in
            viewModel.updateSkillSuggestions(availableSkills: updatedSkills)
        }
        .background(WindowAccessor { window in
            self.windowRef = window
            window?.isMovableByWindowBackground = true
        })
        . detachableWindow
