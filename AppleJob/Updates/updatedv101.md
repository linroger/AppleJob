
// AppleJobApp.swift
// AppleJobApp
// Created by [Your Name] on [Date]

import SwiftUI

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
                            jobStore.updateJobStatus(Set([selectedJob.id]), to: status)
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
import AppKit
import UniformTypeIdentifiers
import PDFKit
import MapKit
            }
import Charts
import Quartz
import QuickLook
import QuickLookUI
import MarkdownKit
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
// Models/JobModels.swift
// Contains all model definitions.

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

// MARK: - JobType, JobStatus, Sort

enum JobType: String, CaseIterable, Codable, CaseNameDisplayable {
    case internship = "Internship"
    case fullTime = "Full Time"
    case offCycleInternship = "Off-Cycle Internship"
    case none = "None" // Default if no type is selected

    var displayName: String {
        self.caseNameForDisplay()
    }
}

protocol CaseNameDisplayable: RawRepresentable, CaseIterable where RawValue == String, AllCases: Collection {
    func caseNameForDisplay() -> String
}

extension CaseNameDisplayable {
    func caseNameForDisplay() -> String {
        self.rawValue
    }
}

enum JobStatus: String, CaseIterable, Codable, CaseNameDisplayable {
    case interested = "Interested"
    case applied = "Applied"
    case interview = "Interview"
    case offer = "Offer"
    case rejection = "Rejection"

    var displayName: String {
        self.caseNameForDisplay()
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
        self.caseNameForDisplay()
    }
}

/// Represents a desired skill with potential aliases.
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

/// Represents a single job application.
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
        case id, companyName, jobTitle, statusRawValue, dateOfApplication, location, linkToJobString, salary, jobDescription, coverLetter, notes, isFavorite, documents, jobType, desiredSkillNames, jobDeadline
    }

    static func == (lhs: JobApplication, rhs: JobApplication) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// A model for uploaded documents.
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
/// Category for documents.
struct DocumentCategory: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var isExpanded: Bool = true

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

// MARK: - Additional Models for Charts (Not the main focus)

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

// MARK: - Dictionary Conversion Extensions (Also in Utilities/Extensions.swift)

extension JobApplication {
    func toDictionary() -> [String: Any] {
        let isoFormatter = ISO8601DateFormatter()
        var dict: [String: Any] = [
            "id": id.uuidString,
            "companyName": companyName,
            "jobTitle": jobTitle,
            "status": status.rawValue,
            "dateOfApplication": isoFormatter.string(from: dateOfApplication),
            "location": location,
            "jobDescription": jobDescription,
            "coverLetter": coverLetter,
            "isFavorite": isFavorite,
            "jobType": jobType.rawValue,
            "desiredSkillNames": desiredSkillNames,
            "documents": documents.map { $0.toDictionary() }
        ]
        if let link = linkToJobString { dict["linkToJobString"] = link }
        if let salary = salary { dict["salary"] = salary }
        if let notes = notes { dict["notes"] = notes }
        if let deadline = jobDeadline { dict["jobDeadline"] = isoFormatter.string(from: deadline) }
        return dict
    }

    static func fromDictionary(_ dict: [String: Any]) -> JobApplication? {
        let isoFormatter = ISO8601DateFormatter()
        guard let idStr = dict["id"] as? String,
              let id = UUID(uuidString: idStr),
              let companyName = dict["companyName"] as? String,
              let jobTitle = dict["jobTitle"] as? String,
              let statusStr = dict["status"] as? String,
              let status = JobStatus(rawValue: statusStr),
              let dateStr = dict["dateOfApplication"] as? String,
              let dateOfApplication = isoFormatter.date(from: dateStr),
              let location = dict["location"] as? String,
              let jobDescription = dict["jobDescription"] as? String,
              let coverLetter = dict["coverLetter"] as? String,
              let isFavorite = dict["isFavorite"] as? Bool,
              let jobTypeStr = dict["jobType"] as? String,
              let jobType = JobType(rawValue: jobTypeStr),
              let desiredSkillNames = dict["desiredSkillNames"] as? [String],
              let docsArray = dict["documents"] as? [[String: Any]]
        else { return nil }

        let linkToJobString = dict["linkToJobString"] as? String
        let salary = dict["salary"] as? Double
        let notes = dict["notes"] as? String
        var jobDeadline: Date? = nil
        if let deadlineStr = dict["jobDeadline"] as? String {
            jobDeadline = isoFormatter.date(from: deadlineStr)
        }
        var documents: [JobDocument] = []
        for docDict in docsArray {
            if let doc = JobDocument.fromDictionary(docDict) {
                documents.append(doc)
            }
        }
        return JobApplication(
            id: id,
            companyName: companyName,
            jobTitle: jobTitle,
            status: status,
            dateOfApplication: dateOfApplication,
            location: location,
            linkToJobString: linkToJobString,
            salary: salary,
            jobDescription: jobDescription,
            coverLetter: coverLetter,
            notes: notes,
            documents: documents,
            isFavorite: isFavorite,
            jobType: jobType,
            desiredSkillNames: desiredSkillNames,
            jobDeadline: jobDeadline
        )
    }
}

extension JobDocument {
    func toDictionary() -> [String: Any] {
        let isoFormatter = ISO8601DateFormatter()
        var dict: [String: Any] = [
            "id": id.uuidString,
            "fileName": fileName,
            "fileData": fileData.base64EncodedString(),
            "creationDate": isoFormatter.string(from: creationDate),
            "lastModifiedDate": isoFormatter.string(from: lastModifiedDate),
            "fileSize": fileSize,
            "wordCount": wordCount
        ]
        if let fileURL = fileURL { dict["fileURL"] = fileURL.absoluteString }
        if let categoryID = categoryID { dict["categoryID"] = categoryID.uuidString }
        return dict
    }

    static func fromDictionary(_ dict: [String: Any]) -> JobDocument? {
        let isoFormatter = ISO8601DateFormatter()
        guard let idStr = dict["id"] as? String,
              let id = UUID(uuidString: idStr),
              let fileName = dict["fileName"] as? String,
              let fileDataStr = dict["fileData"] as? String,
              let fileData = Data(base64Encoded: fileDataStr),
              let creationDateStr = dict["creationDate"] as? String,
              let creationDate = isoFormatter.date(from: creationDateStr),
              let lastModifiedDateStr = dict["lastModifiedDate"] as? String,
              let lastModifiedDate = isoFormatter.date(from: lastModifiedDateStr),
              let fileSize = dict["fileSize"] as? Int,
              let wordCount = dict["wordCount"] as? Int
        else { return nil }
        let fileURL: URL? = {
            if let urlStr = dict["fileURL"] as? String { return URL(string: urlStr) }
            return nil
        }()
        let categoryID: UUID? = {
            if let catIDStr = dict["categoryID"] as? String { return UUID(uuidString: catIDStr) }
            return nil
        }()
        return JobDocument(
            id: id,
            fileName: fileName,
            fileData: fileData,
            fileURL: fileURL,
            creation: creationDate,
            lastModified: lastModifiedDate,
            fileSize: fileSize,
            wordCount: wordCount,
            categoryID: categoryID
        )
    }
}

extension DesiredSkill {
    func toDictionary() -> [String: Any] {
        [
            "id": id.uuidString,
            "name": name,
            "aliases": aliases
        ]
    }

    static func fromDictionary(_ dict: [String: Any]) -> DesiredSkill? {
        guard let idStr = dict["id"] as? String,
              let id = UUID(uuidString: idStr),
              let name = dict["name"] as? String,
              let aliases = dict["aliases"] as? [String]
        else { return nil }
        return DesiredSkill(id: id, name: name, aliases: aliases)
    }
}
// ViewModels/JobViewModel.swift
// Contains the JobViewModel and ParsedJobDescriptionResult

import SwiftUI
import Foundation

/// Helper struct for parsing job descriptions.
struct ParsedJobDescriptionResult {
    var sanitizedText: String
    var detectedJobTitle: String?
    var detectedCompanyName: String?
    var detectedLocation: String?
    var detectedDesiredSkills: String?
    var detectedURL: String?
}

/// View model used for AddJobView and EditJobView.
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

    // Optional job deadline
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
        jobDeadline = job.jobDeadline
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

    func parseDescriptionIfNeeded() {
        let currentDescription = self.jobDescription
        let parseResult = parseJobDescriptionText(currentDescription)

        if parseResult.sanitizedText != currentDescription {
            self.jobDescription = parseResult.sanitizedText
        }

        if jobTitle.isEmpty, let title = parseResult.detectedJobTitle {
            jobTitle = title
        }
        if companyName.isEmpty, let comp = parseResult.detectedCompanyName {
            companyName = comp
        }
        if location.isEmpty, let loc = parseResult.detectedLocation {
            location = loc
        }
        if selectedDesiredSkills.isEmpty, let skills = parseResult.detectedDesiredSkills {
            let skillsArray = skills.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            let titleCasedSkills = skillsArray.map { $0.capitalized }
            selectedDesiredSkills = titleCasedSkills
            desiredSkillText = titleCasedSkills.joined(separator: ", ")
        }
        if linkToJob.isEmpty, let url = parseResult.detectedURL {
            linkToJob = url
        }
        validateInputs()
    }

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

        let nsText = text as NSString
        let lines = nsText.components(separatedBy: .newlines)

        var cleanedLines: [String] = []
        var lastWasBlank = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                if !lastWasBlank { cleanedLines.append("") }
                lastWasBlank = true
            } else {
                cleanedLines.append(line)
                lastWasBlank = false
            }
        }

        let nonEmptyLines = cleanedLines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        var detectedJobTitle: String? = nil
        var detectedCompanyName: String? = nil
        var detectedLocation: String? = nil
        var detectedDesiredSkills: String? = nil
        var detectedURL: String? = nil

        for line in nonEmptyLines {
            let lowerLine = line.lowercased()
            if detectedJobTitle == nil, lowerLine.contains("job title:") {
                if let range = line.range(of: "Job Title:", options: .caseInsensitive) {
                    let value = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
                    detectedJobTitle = value.isEmpty ? nil : value
                }
            }
            if detectedCompanyName == nil, lowerLine.contains("company name:") {
                if let range = line.range(of: "Company Name:", options: .caseInsensitive) {
                    let value = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
                    detectedCompanyName = value.isEmpty ? nil : value
                }
            }
            if detectedLocation == nil, lowerLine.contains("job location:") {
                if let range = line.range(of: "Job Location:", options: .caseInsensitive) {
                    let value = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
                    detectedLocation = value.isEmpty ? nil : value
                }
            }
            if detectedDesiredSkills == nil, lowerLine.contains("desiredskills:") {
                if let range = line.range(of: "desiredskills:", options: .caseInsensitive) {
                    let value = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
                    detectedDesiredSkills = value.isEmpty ? nil : value
                }
            }
        }

        if let lastLine = nonEmptyLines.last, lastLine.lowercased().contains("job url:"), lastLine.lowercased().contains("http") {
            if let range = lastLine.range(of: "Job URL:", options: .caseInsensitive) {
                let value = lastLine[range.upperBound...].trimmingCharacters(in: .whitespaces)
                detectedURL = value.isEmpty ? nil : value
            }
        } else if let lastLine = nonEmptyLines.last, lastLine.lowercased().contains("http") {
            detectedURL = lastLine.trimmingCharacters(in: .whitespaces)
        }

        if detectedJobTitle == nil {
            detectedJobTitle = nonEmptyLines.count > 0 ? nonEmptyLines[0].trimmingCharacters(in: .whitespaces) : nil
        }
        if detectedCompanyName == nil {
            detectedCompanyName = nonEmptyLines.count > 1 ? nonEmptyLines[1].trimmingCharacters(in: .whitespaces) : nil
        }
        if detectedLocation == nil {
            detectedLocation = nonEmptyLines.count > 2 ? nonEmptyLines[2].trimmingCharacters(in: .whitespaces) : nil
        }
        if detectedDesiredSkills == nil {
            detectedDesiredSkills = nonEmptyLines.count > 3 ? nonEmptyLines[3].trimmingCharacters(in: .whitespaces) : nil
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
// Stores/JobStore.swift

import SwiftUI

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
        let jobsArray = jobApplications.map { $0.toDictionary() }
        if let jsonData = try? JSONSerialization.data(withJSONObject: jobsArray, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            UserDefaults.standard.set(jsonString, forKey: "jobs")
        }
        saveSkills()
    }

    func loadJobs() {
        if let savedData = UserDefaults.standard.data(forKey: "jobs"),
           let loadedApps = try? JSONDecoder().decode([JobApplication].self, from: savedData) {
            jobApplications = loadedApps
            sortJobs(by: sorting)
            return
        }
        guard let jsonString = UserDefaults.standard.string(forKey: "jobs"),
              let jsonData = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
              let jobsArray = jsonObject as? [[String: Any]]
        else { return }
        var loadedJobs: [JobApplication] = []
        for dict in jobsArray {
            if let job = JobApplication.fromDictionary(dict) {
                loadedJobs.append(job)
            }
        }
        jobApplications = loadedJobs
        sortJobs(by: sorting)
    }

    func importBackup(url: URL) {
        do {
            let jsonString = try String(contentsOf: url, encoding: .utf8)
            if let jsonData = jsonString.data(using: .utf8),
               let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
               let jobsArray = jsonObject as? [[String: Any]] {
                var importedJobs: [JobApplication] = []
                for dict in jobsArray {
                    if let job = JobApplication.fromDictionary(dict) {
                        importedJobs.append(job)
                    }
                }
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
        let jobsArray = jobApplications.map { $0.toDictionary() }
        if let jsonData = try? JSONSerialization.data(withJSONObject: jobsArray, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            do {
                try jsonString.write(to: url, atomically: true, encoding: .utf8)
                print("Exported backup.")
            } catch {
                print("Error exporting jobs: \(error)")
            }
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
        let skillsArray = availableSkills.map { $0.toDictionary() }
        if let jsonData = try? JSONSerialization.data(withJSONObject: skillsArray, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            UserDefaults.standard.set(jsonString, forKey: "desiredSkills")
        }
    }

    func loadSkills() {
        if let savedData = UserDefaults.standard.data(forKey: "desiredSkills"),
           let loadedSkills = try? JSONDecoder().decode([DesiredSkill].self, from: savedData) {
            availableSkills = loadedSkills
            return
        }
        guard let jsonString = UserDefaults.standard.string(forKey: "desiredSkills"),
              let jsonData = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
              let skillsArray = jsonObject as? [[String: Any]]
        else { return }
        var loadedSkills: [DesiredSkill] = []
        for dict in skillsArray {
            if let skill = DesiredSkill.fromDictionary(dict) {
                loadedSkills.append(skill)
            }
        }
        availableSkills = loadedSkills
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
// Stores/DocumentStore.swift

import SwiftUI

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
        if let jsonData = try? JSONSerialization.data(withJSONObject: documents.map({ $0.toDictionary() }), options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            UserDefaults.standard.set(jsonString, forKey: "documents")
        }
    }

    func loadDocuments() {
        guard let jsonString = UserDefaults.standard.string(forKey: "documents"),
              let jsonData = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
              let docsArray = jsonObject as? [[String: Any]]
        else { return }
        var loadedDocs: [JobDocument] = []
        for dict in docsArray {
            if let doc = JobDocument.fromDictionary(dict) {
                loadedDocs.append(doc)
            }
        }
        documents = loadedDocs
    }

    func saveCategories() {
        if let jsonData = try? JSONSerialization.data(withJSONObject: categories.map({ ["id": $0.id.uuidString, "name": $0.name, "isExpanded": $0.isExpanded] }), options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            UserDefaults.standard.set(jsonString, forKey: "documentCategories")
        }
    }

    func loadCategories() {
        guard let jsonString = UserDefaults.standard.string(forKey: "documentCategories"),
              let jsonData = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
              let catsArray = jsonObject as? [[String: Any]]
        else { return }
        var loadedCats: [DocumentCategory] = []
        for dict in catsArray {
            if let idStr = dict["id"] as? String,
               let id = UUID(uuidString: idStr),
               let name = dict["name"] as? String,
               let isExpanded = dict["isExpanded"] as? Bool {
                loadedCats.append(DocumentCategory(id: id, name: name))
                var cat = DocumentCategory(id: id, name: name)
                cat.isExpanded = isExpanded
                loadedCats.append(cat)
            }
        }
        categories = loadedCats
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
// Stores/ImportExportHelper.swift

import SwiftUI
import UniformTypeIdentifiers

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
// Utilities/Extensions.swift

import SwiftUI

// Gradient text extension.
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
// Views/ContentView.swift

import SwiftUI

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
                            .gradientForeground(colors: [.red, .orange])
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
// Views/JobSidebarView.swift

import SwiftUI

struct JobSidebarView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var searchText: String

    @State private var selectedJobIDs: Set<UUID> = []

    var body: some View {
        List {
            ForEach(filteredJobs, id: \.id) { job in
                SidebarRowItem(job: job, isSelected: .constant(jobStore.selectedJobIDs.contains(job.id)))
                    .listRowBackground(rowBackground(job: job))
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
                    showAddJobWindow()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func showAddJobWindow() {
        let vc = NSHostingController(rootView: AddJobWindowView()
            .environmentObject(jobStore)
            .environmentObject(docStore)
        )
        let window = NSWindow(contentViewController: vc)
        window.title = ""
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask = NSWindow.StyleMask([.titled, .closable, .resizable])
        window.makeKeyAndOrderFront(nil)
    }

    private func rowBackground(job: JobApplication) -> some View {
        if jobStore.selectedJobIDs.contains(job.id) {
            return AnyView(RoundedRectangle(cornerRadius: 8).fill(Color.blue))
        } else {
            return AnyView(Color.clear)
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
        for idx in offsets {
            let job = filteredJobs[idx]
            jobStore.deleteJob(for: job.id)
        }
    }
}

struct SidebarRowItem: View {
    @EnvironmentObject var jobStore: JobStore
    let job: JobApplication
    @Binding var isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(job.companyName)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .secondary)
                Text(job.jobTitle)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white : .secondary)
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
                .foregroundColor(isSelected ? .white : job.status.displayColor)
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
                            jobStore.updateJobStatus(Set([selectedJob.id]), to: status)
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
// Views/AddJobView.swift

import SwiftUI

struct AddJobWindowView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore

    var body: some View {
        AddJobView(isPresented: .constant(false))
            .environmentObject(jobStore)
            .environmentObject(docStore)
            .frame(minWidth: 450, minHeight: 600)
            .onDisappear {
                jobStore.isAddingNewJob = false
            }
    }
}

struct AddJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var isPresented: Bool

    @StateObject private var viewModel: JobViewModel = JobViewModel()
    @State private var importedDocuments: [JobDocument] = []
    @State private var locations: [String] = Array(CityCoordinateDictionary.keys).sorted()

    @State private var showNewLocationWindow = false

    var body: some View {
        VStack {
            Text("Add New Job")
                .font(.title2)
                .padding()
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Group {
                        Text("Company Name").font(.headline)
                        TextField("Company Name", text: $viewModel.companyName)
                            .textFieldStyle(.roundedBorder)
                            .background(.ultraThinMaterial.opacity(0.25))
                            .cornerRadius(10)
                            .onChange(of: viewModel.companyName) { _, _ in viewModel.validateInputs() }

                        Text("Job Title").font(.headline)
                        TextField("Job Title", text: $viewModel.jobTitle)
                            .textFieldStyle(.roundedBorder)
                            .background(.ultraThinMaterial.opacity(0.25))
                            .cornerRadius(10)
                            .onChange(of: viewModel.jobTitle) { _, _ in viewModel.validateInputs() }
                    }

                    Group {
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

                        Text("Location").font(.headline)
                        Picker("Location", selection: $viewModel.location) {
                            ForEach(locations, id: \.self) { loc in
                                Text(loc).tag(loc)
                            }
                            Text("Add New Location...").tag("Add New Location...")
                        }
                        .onChange(of: viewModel.location) { _, newValue in
                            if newValue == "Add New Location..." {
                                showNewLocationWindow = true
                            }
                        }
                    }

                    Group {
                        Text("Salary").font(.headline)
                        TextField("Salary", text: $viewModel.salaryString)
                            .textFieldStyle(.roundedBorder)
                            .background(.ultraThinMaterial.opacity(0.25))
                            .cornerRadius(8)
                            .onChange(of: viewModel.salaryString) { _, v in viewModel.updateSalary(fromString: v) }

                        Text("Link to Job").font(.headline)
                        TextField("Link to Job", text: $viewModel.linkToJob)
                            .textFieldStyle(.roundedBorder)
                            .background(.ultraThinMaterial.opacity(0.25))
                            .cornerRadius(10)
                    }

                    Group {
                        HStack {
                            Text("Job Description").font(.headline)
                            Button("Paste") {
                                if let clip = NSPasteboard.general.string(forType: .string) {
                                    viewModel.jobDescription = clip
                                }
                            }
                        }
                        TextEditor(text: $viewModel.jobDescription)
                            .cornerRadius(10)
                            .modifier(UltraThinMaterialTextEditorStyle())
                            .frame(height: 200)

                        Text("Cover Letter").font(.headline)
                        TextEditor(text: $viewModel.coverLetter)
                            .cornerRadius(10)
                            .modifier(UltraThinMaterialTextEditorStyle())
                            .frame(height: 100)

                        Text("Notes").font(.headline)
                        TextEditor(text: $viewModel.notes)
                            .cornerRadius(10)
                            .modifier(UltraThinMaterialTextEditorStyle())
                            .frame(height: 100)

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
                        .padding(.vertical, 5)
                    }

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
                    .padding(.bottom, 50)
                }
                .padding()
            }
        }
        .frame(minWidth: 400, minHeight: 500)
        .sheet(isPresented: $showNewLocationWindow) {
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
// Views/EditJobView.swift

import SwiftUI

struct EditJobWindowView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    let job: JobApplication

    var body: some View {
        EditJobView(isPresented: .constant(false), job: job)
            .environmentObject(jobStore)
            .environmentObject(docStore)
            .frame(minWidth: 450, minHeight: 600)
            .onDisappear {
                jobStore.isEditingJob = false
            }
    }
}

struct EditJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var isPresented: Bool

    @StateObject var viewModel: JobViewModel
    @State private var importedDocuments: [JobDocument] = []
    @State private var locations: [String] = Array(CityCoordinateDictionary.keys).sorted()

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
                    Group {
                        Text("Company Name").font(.headline)
                        TextField("Company Name", text: $viewModel.companyName)
                            .textFieldStyle(.roundedBorder)
                            .background(.ultraThinMaterial.opacity(0.25))
                            .cornerRadius(8)
                            .onChange(of: viewModel.companyName) { _, _ in viewModel.validateInputs() }

                        Text("Job Title").font(.headline)
                        TextField("Job Title", text: $viewModel.jobTitle)
                            .textFieldStyle(.roundedBorder)
                            .background(.ultraThinMaterial.opacity(0.25))
                            .cornerRadius(8)
                            .onChange(of: viewModel.jobTitle) { _, _ in viewModel.validateInputs() }
                    }

                    Group {
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

                        Text("Location").font(.headline)
                        Picker("Location", selection: $viewModel.location) {
                            ForEach(locations, id: \.self) { loc in
                                Text(loc).tag(loc)
                            }
                            Text("Add New Location...").tag("Add New Location...")
                        }
                        .onChange(of: viewModel.location) { _, newVal in
                            if newVal == "Add New Location..." {
                                showNewLocationWindow = true
                            }
                        }
                    }

                    Group {
                        Text("Salary").font(.headline)
                        TextField("Salary", text: $viewModel.salaryString)
                            .textFieldStyle(.roundedBorder)
                            .background(.ultraThinMaterial.opacity(0.25))
                            .cornerRadius(8)
                            .onChange(of: viewModel.salaryString) { _, v in viewModel.updateSalary(fromString: v) }

                        Text("Link to Job").font(.headline)
                        TextField("Link to Job", text: $viewModel.linkToJob)
                            .textFieldStyle(.roundedBorder)
                            .background(.ultraThinMaterial.opacity(0.25))
                            .cornerRadius(8)
                    }

                    Group {
                        Text("Job Description").font(.headline)
                        TextEditor(text: $viewModel.jobDescription)
                            .modifier(UltraThinMaterialTextEditorStyle())
                            .frame(height: 150)

                        Text("Cover Letter").font(.headline)
                        TextEditor(text: $viewModel.coverLetter)
                            .modifier(UltraThinMaterialTextEditorStyle())
                            .frame(height: 100)

                        Text("Notes").font(.headline)
                        TextEditor(text: $viewModel.notes)
                            .modifier(UltraThinMaterialTextEditorStyle())
                            .frame(height: 60)

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
                    }

                    Divider()
                    HStack {
                        Button("Cancel") {
                            isPresented = false
                        }
                        Spacer()
                        Button("Save") {
                            if let original = jobStore.selectedJobIDs.first,
                               let origJob = jobStore.jobApplications.first(where: { $0.id == original }) {
                                viewModel.updateJob(with: origJob, in: jobStore, documents: importedDocuments)
                                isPresented = false
                            } else {
                                isPresented = false
                            }
                        }
                        .disabled(!viewModel.isInputValid)
                    }
                    .padding(.bottom, 20)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showNewLocationWindow) {
            NewLocationWindowView(
                locations: $locations,
                selectedLocation: $viewModel.location
            )
        }
        .frame(minWidth: 450, minHeight: 600)
        .onAppear {
            viewModel.updateSkillSuggestions(availableSkills: jobStore.availableSkills)
        }
    }
}
// --------------------------------------------------
// MARK: - EnhancedStatsView
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
               PieChartsSectionView               // For brevity, the PieChartsSectionView remains. We won't remove it, though not asked to update it.
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

// Views/JobDetailView.swift

import SwiftUI
import PDFKit
import MarkdownKit

struct JobDetailView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    let job: JobApplication

    @State private var windowRef: NSWindow?
    @State private var quickLookURL: URL? = nil
    let markdownParser = MarkdownParser()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(job.companyName)
                    .font(.largeTitle)
                    .bold()
                Text(job.jobTitle)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Status:")
                            .frame(width: 100, alignment: .leading)
                        Text(job.status.rawValue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(job.status.displayColor.opacity(0.2)))
                            .foregroundColor(job.status.displayColor)
                    }
                    HStack {
                        Text("URL:")
                            .frame(width: 100, alignment: .leading)
                        if let link = job.linkToJobString, let url = URL(string: link) {
                            Link("View Job Posting", destination: url)
                        } else {
                            Text("No job link available").foregroundColor(.secondary)
                        }
                    }
                    HStack {
                        Text("Location:")
                            .frame(width: 100, alignment: .leading)
                        if !job.location.isEmpty {
                            Text(job.location)
                        } else {
                            Text("No location specified").foregroundColor(.secondary)
                        }
                    }
                    HStack {
                        Text("Applied on:")
                            .frame(width: 100, alignment: .leading)
                        Text(job.dateOfApplication.formatted(date: .abbreviated, time: .omitted))
                    }
                }
                .foregroundColor(colorScheme == .dark ? .white : .primary)

                if let dl = job.jobDeadline {
                    Text("Application Deadline: \(dl.formatted(date: .abbreviated, time: .omitted))")
                        .font(.headline)
                        .foregroundColor(.red)
                }

                if let salary = job.salary {
                    let sInt = Int(salary)
                    Text("Salary: \(sInt.formatted(.currency(code: "USD"))) per year")
                        .font(.headline)
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
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                }

                if !job.coverLetter.isEmpty {
                    Divider()
                    Text("Cover Letter").font(.headline)
                    Text(job.coverLetter)
                }

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
// Views/DocumentsViews.swift

import SwiftUI
import PDFKit

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
// Views/NewLocationViews.swift

import SwiftUI

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
                .modifier(TranslucentGradientBackground())
                .overlay(RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(Color.gray.opacity(0.5), lineWidth: 1))
            TextField("Latitude", text: $latitude)
                .modifier(TranslucentGradientBackground())
                .overlay(RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(Color.gray.opacity(0.5), lineWidth: 1))
            TextField("Longitude", text: $longitude)
                .modifier(TranslucentGradientBackground())
                .overlay(RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(Color.gray.opacity(0.5), lineWidth: 1))
            Button("Add Location") {
                if !newLocationName.isEmpty {
                    locations.append(newLocationName)
                    selectedLocation = newLocationName
                    isPresented = false
                }
            }
            .padding(.top, 10)
            Spacer()
        }
        .padding()
    }
}
// Views/SkillViews.swift

import SwiftUI

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
// Views/CustomModifiers.swift

import SwiftUI

struct UltraThinMaterialTextEditorStyle: ViewModifier {
    func body(content: Content) -> some View {
         content
             .padding(8)
             .background(.ultraThinMaterial.opacity(0.25))
             .cornerRadius(10)
             .font(.system(size: 13))
             .foregroundColor(.primary)
    }
}

struct TranslucentGradientBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(6)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.25),
                        Color.gray.opacity(0.25)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(5)
    }
}
