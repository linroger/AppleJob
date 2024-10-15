
//
//  AppleJob.swift
//  AppleJob
//
//  Created by Your Name on YYYY/MM/DD
//

import SwiftUI
import Foundation
import CoreLocation
import UniformTypeIdentifiers
import PDFKit
import MapKit
import Charts
import Quartz
import QuickLook
import QuickLookUI
import MarkdownKit
import AppKit

// MARK: - Protocols

protocol CaseNameDisplayable: RawRepresentable, CaseIterable where RawValue == String, AllCases: Collection {
    func caseNameForDisplay() -> String
}

extension CaseNameDisplayable {
    func caseNameForDisplay() -> String {
        return self.rawValue
    }
}

// MARK: - Enums

enum JobType: String, CaseIterable, Codable, CaseNameDisplayable, Hashable {
    case internship = "Internship"
    case fullTime = "Full Time"
    case offCycleInternship = "Off-Cycle Internship"
    case none = "None" // Default value if no type is selected

    var displayName: String {
        return self.caseNameForDisplay()
    }
}

enum JobStatus: String, CaseIterable, Codable, CaseNameDisplayable, Hashable {
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

enum Sort: String, CaseIterable, CaseNameDisplayable, Hashable {
    case title = "Job Title"
    case company = "Company Name"
    case recentlyApplied = "Recently Applied"

    var displayName: String {
        return self.caseNameForDisplay()
    }
}

// MARK: - Models

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
        self.fileData = fileData
        self.fileURL = fileURL
        self.creationDate = creation
        self.lastModifiedDate = lastModified
        self.fileSize = fileSize ?? fileData.count
        self.wordCount = wordCount ?? 0
        self.categoryID = categoryID
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

struct JobApplication: Codable, Identifiable, Hashable {
    var id: UUID  // Changed from let to var to allow mutation where needed
    var companyName: String
    var jobTitle: String
    var status: JobStatus
    var dateOfApplication: Date
    var applicationDeadline: Date
    var location: String
    var linkToJob: String?
    var salary: Double?
    var jobDescription: String
    var coverLetter: String
    var notes: String?
    var isFavorite: Bool
    var documents: [JobDocument]
    var jobType: JobType
    var desiredSkills: [String]

    init(
        id: UUID = UUID(),
        companyName: String,
        jobTitle: String,
        status: JobStatus = .interested,
        dateOfApplication: Date = Date(),
        applicationDeadline: Date = Date(),
        location: String,
        linkToJob: String? = nil,
        salary: Double? = nil,
        jobDescription: String = "",
        coverLetter: String = "",
        notes: String? = nil,
        documents: [JobDocument] = [],
        isFavorite: Bool = false,
        jobType: JobType = .none,
        desiredSkills: [String] = []
    ) {
        self.id = id
        self.companyName = companyName
        self.jobTitle = jobTitle
        self.status = status
        self.dateOfApplication = dateOfApplication
        self.applicationDeadline = applicationDeadline
        self.location = location
        self.linkToJob = linkToJob
        self.salary = salary
        self.jobDescription = jobDescription
        self.coverLetter = coverLetter
        self.notes = notes
        self.documents = documents
        self.isFavorite = isFavorite
        self.jobType = jobType
        self.desiredSkills = desiredSkills
    }

    enum CodingKeys: String, CodingKey {
        case id, companyName, jobTitle, statusRawValue, dateOfApplication, applicationDeadline, location, linkToJob, salary, jobDescription, coverLetter, notes, isFavorite, documents, jobType, desiredSkills
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.companyName = try container.decode(String.self, forKey: .companyName)
        self.jobTitle = try container.decode(String.self, forKey: .jobTitle)
        let statusRaw = try container.decode(String.self, forKey: .statusRawValue)
        self.status = JobStatus(rawValue: statusRaw) ?? .interested
        self.dateOfApplication = try container.decode(Date.self, forKey: .dateOfApplication)
        self.applicationDeadline = try container.decode(Date.self, forKey: .applicationDeadline)
        self.location = try container.decode(String.self, forKey: .location)
        self.linkToJob = try? container.decode(String.self, forKey: .linkToJob)
        self.salary = try? container.decode(Double.self, forKey: .salary)
        self.jobDescription = try container.decode(String.self, forKey: .jobDescription)
        self.coverLetter = try container.decode(String.self, forKey: .coverLetter)
        self.notes = try? container.decode(String.self, forKey: .notes)
        self.isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        self.documents = try container.decode([JobDocument].self, forKey: .documents)
        self.jobType = try container.decodeIfPresent(JobType.self, forKey: .jobType) ?? .none
        self.desiredSkills = try container.decodeIfPresent([String].self, forKey: .desiredSkills) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(companyName, forKey: .companyName)
        try container.encode(jobTitle, forKey: .jobTitle)
        try container.encode(status.rawValue, forKey: .statusRawValue)
        try container.encode(dateOfApplication, forKey: .dateOfApplication)
        try container.encode(applicationDeadline, forKey: .applicationDeadline)
        try container.encode(location, forKey: .location)
        try container.encode(linkToJob, forKey: .linkToJob)
        try container.encode(salary, forKey: .salary)
        try container.encode(jobDescription, forKey: .jobDescription)
        try container.encode(coverLetter, forKey: .coverLetter)
        try container.encode(notes, forKey: .notes)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encode(documents, forKey: .documents)
        try container.encode(jobType, forKey: .jobType)
        try container.encode(desiredSkills, forKey: .desiredSkills)
    }
}

// MARK: - Global Variables

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

let predefinedCityNames: [String] = Array(CityCoordinateDictionary.keys).sorted()

// MARK: - View Models and Stores

class JobStore: ObservableObject {
    @Published var jobApplications: [JobApplication] = []
    @Published var selectedJob: JobApplication? = nil
    @Published var isAddingNewJob: Bool = false
    @Published var isEditingJob: Bool = false
    @Published var sorting: Sort = .recentlyApplied
    @Published var incomingJobData: [String: Any]? = nil
    @Published var availableSkills: [DesiredSkill] = []

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
            applicationDeadline: job.dateOfApplication,
            location: job.location,
            linkToJob: job.linkToJob,
            salary: job.salary,
            jobDescription: job.jobDescription,
            coverLetter: job.coverLetter,
            notes: job.notes,
            documents: job.documents,
            isFavorite: job.isFavorite,
            jobType: job.jobType,
            desiredSkills: job.desiredSkills
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

class DocumentStore: ObservableObject {
    @Published var documents: [JobDocument] = []
    @Published var selectedDocument: JobDocument? = nil
    @Published var categories: [DocumentCategory] = []
    @Published var isCreatingNewCategory: Bool = false
    @Published var newCategoryName: String = "Category Name"
    @Published var quickLookURL: URL? = nil
    @Published var isEditingMetadata: Bool = false
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
                    if let cdate = attributes[.creationDate] as? Date { creation = cdate }
                    if let mdate = attributes[.modificationDate] as? Date { modified = mdate }
                }
                if let savedURL = DocumentStore.saveDocumentToAppSupport(originalURL: url, fileName: url.lastPathComponent) {
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
        guard let savedURL = DocumentStore.saveDocumentToAppSupport(originalURL: document.fileURL ?? URL(fileURLWithPath: ""), fileName: document.fileName) else {
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
            documents = try JSONDecoder().decode([JobDocument].self, from: savedData)
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
            categories = try JSONDecoder().decode([DocumentCategory].self, from: savedData)
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
        guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
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

class ImportExportHelper: NSObject, ObservableObject {
    @Published var isImporting: Bool = false
    @Published var isExporting: Bool = false

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

class JobViewModel: ObservableObject {
    @Published var companyName: String = ""
    @Published var jobTitle: String = ""
    @Published var status: JobStatus = .interested
    @Published var dateOfApplication: Date = Date()
    @Published var applicationDeadline: Date = Date()
    @Published var location: String = ""
    @Published var linkToJob: String = ""
    @Published var jobDescription: String = ""
    @Published var coverLetter: String = ""
    @Published var notes: String = ""
    @Published var salaryString: String = ""
    @Published var salaryDouble: Double? = nil
    @Published var jobType: JobType = .none
    @Published var desiredSkillText: String = ""
    @Published var selectedDesiredSkills: [String] = []
    @Published var availableSkillSuggestions: [String] = []

    @Published var isInputValid: Bool = false

    init(job: JobApplication, availableSkills: [DesiredSkill] = []) {
        companyName = job.companyName
        jobTitle = job.jobTitle
        status = job.status
        dateOfApplication = job.dateOfApplication
        applicationDeadline = job.applicationDeadline
        location = job.location
        salaryDouble = job.salary
        salaryString = formatSalaryAsInteger(job.salary)
        // Using our property name "linkToJob" (not linkToJobString)
        linkToJob = job.linkToJob ?? ""
        jobDescription = job.jobDescription
        coverLetter = job.coverLetter
        notes = job.notes ?? ""
        jobType = job.jobType
        selectedDesiredSkills = job.desiredSkills
        self.availableSkillSuggestions = availableSkills.map { $0.name }.sorted()
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

    func formatSalaryAsInteger(_ value: Double?) -> String {
        guard let value = value else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? ""
    }

    func parseSalary(_ value: String) -> Double? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        return formatter.number(from: value)?.doubleValue
    }

    func updateSalary(fromString newValue: String) {
        salaryString = newValue
        salaryDouble = parseSalary(newValue)
    }

    func updateSkillSuggestions(availableSkills: [DesiredSkill]) {
        availableSkillSuggestions = availableSkills.map { $0.name }
            .filter { $0.lowercased().contains(desiredSkillText.lowercased()) }
            .sorted()
    }

    func addSelectedSkill(skillName: String, jobStore: JobStore) {
        if !selectedDesiredSkills.contains(skillName) {
            selectedDesiredSkills.append(skillName)
            desiredSkillText = ""
            if !jobStore.availableSkills.contains(where: { $0.name == skillName }) {
                let newSkill = DesiredSkill(name: skillName)
                jobStore.addJob(JobApplication(companyName: "", jobTitle: "")) // Dummy add to trigger skill addition
                jobStore.availableSkills.append(newSkill)
            }
            updateSkillSuggestions(availableSkills: jobStore.availableSkills)
        }
    }

    func removeSelectedSkill(skillName: String) {
        selectedDesiredSkills.removeAll { $0 == skillName }
    }

    func createJobApplication() -> JobApplication {
        return JobApplication(
            companyName: companyName,
            jobTitle: jobTitle,
            status: status,
            dateOfApplication: dateOfApplication,
            applicationDeadline: applicationDeadline,
            location: location,
            linkToJob: linkToJob.isEmpty ? nil : linkToJob,
            salary: salaryDouble,
            jobDescription: jobDescription,
            coverLetter: coverLetter,
            notes: notes,
            documents: [],
            isFavorite: false,
            jobType: jobType,
            desiredSkills: selectedDesiredSkills
        )
    }

    func addJob(to store: JobStore, documents: [JobDocument]) {
        validateInputs()
        if isInputValid {
            let newJob = JobApplication(
                companyName: companyName,
                jobTitle: jobTitle,
                status: status,
                dateOfApplication: dateOfApplication,
                applicationDeadline: applicationDeadline,
                location: location,
                linkToJob: linkToJob.isEmpty ? nil : linkToJob,
                salary: salaryDouble,
                jobDescription: jobDescription,
                coverLetter: coverLetter,
                notes: notes,
                documents: documents,
                isFavorite: false,
                jobType: jobType,
                desiredSkills: selectedDesiredSkills
            )
            store.addJob(newJob)
        }
    }
    
    func updateJob(with originalJob: JobApplication, in store: JobStore, documents: [JobDocument]) {
        validateInputs()
        if isInputValid {
            let updatedJob = JobApplication(
                id: originalJob.id,
                companyName: companyName,
                jobTitle: jobTitle,
                status: status,
                dateOfApplication: dateOfApplication,
                applicationDeadline: applicationDeadline,
                location: location,
                linkToJob: linkToJob.isEmpty ? nil : linkToJob,
                salary: salaryDouble,
                jobDescription: jobDescription,
                coverLetter: coverLetter,
                notes: notes,
                documents: documents,
                isFavorite: originalJob.isFavorite,
                jobType: jobType,
                desiredSkills: selectedDesiredSkills
            )
            store.editJob(with: updatedJob)
        }
    }

    func reset() {
        companyName = ""
        jobTitle = ""
        status = .interested
        dateOfApplication = Date()
        applicationDeadline = Date()
        location = ""
        linkToJob = ""
        jobDescription = ""
        coverLetter = ""
        notes = ""
        salaryString = ""
        jobType = .none
        selectedDesiredSkills = []
        validateInputs()
    }
}

// MARK: - View Modifiers

struct TranslucentTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(8)
            .background(
                ZStack {
                    PastelGradientBackground()
                    Color.clear.background(Material.ultraThin)
                }
                .opacity(0.5)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(Color(NSColor.tertiaryLabelColor), lineWidth: 0.5)
            )
    }
}

extension View {
    func translucentTextFieldStyle() -> some View {
        self.modifier(TranslucentTextFieldStyle())
    }
}

struct TranslucentTextEditorStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(6)
            .background(
                ZStack {
                    PastelGradientBackground()
                    Color.clear.background(Material.ultraThin)
                }
                .opacity(0.5)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(Color(NSColor.tertiaryLabelColor), lineWidth: 0.5)
            )
    }
}

extension View {
    func translucentTextEditorStyle() -> some View {
        self.modifier(TranslucentTextEditorStyle())
    }
}

// MARK: - AutoGrowingTextEditor

struct AutoGrowingTextEditor: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = false
        scrollView.drawsBackground = false

        let textView = NSTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.delegate = context.coordinator
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = [.width]
        textView.backgroundColor = .clear
        textView.font = NSFont.systemFont(ofSize: 14)
        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
        textView.sizeToFit()
        let newHeight = textView.fittingSize.height
        nsView.frame.size.height = newHeight
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: AutoGrowingTextEditor
        init(_ parent: AutoGrowingTextEditor) {
            self.parent = parent
        }
        func textDidChange(_ notification: Notification) {
            if let textView = notification.object as? NSTextView {
                parent.text = textView.string
            }
        }
    }
}

// MARK: - SkillComboBoxField & SkillTag

struct SkillComboBoxField: View {
    @Binding var text: String
    @Binding var suggestions: [String]
    var onCommit: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            TextField("Type a skill (comma-separated), then press Enter", text: $text, onCommit: {
                onCommit()
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            if !suggestions.isEmpty && !text.isEmpty {
                List(suggestions, id: \.self) { suggestion in
                    Text(suggestion)
                        .onTapGesture {
                            text = suggestion
                            onCommit()
                        }
                }
                .frame(maxHeight: 80)
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
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
}

// MARK: - Missing Views Replacement

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
                HStack {
                    Text("Status: ")
                        .bold()
                    Text(job.status.rawValue)
                        .foregroundColor(job.status.displayColor)
                }
                if let link = job.linkToJob, let url = URL(string: link) {
                    Link("View Job Posting", destination: url)
                        .accessibilityLabel("View job posting link")
                } else {
                    Text("No job link available")
                        .foregroundColor(.secondary)
                }
                if !job.location.isEmpty {
                    Text("Location: \(job.location)")
                        .font(.headline)
                } else {
                    Text("No location specified")
                        .foregroundColor(.secondary)
                }
                Text("Applied on: \(job.dateOfApplication.formatted(date: .abbreviated, time: .omitted))")
                if let salary = job.salary {
                    let salaryAsInt = Int(salary)
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
                                    .buttonStyle(BorderedButtonStyle())
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
                if !job.desiredSkills.isEmpty {
                    Divider()
                    Text("Desired Skills")
                        .font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(job.desiredSkills, id: \.self) { skillName in
                                // If a matching DesiredSkill exists in jobStore.availableSkills, show a SkillChipView.
                                if let skillObj = jobStore.availableSkills.first(where: { $0.name == skillName }) {
                                    SkillTag(skillName: skillObj.name, removeAction: {})
                                } else {
                                    Text(skillName)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                if !job.jobDescription.isEmpty {
                    Divider()
                    HStack {
                        Text("Job Description")
                            .font(.headline)
                        Button("Copy") {
                            let pb = NSPasteboard.general
                            pb.declareTypes([.string], owner: nil)
                            pb.setString(job.jobDescription, forType: .string)
                        }
                        .help("Copy job description to clipboard")
                    }
                    let attributedString = markdownParser.parse(job.jobDescription)
                    Text(AttributedString(attributedString))
                        .font(.body)
                        .padding(4)
                }
                if !job.coverLetter.isEmpty {
                    Divider()
                    Text("Cover Letter").font(.headline)
                    Text(job.coverLetter)
                        .font(.body)
                        .padding(4)
                }
                Divider()
                Text("Notes").font(.headline)
                if let notes = job.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.body)
                        .padding(4)
                } else {
                    Text("No notes provided.").foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
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

    func updateWindowTitle() {
        guard let w = windowRef else { return }
        w.title = "\(job.companyName) \(job.jobTitle)"
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

    func cleanFileName(_ filename: String) -> String {
        var cleanedName = filename
        let toRemove = ["Roger Lin", "Position", "2024", "Cover Letter"]
        for s in toRemove {
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
}

// --------------------------------------------------
// MARK: - NewLocationView
// -----------------------------------------------------
struct NewLocationView: View {
    @Binding var locations: [String]
    @Binding var selectedLocation: String
    @Binding var isPresented: Bool

    @State private var newLocationName: String = ""
    @State private var latitude: String = ""
    @State private var longitude: String = ""

    var body: some View {
        ZStack {
            PastelGradientBackground()
            VStack {
                Text("Add a New Location")
                    .font(.headline)
                TextField("Location Name", text: $newLocationName)
                    .background(Material.thin.opacity(0.75))
                    .cornerRadius(5)
                    .overlay(RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(Color.tertiary, lineWidth: 0.5))
                    .controlSize(.large)
                TextField("Latitude", text: $latitude)
                    .background(Material.thin.opacity(0.75))
                    .cornerRadius(5)
                    .overlay(RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(Color.tertiary, lineWidth: 0.5))
                    .controlSize(.large)
                TextField("Longitude", text: $longitude)
                    .background(Material.thin.opacity(0.75))
                    .cornerRadius(5)
                    .overlay(RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(Color.tertiary, lineWidth: 0.5))
                    .controlSize(.large)
                HStack {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .buttonStyle(BorderedButtonStyle())
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
                    .buttonStyle(BorderedProminentButtonStyle())
                    .tint(.blue)
                }
            }
            .padding()
            .frame(width: 300, height: 250)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
        }
        .frame(width: 300, height: 250)
    }
}

// --------------------------------------------------
// MARK: - EditJobView
// --------------------------------------------------
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
        ZStack {
            GradientBackground()
                .ignoresSafeArea()
            VStack {
                Text("Edit Job")
                    .font(.title2)
                    .padding()
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Job Details")
                        TextField("Company Name", text: $viewModel.companyName)
                            .background(Material.thin.opacity(0.75))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(Color.tertiary, lineWidth: 0.5))
                            .onChange(of: viewModel.companyName) { _, _ in
                                viewModel.validateInputs()
                            }
                        TextField("Job Title", text: $viewModel.jobTitle)
                            .background(Material.thin.opacity(0.75))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(Color.tertiary, lineWidth: 0.5))
                            .onChange(of: viewModel.jobTitle) { _, _ in
                                viewModel.validateInputs()
                            }
                        sectionHeader("Application Details")
                        TextField("Link to Job", text: $viewModel.linkToJob)
                            .background(Material.thin.opacity(0.75))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(Color.tertiary, lineWidth: 0.5))
                        TextField(
                            "Salary",
                            value: $viewModel.salaryDouble,
                            format: .currency(code: Locale.current.currency?.identifier ?? "USD")
                        )
                        .background(Material.thin.opacity(0.75))
                        .cornerRadius(5)
                        .overlay(RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(Color.tertiary, lineWidth: 0.5))
                        Picker("Status", selection: $viewModel.status) {
                            ForEach(JobStatus.allCases, id: \.self) { status in
                                Text(status.rawValue).tag(status)
                            }
                        }
                        DatePicker("Application Date", selection: $viewModel.dateOfApplication, displayedComponents: .date)
                        Picker("Location", selection: $viewModel.location) {
                            ForEach(locations, id: \.self) { loc in
                                Text(loc).tag(loc)
                            }
                            Text("Add New Location").tag("Add New Location")
                        }
                        .onChange(of: viewModel.location) { _, newValue in
                            if newValue == "Add New Location" {
                                viewModel.location = ""
                                showAddLocationSheet = true
                            }
                        }
                        sectionHeader("Documents")
                        if !importedDocuments.isEmpty {
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(importedDocuments, id: \.id) { doc in
                                        documentView(for: doc)
                                    }
                                }
                            }
                        }
                        Button("Upload Documents") {
                            isImporting = true
                        }
                        sectionHeader("Job Description")
                        TextEditor(text: $viewModel.jobDescription)
                            .frame(minHeight: 100)
                            .background(Material.thin.opacity(0.75))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(Color.tertiary, lineWidth: 0.5))
                        sectionHeader("Cover Letter")
                        TextEditor(text: $viewModel.coverLetter)
                            .frame(minHeight: 100)
                            .background(Material.thin.opacity(0.75))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(Color.tertiary, lineWidth: 0.5))
                        sectionHeader("Notes")
                        TextEditor(text: $viewModel.notes)
                            .frame(minHeight: 100)
                            .background(Material.thin.opacity(0.75))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(Color.tertiary, lineWidth: 0.5))
                    }
                    .padding()
                }
                HStack {
                    Button(role: .cancel) {
                        isPresented = false
                    } label: {
                        Text("Cancel")
                    }
                    .buttonStyle(BorderedButtonStyle())
                    .tint(.red)
                    Spacer()
                    Button("Save") {
                        viewModel.validateInputs()
                        guard viewModel.isInputValid else { return }
                        let updatedJob = JobApplication(
                            id: jobStore.selectedJob?.id ?? UUID(),
                            companyName: viewModel.companyName,
                            jobTitle: viewModel.jobTitle,
                            status: viewModel.status,
                            dateOfApplication: viewModel.dateOfApplication,
                            location: viewModel.location,
                            linkToJob: viewModel.linkToJob.isEmpty ? nil : viewModel.linkToJob,
                            salary: viewModel.salaryDouble,
                            jobDescription: viewModel.jobDescription,
                            coverLetter: viewModel.coverLetter,
                            notes: viewModel.notes.isEmpty ? nil : viewModel.notes,
                            documents: importedDocuments,
                            isFavorite: jobStore.selectedJob?.isFavorite ?? false,
                            jobType: viewModel.jobType,
                            desiredSkills: viewModel.selectedDesiredSkills
                        )
                        jobStore.editJob(with: updatedJob)
                        isPresented = false
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                    .tint(.blue)
                    .disabled(!viewModel.isInputValid)
                }
                .padding()
            }
            .frame(minWidth: 500, minHeight: 600)
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf, .plainText, .rtf, .image],
            allowsMultipleSelection: true
        ) { handleImportedFiles(result: $0) }
        .sheet(isPresented: $showAddLocationSheet) {
            NewLocationView(
                locations: $locations,
                selectedLocation: $viewModel.location,
                isPresented: $showAddLocationSheet
            )
        }
        .quickLookPreview($quickLookURL)
        .onAppear {
            loadLocations()
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .textCase(.uppercase)
            .padding(.bottom, 5)
    }

    private func documentView(for doc: JobDocument) -> some View {
        HStack {
            Image(systemName: "doc.text")
                .foregroundColor(.primary)
            Text(cleanFileName(doc.fileName))
                .gradientForeground(colors: [.blue, .purple])
        }
        .buttonStyle(BorderedButtonStyle())
        .contextMenu {
            Button("Reveal in Finder") {
                if let fileURL = doc.fileURL {
                    NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                }
            }
            Button("Delete Document") {
                if let idx = importedDocuments.firstIndex(where: { $0.id == doc.id }) {
                    importedDocuments.remove(at: idx)
                }
            }
        }
    }

    private func loadLocations() {
        locations = Array(Set(jobStore.jobApplications.map { $0.location })).sorted()
    }
    
    private func handleImportedFiles(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                if let data = try? Data(contentsOf: url) {
                    let doc = JobDocument(
                        fileName: url.lastPathComponent,
                        fileData: data,
                        fileURL: url,
                        creation: Date(),
                        lastModified: Date()
                    )
                    if !importedDocuments.contains(doc) {
                        importedDocuments.append(doc)
                    }
                }
            }
        case .failure(let error):
            print("Failed to import files: \(error)")
        }
    }
}

// --------------------------------------------------
// MARK: - GradientBackground (for EditJobView)
struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                .purple.opacity(0.4),
                .blue.opacity(0.4)
            ]),
            startPoint: .top,
            endPoint: .bottomTrailing
        )
    }
}

// --------------------------------------------------
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

struct DocumentMetadataEditView: View {
    @EnvironmentObject var docStore: DocumentStore
    @Environment(\.presentationMode) var presentationMode

    @State var doc: JobDocument

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edit Document Metadata")
                .font(.headline)
            TextField("File Name", text: $doc.fileName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
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

// --------------------------------------------------
// MARK: - DocumentsSidebarView
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
                    .buttonStyle(BorderedButtonStyle())
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
                    .buttonStyle(BorderedProminentButtonStyle())
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
                .buttonStyle(BorderedButtonStyle())
                .tint(.red)
                Spacer()
                Button("Save") {
                    docStore.createNewCategory(name: docStore.newCategoryName)
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(BorderedProminentButtonStyle())
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
                    .buttonStyle(BorderedProminentButtonStyle())
                    .tint(.blue)
                    Spacer()
                }
            } else if docStore.selectedDocument == nil {
                Text("Select a document to view.")
                    .font(.title3)
                    .foregroundColor(.secondary)
            } else if let doc = docStore.selectedDocument {
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

// --------------------------------------------------
// MARK: - EnhancedStatsView
// --------------------------------------------------
struct EnhancedStatsView: View {
    @EnvironmentObject var jobStore: JobStore

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 50)
    )
    @State private var cityPins: [CityPin] = []

    @State private var yearContributionData: [Contribution] = []
    @State private var appsContributionData: [Contribution] = []

    @State private var yearChartSelectedDate: Date? = nil
    @State private var appsChartSelectedDate: Date? = nil

    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case sixmonth = "Six Months"
        case year = "Year"
        var id: String { rawValue }
    }
    @AppStorage("StatsViewTimeRange") private var selectedTimeRangeRaw: String = TimeRange.month.rawValue
    @State private var selectedTimeRange: TimeRange = .month

    @State private var availableYears: [Int] = []
    @State private var selectedYear: Int = -1  // -1 means “All Years”

    @State private var barLineData: [DailyApps] = []
    @State private var barLineSelectedDate: Date? = nil

    @State private var monthlyCityData: [MonthlyCityData] = []

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
                    HorizontalStackedBarChartView(monthlyCityData: monthlyCityDataFilteredForSelectedYear())
                } else {
                    Text("Horizontally Stacked Bar Chart requires macOS 13+")
                        .foregroundColor(.secondary)
                }
                singleColumnVerticallyStackedBarChartSection
                top20CompaniesBarSection
                citiesByFrequencySection
                companiesByFrequencySection
                if #available(macOS 14.0, iOS 17.0, *) {
                    PieChartsSectionView(
                        monthlyData: monthlyShareData(),
                        cityData: cityShareData(),
                        yearData: yearlyShareData(),
                        selectedYearText: selectedYearText()
                    )
                } else {
                    Text("Interactive Pie Charts require macOS 14.0+.")
                        .foregroundColor(.secondary)
                }
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
        .navigationTitle("Stats & Analytics")
    }

    // MARK: - Subviews and Helper Methods for EnhancedStatsView
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

    private var appliedCompaniesAndRolesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(jobStore.jobApplications.sorted(by: { $0.dateOfApplication > $1.dateOfApplication })) { job in
                    Button {
                        jobStore.selectedJob = job
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
                            jobStore.selectedJob?.id == job.id
                            ? Color.blue.opacity(0.2)
                            : Color.white.opacity(0.1)
                        )
                        .cornerRadius(5)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }

    private var statsRowSection: some View {
        let total = jobStore.jobApplications.count
        let applied = jobStore.jobApplications.filter { $0.status == .applied }.count
        let interested = jobStore.jobApplications.filter { $0.status == .interested }.count
        let interviewed = jobStore.jobApplications.filter { $0.status == .interview }.count
        let distinctCities = Set(jobStore.jobApplications.map { $0.location }).count
        let topCompany = topCompanyName()
        let (topCityName, topCityCount) = topCity()
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
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
    }

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
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.horizontal)
    }

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
                    .annotation {
                        if item.count > 0 {
                            Text("\(item.count)")
                                .font(.system(size: 8).bold())
                                .foregroundColor(.black.opacity(0.7))
                                .offset(y: -8)
                        }
                    }
                }
                .chartXSelection(value: $yearChartSelectedDate)
                .chartForegroundStyleScale(range: Gradient(colors: enhancedChartColors))
                .chartYAxis {
                    AxisMarks(values: [1, 3, 5, 7]) { val in
                        if let i = val.as(Int.self), let label = shortWeekdaySymbol(i) {
                            AxisValueLabel(label)
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) {
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .foregroundStyle(Color.secondary)
                    }
                }
                .chartPlotStyle { plotArea in
                    plotArea.background(Color.gray.opacity(0.05))
                }
                .frame(height: 200)
                .overlay {
                    if let sel = yearChartSelectedDate {
                        GeometryReader { geo in
                            let dayStr = sel.formatted(date: .abbreviated, time: .omitted)
                            let c = yearContributionData.first(where: { $0.date == sel })?.count ?? 0
                            Text("\(c) apps on \(dayStr)")
                                .font(.headline)
                                .padding(8)
                                .background(Color.green.opacity(0.3))
                                .cornerRadius(6)
                                .position(x: geo.size.width * 0.5, y: 15)
                        }
                    }
                }
                Chart(appsContributionData) { item in
                    RectangleMark(
                        x: .value("WeekOfYear", item.date, unit: .weekOfYear),
                        y: .value("DayOfWeek", weekday(for: item.date))
                    )
                    .foregroundStyle(by: .value("Count", item.count))
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .annotation {
                        if item.count > 0 {
                            Text("\(item.count)")
                                .font(.system(size: 8).bold())
                                .foregroundColor(.black.opacity(0.7))
                                .offset(y: -8)
                        }
                    }
                }
                .chartXSelection(value: $appsChartSelectedDate)
                .chartForegroundStyleScale(range: Gradient(colors: enhancedChartColors))
                .chartYAxis {
                    AxisMarks(values: [1, 3, 5, 7]) { val in
                        if let i = val.as(Int.self), let label = shortWeekdaySymbol(i) {
                            AxisValueLabel(label)
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) {
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .foregroundStyle(Color.secondary)
                    }
                }
                .chartPlotStyle { plotArea in
                    plotArea.background(Color.gray.opacity(0.05))
                }
                .padding(.vertical)
                .frame(height: 200)
                .overlay {
                    if let sel = appsChartSelectedDate {
                        GeometryReader { geo in
                            let dayStr = sel.formatted(date: .abbreviated, time: .omitted)
                            let c = appsContributionData.first(where: { $0.date == sel })?.count ?? 0
                            Text("\(c) apps on \(dayStr)")
                                .font(.headline)
                                .padding(8)
                                .background(Color.blue.opacity(0.3))
                                .cornerRadius(6)
                                .position(x: geo.size.width * 0.5, y: 15)
                        }
                    }
                }
            } else {
                Text("Charts require macOS 13.0+.")
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxHeight: .infinity)
        .frame(maxWidth: .infinity)
    }

    private var timeRangePickerSection: some View {
        HStack {
            Text("Select Time Range:")
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }

    @ViewBuilder
    private var barLineChartsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Applications Frequency (Last 12 Months / Range)")
                .font(.headline)
            if #available(macOS 13.0, *) {
                Chart(barLineData) { dayItem in
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
                    AxisMarks() {
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
            } else {
                Text("Charts require macOS 13.0+.")
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var singleColumnVerticallyStackedBarChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Applications by City - Single Column Vertically Stacked Bar Chart")
                .font(.headline)
            if #available(macOS 13.0, *) {
                Chart(monthlyCityDataFilteredForSelectedYear()) { item in
                    BarMark(
                        x: .value("Month", item.monthKey),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(by: .value("City", item.city))
                }
                .ifShouldScrollHorizontally(selectedYear: selectedYear)
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
                    AxisMarks(values: .automatic)
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

    // MARK: - Setup & Compute Methods for Stats
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
        guard let overallMin = allDates.min(), let overallMax = allDates.max() else {
            yearContributionData = []
            return
        }
        let (startOfRange, endOfRange): (Date, Date)
        if selectedYear == -1 {
            startOfRange = cal.startOfDay(for: overallMin)
            endOfRange   = overallMax
        } else {
            guard let s = cal.date(from: DateComponents(year: selectedYear, month: 1, day: 1)),
                  let e = cal.date(from: DateComponents(year: selectedYear, month: 12, day: 31))
            else {
                yearContributionData = []
                return
            }
            startOfRange = s
            endOfRange   = e
        }
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
            if let next = cal.date(byAdding: .day, value: 1, to: day) {
                day = next
            } else {
                break
            }
        }
        yearContributionData = allDays.map { d in
            Contribution(date: d, count: contributionMap[d] ?? 0)
        }
    }

    private func computeAppsContribution() {
        guard !jobStore.jobApplications.isEmpty else {
            appsContributionData = []
            return
        }
        let cal = Calendar.current
        let allDates = jobStore.jobApplications.map { $0.dateOfApplication }
        guard let overallMin = allDates.min(), let overallMax = allDates.max() else {
            appsContributionData = []
            return
        }
        let (startOfRange, endOfRange): (Date, Date)
        if selectedYear == -1 {
            startOfRange = cal.startOfDay(for: overallMin)
            endOfRange   = overallMax
        } else {
            guard let s = cal.date(from: DateComponents(year: selectedYear, month: 1, day: 1)),
                  let e = cal.date(from: DateComponents(year: selectedYear, month: 12, day: 31))
            else {
                appsContributionData = []
                return
            }
            startOfRange = s
            endOfRange   = e
        }
        var appsMap: [Date: Int] = [:]
        for job in jobStore.jobApplications {
            if job.dateOfApplication >= startOfRange && job.dateOfApplication <= endOfRange {
                let day = cal.startOfDay(for: job.dateOfApplication)
                appsMap[day, default: 0] += 1
            }
        }
        var allDays: [Date] = []
        var day = cal.startOfDay(for: startOfRange)
        while day <= endOfRange {
            allDays.append(day)
            if let next = cal.date(byAdding: .day, value: 1, to: day) {
                day = next
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
        var startDate: Date?
        let now = Date()
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
        monthlyCityData = grouped.map { $0.value }
    }

    func monthlyCityDataFilteredForSelectedYear() -> [MonthlyCityData] {
        monthlyCityData
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

    func cityFreqList() -> [(city: String, count: Int)] {
        var map: [String: Int] = [:]
        for job in jobStore.jobApplications {
            map[job.location, default: 0] += 1
        }
        return map.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }

    func companyFreqList() -> [(name: String, count: Int)] {
        var map: [String: Int] = [:]
        for job in jobStore.jobApplications {
            map[job.companyName, default: 0] += 1
        }
        return map.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }

    func topCompanyName() -> String {
        let sorted = companyFreqList()
        guard let first = sorted.first else { return "N/A" }
        return first.name
    }

    func topCity() -> (String, Int) {
        let sorted = cityFreqList()
        guard let first = sorted.first else { return ("N/A", 0) }
        return first
    }

    func shortWeekdaySymbol(_ dayInt: Int) -> String? {
        switch dayInt {
        case 1: return "Sun"
        case 2: return "Mon"
        case 3: return "Tue"
        case 4: return "Wed"
        case 5: return "Thu"
        case 6: return "Fri"
        case 7: return "Sat"
        default: return nil
        }
    }

    func weekday(for date: Date) -> Int {
        let w = Calendar.current.component(.weekday, from: date)
        return w
    }

    var enhancedChartColors: [Color] {
        [.white, Color(red: 0.8, green: 0.9, blue: 0.8), Color(red: 0.6, green: 0.8, blue: 0.6), Color(red: 0.4, green: 0.7, blue: 0.4), Color(red: 0.2, green: 0.6, blue: 0.2)]
    }

    func monthlyShareData() -> [(monthKey: String, count: Int)] {
        let cal = Calendar.current
        var map: [String: Int] = [:]
        for job in jobStore.jobApplications {
            let jobYear = cal.component(.year, from: job.dateOfApplication)
            if selectedYear != -1, jobYear != selectedYear { continue }
            let m = cal.component(.month, from: job.dateOfApplication)
            let key = cal.shortMonthSymbols[m-1]
            map[key, default: 0] += 1
        }
        return map.map { (monthKey: $0.key, count: $0.value) }
            .sorted { $0.monthKey < $1.monthKey }
    }

    func cityShareData() -> [(city: String, count: Int)] {
        let cal = Calendar.current
        var map: [String: Int] = [:]
        for job in jobStore.jobApplications {
            let jobYear = cal.component(.year, from: job.dateOfApplication)
            if selectedYear != -1, jobYear != selectedYear { continue }
            map[job.location, default: 0] += 1
        }
        return map.map { (city: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    func yearlyShareData() -> [(year: String, count: Int)] {
        var map: [String: Int] = [:]
        let cal = Calendar.current
        for job in jobStore.jobApplications {
            let y = cal.component(.year, from: job.dateOfApplication)
            map["\(y)", default: 0] += 1
        }
        return map.map { (year: $0.key, count: $0.value) }
            .sorted { ($0.year) < ($1.year) }
    }

    func selectedYearText() -> String {
        if selectedYear == -1 {
            return "All Years"
        } else {
            return "\(selectedYear)"
        }
    }
}

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
            .overlay(alignment: .top) {
                if let selection = horizontalPlotSelection,
                   let selectedData = monthlyCityData.first(where: { $0.monthKey == selection }) {
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

@available(macOS 14.0, iOS 17.0, *)
struct PieChartsSectionView: View {
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

@available(macOS 14.0, iOS 17.0, *)
struct PieChartView: View {
    let data: [(key: String, count: Int)]
    @Binding var selectedAngle: Double?
    let centerLabel: String
    var showLegend: Bool = false
    var legendPosition: AnnotationPosition = .bottom
    var body: some View {
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
                    let label = selItem?.key ?? centerLabel
                    let count = selItem?.count ?? totalCount
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

    private func selectedItemLabel(_ angle: Double?) -> (key: String, count: Int)? {
        guard let angle else { return nil }
        let ranges = buildAngleRanges(for: data)
        return ranges.first { $0.range.contains(angle) }
            .map { (key: $0.key, count: $0.count) }
    }

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

@available(macOS 14.0, iOS 17.0, *)
fileprivate struct AngleRangeItem {
    let key: String
    let range: Range<Double>
    let count: Int
}

@available(macOS 13.0, *)
extension View {
    @ViewBuilder
    func ifShouldScrollHorizontally(selectedYear: Int) -> some View {
        if selectedYear == -1 {
            self
                .frame(minWidth: 1000)
                .scrollDisabled(false)
        } else {
            self
        }
    }
}

// MARK: - Supporting Data Structures for Stats
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

// MARK: - Main App Views

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
                .pickerStyle(SegmentedPickerStyle())
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

enum ViewSection: String, CaseIterable {
    case jobDetails = "Job Details"
    case stats = "Stats"
    case documents = "Documents"
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
                            ? Color(NSColor.selectedTextBackgroundColor).opacity(0.6)
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
        }
        .onTapGesture {
            isSelected.toggle()
        }
    }
}

// MARK: - AppDelegate and Main App

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // App launch code if needed
    }
    func application(_ application: NSApplication, open urls: [URL]) {
        print("AppDelegate: application(_:open:) called with URL: \(urls)")
        guard let url = urls.first else { return }
        NotificationCenter.default.post(name: .didOpenCustomURL, object: url)
    }
}

extension Notification.Name {
    static let didOpenCustomURL = Notification.Name("didOpenCustomURL")
}

@main
struct AppleJobApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var jobStore = JobStore()
    @StateObject var docStore = DocumentStore()
    @StateObject var importExportHelper = ImportExportHelper()

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
        if host == "x-callback-url" {
            let path = components.path
            if path.isEmpty {
                print("handleIncomingURL: x-callback-url path missing, returning")
                return
            }
            let action = path.dropFirst()
            print("handleIncomingURL: x-callback-url action: \(action)")
            switch action {
            case "add-job":
                handleAddJobAction(queryItems: components.queryItems)
            case "open-stats":
                handleOpenStatsAction(queryItems: components.queryItems)
            default:
                print("handleIncomingURL: Unknown x-callback-url action: \(action)")
            }
        } else if host == "addjob" {
            handleLegacyAddJob(components: components)
        } else {
            print("handleIncomingURL: Unknown host: \(host)")
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
                let title = jobData["jobTitle"] ?? ""
                let urlString = jobData["URL"] ?? ""
                let desc = jobData["jobDescription"] ?? ""
                // Store the incoming data and trigger AddJobView
                jobStore.incomingJobData = [
                    "jobTitle": title,
                    "url": urlString,
                    "jobDescription": desc
                ]
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

// Supporting types for EnhancedStatsView
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

@available(macOS 13.0, *)
extension View {
    @ViewBuilder
    func ifShouldScrollHorizontally(selectedYear: Int) -> some View {
        if selectedYear == -1 {
            self
                .frame(minWidth: 1000)
                .scrollDisabled(false)
        } else {
            self
        }
    }
}

enum ViewSection: String, CaseIterable {
    case jobDetails = "Job Details"
    case stats = "Stats"
    case documents = "Documents"
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
                            ? Color(NSColor.selectedTextBackgroundColor).opacity(0.6)
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
        }
        .onTapGesture {
            isSelected.toggle()
        }
    }
}

// --------------------------------------------------
// MARK: - ViewSection Enum for ContentView Sidebar
enum ViewSection: String, CaseIterable {
    case jobDetails = "Job Details"
    case stats = "Stats"
    case documents = "Documents"
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
