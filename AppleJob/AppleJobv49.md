//
//  Model.swift
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
    let id: UUID
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

//
//  ViewModel.swift
//  AppleJob
//
//  Created by Your Name on YYYY/MM/DD
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - JobStore

class JobStore: ObservableObject {
    @Published var jobApplications: [JobApplication] = []
    @Published var selectedJob: JobApplication? = nil
    @Published var isAddingNewJob: Bool = false
    @Published var isEditingJob: Bool = false
    @Published var sorting: Sort = .recentlyApplied
    @Published var incomingJobData: [String: Any]? = nil
    @Published var availableSkills: [DesiredSkill] = []
    @Published var selectedQualityFilter: String? = nil

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
            if selectedJob?.id == id {
                selectedJob = nil
            }
            saveJobs()
        }
    }

    func duplicateJob(_ job: JobApplication) {
        var newJob = job
        newJob.id = UUID()
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
        saveSkills()
    }

    func loadJobs() {
        guard let savedData = UserDefaults.standard.data(forKey: "jobs") else { return }
        do {
            jobApplications = try JSONDecoder().decode([JobApplication].self, from: savedData)
            sortJobs(by: sorting)
        } catch {
            print("Failed to load jobs: \(error.localizedDescription)")
        }
    }

    func importBackup(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let importedJobs = try JSONDecoder().decode([JobApplication].self, from: data)
            if !importedJobs.isEmpty {
                DispatchQueue.main.async {
                    self.jobApplications = importedJobs
                    self.sortJobs(by: self.sorting)
                    self.saveJobs()
                    self.parseJobDescriptionsForAllSkills()
                }
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
        if !availableSkills.contains(where: { $0.name == skill.name }) {
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
            var found = false
            let searchTerms = [skill.name.lowercased()] + skill.aliases.map { $0.lowercased() }
            for term in searchTerms {
                if description.contains(term) {
                    found = true
                    break
                }
            }
            if found {
                if !currentJob.desiredSkills.contains(skill.name) {
                    currentJob.desiredSkills.append(skill.name)
                    jobApplications[index] = currentJob
                }
            }
        }
        saveJobs()
    }
}

// MARK: - DocumentStore

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

// MARK: - ImportExportHelper

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

// MARK: - JobViewModel

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
    @Published var isAddingAlias = false
    @Published var skillToAddAlias: String? = nil

    @Published var isInputValid: Bool = false

    init(job: JobApplication, availableSkills: [DesiredSkill]) {
        companyName = job.companyName
        jobTitle = job.jobTitle
        status = job.status
        dateOfApplication = job.dateOfApplication
        applicationDeadline = job.applicationDeadline
        location = job.location
        salaryDouble = job.salary
        salaryString = formatSalaryAsInteger(job.salary)
        linkToJob = job.linkToJob ?? ""
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
                jobStore.addSkill(newSkill)
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
            documents: [], // Documents are handled separately in the views
            isFavorite: false,
            jobType: jobType,
            desiredSkills: selectedDesiredSkills
        )
    }

    func addJob(to store: JobStore, documents: [JobDocument]) {
        guard isInputValid else { return }
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
        reset()
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

//
//  Views.swift
//  AppleJob
//
//  Created by Your Name on YYYY/MM/DD
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers
import MarkdownKit

// MARK: - Custom View Modifiers

extension View {
    func gradientBackground(colors: [Color]) -> some View {
        self.background(
            LinearGradient(
                gradient: Gradient(colors: colors),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
    
    func translucentTextFieldStyle() -> some View {
        self
            .padding(8)
            .background(
                ZStack {
                    PastelGradientBackground()
                    Color.clear.background(Material.ultraThin)
                }
                .opacity(0.5)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            )
            .overlay(RoundedRectangle(cornerRadius: 5)
                .strokeBorder(Color.tertiary, lineWidth: 0.5))
    }
    
    func translucentTextEditorStyle() -> some View {
        self
            .padding(6)
            .background(
                ZStack {
                    PastelGradientBackground()
                    Color.clear.background(Material.ultraThin)
                }
                .opacity(0.5)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            )
            .overlay(RoundedRectangle(cornerRadius: 5)
                .strokeBorder(Color.tertiary, lineWidth: 0.5))
    }
}

// MARK: - PastelGradientBackground

struct PastelGradientBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.94, green: 0.85, blue: 1.0).opacity(0.7),
                Color(red: 0.88, green: 0.95, blue: 0.90).opacity(0.7),
                Color(red: 1.0,  green: 0.94, blue: 0.9).opacity(0.7)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - String Parsing Extensions (for Views)

extension String {
    func replacingMultipleBlankLines() -> String {
        self.replacingOccurrences(of: "(\n\\s*){2,}", with: "\n\n", options: .regularExpression)
    }
    
    func replacingInvalidBullets() -> String {
        self.replacingOccurrences(of: "•", with: "- ")
    }
    
    func ensuringListItemsOnSeparateLines() -> String {
        self.replacingOccurrences(of: "(?<!\\n)- ", with: "\n- ", options: .regularExpression)
    }
    
    func formattingSectionHeaders() -> String {
        let headers = [
            "Responsibilities include:",
            "About Us,",
            "Responsibilities,",
            "Equal Opportunity Employment Policy,",
            "Education,",
            "Job Functions,",
            "Description,",
            "Personal Attributes,",
            "Qualifications,",
            "Desired Qualifications,",
            "Our Company,",
            "Compensation"
        ]
        var lines = self.components(separatedBy: "\n")
        for i in 0..<lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
            for header in headers {
                if trimmed.caseInsensitiveCompare(header) == .orderedSame ||
                    trimmed.lowercased().contains(header.lowercased()) {
                    if !lines[i].hasPrefix("## ") {
                        if i > 0 && !lines[i-1].trimmingCharacters(in: .whitespaces).isEmpty {
                            lines.insert("", at: i)
                        }
                        lines[i] = "## " + lines[i]
                    }
                }
            }
        }
        return lines.joined(separator: "\n")
    }
    
    func extractJobTitle() -> String? {
        for line in self.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                return trimmed.replacingOccurrences(of: "## ", with: "")
            }
        }
        return nil
    }
    
    func extractURL() -> String? {
        let lines = self.components(separatedBy: "\n").prefix(3)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
                return trimmed
            }
        }
        return nil
    }
    
    func extractLocation(from cityNames: [String]) -> String? {
        for city in cityNames {
            if self.range(of: city, options: .caseInsensitive) != nil {
                return city
            }
        }
        return nil
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
            .textFieldStyle(.roundedBorder)
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
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
}

// MARK: - AddJobView

struct AddJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var isPresented: Bool

    @StateObject private var viewModel = JobViewModel()
    @State private var importedDocuments: [JobDocument] = []
    @State private var locations: [String] = CityCoordinateDictionary.keys.sorted()
    @State private var showAddLocationSheet = false
    @State private var isImporting = false
    @State private var quickLookURL: URL? = nil

    let markdownParser = MarkdownParser()

    var body: some View {
        ZStack {
            PastelGradientBackground()
            VStack {
                Text("Add New Job")
                    .font(.title2)
                    .padding()
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("JOB DETAILS")
                        
                        // COMPANY NAME
                        TextField("Company Name", text: $viewModel.companyName)
                            .translucentTextFieldStyle()
                            .controlSize(.large)
                            .onChange(of: viewModel.companyName) { _, _ in viewModel.validateInputs() }
                        
                        // JOB TITLE
                        TextField("Job Title", text: $viewModel.jobTitle)
                            .translucentTextFieldStyle()
                            .controlSize(.large)
                            .onChange(of: viewModel.jobTitle) { _, _ in viewModel.validateInputs() }
                        
                        sectionHeader("APPLICATION DETAILS")
                        
                        // LINK TO JOB
                        TextField("Link to Job", text: $viewModel.linkToJob)
                            .translucentTextFieldStyle()
                            .controlSize(.large)
                        
                        // SALARY
                        TextField("Salary", value: $viewModel.salaryDouble, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .translucentTextFieldStyle()
                            .controlSize(.large)
                        
                        // LOCATION PICKER
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
                        
                        // APPLICATION DATE
                        DatePicker("Application Date", selection: $viewModel.dateOfApplication, displayedComponents: .date)
                        
                        // STATUS PICKER
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
                        
                        sectionHeader("JOB DESCRIPTION")
                        HStack {
                            Text("Job Description").font(.headline)
                            Button("Paste") {
                                if let clipboardText = NSPasteboard.general.string(forType: .string) {
                                    viewModel.jobDescription = clipboardText
                                }
                            }
                            .help("Paste from Clipboard")
                        }
                        TextEditor(text: $viewModel.jobDescription)
                            .frame(minHeight: 200)
                            .translucentTextEditorStyle()
                            .scrollContentBackground(.hidden)
                            .onChange(of: viewModel.jobDescription) { newValue in
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
                                if viewModel.companyName.isEmpty {
                                    for existingApp in jobStore.jobApplications {
                                        if newValue.localizedCaseInsensitiveContains(existingApp.companyName) {
                                            viewModel.companyName = existingApp.companyName
                                            break
                                        }
                                    }
                                }
                            }
                        Button("Parse Description") {
                            parseJobDescription()
                        }
                        
                        sectionHeader("COVER LETTER")
                        TextEditor(text: $viewModel.coverLetter)
                            .frame(minHeight: 200)
                            .translucentTextEditorStyle()
                            .scrollContentBackground(.hidden)
                        
                        sectionHeader("NOTES")
                        TextEditor(text: $viewModel.notes)
                            .frame(minHeight: 200)
                            .translucentTextEditorStyle()
                            .scrollContentBackground(.hidden)
                        
                        sectionHeader("DESIRED SKILLS")
                        SkillComboBoxField(
                            text: $viewModel.desiredSkillText,
                            suggestions: $viewModel.availableSkillSuggestions,
                            onCommit: {
                                viewModel.addSelectedSkill(skillName: viewModel.desiredSkillText, jobStore: jobStore)
                            }
                        )
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(viewModel.selectedDesiredSkills, id: \.self) { skill in
                                    SkillTag(skillName: skill, removeAction: {
                                        viewModel.removeSelectedSkill(skillName: skill)
                                    })
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
                }
                
                // SAVE/CANCEL BUTTONS
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
        }
        .frame(minWidth: 500, minHeight: 700)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf, .plainText, .rtf, .image],
            allowsMultipleSelection: true
        ) { result in
            handleImportedFiles(result: result)
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
            print("AddJobView: onAppear called")
            if let incoming = jobStore.incomingJobData {
                print("AddJobView: incomingJobData is not nil: \(incoming)")
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
            viewModel.updateSkillSuggestions(availableSkills: jobStore.availableSkills)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .textCase(.uppercase)
            .padding(.bottom, 5)
    }

    private func storeImportedDocuments() -> [JobDocument] {
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
        return savedDocs
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
        var cleanedName = filename.replacingOccurrences(of: "_", with: " ")
        cleanedName = cleanedName.replacingOccurrences(of: "-", with: " ")
        cleanedName = cleanedName.replacingOccurrences(of: "\\d", with: "", options: .regularExpression)
        let toRemove = ["Roger Lin", "Position", "2024", "Cover Letter"]
        for rem in toRemove {
            cleanedName = cleanedName.replacingOccurrences(of: rem, with: "")
        }
        cleanedName = cleanedName.trimmingCharacters(in: .whitespaces)
        for ext in [".pdf", ".docx", ".pages"] {
            if cleanedName.hasSuffix(ext) {
                cleanedName = String(cleanedName.dropLast(ext.count))
                break
            }
        }
        return cleanedName.trimmingCharacters(in: .whitespaces)
    }

    private func handleImportedFiles(result: Result<[URL], Error>) {
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
            print("Failed to import files: \(error)")
        }
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
    @State private var locations: [String] = CityCoordinateDictionary.keys.sorted()
    @State private var showAddLocationSheet = false
    @State private var quickLookURL: URL? = nil

    let markdownParser = MarkdownParser()

    init(isPresented: Binding<Bool>, job: JobApplication) {
        self._isPresented = isPresented
        _viewModel = StateObject(wrappedValue: JobViewModel(job: job, availableSkills: []))
        _importedDocuments = State(initialValue: job.documents)
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
                            .modifier(TranslucentTextFieldStyle())
                            .controlSize(.large)
                            .onChange(of: viewModel.companyName) { _, _ in viewModel.validateInputs() }
                        TextField("Job Title", text: $viewModel.jobTitle)
                            .modifier(TranslucentTextFieldStyle())
                            .controlSize(.large)
                            .onChange(of: viewModel.jobTitle) { _, _ in viewModel.validateInputs() }
                        sectionHeader("Application Details")
                        TextField("Link to Job", text: $viewModel.linkToJob)
                            .modifier(TranslucentTextFieldStyle())
                            .controlSize(.large)
                        TextField("Salary", value: $viewModel.salaryDouble, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .modifier(TranslucentTextFieldStyle())
                            .controlSize(.large)
                        Picker("Status", selection: $viewModel.status) {
                            ForEach(JobStatus.allCases, id: \.self) { status in
                                Text(status.rawValue).tag(status)
                            }
                        }
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
                        DatePicker("Application Date", selection: $viewModel.dateOfApplication, displayedComponents: .date)
                        DatePicker("Application Deadline", selection: $viewModel.applicationDeadline, displayedComponents: .date)
                        HStack {
                            TextField("Enter desired skills", text: $viewModel.desiredSkillText, onCommit: {
                                viewModel.addSelectedSkill(skillName: viewModel.desiredSkillText, jobStore: jobStore)
                            })
                            .modifier(TranslucentTextFieldStyle())
                        }
                        if !viewModel.selectedDesiredSkills.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(viewModel.selectedDesiredSkills, id: \.self) { skill in
                                        SkillTag(skillName: skill, removeAction: {
                                            viewModel.removeSelectedSkill(skillName: skill)
                                        })
                                    }
                                }
                            }
                        }
                        Button("Select Documents") {
                            selectDocuments()
                        }
                        sectionHeader("Job Description")
                        HStack {
                            Text("Job Description").font(.headline)
                            Button("Paste") {
                                if let clipboardText = NSPasteboard.general.string(forType: .string) {
                                    viewModel.jobDescription = clipboardText
                                }
                            }
                            .help("Paste from Clipboard")
                        }
                        TextEditor(text: $viewModel.jobDescription)
                            .frame(minHeight: 200)
                            .modifier(TranslucentTextEditorStyle())
                            .scrollContentBackground(.hidden)
                            .onChange(of: viewModel.jobDescription) { newValue in
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
                                if viewModel.companyName.isEmpty {
                                    for existingApp in jobStore.jobApplications {
                                        if newValue.localizedCaseInsensitiveContains(existingApp.companyName) {
                                            viewModel.companyName = existingApp.companyName
                                            break
                                        }
                                    }
                                }
                            }
                        Button("Parse Description") {
                            parseJobDescription()
                        }
                        sectionHeader("Cover Letter")
                        TextEditor(text: $viewModel.coverLetter)
                            .frame(minHeight: 200)
                            .modifier(TranslucentTextEditorStyle())
                            .scrollContentBackground(.hidden)
                        sectionHeader("Notes")
                        TextEditor(text: $viewModel.notes)
                            .frame(minHeight: 200)
                            .modifier(TranslucentTextEditorStyle())
                            .scrollContentBackground(.hidden)
                    }
                    .padding()
                }
                HStack {
                    Button("Cancel", role: .cancel) {
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    Spacer()
                    Button("Save") {
                        saveJob()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(!viewModel.isInputValid)
                }
                .padding()
            }
            .frame(minWidth: 500, minHeight: 700)
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

    private func loadLocations() {
        locations = Array(Set(jobStore.jobApplications.map { $0.location })).sorted()
    }

    private func selectDocuments() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.item]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.begin { response in
            if response == .OK {
                viewModel.documents.append(contentsOf: panel.urls.map {
                    let data = (try? Data(contentsOf: $0)) ?? Data()
                    return JobDocument(fileName: $0.lastPathComponent, fileData: data, fileURL: $0)
                })
            }
        }
    }

    private func parseJobDescription() {
        var text = viewModel.jobDescription
        text = text.replacingMultipleBlankLines()
        text = text.replacingInvalidBullets()
        text = text.ensuringListItemsOnSeparateLines()
        text = text.formattingSectionHeaders()
        if viewModel.jobTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let title = text.extractJobTitle() {
            viewModel.jobTitle = title
        }
        if let url = text.extractURL() {
            viewModel.linkToJob = url
        }
        if let loc = text.extractLocation(from: predefinedCityNames) {
            viewModel.location = loc
        }
        viewModel.jobDescription = text
    }

    private func saveJob() {
        viewModel.validateInputs()
        guard viewModel.isInputValid else { return }
        let finalDocs = storeImportedDocuments()
        docStore.mergeDocuments(finalDocs)
        viewModel.addJob(to: jobStore, documents: finalDocs)
        isPresented = false
    }

    private func storeImportedDocuments() -> [JobDocument] {
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
        return savedDocs
    }

    private func handleImportedFiles(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                guard let data = try? Data(contentsOf: url) else { continue }
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
        case .failure(let error):
            print("Failed to import files: \(error)")
        }
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
}

struct JobDetailView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    let job: JobApplication
    @State private var selectedQualityFilter: String? = nil
    let markdownParser = MarkdownParser()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(job.companyName)
                    .font(.largeTitle)
                    .bold()
                Text(job.jobTitle)
                    .font(.title2)
                Button(action: {}) {
                    Text(job.status.rawValue)
                        .padding(5)
                }
                .buttonStyle(BorderlessButtonStyle())
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray, lineWidth: 1)
                )
                HStack {
                    Text("Link to Job:")
                    Text(job.linkToJob ?? "")
                        .foregroundColor(.blue)
                }
                HStack {
                    Text("Location:")
                    Text(job.location)
                }
                HStack {
                    Text("Application Date:")
                    Text(formatDate(job.dateOfApplication))
                }
                HStack {
                    Text("Application Deadline:")
                    Text(formatDate(job.applicationDeadline))
                }
                if !job.desiredSkills.isEmpty {
                    HStack {
                        Text("Desired Skills:")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(job.desiredSkills, id: \.self) { skill in
                                    Button(action: {
                                        if selectedQualityFilter == skill {
                                            selectedQualityFilter = nil
                                            jobStore.selectedQualityFilter = nil
                                        } else {
                                            selectedQualityFilter = skill
                                            jobStore.selectedQualityFilter = skill
                                        }
                                    }) {
                                        Text(skill)
                                            .padding(5)
                                            .background(selectedQualityFilter == skill ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                                            .cornerRadius(5)
                                    }
                                }
                            }
                        }
                    }
                }
                if !job.documents.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Documents:")
                        ForEach(job.documents, id: \.self) { url in
                            Text(url.lastPathComponent)
                        }
                    }
                }
                Divider()
                Section(header: Text("Job Description").bold()) {
                    Text(markdownParser.parse(job.jobDescription))
                        .font(.system(size: 18))
                        .padding()
                }
                Section(header: Text("Cover Letter").bold()) {
                    Text(markdownParser.parse(job.coverLetter))
                        .font(.system(size: 18))
                        .padding()
                }
                Section(header: Text("Notes").bold()) {
                    Text(markdownParser.parse(job.notes ?? ""))
                        .font(.system(size: 18))
                        .padding()
                }
            }
            .padding()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

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
            VStack(spacing: 20) {
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
                .padding()
            }
            .padding()
            .frame(width: 300, height: 250)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
            .background(WindowAccessor { window in
                window?.isMovableByWindowBackground = true
            })
        }
        .frame(width: 300, height: 250)
    }
}

struct WindowAccessor: NSViewRepresentable {
    let configure: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            configure(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        configure(nsView.window)
    }
}

struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.purple.opacity(0.4),
                Color.blue.opacity(0.4)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
    @State private var showDocInfoPopover: Bool = false

    var body: some View {
        NavigationView {
            sidebar
                .frame(minWidth: 250)
                .background(Color.black.opacity(0.03).blur(radius: 3))
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
                $0.companyName.lowercased().contains(lower) ||
                $0.jobTitle.lowercased().contains(lower) ||
                $0.location.lowercased().contains(lower)
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
                        isSelected ? Color(nsColor: .selectedTextBackgroundColor).opacity(0.6) : job.status.displayColor.opacity(0.2)
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

struct DocumentInfoPopover: View {
    var document: JobDocument?
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let doc = document {
                Text("File Name: \(doc.fileName)")
                    .font(.headline)
                if let url = doc.fileURL {
                    Text("File URL: \(url.absoluteString)")
                        .font(.subheadline)
                }
                Text("Created: \(doc.creationDate.formatted(date: .long, time: .shortened))")
                Text("Last Modified: \(doc.lastModifiedDate.formatted(date: .long, time: .shortened))")
                Text("File Size: \(doc.fileSize) bytes")
                Text("Word Count: \(doc.wordCount)")
            } else {
                Text("No document selected.")
            }
            Spacer()
        }
        .padding()
        .frame(minWidth: 300, minHeight: 200)
    }
}

struct AddJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var isPresented: Bool

    @StateObject private var viewModel = JobViewModel()
    @State private var importedDocuments: [JobDocument] = []
    @State private var locations: [String] = CityCoordinateDictionary.keys.sorted()
    @State private var showAddLocationSheet = false
    @State private var isImporting = false
    @State private var quickLookURL: URL? = nil

    let markdownParser = MarkdownParser()

    var body: some View {
        ZStack {
            PastelGradientBackground()
            VStack {
                Text("Add New Job")
                    .font(.title2)
                    .padding()
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("JOB DETAILS")
                        TextField("Company Name", text: $viewModel.companyName)
                            .translucentTextFieldStyle()
                            .controlSize(.large)
                            .onChange(of: viewModel.companyName) { _, _ in viewModel.validateInputs() }
                        TextField("Job Title", text: $viewModel.jobTitle)
                            .translucentTextFieldStyle()
                            .controlSize(.large)
                            .onChange(of: viewModel.jobTitle) { _, _ in viewModel.validateInputs() }
                        sectionHeader("APPLICATION DETAILS")
                        TextField("Link to Job", text: $viewModel.linkToJob)
                            .translucentTextFieldStyle()
                            .controlSize(.large)
                        TextField("Salary", value: $viewModel.salaryDouble, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .translucentTextFieldStyle()
                            .controlSize(.large)
                        Picker("Status", selection: $viewModel.status) {
                            ForEach(JobStatus.allCases, id: \.self) { status in
                                Text(status.rawValue).tag(status)
                            }
                        }
                        Picker("Location", selection: $viewModel.location) {
                            ForEach(locations, id: \.self) { location in
                                Text(location).tag(location)
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
                        DatePicker("Application Deadline", selection: $viewModel.applicationDeadline, displayedComponents: .date)
                        HStack {
                            TextField("Enter desired skills (comma-separated)", text: $viewModel.desiredSkillText, onCommit: {
                                viewModel.addSelectedSkill(skillName: viewModel.desiredSkillText, jobStore: jobStore)
                            })
                            .translucentTextFieldStyle()
                        }
                        if !viewModel.selectedDesiredSkills.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(viewModel.selectedDesiredSkills, id: \.self) { skill in
                                        SkillTag(skillName: skill, removeAction: {
                                            viewModel.removeSelectedSkill(skillName: skill)
                                        })
                                    }
                                }
                            }
                        }
                        Button("Select Documents") {
                            isImporting = true
                        }
                        sectionHeader("JOB DESCRIPTION")
                        HStack {
                            Text("Job Description").font(.headline)
                            Button("Paste") {
                                if let clipboardText = NSPasteboard.general.string(forType: .string) {
                                    viewModel.jobDescription = clipboardText
                                }
                            }
                            .help("Paste from Clipboard")
                        }
                        TextEditor(text: $viewModel.jobDescription)
                            .frame(minHeight: 200)
                            .translucentTextEditorStyle()
                            .scrollContentBackground(.hidden)
                            .onChange(of: viewModel.jobDescription) { newValue in
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
                                if viewModel.companyName.isEmpty {
                                    for existingApp in jobStore.jobApplications {
                                        if newValue.localizedCaseInsensitiveContains(existingApp.companyName) {
                                            viewModel.companyName = existingApp.companyName
                                            break
                                        }
                                    }
                                }
                            }
                        Button("Parse Description") {
                            parseJobDescription()
                        }
                        sectionHeader("COVER LETTER")
                        TextEditor(text: $viewModel.coverLetter)
                            .frame(minHeight: 200)
                            .translucentTextEditorStyle()
                            .scrollContentBackground(.hidden)
                        sectionHeader("NOTES")
                        TextEditor(text: $viewModel.notes)
                            .frame(minHeight: 200)
                            .translucentTextEditorStyle()
                            .scrollContentBackground(.hidden)
                    }
                    .padding()
                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
                }
                HStack {
                    Button("Cancel", role: .cancel) {
                        isPresented = false
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
        }
        .frame(minWidth: 500, minHeight: 700)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf, .plainText, .rtf, .image],
            allowsMultipleSelection: true
        ) { result in
            handleImportedFiles(result: result)
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
            viewModel.updateSkillSuggestions(availableSkills: jobStore.availableSkills)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .textCase(.uppercase)
            .padding(.bottom, 5)
    }

    private func storeImportedDocuments() -> [JobDocument] {
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
        return savedDocs
    }

    private func handleImportedFiles(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                guard let data = try? Data(contentsOf: url) else { continue }
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
        case .failure(let error):
            print("Failed to import files: \(error)")
        }
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
        var cleanedName = filename.replacingOccurrences(of: "_", with: " ")
        cleanedName = cleanedName.replacingOccurrences(of: "-", with: " ")
        cleanedName = cleanedName.replacingOccurrences(of: "\\d", with: "", options: .regularExpression)
        let toRemove = ["Roger Lin", "Position", "2024", "Cover Letter"]
        for remove in toRemove {
            cleanedName = cleanedName.replacingOccurrences(of: remove, with: "")
        }
        cleanedName = cleanedName.trimmingCharacters(in: .whitespaces)
        for ext in [".pdf", ".docx", ".pages"] {
            if cleanedName.hasSuffix(ext) {
                cleanedName = String(cleanedName.dropLast(ext.count))
                break
            }
        }
        return cleanedName.trimmingCharacters(in: .whitespaces)
    }
}

struct EditJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var isPresented: Bool
    @StateObject private var viewModel: JobViewModel
    @State private var importedDocuments: [JobDocument] = []
    @State private var isImporting = false
    @State private var locations: [String] = CityCoordinateDictionary.keys.sorted()
    @State private var showAddLocationSheet = false
    @State private var quickLookURL: URL? = nil

    let markdownParser = MarkdownParser()

    init(isPresented: Binding<Bool>, job: JobApplication) {
        self._isPresented = isPresented
        _viewModel = StateObject(wrappedValue: JobViewModel(job: job, availableSkills: []))
        _importedDocuments = State(initialValue: job.documents)
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
                            .modifier(TranslucentTextFieldStyle())
                            .controlSize(.large)
                            .onChange(of: viewModel.companyName) { _, _ in viewModel.validateInputs() }
                        TextField("Job Title", text: $viewModel.jobTitle)
                            .modifier(TranslucentTextFieldStyle())
                            .controlSize(.large)
                            .onChange(of: viewModel.jobTitle) { _, _ in viewModel.validateInputs() }
                        sectionHeader("Application Details")
                        TextField("Link to Job", text: $viewModel.linkToJob)
                            .modifier(TranslucentTextFieldStyle())
                            .controlSize(.large)
                        TextField("Salary", value: $viewModel.salaryDouble, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .modifier(TranslucentTextFieldStyle())
                            .controlSize(.large)
                        Picker("Status", selection: $viewModel.status) {
                            ForEach(JobStatus.allCases, id: \.self) { status in
                                Text(status.rawValue).tag(status)
                            }
                        }
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
                        DatePicker("Application Date", selection: $viewModel.dateOfApplication, displayedComponents: .date)
                        DatePicker("Application Deadline", selection: $viewModel.applicationDeadline, displayedComponents: .date)
                        HStack {
                            TextField("Enter desired skills", text: $viewModel.desiredSkillText, onCommit: {
                                viewModel.addSelectedSkill(skillName: viewModel.desiredSkillText, jobStore: jobStore)
                            })
                            .modifier(TranslucentTextFieldStyle())
                        }
                        if !viewModel.selectedDesiredSkills.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(viewModel.selectedDesiredSkills, id: \.self) { skill in
                                        SkillTag(skillName: skill, removeAction: {
                                            viewModel.removeSelectedSkill(skillName: skill)
                                        })
                                    }
                                }
                            }
                        }
                        Button("Select Documents") {
                            isImporting = true
                        }
                        sectionHeader("Job Description")
                        HStack {
                            Text("Job Description").font(.headline)
                            Button("Paste") {
                                if let clipboardText = NSPasteboard.general.string(forType: .string) {
                                    viewModel.jobDescription = clipboardText
                                }
                            }
                            .help("Paste from Clipboard")
                        }
                        TextEditor(text: $viewModel.jobDescription)
                            .frame(minHeight: 200)
                            .modifier(TranslucentTextEditorStyle())
                            .scrollContentBackground(.hidden)
                            .onChange(of: viewModel.jobDescription) { newValue in
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
                                if viewModel.companyName.isEmpty {
                                    for existingApp in jobStore.jobApplications {
                                        if newValue.localizedCaseInsensitiveContains(existingApp.companyName) {
                                            viewModel.companyName = existingApp.companyName
                                            break
                                        }
                                    }
                                }
                            }
                        Button("Parse Description") {
                            parseJobDescription()
                        }
                        sectionHeader("Cover Letter")
                        TextEditor(text: $viewModel.coverLetter)
                            .frame(minHeight: 200)
                            .modifier(TranslucentTextEditorStyle())
                            .scrollContentBackground(.hidden)
                        sectionHeader("Notes")
                        TextEditor(text: $viewModel.notes)
                            .frame(minHeight: 200)
                            .modifier(TranslucentTextEditorStyle())
                            .scrollContentBackground(.hidden)
                    }
                    .padding()
                }
                HStack {
                    Button("Cancel", role: .cancel) {
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    Spacer()
                    Button("Save") {
                        saveJob()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(!viewModel.isInputValid)
                }
                .padding()
            }
            .frame(minWidth: 500, minHeight: 700)
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
            viewModel.updateSkillSuggestions(availableSkills: jobStore.availableSkills)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .textCase(.uppercase)
            .padding(.bottom, 5)
    }

    private func handleImportedFiles(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                guard let data = try? Data(contentsOf: url) else { continue }
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
        case .failure(let error):
            print("Failed to import files: \(error)")
        }
    }

    private func parseJobDescription() {
        var text = viewModel.jobDescription
        text = text.replacingMultipleBlankLines()
        text = text.replacingInvalidBullets()
        text = text.ensuringListItemsOnSeparateLines()
        text = text.formattingSectionHeaders()
        if viewModel.jobTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let title = text.extractJobTitle() {
            viewModel.jobTitle = title
        }
        if let url = text.extractURL() {
            viewModel.linkToJob = url
        }
        if let loc = text.extractLocation(from: predefinedCityNames) {
            viewModel.location = loc
        }
        viewModel.jobDescription = text
    }

    private func saveJob() {
        viewModel.validateInputs()
        guard viewModel.isInputValid else { return }
        let finalDocs = storeImportedDocuments()
        docStore.mergeDocuments(finalDocs)
        viewModel.addJob(to: jobStore, documents: finalDocs)
        isPresented = false
    }

    private func storeImportedDocuments() -> [JobDocument] {
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
        return savedDocs
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
}

struct JobDetailView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    let job: JobApplication
    @State private var selectedQualityFilter: String? = nil
    let markdownParser = MarkdownParser()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(job.companyName)
                    .font(.largeTitle)
                    .bold()
                Text(job.jobTitle)
                    .font(.title2)
                Button(action: {}) {
                    Text(job.status.rawValue)
                        .padding(5)
                }
                .buttonStyle(BorderlessButtonStyle())
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray, lineWidth: 1)
                )
                HStack {
                    Text("Link to Job:")
                    Text(job.linkToJob ?? "")
                        .foregroundColor(.blue)
                }
                HStack {
                    Text("Location:")
                    Text(job.location)
                }
                HStack {
                    Text("Application Date:")
                    Text(formatDate(job.dateOfApplication))
                }
                HStack {
                    Text("Application Deadline:")
                    Text(formatDate(job.applicationDeadline))
                }
                if !job.desiredSkills.isEmpty {
                    HStack {
                        Text("Desired Skills:")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(job.desiredSkills, id: \.self) { skill in
                                    Button(action: {
                                        if selectedQualityFilter == skill {
                                            selectedQualityFilter = nil
                                            jobStore.selectedQualityFilter = nil
                                        } else {
                                            selectedQualityFilter = skill
                                            jobStore.selectedQualityFilter = skill
                                        }
                                    }) {
                                        Text(skill)
                                            .padding(5)
                                            .background(selectedQualityFilter == skill ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                                            .cornerRadius(5)
                                    }
                                }
                            }
                        }
                    }
                }
                if !job.documents.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Documents:")
                        ForEach(job.documents, id: \.self) { url in
                            Text(url.lastPathComponent)
                        }
                    }
                }
                Divider()
                Section(header: Text("Job Description").bold()) {
                    Text(markdownParser.parse(job.jobDescription))
                        .font(.system(size: 18))
                        .padding()
                }
                Section(header: Text("Cover Letter").bold()) {
                    Text(markdownParser.parse(job.coverLetter))
                        .font(.system(size: 18))
                        .padding()
                }
                Section(header: Text("Notes").bold()) {
                    Text(markdownParser.parse(job.notes ?? ""))
                        .font(.system(size: 18))
                        .padding()
                }
            }
            .padding()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

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
            VStack(spacing: 20) {
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
                .padding()
            }
            .padding()
            .frame(width: 300, height: 250)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
            .background(WindowAccessor { window in
                window?.isMovableByWindowBackground = true
            })
        }
        .frame(width: 300, height: 250)
    }
}

struct WindowAccessor: NSViewRepresentable {
    let configure: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            configure(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        configure(nsView.window)
    }
}

struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.purple.opacity(0.4),
                Color.blue.opacity(0.4)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
    @State private var showDocInfoPopover: Bool = false

    var body: some View {
        NavigationView {
            sidebar
                .frame(minWidth: 250)
                .background(Color.black.opacity(0.03).blur(radius: 3))
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
                $0.companyName.lowercased().contains(lower) ||
                $0.jobTitle.lowercased().contains(lower) ||
                $0.location.lowercased().contains(lower)
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
                        isSelected ? Color(nsColor: .selectedTextBackgroundColor).opacity(0.6) : job.status.displayColor.opacity(0.2)
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

struct DocumentInfoPopover: View {
    var document: JobDocument?
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let doc = document {
                Text("File Name: \(doc.fileName)")
                    .font(.headline)
                if let url = doc.fileURL {
                    Text("File URL: \(url.absoluteString)")
                        .font(.subheadline)
                }
                Text("Created: \(doc.creationDate.formatted(date: .long, time: .shortened))")
                Text("Last Modified: \(doc.lastModifiedDate.formatted(date: .long, time: .shortened))")
                Text("File Size: \(doc.fileSize) bytes")
                Text("Word Count: \(doc.wordCount)")
            } else {
                Text("No document selected.")
            }
            Spacer()
        }
        .padding()
        .frame(minWidth: 300, minHeight: 200)
    }
}

struct AddJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var isPresented: Bool

    @StateObject private var viewModel = JobViewModel()
    @State private var importedDocuments: [JobDocument] = []
    @State private var locations: [String] = CityCoordinateDictionary.keys.sorted()
    @State private var showAddLocationSheet = false
    @State private var isImporting = false
    @State private var quickLookURL: URL? = nil

    let markdownParser = MarkdownParser()

    var body: some View {
        ZStack {
            PastelGradientBackground()
            VStack {
                Text("Add New Job")
                    .font(.title2)
                    .padding()
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("JOB DETAILS")
                        TextField("Company Name", text: $viewModel.companyName)
                            .translucentTextFieldStyle()
                            .controlSize(.large)
                            .onChange(of: viewModel.companyName) { _, _ in viewModel.validateInputs() }
                        TextField("Job Title", text: $viewModel.jobTitle)
                            .translucentTextFieldStyle()
                            .controlSize(.large)
                            .onChange(of: viewModel.jobTitle) { _, _ in viewModel.validateInputs() }
                        sectionHeader("APPLICATION DETAILS")
                        TextField("Link to Job", text: $viewModel.linkToJob)
                            .translucentTextFieldStyle()
                            .controlSize(.large)
                        TextField("Salary", value: $viewModel.salaryDouble, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .translucentTextFieldStyle()
                            .controlSize(.large)
                        Picker("Status", selection: $viewModel.status) {
                            ForEach(JobStatus.allCases, id: \.self) { status in
                                Text(status.rawValue).tag(status)
                            }
                        }
                        Picker("Location", selection: $viewModel.location) {
                            ForEach(locations, id: \.self) { location in
                                Text(location).tag(location)
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
                        DatePicker("Application Deadline", selection: $viewModel.applicationDeadline, displayedComponents: .date)
                        HStack {
                            TextField("Enter desired skills (comma-separated)", text: $viewModel.desiredSkillText, onCommit: {
                                viewModel.addSelectedSkill(skillName: viewModel.desiredSkillText, jobStore: jobStore)
                            })
                            .translucentTextFieldStyle()
                        }
                        if !viewModel.selectedDesiredSkills.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(viewModel.selectedDesiredSkills, id: \.self) { skill in
                                        SkillTag(skillName: skill, removeAction: {
                                            viewModel.removeSelectedSkill(skillName: skill)
                                        })
                                    }
                                }
                            }
                        }
                        Button("Select Documents") {
                            isImporting = true
                        }
                        sectionHeader("JOB DESCRIPTION")
                        HStack {
                            Text("Job Description").font(.headline)
                            Button("Paste") {
                                if let clipboardText = NSPasteboard.general.string(forType: .string) {
                                    viewModel.jobDescription = clipboardText
                                }
                            }
                            .help("Paste from Clipboard")
                        }
                        TextEditor(text: $viewModel.jobDescription)
                            .frame(minHeight: 200)
                            .translucentTextEditorStyle()
                            .scrollContentBackground(.hidden)
                            .onChange(of: viewModel.jobDescription) { newValue in
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
                                if viewModel.companyName.isEmpty {
                                    for existingApp in jobStore.jobApplications {
                                        if newValue.localizedCaseInsensitiveContains(existingApp.companyName) {
                                            viewModel.companyName = existingApp.companyName
                                            break
                                        }
                                    }
                                }
                            }
                        Button("Parse Description") {
                            parseJobDescription()
                        }
                        sectionHeader("COVER LETTER")
                        TextEditor(text: $viewModel.coverLetter)
                            .frame(minHeight: 200)
                            .translucentTextEditorStyle()
                            .scrollContentBackground(.hidden)
                        sectionHeader("NOTES")
                        TextEditor(text: $viewModel.notes)
                            .frame(minHeight: 200)
                            .translucentTextEditorStyle()
                            .scrollContentBackground(.hidden)
                    }
                    .padding()
                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
                }
                HStack {
                    Button("Cancel", role: .cancel) {
                        isPresented = false
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
        }
        .frame(minWidth: 500, minHeight: 700)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf, .plainText, .rtf, .image],
            allowsMultipleSelection: true
        ) { result in
            handleImportedFiles(result: result)
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
            viewModel.updateSkillSuggestions(availableSkills: jobStore.availableSkills)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .textCase(.uppercase)
            .padding(.bottom, 5)
    }

    private func storeImportedDocuments() -> [JobDocument] {
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
        return savedDocs
    }

    private func handleImportedFiles(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                guard let data = try? Data(contentsOf: url) else { continue }
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
        case .failure(let error):
            print("Failed to import files: \(error)")
        }
    }

    private func parseJobDescription() {
        var text = viewModel.jobDescription
        text = text.replacingMultipleBlankLines()
        text = text.replacingInvalidBullets()
        text = text.ensuringListItemsOnSeparateLines()
        text = text.formattingSectionHeaders()
        if viewModel.jobTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let title = text.extractJobTitle() {
            viewModel.jobTitle = title
        }
        if let url = text.extractURL() {
            viewModel.linkToJob = url
        }
        if let loc = text.extractLocation(from: predefinedCityNames) {
            viewModel.location = loc
        }
        viewModel.jobDescription = text
    }

    private func selectDocuments() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.item]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.begin { response in
            if response == .OK {
                viewModel.documents.append(contentsOf: panel.urls.map {
                    let data = (try? Data(contentsOf: $0)) ?? Data()
                    return JobDocument(fileName: $0.lastPathComponent, fileData: data, fileURL: $0)
                })
            }
        }
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
}

struct JobDetailView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    let job: JobApplication
    @State private var selectedQualityFilter: String? = nil
    let markdownParser = MarkdownParser()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(job.companyName)
                    .font(.largeTitle)
                    .bold()
                Text(job.jobTitle)
                    .font(.title2)
                Button(action: {}) {
                    Text(job.status.rawValue)
                        .padding(5)
                }
                .buttonStyle(BorderlessButtonStyle())
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray, lineWidth: 1)
                )
                HStack {
                    Text("Link to Job:")
                    Text(job.linkToJob ?? "")
                        .foregroundColor(.blue)
                }
                HStack {
                    Text("Location:")
                    Text(job.location)
                }
                HStack {
                    Text("Application Date:")
                    Text(formatDate(job.dateOfApplication))
                }
                HStack {
                    Text("Application Deadline:")
                    Text(formatDate(job.applicationDeadline))
                }
                if !job.desiredSkills.isEmpty {
                    HStack {
                        Text("Desired Skills:")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(job.desiredSkills, id: \.self) { skill in
                                    Button(action: {
                                        if selectedQualityFilter == skill {
                                            selectedQualityFilter = nil
                                            jobStore.selectedQualityFilter = nil
                                        } else {
                                            selectedQualityFilter = skill
                                            jobStore.selectedQualityFilter = skill
                                        }
                                    }) {
                                        Text(skill)
                                            .padding(5)
                                            .background(selectedQualityFilter == skill ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                                            .cornerRadius(5)
                                    }
                                }
                            }
                        }
                    }
                }
                if !job.documents.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Documents:")
                        ForEach(job.documents, id: \.self) { url in
                            Text(url.lastPathComponent)
                        }
                    }
                }
                Divider()
                Section(header: Text("Job Description").bold()) {
                    Text(markdownParser.parse(job.jobDescription))
                        .font(.system(size: 18))
                        .padding()
                }
                Section(header: Text("Cover Letter").bold()) {
                    Text(markdownParser.parse(job.coverLetter))
                        .font(.system(size: 18))
                        .padding()
                }
                Section(header: Text("Notes").bold()) {
                    Text(markdownParser.parse(job.notes ?? ""))
                        .font(.system(size: 18))
                        .padding()
                }
            }
            .padding()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

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
            VStack(spacing: 20) {
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
                .padding()
            }
            .padding()
            .frame(width: 300, height: 250)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
            .background(WindowAccessor { window in
                window?.isMovableByWindowBackground = true
            })
        }
        .frame(width: 300, height: 250)
    }
}

struct WindowAccessor: NSViewRepresentable {
    let configure: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            configure(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        configure(nsView.window)
    }
}

struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.purple.opacity(0.4),
                Color.blue.opacity(0.4)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
    @State private var showDocInfoPopover: Bool = false

    var body: some View {
        NavigationView {
            sidebar
                .frame(minWidth: 250)
                .background(Color.black.opacity(0.03).blur(radius: 3))
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
                $0.companyName.lowercased().contains(lower) ||
                $0.jobTitle.lowercased().contains(lower) ||
                $0.location.lowercased().contains(lower)
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
                        isSelected ? Color(nsColor: .selectedTextBackgroundColor).opacity(0.6) : job.status.displayColor.opacity(0.2)
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

struct DocumentInfoPopover: View {
    var document: JobDocument?
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let doc = document {
                Text("File Name: \(doc.fileName)")
                    .font(.headline)
                if let url = doc.fileURL {
                    Text("File URL: \(url.absoluteString)")
                        .font(.subheadline)
                }
                Text("Created: \(doc.creationDate.formatted(date: .long, time: .shortened))")
                Text("Last Modified: \(doc.lastModifiedDate.formatted(date: .long, time: .shortened))")
                Text("File Size: \(doc.fileSize) bytes")
                Text("Word Count: \(doc.wordCount)")
            } else {
                Text("No document selected.")
            }
            Spacer()
        }
        .padding()
        .frame(minWidth: 300, minHeight: 200)
    }
}

struct AddJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var isPresented: Bool

    @StateObject private var viewModel = JobViewModel()
    @State private var importedDocuments: [JobDocument] = []
    @State private var locations: [String] = CityCoordinateDictionary.keys.sorted()
    @State private var showAddLocationSheet = false
    @State private var isImporting = false
    @State private var quickLookURL: URL? = nil

    let markdownParser = MarkdownParser()

    var body: some View {
        ZStack {
            PastelGradientBackground()
            VStack {
                Text("Add New Job")
                    .font(.title2)
                    .padding()
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("JOB DETAILS")
                        TextField("Company Name", text: $viewModel.companyName)
                            .translucentTextFieldStyle()
                            .controlSize(.large)
                            .onChange(of: viewModel.companyName) { _, _ in viewModel.validateInputs() }
                        TextField("Job Title", text: $viewModel.jobTitle)
                            .translucentTextFieldStyle()
                            .controlSize(.large)
                            .onChange(of: viewModel.jobTitle) { _, _ in viewModel.validateInputs() }
                        sectionHeader("APPLICATION DETAILS")
                        TextField("Link to Job", text: $viewModel.linkToJob)
                            .translucentTextFieldStyle()
                            .controlSize(.large)
                        TextField("Salary", value: $viewModel.salaryDouble, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .translucentTextFieldStyle()
                            .controlSize(.large)
                        Picker("Status", selection: $viewModel.status) {
                            ForEach(JobStatus.allCases, id: \.self) { status in
                                Text(status.rawValue).tag(status)
                            }
                        }
                        Picker("Location", selection: $viewModel.location) {
                            ForEach(locations, id: \.self) { location in
                                Text(location).tag(location)
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
                        DatePicker("Application Deadline", selection: $viewModel.applicationDeadline, displayedComponents: .date)
                        HStack {
                            TextField("Enter desired skills (comma-separated)", text: $viewModel.desiredSkillText, onCommit: {
                                viewModel.addSelectedSkill(skillName: viewModel.desiredSkillText, jobStore: jobStore)
                            })
                            .translucentTextFieldStyle()
                        }
                        if !viewModel.selectedDesiredSkills.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(viewModel.selectedDesiredSkills, id: \.self) { skill in
                                        SkillTag(skillName: skill, removeAction: {
                                            viewModel.removeSelectedSkill(skillName: skill)
                                        })
                                    }
                                }
                            }
                        }
                        Button("Select Documents") {
                            isImporting = true
                        }
                        sectionHeader("JOB DESCRIPTION")
                        HStack {
                            Text("Job Description").font(.headline)
                            Button("Paste") {
                                if let clipboardText = NSPasteboard.general.string(forType: .string) {
                                    viewModel.jobDescription = clipboardText
                                }
                            }
                            .help("Paste from Clipboard")
                        }
                        TextEditor(text: $viewModel.jobDescription)
                            .frame(minHeight: 200)
                            .translucentTextEditorStyle()
                            .scrollContentBackground(.hidden)
                            .onChange(of: viewModel.jobDescription) { newValue in
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
                                if viewModel.companyName.isEmpty {
                                    for existingApp in jobStore.jobApplications {
                                        if newValue.localizedCaseInsensitiveContains(existingApp.companyName) {
                                            viewModel.companyName = existingApp.companyName
                                            break
                                        }
                                    }
                                }
                            }
                        Button("Parse Description") {
                            parseJobDescription()
                        }
                        sectionHeader("COVER LETTER")
                        TextEditor(text: $viewModel.coverLetter)
                            .frame(minHeight: 200)
                            .translucentTextEditorStyle()
                            .scrollContentBackground(.hidden)
                        sectionHeader("NOTES")
                        TextEditor(text: $viewModel.notes)
                            .frame(minHeight: 200)
                            .translucentTextEditorStyle()
                            .scrollContentBackground(.hidden)
                    }
                    .padding()
                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
                }
                HStack {
                    Button("Cancel", role: .cancel) {
                        isPresented = false
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
        }
        .frame(minWidth: 500, minHeight: 700)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf, .plainText, .rtf, .image],
            allowsMultipleSelection: true
        ) { result in
            handleImportedFiles(result: result)
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
            viewModel.updateSkillSuggestions(availableSkills: jobStore.availableSkills)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .textCase(.uppercase)
            .padding(.bottom, 5)
    }

    private func storeImportedDocuments() -> [JobDocument] {
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
        return savedDocs
    }

    private func handleImportedFiles(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                guard let data = try? Data(contentsOf: url) else { continue }
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
        case .failure(let error):
            print("Failed to import files: \(error)")
        }
    }

    private func parseJobDescription() {
        var text = viewModel.jobDescription
        text = text.replacingMultipleBlankLines()
        text = text.replacingInvalidBullets()
        text = text.ensuringListItemsOnSeparateLines()
        text = text.formattingSectionHeaders()
        if viewModel.jobTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let title = text.extractJobTitle() {
            viewModel.jobTitle = title
        }
        if let url = text.extractURL() {
            viewModel.linkToJob = url
        }
        if let loc = text.extractLocation(from: predefinedCityNames) {
            viewModel.location = loc
        }
        viewModel.jobDescription = text
    }

    private func selectDocuments() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.item]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.begin { response in
            if response == .OK {
                viewModel.documents.append(contentsOf: panel.urls.map {
                    let data = (try? Data(contentsOf: $0)) ?? Data()
                    return JobDocument(fileName: $0.lastPathComponent, fileData: data, fileURL: $0)
                })
            }
        }
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
}

struct JobDetailView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    let job: JobApplication
    @State private var selectedQualityFilter: String? = nil
    let markdownParser = MarkdownParser()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(job.companyName)
                    .font(.largeTitle)
                    .bold()
                Text(job.jobTitle)
                    .font(.title2)
                Button(action: {}) {
                    Text(job.status.rawValue)
                        .padding(5)
                }
                .buttonStyle(BorderlessButtonStyle())
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray, lineWidth: 1)
                )
                HStack {
                    Text("Link to Job:")
                    Text(job.linkToJob ?? "")
                        .foregroundColor(.blue)
                }
                HStack {
                    Text("Location:")
                    Text(job.location)
                }
                HStack {
                    Text("Application Date:")
                    Text(formatDate(job.dateOfApplication))
                }
                HStack {
                    Text("Application Deadline:")
                    Text(formatDate(job.applicationDeadline))
                }
                if !job.desiredSkills.isEmpty {
                    HStack {
                        Text("Desired Skills:")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(job.desiredSkills, id: \.self) { skill in
                                    Button(action: {
                                        if selectedQualityFilter == skill {
                                            selectedQualityFilter = nil
                                            jobStore.selectedQualityFilter = nil
                                        } else {
                                            selectedQualityFilter = skill
                                            jobStore.selectedQualityFilter = skill
                                        }
                                    }) {
                                        Text(skill)
                                            .padding(5)
                                            .background(selectedQualityFilter == skill ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                                            .cornerRadius(5)
                                    }
                                }
                            }
                        }
                    }
                }
                if !job.documents.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Documents:")
                        ForEach(job.documents, id: \.self) { url in
                            Text(url.lastPathComponent)
                        }
                    }
                }
                Divider()
                Section(header: Text("Job Description").bold()) {
                    Text(markdownParser.parse(job.jobDescription))
                        .font(.system(size: 18))
                        .padding()
                }
                Section(header: Text("Cover Letter").bold()) {
                    Text(markdownParser.parse(job.coverLetter))
                        .font(.system(size: 18))
                        .padding()
                }
                Section(header: Text("Notes").bold()) {
                    Text(markdownParser.parse(job.notes ?? ""))
                        .font(.system(size: 18))
                        .padding()
                }
            }
            .padding()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

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
            VStack(spacing: 20) {
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
                .padding()
            }
            .padding()
            .frame(width: 300, height: 250)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
            .background(WindowAccessor { window in
                window?.isMovableByWindowBackground = true
            })
        }
        .frame(width: 300, height: 250)
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
            try createZipArchive(at: tempDir, destination: url)
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


