
```swift
// AppleJobApp.swift
// AppleJobApp
// Created by Your Name on Date

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
        self.fileData = fileData
        self.fileURL = fileURL
        self.creationDate = creation
        self.lastModifiedDate = lastModified
        self.fileSize = fileSize ?? fileData.count
        self.wordCount = wordCount ?? 0
        self.categoryID = categoryID
    }
}

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

// MARK: - Additional Models for Charts

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
//
//  JobViewModel.swift
//  AppleJobApp
//
//  Created by Your Name on Date
//

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
    var detectedSalary: String? // NEW: Detected Salary
}

/// View model used for AddJobView and EditJobView.
class JobViewModel: ObservableObject {
    @Published var companyName: String = ""
    @Published var jobTitle: String = ""
    @Published var status: JobStatus = .applied // Updated default to Applied
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
    @Published var jobType: JobType = .fullTime // Updated default to Full Time
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
            self.salaryString = formatter.string(from: NSNumber(value: salary)) ?? ""
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

    func addJob(to store: JobStore, documents: [JobDocument], isPresented: Binding<Bool>) { // Added Binding<Bool> isPresented
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
        isPresented.wrappedValue = false // Dismiss the view
    }

    func updateJob(with originalJob: JobApplication, in store: JobStore, documents: [JobDocument], isPresented: Binding<Bool>) { // Added Binding<Bool> isPresented
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
        isPresented.wrappedValue = false // Dismiss the view
    }

    func reset() {
        companyName = ""
        jobTitle = ""
        status = .applied // Default to Applied
        dateOfApplication = Date()
        location = ""
        linkToJob = ""
        jobDescription = ""
        coverLetter = ""
        notes = ""
        salaryString = ""
        jobType = .fullTime // Default to Full Time
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
        if salaryString.isEmpty, let salary = parseResult.detectedSalary { // NEW: Parse Salary
            salaryString = salary
            salaryDouble = parseSalary(salary)
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
                detectedURL: nil,
                detectedSalary: nil // NEW: detectedSalary
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
        var detectedSalary: String? = nil // NEW: detectedSalary

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
            // NEW: Detect Salary
            if detectedSalary == nil, lowerLine.starts(with: "salary:") {
                if let range = line.range(of: "salary:", options: .caseInsensitive) {
                    let value = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
                    detectedSalary = value.isEmpty ? nil : value
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

        // Clean detected desired skills: remove "Desired Skills:" prefix
        if let skills = detectedDesiredSkills {
            detectedDesiredSkills = skills
                .replacingOccurrences(of: "Desired Skills: ", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespaces)
        }

        let sanitized = cleanedLines.joined(separator: "\n")

        return ParsedJobDescriptionResult(
            sanitizedText: sanitized,
            detectedJobTitle: detectedJobTitle,
            detectedCompanyName: detectedCompanyName,
            detectedLocation: detectedLocation,
            detectedDesiredSkills: detectedDesiredSkills,
            detectedURL: detectedURL,
            detectedSalary: detectedSalary // NEW: detectedSalary
        )
    }
}
// Stores/JobStore.swift
//
//  JobStore.swift
//  AppleJobApp
//
//  Created by Your Name on Date
//
//
//  JobStore.swift
//  AppleJobApp
//
//  Created by Your Name on Date
//
//
//  JobStore.swift
//  AppleJobApp
//
//  Created by Your Name on Date
//

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
        // On init, load from UserDefaults (restoring the old fallback approach).
        loadJobs()
        loadSkills()
    }

    // MARK: - Add Job
    func addJob(_ job: JobApplication) {
        // Sort + parse + save on background thread to avoid blocking the main UI.
        DispatchQueue.global(qos: .userInitiated).async { [self] in

            // 1) Insert new job and sort in background
            let sortedJobs = (self.jobApplications + [job])
                .sorted(by: self.sortingComparator(for: self.sorting))

            // 2) Update the @Published property on the main thread
            DispatchQueue.main.async {
                self.jobApplications = sortedJobs
            }

            // 3) Save + parse in the background
            self.saveJobs()
            self.parseJobDescriptionsForAllSkills()
        }
    }

    // MARK: - Edit Job
    func editJob(with updatedJob: JobApplication) {
        if let index = jobApplications.firstIndex(where: { $0.id == updatedJob.id }) {
            jobApplications[index] = updatedJob
            // Keep or update the sorting approach
            sortJobs(by: sorting)
            saveJobs()
            parseJobDescriptionsForAllSkills()
        }
    }

    // MARK: - Delete Job
    func deleteJob(for id: UUID) {
        if let index = jobApplications.firstIndex(where: { $0.id == id }) {
            jobApplications.remove(at: index)
            selectedJobIDs.remove(id)
            saveJobs()
        }
    }

    // MARK: - Duplicate Job
    func duplicateJob(_ job: JobApplication) {
        let newJob = JobApplication(
            companyName: job.companyName,
            jobTitle: job.jobTitle,
            status: job.status,
            dateOfApplication: Date(), // Make the new copy have "today's" date
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

    // MARK: - Update Status
    func updateJobStatus(_ ids: Set<UUID>, to status: JobStatus) {
        for id in ids {
            if let index = jobApplications.firstIndex(where: { $0.id == id }) {
                jobApplications[index].status = status
            }
        }
        saveJobs()
    }

    // MARK: - Update Job Type
    func updateJobType(_ ids: Set<UUID>, to jobType: JobType) {
        for id in ids {
            if let index = jobApplications.firstIndex(where: { $0.id == id }) {
                jobApplications[index].jobType = jobType
            }
        }
        saveJobs()
    }

    // MARK: - Toggle Favorite
    func toggleFavorite(for id: UUID) {
        if let index = jobApplications.firstIndex(where: { $0.id == id }) {
            jobApplications[index].isFavorite.toggle()
            saveJobs()
        }
    }

    // MARK: - Sorting
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

    /// Returns a comparator for background sorting
    private func sortingComparator(for sort: Sort)
        -> (JobApplication, JobApplication) -> Bool
    {
        switch sort {
        case .title:
            return { $0.jobTitle.lowercased() < $1.jobTitle.lowercased() }
        case .company:
            return { $0.companyName.lowercased() < $1.companyName.lowercased() }
        case .recentlyApplied:
            return { $0.dateOfApplication > $1.dateOfApplication }
        }
    }

    // MARK: - Save & Load Jobs
    func saveJobs() {
        // Convert each JobApplication to a dictionary
        let jobsArray = jobApplications.map { $0.toDictionary() }

        DispatchQueue.global(qos: .utility).async {
            // Store them as JSON text in UserDefaults
            if let jsonData = try? JSONSerialization.data(withJSONObject: jobsArray, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                UserDefaults.standard.set(jsonString, forKey: "jobs")
            }
        }
    }

    /// **Important**: Hybrid loading approach:
    ///  1) Try decoding `[JobApplication]` using `JSONDecoder` (the old format).
    ///  2) If that fails, read as a JSON string of dictionaries (the dictionary-based format).
    func loadJobs() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // 1) First, see if there's raw `Data` that can decode as [JobApplication] via JSONDecoder
            if let savedData = UserDefaults.standard.data(forKey: "jobs"),
               let loadedByDecoder = try? JSONDecoder().decode([JobApplication].self, from: savedData)
            {
                // Successfully decoded the older "array" format
                let sortedDecoded = loadedByDecoder
                    .sorted(by: self.sortingComparator(for: self.sorting))

                DispatchQueue.main.async {
                    self.jobApplications = sortedDecoded
                    // Also parse skill references, if needed
                    self.parseJobDescriptionsForAllSkills()
                }
                return
            }

            // 2) Otherwise, try the dictionary-based JSON string
            guard let jsonString = UserDefaults.standard.string(forKey: "jobs"),
                  let jsonData = jsonString.data(using: .utf8),
                  let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
                  let jobsArray = jsonObject as? [[String: Any]]
            else {
                // No data found
                return
            }

            // Convert each dictionary to a JobApplication
            var loadedJobs: [JobApplication] = []
            for dict in jobsArray {
                if let job = JobApplication.fromDictionary(dict) {
                    loadedJobs.append(job)
                }
            }

            let sortedList = loadedJobs
                .sorted(by: self.sortingComparator(for: self.sorting))

            DispatchQueue.main.async {
                self.jobApplications = sortedList
                self.parseJobDescriptionsForAllSkills()
            }
        }
    }

    // MARK: - Import / Export Backup
    func importBackup(url: URL) {
        do {
            let jsonString = try String(contentsOf: url, encoding: .utf8)
            if let jsonData = jsonString.data(using: .utf8),
               let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
               let jobsArray = jsonObject as? [[String: Any]]
            {
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
                print("Exported backup to: \(url.lastPathComponent)")
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
        DispatchQueue.global(qos: .utility).async {
            if let jsonData = try? JSONSerialization.data(withJSONObject: skillsArray, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                UserDefaults.standard.set(jsonString, forKey: "desiredSkills")
            }
        }
    }

    func loadSkills() {
        // Also maintain fallback for skills if you used old direct-coded approach:
        if let savedData = UserDefaults.standard.data(forKey: "desiredSkills"),
           let loadedByDecoder = try? JSONDecoder().decode([DesiredSkill].self, from: savedData)
        {
            availableSkills = loadedByDecoder
            return
        }

        // Otherwise parse dictionary-based
        guard let jsonString = UserDefaults.standard.string(forKey: "desiredSkills"),
              let data = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let skillsArray = jsonObject as? [[String: Any]]
        else { return }

        var loaded: [DesiredSkill] = []
        for dict in skillsArray {
            if let skill = DesiredSkill.fromDictionary(dict) {
                loaded.append(skill)
            }
        }
        availableSkills = loaded
    }

    // MARK: - Parsing Skills in Job Descriptions
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

//
//  DocumentStore.swift
//  AppleJobApp
//
//  Created by Your Name on Date
//

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

    // MARK: - Upload Documents
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

    // MARK: - Download Document
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

    // MARK: - Duplicate Document
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

    // MARK: - Delete Document
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

    // MARK: - Merge Documents
    func mergeDocuments(_ newDocs: [JobDocument]) {
        for doc in newDocs {
            if !documents.contains(doc) {
                documents.append(doc)
            }
        }
        saveDocuments()
    }

    // MARK: - Save & Load Documents (Dictionary-based JSON)
    func saveDocuments() {
        // Convert each document to a dictionary, then store in UserDefaults
        let docsArray = documents.map { $0.toDictionary() }
        if let jsonData = try? JSONSerialization.data(withJSONObject: docsArray, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            UserDefaults.standard.set(jsonString, forKey: "documents")
        }
    }

    func loadDocuments() {
        // Attempt to load using JSONDecoder
        if let savedData = UserDefaults.standard.data(forKey: "documents"),
           let decodedDocs = try? JSONDecoder().decode([JobDocument].self, from: savedData) {
            self.documents = decodedDocs
            return
        }

        // Fallback: load dictionary-based JSON string
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
    // MARK: - Categories
    func saveCategories() {
        let catsArray: [[String: Any]] = categories.map { cat in
            [
                "id": cat.id.uuidString,
                "name": cat.name,
                "isExpanded": cat.isExpanded
            ]
        }
        if let jsonData = try? JSONSerialization.data(withJSONObject: catsArray, options: []),
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
               let isExpanded = dict["isExpanded"] as? Bool
            {
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

    // MARK: - Editing Metadata
    func beginEditMetadata(for doc: JobDocument) {
        self.documentToEdit = doc
        self.isEditingMetadata = true
    }

    // MARK: - Utility: Save to App Support
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
import AppKit

struct AddJobWindowView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore

    var body: some View {
        AddJobView(isPresented: .constant(true)) // isPresented is now true by default for window
            .environmentObject(jobStore)
            .environmentObject(docStore)
            .frame(minWidth: 450, minHeight: 600)
            .onDisappear {
                jobStore.isAddingNewJob = false
            }
    }
}
import SwiftUI
import AppKit

struct AddJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var isPresented: Bool

    @StateObject private var viewModel: JobViewModel = JobViewModel()
    @State private var importedDocuments: [JobDocument] = []
    @State private var locations: [String] = Array(CityCoordinateDictionary.keys).sorted()
    @State private var showNewLocationWindow = false
    @State private var selectedCoverLetterURL: URL?
    @State private var isImportingDocuments = false // For document import sheet

    var body: some View {
        VStack(spacing: 12) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add New Job")
                        .font(.title2)
                        .padding(.top)

                    Group {
                        TextField("Company Name", text: $viewModel.companyName, prompt: Text("Enter company name"))
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: viewModel.companyName) { _, _ in viewModel.validateInputs() }

                        TextField("Job Title", text: $viewModel.jobTitle, prompt: Text("Enter job title"))
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: viewModel.jobTitle) { _, _ in viewModel.validateInputs() }
                    }

                    Group {
                        Text("Status & Type").font(.headline)

                        Picker("Status", selection: $viewModel.status) {
                            ForEach(JobStatus.allCases, id: \.self) { st in
                                Text(st.rawValue).tag(st)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("Job Type", selection: $viewModel.jobType) {
                            ForEach(JobType.allCases, id: \.self) { jt in
                                Text(jt.rawValue).tag(jt)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Group {
                        Text("Application Details").font(.headline)

                        DatePicker("Date of Application", selection: $viewModel.dateOfApplication, displayedComponents: .date)

                        Picker("Select Location", selection: $viewModel.location) {
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
                        Text("Salary & Link").font(.headline)

                        TextField("Enter salary", text: $viewModel.salaryString)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: viewModel.salaryString) { _, v in viewModel.updateSalary(fromString: v) }

                        TextField("Enter job link", text: $viewModel.linkToJob)
                            .textFieldStyle(.roundedBorder)
                    }

                    Group {
                        Text("Job Description").font(.headline)

                        HStack {
                            Button("Paste") {
                                if let clip = NSPasteboard.general.string(forType: .string) {
                                    viewModel.jobDescription = clip
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                            Spacer()
                        }

                        TextEditor(text: $viewModel.jobDescription)
                            .frame(height: 120)
                            .padding(6)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Group {
                        Text("Notes").font(.headline)
                        TextEditor(text: $viewModel.notes)
                            .frame(height: 80)
                            .padding(6)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    // NEW: Upload Documents Section
                    Group {
                        Text("Upload Documents").font(.headline)
                        Button("Import Documents") {
                            isImportingDocuments = true
                        }
                        .buttonStyle(.borderedProminent)
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(importedDocuments, id: \.id) { doc in
                                    Text(doc.fileName)
                                        .padding(5)
                                        .background(Color.gray.opacity(0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                }
                            }
                        }
                    }

                    Group {
                        Text("Upload Cover Letter").font(.headline)

                        HStack {
                            Button(action: uploadCoverLetter) {
                                Label("Upload PDF", systemImage: "doc.badge.plus")
                            }
                            .buttonStyle(.borderedProminent)

                            if let selectedCoverLetterURL = selectedCoverLetterURL {
                                Text(selectedCoverLetterURL.lastPathComponent)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Group {
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
                }
                .padding()
            }

            Divider()

            HStack {
                Button("Cancel") { // Updated Cancel Button Action
                    isPresented = false
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Add Job") {
                    if viewModel.isInputValid {
                        viewModel.addJob(to: jobStore, documents: importedDocuments, isPresented: $isPresented) // Pass Binding<Bool> isPresented
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.isInputValid)
            }
            .padding()
        }
        .frame(minWidth: 450, minHeight: 500)
        .sheet(isPresented: $showNewLocationWindow) {
            NewLocationWindowView(
                locations: $locations,
                selectedLocation: $viewModel.location
            )
        }
        .fileImporter( // Document import sheet
            isPresented: $isImportingDocuments,
            allowedContentTypes: [.pdf, .image, .plainText, .rtf],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    do {
                        let data = try Data(contentsOf: url)
                        let doc = JobDocument(fileName: url.lastPathComponent, fileData: data)
                        importedDocuments.append(doc)
                    } catch {
                        print("Error importing document: \(error)")
                    }
                }
            case .failure(let error):
                print("Document import failed: \(error)")
            }
        }
        .onAppear {
            viewModel.updateSkillSuggestions(availableSkills: jobStore.availableSkills)
        }
    }


    // MARK: - Upload Cover Letter Function
    private func uploadCoverLetter() {
        let openPanel = NSOpenPanel()
            openPanel.title = "Select Cover Letter PDF"
            openPanel.allowedContentTypes = [.pdf]
            openPanel.allowsMultipleSelection = false
            openPanel.canChooseFiles = true
            openPanel.canChooseDirectories = false

        if openPanel.runModal() == .OK {
            selectedCoverLetterURL = openPanel.urls.first
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
        EditJobView(isPresented: .constant(true), job: job) // isPresented is now true by default for window
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
    @Binding var isPresented: Binding<Bool> // Changed to Binding<Bool>

    @StateObject var viewModel: JobViewModel
    @State private var importedDocuments: [JobDocument] = []
    @State private var locations: [String] = Array(CityCoordinateDictionary.keys).sorted()

    @State private var showNewLocationWindow = false
    @State private var isImportingDocuments = false // For document import sheet

    init(isPresented: Binding<Bool>, job: JobApplication) {
        self._isPresented = isPresented
        let vm = JobViewModel(job: job, availableSkills: [])
        _viewModel = StateObject(wrappedValue: vm)
        _importedDocuments = State(initialValue: job.documents) // Initialize importedDocuments with existing job documents
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

                        // NEW: Upload Documents Section in Edit View
                        Group {
                            Text("Upload Documents").font(.headline)
                            Button("Import Documents") {
                                isImportingDocuments = true
                            }
                            .buttonStyle(.borderedProminent)
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(importedDocuments, id: \.id) { doc in
                                        Text(doc.fileName)
                                            .padding(5)
                                            .background(Color.gray.opacity(0.2))
                                            .clipShape(RoundedRectangle(cornerRadius: 5))
                                    }
                                }
                            }
                        }

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
                        Button("Cancel") { // Updated Cancel Button Action
                            isPresented.wrappedValue = false
                        }
                        Spacer()
                        Button("Save") {
                            if let original = jobStore.selectedJobIDs.first,
                               let origJob = jobStore.jobApplications.first(where: { $0.id == original }) {
                                viewModel.updateJob(with: origJob, in: jobStore, documents: importedDocuments, isPresented: $isPresented) // Pass Binding<Bool> isPresented
                            } else {
                                isPresented.wrappedValue = false
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
        .fileImporter( // Document import sheet
            isPresented: $isImportingDocuments,
            allowedContentTypes: [.pdf, .image, .plainText, .rtf],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    do {
                        let data = try Data(contentsOf: url)
                        let doc = JobDocument(fileName: url.lastPathComponent, fileData: data)
                        importedDocuments.append(doc)
                    } catch {
                        print("Error importing document: \(error)")
                    }
                }
            case .failure(let error):
                print("Document import failed: \(error)")
            }
        }
        .frame(minWidth: 450, minHeight: 600)
        .onAppear {
            viewModel.updateSkillSuggestions(availableSkills: jobStore.availableSkills)
        }
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
// ======================================================
// MARK: - UltraThinMaterialTextEditorStyle Modifier
// ======================================================
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
```
