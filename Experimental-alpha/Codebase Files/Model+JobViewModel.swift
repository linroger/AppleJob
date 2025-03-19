// -----------------------------------------------------------------------------
// MARK: - Model+JobViewModel
// -----------------------------------------------------------------------------
//
//  AppleJob.swift
//  Complete Single-File Codebase with All Sections
//
// Now includes LinkedIn Insights parser and visualization functionality
//
//  NOTE: This file reflects the complete codebase with requested modifications:
//
//    1) Removed **Tailor Resume/Cover Letter & AI Features** as requested by the user.
//       - Removed all references to `tailoredResume`, `tailoredCoverLetter`, `AIService`, `modelcontext`.
//       - Deleted `ResumeEditorView` and `Resume` model files.
//       - Removed AI-related settings from `SettingsView`.
//       - Updated `JobStore` to remove AI processing functions and states.
//       - Corrected errors resulting from these removals throughout the codebase.
//
//  All other code remains intact or only minimally changed to accommodate these updates.
//
// -----------------------------------------------------------------------------
// MARK: - Imports
// -----------------------------------------------------------------------------

import SwiftUI
import AppKit
import UniformTypeIdentifiers
import PDFKit
import MapKit
import Charts
import Quartz
import QuickLook
import QuickLookUI
import MarkdownUI  // Replacing MarkdownKit with MarkdownUI
import SwiftData
import SwiftSoup  // For LinkedIn HTML parsing
import WebKit     // For WebView to automate LinkedIn access

// MARK: - Custom Shapes
struct Square: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        return path
    }
}

// MARK: - SwiftData Models
// MARK: - SwiftData Models

@Model
class SwiftDataJobApplication {
    var id: UUID
    var companyName: String
    var jobTitle: String
    var status: JobStatus
    var dateOfApplication: Date
    var location: String
    var linkToJobString: String?
    var salaryString: String?
    var salaryMin: Double?
    var salaryMax: Double?
    var jobDescription: String
    var coverLetter: String
    var notes: String?
    var isFavorite: Bool
    var documentsList: [JobDocument]
    var jobType: JobType
    var desiredSkillNames: [String]
    var jobDeadline: Date?
    var linkedInInsightsData: Data?
    var crossJobSkillNames: [String]
    @Relationship(deleteRule: .cascade) var documents: [SwiftDataJobDocument]

    // NEW FIELD FOR LINKEDIN INSIGHTS

    init(
        id: UUID = UUID(),
             companyName: String,
             jobTitle: String,
             status: JobStatus = .interested,
             dateOfApplication: Date = Date(),
             location: String,
             linkToJobString: String? = nil,
             salaryString: String? = nil,
             salaryMin: Double? = nil,
             salaryMax: Double? = nil,
             jobDescription: String = "",
             coverLetter: String = "",
             notes: String? = nil,
             documents: [JobDocument] = [],
             isFavorite: Bool = false,
             jobType: JobType = .none,
             desiredSkillNames: [String] = [],
             jobDeadline: Date? = nil,
             linkedInInsightsData: Data? = nil,
             crossJobSkillNames: [String] = []
    ) {
        self.id = id
              self.companyName = companyName
              self.jobTitle = jobTitle
              self.status = status
              self.dateOfApplication = dateOfApplication
              self.location = location
              self.linkToJobString = linkToJobString
              self.salaryString = salaryString
              self.salaryMin = salaryMin
              self.salaryMax = salaryMax
              self.jobDescription = jobDescription
              self.coverLetter = coverLetter
              self.notes = notes
              self.documentsList = documents
              self.documents = []
              self.isFavorite = isFavorite
              self.jobType = jobType
              self.desiredSkillNames = desiredSkillNames
              self.jobDeadline = jobDeadline
              self.linkedInInsightsData = linkedInInsightsData
              self.crossJobSkillNames = crossJobSkillNames
    }

    func toJobApplication() -> JobApplication {
        // Decode LinkedInInsightsData if present
        var linkedInData: LinkedInInsightsData? = nil
        if let insightsData = linkedInInsightsData {
            linkedInData = try? JSONDecoder().decode(LinkedInInsightsData.self, from: insightsData)
        }

        return JobApplication(
            id: id,
            companyName: companyName,
            jobTitle: jobTitle,
            status: status,
            dateOfApplication: dateOfApplication,
            location: location,
            linkToJobString: linkToJobString,
            salaryString: salaryString,
            salaryMin: salaryMin,
            salaryMax: salaryMax,
            jobDescription: jobDescription,
            coverLetter: coverLetter,
            notes: notes,
            documents: SwiftDataJobDocument.toJobDocuments(from: documents),
            isFavorite: isFavorite,
            jobType: jobType,
            desiredSkillNames: desiredSkillNames,
            jobDeadline: jobDeadline,
            linkedInInsightsData: linkedInData,
            crossJobSkillNames: crossJobSkillNames
        )
    }
}

@Model
class SwiftDataJobDocument {
    var id: UUID
    var fileName: String
    var fileURL: URL?
    var fileData: Data
    var creationDate: Date
    var lastModifiedDate: Date
    var fileSize: Int
    var wordCount: Int
    var categoryID: UUID?
    var associatedCompany: String?
    var associatedJobTitle: String?
    var associatedApplicationDate: Date?
    
    // Helper function to convert array of SwiftDataJobDocument to array of JobDocument
    static func toJobDocuments(from swiftDataDocs: [SwiftDataJobDocument]) -> [JobDocument] {
        return swiftDataDocs.map { doc in
            JobDocument(
                id: doc.id,
                fileName: doc.fileName,
                fileData: doc.fileData,
                fileURL: doc.fileURL,
                creation: doc.creationDate,
                lastModified: doc.lastModifiedDate,
                fileSize: doc.fileSize,
                wordCount: doc.wordCount,
                categoryID: doc.categoryID,
                associatedCompany: doc.associatedCompany,
                associatedJobTitle: doc.associatedJobTitle,
                associatedApplicationDate: doc.associatedApplicationDate
            )
        }
    }

    init(
        id: UUID = UUID(),
        fileName: String,
        fileData: Data,
        fileURL: URL? = nil,
        creation: Date = Date(),
        lastModified: Date = Date(),
        fileSize: Int? = nil,
        wordCount: Int? = nil,
        categoryID: UUID? = nil,
        associatedCompany: String? = nil,
        associatedJobTitle: String? = nil,
        associatedApplicationDate: Date? = nil
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
        self.associatedCompany = associatedCompany
        self.associatedJobTitle = associatedJobTitle
        self.associatedApplicationDate = associatedApplicationDate
    }

    func toJobDocument() -> JobDocument {
        JobDocument(
            id: id,
            fileName: fileName,
            fileData: fileData,
            fileURL: fileURL,
            creation: creationDate,
            lastModified: lastModifiedDate,
            fileSize: fileSize,
            wordCount: wordCount,
            categoryID: categoryID,
            associatedCompany: associatedCompany,
            associatedJobTitle: associatedJobTitle,
            associatedApplicationDate: associatedApplicationDate
        )
    }
}



// --------------------------------------------------
// MARK: - Constants
// --------------------------------------------------
struct Constants {
    static let jobsKey = "jobs"
    static let skillsKey = "desiredSkills"
    static let documentsKey = "documents"
    static let documentCategoriesKey = "documentCategories"
}

// --------------------------------------------------
// MARK: - Protocol: CaseNameDisplayable
// --------------------------------------------------
protocol CaseNameDisplayable: RawRepresentable, CaseIterable where RawValue == String, AllCases: Collection {
    func caseNameForDisplay() -> String
}
extension CaseNameDisplayable {
    func caseNameForDisplay() -> String {
        return self.rawValue
    }
}

// --------------------------------------------------
// MARK: - Enums: JobType, JobStatus, Sort, ViewSection
// --------------------------------------------------
enum JobType: String, CaseIterable, Codable, CaseNameDisplayable {
    case internship = "Internship"
    case fullTime = "Full Time"
    case offCycleInternship = "Off-Cycle Internship"
    case none = "None" // Default if no type is selected
}

enum JobStatus: String, CaseIterable, Codable, CaseNameDisplayable {
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

enum Sort: String, CaseIterable, CaseNameDisplayable {
    case title = "Job Title"
    case company = "Company Name"
    case recentlyApplied = "Recently Applied"
}

enum ViewSection: String, CaseIterable, CaseNameDisplayable, Hashable, Identifiable {
    case jobDetails = "Job Details"
    case stats = "Stats"
    case documents = "Documents"
    case notes = "Notes"
    
    var id: String { self.rawValue }
}

// --------------------------------------------------
// MARK: - Model: DesiredSkill
// --------------------------------------------------
struct DesiredSkill: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var aliases: [String]

    init(id: UUID = UUID(), name: String, aliases: [String] = []) {
        self.id = id
        self.name = name
        self.aliases = aliases
    }

    func toDictionary() -> [String: Any] {
        return [
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

// --------------------------------------------------
// MARK: - Model: JobDocument
// --------------------------------------------------
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

    // Additional metadata fields to store job context:
    var associatedCompany: String?
    var associatedJobTitle: String?
    var associatedApplicationDate: Date?
    
    // No helper function here to avoid circular dependencies

    init(
        id: UUID = UUID(),
        fileName: String,
        fileData: Data,
        fileURL: URL? = nil,
        creation: Date = Date(),
        lastModified: Date = Date(),
        fileSize: Int? = nil,
        wordCount: Int? = nil,
        categoryID: UUID? = nil,
        associatedCompany: String? = nil,
        associatedJobTitle: String? = nil,
        associatedApplicationDate: Date? = nil
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
        self.associatedCompany = associatedCompany
        self.associatedJobTitle = associatedJobTitle
        self.associatedApplicationDate = associatedApplicationDate
    }

    // Dictionary-based backups
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
        if let associatedCompany = associatedCompany {
            dict["associatedCompany"] = associatedCompany
        }
        if let associatedJobTitle = associatedJobTitle {
            dict["associatedJobTitle"] = associatedJobTitle
        }
        if let associatedApplicationDate = associatedApplicationDate {
            dict["associatedApplicationDate"] = isoFormatter.string(from: associatedApplicationDate)
        }
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
            if let urlStr = dict["fileURL"] as? String {
                return URL(string: urlStr)
            }
            return nil
        }()
        let categoryID: UUID? = {
            if let catIDStr = dict["categoryID"] as? String {
                return UUID(uuidString: catIDStr)
            }
            return nil
        }()

        let associatedCompany = dict["associatedCompany"] as? String
        let associatedJobTitle = dict["associatedJobTitle"] as? String
        var associatedApplicationDate: Date? = nil
        if let appDateStr = dict["associatedApplicationDate"] as? String {
            associatedApplicationDate = isoFormatter.date(from: appDateStr)
        }

        return JobDocument(
            id: id,
            fileName: fileName,
            fileData: fileData,
            fileURL: fileURL,
            creation: creationDate,
            lastModified: lastModifiedDate,
            fileSize: fileSize,
            wordCount: wordCount,
            categoryID: categoryID,
            associatedCompany: associatedCompany,
            associatedJobTitle: associatedJobTitle,
            associatedApplicationDate: associatedApplicationDate
        )
    }
}

// --------------------------------------------------
// MARK: - Model: DocumentCategory
// --------------------------------------------------
struct DocumentCategory: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var isExpanded: Bool = true

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

// --------------------------------------------------
// MARK: - Model: JobApplication
// --------------------------------------------------
struct JobApplication: Codable, Identifiable, Hashable {
    var id: UUID
    var companyName: String
    var jobTitle: String
    var status: JobStatus
    var dateOfApplication: Date
    var location: String
    var linkToJobString: String?
    // If the user enters a single salary or a range, we store the raw text in `salaryString`
    // and optionally parse out min/max if there's a dash.
    var salaryString: String?
    var salaryMin: Double?
    var salaryMax: Double?

    var jobDescription: String
    var coverLetter: String
    var notes: String?
    var isFavorite: Bool
    var documents: [JobDocument]
    var jobType: JobType
    var desiredSkillNames: [String]
    var jobDeadline: Date?
    var linkedInInsightsData: LinkedInInsightsData?
    
    // Skills auto-added from older logic; we’re no longer updating these for new jobs,
    // but we keep them so existing cross-job references remain visible.
    var crossJobSkillNames: [String]

    init(
        id: UUID = UUID(),
        companyName: String,
        jobTitle: String,
        status: JobStatus = .interested,
        dateOfApplication: Date = Date(),
        location: String,
        linkToJobString: String? = nil,
        salaryString: String? = nil,
        salaryMin: Double? = nil,
        salaryMax: Double? = nil,
        jobDescription: String = "",
        coverLetter: String = "",
        notes: String? = nil,
        documents: [JobDocument] = [],
        isFavorite: Bool = false,
        jobType: JobType = .none,
        desiredSkillNames: [String] = [],
        jobDeadline: Date? = nil,
        linkedInInsightsData: LinkedInInsightsData? = nil,
        crossJobSkillNames: [String] = []
    ) {
        self.id = id
        self.companyName = companyName
        self.jobTitle = jobTitle
        self.status = status
        self.dateOfApplication = dateOfApplication
        self.location = location
        self.linkToJobString = linkToJobString
        self.salaryString = salaryString
        self.salaryMin = salaryMin
        self.salaryMax = salaryMax
        self.jobDescription = jobDescription
        self.coverLetter = coverLetter
        self.notes = notes
        self.documents = documents
        self.isFavorite = isFavorite
        self.jobType = jobType
        self.desiredSkillNames = desiredSkillNames
        self.jobDeadline = jobDeadline
        self.linkedInInsightsData = linkedInInsightsData
        self.crossJobSkillNames = crossJobSkillNames
    }

    // Custom Key
    enum CodingKeys: String, CodingKey {
        case id
        case companyName
        case jobTitle
        case status
        case dateOfApplication
        case location
        case linkToJobString
        case salaryString
        case salaryMin
        case salaryMax
        case jobDescription
        case coverLetter
        case notes
        case isFavorite
        case documents
        case jobType
        case desiredSkillNames
        case jobDeadline
        case crossJobSkillNames
    }

    // Basic dictionary approach for backups
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
            "documents": documents.map { $0.toDictionary() },
            "crossJobSkillNames": crossJobSkillNames
        ]
        if let link = linkToJobString { dict["linkToJobString"] = link }
        if let salStr = salaryString { dict["salaryString"] = salStr }
        if let sMin = salaryMin { dict["salaryMin"] = sMin }
        if let sMax = salaryMax { dict["salaryMax"] = sMax }
        if let notes = notes { dict["notes"] = notes }
        if let deadline = jobDeadline { dict["jobDeadline"] = isoFormatter.string(from: deadline) }
        return dict
    }

    static func fromDictionary(_ dict: [String: Any]) -> JobApplication? {
        let isoFormatter = ISO8601DateFormatter()
        guard
            let idStr = dict["id"] as? String,
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
        else {
            return nil
        }
        let linkToJobString = dict["linkToJobString"] as? String
        let salaryString = dict["salaryString"] as? String
        let salaryMin = dict["salaryMin"] as? Double
        let salaryMax = dict["salaryMax"] as? Double
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

        let crossSkillNames = dict["crossJobSkillNames"] as? [String] ?? []

        return JobApplication(
            id: id,
            companyName: companyName,
            jobTitle: jobTitle,
            status: status,
            dateOfApplication: dateOfApplication,
            location: location,
            linkToJobString: linkToJobString,
            salaryString: salaryString,
            salaryMin: salaryMin,
            salaryMax: salaryMax,
            jobDescription: jobDescription,
            coverLetter: coverLetter,
            notes: notes,
            documents: documents,
            isFavorite: isFavorite,
            jobType: jobType,
            desiredSkillNames: desiredSkillNames,
            jobDeadline: jobDeadline,
            crossJobSkillNames: crossSkillNames
        )
    }

    static func == (lhs: JobApplication, rhs: JobApplication) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// --------------------------------------------------
// MARK: - Helper Data Structures for Charts
// --------------------------------------------------
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

// MARK: - LinkedIn Insights Data Structures

// MARK: - LinkedIn Insights Data Structures

struct EmployeeGrowth: Identifiable, Codable {
    var id = UUID()
    let dayOfWeek: String
    let month: String
    let day: String
    let time: String
    let employeeCount: Int
    let growth: String
    var year: Int?

    var date: Date? {
        guard let year = year else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d yyyy"
        return dateFormatter.date(from: "\(month) \(day) \(year)")
    }
}

typealias FunctionDistribution = [String: String]

struct HeadcountGrowth: Identifiable, Codable {
    var id = UUID()
    let function: String
    let numEmployees: String
    let percentage: String
    let growth6m: String
    let growth1y: String
    let added6m: Int?
    let added1y: Int?
}

struct NewHire: Identifiable, Codable {
    var id = UUID()
    let date: String
    let seniorHires: String
    let otherHires: String
}

struct JobOpenings: Codable {
    let distribution: [String: String]
    let openingsDetails: [JobOpeningDetail]
    let jobOpeningsGrowth: [JobOpeningGrowth]
}

struct JobOpeningDetail: Identifiable, Codable {
    var id = UUID()
    let function: String
    let numEmployees: String
    let percentage: String
    let growth3m: String
    let growth6m: String
}

struct JobOpeningGrowth: Identifiable, Codable {
    var id = UUID()
    let function: String
    let growth3m: String
    let growth6m: String
}

struct JobOpeningPlainText: Identifiable, Codable {
    var id = UUID()
    let function: String
    let numEmployees: String
    let growth3m: String
    let growth6m: String
}

/// Updated to include optional companyName and importDate
struct LinkedInInsightsData: Codable {
    let employeeGrowth: [EmployeeGrowth]
    let functionDistribution: FunctionDistribution
    let headcountGrowth: [HeadcountGrowth]
    let newHires: [NewHire]
    let jobOpenings: JobOpenings
    let jobOpeningsPlainText: [JobOpeningPlainText]
    let medianTenure: String?
    let totalEmployees: [String: String]

    // NEW FIELDS
    var companyName: String?
    var importDate: Date?
}

struct SalaryRangeItem: Identifiable {
    let id = UUID()
    let jobID: UUID
    let company: String
    let jobTitle: String
    let date: Date
    let minSalary: Double
    let maxSalary: Double
    let orderIndex: Int
}

// --------------------------------------------------
// MARK: - Model: Note
// --------------------------------------------------
@Model
class SwiftDataNote {
    var id: UUID
    var content: String
    var creationDate: Date
    var lastModifiedDate: Date
    var order: Int
    
    init(
        id: UUID = UUID(),
        content: String,
        creationDate: Date = Date(),
        lastModifiedDate: Date = Date(),
        order: Int
    ) {
        self.id = id
        self.content = content
        self.creationDate = creationDate
        self.lastModifiedDate = lastModifiedDate
        self.order = order
    }
    
    func toNote() -> Note {
        return Note(
            id: id,
            content: content,
            creationDate: creationDate,
            lastModifiedDate: lastModifiedDate,
            order: order
        )
    }
}

struct Note: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var content: String
    var creationDate: Date
    var lastModifiedDate: Date
    var order: Int
    
    init(
        id: UUID = UUID(),
        content: String,
        creationDate: Date = Date(),
        lastModifiedDate: Date = Date(),
        order: Int
    ) {
        self.id = id
        self.content = content
        self.creationDate = creationDate
        self.lastModifiedDate = lastModifiedDate 
        self.order = order
    }
    
    // Dictionary representation for backup
    func toDictionary() -> [String: Any] {
        let isoFormatter = ISO8601DateFormatter()
        return [
            "id": id.uuidString,
            "content": content,
            "creationDate": isoFormatter.string(from: creationDate),
            "lastModifiedDate": isoFormatter.string(from: lastModifiedDate),
            "order": order
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> Note? {
        let isoFormatter = ISO8601DateFormatter()
        guard let idStr = dict["id"] as? String,
              let id = UUID(uuidString: idStr),
              let content = dict["content"] as? String,
              let creationDateStr = dict["creationDate"] as? String,
              let creationDate = isoFormatter.date(from: creationDateStr),
              let lastModifiedDateStr = dict["lastModifiedDate"] as? String,
              let lastModifiedDate = isoFormatter.date(from: lastModifiedDateStr),
              let order = dict["order"] as? Int
        else { return nil }
        
        return Note(
            id: id,
            content: content,
            creationDate: creationDate,
            lastModifiedDate: lastModifiedDate,
            order: order
        )
    }
    
    static func == (lhs: Note, rhs: Note) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

//-----------------------------------------------------------------------------------------------------//
