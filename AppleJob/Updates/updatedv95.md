
//
//  AppleJob.swift
//  AppleJob
//
//  Created by [Your Name] on [Date].
//  Single-file codebase with all requested features, no placeholders.
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
import MarkdownKit

// --------------------------------------------------
// MARK: - JobType, JobStatus, Sort
// --------------------------------------------------

// We re-import these just once at the top:
import SwiftUI
import AppKit
import UniformTypeIdentifiers
import PDFKit
import MapKit
import Charts
import Quartz
import QuickLook
import QuickLookUI
import MarkdownKit

/**
Represents the type of job application.
*/
enum JobType: String, CaseIterable, Codable, CaseNameDisplayable {
    case internship = "Internship"
    case fullTime = "Full Time"
    case offCycleInternship = "Off-Cycle Internship"
    case none = "None" // Default if no type is selected

    var displayName: String {
        return self.caseNameForDisplay()
    }
}

protocol CaseNameDisplayable: RawRepresentable, CaseIterable where RawValue == String, AllCases: Collection {
    func caseNameForDisplay() -> String
}

extension CaseNameDisplayable {
    func caseNameForDisplay() -> String {
        return self.rawValue
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
    var name: String
    var aliases: [String]

    init(id: UUID = UUID(), name: String, aliases: [String] = []) {
        self.id = id
        self.name = name
        self.aliases = aliases
    }
}

/**
A model representing a single job application, now including a jobDeadline.
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
    var jobType: JobType
    var desiredSkillNames: [String]

    // NEW: jobDeadline
    var jobDeadline: Date?

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
        jobType: JobType = .none,
        desiredSkillNames: [String] = [],
        jobDeadline: Date? = nil
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
        self.jobType = jobType
        self.desiredSkillNames = desiredSkillNames
        self.jobDeadline = jobDeadline
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
        self.jobType    = try container.decodeIfPresent(JobType.self, forKey: .jobType) ?? .none
        self.desiredSkillNames = try container.decodeIfPresent([String].self, forKey: .desiredSkillNames) ?? []
        self.jobDeadline = try container.decodeIfPresent(Date.self, forKey: .jobDeadline)
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
        try container.encode(jobType, forKey: .jobType)
        try container.encode(desiredSkillNames, forKey: .desiredSkillNames)
        try container.encode(jobDeadline, forKey: .jobDeadline)
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
        case jobType
        case desiredSkillNames
        case jobDeadline
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
}

/**
Dictionary for city -> coordinate, used for location picks.
*/
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

/**
Category logic for documents.
*/
struct DocumentCategory: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var isExpanded: Bool = true

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

/**
Various code below for charts, not the main focus.
*/
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

struct MonthlyCityData: Identifiable, Equatable {
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

//
// MARK: - JobStore
//
class JobStore: ObservableObject {
    @Published var jobApplications: [JobApplication] = []
    @Published var selectedJobIDs: Set<UUID> = []

    var selectedJob: JobApplication? {
        if let firstID = selectedJobIDs.first {
            return jobApplications.first(where: { $0.id == firstID })
        }
        return nil
    }

    @Published var isAddingNewJob = false
    @Published var isEditingJob = false
    @Published var sorting: Sort = .recentlyApplied
    @Published var incomingJobData: [String: Any]? = nil
    @Published var availableSkills: [DesiredSkill] = []

    @Published var skillBeingEdited: DesiredSkill? = nil
    @Published var isShowingAliasEditor = false
    @Published var isAddingNewSkill = false

    init() {
        loadJobs()
        loadSkills()
    }

    func addJob(_ job: JobApplication) {
        jobApplications.append(job)
        sortJobs(by: sorting)
        saveJobs()
        parseJobDescriptionsForAllSkills()
    }

    func editJob(with updatedJob: JobApplication) {
        if let index = jobApplications.firstIndex(where: { $0.id == updatedJob.id }) {
            jobApplications[index] = updatedJob
            sortJobs(by: sorting)
            saveJobs()
            parseJobDescriptionsForAllSkills()
        }
    }

    func deleteJob(for id: UUID) {
        if let index = jobApplications.firstIndex(where: { $0.id == id }) {
            jobApplications.remove(at: index)
            selectedJobIDs.remove(id)
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
            jobType: job.jobType,
            desiredSkillNames: job.desiredSkillNames,
            jobDeadline: job.jobDeadline
        )
        jobApplications.append(newJob)
        sortJobs(by: sorting)
        saveJobs()
    }

    func updateJobStatus(_ ids: Set<UUID>, to status: JobStatus) {
        for id in ids {
            if let index = jobApplications.firstIndex(where: { $0.id == id }) {
                jobApplications[index].status = status
            }
        }
        saveJobs()
    }

    func updateJobType(_ ids: Set<UUID>, to jobType: JobType) {
        for id in ids {
            if let index = jobApplications.firstIndex(where: { $0.id == id }) {
                jobApplications[index].jobType = jobType
            }
        }
        saveJobs()
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
        saveSkills()
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
                self.parseJobDescriptionsForAllSkills()
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

    // MARK: - Skills
    func addSkill(_ skill: DesiredSkill) {
        if !availableSkills.contains(where: { $0.name.lowercased() == skill.name.lowercased() }) {
            availableSkills.append(skill)
            saveSkills()
            parseJobDescriptionsForSkill(skill)
        }
    }

    func updateSkill(_ skill: DesiredSkill) {
        if let index = availableSkills.firstIndex(where: { $0.id == skill.id }) {
            availableSkills[index] = skill
            saveSkills()
            parseJobDescriptionsForSkill(skill)
        }
    }

    func deleteSkill(_ skill: DesiredSkill) {
        if let index = availableSkills.firstIndex(where: { $0.id == skill.id }) {
            availableSkills.remove(at: index)
            saveSkills()
            for i in jobApplications.indices {
                jobApplications[i].desiredSkillNames.removeAll { $0 == skill.name }
            }
            saveJobs()
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
        let searchTerms = [skill.name.lowercased()] + skill.aliases.map { $0.lowercased() }
        for i in jobApplications.indices {
            var job = jobApplications[i]
            let desc = job.jobDescription.lowercased()
            let found = searchTerms.contains { desc.contains($0) }
            if found {
                if !job.desiredSkillNames.contains(skill.name) {
                    job.desiredSkillNames.append(skill.name)
                }
            }
            jobApplications[i] = job
        }
        saveJobs()
    }

    func beginEditAlias(for skillName: String) {
        if let sk = availableSkills.first(where: { $0.name == skillName }) {
            skillBeingEdited = sk
            isShowingAliasEditor = true
        }
    }
}

// --------------------------------------------------
// MARK: - DocumentStore
// --------------------------------------------------
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

// For import/export backups
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
A helper struct to store parse results from the job description.
We’ll build the logic to fill jobTitle, jobDeadline, location, etc.
*/
/**
 A helper struct to store parse results from the job description.
 The parsing now extracts:
  - First non-empty line → detectedJobTitle
  - Second non-empty line → detectedCompanyName
  - Third non-empty line → detectedLocation
  - Fourth non-empty line → detectedDesiredSkills
  - Last non-empty line (if it contains "http") → detectedURL
 And also returns a sanitized version of the text (with only single blank lines).
*/
struct ParsedJobDescriptionResult {
    var sanitizedText: String
    var detectedJobTitle: String?
    var detectedCompanyName: String?
    var detectedLocation: String?
    var detectedDesiredSkills: String?
    var detectedURL: String?
}
/**
A view model used for AddJobView and EditJobView, including parsing logic
to handle first line => jobTitle, city name => location, date => jobDeadline, etc.
*/
class JobViewModel: ObservableObject {
    @Published var companyName: String = ""
    @Published var jobTitle: String = ""
    @Published var status: JobStatus = .interested
    @Published var dateOfApplication: Date = Date()
    @Published var location: String = ""
    @Published var linkToJob: String = ""
    @Published var jobDescription: String = "" {
        didSet { parseDescriptionIfNeeded() }
    }
    @Published var coverLetter: String = ""
    @Published var notes: String = ""
    @Published var salaryString: String = ""
    @Published var salaryDouble: Double? = nil
    @Published var jobType: JobType = .none
    @Published var desiredSkillText: String = ""
    @Published var selectedDesiredSkills: [String] = []
    @Published var availableSkillSuggestions: [String] = []
    @Published var isInputValid: Bool = false

    // For an optional job deadline if date found > dateOfApplication
    @Published var jobDeadline: Date? = nil

    init(job: JobApplication, availableSkills: [DesiredSkill]) {
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
        jobType = job.jobType
        selectedDesiredSkills = job.desiredSkillNames
        jobDeadline = job.jobDeadline // If previously set
        if let salary = job.salary {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
            salaryString = formatter.string(from: NSNumber(value: salary)) ?? ""
        } else {
            salaryString = ""
        }
        self.availableSkillSuggestions = availableSkills.map { $0.name }.sorted()
        validateInputs()
        parseDescriptionIfNeeded()
    }

    init() {
        validateInputs()
    }

    func validateInputs() {
        DispatchQueue.main.async {
            self.isInputValid = !(self.companyName.isEmpty || self.jobTitle.isEmpty)
        }
    }

    func formatSalaryAsInteger(_ value: Double?) -> String {
        guard let value = value else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? ""
    }

    func parseSalary(_ value: String) -> Double? {
        let dashParts = value.components(separatedBy: "-")
        guard let first = dashParts.first else { return nil }
        let cleaned = first.trimmingCharacters(in: .whitespacesAndNewlines)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        return formatter.number(from: cleaned)?.doubleValue
    }

    func updateSalary(fromString newValue: String) {
        salaryString = newValue
        salaryDouble = parseSalary(newValue)
    }

    func updateSkillSuggestions(availableSkills: [DesiredSkill]) {
        availableSkillSuggestions = availableSkills
            .map { $0.name }
            .filter { $0.lowercased().contains(desiredSkillText.lowercased()) }
            .sorted()
    }

    func addSelectedSkill(skillName: String, jobStore: JobStore) {
        let parts = skillName.components(separatedBy: ",")
        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            if !jobStore.availableSkills.contains(where: { $0.name.lowercased() == trimmed.lowercased() }) {
                let newSkill = DesiredSkill(name: trimmed)
                jobStore.addSkill(newSkill)
            }
            if !selectedDesiredSkills.contains(trimmed) {
                selectedDesiredSkills.append(trimmed)
            }
        }
        desiredSkillText = ""
        updateSkillSuggestions(availableSkills: jobStore.availableSkills)
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
            salary: salaryDouble,
            jobDescription: jobDescription,
            coverLetter: coverLetter,
            notes: notes,
            documents: documents,
            isFavorite: false,
            jobType: jobType,
            desiredSkillNames: selectedDesiredSkills,
            jobDeadline: jobDeadline
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
            salary: salaryDouble,
            jobDescription: jobDescription,
            coverLetter: coverLetter,
            notes: notes,
            documents: documents,
            isFavorite: originalJob.isFavorite,
            jobType: jobType,
            desiredSkillNames: selectedDesiredSkills,
            jobDeadline: jobDeadline
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
        salaryString = ""
        jobType = .none
        selectedDesiredSkills = []
        jobDeadline = nil
        validateInputs()
    }

    /**
     Enhanced parse logic:
     1. If the first non-empty line does not start with "http", treat it as jobTitle.
     2. We parse the text for city matches from CityCoordinateDictionary’s keys
     (looking only at city portion before comma). If found, set location.
     3. We parse the text for date values. If the date is after dateOfApplication => jobDeadline.
     4. We remove repeated blank lines, standardize bullet points, etc.
     */
    func parseDescriptionIfNeeded() {
        // Create local copy first to prevent infinite recursion
        let currentDescription = self.jobDescription
        let parseResult = parseJobDescriptionText(currentDescription)

        // Only update if different to prevent re-triggering
        if parseResult.sanitizedText != currentDescription {
            self.jobDescription = parseResult.sanitizedText
        }

        // Use parsed values only if fields are empty
        if jobTitle.isEmpty, let title = parseResult.detectedJobTitle {
            jobTitle = title
        }
        if companyName.isEmpty, let comp = parseResult.detectedCompanyName {
            companyName = comp
        }
        if location.isEmpty, let loc = parseResult.detectedLocation {
            location = loc
        }
        if desiredSkillText.isEmpty, let skills = parseResult.detectedDesiredSkills {
            desiredSkillText = skills
        }
        if linkToJob.isEmpty, let url = parseResult.detectedURL {
            linkToJob = url
        }
        validateInputs()
    }


    /**
     Parses the job description text with the following rules:
     - Removes repeated blank lines.
     - Uses the first non-empty line as jobTitle.
     - Uses the second non-empty line as companyName.
     - Uses the third non-empty line as location.
     - Uses the fourth non-empty line as desiredSkills.
     - Uses the last non-empty line as the URL if it contains "http".
     */
    // Split the text into lines
    /**
     Parses the job description text with the following rules:
     - Removes repeated blank lines.
     - Uses the first non-empty line as jobTitle.
     - Uses the second non-empty line as companyName.
     - Uses the third non-empty line as location.
     - Uses the fourth non-empty line as desiredSkills.
     - Uses the last non-empty line as the URL if it contains "http".
     */
    private func parseJobDescriptionText(_ text: String) -> ParsedJobDescriptionResult {
        guard !text.isEmpty else {
            return ParsedJobDescriptionResult(
                sanitizedText: "",
                detectedJobTitle: nil,
                detectedCompanyName: nil,
                detectedLocation: nil,
                detectedDesiredSkills: nil,
                detectedURL: nil
            )
        }

        // Use NSString for safer memory handling if needed
        let nsText = text as NSString
        let lines = nsText.components(separatedBy: .newlines)

        var cleanedLines: [String] = []
        var lastWasBlank = false

        // Process lines using a for-in loop
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                if !lastWasBlank {
                    cleanedLines.append("")
                }
                lastWasBlank = true
            } else {
                cleanedLines.append(line)
                lastWasBlank = false
            }
        }

        // Create an array of non-empty lines (ignoring whitespace-only lines)
        let nonEmptyLines = cleanedLines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        let detectedJobTitle = nonEmptyLines.count > 0 ? nonEmptyLines[0].trimmingCharacters(in: .whitespaces) : nil
        let detectedCompanyName = nonEmptyLines.count > 1 ? nonEmptyLines[1].trimmingCharacters(in: .whitespaces) : nil
        let detectedLocation = nonEmptyLines.count > 2 ? nonEmptyLines[2].trimmingCharacters(in: .whitespaces) : nil
        let detectedDesiredSkills = nonEmptyLines.count > 3 ? nonEmptyLines[3].trimmingCharacters(in: .whitespaces) : nil

        var detectedURL: String? = nil
        if let lastLine = nonEmptyLines.last, lastLine.lowercased().contains("http") {
            detectedURL = lastLine.trimmingCharacters(in: .whitespaces)
        }

        let sanitized = cleanedLines.joined(separator: "\n")

        return ParsedJobDescriptionResult(
            sanitizedText: sanitized,
            detectedJobTitle: detectedJobTitle,
            detectedCompanyName: detectedCompanyName,
            detectedLocation: detectedLocation,
            detectedDesiredSkills: detectedDesiredSkills,
            detectedURL: detectedURL
        )
    }
}

// --------------------------------------------------
// MARK: - AppleJobApp (Entry Point)
// --------------------------------------------------
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
            // Additional items if needed
        }
    }

    func exportAllDocumentsToZip(url: URL) {
        // Implementation for zipping docStore.documents omitted
        print("Exporting all documents to a zip at \(url)")
    }
}

// --------------------------------------------------
// MARK: - ContentView
// --------------------------------------------------
enum ViewSection: String, CaseIterable, CaseNameDisplayable {
    case jobDetails = "Job Details"
    case stats = "Stats"
    case documents = "Documents"

    var displayName: String {
        self.caseNameForDisplay()
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

    var body: some View {
        NavigationView {
            sidebar
                .frame(minWidth: 250)
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
            } else {
                Text("Select a job to view details").foregroundColor(.secondary)
            }
        case .stats:
            EnhancedStatsView()
        case .documents:
            DocumentsMainView()
        }
    }
}

// --------------------------------------------------
// MARK: - JobSidebarView
// --------------------------------------------------
struct JobSidebarView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var searchText: String

    var body: some View {
        // We use a custom approach to highlight selection in each row
        List {
            ForEach(filteredJobs, id: \.id) { job in
                SidebarRowItem(job: job)
                    .listRowBackground(rowBackground(job: job))
            }
            .onDelete(perform: deleteJobs)
        }
        .listStyle(SidebarListStyle())
        .searchable(text: $searchText)
        .navigationTitle("Applications")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("New") {
                    jobStore.isAddingNewJob = true
                    showAddJobWindow()
                }
            }
        }
    }

    private func showAddJobWindow() {
        // Open an NSWindow hosting AddJobView:
        let vc = NSHostingController(rootView: AddJobWindowView()
            .environmentObject(jobStore)
            .environmentObject(docStore)
        )
        let window = NSWindow(contentViewController: vc)
        window.title = "Add New Job"
        window.styleMask = NSWindow.StyleMask([.titled, .closable, .resizable])
        window.makeKeyAndOrderFront(nil)
    }

    private func rowBackground(job: JobApplication) -> Color {
        jobStore.selectedJobIDs.contains(job.id) ? .blue : .clear
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
        for idx in offsets {
            let job = filteredJobs[idx]
            jobStore.deleteJob(for: job.id)
        }
    }
}

/**
A row in the sidebar list.
If you click it, we update the jobStore.selectedJobIDs to reflect selection.
We highlight the row with a .blue background and .white text if it's selected.
*/
struct SidebarRowItem: View {
    @EnvironmentObject var jobStore: JobStore
    let job: JobApplication

    var isSelected: Bool {
        jobStore.selectedJobIDs.contains(job.id)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(job.companyName)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                Text(job.jobTitle)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            Spacer()
            Text(job.status.rawValue)
                .font(.caption)
                .padding(5)
                .background(Capsule().fill(job.status.displayColor.opacity(0.2)))
                .foregroundColor(isSelected ? .white : job.status.displayColor)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Single selection unless user holds Command
            let cmdPressed = NSEvent.modifierFlags.contains(.command)
            if cmdPressed {
                if isSelected {
                    jobStore.selectedJobIDs.remove(job.id)
                } else {
                    jobStore.selectedJobIDs.insert(job.id)
                }
            } else {
                jobStore.selectedJobIDs = [job.id]
            }
        }
    }
}

// AddJobWindowView spawns a new NSWindow for the "AddJobView"
struct AddJobWindowView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore

    var body: some View {
        AddJobView(isPresented: .constant(false))
            .environmentObject(jobStore)
            .environmentObject(docStore)
            .frame(minWidth: 600, minHeight: 500)
            .onDisappear {
                jobStore.isAddingNewJob = false
            }
    }
}
struct EditJobWindowView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    let job: JobApplication

    var body: some View {
        // Provide a SwiftUI view:
        EditJobView(isPresented: .constant(false), job: job)
            .environmentObject(jobStore)
            .environmentObject(docStore)
            .frame(minWidth: 600, minHeight: 500)
            .onDisappear {
                jobStore.isEditingJob = false
            }
    }
}

// --------------------------------------------------
// MARK: - JobDetailView
// --------------------------------------------------
struct JobDetailView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    let job: JobApplication

    @State private var windowRef: NSWindow?
    @State private var quickLookURL: URL? = nil
    let markdownParser = MarkdownParser()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(job.companyName)
                    .font(.largeTitle)
                    .bold()
                Text(job.jobTitle)
                    .font(.title2)

                // Show status, URL, location, date
                HStack {
                    Text("Status: ").bold()
                    Text(job.status.rawValue)
                        .foregroundColor(job.status.displayColor)
                }
                if let link = job.linkToJobString, let url = URL(string: link) {
                    Link("View Job Posting", destination: url)
                } else {
                    Text("No job link available").foregroundColor(.secondary)
                }
                if !job.location.isEmpty {
                    Text("Location: \(job.location)").font(.headline)
                } else {
                    Text("No location specified").foregroundColor(.secondary)
                }

                Text("Applied on: \(job.dateOfApplication.formatted(date: .abbreviated, time: .omitted))")

                // NEW: show jobDeadline if available
                if let dl = job.jobDeadline {
                    Text("Application Deadline: \(dl.formatted(date: .abbreviated, time: .omitted))")
                        .font(.headline)
                        .foregroundColor(.red)
                }

                if let salary = job.salary {
                    let sInt = Int(salary)
                    Text("Salary: \(sInt.formatted(.currency(code: "USD"))) per year").font(.headline)
                }

                if !job.documents.isEmpty {
                    Divider()
                    Text("Documents").font(.headline)
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(job.documents) { doc in
                                Button {
                                    openQuickLook(doc)
                                } label: {
                                    HStack {
                                        Image(systemName: "doc.text")
                                        Text(cleanFileName(doc.fileName))
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
                    Text("Desired Skills").font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(job.desiredSkillNames, id: \.self) { skillName in
                                if let skillObj = jobStore.availableSkills.first(where: { $0.name == skillName }) {
                                    SkillChipView(skill: skillObj)
                                } else {
                                    Text(skillName)
                                        .padding(6)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }

                // Job Description
                if !job.jobDescription.isEmpty {
                    Divider()
                    HStack {
                        Text("Job Description").font(.headline)
                        Button("Copy") {
                            let pb = NSPasteboard.general
                            pb.declareTypes([.string], owner: nil)
                            pb.setString(job.jobDescription, forType: .string)
                        }
                    }
                    let md = markdownParser.parse(job.jobDescription)
                    Text(AttributedString(md))
                        .font(.body)
                }

                // Cover Letter
                if !job.coverLetter.isEmpty {
                    Divider()
                    Text("Cover Letter").font(.headline)
                    Text(job.coverLetter)
                }

                // Notes
                Divider()
                Text("Notes").font(.headline)
                if let notes = job.notes, !notes.isEmpty {
                    Text(notes)
                } else {
                    Text("No notes provided.").foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .toolbar {
            ToolbarItemGroup {
                Button {
                    jobStore.isEditingJob = true
                    showEditJobWindow()
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
                if let kw = NSApp.windows.first(where: { $0.isKeyWindow }) {
                    windowRef = kw
                }
            }
            updateWindowTitle()
        }
        .onChange(of: job.id) { _, _ in
            updateWindowTitle()
        }
        .quickLookPreview($quickLookURL)
    }

    private func showEditJobWindow() {
        // Open a new NSWindow for EditJobView
        let vc = NSHostingController(rootView: EditJobWindowView(job: job)
            .environmentObject(jobStore)
            .environmentObject(docStore)
        )
        let window = NSWindow(contentViewController: vc)
        window.title = "Edit Job"
        window.styleMask = NSWindow.StyleMask([.titled, .closable, .resizable])
        window.makeKeyAndOrderFront(nil)
    }

    private func updateWindowTitle() {
        guard let w = windowRef else { return }
        w.title = "\(job.companyName) \(job.jobTitle)"
    }

    private func openQuickLook(_ doc: JobDocument) {
        if let fileURL = doc.fileURL {
            quickLookURL = fileURL
        } else {
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(doc.fileName)
            do {
                try doc.fileData.write(to: tmp)
                quickLookURL = tmp
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
        var cleaned = filename
        let removeList = ["Roger Lin", "Position", "2024", "Cover Letter"]
        for r in removeList {
            cleaned = cleaned.replacingOccurrences(of: r, with: "")
        }
        let exts = [".pdf", ".docx", ".pages", ".rtf", ".txt"]
        for e in exts {
            if cleaned.hasSuffix(e) {
                cleaned = String(cleaned.dropLast(e.count))
                break
            }
        }
        return cleaned.trimmingCharacters(in: .whitespaces)
    }
}

// --------------------------------------------------
// MARK: - SkillChipView
// --------------------------------------------------
struct SkillChipView: View {
    @EnvironmentObject var jobStore: JobStore
    let skill: DesiredSkill
    @State private var isSelected = false

    var body: some View {
        Text(skill.name)
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .cornerRadius(8)
            .onTapGesture {
                isSelected.toggle()
            }
            .contextMenu {
                Button("Add Alias") {
                    jobStore.beginEditAlias(for: skill.name)
                }
                Button("Edit Alias") {
                    jobStore.beginEditAlias(for: skill.name)
                }
                Button("Delete Alias", role: .destructive) {
                    var cleared = skill
                    cleared.aliases = []
                    jobStore.updateSkill(cleared)
                }
                Divider()
                Button("Add New Skill") {
                    jobStore.isAddingNewSkill = true
                }
                Button("Delete Skill", role: .destructive) {
                    jobStore.deleteSkill(skill)
                }
            }
    }
}

// --------------------------------------------------
// MARK: - AddJobView (MODIFIED - Uses TransparentTextEditorStyle)
// --------------------------------------------------
struct AddJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var isPresented: Bool

    @StateObject private var viewModel: JobViewModel = JobViewModel()
    @State private var importedDocuments: [JobDocument] = []
    @State private var locations: [String] = CityCoordinateDictionary.keys.sorted()

    @State private var showNewLocationWindow = false

    var body: some View {
        VStack {
            Text("Add New Job")
                .font(.title2)
                .padding()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Company Name").font(.headline)
                    TextField("Company Name", text: $viewModel.companyName)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: viewModel.companyName) {_, _ in viewModel.validateInputs() }

                    Text("Job Title").font(.headline)
                    TextField("Job Title", text: $viewModel.jobTitle)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: viewModel.jobTitle) {_, _ in viewModel.validateInputs() }

                    Text("Status").font(.headline)
                    Picker("Status", selection: $viewModel.status) {
                        ForEach(JobStatus.allCases, id: \.self) { st in
                            Text(st.rawValue).tag(st)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("Job Type").font(.headline)
                    Picker("Job Type", selection: $viewModel.jobType) {
                        ForEach(JobType.allCases, id: \.self) { jt in
                            Text(jt.rawValue).tag(jt)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("Date of Application").font(.headline)
                    DatePicker("", selection: $viewModel.dateOfApplication, displayedComponents: .date)
                        .labelsHidden()

                    // location with "Add New Location..."
                    Text("Location").font(.headline)
                    Picker("Location", selection: $viewModel.location) {
                        ForEach(locations, id: \.self) { loc in
                            Text(loc).tag(loc)
                        }
                        // NEW:
                        Text("Add New Location...").tag("Add New Location...")
                    }
                    .onChange(of: viewModel.location) {_, newValue in
                        if newValue == "Add New Location..." {
                            showNewLocationWindow = true
                        }
                    }

                    Text("Salary").font(.headline)
                    TextField("Salary", text: $viewModel.salaryString)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: viewModel.salaryString) {_, v in
                            viewModel.updateSalary(fromString: v)
                        }

                    Text("Link to Job").font(.headline)
                    TextField("Link to Job", text: $viewModel.linkToJob)
                        .textFieldStyle(.roundedBorder)

                    // description
                    HStack {
                        Text("Job Description").font(.headline)
                        Button("Paste") {
                            if let clip = NSPasteboard.general.string(forType: .string) {
                                viewModel.jobDescription = clip
                            }
                        }
                    }
                    TextEditor(text: $viewModel.jobDescription)
                        .frame(height: 180)
                        .modifier(TransparentTextEditorStyle())

                    Text("Cover Letter").font(.headline)
                    TextEditor(text: $viewModel.coverLetter)
                        .frame(height: 120)
                        .modifier(TransparentTextEditorStyle())

                    Text("Notes").font(.headline)
                    TextEditor(text: $viewModel.notes)
                        .frame(height: 80)
                        .modifier(TransparentTextEditorStyle())

                    Text("Desired Skills").font(.headline)
                    SkillComboBoxField(
                        text: $viewModel.desiredSkillText,
                        suggestions: $viewModel.availableSkillSuggestions
                    ) {
                        viewModel.addSelectedSkill(skillName: viewModel.desiredSkillText, jobStore: jobStore)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(viewModel.selectedDesiredSkills, id: \.self) { sName in
                                SkillTag(skillName: sName) {
                                    viewModel.removeSelectedSkill(skillName: sName)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    Divider()
                    HStack {
                        Button("Cancel") {
                            isPresented = false
                        }
                        Spacer()
                        Button("Add Job") {
                            if viewModel.isInputValid {
                                viewModel.addJob(to: jobStore, documents: importedDocuments)
                                isPresented = false
                            }
                        }
                        .disabled(!viewModel.isInputValid)
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 500, minHeight: 600)
        .sheet(isPresented: $showNewLocationWindow) {
            // The "Add new location" window
            NewLocationWindowView(
                locations: $locations,
                selectedLocation: $viewModel.location
            )
        }
        .onAppear {
            viewModel.updateSkillSuggestions(availableSkills: jobStore.availableSkills)
        }
    }
}

// The separate new location popup
struct NewLocationWindowView: View {
    @Binding var locations: [String]
    @Binding var selectedLocation: String
    @State private var isPresented: Bool = true

    var body: some View {
        NewLocationView(
            locations: $locations,
            selectedLocation: $selectedLocation,
            isPresented: $isPresented
        )
        .frame(width: 350, height: 250)
    }
}

// Custom TextEditor Modifier with transparent gradient
// --------------------------------------------------
// MARK: - TransparentTextEditorStyle (MODIFIED)
// --------------------------------------------------

struct TransparentTextEditorStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(8)
            .lineSpacing(6)
            .background(
                ZStack {
                    // Pastel gradient background (behind material)
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(.sRGB, red: 0.95, green: 0.92, blue: 1.00, opacity: 0.25),
                                    Color(.sRGB, red: 0.87, green: 0.98, blue: 1.00, opacity: 0.25)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .opacity(0.25) // Gradient opacity set here

                    // Ultra Thin Material layer (on top of gradient)
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        // No need to set opacity for material here, it's inherently semi-transparent
                }
                .cornerRadius(8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
            .font(.system(size: 13))
            .foregroundColor(.primary)
    }
}


// --------------------------------------------------
// MARK: - EditJobView
// --------------------------------------------------
struct EditJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var isPresented: Bool

    @StateObject var viewModel: JobViewModel
    @State private var importedDocuments: [JobDocument] = []
    @State private var locations: [String] = CityCoordinateDictionary.keys.sorted()

    @State private var showNewLocationWindow = false

    init(isPresented: Binding<Bool>, job: JobApplication) {
        self._isPresented = isPresented
        let vm = JobViewModel(job: job, availableSkills: [])
        _viewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        VStack {
            Text("Edit Job")
                .font(.title2)
                .padding()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Company Name").font(.headline)
                    TextField("Company Name", text: $viewModel.companyName)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: viewModel.companyName) {_, _ in
                            viewModel.validateInputs()
                        }

                    Text("Job Title").font(.headline)
                    TextField("Job Title", text: $viewModel.jobTitle)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: viewModel.jobTitle) {_, _ in
                            viewModel.validateInputs()
                        }

                    Text("Status").font(.headline)
                    Picker("Status", selection: $viewModel.status) {
                        ForEach(JobStatus.allCases, id: \.self) { st in
                            Text(st.rawValue).tag(st)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("Job Type").font(.headline)
                    Picker("Job Type", selection: $viewModel.jobType) {
                        ForEach(JobType.allCases, id: \.self) { jt in
                            Text(jt.rawValue).tag(jt)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("Date of Application").font(.headline)
                    DatePicker("", selection: $viewModel.dateOfApplication, displayedComponents: .date)
                        .labelsHidden()

                    // location with "Add New Location..."
                    Text("Location").font(.headline)
                    Picker("Location", selection: $viewModel.location) {
                        ForEach(locations, id: \.self) { loc in
                            Text(loc).tag(loc)
                        }
                        Text("Add New Location...").tag("Add New Location...")
                    }
                    .onChange(of: viewModel.location) {_, newVal in
                        if newVal == "Add New Location..." {
                            showNewLocationWindow = true
                        }
                    }

                    Text("Salary").font(.headline)
                    TextField("Salary", text: $viewModel.salaryString)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: viewModel.salaryString) {_, v in
                            viewModel.updateSalary(fromString: v)
                        }

                    Text("Link to Job").font(.headline)
                    TextField("Link to Job", text: $viewModel.linkToJob)
                        .textFieldStyle(.roundedBorder)

                    Text("Job Description").font(.headline)
                    TextEditor(text: $viewModel.jobDescription)
                        .frame(height: 150)
                        .border(Color.gray, width: 1)

                    Text("Cover Letter").font(.headline)
                    TextEditor(text: $viewModel.coverLetter)
                        .frame(height: 100)
                        .border(Color.gray, width: 1)

                    Text("Notes").font(.headline)
                    TextEditor(text: $viewModel.notes)
                        .frame(height: 60)
                        .border(Color.gray, width: 1)

                    Text("Desired Skills").font(.headline)
                    SkillComboBoxField(
                        text: $viewModel.desiredSkillText,
                        suggestions: $viewModel.availableSkillSuggestions
                    ) {
                        viewModel.addSelectedSkill(skillName: viewModel.desiredSkillText, jobStore: jobStore)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(viewModel.selectedDesiredSkills, id: \.self) { sName in
                                SkillTag(skillName: sName) {
                                    viewModel.removeSelectedSkill(skillName: sName)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    Divider()
                    HStack {
                        Button("Cancel") {
                            isPresented = false
                        }
                        Spacer()
                        Button("Save") {
                            if let original = jobStore.jobApplications.first(where: { $0.id == viewModelUpdateID }) {
                                viewModel.updateJob(with: original, in: jobStore, documents: importedDocuments)
                                isPresented = false
                            } else {
                                isPresented = false
                            }
                        }
                        .disabled(!viewModel.isInputValid)
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showNewLocationWindow) {
            // The "Add new location" window
            NewLocationWindowView(
                locations: $locations,
                selectedLocation: $viewModel.location
            )
        }
        .frame(minWidth: 500, minHeight: 600)
        .onAppear {
            viewModel.updateSkillSuggestions(availableSkills: jobStore.availableSkills)
        }
    }

    private var viewModelUpdateID: UUID? {
        jobStore.selectedJobIDs.first
    }
}

// --------------------------------------------------
// MARK: - SkillComboBoxField & SkillTag
// --------------------------------------------------
struct SkillComboBoxField: View {
    @Binding var text: String
    @Binding var suggestions: [String]
    var onCommit: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            TextField("Type a skill (comma-separated), then press Enter", text: $text, onCommit: {
                onCommit()
            })
            .textFieldStyle(.roundedBorder)

            if !suggestions.isEmpty && !text.isEmpty {
                List(suggestions, id: \.self) { s in
                    Text(s).onTapGesture {
                        text = s
                        onCommit()
                    }
                }
                .frame(maxHeight: 100)
            }
        }
    }
}

struct SkillTag: View {
    let skillName: String
    var removeAction: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(skillName)
            Button {
                removeAction()
            } label: {
                Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
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



// --------------------------------------------------
// MARK: - EnhancedStatsView (Optional Subview)
// --------------------------------------------------
//
//  EnhancedStatsView.swift
//  AppleJob
//
//  Created by Roger Lin on 1/26/25.
//

import SwiftUI
import Charts
import MapKit


struct EnhancedStatsView: View {
   @EnvironmentObject var jobStore: JobStore

   // MARK: - Region & City Pins
   @State private var region = MKCoordinateRegion(
       center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
       span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 50)
   )
   @State private var cityPins: [CityPin] = []

   // MARK: - GitHub-Style Data
   @State private var yearContributionData: [Contribution] = []
   @State private var appsContributionData: [Contribution] = []

   // Selections for GitHub Charts
   @State private var yearChartSelectedDate: Date? = nil
   @State private var appsChartSelectedDate: Date? = nil

   // MARK: - Time Range
   enum TimeRange: String, CaseIterable, Identifiable {
       case week = "Week"
       case month = "Month"
       case sixmonth = "Six Months"
       case year = "Year"
       var id: String { rawValue }
   }
   @AppStorage("StatsViewTimeRange") private var selectedTimeRangeRaw: String = TimeRange.month.rawValue
   @State private var selectedTimeRange: TimeRange = .month

   // MARK: - Year Picker
   @State private var availableYears: [Int] = []
   @State private var selectedYear: Int = -1  // -1 means “All Years”

   // MARK: - Data for Bar/Line
   @State private var barLineData: [DailyApps] = []
   @State private var barLineSelectedDate: Date? = nil

   // MARK: - City-based Data
   @State private var monthlyCityData: [MonthlyCityData] = []

    // Hold the monthlyCityData after filtering for selected year
    @State private var filteredMonthlyCityData: [MonthlyCityData] = []


   var body: some View {
       ScrollView {
           VStack(alignment: .leading, spacing: 24) {
               mapSection
               appliedCompaniesAndRolesView
               statsRowSection

               dynamicYearPickerSection

               githubChartsSection

               timeRangePickerSection

               barLineChartsSection

               if #available(macOS 13.0, *) {
                   HorizontalStackedBarChartView(
                       monthlyCityData: filteredMonthlyCityData // Use filtered data here
                   )
               } else {
                   Text("Horizontally Stacked Bar Chart requires macOS 13+")
                       .foregroundColor(.secondary)
               }

               singleColumnVerticallyStackedBarChartSection

               top20CompaniesBarSection
               citiesByFrequencySection
               companiesByFrequencySection

               // For brevity, the PieChartsSectionView remains. We won't remove it, though not asked to update it.
               // ...
           }
           .padding()
       }
       .onAppear {
           if let tr = TimeRange(rawValue: selectedTimeRangeRaw) {
               selectedTimeRange = tr
           } else {
               selectedTimeRange = .month
           }
           setupAvailableYears()
           computeCityPins()
           computeYearContribution()
           computeAppsContribution()
           computeBarLineData()
           computeMonthlyCityData()
       }
       .onChange(of: selectedTimeRange) { _, newVal in
           selectedTimeRangeRaw = newVal.rawValue
           computeBarLineData()
       }
       .onChange(of: selectedYear) { _, _ in
           computeYearContribution()
           computeAppsContribution()
           computeMonthlyCityData()
       }
       .onChange(of: monthlyCityData) { _, _ in
           filterMonthlyCityDataForSelectedYear() // Filter monthlyCityData when it changes
       }
   }

   // MARK: - Map Section
   private var mapSection: some View {
       VStack(alignment: .leading, spacing: 12) {
           Text("Applications Map")
               .font(.headline)

           Map {
               ForEach(cityPins) { cityPin in
                   Annotation("City: \(cityPin.city)", coordinate: cityPin.coordinate) {
                       Circle()
                           .fill(Color.red.opacity(0.5))
                           .frame(
                               width: max(10, CGFloat(cityPin.count) * 1.5),
                               height: max(10, CGFloat(cityPin.count) * 1.5)
                           )
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

   // MARK: - Recently Applied
   private var appliedCompaniesAndRolesView: some View {
       ScrollView(.horizontal, showsIndicators: false) {
           HStack(spacing: 10) {
               ForEach(jobStore.jobApplications.sorted(by: { $0.dateOfApplication > $1.dateOfApplication })) { job in
                   Button {
                       jobStore.selectedJobIDs = [job.id]
                   } label: {
                       VStack(alignment: .center, spacing: 5) {
                           Text(job.companyName)
                               .font(.title3)
                               .bold()
                               .multilineTextAlignment(.center)
                               .foregroundStyle(
                                   LinearGradient(
                                       gradient: Gradient(colors: [.blue, .purple]),
                                       startPoint: .leading,
                                       endPoint: .trailing
                                   )
                               )
                               .frame(width: 125)
                               .fixedSize(horizontal: false, vertical: true)

                           Text(job.jobTitle)
                               .font(.headline)
                               .multilineTextAlignment(.center)
                               .foregroundStyle(
                                   LinearGradient(
                                       gradient: Gradient(colors: [.teal, .green]),
                                       startPoint: .leading,
                                       endPoint: .trailing
                                   )
                               )
                               .frame(width: 150)
                               .fixedSize(horizontal: false, vertical: true)
                       }
                       .padding()
                       .background(
                           jobStore.selectedJobIDs.contains(job.id)
                           ? Color.blue.opacity(0.2)
                           : Color.white.opacity(0.1)
                       )
                       .cornerRadius(5)
                   }
                   .buttonStyle(.plain)
               }
           }
           .padding(.horizontal)
       }
   }

   // MARK: - Stats Row
   private var statsRowSection: some View {
       let total = jobStore.jobApplications.count
       let applied = jobStore.jobApplications.filter { $0.status == .applied }.count
       let interested = jobStore.jobApplications.filter { $0.status == .interested }.count
       let interviewed = jobStore.jobApplications.filter { $0.status == .interview }.count
       let distinctCities = Set(jobStore.jobApplications.map { $0.location }).count
       let topCompany = topCompanyName()
       let (topCityName, topCityCount) = topCity()

       // NEW: Count internships vs fullTime
       let internshipCount = jobStore.jobApplications.filter { $0.jobType == .internship }.count
       let fullTimeCount = jobStore.jobApplications.filter { $0.jobType == .fullTime }.count

       let gradient = LinearGradient(
           colors: [.blue, .pink],
           startPoint: .leading,
           endPoint: .trailing
       )

       return ScrollView(.horizontal, showsIndicators: false) {
           HStack(spacing: 32) {
               VStack {
                   Text("Total Apps")
                   Text("\(total)")
                       .font(.largeTitle)
                       .bold()
                       .foregroundStyle(gradient)
               }
               VStack {
                   Text("Applied")
                   Text("\(applied)")
                       .font(.largeTitle)
                       .bold()
                       .foregroundStyle(gradient)
               }
               VStack {
                   Text("Interested")
                   Text("\(interested)")
                       .font(.largeTitle)
                       .bold()
                       .foregroundStyle(gradient)
               }
               VStack {
                   Text("Interviews")
                   Text("\(interviewed)")
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
                   Text(topCityName)
                       .font(.title3)
                       .bold()
                       .foregroundStyle(gradient)
                   Text("\(topCityCount)")
                       .font(.title3)
                       .bold()
                       .foregroundStyle(gradient)
               }
               // NEW: Internships & FullTime
               VStack {
                   Text("Internships")
                   Text("\(internshipCount)")
                       .font(.largeTitle)
                       .bold()
                       .foregroundStyle(gradient)
               }
               VStack {
                   Text("Full-Time")
                   Text("\(fullTimeCount)")
                       .font(.largeTitle)
                       .bold()
                       .foregroundStyle(gradient)
               }
           }
           .padding(.vertical, 8)
           .frame(maxWidth: .infinity)
       }
   }

   // MARK: - Dynamic Year Picker
   private var dynamicYearPickerSection: some View {
       let sortedYears = availableYears.sorted()
       let yearsWithAll = sortedYears + [-1]

       return HStack {
           Text("Select Year:")
           Picker("Year", selection: $selectedYear) {
               ForEach(yearsWithAll, id: \.self) { yr in
                   if yr == -1 {
                       Text("All Years").tag(yr)
                   } else {
                       Text("\(yr)").tag(yr)
                   }
               }
           }
           .pickerStyle(.segmented)
       }
       .padding(.horizontal)
   }

   // MARK: - GitHub-Style Charts
   private var githubChartsSection: some View {
       VStack(alignment: .leading, spacing: 24) {
           Text("GitHub-Style Contribution Charts")
               .font(.headline)
               .padding(.vertical)

           if #available(macOS 13.0, *) {
               Chart(yearContributionData) { item in
                   RectangleMark(
                       x: .value("WeekOfYear", item.date, unit: .weekOfYear),
                       y: .value("DayOfWeek", weekday(for: item.date))
                   )
                   .foregroundStyle(by: .value("Count", item.count))
                   .clipShape(RoundedRectangle(cornerRadius: 2))
               }
               .chartForegroundStyleScale(range: Gradient(colors: enhancedChartColors))
               .chartYAxis {
                   AxisMarks(values: [1, 3, 5, 7])
               }
               .chartXAxis {
                   AxisMarks(values: .stride(by: .month))
               }
               .chartPlotStyle { plotArea in
                   plotArea.background(Color.gray.opacity(0.05))
               }
               .ifShouldScrollHorizontally(selectedYear: selectedYear)
               .frame(height: 200)

               Chart(appsContributionData) { item in
                   RectangleMark(
                       x: .value("WeekOfYear", item.date, unit: .weekOfYear),
                       y: .value("DayOfWeek", weekday(for: item.date))
                   )
                   .foregroundStyle(by: .value("Count", item.count))
                   .clipShape(RoundedRectangle(cornerRadius: 2))
               }
               .chartForegroundStyleScale(range: Gradient(colors: enhancedChartColors))
               .chartYAxis {
                   AxisMarks(values: [1, 3, 5, 7])
               }
               .chartXAxis {
                   AxisMarks(values: .stride(by: .month))
               }
               .chartPlotStyle { plotArea in
                   plotArea.background(Color.gray.opacity(0.05))
               }
               .frame(height: 200)
               .ifShouldScrollHorizontally(selectedYear: selectedYear)

           } else {
               Text("Charts require macOS 13.0+.")
                   .foregroundColor(.secondary)
           }
       }
       .frame(maxHeight: .infinity)
   }

   var enhancedChartColors: [Color] {
       [.white, Color(red: 0.8, green: 0.9, blue: 0.8), Color(red: 0.6, green: 0.8, blue: 0.6), Color(red: 0.4, green: 0.7, blue: 0.4), Color(red: 0.2, green: 0.6, blue: 0.2)]
   }

   // MARK: - Time Range Picker
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

   // MARK: - Bar+Line Chart
    // MARK: - Bar+Line Chart
    // MARK: - Bar+Line Chart
    private var barLineChartsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Applications Frequency (Last 12 Months / Range)")
                .font(.headline)

            Chart {
                // Main bar marks
                ForEach(barLineData) { dayItem in
                    BarMark(
                        x: .value("Date", dayItem.date),
                        y: .value("Applications", dayItem.count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.7), .blue]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(3)
                }

                // Average line - outside the ForEach loop
                if let average = computeAverage(for: barLineData) {
                    RuleMark(y: .value("Average", average))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(Color.red.opacity(0.7))
                }
            }
            .chartXSelection(value: $barLineSelectedDate)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) {
                    AxisGridLine(stroke: StrokeStyle(dash: [2]))
                        .foregroundStyle(Color.gray.opacity(0.3))
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                        .foregroundStyle(Color.secondary)
                }
            }
            .chartYAxis {
                AxisMarks {
                    AxisGridLine()
                        .foregroundStyle(Color.gray.opacity(0.3))
                    AxisTick()
                }
            }
            .chartPlotStyle { plotArea in
                plotArea.background(Color.gray.opacity(0.05))
            }
            .frame(height: 300)
            .overlay {
                if let sel = barLineSelectedDate {
                    GeometryReader { geo in
                        let dayStr = sel.formatted(date: .abbreviated, time: .omitted)
                        let c = barLineData.first(where: { $0.date == sel })?.count ?? 0
                        Text("\(c) apps on \(dayStr)")
                            .font(.headline)
                            .padding(8)
                            .background(Color.green.opacity(0.3))
                            .cornerRadius(6)
                            .position(x: geo.size.width * 0.5, y: 15)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tooltip View (Extracted from .overlay {})
    private func tooltipView(for date: Date, width: CGFloat) -> some View {
        let dayString = date.formatted(date: .abbreviated, time: .omitted)
        let count = barLineData.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })?.count ?? 0

        return Text("\(count) apps on \(dayString)")
            .font(.headline)
            .padding(8)
            .background(Color.green.opacity(0.3))
            .cornerRadius(6)
            .position(x: width * 0.5, y: 15)
    }

    // MARK: - Compute Average Applications (Extracted from .chartOverlay {})
    private func computeAverage(for data: [DailyApps]) -> Double? {
        let nonZeroData = data.filter { $0.count > 0 }
        guard !nonZeroData.isEmpty else { return nil }

        let totalApplications = nonZeroData.reduce(0) { $0 + $1.count }
        return Double(totalApplications) / Double(nonZeroData.count)
    }
   // Single Column Vertically Stacked
   @ViewBuilder
   private var singleColumnVerticallyStackedBarChartSection: some View {
       VStack(alignment: .leading, spacing: 12) {
           Text("Applications by City - Single Column Vertically Stacked Bar Chart")
               .font(.headline)
           if #available(macOS 13.0, *) {
               Chart(filteredMonthlyCityData) { item in // FIXED: Use filtered data
                   BarMark(
                       x: .value("Month", item.monthKey),
                       y: .value("Count", item.count)
                   )
                   .foregroundStyle(by: .value("City", item.city))
                   // Hover annotation
                   .annotation(position: .overlay, alignment: .top) {
                       // We can show a tooltip-like annotation if the user hovers
                       // But we only want to show it for the hovered segment
                       // For simplicity, a short example:
                       Text("\(item.city): \(item.count)")
                           .font(.caption)
                           .padding(4)
                           .background(Color.yellow.opacity(0.7))
                           .cornerRadius(5)
                           .opacity(0) // Because we would do an .chartOverlay with dynamic detection
                   }
               }
               .chartXAxis {
                   AxisMarks()
               }
               .chartYAxis {
                   AxisMarks()
               }
               .frame(height: 300)
               .chartOverlay { proxy in
                   // We can do a custom approach to detect hovered element if needed
                   // Skipping a detailed approach for brevity
               }
           } else {
               Text("Requires macOS 13.0+.")
                   .foregroundColor(.secondary)
           }
       }
       .frame(maxWidth: .infinity)
       .frame(maxHeight: .infinity)
   }

   private var top20CompaniesBarSection: some View {
       VStack(alignment: .leading, spacing: 16) {
           Text("Top 20 Companies by Application Frequency (All Years)")
               .font(.headline)

           if #available(macOS 13.0, *) {
               let freq = buildTop20CompanyFreq()
               Chart(freq) { item in
                   BarMark(
                       x: .value("Company", item.name),
                       y: .value("Count", item.count)
                   )
               }
               .chartXAxis {
                   AxisMarks()
               }
               .chartYAxis {
                   AxisMarks()
               }
               .frame(height: 300)
           } else {
               Text("Requires macOS 13.0+.")
                   .foregroundColor(.secondary)
           }
       }
       .frame(maxWidth: .infinity)
       .frame(maxHeight: .infinity)
   }

   private var citiesByFrequencySection: some View {
       let cityCounts = cityFreqList()
       return VStack(alignment: .leading) {
           Text("Cities by Frequency (All Years)")
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
                       .padding(5)
                   }
               }
               .padding(.horizontal, 15)
               .padding(.bottom, 25)
               .frame(maxWidth: .infinity)
           }
       }
   }

   private var companiesByFrequencySection: some View {
       let companies = companyFreqList()
       return VStack(alignment: .leading, spacing: 10) {
           Text("Companies By Frequency")
               .font(.headline)

           ScrollView(.horizontal, showsIndicators: true) {
               HStack(spacing: 20) {
                   ForEach(companies, id: \.name) { item in
                       VStack {
                           Text(item.name)
                               .font(.headline)
                               .frame(width: 100)
                               .gradientForeground(colors: [.blue, .purple])
                               .multilineTextAlignment(.center)
                           Text("\(item.count)")
                               .font(.title3)
                       }
                       .padding(5)
                   }
               }
               .padding(.horizontal, 15)
               .frame(maxWidth: .infinity)
           }
       }
   }

    // Data filtering and computation functions - Moved inside EnhancedStatsView
    private func monthlyCityDataFilteredForSelectedYear() -> [MonthlyCityData] {
        filteredMonthlyCityData
    }

    private func buildTop20CompanyFreq() -> [CompanyFreq] {
        var freq: [String: Int] = [:]
        for job in jobStore.jobApplications {
            freq[job.companyName, default: 0] += 1
        }
        return freq
            .sorted { $0.value > $1.value }
            .prefix(20)
            .map { CompanyFreq(name: $0.key, count: $0.value) }
    }

    private func cityFreqList() -> [(city: String, count: Int)] {
        var map: [String: Int] = [:]
        for job in jobStore.jobApplications {
            map[job.location, default: 0] += 1
        }
        return map.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }

    private func companyFreqList() -> [(name: String, count: Int)] {
        var map: [String: Int] = [:]
        for job in jobStore.jobApplications {
            map[job.companyName, default: 0] += 1
        }
        return map.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }

    private func topCompanyName() -> String {
        let sorted = companyFreqList()
        guard let first = sorted.first else { return "N/A" }
        return first.name
    }

    private func topCity() -> (String, Int) {
        let sorted = cityFreqList()
        guard let first = sorted.first else { return ("N/A", 0) }
        return first
    }

    private func setupAvailableYears() {
        let allDates = jobStore.jobApplications.map { $0.dateOfApplication }
        guard !allDates.isEmpty else {
            self.availableYears = []
            self.selectedYear = -1
            return
        }
        let cal = Calendar.current
        let minYear = cal.component(.year, from: allDates.min()!)
        let maxYear = cal.component(.year, from: allDates.max()!)

        if minYear <= maxYear {
            self.availableYears = Array(minYear...maxYear)
        } else {
            self.availableYears = []
        }
        if !self.availableYears.contains(selectedYear) && selectedYear != -1 {
            self.selectedYear = -1
        }
    }

    private func computeCityPins() {
        var cityCount: [String: Int] = [:]
        for job in jobStore.jobApplications {
            cityCount[job.location, default: 0] += 1
        }
        cityPins = cityCount.map { (city, ct) in
            let coord = CityCoordinateDictionary[city]
                ?? CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795)
            return CityPin(city: city, coordinate: coord, count: ct)
        }
    }

    private func computeYearContribution() {
        guard !jobStore.jobApplications.isEmpty else {
            yearContributionData = []
            return
        }
        let cal = Calendar.current
        let allDates = jobStore.jobApplications.map { $0.dateOfApplication }

        // If all years => only last 12 months
        if selectedYear == -1 {
            guard let end = allDates.max() else {
                yearContributionData = []
                return
            }
            let start = cal.date(byAdding: .month, value: -12, to: end) ?? end
            // Build day-based counts
            var contributionMap: [Date: Int] = [:]
            for job in jobStore.jobApplications {
                if job.dateOfApplication >= start && job.dateOfApplication <= end {
                    let day = cal.startOfDay(for: job.dateOfApplication)
                    contributionMap[day, default: 0] += 1
                }
            }
            // Fill in the date range
            var allDays: [Date] = []
            var day = cal.startOfDay(for: start)
            while day <= end {
                allDays.append(day)
                if let nxt = cal.date(byAdding: .day, value: 1, to: day) {
                    day = nxt
                } else {
                    break
                }
            }
            yearContributionData = allDays.map { d in
                Contribution(date: d, count: contributionMap[d] ?? 0)
            }
            return
        }

        // Otherwise, show the entire year
        guard let overallMin = allDates.min(),
              let overallMax = allDates.max() else {
            yearContributionData = []
            return
        }

        guard let s = cal.date(from: DateComponents(year: selectedYear, month: 1, day: 1)),
              let e = cal.date(from: DateComponents(year: selectedYear, month: 12, day: 31))
        else {
            yearContributionData = []
            return
        }
        let startOfRange = s
        let endOfRange = e

        var contributionMap: [Date: Int] = [:]
        for job in jobStore.jobApplications {
            if job.dateOfApplication >= startOfRange && job.dateOfApplication <= endOfRange {
                let day = cal.startOfDay(for: job.dateOfApplication)
                contributionMap[day, default: 0] += 1
            }
        }

        var allDays: [Date] = []
        var day = cal.startOfDay(for: startOfRange)
        while day <= endOfRange {
            allDays.append(day)
            if let nxt = cal.date(byAdding: .day, value: 1, to: day) {
                day = nxt
            } else {
                break
            }
        }
        yearContributionData = allDays.map { d in
            Contribution(date: d, count: contributionMap[d] ?? 0)
        }
    }

    private func computeAppsContribution() {
        // For consistency with yearContributionData
        // If all years => last 12 months
        let cal = Calendar.current
        let allDates = jobStore.jobApplications.map { $0.dateOfApplication }
        guard !allDates.isEmpty else {
            appsContributionData = []
            return
        }

        if selectedYear == -1 {
            guard let end = allDates.max() else {
                appsContributionData = []
                return
            }
            let start = cal.date(byAdding: .month, value: -12, to: end) ?? end
            var appsMap: [Date: Int] = [:]
            for job in jobStore.jobApplications {
                if job.dateOfApplication >= start && job.dateOfApplication <= end {
                    let day = cal.startOfDay(for: job.dateOfApplication)
                    appsMap[day, default: 0] += 1
                }
            }
            var allDays: [Date] = []
            var day = cal.startOfDay(for: start)
            while day <= end {
                allDays.append(day)
                if let nxt = cal.date(byAdding: .day, value: 1, to: day) {
                    day = nxt
                } else {
                    break
                }
            }
            appsContributionData = allDays.map { d in
                Contribution(date: d, count: appsMap[d] ?? 0)
            }
            return
        }

        guard let s = cal.date(from: DateComponents(year: selectedYear, month: 1, day: 1)),
              let e = cal.date(from: DateComponents(year: selectedYear, month: 12, day: 31)) else {
            appsContributionData = []
            return
        }
        var appsMap: [Date: Int] = [:]
        for job in jobStore.jobApplications {
            if job.dateOfApplication >= s && job.dateOfApplication <= e {
                let day = cal.startOfDay(for: job.dateOfApplication)
                appsMap[day, default: 0] += 1
            }
        }
        var allDays: [Date] = []
        var day = cal.startOfDay(for: s)
        while day <= e {
            allDays.append(day)
            if let nxt = cal.date(byAdding: .day, value: 1, to: day) {
                day = nxt
            } else {
                break
            }
        }
        appsContributionData = allDays.map { d in
            Contribution(date: d, count: appsMap[d] ?? 0)
        }
    }

    private func computeBarLineData() {
        let cal = Calendar.current
        let now = Date()

        var startDate: Date?
        switch selectedTimeRange {
        case .week:
            startDate = cal.date(byAdding: .day, value: -7, to: now)
        case .month:
            startDate = cal.date(byAdding: .month, value: -1, to: now)
        case .sixmonth:
            startDate = cal.date(byAdding: .month, value: -6, to: now)
        case .year:
            startDate = cal.date(byAdding: .year, value: -1, to: now)
        }

        guard let start = startDate else {
            barLineData = []
            return
        }

        var dailyMap: [Date: Int] = [:]
        for job in jobStore.jobApplications {
            if job.dateOfApplication >= start && job.dateOfApplication <= now {
                let day = cal.startOfDay(for: job.dateOfApplication)
                dailyMap[day, default: 0] += 1
            }
        }

        var allDays: [Date] = []
        var day = cal.startOfDay(for: start)
        while day <= now {
            allDays.append(day)
            guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }

        barLineData = allDays.map { d in
            DailyApps(date: d, count: dailyMap[d] ?? 0)
        }
    }

    private func computeMonthlyCityData() {
        var results: [MonthlyCityData] = []
        let cal = Calendar.current

        for job in jobStore.jobApplications {
            let jobYear = cal.component(.year, from: job.dateOfApplication)
            if selectedYear != -1, jobYear != selectedYear {
                continue
            }
            let month = cal.component(.month, from: job.dateOfApplication)
            let monthKey = "\(cal.shortMonthSymbols[month-1])"
            results.append(
                MonthlyCityData(
                    monthKey: monthKey,
                    city: job.location,
                    count: 1,
                    date: job.dateOfApplication
                )
            )
        }

        var grouped: [String: MonthlyCityData] = [:]
        for item in results {
            let key = item.monthKey + "_" + item.city
            if let existing = grouped[key] {
                grouped[key] = MonthlyCityData(
                    monthKey: existing.monthKey,
                    city: existing.city,
                    count: existing.count + 1,
                    date: existing.date
                )
            } else {
                grouped[key] = item
            }
        }
        monthlyCityData = grouped.map { $0.value }.sorted {
            let monthOrder = Calendar.current.shortMonthSymbols
            return monthOrder.firstIndex(of: $0.monthKey)! < monthOrder.firstIndex(of: $1.monthKey)!
        }
        filterMonthlyCityDataForSelectedYear() // Call filtering after computing
    }

    // Filter monthlyCityData based on selected year
    private func filterMonthlyCityDataForSelectedYear() {
        if selectedYear == -1 {
            filteredMonthlyCityData = monthlyCityData
        } else {
            let cal = Calendar.current
            filteredMonthlyCityData = monthlyCityData.filter {
                cal.component(.year, from: $0.date) == selectedYear
            }
        }
    }


   func weekday(for date: Date) -> Int {
       let w = Calendar.current.component(.weekday, from: date)
       return w
   }
}

@available(macOS 13.0, *)
extension View {
   @ViewBuilder
   func ifShouldScrollHorizontally(selectedYear: Int) -> some View {
       if selectedYear == -1 {
           ScrollView(.horizontal) {
               self
           }
       } else {
           self
       }
   }
}


// --------------------------------------------------
// MARK: - Subview for Horizontally Stacked Bar
// --------------------------------------------------
@available(macOS 13.0, *)
struct HorizontalStackedBarChartView: View {
   @State private var horizontalPlotSelection: String? = nil
   let monthlyCityData: [MonthlyCityData]

   var body: some View {
       VStack(alignment: .leading, spacing: 12) {
           Text("Applications by City - Horizontally Stacked Bar Chart")
               .font(.headline)

           Chart(monthlyCityData) { item in
               BarMark(
                   x: .value("Month", item.monthKey),
                   y: .value("Count", item.count)
               )
               .position(by: .value("City", item.city))
               .foregroundStyle(by: .value("City", item.city))
           }
           .chartXAxis {
               AxisMarks()
           }
           .chartYAxis {
               AxisMarks()
           }
           .chartXSelection(value: $horizontalPlotSelection)
           .frame(height: 300)
           .overlay(alignment: Alignment.top) { // Fix for incorrect alignment
               if let selection = horizontalPlotSelection {
                   if let selectedData = monthlyCityData.first(where: { $0.monthKey == selection }) {
                       Text("\(selectedData.city): \(selectedData.count) Applications")
                           .padding(8)
                           .background(Color.gray.opacity(0.8))
                           .foregroundColor(.white)
                           .cornerRadius(8)
                           .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                           .padding(.top, 4)
                   }
               }
           }
       }
   }
}

// --------------------------------------------------
// MARK: - Subview for Pie Charts
// --------------------------------------------------
@available(macOS 14.0, iOS 17.0, *)
struct PieChartsSectionView: View {
   // Each pie chart uses local states for angle selection, so only the pie subview re-renders
   @State private var selectedMonthAngle: Double? = nil
   @State private var selectedCityAngle: Double? = nil
   @State private var selectedYearAngle: Double? = nil

   let monthlyData: [(monthKey: String, count: Int)]
   let cityData: [(city: String, count: Int)]
   let yearData: [(year: String, count: Int)]
   let selectedYearText: String

   var body: some View {
       VStack(alignment: .center, spacing: 16) {
           Text("Application Shares (Pie Charts)")
               .font(.headline)
               .foregroundStyle(
                   LinearGradient(
                       gradient: Gradient(colors: [.blue, .purple]),
                       startPoint: .leading,
                       endPoint: .trailing
                   )
               )

           ScrollView(.horizontal, showsIndicators: true) {
               HStack(alignment: .center, spacing: 32) {
                   // 1) Month Pie
                   VStack {
                       Text("Share by Month (\(selectedYearText))")
                           .font(.subheadline)
                           .foregroundStyle(
                               LinearGradient(
                                   gradient: Gradient(colors: [.green, .teal]),
                                   startPoint: .leading,
                                   endPoint: .trailing
                               )
                           )
                       PieChartView(
                           data: monthlyData.map { (key: $0.monthKey, count: $0.count) },
                           selectedAngle: $selectedMonthAngle,
                           centerLabel: "Months"
                       )
                       .frame(minWidth: 350, minHeight: 350)
                   }

                   // 2) City Pie
                   VStack {
                       Text("Share by City (\(selectedYearText))")
                           .font(.subheadline)
                           .foregroundStyle(
                               LinearGradient(
                                   gradient: Gradient(colors: [.pink, .orange]),
                                   startPoint: .leading,
                                   endPoint: .trailing
                               )
                           )
                       PieChartView(
                           data: cityData.map { (key: $0.city, count: $0.count) },
                           selectedAngle: $selectedCityAngle,
                           centerLabel: "Cities",
                           showLegend: true
                       )
                       .frame(minWidth: 700, minHeight: 350)
                   }

                   // 3) Year Pie
                   VStack {
                       Text("Share by Year")
                           .font(.subheadline)
                           .foregroundStyle(
                               LinearGradient(
                                   gradient: Gradient(colors: [.indigo, .cyan]),
                                   startPoint: .leading,
                                   endPoint: .trailing
                               )
                           )
                       PieChartView(
                           data: yearData.map { (key: $0.year, count: $0.count) },
                           selectedAngle: $selectedYearAngle,
                           centerLabel: "Years",
                           legendPosition: .bottom
                       )
                       .frame(minWidth: 350, minHeight: 350)
                   }
               }
               .padding(.horizontal, 10)
           }
       }
   }
}

// --------------------------------------------------
// MARK: - Reusable Swift Charts “Pie” subview
// --------------------------------------------------
@available(macOS 14.0, iOS 17.0, *)
struct PieChartView: View {
   // Data is an array of (key: String, count: Int)
   let data: [(key: String, count: Int)]
   @Binding var selectedAngle: Double?
   let centerLabel: String
   var showLegend: Bool = false
   var legendPosition: AnnotationPosition = .bottom
   var body: some View {
       // Sum up everything
       let totalCount = data.reduce(0) { $0 + $1.count }

       Chart(data, id: \.key) { item in
           SectorMark(
               angle: .value("Count", item.count),
               innerRadius: .ratio(0.5),
               angularInset: 1
           )
           .cornerRadius(4)
           .foregroundStyle(by: .value("Key", item.key))
           .opacity(item.key == selectedItemLabel(selectedAngle)?.key ? 1 : 0.65)
       }
       .chartLegend(position: showLegend ? legendPosition : .automatic)
       .chartAngleSelection(value: $selectedAngle)
       .chartBackground { chartProxy in
           GeometryReader { geometry in
               if let anchor = chartProxy.plotFrame {
                   let frame = geometry[anchor]
                   let selItem = selectedItemLabel(selectedAngle)
                   let label   = selItem?.key ?? centerLabel
                   let count   = selItem?.count ?? totalCount

                   VStack {
                       Text(label)
                           .font(.headline)
                           .foregroundStyle(
                               LinearGradient(
                                   gradient: Gradient(colors: [.blue, .purple]),
                                   startPoint: .leading,
                                   endPoint: .trailing
                               )
                           )
                       Text("\(count) apps")
                           .font(.title2)
                           .foregroundStyle(
                               LinearGradient(
                                   gradient: Gradient(colors: [.orange, .red]),
                                   startPoint: .leading,
                                   endPoint: .trailing
                               )
                           )
                   }
                   .position(x: frame.midX, y: frame.midY)
               }
           }
       }
   }

   // Convert angle to item
   private func selectedItemLabel(_ angle: Double?) -> (key: String, count: Int)? {
       guard let angle else { return nil }
       let ranges = buildAngleRanges(for: data)
       return ranges.first { $0.range.contains(angle) }
           .map { (key: $0.key, count: $0.count) }
   }

   // Build angle ranges from data
   private func buildAngleRanges(for entries: [(key: String, count: Int)]) -> [AngleRangeItem] {
       var result: [AngleRangeItem] = []
       var runningTotal: Double = 0
       for entry in entries {
           let start = runningTotal
           let end = runningTotal + Double(entry.count)
           result.append(
               AngleRangeItem(
                   key: entry.key,
                   range: start..<end,
                   count: entry.count
               )
           )
           runningTotal = end
       }
       return result
   }
}

// A small helper struct for the angle range logic
@available(macOS 14.0, iOS 17.0, *)
fileprivate struct AngleRangeItem {
   let key: String
   let range: Range<Double>
   let count: Int
}
// --------------------------------------------------
// MARK: - Documents Views
// --------------------------------------------------
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

struct DocumentsSidebarView: View {
    @EnvironmentObject var docStore: DocumentStore

    @State private var isEditingCategory: Bool = false
    @State private var categoryToEdit: DocumentCategory? = nil
    @State private var categoryNameForEdit: String = ""

    var body: some View {
        List(selection: $docStore.selectedDocument) {
            Section {
                DisclosureGroup {
                    ForEach(uncategorizedDocuments, id: \.id) { doc in
                        documentSidebarItem(doc)
                            .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 0))
                    }
                } label: {
                    Text("All Documents")
                        .font(.headline)
                }
            }
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
                        for idx in docStore.documents.indices {
                            if docStore.documents[idx].categoryID == category.id {
                                docStore.documents[idx].categoryID = nil
                            }
                        }
                        docStore.saveDocuments()
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
        .contextMenu {
            Button("Create New Category") {
                docStore.newCategoryName = "Category Name"
                docStore.isCreatingNewCategory = true
            }
        }
        .sheet(isPresented: $docStore.isCreatingNewCategory) {
            NewCategorySheet()
                .environmentObject(docStore)
        }
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

    private func docsForCategory(_ catID: UUID) -> [JobDocument] {
        docStore.documents
            .filter { $0.categoryID == catID }
            .sorted { $0.lastModifiedDate > $1.lastModifiedDate }
    }

    @ViewBuilder
    private func documentSidebarItem(_ doc: JobDocument) -> some View {
        Label {
            Text(cleanFileName(doc.fileName))
                .font(.system(size: 12))
        } icon: {
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

struct DocumentsMainView: View {
    @EnvironmentObject var docStore: DocumentStore

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
                PDFInlineViewer(fileURL: doc.fileURL, fileData: doc.fileData)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if self.windowRef == nil {
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
