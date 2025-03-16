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

// MARK: - Imports

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

enum ViewSection: String, CaseIterable, CaseNameDisplayable {
    case jobDetails = "Job Details"
    case stats = "Stats"
    case documents = "Documents"
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
// MARK: - LinkedIn Insights Parser Functions
// --------------------------------------------------
// --------------------------------------------------
// MARK: - LinkedIn Insights Parser Functions
// --------------------------------------------------

// --------------------------------------------------
// MARK: - LinkedIn Insights Parser Functions
// --------------------------------------------------

// -------------------------------------
// MARK: - Helper Functions
// -------------------------------------

/// Cleans up duplicated or extraneous growth strings like "5%5% increase", "4%4% increase", etc.
func cleanGrowthString(_ growthStr: String) -> String {
    // First, check for duplicate percentages like "5%5% increase"
    let duplicatePattern = #"(-?\d+%)(?:\s*-?)?\1\s*(\b.*)"#
    let regex1 = try! NSRegularExpression(pattern: duplicatePattern)
    let range = NSRange(growthStr.startIndex..<growthStr.endIndex, in: growthStr)

    if let match = regex1.firstMatch(in: growthStr, range: range),
       let percentRange = Range(match.range(at: 1), in: growthStr),
       let trendRange = Range(match.range(at: 2), in: growthStr) {
        let percent = String(growthStr[percentRange])
        let trend = String(growthStr[trendRange]).trimmingCharacters(in: .whitespaces)
        return trend.isEmpty ? percent : "\(percent) \(trend)"
    }

    // Otherwise, parse with a more general pattern
    let pattern = #"(.*?)(-?\d+%)\s*(\b.*)"#
    let regex2 = try! NSRegularExpression(pattern: pattern)

    if let match = regex2.firstMatch(in: growthStr, range: range),
       let percentRange = Range(match.range(at: 2), in: growthStr),
       let trendRange = Range(match.range(at: 3), in: growthStr) {
        let percent = String(growthStr[percentRange])
        let trend = String(growthStr[trendRange]).trimmingCharacters(in: .whitespaces)
        return trend.isEmpty ? percent : "\(percent) \(trend)"
    }

    return growthStr
}

/// Parses a string like "4% increase" or "10% decrease" and returns an integer growth percentage.
/// Returns 0 if it contains "No change".
func parseGrowthPercentage(_ growthStr: String) -> Int? {
    if growthStr.contains("No change") { return 0 }
    let pattern = #"(\d+)%"#
    let regex = try! NSRegularExpression(pattern: pattern)
    let range = NSRange(growthStr.startIndex..<growthStr.endIndex, in: growthStr)
    if let match = regex.firstMatch(in: growthStr, range: range),
       let percentRange = Range(match.range(at: 1), in: growthStr) {
        var percent = Int(growthStr[percentRange])!
        if growthStr.lowercased().contains("decrease") {
            percent = -percent
        }
        return percent
    }
    return nil
}

/// Calculates how many employees were "added" based on a current count and a growth percent.
func calculateAdded(current: String, growthPercent: Int?) -> Int? {
    guard let growthPercent = growthPercent,
          let n = Int(current.replacingOccurrences(of: ",", with: "")) else { return nil }
    if growthPercent == 0 { return 0 }
    let previous = Double(n) / (1.0 + Double(growthPercent) / 100.0)
    let added = Double(n) - previous
    return Int(added.rounded())
}

/// Attempts to guess the company name from the LinkedIn HTML document.
func extractCompanyName(from doc: Document) -> String? {
    // 1. From the page title
    if let title = try? doc.title() {
        let components = title.components(separatedBy: " | ")
        if !components.isEmpty {
            let possibleName = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            if !possibleName.isEmpty && !possibleName.lowercased().contains("linkedin") {
                return possibleName
            }
        }
    }
    // 2. From meta property="og:title"
    if let metaCompany = try? doc.select("meta[property='og:title']").first(),
       let content = try? metaCompany.attr("content") {
        let parts = content.components(separatedBy: " | ")
        if !parts.isEmpty {
            let possibleName = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            if !possibleName.isEmpty && !possibleName.lowercased().contains("linkedin") {
                return possibleName
            }
        }
    }
    // 3. From a company header
    if let companyHeader = try? doc.select("h1.org-top-card-summary__title").first() {
        let textVal = try? companyHeader.text().trimmingCharacters(in: .whitespacesAndNewlines)
        if let name = textVal, !name.isEmpty {
            return name
        }
    }
    // Fallback: nil if not found
    return nil
}

// -------------------------------------
// MARK: - Extraction Functions
// -------------------------------------

func extractEmployeeGrowth(from doc: Document) throws -> [EmployeeGrowth] {
    var data: [EmployeeGrowth] = []
    guard let group = try doc.select("g[class*=highcharts-markers]").first() else { return data }
    let paths = try group.select("path[aria-label]")

    // This pattern attempts to capture a highcharts data label like:
    // "1. Wednesday, Mar 5, 14:00, 1,253 employees, +3% growth"
    let pattern = #"^\d+\.\s+([^,]+),\s+([^,]+)\s+(\d+),\s+([^,]+),\s+([\d,]+) employees(?:, (.+))?$"#
    let regex = try NSRegularExpression(pattern: pattern)

    for path in paths {
        let label = try path.attr("aria-label")
        let range = NSRange(label.startIndex..<label.endIndex, in: label)

        if let match = regex.firstMatch(in: label, range: range), match.numberOfRanges >= 6 {
            guard
                let dayRange = Range(match.range(at: 1), in: label),
                let monthRange = Range(match.range(at: 2), in: label),
                let dayNumRange = Range(match.range(at: 3), in: label),
                let timeRange = Range(match.range(at: 4), in: label),
                let countRange = Range(match.range(at: 5), in: label)
            else { continue }

            let dayOfWeek = String(label[dayRange])
            let month = String(label[monthRange])
            let day = String(label[dayNumRange])
            let time = String(label[timeRange])
            let countStr = String(label[countRange]).replacingOccurrences(of: ",", with: "")
            let employeeCount = Int(countStr) ?? 0

            let growth: String
            if match.numberOfRanges > 6, let growthRange = Range(match.range(at: 6), in: label) {
                growth = String(label[growthRange])
            } else {
                growth = ""
            }

            data.append(
                EmployeeGrowth(
                    dayOfWeek: dayOfWeek,
                    month: month,
                    day: day,
                    time: time,
                    employeeCount: employeeCount,
                    growth: growth,
                    year: nil
                )
            )
        }
    }

    // Approximate approach to assign a year to each data point
    let monthMap: [String: Int] = [
        "Jan": 1, "Feb": 2, "Mar": 3, "Apr": 4, "May": 5,
        "Jun": 6, "Jul": 7, "Aug": 8, "Sep": 9,
        "Oct": 10, "Nov": 11, "Dec": 12
    ]
    if let lastIndex = data.indices.reversed().first(where: { monthMap[data[$0].month] != nil }) {
        // Assume the last item is from the current year (e.g. 2025)
        data[lastIndex].year = 2025
        for i in (0..<lastIndex).reversed() {
            if
                let currentMonth = monthMap[data[i].month],
                let nextMonth = monthMap[data[i + 1].month],
                let nextYear = data[i + 1].year
            {
                data[i].year = (nextMonth == 1 && currentMonth == 12) ? (nextYear - 1) : nextYear
            }
        }
    }

    return data
}

func extractFunctionDistribution(from doc: Document) throws -> FunctionDistribution {
    var distribution: [String: String] = [:]
    guard let tableDiv = try doc.select("div.org-function-percentage-table").first() else { return distribution }
    let rows = try tableDiv.select("tr")
    for row in rows {
        if let td = try row.select("td").first(),
           let strong = try td.select("strong").first() {
            let percentage = try strong.text().trimmingCharacters(in: .whitespaces)
            let text = try td.text().trimmingCharacters(in: .whitespaces)
            let parts = text.split(separator: "·").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count >= 2 {
                distribution[parts[1]] = percentage
            }
        }
    }
    return distribution
}

func extractHeadcountGrowth(from doc: Document) throws -> [HeadcountGrowth] {
    var growthData: [HeadcountGrowth] = []
    guard let table = try doc.select("table[summary*=Headcount growth by function]").first() else { return growthData }
    // Skip the header row
    let rows = try table.select("tr").array()[1...]
    for row in rows {
        let cells = try row.select("td").array()
        if cells.count >= 5 {
            let function = try cells[0].text().trimmingCharacters(in: .whitespaces)
            let numEmployees = try cells[1].text().trimmingCharacters(in: .whitespaces)
            let percentage = try cells[2].text().trimmingCharacters(in: .whitespaces)
            let growth6m = cleanGrowthString(try cells[3].text().trimmingCharacters(in: .whitespaces))
            let growth1y = cleanGrowthString(try cells[4].text().trimmingCharacters(in: .whitespaces))

            growthData.append(
                HeadcountGrowth(
                    function: function,
                    numEmployees: numEmployees,
                    percentage: percentage,
                    growth6m: growth6m,
                    growth1y: growth1y,
                    added6m: nil,
                    added1y: nil
                )
            )
        }
    }
    return growthData
}

func extractNewHires(from doc: Document) throws -> [NewHire] {
    var hires: [NewHire] = []
    guard let table = try doc.select("table[summary*=Senior hires over time]").first() else { return hires }
    let rows = try table.select("tr").array()[1...] // skip header
    for row in rows {
        let cells = try row.select("td").array()
        if cells.count >= 3 {
            let date = try cells[0].text().trimmingCharacters(in: .whitespaces)
            let seniorHires = try cells[1].text().trimmingCharacters(in: .whitespaces)
            let otherHires = try cells[2].text().trimmingCharacters(in: .whitespaces)
            hires.append(NewHire(date: date, seniorHires: seniorHires, otherHires: otherHires))
        }
    }
    return hires
}

func extractJobOpenings(from doc: Document) throws -> JobOpenings {
    var distribution: [String: String] = [:]
    var openingsDetails: [JobOpeningDetail] = []
    var jobOpeningsGrowth: [JobOpeningGrowth] = []

    guard let jobModule = try doc.select("section[class*=org-insights-jobs-module]").first() else {
        return JobOpenings(distribution: distribution, openingsDetails: openingsDetails, jobOpeningsGrowth: jobOpeningsGrowth)
    }

    // Distribution
    if let distTable = try jobModule.select("div.org-function-percentage-table").first() {
        let rows = try distTable.select("tr")
        for row in rows {
            if let td = try row.select("td").first(),
               let strong = try td.select("strong").first() {
                let percentage = try strong.text().trimmingCharacters(in: .whitespaces)
                let text = try td.text().trimmingCharacters(in: .whitespaces)
                let parts = text.split(separator: "·").map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count >= 2 {
                    distribution[parts[1]] = percentage
                }
            }
        }
    }

    // Openings details
    if let detailsTable = try jobModule.select("table[id=function-growth__a11y-jobs-table]").first() {
        let rows = try detailsTable.select("tr").array()[1...] // skip header
        for row in rows {
            let cells = try row.select("td").array()
            if cells.count >= 5 {
                let function = try cells[0].text().trimmingCharacters(in: .whitespaces)
                let numEmployees = try cells[1].text().trimmingCharacters(in: .whitespaces)
                let percentage = try cells[2].text().trimmingCharacters(in: .whitespaces)
                let growth3m = cleanGrowthString(try cells[3].text().trimmingCharacters(in: .whitespaces))
                let growth6m = cleanGrowthString(try cells[4].text().trimmingCharacters(in: .whitespaces))

                openingsDetails.append(
                    JobOpeningDetail(
                        function: function,
                        numEmployees: numEmployees,
                        percentage: percentage,
                        growth3m: growth3m,
                        growth6m: growth6m
                    )
                )
            }
        }
    }

    // Job openings growth
    if let growthTable = try jobModule.select("table[class*=org-insights-functions-growth__table]").first() {
        let rows = try growthTable.select("tr").array()[1...] // skip header
        for row in rows {
            let cells = try row.select("td").array()
            if cells.count >= 3 {
                let function = try cells[0].text().trimmingCharacters(in: .whitespaces)
                let growth3m = cleanGrowthString(try cells[1].text().trimmingCharacters(in: .whitespaces))
                let growth6m = cleanGrowthString(try cells[2].text().trimmingCharacters(in: .whitespaces))
                jobOpeningsGrowth.append(
                    JobOpeningGrowth(
                        function: function,
                        growth3m: growth3m,
                        growth6m: growth6m
                    )
                )
            }
        }
    }

    return JobOpenings(
        distribution: distribution,
        openingsDetails: openingsDetails,
        jobOpeningsGrowth: jobOpeningsGrowth
    )
}

func extractJobOpeningsPlainText(from doc: Document) throws -> [JobOpeningPlainText] {
    var result: [JobOpeningPlainText] = []
    guard
        let growthDiv = try doc.select("div.org-function-growth-table").first(),
        let table = try growthDiv.select("table[id=function-growth__a11y-jobs-table]").first()
    else {
        return result
    }
    let rows = try table.select("tr").array()[1...] // skip header
    for row in rows {
        let cells = try row.select("td").array()
        if cells.count >= 5 {
            let function = try cells[0].text().trimmingCharacters(in: .whitespaces)
            let numEmployees = try cells[1].text().trimmingCharacters(in: .whitespaces)
            let growth3m = cleanGrowthString(try cells[3].text().trimmingCharacters(in: .whitespaces))
            let growth6m = cleanGrowthString(try cells[4].text().trimmingCharacters(in: .whitespaces))

            result.append(
                JobOpeningPlainText(
                    function: function,
                    numEmployees: numEmployees,
                    growth3m: growth3m,
                    growth6m: growth6m
                )
            )
        }
    }
    return result
}

func extractMedianTenure(from doc: Document) -> String? {
    let text = try? doc.text()
    let pattern = #"Median employee tenure.*?([\d.]+) years"#
    let regex = try! NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
    if
        let text = text,
        let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
        let valRange = Range(match.range(at: 1), in: text)
    {
        return String(text[valRange]) + " years"
    }
    return nil
}

func extractTotalEmployees(from doc: Document) throws -> [String: String] {
    var result: [String: String] = [:]
    guard let table = try doc.select("table[summary=Total employee count]").first() else { return result }

    // Overall total employees
    if let totalSpan = try table.select("span.t-bold").first() {
        result["total_employees"] = try totalSpan.text().trimmingCharacters(in: .whitespaces)
    }

    // Growth by time range
    let headers = try table.select("th.t-normal")
    let values = try table.select("td.t-bold")
    for (header, value) in zip(headers, values) {
        let key = try header.text().trimmingCharacters(in: .whitespaces).lowercased()
        if let growthSpan = try value.select("span.visually-hidden").first() {
            let growth = cleanGrowthString(try growthSpan.text().trimmingCharacters(in: .whitespaces))
            result[key] = growth
        }
    }
    return result
}

// -------------------------------------
// MARK: - Master Extract Function
// -------------------------------------

/// Parses raw HTML from a LinkedIn company insights page into a `LinkedInInsightsData` object.
/// This version includes company-name extraction and an import timestamp.
func extractData(from html: String) throws -> LinkedInInsightsData {
    do {
        let doc = try SwiftSoup.parse(html)

        // 1. Attempt to extract the company name
        let guessedCompanyName = extractCompanyName(from: doc)

        // 2. For each category, parse in a do/catch so one failure won't break everything
        let employeeGrowth: [EmployeeGrowth]
        do {
            employeeGrowth = try extractEmployeeGrowth(from: doc)
        } catch {
            print("Error extracting employee growth: \(error)")
            employeeGrowth = []
        }

        let functionDistribution: FunctionDistribution
        do {
            functionDistribution = try extractFunctionDistribution(from: doc)
        } catch {
            print("Error extracting function distribution: \(error)")
            functionDistribution = [:]
        }

        var headcountGrowth: [HeadcountGrowth]
        do {
            headcountGrowth = try extractHeadcountGrowth(from: doc)
        } catch {
            print("Error extracting headcount growth: \(error)")
            headcountGrowth = []
        }

        let newHires: [NewHire]
        do {
            newHires = try extractNewHires(from: doc)
        } catch {
            print("Error extracting new hires: \(error)")
            newHires = []
        }

        let jobOpenings: JobOpenings
        do {
            jobOpenings = try extractJobOpenings(from: doc)
        } catch {
            print("Error extracting job openings: \(error)")
            jobOpenings = JobOpenings(distribution: [:], openingsDetails: [], jobOpeningsGrowth: [])
        }

        let jobOpeningsPlainText: [JobOpeningPlainText]
        do {
            jobOpeningsPlainText = try extractJobOpeningsPlainText(from: doc)
        } catch {
            print("Error extracting job openings plain text: \(error)")
            jobOpeningsPlainText = []
        }

        let medianTenure = extractMedianTenure(from: doc)

        let totalEmployees: [String: String]
        do {
            totalEmployees = try extractTotalEmployees(from: doc)
        } catch {
            print("Error extracting total employees: \(error)")
            totalEmployees = [:]
        }

        // 3. Compute added employees for headcount growth
        headcountGrowth = headcountGrowth.map { item in
            let g6 = parseGrowthPercentage(item.growth6m)
            let g1 = parseGrowthPercentage(item.growth1y)
            let a6 = calculateAdded(current: item.numEmployees, growthPercent: g6)
            let a1 = calculateAdded(current: item.numEmployees, growthPercent: g1)
            return HeadcountGrowth(
                function: item.function,
                numEmployees: item.numEmployees,
                percentage: item.percentage,
                growth6m: item.growth6m,
                growth1y: item.growth1y,
                added6m: a6,
                added1y: a1
            )
        }

        // 4. Assemble and return final object with companyName + importDate
        return LinkedInInsightsData(
            employeeGrowth: employeeGrowth,
            functionDistribution: functionDistribution,
            headcountGrowth: headcountGrowth,
            newHires: newHires,
            jobOpenings: jobOpenings,
            jobOpeningsPlainText: jobOpeningsPlainText,
            medianTenure: medianTenure,
            totalEmployees: totalEmployees,
            companyName: guessedCompanyName,
            importDate: Date()
        )

    } catch {
        print("Critical error in LinkedIn Insights parsing: \(error)")
        // Return an empty dataset rather than throwing, to avoid crashing the flow
        return LinkedInInsightsData(
            employeeGrowth: [],
            functionDistribution: [:],
            headcountGrowth: [],
            newHires: [],
            jobOpenings: JobOpenings(distribution: [:], openingsDetails: [], jobOpeningsGrowth: []),
            jobOpeningsPlainText: [],
            medianTenure: nil,
            totalEmployees: [:],
            companyName: nil,
            importDate: Date()
        )
    }
}

// --------------------------------------------------
// MARK: - City-Coordinate Dictionary
// --------------------------------------------------

fileprivate var CityCoordinateDictionary: [String: CLLocationCoordinate2D] = [
    "New York City, NY": CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
    "Los Angeles, CA":   CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
    "Chicago, IL":       CLLocationCoordinate2D(latitude: 41.8781, longitude: -87.6298),
    "San Francisco, CA": CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    "Seattle, WA":       CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321),
    "Beijing, CN":       CLLocationCoordinate2D(latitude: 39.916668, longitude: 116.383331),
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
    "Manila, PH":        CLLocationCoordinate2D(latitude: 14.58834, longitude: 121.05949),
    "Tampa, FL":         CLLocationCoordinate2D(latitude: 27.9517, longitude: -82.4588),
    "San Diego, CA":     CLLocationCoordinate2D(latitude: 32.7157, longitude: -117.1611),
    "Singapore, SG":     CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198),
    "Global":            CLLocationCoordinate2D(latitude: 34.149884, longitude: -118.056932)
]

//---------------------------------------------------------------------------------------------------------//
//
//  DocumentStore.swift
//  Experimental-alpha
//
//  Created by Roger Lin on 3/4/25.
//


// --------------------------------------------------
// MARK: - LinkedIn Automation
// --------------------------------------------------

// --------------------------------------------------
// MARK: - LinkedIn Automation
// --------------------------------------------------

class LinkedInAutomationManager: NSObject, WKNavigationDelegate, WKUIDelegate {
    private var webView: WKWebView!
    private var url: URL
    private var completionHandler: ((String?, Error?) -> Void)?
    private var navigationCompletedHandler: (() -> Void)?
    private var username: String
    private var password: String
    private var isLoggedIn = false
    private var isDownloading = false

    init(url: URL, username: String, password: String) {
        self.url = url
        self.username = username
        self.password = password
        super.init()
        setupWebView()
    }

    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = prefs

        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1200, height: 800), configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
    }

    func startAutomation(completion: @escaping (String?, Error?) -> Void) {
        self.completionHandler = completion

        // Navigate to LinkedIn’s login page
        let request = URLRequest(url: URL(string: "https://www.linkedin.com/login")!)
        webView.load(request)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.url?.absoluteString.contains("linkedin.com/login") == true && !isLoggedIn {
            // On login screen, inject credentials
            performLogin { [weak self] success in
                if success {
                    self?.isLoggedIn = true
                    self?.navigateToInsightsPage()
                } else {
                    self?.completionHandler?(nil, NSError(domain: "LinkedInAutomation", code: 1001,
                                                          userInfo: [NSLocalizedDescriptionKey: "Failed to log in to LinkedIn"]))
                }
            }
        }
        else if let currentURL = webView.url?.absoluteString, currentURL.contains(url.absoluteString) {
            // Once on the target insights page, wait a moment before extracting HTML
            if !isDownloading {
                isDownloading = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                    self?.extractHTMLFromWebView()
                }
            }
        }
        else if navigationCompletedHandler != nil {
            navigationCompletedHandler?()
            navigationCompletedHandler = nil
        }
    }

    private func performLogin(completion: @escaping (Bool) -> Void) {
        let loginScript = """
        document.getElementById('username').value = '\(username)';
        document.getElementById('password').value = '\(password)';
        document.querySelector('button[type="submit"]').click();
        true;
        """

        webView.evaluateJavaScript(loginScript) { _, error in
            if let error = error {
                print("Login script error: \(error)")
                completion(false)
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                completion(true)
            }
        }
    }

    private func navigateToInsightsPage() {
        // Once logged in, load the actual insights page
        self.navigationCompletedHandler = { [weak self] in
            // Remove the unrelated data processing code
            self?.isDownloading = false
        }
        webView.load(URLRequest(url: url))
    }

    private func extractHTMLFromWebView() {
        webView.evaluateJavaScript("document.documentElement.outerHTML") { [weak self] (result, error) in
            if let error = error {
                self?.completionHandler?(nil, error)
                return
            }
            guard let htmlString = result as? String else {
                self?.completionHandler?(
                    nil,
                    NSError(domain: "LinkedInAutomation", code: 1002,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to extract HTML content"])
                )
                return
            }

            // Return final HTML
            self?.completionHandler?(htmlString, nil)
        }
    }
}

//--------------------------------------------------------------------------------------------------------//
//
//  JobStore.swift
//  Experimental-alpha
//
//  Created by Roger Lin on 3/4/25.
//

// MARK: - JobStore
// MARK: - JobStore
class JobStore: ObservableObject {
    @Published var jobApplications: [JobApplication] = []
    @Published var selectedJobIDs: Set<UUID> = []
    weak var documentStore: DocumentStore? = nil
    @Published var isAddingNewJob = false
    @Published var isEditingJob = false
    @Published var sorting: Sort = .recentlyApplied
    @Published var incomingJobData: [String: Any]? = nil
    @Published var availableSkills: [DesiredSkill] = []
    @Published var skillBeingEdited: DesiredSkill? = nil
    @Published var isShowingAliasEditor = false
    @Published var isAddingNewSkill = false

    // NEW: Track when we are automating LinkedIn logins
    @Published var isLoadingLinkedInData = false

    init(documentStore: DocumentStore? = nil) {
        self.documentStore = documentStore
        loadJobs()
        loadSkills()
        mergeExistingJobDocuments()
    }

    var selectedJob: JobApplication? {
        if let firstID = selectedJobIDs.first {
            return jobApplications.first(where: { $0.id == firstID })
        }
        return nil
    }

    private func mergeExistingJobDocuments() {
        guard let docStore = self.documentStore else { return }
        var allJobDocs: [JobDocument] = []
        for job in jobApplications {
            for doc in job.documents {
                var mutableDoc = doc
                mutableDoc.associatedCompany = job.companyName
                mutableDoc.associatedJobTitle = job.jobTitle
                mutableDoc.associatedApplicationDate = job.dateOfApplication
                allJobDocs.append(mutableDoc)
            }
        }
        docStore.mergeDocuments(allJobDocs)
    }

    // MARK: - CRUD (Add, Edit, Delete, Duplicate)
    func addJob(_ job: JobApplication) {
        var newJob = job
        parseJobDescriptionForSingleJob(&newJob)
        jobApplications.append(newJob)
        sortJobs(by: sorting)
        saveJobs()
    }

    func editJob(with updatedJob: JobApplication) {
        if let index = jobApplications.firstIndex(where: { $0.id == updatedJob.id }) {
            var singleJobEdit = updatedJob
            parseJobDescriptionForSingleJob(&singleJobEdit)
            jobApplications[index] = singleJobEdit
            sortJobs(by: sorting)
            saveJobs()
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
            salaryString: job.salaryString,
            salaryMin: job.salaryMin,
            salaryMax: job.salaryMax,
            jobDescription: job.jobDescription,
            coverLetter: job.coverLetter,
            notes: job.notes,
            documents: job.documents,
            isFavorite: job.isFavorite,
            jobType: job.jobType,
            desiredSkillNames: job.desiredSkillNames,
            jobDeadline: job.jobDeadline,
            linkedInInsightsData: job.linkedInInsightsData,
            crossJobSkillNames: job.crossJobSkillNames
        )
        jobApplications.append(newJob)
        sortJobs(by: sorting)
        saveJobs()
    }

    // MARK: - Update Status, Type, Favorite
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

    // MARK: - LinkedIn Insights Import
    func importLinkedInInsightsForJob(id: UUID, from html: String) {
        guard let parsedData = try? extractData(from: html) else {
            print("Failed to parse LinkedIn Insights HTML")
            return
        }
        if let index = jobApplications.firstIndex(where: { $0.id == id }) {
            // If no extracted name, keep the job’s name
            var updated = parsedData
            if updated.companyName == nil {
                updated.companyName = jobApplications[index].companyName
            }
            jobApplications[index].linkedInInsightsData = updated
            saveJobs()
        }
    }

    func automaticallyImportLinkedInInsights(forJobID id: UUID, fromURL urlString: String, username: String, password: String, completion: @escaping (Bool, String) -> Void) {
        guard let insightsURL = URL(string: urlString) else {
            completion(false, "Invalid URL")
            return
        }
        isLoadingLinkedInData = true
        let automationManager = LinkedInAutomationManager(url: insightsURL, username: username, password: password)
        automationManager.startAutomation { [weak self] (htmlString, error) in
            DispatchQueue.main.async {
                self?.isLoadingLinkedInData = false
                if let error = error {
                    completion(false, "Failed to automate LinkedIn import: \(error.localizedDescription)")
                    return
                }
                guard let html = htmlString else {
                    completion(false, "No HTML content returned.")
                    return
                }
                // Optionally save HTML to a file for reference:
                do {
                    let appSupportURL = try FileManager.default.url(
                        for: .applicationSupportDirectory,
                        in: .userDomainMask,
                        appropriateFor: nil,
                        create: true
                    )
                    let htmlDir = appSupportURL.appendingPathComponent("LinkedInHTML", isDirectory: true)
                    try FileManager.default.createDirectory(at: htmlDir, withIntermediateDirectories: true)
                    let fileName = "linkedin_\(id.uuidString)_\(Date().timeIntervalSince1970).html"
                    let filePath = htmlDir.appendingPathComponent(fileName)
                    try html.write(to: filePath, atomically: true, encoding: .utf8)
                } catch {
                    print("Error saving HTML file: \(error)")
                }
                // Now parse and import
                self?.importLinkedInInsightsForJob(id: id, from: html)
                completion(true, "Successfully imported LinkedIn insights.")
            }
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

    // MARK: - Persist Jobs
    func saveJobs() {
        syncToUserDefaults()
        saveToSwiftData()
        saveSkills()
    }

    private func syncToUserDefaults() {
        let jobsArray = jobApplications.map { $0.toDictionary() }
        if let jsonData = try? JSONSerialization.data(withJSONObject: jobsArray, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            UserDefaults.standard.set(jsonString, forKey: "jobs")
        }
        saveSkills()
    }

    private func loadJobs() {
        // Attempt SwiftData fetch first
        let descriptor = FetchDescriptor<SwiftDataJobApplication>()
        let swiftDataJobs: [SwiftDataJobApplication]
        do {
            swiftDataJobs = try documentStore?.modelContext.fetch(descriptor) ?? []
        } catch {
            swiftDataJobs = []
        }

        if !swiftDataJobs.isEmpty {
            jobApplications = swiftDataJobs.map { $0.toJobApplication() }
            sortJobs(by: sorting)
            syncToUserDefaults()
            for i in jobApplications.indices {
                if jobApplications[i].salaryMin == nil || jobApplications[i].salaryMax == nil {
                    parseMissingSalaryMinMax(for: &jobApplications[i])
                }
            }
            return
        }

        // Otherwise fallback to UserDefaults
        loadFromUserDefaults()
        saveToSwiftData()
        for i in jobApplications.indices {
            if jobApplications[i].salaryMin == nil || jobApplications[i].salaryMax == nil {
                parseMissingSalaryMinMax(for: &jobApplications[i])
            }
        }
    }

    private func loadFromUserDefaults() {
        guard let jsonString = UserDefaults.standard.string(forKey: "jobs"),
              let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData, options: []),
              let array = json as? [[String: Any]]
        else { return }

        var temp: [JobApplication] = []
        for dict in array {
            if let job = JobApplication.fromDictionary(dict) {
                temp.append(job)
            }
        }
        jobApplications = temp
        sortJobs(by: sorting)
    }

    private func saveToSwiftData() {
        guard let ctx = documentStore?.modelContext else { return }
        do {
            try ctx.delete(model: SwiftDataJobApplication.self)
            for job in jobApplications {
                var linkedInData: Data? = nil
                if let insights = job.linkedInInsightsData {
                    linkedInData = try? JSONEncoder().encode(insights)
                }
                let swiftDocs = job.documents.map {
                    SwiftDataJobDocument(
                        id: $0.id,
                        fileName: $0.fileName,
                        fileData: $0.fileData,
                        fileURL: $0.fileURL,
                        creation: $0.creationDate,
                        lastModified: $0.lastModifiedDate,
                        fileSize: $0.fileSize,
                        wordCount: $0.wordCount,
                        categoryID: $0.categoryID,
                        associatedCompany: $0.associatedCompany,
                        associatedJobTitle: $0.associatedJobTitle,
                        associatedApplicationDate: $0.associatedApplicationDate
                    )
                }
                let sdJob = SwiftDataJobApplication(
                    id: job.id,
                    companyName: job.companyName,
                    jobTitle: job.jobTitle,
                    status: job.status,
                    dateOfApplication: job.dateOfApplication,
                    location: job.location,
                    linkToJobString: job.linkToJobString,
                    salaryString: job.salaryString,
                    salaryMin: job.salaryMin,
                    salaryMax: job.salaryMax,
                    jobDescription: job.jobDescription,
                    coverLetter: job.coverLetter,
                    notes: job.notes,
                    documents: job.documents, // pass the original [JobDocument]
                    isFavorite: job.isFavorite,
                    jobType: job.jobType,
                    desiredSkillNames: job.desiredSkillNames,
                    jobDeadline: job.jobDeadline,
                    linkedInInsightsData: linkedInData
                )
                // Assign SwiftDataJobDocuments to the relationship
                sdJob.documents = swiftDocs
                ctx.insert(sdJob)
            }
            try ctx.save()
        } catch {
            print("SwiftData saving error: \(error)")
        }
    }

    private func parseMissingSalaryMinMax(for job: inout JobApplication) {
        let (mn, mx) = JobViewModel.parseSalaryRangeStatic(job.salaryString ?? "")
        job.salaryMin = mn
        job.salaryMax = mx
    }

    // MARK: - Backup Import/Export
    func importBackup(url: URL) {
        do {
            let json = try String(contentsOf: url, encoding: .utf8)
            if let data = json.data(using: .utf8),
               let array = try? JSONSerialization.jsonObject(with: data, options: []),
               let jobDicts = array as? [[String: Any]] {
                var imported: [JobApplication] = []
                for dict in jobDicts {
                    if let j = JobApplication.fromDictionary(dict) {
                        imported.append(j)
                    }
                }
                DispatchQueue.main.async {
                    self.jobApplications = imported
                    self.sortJobs(by: self.sorting)
                    self.saveJobs()
                    for i in self.jobApplications.indices {
                        if self.jobApplications[i].salaryMin == nil || self.jobApplications[i].salaryMax == nil {
                            self.parseMissingSalaryMinMax(for: &self.jobApplications[i])
                        }
                    }
                }
            }
        } catch {
            print("Error importing jobs: \(error)")
        }
    }

    func exportBackup(url: URL) {
        let array = jobApplications.map { $0.toDictionary() }
        if let data = try? JSONSerialization.data(withJSONObject: array, options: .prettyPrinted),
           let str = String(data: data, encoding: .utf8) {
            do {
                try str.write(to: url, atomically: true, encoding: .utf8)
                print("Exported backup.")
            } catch {
                print("Export error: \(error)")
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
        if let i = availableSkills.firstIndex(where: { $0.id == skill.id }) {
            availableSkills[i] = skill
            saveSkills()
            parseJobDescriptionsForSkill(skill)
        }
    }

    func deleteSkill(_ skill: DesiredSkill) {
        if let i = availableSkills.firstIndex(where: { $0.id == skill.id }) {
            availableSkills.remove(at: i)
            saveSkills()
            for j in jobApplications.indices {
                jobApplications[j].desiredSkillNames.removeAll { $0 == skill.name }
            }
            saveJobs()
        }
    }

    func saveSkills() {
        do {
            let data = try JSONEncoder().encode(availableSkills)
            UserDefaults.standard.set(data, forKey: Constants.skillsKey)
        } catch {
            print("Error saving skills: \(error)")
        }
    }

    func loadSkills() {
        if let savedData = UserDefaults.standard.data(forKey: Constants.skillsKey),
           let loaded = try? JSONDecoder().decode([DesiredSkill].self, from: savedData) {
            availableSkills = loaded
            return
        }
        guard let jsonString = UserDefaults.standard.string(forKey: Constants.skillsKey),
              let jsonData = jsonString.data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: jsonData, options: []),
              let skillDicts = arr as? [[String: Any]]
        else { return }
        var loadedSkills: [DesiredSkill] = []
        for d in skillDicts {
            if let s = DesiredSkill.fromDictionary(d) {
                loadedSkills.append(s)
            }
        }
        availableSkills = loadedSkills
    }

    func parseJobDescriptionForSingleJob(_ job: inout JobApplication) {
        for skill in availableSkills {
            let terms = [skill.name.lowercased()] + skill.aliases.map { $0.lowercased() }
            let desc = job.jobDescription.lowercased()
            if terms.contains(where: { desc.contains($0) }) {
                if !job.desiredSkillNames.contains(skill.name) {
                    job.desiredSkillNames.append(skill.name)
                }
            }
        }
    }

    func parseJobDescriptionsForSkill(_ skill: DesiredSkill) {
        let searchTerms = [skill.name.lowercased()] + skill.aliases.map { $0.lowercased() }
        for i in jobApplications.indices {
            var j = jobApplications[i]
            let desc = j.jobDescription.lowercased()
            if searchTerms.contains(where: { desc.contains($0) }) {
                if !j.desiredSkillNames.contains(skill.name) {
                    j.desiredSkillNames.append(skill.name)
                }
            }
            jobApplications[i] = j
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

// Extend JobApplication to quickly retrieve docs array for merging
extension JobApplication {
    func jobDocumentsForMerging() -> [JobDocument] {
        return documents
    }
}

extension JobViewModel {
    /// Parses the job description for salary information.
    ///
    /// **Guidelines & Parsing Rules:**
    /// 1. **Marker Search:** Look for the literal `"Salary:"` (case-insensitive) in the description.
    /// 2. **Line Extraction:** Once found, extract the remainder of that line (i.e. up to the next newline).
    /// 3. **Currency Pattern:** Within that line, search for currency patterns that:
    ///    - Start with a `$` sign.
    ///    - Have at least two digits immediately following (e.g. `$78...`).
    ///    - May contain commas and a decimal point.
    ///    - Optionally include a trailing `K` (or `k`), which should be replaced with `000`.
    /// 4. **Multiple Occurrences:** If a single match is found, use that value for both minimum and maximum.
    ///    If two or more are found, sort the values and choose the lower as the minimum and the higher as the maximum.
    ///    (It is allowed for both values to be identical.)
    /// 5. **Formatting:** Use a `NumberFormatter` configured for currency (with no fractional digits) to format
    ///    the output. The final salary string for the textfield should be in the format:
    ///       - **Single Value:** e.g. `$78,000`
    ///       - **Range:** e.g. `$119,000 – $150,000`
    ///
    /// - Parameter description: The full job description text.
    /// - Returns: A tuple containing:
    ///    - **formattedSalary:** The currency-formatted string.
    ///    - **minSalary:** The minimum salary as a Double.
    ///    - **maxSalary:** The maximum salary as a Double.
    static func parseSalaryCurrency(from description: String) -> (formattedSalary: String?, minSalary: Double?, maxSalary: Double?) {
        // 1. Search for "Salary:" in a case-insensitive manner.
        guard let salaryMarkerRange = description.range(of: "(?i)Salary:\\s*", options: .regularExpression) else {
            // No salary marker found; return nils.
            return (nil, nil, nil)
        }

        // 2. Extract the substring after "Salary:" up to the end of the line.
        let substringAfterMarker = description[salaryMarkerRange.upperBound...]
        let salaryLine = substringAfterMarker.split(separator: "\n").first.map(String.init) ?? ""

        // 3. Define a regex to match a currency pattern.
        // Pattern details:
        // - Starts with a "$" sign.
        // - Uses a positive lookahead to ensure at least two digits follow.
        // - Matches digits, commas, and decimal points.
        // - Optionally matches a trailing "K" (case-insensitive) which we will later replace.
        let pattern = "\\$(?=\\d{2})[\\d,\\.]+(?:[kK])?"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return (nil, nil, nil)
        }

        // 4. Find all matches in the extracted salary line.
        let matches = regex.matches(in: salaryLine, options: [], range: NSRange(location: 0, length: salaryLine.utf16.count))
        var salaryValues: [Double] = []

        for match in matches {
            if let range = Range(match.range, in: salaryLine) {
                var salaryString = String(salaryLine[range])

                // 5. Replace any "K" (or "k") with "000".
                salaryString = salaryString.replacingOccurrences(of: "(?i)k", with: "000", options: .regularExpression)

                // 6. Remove the "$" sign and any commas.
                salaryString = salaryString.replacingOccurrences(of: "$", with: "")
                salaryString = salaryString.replacingOccurrences(of: ",", with: "")

                // 7. Trim any extraneous whitespace.
                salaryString = salaryString.trimmingCharacters(in: .whitespacesAndNewlines)

                // 8. Convert the cleaned string to a Double.
                if let value = Double(salaryString) {
                    salaryValues.append(value)
                }
            }
        }

        // 9. If no values were found, return nil.
        if salaryValues.isEmpty {
            return (nil, nil, nil)
        }

        // 10. Determine the minimum and maximum salary values.
        let minSalary: Double
        let maxSalary: Double

        if salaryValues.count == 1 {
            minSalary = salaryValues[0]
            maxSalary = salaryValues[0]
        } else {
            minSalary = salaryValues.min() ?? salaryValues[0]
            maxSalary = salaryValues.max() ?? salaryValues[0]
        }

        // 11. Format the numeric salary values as currency.
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        let formattedMin = formatter.string(from: NSNumber(value: minSalary)) ?? ""
        let formattedMax = formatter.string(from: NSNumber(value: maxSalary)) ?? ""

        // 12. Build the final formatted salary string.
        let formattedSalary: String
        if minSalary == maxSalary {
            formattedSalary = formattedMax
        } else {
            formattedSalary = "\(formattedMin) – \(formattedMax)"
        }

        return (formattedSalary, minSalary, maxSalary)
    }

    /// Uses the current job description to update the salary textfield input and the internal salary values.
    func parseSalaryFromJobDescription() {
        let (formatted, min, max) = JobViewModel.parseSalaryCurrency(from: self.jobDescription)
        if let formatted = formatted {
            self.salaryString = formatted
            self.salaryMin = min
            self.salaryMax = max
        }
    }
}
//--------------------------------------------------------------------------------------------------------//


//--------------------------------------------------------------------------------------------------------//

//
//  ContentView.swift
//  Experimental-alpha
//
//  Created by Roger Lin on 3/4/25.
//

import Foundation

// MARK: - ContentView
struct ContentView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @EnvironmentObject var importExportHelper: ImportExportHelper
    @Binding var showSettings: Bool
    @State private var selectedSection: ViewSection = .jobDetails
    @State private var searchText: String = ""
    @State private var isDarkMode: Bool = false
    @State private var showDocInfoPopover = false


    var body: some View {
        NavigationView {
            sidebar
                .frame(minWidth: 250)
                .transition(.move(edge: .leading))

            mainContent
                .transition(.opacity)
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
                                docStore.uploadDocumentsNonAsync(from: openPanel.urls)
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
        .animation(.easeInOut, value: selectedSection) // Add transition animation for section switching
        .onDisappear {
            // Clean up resources when view disappears
            docStore.clearCaches()
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
                JobDetailView(job: job, showSettings: $showSettings)  // ✅ Pass showSettings
                    .id(job.id) // Force view refresh when job changes
            } else {
                Text("Select a job to view details")
                    .foregroundColor(.secondary)
            }
        case .stats:
            EnhancedStatsView()
        case .documents:
            DocumentsMainView()
                .id(docStore.selectedDocument?.id) // Force view refresh when selected document changes
        }
    }
}

//
//  DocumentStore.swift
//  Experimental-alpha
//
//  Created by Roger Lin on 3/4/25.
//
// MARK: - DocumentStore
class DocumentStore: ObservableObject {
    @Published var documents: [JobDocument] = []
    @Published var selectedDocument: JobDocument? = nil
    @Published var categories: [DocumentCategory] = []
    @Published var isCreatingNewCategory = false
    @Published var newCategoryName: String = "Category Name"
    @Published var quickLookURL: URL? = nil
    @Published var isEditingMetadata = false
    @Published var documentToEdit: JobDocument? = nil
    public let modelContext: ModelContext
    // Variables to track memory usage
    private var cachedPDFDocuments: [UUID: PDFDocument] = [:]
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadDocuments()
        loadCategories()
        deduplicateDocuments()
    }
    private func loadFromUserDefaults() {
        guard let jsonString = UserDefaults.standard.string(forKey: Constants.documentsKey),
              let jsonData = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
              let docsArray = jsonObject as? [[String: Any]]
        else {
            return
        }
        var loadedDocs: [JobDocument] = []
        for dict in docsArray {
            if let doc = JobDocument.fromDictionary(dict) {
                loadedDocs.append(doc)
            }
        }
        documents = loadedDocs
        deduplicateDocuments()
    }
    // For non-async usage
    func uploadDocumentsNonAsync(from urls: [URL]) {
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
        deduplicateDocuments()
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
            categoryID: document.categoryID,
            associatedCompany: document.associatedCompany,
            associatedJobTitle: document.associatedJobTitle,
            associatedApplicationDate: document.associatedApplicationDate
        )
        documents.append(newDoc)
        saveDocuments()
        deduplicateDocuments()
    }
    func deleteDocument(_ document: JobDocument) {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents.remove(at: index)
            // Clean up cached PDF if it exists
            cachedPDFDocuments[document.id] = nil
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
    func deduplicateDocuments() {
        // Group documents by filename
        var fileNameMap: [String: [JobDocument]] = [:]
        for doc in documents {
            if fileNameMap[doc.fileName] == nil {
                fileNameMap[doc.fileName] = [doc]
            } else {
                fileNameMap[doc.fileName]?.append(doc)
            }
        }
        // For each filename, keep only the most recent document
        var deduplicated: [JobDocument] = []
        for (_, docs) in fileNameMap {
            if docs.count > 1 {
                // Sort by last modified date (newest first) and take the first one
                if let newest = docs.sorted(by: { $0.lastModifiedDate > $1.lastModifiedDate }).first {
                    deduplicated.append(newest)
                }
            } else if let doc = docs.first {
                deduplicated.append(doc)
            }
        }
        documents = deduplicated
        saveDocuments()
    }
    /// Merges a set of new documents into our store, ignoring duplicates.
    func mergeDocuments(_ newDocs: [JobDocument]) {
        for doc in newDocs {
            if !documents.contains(where: { $0.id == doc.id }) {
                documents.append(doc)
            }
        }
        saveDocuments()
        deduplicateDocuments()
    }
    // Save & Load Documents
    func saveDocuments() {
        saveToSwiftData()
        let docsArray = documents.map { $0.toDictionary() } // Keep UserDefaults backup for now
        if let jsonData = try? JSONSerialization.data(withJSONObject: docsArray, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            UserDefaults.standard.set(jsonString, forKey: Constants.documentsKey)
        }
    }
    func loadDocuments() {
        // First try SwiftData
        let descriptor = FetchDescriptor<SwiftDataJobDocument>()
        do {
            let swiftDataDocs = try modelContext.fetch(descriptor)
            if !swiftDataDocs.isEmpty {
                documents = SwiftDataJobDocument.toJobDocuments(from: swiftDataDocs)
                deduplicateDocuments()
                return
            }
            // Fallback to UserDefaults if SwiftData is empty
            loadFromUserDefaults()
            saveToSwiftData() // Migrate to SwiftData on first load from UserDefaults
        } catch {
            print("SwiftData fetch failed: \(error)")
            loadFromUserDefaults()
        }
    }
    private func saveToSwiftData() {
        do {
            try modelContext.delete(model: SwiftDataJobDocument.self)
            for doc in documents {
                let sdDoc = SwiftDataJobDocument(
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
                modelContext.insert(sdDoc)
            }
            try modelContext.save()
        } catch {
            print("SwiftData document save failed: \(error)")
        }
    }
    // Categories
    func saveCategories() {
        let catsArray = categories.map {
            [
                "id": $0.id.uuidString,
                "name": $0.name,
                "isExpanded": $0.isExpanded
            ] as [String: Any]
        }
        if let jsonData = try? JSONSerialization.data(withJSONObject: catsArray, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            UserDefaults.standard.set(jsonString, forKey: Constants.documentCategoriesKey)
        }
    }
    func loadCategories() {
        guard let jsonString = UserDefaults.standard.string(forKey: Constants.documentCategoriesKey),
              let jsonData = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
              let catsArray = jsonObject as? [[String: Any]]
        else {
            return
        }
        var loadedCats: [DocumentCategory] = []
        for dict in catsArray {
            if let idStr = dict["id"] as? String,
               let id = UUID(uuidString: idStr),
               let name = dict["name"] as? String,
               let isExpanded = dict["isExpanded"] as? Bool {
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
    // Move/copy documents into Application Support
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
    // Memory Management - Get cached PDF document or create one
    func getPDFDocument(for document: JobDocument) -> PDFDocument? {
        // Check if we have a cached version
        if let cachedPDF = cachedPDFDocuments[document.id] {
            return cachedPDF
        }
        // Create a new PDF document
        let pdfDoc = PDFDocument(data: document.fileData)
        // Cache it for future use
        if let pdfDoc = pdfDoc {
            cachedPDFDocuments[document.id] = pdfDoc
            // Clear cache if it gets too large (over 10 items)
            if cachedPDFDocuments.count > 10 {
                // Keep the 5 most recently accessed items
                let recentDocIDs = Array(cachedPDFDocuments.keys.suffix(5))
                cachedPDFDocuments = cachedPDFDocuments.filter { recentDocIDs.contains($0.key) }
            }
        }
        return pdfDoc
    }
    // Memory Management - Clear caches
    func clearCaches() {
        cachedPDFDocuments.removeAll()
    }
}


// MARK: - LinkedInInsightsImporter
struct LinkedInInsightsImporter: View {
    @EnvironmentObject var jobStore: JobStore
    @Binding var job: JobApplication
    @State private var isShowingImportDialog = false
    @State private var isShowingAutomationDialog = false
    @State private var linkedInURL = ""
    @State private var username = "linroger023@gmail.com"
    @State private var password = "Belgravia11!"
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        VStack {
            if jobStore.isLoadingLinkedInData {
                ProgressView("Loading LinkedIn data...").padding()
            } else {
                HStack {
                    Button("Import LinkedIn Insight") {
                        isShowingImportDialog = true
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Import from URL") {
                        isShowingAutomationDialog = true
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 5)
            }
        }
        .fileImporter(isPresented: $isShowingImportDialog, allowedContentTypes: [.html], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    do {
                        let htmlContent = try String(contentsOf: url, encoding: .utf8)
                        jobStore.importLinkedInInsightsForJob(id: job.id, from: htmlContent)
                        if let updatedJob = jobStore.jobApplications.first(where: { $0.id == job.id }) {
                            job = updatedJob
                        }
                    } catch {
                        errorMessage = "Failed to read HTML file: \(error.localizedDescription)"
                        showError = true
                    }
                }
            case .failure(let error):
                errorMessage = "File import failed: \(error.localizedDescription)"
                showError = true
            }
        }
        .sheet(isPresented: $isShowingAutomationDialog) {
            VStack(spacing: 20) {
                Text("Import LinkedIn Insights from URL").font(.title2).bold()
                TextField("LinkedIn Company Insights URL", text: $linkedInURL)
                    .textFieldStyle(.roundedBorder)
                TextField("LinkedIn Username", text: $username)
                    .textFieldStyle(.roundedBorder)
                SecureField("LinkedIn Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                Text("Note: This uses your LinkedIn credentials to log in and scrape insights data.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                HStack {
                    Button("Cancel") {
                        isShowingAutomationDialog = false
                    }
                    .buttonStyle(.bordered)
                    Button("Import") {
                        isShowingAutomationDialog = false
                        isLoading = true
                        jobStore.automaticallyImportLinkedInInsights(forJobID: job.id, fromURL: linkedInURL, username: username, password: password) { success, message in
                            isLoading = false
                            if !success {
                                errorMessage = message
                                showError = true
                            } else {
                                if let updatedJob = jobStore.jobApplications.first(where: { $0.id == job.id }) {
                                    job = updatedJob
                                }
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(linkedInURL.isEmpty)
                }
            }
            .padding()
            .frame(width: 400, height: 320)
        }
        .alert("Import Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
}




// MARK: - ImportExportHelper

// MARK: - ImportExportHelper
class ImportExportHelper: NSObject, ObservableObject {
    @Published var isImporting = false
    @Published var isExporting = false

    func importBackup(completion: @escaping (URL) -> Void) {
        let op = NSOpenPanel()
        op.allowedContentTypes = [UTType.json]
        op.allowsMultipleSelection = false
        op.canChooseDirectories = false
        op.canChooseFiles = true
        op.begin { resp in
            if resp == .OK, let url = op.url {
                completion(url)
            }
        }
    }

    func exportBackup(completion: @escaping (URL) -> Void) {
        let sp = NSSavePanel()
        sp.allowedContentTypes = [UTType.json]
        sp.canCreateDirectories = true
        sp.nameFieldStringValue = "JobsBackup.json"
        sp.begin { resp in
            if resp == .OK, let url = sp.url {
                completion(url)
            }
        }
    }

    func importDocuments(completion: @escaping ([URL]) -> Void) {
        let op = NSOpenPanel()
        op.allowedContentTypes = [.pdf, .image, .plainText, .rtf]
        op.allowsMultipleSelection = true
        op.canChooseDirectories = false
        op.canChooseFiles = true
        op.begin { resp in
            if resp == .OK {
                completion(op.urls)
            }
        }
    }

    func exportDocuments(completion: @escaping (URL) -> Void) {
        let sp = NSSavePanel()
        sp.allowedContentTypes = [.zip]
        sp.canCreateDirectories = true
        sp.nameFieldStringValue = "DocumentsExport.zip"
        sp.begin { resp in
            if resp == .OK, let url = sp.url {
                completion(url)
            }
        }
    }
}



//--------------------------------------------------------------------------------------------------------//




//--------------------------------------------------------------------------------------------------------//

//
//  Main App.swift
//  Experimental-alpha
//
//  Created by Roger Lin on 3/4/25.
//

// MARK: - Main App
@main
struct AppleJobApp: App {
    @StateObject private var jobStore: JobStore
    @StateObject private var docStore: DocumentStore
    @StateObject private var importExportHelper = ImportExportHelper()
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: SwiftDataJobApplication.self, SwiftDataJobDocument.self,
                configurations: ModelConfiguration()
            )
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }

        // Create the stores separately
        let stores = AppleJobApp.createStores(using: container)
        _docStore = StateObject(wrappedValue: stores.documentStore)
        _jobStore = StateObject(wrappedValue: stores.jobStore)
    }

    private static func createStores(using container: ModelContainer) -> (documentStore: DocumentStore, jobStore: JobStore) {
        let documentStore = DocumentStore(modelContext: container.mainContext)
        let jobStore = JobStore(documentStore: documentStore)
        return (documentStore, jobStore)
    }

    // Settings sheet state
    @State private var showSettings = false

    var body: some Scene {
        WindowGroup {
            ContentView(showSettings: $showSettings)
                .environmentObject(jobStore)
                .environmentObject(docStore)
                .environmentObject(importExportHelper)

                .sheet(isPresented: $showSettings) {
                    SettingsView(importExportHelper: importExportHelper)
                        .environmentObject(jobStore)
                        .environmentObject(docStore)
                }
        }
        .modelContainer(container) // Attach ModelContainer to WindowGroup
        .commands {
            fileMenuCommands
            editMenuCommands
            settingsCommands
        }
    }
    private var settingsCommands: some Commands {
        CommandMenu("Settings") { // Or whatever menu you want to put Settings under
            Button("Settings...") {
                showSettings = true // Assuming showSettings is meant to be used here (from ContentView's binding)
            }
            .keyboardShortcut(",", modifiers: .command)
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
                    docStore.uploadDocumentsNonAsync(from: urls)
                }
            }

            Button("Export Documents...") {
                importExportHelper.exportDocuments { url in
                    exportAllDocumentsToZip(url: url)
                }
            }

            Divider()
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

            Button("Settings...") {
                showSettings = true
            }
            .keyboardShortcut(",", modifiers: .command)

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
            throw NSError(
                domain: "ZipError",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: "Zip process failed."]
            )
        }
    }
}
//--------------------------------------------------------------------------------------------------------//

//
//  SettingsView.swift
//  Experimental-alpha
//
//  Created by Roger Lin on 3/4/25.
//

import Foundation

// MARK: - SettingsView
struct SettingsView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @ObservedObject var importExportHelper: ImportExportHelper
    @AppStorage("usesDarkMode") private var usesDarkMode = false
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0

    var body: some View {
        VStack {
            TabView(selection: $selectedTab) {
                // General Tab
                generalSettings
                    .tabItem {
                        Label("General", systemImage: "gear")
                    }
                    .tag(0)

                // Backup & Import Tab
                backupSettings
                    .tabItem {
                        Label("Backup & Import", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .tag(1)

                // About Tab
                aboutSettings
                    .tabItem {
                        Label("About", systemImage: "info.circle")
                    }
                    .tag(3)
            }
            .padding()

            Divider()

            HStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 600, height: 500)
        .onAppear {
            // Observe system appearance changes
            NSApp.appearance = usesDarkMode ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
        }
    }

    // General Settings tab content
    private var generalSettings: some View {
        Form {
            Section("Appearance") {
                Toggle("Dark Mode", isOn: $usesDarkMode)
                    .onChange(of: usesDarkMode) { _, newValue in
                        NSApp.appearance = newValue ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
                    }
            }

            Section("Job Application Settings") {
                // Add any job application related settings here
                Toggle("Autofill Job Details from URL", isOn: .constant(true))
                    .disabled(true) // Placeholder for future functionality

                Toggle("Save Documents to Global Store", isOn: .constant(true))
                    .disabled(true) // Placeholder for future functionality
            }
        }
    }

    // Backup & Import tab content
    private var backupSettings: some View {
        Form {
            Section("Backup") {
                VStack(alignment: .leading) {
                    Text("Export your job applications and documents as a backup file")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Export Job Applications") {
                        importExportHelper.isExporting = true
                        importExportHelper.exportBackup { url in
                            jobStore.exportBackup(url: url)
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Export Documents") {
                        importExportHelper.exportDocuments { url in
                            // Call document export function
                            exportAllDocumentsToZip(url: url)
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 5)
            }

            Section("Import") {
                VStack(alignment: .leading) {
                    Text("Import a backup file to restore your job applications")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Import Job Applications") {
                        importExportHelper.isImporting = true
                        importExportHelper.importBackup { url in
                            jobStore.importBackup(url: url)
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Import Documents") {
                        importExportHelper.importDocuments { urls in
                            // Call document import function once with all URLs
                            docStore.uploadDocumentsNonAsync(from: urls)
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 5)
            }

            Section("Data Management") {
                Button("Clear Unused Document Cache") {
                    docStore.clearCaches()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // About tab content
    private var aboutSettings: some View {
        VStack(spacing: 20) {
            Image(systemName: "briefcase.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("AppleJob")
                .font(.largeTitle)
                .bold()

            Text("Version 1.0")
                .font(.headline)

            Text("A job application tracking app for macOS")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()

            Text("© 2025 Roger Lin. All rights reserved.")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            throw NSError(
                domain: "ZipError",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: "Zip process failed."]
            )
        }
    }
}



//--------------------------------------------------------------------------------------------------------//



// --------------------------------------------------
// MARK: - JobViewModel
// --------------------------------------------------

/// Holds partial parse results from job description text
struct ParsedJobDescriptionResult {
    var sanitizedText: String
    var detectedJobTitle: String?
    var detectedCompanyName: String?
    var detectedLocation: String?
    var detectedDesiredSkills: String? = nil
    var detectedURL: String?

}

class JobViewModel: ObservableObject {
    @Published var companyName: String = ""
    @Published var jobTitle: String = ""
    @Published var status: JobStatus = .applied
    @Published var dateOfApplication: Date = Date()
    @Published var location: String = ""
    @Published var linkToJob: String = ""
    @Published var jobDescription: String = "" {
        didSet { parseDescriptionIfNeeded() }
    }
    @Published var coverLetter: String = ""
    @Published var notes: String = ""
    @Published var salaryString: String = ""
    @Published var salaryMin: Double? = nil
    @Published var salaryMax: Double? = nil
    @Published var jobType: JobType = .fullTime
    @Published var desiredSkillText: String = ""
    @Published var selectedDesiredSkills: [String] = []
    @Published var availableSkillSuggestions: [String] = []
    @Published var isInputValid: Bool = false
    @Published var jobDeadline: Date? = nil

    init() {
        validateInputs()
    }

    init(job: JobApplication, availableSkills: [DesiredSkill]) {
        companyName = job.companyName
        jobTitle = job.jobTitle
        status = job.status
        dateOfApplication = job.dateOfApplication
        location = job.location
        linkToJob = job.linkToJobString ?? ""
        jobDescription = job.jobDescription
        coverLetter = job.coverLetter
        notes = job.notes ?? ""
        jobType = job.jobType
        selectedDesiredSkills = job.desiredSkillNames
        jobDeadline = job.jobDeadline

        // If the user has a salary range or a single salary, store in salaryString
        if let existing = job.salaryString {
            salaryString = existing
        }
        // Also hold onto job’s min/max if present
        salaryMin = job.salaryMin
        salaryMax = job.salaryMax

        availableSkillSuggestions = availableSkills.map { $0.name }.sorted()
        validateInputs()
        parseDescriptionIfNeeded()

    }

    func validateInputs() {
        DispatchQueue.main.async {
            self.isInputValid = !(self.companyName.isEmpty || self.jobTitle.isEmpty)
        }
    }

    /// Overhauled to remove "K" and certain patterns, then parse numeric
    func updateSalary(fromString newValue: String) {
        // Clean the string by removing certain patterns
        var cleaned = newValue
        // Replace "K" with "000" (case-insensitive)
        cleaned = cleaned.replacingOccurrences(of: "(?i)k", with: "000", options: .regularExpression)
        // Remove '/', 'year', 'yr', 'per' (case-insensitive)
        let patternsToRemove = ["(?i)/", "(?i)year", "(?i)yr", "(?i)per"]
        for pattern in patternsToRemove {
            cleaned = cleaned.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }

        salaryString = cleaned
        let (minVal, maxVal) = JobViewModel.parseSalaryRangeStatic(cleaned)
        self.salaryMin = minVal
        self.salaryMax = maxVal
    }

    /// Static function for re-parsing older jobs as well
    static func parseSalaryRangeStatic(_ value: String) -> (Double?, Double?) {
        let trimmed = value.replacingOccurrences(of: "$", with: "")
        let parts = trimmed.components(separatedBy: "-")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        if parts.count == 2 {
            let minStr = parts[0]
            let maxStr = parts[1]
            let minVal = parseNumeric(minStr)
            let maxVal = parseNumeric(maxStr)
            return (minVal, maxVal)
        } else {
            // Single numeric
            let singleVal = parseNumeric(trimmed)
            return (singleVal, nil)
        }
    }

    private static func parseNumeric(_ string: String) -> Double? {
        // Remove commas and any stray spaces
        let stripped = string
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
        return Double(stripped)
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
            let skillsArray = skills
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
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
                   if !lastWasBlank {
                       cleanedLines.append("")
                   }
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
               // Check Desired Skills
               if detectedDesiredSkills == nil, lowerLine.contains("desired skills:") {
                   if let range = line.range(of: "Desired Skills:", options: .caseInsensitive) {
                       let value = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
                       detectedDesiredSkills = value.isEmpty ? nil : value
                   }
               }
               if detectedDesiredSkills == nil, lowerLine.contains("desired skill:") {
                   if let range = line.range(of: "Desired Skill:", options: .caseInsensitive) {
                       let value = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
                       detectedDesiredSkills = value.isEmpty ? nil : value
                   }
               }
               if detectedLocation == nil, lowerLine.contains("job location:") {
                   if let range = line.range(of: "Job Location:", options: .caseInsensitive) {
                       let value = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
                       detectedLocation = value.isEmpty ? nil : value
                   }
               }

           }

           if let lastLine = nonEmptyLines.last, detectedURL == nil {
               if lastLine.lowercased().contains("job url:") && lastLine.lowercased().contains("http") {
                   if let range = lastLine.range(of: "Job URL:", options: .caseInsensitive) {
                       let value = lastLine[range.upperBound...].trimmingCharacters(in: .whitespaces)
                       detectedURL = value.isEmpty ? nil : value
                   }
               } else if lastLine.lowercased().contains("http") {
                   detectedURL = lastLine.trimmingCharacters(in: .whitespaces)
               }
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




    func addJob(to store: JobStore, documents: [JobDocument]) {
        guard isInputValid else { return }
        let newJob = JobApplication(
            companyName: companyName,
            jobTitle: jobTitle,
            status: status,
            dateOfApplication: dateOfApplication,
            location: location,
            linkToJobString: linkToJob.isEmpty ? nil : linkToJob,
            salaryString: salaryString.isEmpty ? nil : salaryString,
            salaryMin: salaryMin,
            salaryMax: salaryMax,
            jobDescription: jobDescription,
            coverLetter: coverLetter,
            notes: notes.isEmpty ? nil : notes,
            documents: documents,
            isFavorite: false,
            jobType: jobType,
            desiredSkillNames: selectedDesiredSkills
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
            salaryString: salaryString.isEmpty ? nil : salaryString,
            salaryMin: salaryMin,
            salaryMax: salaryMax,
            jobDescription: jobDescription,
            coverLetter: coverLetter,
            notes: notes.isEmpty ? nil : notes,
            documents: documents,
            isFavorite: originalJob.isFavorite,
            jobType: jobType,
            desiredSkillNames: selectedDesiredSkills,
            jobDeadline: jobDeadline,
            crossJobSkillNames: originalJob.crossJobSkillNames
        )
        store.editJob(with: updatedJob)
        reset()
    }

    func reset() {
        companyName = ""
        jobTitle = ""
        status = .applied
        dateOfApplication = Date()
        location = ""
        linkToJob = ""
        jobDescription = ""
        coverLetter = ""
        notes = ""
        salaryString = ""
        salaryMin = nil
        salaryMax = nil
        jobType = .fullTime
        selectedDesiredSkills = []
        jobDeadline = nil
        validateInputs()
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
        let vc = NSHostingController(
            rootView: AddJobWindowView()
                .environmentObject(jobStore)
                .environmentObject(docStore)
        )
        let window = NSWindow(contentViewController: vc)
        window.title = ""
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask = [.titled, .closable, .resizable]
        window.makeKeyAndOrderFront(nil)
    }

    private func rowBackground(job: JobApplication) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(jobStore.selectedJobIDs.contains(job.id) ? Color.blue.opacity(0.5) : Color.clear)
            .padding(.horizontal, 4)
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
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            Spacer()
            Text(job.status.rawValue)
                .font(.caption)
                .padding(5)
                .background(
                    Capsule().fill(isSelected ? Color(.lightGray).opacity(0.33) : job.status.displayColor.opacity(0.2))
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

// --------------------------------------------------
// MARK: - Add & Edit Job Windows
// --------------------------------------------------
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

// --------------------------------------------------
// MARK: - AddJobView
// --------------------------------------------------
struct AddJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var isPresented: Bool

    @StateObject private var viewModel: JobViewModel = JobViewModel()
    @State private var importedDocuments: [JobDocument] = []
    @State private var isImporting = false
    @State private var locations: [String] = CityCoordinateDictionary.keys.sorted()
    @State private var showNewLocationWindow = false
    @State private var quickLookURL: URL? = nil

    @State private var windowRef: NSWindow?

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Company Name").font(.headline)
                    TextField("Company Name", text: $viewModel.companyName)
                        .textFieldStyle(.roundedBorder)
                        .background(.ultraThinMaterial.opacity(0.25))
                        .cornerRadius(8)
                        .onChange(of: viewModel.companyName) { _, _ in
                            viewModel.validateInputs()
                        }

                    Text("Job Title").font(.headline)
                    TextField("Job Title", text: $viewModel.jobTitle)
                        .textFieldStyle(.roundedBorder)
                        .background(.ultraThinMaterial.opacity(0.25))
                        .cornerRadius(8)
                        .onChange(of: viewModel.jobTitle) { _, _ in
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

                    Text("Salary").font(.headline)
                    TextField("Salary (e.g. $70,000 - $110,000)", text: $viewModel.salaryString)
                        .textFieldStyle(.roundedBorder)
                        .background(.ultraThinMaterial.opacity(0.25))
                        .cornerRadius(8)
                        .onChange(of: viewModel.salaryString) { _, v in
                            viewModel.updateSalary(fromString: v)
                        }

                    Text("Link to Job").font(.headline)
                    TextField("Link to Job", text: $viewModel.linkToJob)
                        .textFieldStyle(.roundedBorder)
                        .background(.ultraThinMaterial.opacity(0.25))
                        .cornerRadius(8)

                    Divider()
                    HStack {
                        Text("Documents").font(.headline)
                        
                        Spacer()
                        
                        // Updated button: remove the optional chaining
                        Button(action: {
                            // LinkedInInsights button in EditJobView
                            if viewModel.notes.isEmpty {
                                viewModel.notes = "LinkedIn Insights can be imported after saving the job application."
                            }
                        }) {
                            Label("LinkedIn Insights", systemImage: "chart.bar.fill")
                        }
                        .help("After creating the job, you can import LinkedIn Insights from the job detail view")
                    }
                    
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
                                    .contextMenu {
                                        Button("Delete Document", role: .destructive) {
                                            if let idx = importedDocuments.firstIndex(of: doc) {
                                                importedDocuments.remove(at: idx)
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

                    HStack {
                        Text("Job Description").font(.headline)
                        Button("Parse Salary") {
                            // Call the new parsing function to update salary fields
                            viewModel.parseSalaryFromJobDescription()
                        }
                        Button("Paste") {
                            if let clip = NSPasteboard.general.string(forType: .string) {
                                viewModel.jobDescription = clip
                                viewModel.parseSalaryFromJobDescription() // Parse salary after pasting description
                            }
                        }
                    }
                    TextEditor(text: $viewModel.jobDescription)
                        .modifier(UltraThinMaterialTextEditorStyle())
                        .frame(height: 180)
                        .onChange(of: viewModel.jobDescription) { _, _ in
                            //viewModel.parseSalaryFromDescription() // Parse salary on description change - No longer parse on every change to avoid over-parsing. Keep manual parse and paste parse
                        }


                    Text("Cover Letter").font(.headline)
                    TextEditor(text: $viewModel.coverLetter)
                        .modifier(UltraThinMaterialTextEditorStyle())
                        .frame(height: 120)

                    Text("Notes").font(.headline)
                    TextEditor(text: $viewModel.notes)
                        .modifier(UltraThinMaterialTextEditorStyle())
                        .frame(height: 80)

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
                            closeWindow()
                        }
                        Spacer()
                        Button("Save") {
                            viewModel.validateInputs()
                            if viewModel.isInputValid {
                                // Merge docs to global
                                docStore.mergeDocuments(importedDocuments)
                                // Attach job metadata
                                for i in 0..<importedDocuments.count {
                                    importedDocuments[i].associatedCompany = viewModel.companyName
                                    importedDocuments[i].associatedJobTitle = viewModel.jobTitle
                                    importedDocuments[i].associatedApplicationDate = viewModel.dateOfApplication
                                }
                                viewModel.addJob(to: jobStore, documents: importedDocuments)
                                closeWindow()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .disabled(!viewModel.isInputValid)
                    }
                    .padding(.bottom, 20)
                }
                .padding()
            }
        }
        .frame(minWidth: 450, minHeight: 600)
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
        .sheet(isPresented: $showNewLocationWindow) {
            NewLocationWindowView(
                locations: $locations,
                selectedLocation: $viewModel.location
            )
        }
        .onAppear {
            viewModel.updateSkillSuggestions(availableSkills: jobStore.availableSkills)
            //viewModel.parseSalaryFromDescription() // Parse salary when view appears - No longer parse on view appear to avoid over-parsing. Keep manual parse and paste parse
            if windowRef == nil {
                if let kWindow = NSApp.windows.first(where: { $0.isKeyWindow }) {
                    windowRef = kWindow
                }
            }
        }
        .quickLookPreview($quickLookURL)
    }

    private func closeWindow() {
        windowRef?.close()
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
        let toRemove = ["Position", "2024", "Cover Letter"]
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
        return cleanedName.trimmingCharacters(in: .whitespaces)
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
    @State private var isImporting = false
    @State private var locations: [String] = CityCoordinateDictionary.keys.sorted()
    @State private var showNewLocationWindow = false
    @State private var quickLookURL: URL? = nil

    @State private var windowRef: NSWindow?

    init(isPresented: Binding<Bool>, job: JobApplication) {
        self._isPresented = isPresented
        let vm = JobViewModel(job: job, availableSkills: [])
        _viewModel = StateObject(wrappedValue: vm)
        _importedDocuments = State(initialValue: job.documents)
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Company Name").font(.headline)
                    TextField("Company Name", text: $viewModel.companyName)
                        .textFieldStyle(.roundedBorder)
                        .background(.ultraThinMaterial.opacity(0.25))
                        .cornerRadius(8)
                        .onChange(of: viewModel.companyName) { _, _ in
                            viewModel.validateInputs()
                        }

                    Text("Job Title").font(.headline)
                    TextField("Job Title", text: $viewModel.jobTitle)
                        .textFieldStyle(.roundedBorder)
                        .background(.ultraThinMaterial.opacity(0.25))
                        .cornerRadius(8)
                        .onChange(of: viewModel.jobTitle) { _, _ in
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

                    Text("Salary").font(.headline)
                    TextField("Salary (e.g. $70,000 - $110,000)", text: $viewModel.salaryString)
                        .textFieldStyle(.roundedBorder)
                        .background(.ultraThinMaterial.opacity(0.25))
                        .cornerRadius(8)
                        .onChange(of: viewModel.salaryString) { _, v in
                            viewModel.updateSalary(fromString: v)
                        }

                    Text("Link to Job").font(.headline)
                    TextField("Link to Job", text: $viewModel.linkToJob)
                        .textFieldStyle(.roundedBorder)
                        .background(.ultraThinMaterial.opacity(0.25))
                        .cornerRadius(8)

                    Divider()
                    HStack {
                        Text("Documents").font(.headline)
                        
                        Spacer()
                        
                        // Updated button: remove the optional chaining
                        Button(action: {
                            // LinkedInInsights button in EditJobView
                            if viewModel.notes.isEmpty {
                                viewModel.notes = "LinkedIn Insights can be imported after saving the job application."
                            }
                        }) {
                            Label("LinkedIn Insights", systemImage: "chart.bar.fill")
                        }
                        .help("After saving the job, you can import LinkedIn Insights from the job detail view")
                    }
                    
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
                                    .contextMenu {
                                        Button("Delete Document", role: .destructive) {
                                            if let idx = importedDocuments.firstIndex(of: doc) {
                                                importedDocuments.remove(at: idx)
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

                    Text("Job Description").font(.headline)
                    TextEditor(text: $viewModel.jobDescription)
                        .modifier(UltraThinMaterialTextEditorStyle())
                        .frame(height: 150)
                        .onChange(of: viewModel.jobDescription) { _, _ in
                            //viewModel.parseSalaryFromDescription() // Parse salary on description change - No longer parse on every change to avoid over-parsing. Keep manual parse and paste parse
                        }

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

                    Divider()
                    HStack {
                        Button("Cancel") {
                            closeWindow()
                        }
                        Spacer()
                        Button("Save") {
                            if let original = jobStore.jobApplications.first(where: { $0.id == viewModelUpdateID }) {
                                docStore.mergeDocuments(importedDocuments)
                                for i in 0..<importedDocuments.count {
                                    importedDocuments[i].associatedCompany = viewModel.companyName
                                    importedDocuments[i].associatedJobTitle = viewModel.jobTitle
                                    importedDocuments[i].associatedApplicationDate = viewModel.dateOfApplication
                                }
                                viewModel.updateJob(with: original, in: jobStore, documents: importedDocuments)
                                closeWindow()
                            } else {
                                closeWindow()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .disabled(!viewModel.isInputValid)
                    }
                    .padding(.bottom, 20)
                }
                .padding()
            }
        }
        .frame(minWidth: 450, minHeight: 600)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf, .plainText, .rtf, .image],
            allowsMultipleSelection: true
        ) { result in
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
                print("Import error: \(error)")
            }
        }
        .sheet(isPresented: $showNewLocationWindow) {
            NewLocationWindowView(
                locations: $locations,
                selectedLocation: $viewModel.location
            )
        }
        .onAppear {
            viewModel.updateSkillSuggestions(availableSkills: jobStore.availableSkills)
            if windowRef == nil {
                if let kWindow = NSApp.windows.first(where: { $0.isKeyWindow }) {
                    windowRef = kWindow
                }
            }
        }
        .quickLookPreview($quickLookURL)
    }

    private func closeWindow() {
        windowRef?.close()
    }

    private var viewModelUpdateID: UUID? {
        jobStore.selectedJobIDs.first
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
        filename.replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespaces)
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

// --------------------------------------------------
// MARK: - UltraThinMaterialTextEditorStyle
// --------------------------------------------------
struct UltraThinMaterialTextEditorStyle: ViewModifier {
    func body(content: Content) -> some View {
         content
             .padding(8)
             .background(.ultraThinMaterial.opacity(0.25))
             .cornerRadius(8)
             .font(.system(size: 13))
             .foregroundColor(.primary)
    }
}

// --------------------------------------------------
// MARK: - NewLocationWindowView & NewLocationView
// --------------------------------------------------
import SwiftUI
import CoreLocation
import SwiftData

// --------------------------------------------------
// MARK: - NewLocationWindowView & NewLocationView
// --------------------------------------------------

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
        .frame(width: 350, height: 300)
    }
}

struct NewLocationView: View {
    @Binding var locations: [String]
    @Binding var selectedLocation: String
    @Binding var isPresented: Bool

    @State private var newLocationName: String = ""
    @State private var latitude: String = ""
    @State private var longitude: String = ""
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack {
            Text("Add a New Location")
                .font(.headline)

            TextField("Location Name", text: $newLocationName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 5)

            if !newLocationName.isEmpty {
                Button("Look Up") {
                    lookupCoordinates(for: newLocationName)
                }
                .padding(.bottom, 10)
            }

            TextField("Latitude", text: $latitude)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Longitude", text: $longitude)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                .padding()

                Button("Save Location") {
                    if !newLocationName.isEmpty, let lat = Double(latitude), let lon = Double(longitude) {
                        locations.append(newLocationName)
                        selectedLocation = newLocationName
                        saveLocation(name: newLocationName, latitude: lat, longitude: lon)
                        isPresented = false
                    }
                }
                .keyboardShortcut(.defaultAction)
                .padding()
            }
            Spacer()
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func lookupCoordinates(for city: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(city) { (placemarks, error) in
            if let placemark = placemarks?.first, let location = placemark.location {
                latitude = "\(location.coordinate.latitude)"
                longitude = "\(location.coordinate.longitude)"
            }
        }
    }

    private func saveLocation(name: String, latitude: Double, longitude: Double) {
        let newLocation = SavedLocation(name: name, latitude: latitude, longitude: longitude)
        modelContext.insert(newLocation)
        try? modelContext.save()
    }
}

// --------------------------------------------------
// MARK: - SwiftData Model for Location Persistence
// --------------------------------------------------

@Model
class SavedLocation {
    var id: UUID = UUID()
    var name: String
    var latitude: Double
    var longitude: Double

    init(name: String, latitude: Double, longitude: Double) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
}



// --------------------------------------------------
// MARK: - EnhancedStatsView
// --------------------------------------------------
import SwiftUI
import Charts
import MapKit

// --------------------------------------------------
// MARK: - EnhancedStatsView
// --------------------------------------------------
struct EnhancedStatsView: View {
    // Environment objects
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore

    // MARK: - State Variables

    // General selection/hover states
    @State private var selectedSalaryValue: Double?
    @State private var hoveredJobID: UUID? = nil         // For salary chart tooltip (from snippet one)
    @State private var hoveredPieJobID: UUID? = nil        // For pie chart hover (from snippet two)
    @State private var hoveredSalaryItemID: UUID? = nil    // Additional hover state (from snippet two)
    @State private var selectedSalaryItem: SalaryRangeItem? = nil

    // Year and time-range states
    @State private var selectedYear: Int = -1
    @State private var availableYears: [Int] = []
    @State private var selectedTimeRange: TimeRange = .month
    @AppStorage("StatsViewTimeRange") private var selectedTimeRangeRaw: String = TimeRange.month.rawValue

    // Data storage arrays
    @State private var cityPins: [CityPin] = []
    @State private var barLineData: [DailyApps] = []
    @State private var yearContributionData: [Contribution] = []
    @State private var appsContributionData: [Contribution] = []
    @State private var monthlyCityData: [MonthlyCityData] = []
    @State private var filteredMonthlyCityData: [MonthlyCityData] = []
    @State private var salaryRangeData: [SalaryRangeItem] = []

    // Selected chart dates
    @State private var barLineSelectedDate: Date? = nil
    @State private var yearChartSelectedDate: Date? = nil
    @State private var appsChartSelectedDate: Date? = nil

    // Map region
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 50)
    )

    // Time range options
    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case sixmonth = "Six Months"
        case year = "Year"
        var id: String { rawValue }
    }

    // --------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------
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
                HorizontalStackedBarChartIfAvailable(monthlyCityData: filteredMonthlyCityData)
                singleColumnVerticallyStackedBarChartSection
                top20CompaniesBarSection
                citiesByFrequencySection
                companiesByFrequencySection
                pieChartsSection
                Divider()
                salaryRangeChartSection
            }
            .padding()
        }
        .onAppear {
            setupViewOnAppear()
            asyncComputeBarLineData()
        }
        .onChange(of: selectedTimeRange) { _, _ in
            selectedTimeRangeRaw = selectedTimeRange.rawValue
            asyncComputeBarLineData()
        }
        .onChange(of: selectedYear) { _, _ in
            refreshYearDependentData()
        }
        .onChange(of: monthlyCityData) { _, _ in
            filterMonthlyCityDataForSelectedYear()
        }
    }

    // --------------------------------------------------
    // MARK: - Setup Methods
    // --------------------------------------------------
    private func setupViewOnAppear() {
        if let tr = TimeRange(rawValue: selectedTimeRangeRaw) {
            selectedTimeRange = tr
        } else {
            selectedTimeRange = .month
        }
        setupAvailableYears()
        refreshYearDependentData()
    }

    private func refreshYearDependentData() {
        asyncComputeCityPins()
        asyncComputeYearContribution()
        asyncComputeAppsContribution()
        asyncComputeMonthlyCityData()
        asyncComputeSalaryRangeData()
    }

    // --------------------------------------------------
    // MARK: - Async Data Computations
    // --------------------------------------------------
    private func asyncComputeCityPins() {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = buildCityPins()
            DispatchQueue.main.async {
                self.cityPins = result
            }
        }
    }

    private func asyncComputeYearContribution() {
        DispatchQueue.global(qos: .userInitiated).async {
            let data = buildYearContribution()
            DispatchQueue.main.async {
                self.yearContributionData = data
            }
        }
    }

    private func asyncComputeAppsContribution() {
        DispatchQueue.global(qos: .userInitiated).async {
            let data = buildAppsContribution()
            DispatchQueue.main.async {
                self.appsContributionData = data
            }
        }
    }

    private func asyncComputeBarLineData() {
        DispatchQueue.global(qos: .userInitiated).async {
            let data = buildBarLineData()
            DispatchQueue.main.async {
                self.barLineData = data
            }
        }
    }

    private func asyncComputeMonthlyCityData() {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = buildMonthlyCityData()
            DispatchQueue.main.async {
                self.monthlyCityData = result
                self.filterMonthlyCityDataForSelectedYear()
            }
        }
    }

    private func asyncComputeSalaryRangeData() {
        DispatchQueue.global(qos: .userInitiated).async {
            let data = buildSalaryRangeData()
            DispatchQueue.main.async {
                self.salaryRangeData = data
            }
        }
    }
    // -----------------------------
    // Time Range Picker
    // -----------------------------
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
    // --------------------------------------------------
    // MARK: - Data Building Methods
    // --------------------------------------------------
    private func buildCityPins() -> [CityPin] {
        var cityCount: [String: Int] = [:]
        for job in jobStore.jobApplications {
            cityCount[job.location, default: 0] += 1
        }
        return cityCount.map { (city, ct) in
            let coord = CityCoordinateDictionary[city]
                ?? CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795)
            return CityPin(city: city, coordinate: coord, count: ct)
        }
    }

    private func buildYearContribution() -> [Contribution] {
        guard !jobStore.jobApplications.isEmpty else {
            return []
        }
        let cal = Calendar.current
        let allDates = jobStore.jobApplications.map { $0.dateOfApplication }

        if selectedYear == -1 {
            guard let end = allDates.max() else {
                return []
            }
            let start = cal.date(byAdding: .month, value: -12, to: end) ?? end
            var contributionMap: [Date: Int] = [:]
            for job in jobStore.jobApplications {
                if job.dateOfApplication >= start && job.dateOfApplication <= end {
                    let day = cal.startOfDay(for: job.dateOfApplication)
                    contributionMap[day, default: 0] += 1
                }
            }
            var allDays: [Date] = []
            var day = cal.startOfDay(for: start)
            while day <= end {
                allDays.append(day)
                if let nxt = cal.date(byAdding: .day, value: 1, to: day) {
                    day = nxt
                } else { break }
            }
            return allDays.map { d in
                Contribution(date: d, count: contributionMap[d] ?? 0)
            }
        } else {
            guard let s = cal.date(from: DateComponents(year: selectedYear, month: 1, day: 1)),
                  let e = cal.date(from: DateComponents(year: selectedYear, month: 12, day: 31))
            else { return [] }
            var contributionMap: [Date: Int] = [:]
            for job in jobStore.jobApplications {
                if job.dateOfApplication >= s && job.dateOfApplication <= e {
                    let day = cal.startOfDay(for: job.dateOfApplication)
                    contributionMap[day, default: 0] += 1
                }
            }
            var allDays: [Date] = []
            var day = cal.startOfDay(for: s)
            while day <= e {
                allDays.append(day)
                if let nxt = cal.date(byAdding: .day, value: 1, to: day) {
                    day = nxt
                } else { break }
            }
            return allDays.map { d in
                Contribution(date: d, count: contributionMap[d] ?? 0)
            }
        }
    }

    private func buildAppsContribution() -> [Contribution] {
        let cal = Calendar.current
        let allDates = jobStore.jobApplications.map { $0.dateOfApplication }
        guard !allDates.isEmpty else { return [] }

        if selectedYear == -1 {
            guard let end = allDates.max() else { return [] }
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
                } else { break }
            }
            return allDays.map { d in
                Contribution(date: d, count: appsMap[d] ?? 0)
            }
        } else {
            guard let s = cal.date(from: DateComponents(year: selectedYear, month: 1, day: 1)),
                  let e = cal.date(from: DateComponents(year: selectedYear, month: 12, day: 31))
            else { return [] }
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
                } else { break }
            }
            return allDays.map { d in
                Contribution(date: d, count: appsMap[d] ?? 0)
            }
        }
    }

    private func buildBarLineData() -> [DailyApps] {
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
        guard let start = startDate else { return [] }
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
        return allDays.map { d in
            DailyApps(date: d, count: dailyMap[d] ?? 0)
        }
    }

    private func buildMonthlyCityData() -> [MonthlyCityData] {
        var results: [MonthlyCityData] = []
        let cal = Calendar.current

        for job in jobStore.jobApplications {
            let jobYear = cal.component(.year, from: job.dateOfApplication)
            if selectedYear != -1, jobYear != selectedYear { continue }
            let month = cal.component(.month, from: job.dateOfApplication)
            let monthKey = "\(cal.shortMonthSymbols[month - 1])"
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
        let final = grouped.map { $0.value }.sorted {
            let monthOrder = Calendar.current.shortMonthSymbols
            guard
                let idxA = monthOrder.firstIndex(of: $0.monthKey),
                let idxB = monthOrder.firstIndex(of: $1.monthKey)
            else { return false }
            return idxA < idxB
        }
        return final
    }

    private func filterMonthlyCityDataForSelectedYear() {
        let cal = Calendar.current
        if selectedYear == -1 {
            filteredMonthlyCityData = monthlyCityData
        } else {
            filteredMonthlyCityData = monthlyCityData.filter {
                cal.component(.year, from: $0.date) == selectedYear
            }
        }
    }

    private func buildSalaryRangeData() -> [SalaryRangeItem] {
        let cal = Calendar.current
        let filteredApps = jobStore.jobApplications.filter {
            selectedYear == -1 || cal.component(.year, from: $0.dateOfApplication) == selectedYear
        }
        let sortedApps = filteredApps.sorted { $0.dateOfApplication < $1.dateOfApplication }
        var result: [SalaryRangeItem] = []
        for (idx, app) in sortedApps.enumerated() {
            guard let minVal = app.salaryMin, minVal > 0,
                  let maxVal = app.salaryMax, maxVal > 0
            else { continue }
            let item = SalaryRangeItem(
                jobID: app.id,
                company: app.companyName,
                jobTitle: app.jobTitle,
                date: app.dateOfApplication,
                minSalary: minVal,
                maxSalary: maxVal,
                orderIndex: idx
            )
            result.append(item)
        }
        return result
    }

    private func setupAvailableYears() {
        let allDates = jobStore.jobApplications.map { $0.dateOfApplication }
        guard !allDates.isEmpty else {
            self.availableYears = []
            self.selectedYear = -1
            return
        }
        let cal = Calendar.current
        guard let minDate = allDates.min(), let maxDate = allDates.max() else { return }
        let minYear = cal.component(.year, from: minDate)
        let maxYear = cal.component(.year, from: maxDate)
        self.availableYears = minYear <= maxYear ? Array(minYear...maxYear) : []
        if !self.availableYears.contains(selectedYear) && selectedYear != -1 {
            self.selectedYear = -1
        }
    }

    // --------------------------------------------------
    // MARK: - Helper Functions for Frequency Lists
    // --------------------------------------------------
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

    private func yearFreqList() -> [(year: String, count: Int)] {
        var yearCounts: [String: Int] = [:]
        let cal = Calendar.current
        for job in jobStore.jobApplications {
            let yearString = String(cal.component(.year, from: job.dateOfApplication))
            yearCounts[yearString, default: 0] += 1
        }
        return yearCounts.map { (year: $0.key, count: $0.value) }.sorted { $0.year < $1.year }
    }

    private func computeAverage(for data: [DailyApps]) -> Double? {
        let nonZeroData = data.filter { $0.count > 0 }
        guard !nonZeroData.isEmpty else { return nil }
        let totalApplications = nonZeroData.reduce(0) { $0 + $1.count }
        return Double(totalApplications) / Double(nonZeroData.count)
    }

    private func weekday(for date: Date) -> Int {
        Calendar.current.component(.weekday, from: date)
    }

    private var chartColors: [Color] {
        [
            .green.opacity(0.2),
            .green.opacity(0.4),
            .green.opacity(0.6),
            .green.opacity(0.8),
            .green
        ]
    }

    // --------------------------------------------------
    // MARK: - View Sections
    // --------------------------------------------------

    // -----------------------------
    // Map Section
    // -----------------------------
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Applications Map")
                .font(.headline)

            Map {
                ForEach(cityPins) { cityPin in
                    Annotation(cityPin.city, coordinate: cityPin.coordinate) {
                        Circle()
                            .fill(Color.red.opacity(0.5))
                            .frame(
                                width: circleSize(for: cityPin.count),
                                height: circleSize(for: cityPin.count)
                            )
                            .overlay(
                                Text("\(cityPin.count)")
                                    .foregroundColor(.white)
                                    .font(.system(size: 10))
                            )
                    }
                }
            }
            .frame(height: 300)
            .cornerRadius(20)
        }
        .padding()
    }

    private func circleSize(for count: Int) -> CGFloat {
        let base: CGFloat = 5
        let scale: CGFloat = 10
        return log10(CGFloat(count) * base) * scale
    }

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
                        .background(job == jobStore.selectedJob ? Color.blue.opacity(0.2) : Color.white.opacity(0.1))
                        .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    // -----------------------------
    // Stats row
    // -----------------------------
    private var statsRowSection: some View {
        let total = jobStore.jobApplications.count
        let applied = jobStore.jobApplications.filter { $0.status == .applied }.count
        let interested = jobStore.jobApplications.filter { $0.status == .interested }.count
        let interviewed = jobStore.jobApplications.filter { $0.status == .interview }.count
        let distinctCities = Set(jobStore.jobApplications.map { $0.location }).count
        let topCompany = topCompanyName()
        let (topCityName, topCityCount) = topCity()
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


    // -----------------------------
    // Year Picker
    // -----------------------------
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
                        Text(verbatim: "\(yr)").tag(yr)
                    }
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
    }

    // -----------------------------
    // GitHub-Style Charts
    // -----------------------------
    private var githubChartsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("GitHub-Style Contribution Charts")
                .font(.headline)
                .padding(.bottom, 5)

            if #available(macOS 13.0, *) {
                VStack(alignment: .leading) {
                    Chart(yearContributionData) { item in
                        RectangleMark(
                            x: .value("WeekOfYear", item.date, unit: .weekOfYear),
                            y: .value("DayOfWeek", weekday(for: item.date))
                        )
                        .foregroundStyle(by: .value("Count", item.count))
                        .clipShape(RoundedRectangle(cornerRadius: 1))
                    }
                    .chartXSelection(value: $yearChartSelectedDate)
                    .chartForegroundStyleScale(range: Gradient(colors: chartColors))
                    .frame(height: 200)
                    .padding(.horizontal)
                    .overlay(alignment: .top) {
                        if let sel = yearChartSelectedDate {
                            let dayStr = sel.formatted(date: .abbreviated, time: .omitted)
                            let yearProgress = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: sel), to: Date()).day ?? 0
                            let percentage = Double(yearProgress) / 365.0 * 100

                            VStack {
                                Text(dayStr)
                                Text("\(String(format: "%.1f", percentage))% of year")
                            }
                            .padding(8)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                }

                VStack(alignment: .leading) {
                    Chart(appsContributionData) { item in
                        RectangleMark(
                            x: .value("WeekOfYear", item.date, unit: .weekOfYear),
                            y: .value("DayOfWeek", weekday(for: item.date))
                        )
                        .foregroundStyle(by: .value("Count", item.count))
                        .clipShape(RoundedRectangle(cornerRadius: 0.5))
                        .annotation(position: .overlay) {
                            if item.count > 0 {
                                Text("\(item.count)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .bold()
                            }
                        }
                    }
                    .chartXSelection(value: $appsChartSelectedDate)
                    .chartForegroundStyleScale(range: Gradient(colors: chartColors))
                    .frame(height: 200)
                    .padding(.horizontal)
                    .overlay(alignment: .top) {
                        if let sel = appsChartSelectedDate {
                            let dayStr = sel.formatted(date: .abbreviated, time: .omitted)
                            let c = appsContributionData.first(where: { $0.date == sel })?.count ?? 0
                            VStack {
                                Text(dayStr)
                                Text("\(c) applications")
                            }
                            .padding(8)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }




    // -----------------------------
    // Bar/Line Chart
    // -----------------------------
    private var barLineChartsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Applications Frequency (Last \(selectedTimeRange.rawValue))")
                .font(.headline)
                .padding(.bottom, 5)

            Chart {
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


    // -----------------------------
    // Single Column Stacked Chart
    // -----------------------------
    private var singleColumnVerticallyStackedBarChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Applications by City - Single Column Vertically Stacked Bar Chart")
                .font(.headline)
                .padding(.bottom, 5)
            if #available(macOS 13.0, *) {
                Chart(filteredMonthlyCityData) { item in
                    BarMark(
                        x: .value("Month", item.monthKey),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(by: .value("City", item.city))
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

    private var top20CompaniesBarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top 20 Companies by Application Frequency (All Years)")
                .font(.headline)
                .padding(.bottom, 5)

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

    private var citiesByFrequencySection: some View {
        let cityCounts = cityFreqList()
        return VStack(alignment: .leading) {
            Text("Cities by Frequency (All Years)")
                .font(.headline)
                .padding(.bottom, 5)
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
                .padding(.bottom, 5)

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


    // -----------------------------
    // Pie Charts Section
    // -----------------------------
    private var pieChartsSection: some View {
        let monthData = filteredMonthlyCityData.groupedByMonth
        let cityData = MonthlyCityData.groupByCity(filteredMonthlyCityData)
        let yearData = yearFreqList()
        let selectedYearText = selectedYear == -1 ? "All Years" : "\(selectedYear)"

        return PieChartsSectionView(
            monthlyData: monthData,
            cityData: cityData,
            yearData: yearData,
            selectedYearText: selectedYearText
        )
    }


    // Salary Range Chart Section with Tooltip
    private var salaryRangeChartSection: some View {
        VStack(alignment: .leading) {
            Text("Salary Ranges for Job Applications")
                .font(.headline)
                .padding(.bottom, 5)
            Chart(salaryRangeData) { item in
                BarMark(
                    xStart: .value("Min Salary", item.minSalary),
                    xEnd: .value("Max Salary", item.maxSalary),
                    y: .value("Application Order", item.orderIndex)
                )
                .foregroundStyle(.blue.opacity(0.7))
                .cornerRadius(4)
                if let selectedSalary = selectedSalaryValue,
                   (item.minSalary...item.maxSalary).contains(selectedSalary) {
                    PointMark(
                        x: .value("Selected Salary", selectedSalary),
                        y: .value("Application Order", item.orderIndex)
                    )
                    .foregroundStyle(.clear)
                    .annotation(
                        position: .top,
                        spacing: 4,
                        overflowResolution: .init(x: .fit, y: .disabled)
                    ) {
                        jobDetailTooltip(for: item)
                    }
                }
            }
            .chartXSelection(value: $selectedSalaryValue)
            .frame(minHeight: 400)
            .chartXAxis {
                AxisMarks(position: .bottom, values: .automatic) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .currency(code: "USD"))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel("Application \(value.index + 1)")
                }
            }
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func jobDetailTooltip(for item: SalaryRangeItem) -> some View {
        if let job = jobStore.jobApplications.first(where: { $0.id == item.jobID }) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.green.opacity(0.5))
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(job.companyName) - \(job.jobTitle)")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("💰 \(Int(item.minSalary)) - \(Int(item.maxSalary))")
                        .font(.body)
                        .foregroundColor(.yellow)
                }
                .padding(8)
            }
            .frame(maxWidth: 250)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.green.opacity(0.5))
                Text("Unknown job.")
                    .foregroundColor(.white)
            }
            .frame(maxWidth: 200)
        }
    }
}


// --------------------------------------------------
// MARK: - HorizontalStackedBarChartIfAvailable
// --------------------------------------------------
@available(macOS 13.0, *)
struct HorizontalStackedBarChartIfAvailable: View {
    let monthlyCityData: [MonthlyCityData]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Applications by City - Horizontally Stacked Bar Chart")
                .font(.headline)
                .padding(.bottom, 5)
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
            .frame(height: 300)
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
    @Binding var showSettings: Bool  // ✅ Accept as a Bindin
    @State private var windowRef: NSWindow?
    @State private var quickLookURL: URL? = nil
    @State private var showInsightsImporter = false
    @State private var linkedInInsightsData: LinkedInInsightsData?
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                CompanyHeaderView(job: job)
                StatusInfoView(job: job)
                DocumentsSectionView(job: job)
                SkillsSectionView(job: job)
                DescriptionSectionView(job: job)
                coverLetterSection
                notesSection
                
                // LinkedIn Insights Section
                if let insights = linkedInInsightsData {
                    Divider()
                    HStack {
                        Text("LinkedIn Insights")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Update Insights") {
                            showInsightsImporter = true
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    VisualizerView(data: insights)
                } else {
                    Divider()
                    HStack {
                        Text("LinkedIn Insights")
                            .font(.headline)
                            
                        Spacer()
                        
                        Button("Import Insights") {
                            showInsightsImporter = true
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Text("Import LinkedIn Insights to view detailed statistics about this company.")
                        .foregroundColor(.secondary)
                        .padding()
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
                Button {
                    showInsightsImporter = true
                } label: {
                    Label("LinkedIn Insights", systemImage: "chart.bar.fill")
                }
                Button {
                        showSettings = true
                } label: {
                    Label("Settings", systemImage: "gear")
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
            
            // Load LinkedIn insights from job notes if available
            if let notes = job.notes, notes.contains("LINKEDIN_INSIGHTS_DATA:") {
                do {
                    if let startIdx = notes.range(of: "LINKEDIN_INSIGHTS_DATA:")?.upperBound,
                       let endIdx = notes.range(of: ":END_LINKEDIN_INSIGHTS_DATA", range: startIdx..<notes.endIndex)?.lowerBound {
                        let jsonString = String(notes[startIdx..<endIdx])
                        if let jsonData = jsonString.data(using: .utf8) {
                            let decoder = JSONDecoder()
                            self.linkedInInsightsData = try decoder.decode(LinkedInInsightsData.self, from: jsonData)
                        }
                    }
                } catch {
                    print("Error decoding LinkedIn insights: \(error)")
                }
            }
        }
        .onChange(of: job.id) { _, _ in
            updateWindowTitle()
        }
        .quickLookPreview($quickLookURL)
        .fileImporter(
            isPresented: $showInsightsImporter,
            allowedContentTypes: [.html],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    do {
                        let html = try String(contentsOf: url, encoding: .utf8)
                        self.linkedInInsightsData = try extractData(from: html)
                        
                        // Save insights data to job notes
                        let encoder = JSONEncoder()
                        let jsonData = try encoder.encode(self.linkedInInsightsData)
                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                            var updatedNotes = job.notes ?? ""
                            
                            // Remove any existing insights data
                            if let startRange = updatedNotes.range(of: "LINKEDIN_INSIGHTS_DATA:"),
                               let endRange = updatedNotes.range(of: ":END_LINKEDIN_INSIGHTS_DATA", range: startRange.lowerBound..<updatedNotes.endIndex),
                               let endUpperBound = updatedNotes.index(endRange.upperBound, offsetBy: 0, limitedBy: updatedNotes.endIndex) {
                                updatedNotes.removeSubrange(startRange.lowerBound..<endUpperBound)
                            }
                            
                            // Add updated insights data
                            if !updatedNotes.isEmpty && !updatedNotes.hasSuffix("\n\n") {
                                updatedNotes += "\n\n"
                            }
                            updatedNotes += "LINKEDIN_INSIGHTS_DATA:\(jsonString):END_LINKEDIN_INSIGHTS_DATA"
                            
                            // Update job in store
                            var updatedJob = job
                            updatedJob.notes = updatedNotes
                            jobStore.editJob(with: updatedJob)
                        }
                    } catch {
                        print("Error processing HTML file: \(error)")
                    }
                }
            case .failure(let error):
                print("Error selecting file: \(error)")
            }
        }
    }

    private var coverLetterSection: some View {
        Group {
            if !job.coverLetter.isEmpty {
                Divider()
                Text("Cover Letter").font(.headline)
                // Use MarkdownUI
                Markdown(job.coverLetter)
            } else {
                Text("No cover letter required.").foregroundColor(.secondary)
            }
        }
    }

    
    
    // --------------------------------------------------
    // MARK: - notesSection (Unchanged, compiles fine)
    // --------------------------------------------------
    private var notesSection: some View {
        Group {
            Divider()
            Text("Notes").font(.headline)
            if let userNotes = job.notes, !userNotes.isEmpty {
                // Calculate filtered notes first
                let filteredNotes: String = {
                    if let startRange = userNotes.range(of: "LINKEDIN_INSIGHTS_DATA:"),
                       let endRange = userNotes.range(of: ":END_LINKEDIN_INSIGHTS_DATA", range: startRange.lowerBound..<userNotes.endIndex),
                       let endUpperBound = userNotes.index(endRange.upperBound, offsetBy: 0, limitedBy: userNotes.endIndex) {
                        let firstPart = userNotes[..<startRange.lowerBound]
                        let secondPart = userNotes[endUpperBound...]
                        return String(firstPart) + String(secondPart)
                    } else {
                        return userNotes
                    }
                }()
                
                // Then return the view based on filteredNotes
                if !filteredNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Markdown(filteredNotes)
                } else {
                    Text("No notes provided.").foregroundColor(.secondary)
                }
            } else {
                Text("No notes provided.").foregroundColor(.secondary)
            }
        }
    }

    
    

    private func showEditJobWindow() {
        let vc = NSHostingController(
            rootView: EditJobWindowView(job: job)
                .environmentObject(jobStore)
                .environmentObject(docStore)
        )
        let window = NSWindow(contentViewController: vc)
        window.title = "Edit Job"
        window.styleMask = [.titled, .closable, .resizable]
        window.makeKeyAndOrderFront(nil)
    }

    private func updateWindowTitle() {
        guard let w = windowRef else { return }
        w.title = "\(job.companyName) \(job.jobTitle)"
    }
}

// Subview: CompanyHeaderView
struct CompanyHeaderView: View {
    let job: JobApplication
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(job.companyName)
                .font(.largeTitle)
                .bold()
                .gradientForeground(colors: [.pink, .purple])
            Text(job.jobTitle)
                .font(.title2)
                .gradientForeground(colors: [.red, .orange])
        }
    }
}

// Subview: StatusInfoView with improved Salary display
struct StatusInfoView: View {
    @Environment(\.colorScheme) var colorScheme
    let job: JobApplication

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            rowItem("Status:", job.status.rawValue)
            rowItem("URL:", job.linkToJobString != nil ? "" : "No job link available") {
                if let link = job.linkToJobString, let url = URL(string: link) {
                    AnyView(Link("View Job Posting", destination: url).foregroundColor(.blue))
                } else {
                    AnyView(EmptyView())
                }
            }
            rowItem("Location:", job.location.isEmpty ? "No location specified" : job.location)
            rowItem("Applied on:", job.dateOfApplication.formatted(date: .abbreviated, time: .omitted))

            if let dl = job.jobDeadline {
                rowItem("Deadline:", dl.formatted(date: .abbreviated, time: .omitted), color: .red)
            }

            let displayedSalary: String = {
                if let sStr = job.salaryString, !sStr.isEmpty {
                    return sStr
                } else if let sMin = job.salaryMin {
                    if let sMax = job.salaryMax, sMax != sMin {
                        let minInt = Int(sMin)
                        let maxInt = Int(sMax)
                        if minInt < maxInt {
                            return "$\(minInt) - $\(maxInt)"
                        } else {
                            return "$\(minInt)"
                        }
                    } else {
                        let valInt = Int(sMin)
                        return "$\(valInt)"
                    }
                }
                return "Negotiable"
            }()
            rowItem("Salary:", displayedSalary)
        }
        .foregroundColor(colorScheme == .dark ? .white : .black)
    }

    private func rowItem(
        _ label: String,
        _ value: String,
        color: Color? = nil,
        content: (() -> AnyView)? = nil
    ) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .fontWeight(.semibold)
                .frame(width: 100, alignment: .leading)
                .padding(.leading, 20)
            if let builder = content {
                builder()
            } else {
                Text(value)
                    .foregroundColor(color ?? .primary)
            }
            Spacer()
        }
    }
}

// Subview: DocumentsSectionView
struct DocumentsSectionView: View {
    @EnvironmentObject var docStore: DocumentStore
    @State private var quickLookURL: URL? = nil
    let job: JobApplication

    var body: some View {
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
                            .gradientForeground(colors: [.blue, .purple])
                        }
                        .buttonStyle(.bordered)
                        .contextMenu {
                            Button("Delete Document", role: .destructive) {
                                docStore.deleteDocument(doc)
                            }
                            Button("Reveal in Finder") {
                                revealInFinder(doc)
                            }
                            Divider()
                            Button("Edit Metadata") {
                                docStore.beginEditMetadata(for: doc)
                            }
                        }
                    }
                }
            }
            .quickLookPreview($quickLookURL)
        }
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
        var cleanedName = filename
        cleanedName = cleanedName.replacingOccurrences(of: "_", with: " ")
        cleanedName = cleanedName.replacingOccurrences(of: "-", with: " ")
        cleanedName = cleanedName.replacingOccurrences(of: "\\d", with: "", options: .regularExpression)
        let toRemove = ["Position", "2024", "Cover Letter"]
        for removal in toRemove {
            cleanedName = cleanedName.replacingOccurrences(of: removal, with: "")
        }
        for ext in [".pdf", ".docx", ".pages", ".rtf", ".txt"] {
            if cleanedName.hasSuffix(ext) {
                cleanedName = String(cleanedName.dropLast(ext.count))
                break
            }
        }
        return cleanedName.trimmingCharacters(in: .whitespaces)
    }
}

// Subview: SkillsSectionView
struct SkillsSectionView: View {
    @EnvironmentObject var jobStore: JobStore
    let job: JobApplication

    var body: some View {
        if !job.desiredSkillNames.isEmpty {
            Divider()
            Text("Desired Skills").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(job.desiredSkillNames, id: \.self) { skillName in
                        let isCross = job.crossJobSkillNames.contains(skillName)
                        let gradientColors = isCross
                            ? [Color.pink.opacity(0.3), Color.purple.opacity(0.5)]
                            : [Color.orange.opacity(0.3), Color.pink.opacity(0.5)]
                        ZStack {
                            Text(skillName)
                                .padding(6)
                                .foregroundColor(.black)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: gradientColors),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }
}

// Subview: DescriptionSectionView
struct DescriptionSectionView: View {
    let job: JobApplication
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
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
            // Render Markdown using MarkdownUI
            Markdown(job.jobDescription)
                .markdownTheme(.basic)
                .background(Color(nsColor: .windowBackgroundColor))
                .markdownTextStyle(\.text){
                    FontSize(11)
                  }
        }

    }
}

// --------------------------------------------------
// MARK: - PDFInlineViewer
// --------------------------------------------------
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
        let currentData = nsView.document?.dataRepresentation() ?? Data()
        if currentData != fileData {
            nsView.document = PDFDocument(data: fileData)
        }
    }
}

// --------------------------------------------------
// MARK: - DocumentsSidebarView
// --------------------------------------------------
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
        let stringsToRemove = ["Position", "2024", "Cover Letter"]
        for stringToRemove in stringsToRemove {
            cleanedName = cleanedName.replacingOccurrences(of: stringToRemove, with: "")
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

// --------------------------------------------------
// MARK: - DocumentsMainView
// --------------------------------------------------
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
                            docStore.uploadDocumentsNonAsync(from: urls)
                        }
                    }
                    .buttonStyle(.borderedProminent)
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
        let stringsToRemove = ["Position", "2024", "Cover Letter"]
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

// --------------------------------------------------
// MARK: - DocumentInfoPopover
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
                if let c = doc.associatedCompany {
                    Text("Company: \(c)")
                }
                if let t = doc.associatedJobTitle {
                    Text("Job Title: \(t)")
                }
                if let d = doc.associatedApplicationDate {
                    Text("Applied On: \(d.formatted(date: .abbreviated, time: .omitted))")
                }

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

// --------------------------------------------------
// MARK: - Binding Extensions
// --------------------------------------------------
extension Binding where Value == String {
    init(_ source: Binding<Value?>, default defaultValue: String) {
        self.init(
            get: { source.wrappedValue ?? defaultValue },
            set: { newValue in
                source.wrappedValue = newValue.isEmpty ? nil : newValue
            }
        )
    }
}

extension Binding where Value == String? {
    func withDefault(_ defaultValue: String) -> Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? defaultValue },
            set: { self.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}

extension Binding where Value == Optional<Date> {
    init(_ source: Binding<Value>, default defaultValue: Date) {
        self.init(
            get: { source.wrappedValue ?? defaultValue },
            set: { newValue in
                source.wrappedValue = newValue
            }
        )
    }
}

// --------------------------------------------------
// MARK: - DocumentMetadataEditView
// --------------------------------------------------
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

            TextField("Associated Company", text: Binding($doc.associatedCompany, default: ""))
                .textFieldStyle(.roundedBorder)

            TextField("Associated Job Title", text: Binding($doc.associatedJobTitle, default: ""))
                .textFieldStyle(.roundedBorder)

            DatePicker(
                "Associated Application Date",
                selection: Binding<Date>(
                    get: { doc.associatedApplicationDate ?? Date() },
                    set: { date in
                        doc.associatedApplicationDate = date
                    }
                ),
                displayedComponents: .date
            )
            .environment(\.locale, Locale(identifier: "en_US"))

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Button("Save") {
                    if let idx = docStore.documents.firstIndex(where: { $0.id == doc.id }) {
                        docStore.documents[idx] = doc
                        docStore.saveDocuments()
                    }
                    presentationMode.wrappedValue.dismiss()
                    docStore.isEditingMetadata = false
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            .padding(.top, 12)
        }
        .padding()
        .frame(minWidth: 400)
    }
}

// --------------------------------------------------
// MARK: - PieChartsSectionView
// --------------------------------------------------
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

fileprivate struct AngleRangeItem {
    let key: String
    let range: Range<Double>
    let count: Int
}

// A Swift Charts “Pie” subview
struct PieChartView: View {
    let data: [(key: String, count: Int)]
    @Binding var selectedAngle: Double?
    let centerLabel: String
    var showLegend: Bool = false
    var legendPosition: AnnotationPosition = .automatic

    var body: some View {
        if #available(macOS 13.0, *) {
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
                        let count   = selItem?.count ?? data.reduce(0) { $0 + $1.count }

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
        } else {
            Text("Pie Chart requires macOS 13.0+")
                .foregroundColor(.secondary)
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

// Utility extension for grouping monthly city data
extension Array where Element == MonthlyCityData {
    var groupedByMonth: [(monthKey: String, count: Int)] {
        let grouped = Dictionary(grouping: self, by: { $0.monthKey })
        return grouped.map { key, values in
            (monthKey: key, count: values.reduce(0) { $0 + $1.count })
        }.sorted {
            (Calendar.current.shortMonthSymbols.firstIndex(of: $0.monthKey) ?? 0) <
            (Calendar.current.shortMonthSymbols.firstIndex(of: $1.monthKey) ?? 0)
        }
    }
}

extension MonthlyCityData {
    static func groupByCity(_ data: [MonthlyCityData]) -> [(city: String, count: Int)] {
        let grouped = Dictionary(grouping: data, by: { $0.city })
        return grouped.map { ($0.key, $0.value.reduce(0) { $0 + $1.count }) }
    }
}

// GradientForeground
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



// MARK: - LinkedInInsightsView


struct LinkedInInsightsView: View {
    let insightsData: LinkedInInsightsData
    @State private var selectedTab = 0
    @State private var chartHeight: CGFloat = 250

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("LinkedIn Insights: \(insightsData.companyName ?? "")")
                    .font(.headline)
                Spacer()
                if let importDate = insightsData.importDate {
                    Text("Imported: \(formatDate(importDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            TabView(selection: $selectedTab) {
                // Growth
                employeeGrowthView
                    .tabItem {
                        Label("Growth", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(0)
                // Composition
                compositionView
                    .tabItem {
                        Label("Composition", systemImage: "chart.pie")
                    }
                    .tag(1)
                // Hiring
                hiringView
                    .tabItem {
                        Label("Hiring", systemImage: "person.badge.plus")
                    }
                    .tag(2)
                // Jobs
                jobsView
                    .tabItem {
                        Label("Jobs", systemImage: "briefcase")
                    }
                    .tag(3)
            }
            .frame(height: 350)
            .padding(.vertical)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
    }

    private var employeeGrowthView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Employee Growth").font(.title3).bold()
            if !insightsData.employeeGrowth.isEmpty,
               insightsData.employeeGrowth.contains(where: { $0.date != nil }) {
                Chart {
                    ForEach(insightsData.employeeGrowth.filter { $0.date != nil }, id: \.id) { item in
                        if let dt = item.date {
                            LineMark(x: .value("Date", dt), y: .value("Employees", item.employeeCount))
                                .foregroundStyle(.blue)
                                .interpolationMethod(.catmullRom)
                            PointMark(x: .value("Date", dt), y: .value("Employees", item.employeeCount))
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: chartHeight)
            } else {
                Text("No employee growth data available").foregroundColor(.secondary)
            }
            if let totalEmp = insightsData.totalEmployees["total_employees"] {
                Text("Total Employees: \(totalEmp)").font(.headline)
            }
            if let median = insightsData.medianTenure {
                Text("Median Tenure: \(median)").font(.subheadline)
            }
        }
        .padding()
    }

    private var compositionView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Company Composition").font(.title3).bold()
            if !insightsData.functionDistribution.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach(insightsData.functionDistribution.sorted { $0.value > $1.value }, id: \.key) { (funcName, pct) in
                        HStack {
                            Text(funcName).lineLimit(1)
                            Spacer()
                            Text(pct).bold()
                        }.padding(.vertical, 4)
                    }
                }
            } else {
                Text("No composition data available").foregroundColor(.secondary)
            }
        }
        .padding()
    }

    private var hiringView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Hiring Trends").font(.title3).bold()
            if !insightsData.newHires.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(insightsData.newHires.sorted { $0.date > $1.date }) { hire in
                            HStack {
                                Text(hire.date).frame(width: 100, alignment: .leading)
                                Divider()
                                VStack(alignment: .leading) {
                                    if hire.seniorHires != "0" {
                                        Text("Senior: \(hire.seniorHires)").foregroundColor(.blue)
                                    }
                                    Text("Other: \(hire.otherHires)").foregroundColor(.green)
                                }
                            }
                            .padding(.vertical, 5)
                            Divider()
                        }
                    }
                }
            } else {
                Text("No hiring data available").foregroundColor(.secondary)
            }
        }
        .padding()
    }

    private var jobsView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Job Openings").font(.title3).bold()
            if !insightsData.jobOpenings.openingsDetails.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(insightsData.jobOpenings.openingsDetails) { detail in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(detail.function).font(.headline)
                                HStack {
                                    Text("Count: \(detail.numEmployees)")
                                    Spacer()
                                    Text("3m: \(detail.growth3m)")
                                    Spacer()
                                    Text("6m: \(detail.growth6m)")
                                }.font(.caption)
                            }
                            .padding(.vertical, 5)
                            Divider()
                        }
                    }
                }
            } else if !insightsData.jobOpeningsPlainText.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(insightsData.jobOpeningsPlainText) { detail in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(detail.function).font(.headline)
                                HStack {
                                    Text("Count: \(detail.numEmployees)")
                                    Spacer()
                                    Text("3m: \(detail.growth3m)")
                                    Spacer()
                                    Text("6m: \(detail.growth6m)")
                                }.font(.caption)
                            }
                            .padding(.vertical, 5)
                            Divider()
                        }
                    }
                }
            } else {
                Text("No job openings data available").foregroundColor(.secondary)
            }
        }
        .padding()
    }

    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: date)
    }
}


// --------------------------------------------------
// MARK: - LinkedIn Insights Import and Visualization

// Helper function to parse LinkedIn insights HTML files
func parseLinkedInInsights(from url: URL, completion: @escaping (Result<LinkedInInsightsData, Error>) -> Void) {
    do {
        // First, get security-scoped access to the file
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access the security scoped resource")
            completion(.failure(NSError(domain: "LinkedInInsightsParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to access the security scoped resource"])))
            return
        }
        
        // Read the HTML content and parse it
        let html = try String(contentsOf: url, encoding: .utf8)
        
        // Log the file path and size for debugging
        print("Successfully read HTML file: \(url.path)")
        print("HTML content size: \(html.count) characters")
        
        // Parse the data from the HTML string
        parseLinkedInInsightsFromHTML(html, completion: completion)
        
        // Stop accessing the security-scoped resource
        url.stopAccessingSecurityScopedResource()
    } catch {
        // Stop accessing in case of error
        url.stopAccessingSecurityScopedResource()
        print("Error processing HTML file: \(error)")
        completion(.failure(error))
    }
}

// Helper function to parse LinkedIn insights from HTML string
func parseLinkedInInsightsFromHTML(_ html: String, completion: @escaping (Result<LinkedInInsightsData, Error>) -> Void) {
    do {
        // Try to parse the data
        let data = try extractData(from: html)
        
        // Log successful parsing
        print("Successfully parsed LinkedIn insights data")
        print("Employee growth points: \(data.employeeGrowth.count)")
        print("Function distribution categories: \(data.functionDistribution.count)")
        if let totalEmployees = data.totalEmployees["total_employees"] {
            print("Total employees: \(totalEmployees)")
        }
        
        completion(.success(data))
    } catch {
        print("Error parsing LinkedIn insights: \(error)")
        completion(.failure(error))
    }
}

// A debug view that lets you input a sample HTML to test parsing
struct LinkedInInsightsDebugView: View {
    @State private var sampleHTML = "<!-- Paste LinkedIn Insights HTML here -->"
    @State private var parsedData: LinkedInInsightsData?
    @State private var errorMessage: String?
    @State private var isParsing = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("LinkedIn Insights HTML Debugger")
                .font(.title)
                .padding(.top)
            
            Text("Enter LinkedIn Insights HTML below:")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            TextEditor(text: $sampleHTML)
                .font(.system(.body, design: .monospaced))
                .frame(height: 200)
                .border(Color.gray, width: 1)
                .padding(.horizontal)
            
            Button(action: {
                errorMessage = nil
                parsedData = nil
                isParsing = true
                
                // Parse the HTML
                parseLinkedInInsightsFromHTML(sampleHTML) { result in
                    isParsing = false
                    switch result {
                    case .success(let data):
                        parsedData = data
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }) {
                Text("Parse HTML")
                    .frame(width: 150)
            }
            .buttonStyle(.borderedProminent)
            .disabled(sampleHTML.isEmpty || isParsing)
            
            if isParsing {
                ProgressView("Parsing...")
            } else if let errorMessage = errorMessage {
                VStack {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                }
            } else if let data = parsedData {
                VStack(alignment: .leading) {
                    Text("Parsing Successful!")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    if let totalEmployees = data.totalEmployees["total_employees"] {
                        Text("Total Employees: \(totalEmployees)")
                    }
                    
                    if !data.employeeGrowth.isEmpty {
                        Text("Employee Growth Data Points: \(data.employeeGrowth.count)")
                    }
                    
                    if !data.functionDistribution.isEmpty {
                        Text("Function Categories: \(data.functionDistribution.count)")
                    }
                    
                    HStack {
                        Spacer()
                        Button("View Visualizations") {
                            // Show visualizations
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }
                    .padding()
                }
                .padding()
                .background(Color(nsColor: .windowBackgroundColor))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

// Test view to verify LinkedIn Insights parsing
struct LinkedInInsightsTestView: View {
    @State private var isShowingFilePicker = false
    @State private var parsedData: LinkedInInsightsData?
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            Button("Import LinkedIn Insights HTML") {
                isShowingFilePicker = true
            }
            .buttonStyle(.bordered)
            .padding()
            
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }
            
            if let data = parsedData {
                Text("Data parsed successfully!")
                    .foregroundColor(.green)
                    .padding()
                
                ScrollView {
                    VisualizerView(data: data)
                        .padding()
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.html]
        ) { result in
            switch result {
            case .success(let url):
                errorMessage = nil
                parseLinkedInInsights(from: url) { parseResult in
                    switch parseResult {
                    case .success(let insightsData):
                        parsedData = insightsData
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
                
            case .failure(let error):
                errorMessage = "Failed to select file: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - LinkedIn Insights Visualization
// --------------------------------------------------

//
// MARK: - LinkedInInsights Visualization
// --------------------------------------------------

import SwiftUI
import Charts

// MARK: - Data Model Extension (Sample)
extension NewHire {
    var chartDate: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        return dateFormatter.date(from: date)
    }
}

// MARK: - Helper Function
private func cleanDuplicatedText(_ text: String) -> String {
    let patterns = [
        "([0-9]+%)[0-9]+% (increase|decrease)",
        "([0-9]+%) [0-9]+% (increase|decrease)"
    ]
    var result = text
    for pattern in patterns {
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let percentageRange = Range(match.range(at: 1), in: text),
           let typeRange = Range(match.range(at: 2), in: text) {
            let percentage = String(text[percentageRange])
            let type = String(text[typeRange])
            result = "\(percentage) \(type)"
        }
    }
    return result
}

// MARK: - Helper Views
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title2)
            .fontWeight(.bold)
            .padding(.top, 10)
    }
}

// MARK: - Chart Views
struct EmployeeGrowthChart: View {
    let employeeGrowth: [EmployeeGrowth]
    @State private var selectedDate: Date?
    @State private var scrollPosition: Date?
    
    private var visibleDomain: ClosedRange<Date> {
        if let start = validDataPoints.first?.date,
           let end = validDataPoints.last?.date {
            // View 6 months at a time by default
            let sixMonths = TimeInterval(60 * 60 * 24 * 30 * 6)
            if end.timeIntervalSince(start) > sixMonths {
                return (end.addingTimeInterval(-sixMonths))...end
            }
            return start...end
        }
        // Default range if we don't have data points
        let now = Date()
        let sixMonthsAgo = now.addingTimeInterval(-60 * 60 * 24 * 30 * 6)
        return sixMonthsAgo...now
    }

    private var validDataPoints: [EmployeeGrowth] {
        employeeGrowth.filter { $0.date != nil }.sorted { ($0.date ?? Date()) < ($1.date ?? Date()) }
    }

    private var yDomainRange: ClosedRange<Int> {
        if !validDataPoints.isEmpty,
           let minCount = validDataPoints.map({ $0.employeeCount }).min(),
           let maxCount = validDataPoints.map({ $0.employeeCount }).max() {
            let buffer = Double(maxCount - minCount) * 0.25
            let lowerBound = max(0, Int(Double(minCount) - buffer))
            let upperBound = Int(Double(maxCount) + buffer)
            return lowerBound...upperBound
        }
        return 0...100 // Default if no data
    }

    // Helper method to create line marks for data points
    @ChartContentBuilder
    private func chartLineMarks() -> some ChartContent {
        ForEach(validDataPoints, id: \.id) { item in
            if let itemDate = item.date {
                LineMark(
                    x: .value("Date", itemDate, unit: .day),
                    y: .value("Employee Count", item.employeeCount)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                .symbol {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                }
                .symbolSize(30)
                .interpolationMethod(.catmullRom)
            }
        }
    }
    
    // Helper method to create selection marks
    @ChartContentBuilder
    private func chartSelectionMarks() -> some ChartContent {
        if let selectedDate = selectedDate,
           let selectedItem = validDataPoints.first(where: {
               guard let itemDate = $0.date else { return false }
               return Calendar.current.isDate(itemDate, inSameDayAs: selectedDate)
           }) {
            
            RuleMark(
                x: .value("Selected", selectedDate)
            )
            .foregroundStyle(Color.gray.opacity(0.3))
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            .offset(yStart: -10)
            .zIndex(-1)
            .annotation(position: .top, spacing: 0,
                      overflowResolution: .init(
                          x: .fit(to: .chart),
                          y: .disabled
                      )) {
                AnnotationLabel(for: selectedItem)
            }
            
            PointMark(
                x: .value("Date", selectedDate),
                y: .value("Employee Count", selectedItem.employeeCount)
            )
            .foregroundStyle(Color(.systemRed))
            .symbolSize(100)
        }
    }
    
    // Helper method to create annotation label
    private func AnnotationLabel(for item: EmployeeGrowth) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(item.month) \(item.day), \(item.year ?? 2025)")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(item.employeeCount) employees")
                .font(.headline)
                .foregroundColor(.primary)
            if !item.growth.isEmpty {
                Text(item.growth)
                    .font(.caption)
                    .foregroundColor(item.growth.contains("increase") ? .green : .red)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(radius: 2)
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main chart - simplify by breaking down chart content into multiple parts
            Chart {
                // Base line chart
                chartLineMarks()
                
                // Selection marks - handle separately
                chartSelectionMarks()
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) {
                    AxisValueLabel(format: .dateTime.month().year())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisValueLabel()
                    AxisGridLine()
                }
            }
            .chartYScale(domain: yDomainRange)
            .chartXScale(domain: visibleDomain)
            .chartXSelection(value: $selectedDate)
            .frame(height: 300)
            .padding(.horizontal)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
            .cornerRadius(10)
            .chartGesture { proxy in
                DragGesture(minimumDistance: 0)
                    .onChanged { proxy.selectXValue(at: $0.location.x) }
                    .onEnded { _ in /* Keep selection */ }
            }

            if let selectedDate = selectedDate,
               let item = validDataPoints.first(where: { Calendar.current.isDate($0.date!, inSameDayAs: selectedDate) }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Date: \(item.month) \(item.day), \(item.year ?? 2025)")
                            .font(.subheadline)
                        Text("Employees: \(item.employeeCount)")
                            .font(.title3)
                            .bold()
                        if !item.growth.isEmpty {
                            Text("Growth: \(item.growth)")
                                .foregroundColor(item.growth.contains("increase") ? .green : .red)
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .windowBackgroundColor).opacity(0.5)))
                .padding([.horizontal, .bottom])
            }
        }
    }
}

// MARK: - UPDATED FunctionDistributionChart
struct FunctionDistributionChart: View {
    let distribution: [String: String]
    @State private var selectedCategory: String?
    @State private var selectedAngle: Double?
    
    private var topFunction: String {
        chartData.first?.key ?? "Unknown"
    }

    private var chartData: [(key: String, value: Double)] {
        // Break into multiple steps
        let parsedValues = distribution.compactMap { key, valueStr -> (String, Double)? in
            if let value = Double(valueStr.replacingOccurrences(of: "%", with: "")) {
                return (key, value)
            }
            return nil
        }
        return parsedValues.sorted { $0.1 > $1.1 }
    }

    // Helper to create bar chart marks
    @ChartContentBuilder
    private func makeBarChartContent() -> some ChartContent {
        ForEach(chartData, id: \.key) { item in
            let itemKey = item.key
            let itemValue = item.value
            let isSelected = selectedCategory == nil || itemKey == selectedCategory
            
            BarMark(
                x: .value("Function", itemKey),
                y: .value("Percentage", itemValue)
            )
            .cornerRadius(6)
            .foregroundStyle(by: .value("Function", itemKey))
            .opacity(isSelected ? 1.0 : 0.3)
            .annotation(position: .top) {
                if itemKey == selectedCategory {
                    let percentage = Int(itemValue)
                    let text = "\(percentage)%"
                    
                    Text(text)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(nsColor: .windowBackgroundColor))
                                .shadow(radius: 1)
                        )
                }
            }
        }
    }
    
    // Extract bar chart view to a separate function
    @ViewBuilder
    private func barChartView() -> some View {
        VStack(spacing: 10) {
            Text("Function Distribution (Bar Chart)")
                .font(.headline)
            
            Chart {
                makeBarChartContent()
            }
            .chartXSelection(value: $selectedCategory)
            .chartXAxis {
                AxisMarks {
                    AxisValueLabel()
                        .font(.system(size: 10))
                }
            }
            .chartYAxis {
                AxisMarks {
                    AxisValueLabel()
                    AxisGridLine()
                }
            }
            .chartYScale(domain: 0...100)
            .frame(height: 300)
            .chartGesture { proxy in
                DragGesture(minimumDistance: 0)
                    .onChanged { proxy.selectXValue(at: $0.location.x) }
                    .onEnded { _ in /* Keep selection */ }
            }
        }
        .padding(.horizontal)
    }
    
    // Create individual bar marks
    @ViewBuilder
    private func makeBarMarks() -> some View {
        Chart {
            ForEach(chartData, id: \.key) { item in
                BarMark(
                    x: .value("Function", item.key),
                    y: .value("Percentage", item.value)
                )
                .cornerRadius(6)
                .foregroundStyle(by: .value("Function", item.key))
                .opacity(selectedCategory == nil || item.key == selectedCategory ? 1 : 0.3)
                
                if item.key == selectedCategory {
                    RuleMark(y: .value("Selected", item.value))
                        .foregroundStyle(.secondary)
                        .annotation(position: .top) {
                            Text("\(Int(item.value))%")
                                .font(.caption)
                                .padding(4)
                                .background(Color(nsColor: .windowBackgroundColor))
                                .cornerRadius(4)
                                .shadow(radius: 1)
                        }
                }
            }
        }
    }
    // Pie chart mark generator
    // MARK: - Pie Chart Content
    @State private var hoveredSector: String?

    @ChartContentBuilder
    private func makePieChartContent() -> some ChartContent {
        ForEach(chartData, id: \.key) { item in
            let isHovered = hoveredSector == nil || item.key == hoveredSector
            SectorMark(
                angle: .value("Percentage", item.value),
                innerRadius: .ratio(0.6),
                angularInset: 1
            )
            .cornerRadius(8)
            .foregroundStyle(by: .value("Function", item.key))
            .opacity(isHovered ? 1.0 : 0.3)
        }
    }

    // MARK: - Pie Chart View
    @ViewBuilder
    private func pieChartView() -> some View {
        VStack(spacing: 10) {
            Text("Function Distribution")
                .font(.headline)

            Chart {
                makePieChartContent()
            }
            .chartAngleSelection(value: $hoveredSector)
            .chartLegend(position: .bottom)
            .frame(height: 320)
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if let plotFrame = chartProxy.plotFrame {
                        let frame = geometry[plotFrame]
                        VStack(spacing: 4) {
                            if let hoveredSector = hoveredSector,
                               let hoveredItem = chartData.first(where: { $0.key == hoveredSector }) {
                                Text(hoveredSector)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .frame(maxWidth: 120)
                                Text(hoveredItem.value.formatted(.percent.precision(.fractionLength(0))))
                                    .font(.title2.bold())
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Total")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("100%")
                                    .font(.title2.bold())
                                    .foregroundColor(.secondary)
                            }
                        }
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
            }
        }
        .padding(.horizontal)
    }


    // Stacked bar mark generator
    @ChartContentBuilder
    private func makeStackedBarContent() -> some ChartContent {
        ForEach(chartData, id: \.key) { item in
            BarMark(
                x: .value("Percentage", item.value),
                stacking: .normalized
            )
            .foregroundStyle(by: .value("Function", item.key))
        }
    }

    // Stacked bar view
    @ViewBuilder
    private func stackedBarView() -> some View {
        VStack(spacing: 10) {
            Text("Function Distribution (Normalized)")
                .font(.headline)
            Chart {
                makeStackedBarContent()
            }
            .chartXAxis(.hidden)
            .chartLegend(position: .bottom)
            .frame(height: 300)
        }
        .padding(.horizontal)
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView {
                barChartView()
                pieChartView()
                stackedBarView()
            }
            .tabViewStyle(.automatic)
            .frame(height: 350)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
            .cornerRadius(10)

            if let category = selectedCategory,
               let value = distribution[category]?.replacingOccurrences(of: "%", with: "") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Function: \(category)").font(.headline)
                        Text("Percentage: \(value)%").font(.subheadline)
                    }
                    Spacer()
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .windowBackgroundColor).opacity(0.5)))
                .padding([.horizontal, .bottom])
            }
        }
    }
}

// MARK: - UPDATED NewHiresChart
struct NewHiresChart: View {
    let newHires: [NewHire]
    @State private var selectedDate: Date?
    @State private var selectedRange: ClosedRange<Date>?
    @State private var scrollPosition: Date?
    
    private var visibleDomain: ClosedRange<Date>? {
        guard let _ = validHires.first?.chartDate,
              let last = validHires.last?.chartDate else {
            return nil
        }
        
        // Calculate 6 months before the last date
        let sixMonthsInSeconds: TimeInterval = -60 * 60 * 24 * 30 * 6
        let startDate = last.addingTimeInterval(sixMonthsInSeconds)
        
        let defaultRange = startDate...last
        return selectedRange ?? defaultRange
    }

    private var validHires: [NewHire] {
        newHires.filter {
            if let senior = Int($0.seniorHires), let other = Int($0.otherHires) {
                return $0.chartDate != nil && (senior > 0 || other > 0)
            }
            return false
        }.sorted { ($0.chartDate ?? Date()) < ($1.chartDate ?? Date()) }
    }

    // MARK: - Trend Line Content
    @ChartContentBuilder
    private func makeSeniorHiresMarks() -> some ChartContent {
        ForEach(validHires.filter { Int($0.seniorHires) != nil && $0.chartDate != nil }, id: \.id) { hire in
            if let senior = Int(hire.seniorHires), let date = hire.chartDate {
                LineMark(
                    x: .value("Date", date, unit: .month),
                    y: .value("Senior Hires", senior)
                )
                .foregroundStyle(Color.orange)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                .interpolationMethod(.catmullRom)
                .symbol {
                    Circle()
                        .strokeBorder(Color.orange, lineWidth: 2)
                        .frame(width: 10, height: 10)
                }
            }
        }
    }

    @ChartContentBuilder
    private func makeOtherHiresMarks() -> some ChartContent {
        ForEach(validHires.filter { Int($0.otherHires) != nil && $0.chartDate != nil }, id: \.id) { hire in
            if let other = Int(hire.otherHires), let date = hire.chartDate {
                LineMark(
                    x: .value("Date", date, unit: .month),
                    y: .value("Other Hires", other)
                )
                .foregroundStyle(Color.green)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                .interpolationMethod(.catmullRom)
                .symbol {
                    Rectangle()
                        .strokeBorder(Color.green, lineWidth: 2)
                        .frame(width: 10, height: 10)
                }
            }
        }
    }

    @ViewBuilder
    private func trendLineChartView() -> some View {
        VStack(spacing: 10) {
            Text("Cumulative Hiring Trend")
                .font(.headline)

            Chart {
                makeSeniorHiresMarks()
                makeOtherHiresMarks()
            }
            .chartForegroundStyleScale([
                "Senior Hires": Color.orange,
                "Other Hires": Color.green
            ])
            .chartLegend(position: .top)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) {
                    AxisValueLabel(format: .dateTime.month().year())
                }
            }
            .chartYAxis {
                AxisMarks {
                    AxisValueLabel()
                    AxisGridLine()
                }
            }
        }
        .frame(height: 350)
    }

    // MARK: - Interactive Bar Content
    @ChartContentBuilder
    private func makeBarChartMarks() -> some ChartContent {
        ForEach(validHires.filter {
            Int($0.seniorHires) != nil && Int($0.otherHires) != nil && $0.chartDate != nil
        }, id: \.id) { hire in
            if let senior = Int(hire.seniorHires),
               let other = Int(hire.otherHires),
               let date = hire.chartDate {
                BarMark(
                    x: .value("Date", date, unit: .month),
                    y: .value("Senior Hires", senior)
                )
                .position(by: .value("Type", "Senior"))
                .foregroundStyle(Color.orange)
                .cornerRadius(6)
                
                BarMark(
                    x: .value("Date", date, unit: .month),
                    y: .value("Other Hires", other)
                )
                .position(by: .value("Type", "Other"))
                .foregroundStyle(Color.green)
                .cornerRadius(6)
            }
        }
    }
    
    // Helper function to create selection annotations
    // Instead of defining a View Builder, we'll use this in the chart directly

    // Helper function for selection rule
    @ChartContentBuilder
    private func makeSelectionRule() -> some ChartContent {
        if let selectedDate = selectedDate,
           let hire = validHires.first(where: {
               guard let hireDate = $0.chartDate else { return false }
               return Calendar.current.isDate(hireDate, equalTo: selectedDate, toGranularity: .month)
           }),
           let date = hire.chartDate {
            RuleMark(
                x: .value("Selected", date)
            )
            .foregroundStyle(Color.gray.opacity(0.3))
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            .offset(yStart: -10)
            .zIndex(-1)
            .annotation(position: .top) {
                hiresAnnotation(for: hire)
            }
        }
    }

    // Helper function for annotation
    private func hiresAnnotation(for hire: NewHire) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(hire.date)")
                .font(.caption)
                .foregroundColor(.secondary)
            if let senior = Int(hire.seniorHires) {
                HStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text("Senior: \(senior)")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            if let other = Int(hire.otherHires) {
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Other: \(other)")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            if let senior = Int(hire.seniorHires), let other = Int(hire.otherHires) {
                Text("Total: \(senior + other)")
                    .font(.caption.bold())
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(radius: 2)
        )
    }

    // Creates the interactive bar chart view
    @ViewBuilder
    private func interactiveBarChartView() -> some View {
        VStack(spacing: 10) {
            Text("New Hires By Month (Interactive)")
                .font(.headline)
            Chart {
                makeBarChartMarks()
                makeSelectionRule()
            }
            // Configure chart styling and behavior
            .chartForegroundStyleScale(["Senior": Color.orange, "Other": Color.green])
            .chartLegend(position: .top) {
                HStack(spacing: 20) {
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange)
                            .frame(width: 12, height: 12)
                        Text("Senior Hires").font(.caption)
                    }
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                        Text("Other Hires").font(.caption)
                    }
                }
                .padding(.horizontal)
            }
            .chartXSelection(value: $selectedDate)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) {
                    AxisValueLabel(format: .dateTime.month().year())
                }
            }
            .chartYAxis {
                AxisMarks {
                    AxisValueLabel()
                    AxisGridLine()
                }
            }
            .frame(height: 300)
        }
        .frame(height: 350)
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView {
                interactiveBarChartView().tag(0)
                trendLineChartView().tag(1)
            }
            .tabViewStyle(.automatic)
            .frame(height: 400)
            .padding(.horizontal)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
            .cornerRadius(10)

            if let selectedDate = selectedDate,
               let hire = validHires.first(where: {
                   guard let hireDate = $0.chartDate else { return false }
                   return Calendar.current.isDate(hireDate, equalTo: selectedDate, toGranularity: .month)
               }) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Date: \(hire.date)").font(.subheadline)
                        if let senior = Int(hire.seniorHires) {
                            HStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.orange)
                                    .frame(width: 12, height: 12)
                                Text("Senior Hires: \(senior)")
                                    .font(.subheadline)
                                    .bold()
                            }
                        }
                        if let other = Int(hire.otherHires) {
                            HStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.green)
                                    .frame(width: 12, height: 12)
                                Text("Other Hires: \(other)")
                                    .font(.subheadline)
                                    .bold()
                            }
                        }
                        if let senior = Int(hire.seniorHires), let other = Int(hire.otherHires) {
                            Text("Total: \(senior + other)")
                                .font(.headline)
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .windowBackgroundColor).opacity(0.5)))
                .padding([.horizontal, .bottom])
            }
        }
    }
}

// MARK: - Table Views
struct HeadcountGrowthTable: View {
    let headcountGrowth: [HeadcountGrowth]
    @State private var sortOrder: [KeyPathComparator<HeadcountGrowth>] = [.init(\.function, order: .forward)]

    private func growthTrend(_ growth: String) -> String {
        if growth.lowercased().contains("increase") { return "↑" }
        else if growth.lowercased().contains("decrease") { return "↓" }
        else { return "−" }
    }

    private var functionDistribution: [String: Double] {
        var distribution: [String: Double] = [:]
        let total = headcountGrowth.reduce(0) { sum, item in
            if let empCount = Int(item.numEmployees.replacingOccurrences(of: ",", with: "")) {
                return sum + empCount
            }
            return sum
        }
        for item in headcountGrowth {
            if let empCount = Int(item.numEmployees.replacingOccurrences(of: ",", with: "")) {
                distribution[item.function] = Double(empCount) / Double(total) * 100.0
            }
        }
        return distribution
    }

    var body: some View {
        VStack(spacing: 20) {
            if !functionDistribution.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Function Distribution (Current)").font(.headline)
                    Chart {
                        ForEach(functionDistribution.sorted(by: { $0.value > $1.value }), id: \.key) { item in
                            SectorMark(angle: .value("Percentage", item.value), innerRadius: .ratio(0.5), angularInset: 1)
                                .cornerRadius(4)
                                .foregroundStyle(by: .value("Function", item.key))
                        }
                    }
                    .frame(height: 250)
                    .chartLegend(position: .bottom)
                }
                .padding()
                .background(Color(nsColor: .windowBackgroundColor).opacity(0.3))
                .cornerRadius(10)
            }
            Table(headcountGrowth, sortOrder: $sortOrder) {
                TableColumn("Function", value: \.function) { item in
                    Text(item.function).lineLimit(2)
                }.width(min: 150)
                TableColumn("Employees", value: \.numEmployees) { item in
                    Text(item.numEmployees)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }.width(min: 100)
                TableColumn("6m Growth") { item in
                    HStack(spacing: 4) {
                        let isIncrease = item.growth6m.lowercased().contains("increase")
                        let isDecrease = item.growth6m.lowercased().contains("decrease")
                        let trendColor: Color = isIncrease ? .green : (isDecrease ? .red : .gray)
                        Text(growthTrend(item.growth6m))
                            .font(.caption)
                            .foregroundColor(trendColor)
                        Text(cleanDuplicatedText(item.growth6m))
                            .foregroundColor(isIncrease ? .green : (isDecrease ? .red : .primary))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }.width(min: 120)
                TableColumn("6m Added") { item in
                    Text(item.added6m != nil ? (item.added6m! > 0 ? "+\(item.added6m!)" : "\(item.added6m!)") : "N/A")
                        .foregroundColor(item.added6m != nil && item.added6m! > 0 ? .green : item.added6m != nil && item.added6m! < 0 ? .red : .primary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }.width(min: 100)
                TableColumn("1y Growth") { item in
                    HStack(spacing: 4) {
                        Text(growthTrend(item.growth1y))
                            .font(.caption)
                            .foregroundColor(item.growth1y.lowercased().contains("increase") ? .green : item.growth1y.lowercased().contains("decrease") ? .red : .gray)
                        Text(cleanDuplicatedText(item.growth1y))
                            .foregroundColor(item.growth1y.lowercased().contains("increase") ? .green : item.growth1y.lowercased().contains("decrease") ? .red : .primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }.width(min: 120)
                TableColumn("1y Added") { item in
                    Text(item.added1y != nil ? (item.added1y! > 0 ? "+\(item.added1y!)" : "\(item.added1y!)") : "N/A")
                        .foregroundColor(item.added1y != nil && item.added1y! > 0 ? .green : item.added1y != nil && item.added1y! < 0 ? .red : .primary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }.width(min: 100)
            }
            .tableStyle(.inset(alternatesRowBackgrounds: true))
            .frame(height: CGFloat(min(headcountGrowth.count * 45 + 40, 350)))
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3), lineWidth: 1))
            .font(.subheadline)
            .foregroundStyle(.primary)
            .headerProminence(.increased)
        }
    }
}

// MARK: - UPDATED JobOpeningsDetailsTable
struct JobOpeningsDetailsTable: View {
    let details: [JobOpeningDetail]
    @State private var selectedFunction: String?
    @State private var totalOpenings: Int = 0
    @State private var sortOrder = [KeyPathComparator(\JobOpeningDetail.function)]
    @State private var hoveredSector: String? = nil

    private var distributionData: [String: Double] {
        var data: [String: Double] = [:]
        var total = 0
        guard !details.isEmpty else { return data }
        for detail in details {
            if let count = Int(detail.numEmployees.replacingOccurrences(of: ",", with: "")) {
                total += count
            }
            if let percentage = Double(detail.percentage.replacingOccurrences(of: "%", with: "")) {
                data[detail.function] = percentage
            }
        }
        DispatchQueue.main.async {
            self.totalOpenings = total
        }
        return data
    }

    var body: some View {
        VStack(spacing: 20) {
            if !distributionData.isEmpty {
                JobOpeningsDistributionChart(
                    distributionData: distributionData,
                    totalOpenings: totalOpenings,
                    details: details
                )
            }
            JobOpeningsDetailsTableView(details: details)
        }
    }
}

struct JobOpeningsDistributionChart: View {
    let distributionData: [String: Double]
    let totalOpenings: Int
    let details: [JobOpeningDetail]
    @State private var hoveredSector: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Job Openings Distribution")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.horizontal)

            Chart {
                ForEach(distributionData.sorted(by: { $0.value > $1.value }), id: \.key) { item in
                    SectorMark(
                        angle: .value("Percentage", item.value),
                        innerRadius: .ratio(0.65),
                        angularInset: 4
                    )
                    .cornerRadius(5)
                    .foregroundStyle(by: .value("Function", item.key))
                    .opacity(hoveredSector == nil || hoveredSector == item.key ? 1 : 0.7)
                }

                PointMark(
                    x: .value("center", 0),
                    y: .value("center", 0)
                )
                .annotation(position: .overlay) {
                    if let hoveredSector = hoveredSector,
                       let hoveredItem = distributionData.first(where: { $0.key == hoveredSector }) {
                        VStack(spacing: 4) {
                            Text(hoveredSector)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .frame(maxWidth: 120)
                            Text(hoveredItem.value.formatted(.percent.precision(.fractionLength(0))))
                                .font(.title2.bold())
                                .foregroundColor(.secondary)
                            if let detail = details.first(where: { $0.function == hoveredSector }) {
                                Text(detail.numEmployees)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    } else {
                        VStack(spacing: 4) {
                            Text("Total")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("\(totalOpenings)")
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                            Text("Openings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartLegend(position: .bottom, alignment: .center, spacing: 8)
            .chartAngleSelection(value: $hoveredSector)
            .frame(height: 250)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.background)
                .shadow(radius: 3)
        )
                .padding(.bottom)
    }
}

struct JobOpeningsDetailsTableView: View {
    let details: [JobOpeningDetail]
    @State private var sortOrder = [KeyPathComparator(\JobOpeningDetail.function)]

    private var sortedDetails: [JobOpeningDetail] {
        return details.sorted(using: sortOrder)
    }

            // Proper Table implementation with sortable columns and alternating rows
    var body: some View {
        Table(sortedDetails, sortOrder: $sortOrder) {
            TableColumn("Function", value: \.function) { item in
                Text(item.function)
                    .lineLimit(2)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
            }
            .width(min: 150)

            TableColumn("Job Openings", value: \.numEmployees) { item in
                Text(item.numEmployees)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
            }
            .width(min: 80)

            TableColumn("Share (%)", value: \.percentage) { item in
                Text(item.percentage)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
            }
            .width(min: 100)

            TableColumn("3m Growth") { item in
                Text(cleanDuplicatedText(item.growth3m))
                    .foregroundColor(
                        item.growth3m.contains("increase")
                            ? .green
                            : item.growth3m.contains("decrease")
                            ? .red
                            : .primary
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
            }
            .width(min: 120)

            TableColumn("6m Growth") { item in
                Text(cleanDuplicatedText(item.growth6m))
                    .foregroundColor(
                        item.growth6m.contains("increase")
                            ? .green
                            : item.growth6m.contains("decrease")
                            ? .red
                            : .primary
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
            }
            .width(min: 120)
        }
        .alternatingRowBackgrounds(.enabled)
        .font(.subheadline)
        .foregroundStyle(.primary)
        .frame(minHeight: min(CGFloat(details.count * 44 + 44), 400))
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.background)
                .shadow(radius: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .padding()
    }
}

struct JobOpeningsGrowthTable: View {
    let growth: [JobOpeningGrowth]
    @State private var sortOrder: [KeyPathComparator<JobOpeningGrowth>] = [.init(\.function, order: .forward)]

    private func growthTrend(_ growth: String) -> String {
        if growth.lowercased().contains("increase") { return "↑" }
        else if growth.lowercased().contains("decrease") { return "↓" }
        else { return "−" }
    }

    var body: some View {
        Table(growth, sortOrder: $sortOrder) {
            TableColumn("Function", value: \.function) { item in
                Text(item.function).lineLimit(2)
            }.width(min: 150)
            TableColumn("3m Growth") { item in
                HStack(spacing: 4) {
                    Text(growthTrend(item.growth3m))
                        .font(.caption)
                        .foregroundColor(item.growth3m.lowercased().contains("increase") ? .green : item.growth3m.lowercased().contains("decrease") ? .red : .gray)
                    Text(cleanDuplicatedText(item.growth3m))
                        .foregroundColor(item.growth3m.lowercased().contains("increase") ? .green : item.growth3m.lowercased().contains("decrease") ? .red : .primary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }.width(min: 120)
            TableColumn("6m Growth") { item in
                HStack(spacing: 4) {
                    Text(growthTrend(item.growth6m))
                        .font(.caption)
                        .foregroundColor(item.growth6m.lowercased().contains("increase") ? .green : item.growth6m.lowercased().contains("decrease") ? .red : .gray)
                    Text(cleanDuplicatedText(item.growth6m))
                        .foregroundColor(item.growth6m.lowercased().contains("increase") ? .green : item.growth6m.lowercased().contains("decrease") ? .red : .primary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }.width(min: 120)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .frame(height: CGFloat(min(growth.count * 45 + 40, 350)))
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3), lineWidth: 1))
        .font(.subheadline)
        .foregroundStyle(.primary)
        .headerProminence(.increased)
    }
}

struct JobOpeningsBottomTable: View {
    let plainText: [JobOpeningPlainText]
    @State private var sortOrder: [KeyPathComparator<JobOpeningPlainText>] = [.init(\.function, order: .forward)]

    private func growthTrend(_ growth: String) -> String {
        if growth.lowercased().contains("increase") { return "↑" }
        else if growth.lowercased().contains("decrease") { return "↓" }
        else { return "−" }
    }

    var body: some View {
        VStack(spacing: 20) {
            Table(plainText, sortOrder: $sortOrder) {
                TableColumn("Function", value: \.function) { item in
                    Text(item.function)
                        .lineLimit(2)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                }
                .width(min: 150)

                TableColumn("Employees", value: \.numEmployees) { item in
                    Text(item.numEmployees)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                }
                .width(min: 100)

                TableColumn("3m Growth") { item in
                    HStack(spacing: 4) {
                        Text(growthTrend(item.growth3m))
                            .font(.caption)
                            .foregroundColor(item.growth3m.lowercased().contains("increase") ? .green : item.growth3m.lowercased().contains("decrease") ? .red : .gray)
                        Text(cleanDuplicatedText(item.growth3m))
                            .foregroundColor(item.growth3m.lowercased().contains("increase") ? .green : item.growth3m.lowercased().contains("decrease") ? .red : .primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                }
                .width(min: 120)

                TableColumn("6m Growth") { item in
                    HStack(spacing: 4) {
                        Text(growthTrend(item.growth6m))
                            .font(.caption)
                            .foregroundColor(item.growth6m.lowercased().contains("increase") ? .green : item.growth6m.lowercased().contains("decrease") ? .red : .gray)
                        Text(cleanDuplicatedText(item.growth6m))
                            .foregroundColor(item.growth6m.lowercased().contains("increase") ? .green : item.growth6m.lowercased().contains("decrease") ? .red : .primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                }
                .width(min: 120)
            }
            .alternatingRowBackgrounds(.enabled)
            .font(.subheadline)
            .foregroundStyle(.primary)
            .frame(minHeight: min(CGFloat(plainText.count * 44 + 44), 400))
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.background)
                    .shadow(radius: 3)
            )
            .padding(.bottom)
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Visualization View
struct VisualizerView: View {
    let data: LinkedInInsightsData

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let medianTenure = data.medianTenure {
                Text("Median Employee Tenure: \(medianTenure)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.bottom, 10)
            }
            if let totalEmployees = data.totalEmployees["total_employees"] {
                Text("Total Employees: \(totalEmployees)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.bottom, 10)
            }
            if !data.employeeGrowth.isEmpty {
                SectionHeader(title: "Employee Growth Over Time")
                EmployeeGrowthChart(employeeGrowth: data.employeeGrowth)
            }
            if !data.functionDistribution.isEmpty {
                SectionHeader(title: "Function Distribution")
                FunctionDistributionChart(distribution: data.functionDistribution)
            }
            if !data.headcountGrowth.isEmpty {
                SectionHeader(title: "Headcount Growth")
                HeadcountGrowthTable(headcountGrowth: data.headcountGrowth)
            }
            if !data.newHires.isEmpty {
                SectionHeader(title: "New Hires Over Time")
                NewHiresChart(newHires: data.newHires)
            }
            if !data.jobOpenings.distribution.isEmpty {
                SectionHeader(title: "Job Openings Distribution")
                FunctionDistributionChart(distribution: data.jobOpenings.distribution)
            }
            if !data.jobOpenings.openingsDetails.isEmpty {
                SectionHeader(title: "Job Openings Details")
                JobOpeningsDetailsTable(details: data.jobOpenings.openingsDetails)
            }
            if !data.jobOpenings.jobOpeningsGrowth.isEmpty {
                SectionHeader(title: "Job Openings Growth")
                JobOpeningsGrowthTable(growth: data.jobOpenings.jobOpeningsGrowth)
            }
            if !data.jobOpeningsPlainText.isEmpty {
                SectionHeader(title: "Job Openings Plain Text")
                JobOpeningsBottomTable(plainText: data.jobOpeningsPlainText)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: SwiftDataJobApplication.self, SwiftDataJobDocument.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)) // Use in-memory store for previews
        } catch {
            fatalError("Failed to initialize SwiftData container for previews: \(error)")
        }
        let documentStore = DocumentStore(modelContext: container.mainContext)
        let jobStore = JobStore(documentStore: documentStore)
        let importExportHelper = ImportExportHelper()

        return ContentView(showSettings: .constant(false)) // Pass a constant binding for showSettings
            .environmentObject(jobStore)
            .environmentObject(documentStore)
            .environmentObject(importExportHelper)
    }
}
#endif
