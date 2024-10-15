
//
//  AppleJob.swift
//  Complete Single-File Codebase with All Sections
//
//  NOTE: This file reflects the complete codebase with requested modifications:
//
//    1) **Document-Job Associations**
//       - Ensured that `associatedCompany`, `associatedJobTitle`, and `associatedApplicationDate` in `JobDocument`
//         are tied to `companyName`, `jobTitle`, and `dateOfApplication` from each `JobApplication`.
//       - Added a step after loading jobs to merge all documents from older jobs into the global DocumentStore.
//         This ensures older jobs’ documents appear in the Documents tab and older salary data is also recognized.
//
//    2) **Include Older Jobs in Charts & Visualizations**
//       - We now parse older jobs’ salary strings upon load if numeric `salaryMin` and `salaryMax` are missing.
//         This allows older jobs to appear properly in the Salary Range chart and other stats.
//
//    3) **Salary TextField Parsing**
//       - Updated the salary parsing to handle “K” suffix as thousands (e.g., “70K” → “70000”),
//         and remove patterns like "/", "year", "yr", "per" from the salary text before numeric parsing.
//
//    4) **MarkdownUI (Replacing MarkdownKit)**
//       - Removed `import MarkdownKit` and replaced it with `import MarkdownUI` for rendering the job description,
//         cover letter, and notes in `JobDetailView`.
//       - This should simplify the code, potentially improve performance, and allow advanced Markdown styling.
//
//    5) **Tooltip/Annotation for Salary Range Chart**
//       - Added additional info (company name, job title, application date) to the chart tooltip in `EnhancedStatsView`
//         so users can see which job application they’re hovering over.
//
//    6) **Reduced Lag When Selecting a New Job**
//       - Moved expensive data computations in `EnhancedStatsView` to background threads,
//         then dispatch back to the main thread to update published properties. This avoids blocking the main UI thread
//         for 2-3 seconds when switching between jobs in the sidebar.
//
//    7) **Salary Range Chart Improvements**
//        - Chart redraw optimization for state changes.
//        - Inclusion of all job applications with salary ranges.
//        - Even bar spacing on the Y-axis.
//        - Pinned hover annotation to the top right.
//        - Dropdown menu for chart coloring options (Default, City, Year).
//        - Legends added for City and Year coloring.
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

// --------------------------------------------------
// MARK: - SwiftData Models
// --------------------------------------------------

@Model
class SwiftDataJobApplication {
    var id: UUID
    var companyName: String
    var jobTitle: String
    var status: String
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
    var jobType: String
    var desiredSkillNames: [String]
    var jobDeadline: Date?
    var crossJobSkillNames: [String]
    @Relationship(deleteRule: .cascade) var documents: [SwiftDataJobDocument]

    init(
        id: UUID = UUID(),
        companyName: String,
        jobTitle: String,
        status: JobStatus,
        dateOfApplication: Date,
        location: String,
        linkToJobString: String? = nil,
        salaryString: String? = nil,
        salaryMin: Double? = nil,
        salaryMax: Double? = nil,
        jobDescription: String = "",
        coverLetter: String = "",
        notes: String? = nil,
        documents: [SwiftDataJobDocument] = [],
        isFavorite: Bool = false,
        jobType: JobType = .none,
        desiredSkillNames: [String] = [],
        jobDeadline: Date? = nil,
        crossJobSkillNames: [String] = []
    ) {
        self.id = id
        self.companyName = companyName
        self.jobTitle = jobTitle
        self.status = status.rawValue
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
        self.jobType = jobType.rawValue
        self.desiredSkillNames = desiredSkillNames
        self.jobDeadline = jobDeadline
        self.crossJobSkillNames = crossJobSkillNames
    }

    func toJobApplication() -> JobApplication {
        JobApplication(
            id: id,
            companyName: companyName,
            jobTitle: jobTitle,
            status: JobStatus(rawValue: status) ?? .interested,
            dateOfApplication: dateOfApplication,
            location: location,
            linkToJobString: linkToJobString,
            salaryString: salaryString,
            salaryMin: salaryMin,
            salaryMax: salaryMax,
            jobDescription: jobDescription,
            coverLetter: coverLetter,
            notes: notes,
            documents: documents.map { $0.toJobDocument() },
            isFavorite: isFavorite,
            jobType: JobType(rawValue: jobType) ?? .none,
            desiredSkillNames: desiredSkillNames,
            jobDeadline: jobDeadline,
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



struct SalaryRangeItem: Identifiable {
    let id = UUID()
    let jobID: UUID
    let company: String
    let jobTitle: String
    let date: Date
    let minSalary: Double
    let maxSalary: Double
    let orderIndex: Int
    let city: String // Added city
    let year: Int // Added year

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
    "Singapore, SG":     CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198),
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
    "Manila, PH":        CLLocationCoordinate2D(latitude: 14.592295526153894, longitude: 121.05937131989722),
    "Global":            CLLocationCoordinate2D(latitude: 34.149884, longitude: -118.056932)
]

// --------------------------------------------------
// MARK: - JobStore
// --------------------------------------------------

// --------------------------------------------------
// MARK: - Updated JobStore with SwiftData Integration
// --------------------------------------------------


class JobStore: ObservableObject {
    @Published var jobApplications: [JobApplication] = []
    @Published var selectedJobIDs: Set<UUID> = []
    weak var documentStore: DocumentStore? = nil

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

    private let modelContext: ModelContext

    init(documentStore: DocumentStore? = nil, modelContext: ModelContext) {
        self.modelContext = modelContext  // ✅ Corrected
        self.documentStore = documentStore
        loadJobs()
        loadSkills()
        mergeExistingJobDocuments()
    }

    private func mergeExistingJobDocuments() {
        guard let docStore = self.documentStore else { return }
        var allJobDocs: [JobDocument] = []
        for job in jobApplications {
            for doc in job.documents {
                // Set the associated job details for the document when merging
                var mutableDoc = doc
                mutableDoc.associatedCompany = job.companyName
                mutableDoc.associatedJobTitle = job.jobTitle
                mutableDoc.associatedApplicationDate = job.dateOfApplication
                allJobDocs.append(mutableDoc)
            }
        }
        docStore.mergeDocuments(allJobDocs)
    }
//EndTemp

    // ----------------------------------
    // Add, Edit, Duplicate, Delete
    // ----------------------------------
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
            crossJobSkillNames: job.crossJobSkillNames
        )
        jobApplications.append(newJob)
        sortJobs(by: sorting)
        saveJobs()
    }

    // ----------------------------------
    // Status, Type, Favorite
    // ----------------------------------
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

    // ----------------------------------
    // Sorting
    // ----------------------------------
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

    // ----------------------------------
    // Save & Load
    // ----------------------------------
    func saveJobs() {
        syncToUserDefaults() // Keep UserDefaults backup for now
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
        // First try to load from SwiftData
        let descriptor = FetchDescriptor<SwiftDataJobApplication>()
        guard let swiftDataJobs = try? modelContext.fetch(descriptor) else {
            loadFromUserDefaults()
            return
        }

        if !swiftDataJobs.isEmpty {
            jobApplications = swiftDataJobs.map { $0.toJobApplication() }
            sortJobs(by: sorting)
            syncToUserDefaults() // Keep UserDefaults in sync for backup

             // Parse salary for older jobs after loading
            for index in jobApplications.indices {
                if jobApplications[index].salaryMin == nil || jobApplications[index].salaryMax == nil {
                    parseMissingSalaryMinMax(for: &jobApplications[index])
                }
            }
            return
        }

        // Fallback to UserDefaults if SwiftData is empty or fails
        loadFromUserDefaults()
        saveToSwiftData() // Save to SwiftData after loading from UserDefaults for migration

         // Parse salary for older jobs after loading
        for index in jobApplications.indices {
            if jobApplications[index].salaryMin == nil || jobApplications[index].salaryMax == nil {
                parseMissingSalaryMinMax(for: &jobApplications[index])
            }
        }
    }

    private func loadFromUserDefaults() {
        // Otherwise, try to load the JSON string from UserDefaults
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

    private func saveToSwiftData() {
        do {
            // Clear existing SwiftData entries
            try modelContext.delete(model: SwiftDataJobApplication.self)

            // Add current jobs
            for job in jobApplications {
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
                    documents: job.documents.map { SwiftDataJobDocument(
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
                    )},
                    isFavorite: job.isFavorite,
                    jobType: job.jobType,
                    desiredSkillNames: job.desiredSkillNames,
                    jobDeadline: job.jobDeadline,
                    crossJobSkillNames: job.crossJobSkillNames
                )
                modelContext.insert(sdJob)
            }
            try modelContext.save()
        } catch {
            print("SwiftData save failed: \(error)")
        }
    }

    /// Reparse the salaryString for older jobs if numeric is missing
    private func parseMissingSalaryMinMax(for job: inout JobApplication) {
        // We can reuse the parse logic from JobViewModel:
        let (minVal, maxVal) = JobViewModel.parseSalaryRangeStatic(job.salaryString ?? "")
        job.salaryMin = minVal
        job.salaryMax = maxVal
    }

    // ----------------------------------
    // Backup Import / Export
    // ----------------------------------
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
                     // Fix older data after import as well:
                    for index in self.jobApplications.indices {
                        if self.jobApplications[index].salaryMin == nil || self.jobApplications[index].salaryMax == nil {
                            self.parseMissingSalaryMinMax(for: &self.jobApplications[index])
                        }
                    }
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

    // ----------------------------------
    // Skills
    // ----------------------------------
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
            UserDefaults.standard.set(data, forKey: Constants.skillsKey)
        } catch {
            print("Error saving skills: \(error)")
        }
    }

    func loadSkills() {
        if let savedData = UserDefaults.standard.data(forKey: Constants.skillsKey) {
            if let loadedSkills = try? JSONDecoder().decode([DesiredSkill].self, from: savedData) {
                availableSkills = loadedSkills
                return
            }
        }
        guard let jsonString = UserDefaults.standard.string(forKey: Constants.skillsKey),
              let jsonData = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
              let skillsArray = jsonObject as? [[String: Any]]
        else {
            return
        }
        var loadedSkills: [DesiredSkill] = []
        for dict in skillsArray {
            if let skill = DesiredSkill.fromDictionary(dict) {
                loadedSkills.append(skill)
            }
        }
        availableSkills = loadedSkills
    }

    // ----------------------------------
    // Skill Parsing (Single Job Only)
    // ----------------------------------
    func parseJobDescriptionForSingleJob(_ job: inout JobApplication) {
        for skill in availableSkills {
            let searchTerms = [skill.name.lowercased()] + skill.aliases.map { $0.lowercased() }
            let desc = job.jobDescription.lowercased()
            let found = searchTerms.contains { desc.contains($0) }
            if found && !job.desiredSkillNames.contains(skill.name) {
                job.desiredSkillNames.append(skill.name)
            }
        }
    }

    func parseJobDescriptionsForSkill(_ skill: DesiredSkill) {
        // For each job, see if the skill or any aliases is in that job’s description
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

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadDocuments()
        loadCategories()
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

    /// Merges a set of new documents into our store, ignoring duplicates.
    func mergeDocuments(_ newDocs: [JobDocument]) {
        for doc in newDocs {
            if !documents.contains(doc) {
                documents.append(doc)
            }
        }
        saveDocuments()
    }

    // ----------------------------------
    // Save & Load Documents
    // ----------------------------------
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
        guard let swiftDataDocs = try? modelContext.fetch(descriptor) else {
            loadFromUserDefaults()
            return
        }

        if !swiftDataDocs.isEmpty {
            documents = swiftDataDocs.map { $0.toJobDocument() }
            return
        }

        // Fallback to UserDefaults if SwiftData is empty or fails
        loadFromUserDefaults()
        saveToSwiftData() // Migrate to SwiftData on first load from UserDefaults
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

    // ----------------------------------
    // Categories
    // ----------------------------------
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

    // ----------------------------------
    // Move/copy documents into Application Support
    // ----------------------------------
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

// --------------------------------------------------
// MARK: - ImportExportHelper
// --------------------------------------------------
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
    @Published var salaryMin: Double? = nil
    @Published var salaryMax: Double? = nil
    @Published var jobType: JobType = .none
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
        status = .interested
        dateOfApplication = Date()
        location = ""
        linkToJob = ""
        jobDescription = ""
        coverLetter = ""
        notes = ""
        salaryString = ""
        salaryMin = nil
        salaryMax = nil
        jobType = .none
        selectedDesiredSkills = []
        jobDeadline = nil
        validateInputs()
    }
}

// --------------------------------------------------
// MARK: - Main App
// --------------------------------------------------
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
        let jobStore = JobStore(documentStore: documentStore, modelContext: container.mainContext)
        return (documentStore, jobStore)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(jobStore)
                .environmentObject(docStore)
                .environmentObject(importExportHelper)
        }
        .modelContainer(container) // Attach ModelContainer to WindowGroup
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
                    docStore.uploadDocumentsNonAsync(from: urls)
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

// --------------------------------------------------
// MARK: - ContentView
// --------------------------------------------------
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
                    .contentTransition(.opacity) // Add content transition for smoother updates
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
            .animation(.easeInOut, value: jobStore.selectedJobIDs.contains(job.id)) // Add animation for background color change
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
        withAnimation { // Add animation for job deletion in sidebar
            for idx in offsets {
                let job = filteredJobs[idx]
                jobStore.deleteJob(for: job.id)
            }
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
            withAnimation(.easeInOut(duration: 0.15)) { // Add animation for selection highlight
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
            .frame(minWidth: 450, minHeight: 650)
            .transition(.slide) // Add transition for window appearance
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
            .frame(minWidth: 450, minHeight: 650)
            .transition(.slide) // Add transition for window appearance
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
    @State private var showCelebration = false // State for celebration animation

    @State private var windowRef: NSWindow?

    var body: some View {
        ZStack {
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
                        Text("Documents").font(.headline)
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
                            .buttonStyle(.bordered)
                            .tint(.red)
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
                                    withAnimation { // Show celebration animation on save
                                        showCelebration = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { // Delay to allow animation to play
                                        closeWindow()
                                    }
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
            if showCelebration {
                CelebrationView()
                    .transition(.scale) // Animation for celebration view
                    .zIndex(1) // Ensure celebration is on top
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { // Duration of celebration
                            withAnimation {
                                showCelebration = false
                            }
                        }
                    }
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
    @State private var showCelebration = false // State for celebration animation

    @State private var windowRef: NSWindow?

    init(isPresented: Binding<Bool>, job: JobApplication) {
        self._isPresented = isPresented
        let vm = JobViewModel(job: job, availableSkills: [])
        _viewModel = StateObject(wrappedValue: vm)
        _importedDocuments = State(initialValue: job.documents)
    }

    var body: some View {
        ZStack {
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
                        Text("Documents").font(.headline)
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
                            .buttonStyle(.bordered)
                            .tint(.red)
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
                                    withAnimation { // Show celebration animation on save
                                        showCelebration = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { // Delay to allow animation to play
                                        closeWindow()
                                    }
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
            if showCelebration {
                CelebrationView()
                    .transition(.scale) // Animation for celebration view
                    .zIndex(1) // Ensure celebration is on top
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { // Duration of celebration
                            withAnimation {
                                showCelebration = false
                            }
                        }
                    }
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
                .transition(.move(edge: .bottom).combined(with: .opacity)) // Add suggestion list transition
                .animation(.easeInOut, value: suggestions) // Animate suggestion list updates
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
                .transition(.scale) // Animation for skill tag appearance
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
        .transition(.scale) // Animation for skill tag removal
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
        .transition(.slide) // Add transition for new location window
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
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .padding(.top, 10)
            Spacer()
        }
        .padding()
    }
}

struct TranslucentGradientBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(6)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.6),
                        Color.gray.opacity(0.3)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(5)
    }
}

// --------------------------------------------------
// MARK: - EnhancedStatsView
// --------------------------------------------------
import SwiftUI
import Charts
import MapKit

// Define SalaryChartDisplayOption enum here, inside or outside the struct, as needed
enum SalaryChartDisplayOption: String, CaseIterable, Identifiable {
    case `default` = "Default"
    case city = "City"
    case year = "Year"
    var id: String { rawValue }
}

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
    @State private var hoveredJobID: UUID? = nil
    @State private var hoveredPieJobID: UUID? = nil
    @State private var hoveredSalaryItemID: UUID? = nil
    @State private var selectedSalaryChartOption: SalaryChartDisplayOption = .default

    // Year and time-range states
    @State private var selectedYear: Int = -1
    @State private var availableYears: [Int] = []
    @State private var selectedTimeRange: TimeRange = .month
    @AppStorage("StatsViewTimeRange") private var selectedTimeRangeRaw: String = TimeRange.month.rawValue

    // Data storage arrays (using @State for isolated redraws)
    @State private var cityPins: [CityPin] = []
    @State private var barLineData: [DailyApps] = []
    @State private var yearContributionData: [Contribution] = []
    @State private var appsContributionData: [Contribution] = []
    @State private var monthlyCityData: [MonthlyCityData] = []
    @State private var filteredMonthlyCityData: [MonthlyCityData] = []
    @State private var salaryRangeData: [SalaryRangeItem] = [] //  @State for isolated redraws


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
                salaryRangeSection // Salary Range Chart Section - Isolated Section
            }
            .padding()
        }
        .onAppear(perform: setupViewOnAppear)
        .onChange(of: selectedTimeRange) { _, _ in
            selectedTimeRangeRaw = selectedTimeRange.rawValue
            asyncDataComputations()
        }
        .onChange(of: selectedYear) { _, _ in
            refreshYearDependentData()
        }
        .onChange(of: monthlyCityData) { _, _ in
            filterMonthlyCityDataForSelectedYear()
        }
        .onChange(of: jobStore.jobApplications) { _, _ in // React to job application changes
            asyncComputeSalaryRangeData() // Refresh salary chart data specifically on job changes
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
        asyncDataComputations() // Initial data load on appear
        asyncComputeSalaryRangeData() // Initial load of salary range data
    }


    private func refreshYearDependentData() {
        asyncComputeCityPins()
        asyncComputeYearContribution()
        asyncComputeAppsContribution()
        asyncComputeMonthlyCityData()
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
    // MARK: - Async Data Computations (Consolidated - excluding Salary Range Data)
    // --------------------------------------------------
    private func asyncDataComputations() {
        DispatchQueue.global(qos: .userInitiated).async {
            let cityPinsResult = buildCityPins()
            let barLineDataResult = buildBarLineData()
            let monthlyCityDataResult = buildMonthlyCityData()
            DispatchQueue.main.async {
                self.cityPins = cityPinsResult
                self.barLineData = barLineDataResult
                self.monthlyCityData = monthlyCityDataResult
                self.filterMonthlyCityDataForSelectedYear()
            }
        }
    }

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


    // MARK: - Map Section
    private var mapSection: some View {
        // ... (rest of mapSection code is same)
        VStack(alignment: .leading, spacing: 12) {
            Text("Applications Map")
                .font(.headline)

            Map(coordinateRegion: $region, annotationItems: cityPins) { pin in
                MapAnnotation(coordinate: pin.coordinate) {
                    ZStack {
                        Circle().fill(.red).opacity(0.3).frame(width: circleSize(for: pin.count), height: circleSize(for: pin.count))
                        Circle().stroke(.red, lineWidth: 2).frame(width: circleSize(for: pin.count), height: circleSize(for: pin.count))
                        Text("\(pin.count)").font(.caption).foregroundColor(.black)
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
        // ... (rest of appliedCompaniesAndRolesView code is same)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(jobStore.jobApplications.sorted(by: { $0.dateOfApplication > $1.dateOfApplication }), id: \.id) { job in
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
                    .transition(.scale) // Add transition for applied job items
                }
            }
            .padding(.horizontal)
        }
    }

    // -----------------------------
    // Stats row
    // -----------------------------
    private var statsRowSection: some View {
        // ... (rest of statsRowSection code is same)
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
        // ... (rest of dynamicYearPickerSection code is same)
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
        // ... (rest of githubChartsSection code is same)
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
                .transition(.move(edge: .bottom)) // Add chart transition

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
                .transition(.move(edge: .bottom)) // Add chart transition
            }
        }
    }





    // -----------------------------
    // Bar/Line Chart
    // -----------------------------
    private var barLineChartsSection: some View {
        // ... (rest of barLineChartsSection code is same)
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
        .transition(.move(edge: .bottom)) // Add chart transition
    }


    // -----------------------------
    // Single Column Stacked Chart
    // -----------------------------
    private var singleColumnVerticallyStackedBarChartSection: some View {
        // ... (rest of singleColumnVerticallyStackedBarChartSection code is same)
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
        .transition(.move(edge: .bottom)) // Add chart transition
    }

    private var top20CompaniesBarSection: some View {
        // ... (rest of top20CompaniesBarSection code is same)
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
        .transition(.move(edge: .bottom)) // Add chart transition
    }

    private func buildTop20CompanyFreq() -> [CompanyFreq] {
        // ... (rest of buildTop20CompanyFreq code is same)
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
        // ... (rest of citiesByFrequencySection code is same)
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
        .transition(.move(edge: .bottom)) // Add scrollview transition
    }

    private var companiesByFrequencySection: some View {
        // ... (rest of companiesByFrequencySection code is same)
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
        .transition(.move(edge: .bottom)) // Add scrollview transition
    }


    // -----------------------------
    // Pie Charts Section
    // -----------------------------
    private var pieChartsSection: some View {
        // ... (rest of pieChartsSection code is same)
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
        .transition(.move(edge: .bottom)) // Add pie chart transition
    }


    // MARK: - The Salary Range Section - Updated
    @ViewBuilder
    private var salaryRangeSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Salary Ranges for Job Applications")
                    .font(.headline)
                    .padding(.bottom, 5)
                Spacer()
                Picker("Color By", selection: $selectedSalaryChartOption) {
                    ForEach(SalaryChartDisplayOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .animation(.easeInOut, value: selectedSalaryChartOption)
            }

            ZStack(alignment: .topTrailing) {
                let colorDict = chartColorScale()
                let sortedKeys = colorDict.keys.sorted()

                Chart(salaryRangeData, id: \.id) { item in
                    BarMark(
                        xStart: .value("Min Salary", item.minSalary),
                        xEnd:   .value("Max Salary", item.maxSalary),
                        y:      .value("Application Order", item.orderIndex) // Y-Value as orderIndex for even spacing
                    )
                    .foregroundStyle(by: .value("Color Identifier", barColorIdentifier(for: item)))
                    .cornerRadius(4)
                    .annotation(position: .topTrailing, anchor: .topTrailing) { // Pinned to top trailing
                        if hoveredSalaryItemID == item.id {
                            jobDetailTooltip(for: item)
                        }
                    }
                }
                .chartYAxis(.hidden) // Hide Y-Axis for even spacing
                .chartXAxis {
                    AxisMarks(values: .stride(by: 20000.0)) {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .currency(code: "USD"))
                    }
                }
                .chartForegroundStyleScale(
                    domain: sortedKeys,
                    range: sortedKeys.compactMap { colorDict[$0] }
                )
                .chartLegend(position: .bottom, alignment: .leading, spacing: 8)
                .frame(height: 500)
                .padding(.horizontal, 16)
                .chartOverlay { proxy in
                    Color.clear
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let location):
                                if let xValue = proxy.value(atX: location.x, as: Double.self),
                                   let yValue = proxy.value(atY: location.y, as: Int.self) {
                                    let foundItem = salaryRangeData.first { item in
                                        item.orderIndex == yValue &&
                                        xValue >= item.minSalary && xValue <= item.maxSalary
                                    }
                                    hoveredSalaryItemID = foundItem?.id
                                }
                            case .ended:
                                hoveredSalaryItemID = nil
                            }
                        }
                }

                if selectedSalaryChartOption == .city {
                    chartLegend(for: .city)
                } else if selectedSalaryChartOption == .year {
                    chartLegend(for: .year)
                }
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal)
    }


    // MARK: - Chart Legend - unchanged
    @ViewBuilder
    func chartLegend(for option: SalaryChartDisplayOption) -> some View {
        switch option {
        case .city:
            HStack {
                ForEach(CityCoordinateDictionary.keys.sorted(), id: \.self) { city in
                    let color = cityColor(for: city)
                    HStack{
                        Circle().fill(color).frame(width: 8, height: 8)
                        Text(city).font(.caption)
                    }
                }
            }
        case .year:
            HStack {
                ForEach([2022, 2023, 2024, 2025], id: \.self) { year in
                    let color = yearColor(for: year)
                    HStack{
                        Circle().fill(color).frame(width: 8, height: 8)
                        Text(String(year)).font(.caption)
                    }
                }
            }
        default:
            EmptyView()
        }
    }

    // MARK: - Construct the bar’s color identifier, chartColorScale, cityColor, yearColor - unchanged
    private func barColorIdentifier(for item: SalaryRangeItem) -> String {
        switch selectedSalaryChartOption {
        case .default:
            return "default"
        case .city:
            // Tag it as `city:locationString`
            return "city:\(item.city)"
        case .year:
            // Tag it as `year:YYYY`
            return "year:\(item.year)"
        }
    }

    // MARK: - Dynamically build a [String: Color] dictionary
    private func chartColorScale() -> [String: Color] {
        var scaleArray: [(String, Color)] = []
        scaleArray.append(("default", .blue.opacity(0.7)))
        for (cityName, _) in CityCoordinateDictionary {
            scaleArray.append(("city:\(cityName)", cityColor(for: cityName)))
        }
        let interestingYears = [2022, 2023, 2024, 2025]
        for year in interestingYears {
            scaleArray.append(("year:\(year)", yearColor(for: year)))
        }
        return Dictionary(uniqueKeysWithValues: scaleArray)
    }

    // MARK: - City => SwiftUI Color
    private func cityColor(for city: String) -> Color {
        let baseColors: [Color] = [.red, .green, .purple, .cyan, .orange, .brown, .pink, .indigo]
        let idx = abs(city.hashValue) % baseColors.count
        return baseColors[idx].opacity(0.7)
    }

    // MARK: - Year => SwiftUI Color
    private func yearColor(for year: Int) -> Color {
        let baseColors: [Color] = [.yellow, .red, .mint, .teal, .orange, .purple, .gray]
        let idx = abs(year.hashValue) % baseColors.count
        return baseColors[idx].opacity(0.7)
    }

    // MARK: - Tooltip - Updated for more details
    @ViewBuilder
    private func jobDetailTooltip(for item: SalaryRangeItem) -> some View {
        if let job = jobStore.jobApplications.first(where: { $0.id == item.jobID }) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(job.companyName)")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(item.jobTitle)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text("Applied: \(item.date, format: .dateTime.month().day().year())") // Added Date
                    .font(.caption)
                    .foregroundColor(.white)
                Text("💰 \(formatSalary(item.minSalary)) - \(formatSalary(item.maxSalary))")
                    .font(.body)
                    .foregroundColor(.yellow)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.green.opacity(0.7))
            )
            .frame(maxWidth: 250)
            .transition(.opacity.combined(with: .move(edge: .top)))
        } else {
            Text("Unknown job.")
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.red.opacity(0.6))
                )
                .frame(maxWidth: 200)
                .foregroundColor(.white)
        }
    }

    // MARK: - Format Salary - unchanged
    private func formatSalary(_ salary: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: salary)) ?? "\(salary)"
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
        .transition(.move(edge: .bottom)) // Add chart transition
    }
}

extension EnhancedStatsView {
    // Re-implement buildSalaryRangeData to ensure chronological ordering
    fileprivate func buildSalaryRangeData() -> [SalaryRangeItem] {
        let cal = Calendar.current
        let filteredApps = jobStore.jobApplications.filter {
            selectedYear == -1 || cal.component(.year, from: $0.dateOfApplication) == selectedYear
        }
        let sortedApps = filteredApps.sorted { $0.dateOfApplication > $1.dateOfApplication } // Sort newest to oldest

        var result: [SalaryRangeItem] = []
        for (idx, app) in sortedApps.enumerated() { // Already sorted chronologically
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
                orderIndex: idx, // Use index in the sorted array for order
                city: app.location,
                year: cal.component(.year, from: app.dateOfApplication)
            )
            result.append(item)
        }
        return result
    }
}
// --------------------------------------------------
// MARK: - JobDetailView
// --------------------------------------------------
struct JobDetailView: View {
    // ... (rest of JobDetailView code is same)
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    let job: JobApplication

    @State private var windowRef: NSWindow?
    @State private var quickLookURL: URL? = nil
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
        .transition(.opacity) // Add job detail view transition
    }

    private var coverLetterSection: some View {
        // ... (rest of coverLetterSection code is same)
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

    private var notesSection: some View {
        Group {
            Divider()
            Text("Notes").font(.headline)
            if let userNotes = job.notes, !userNotes.isEmpty {
                Markdown(userNotes)
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
                .transition(.scale) // Add company header transition
            Text(job.jobTitle)
                .font(.title2)
                .gradientForeground(colors: [.red, .orange])
                .transition(.scale) // Add job title transition
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
        // ... (rest of rowItem code is same)
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
        .transition(.opacity) // Add row item transition
    }
}

// Subview: DocumentsSectionView
struct DocumentsSectionView: View {
    // ... (rest of DocumentsSectionView code is same)
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
                        .transition(.scale) // Add document button transition
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
        // ... (rest of openQuickLook code is same)
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
        // ... (rest of revealInFinder code is same)
        if let fileURL = doc.fileURL {
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        }
    }

    private func cleanFileName(_ filename: String) -> String {
        // ... (rest of cleanFileName code is same)
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
    // ... (rest of SkillsSectionView code is same)
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
                            : [Color.orange.opacity(0.3), Color.yellow.opacity(0.5)]
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
                        .transition(.scale) // Add skill tag transition
                    }
                }
            }
        }
    }
}

// Subview: DescriptionSectionView
struct DescriptionSectionView: View {
    // ... (rest of DescriptionSectionView code is same)
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
                .buttonStyle(.bordered) // Apply bordered style to copy button for consistency
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
    // ... (rest of PDFInlineViewer code is same)
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
                            .contentTransition(.opacity) // Add content transition for smoother updates
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
                            .contentTransition(.opacity) // Add content transition for smoother updates
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
        .transition(.opacity) // Add documents main view transition
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
                .buttonStyle(.bordered) // Apply bordered style to edit metadata button for consistency
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
        .transition(.scale) // Add document info popover transition
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
        .transition(.slide) // Add document metadata edit view transition
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
                    .transition(.move(edge: .leading)) // Add pie chart transition

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
                    .transition(.move(edge: .leading)) // Add pie chart transition

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
                    .transition(.move(edge: .leading)) // Add pie chart transition
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
            Calendar.current.shortMonthSymbols.firstIndex(of: $0.monthKey) ?? 0 <
            Calendar.current.shortMonthSymbols.firstIndex(of: $1.monthKey) ?? 0
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

// --------------------------------------------------
// MARK: - CelebrationView (Confetti Animation)
// --------------------------------------------------
struct CelebrationView: View {
    @State private var confettiParticles: [ConfettiParticle] = []

    var body: some View {
        ZStack {
            ForEach(confettiParticles) { particle in
                ConfettiShape()
                    .fill(particle.color)
                    .frame(width: 8, height: 8)
                    .position(particle.position)
                    .rotationEffect(particle.rotation)
            }
        }
        .onAppear {
            startConfettiAnimation()
        }
    }

    func startConfettiAnimation() {
        confettiParticles = [] // Reset particles for restart
        for _ in 0..<200 { // More particles for better effect
            confettiParticles.append(ConfettiParticle())
        }

        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            withAnimation(.linear) {
                for index in confettiParticles.indices {
                    confettiParticles[index].update()
                }
            }

            if confettiParticles.allSatisfy({ $0.isOffScreen }) {
                timer.invalidate()
            }
        }
    }
}

struct ConfettiShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        return path
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint
    var color: Color
    var rotation: Angle = .zero
    var rotationSpeed = Double.random(in: -0.1...0.1)
    var gravity = 0.3
    var isOffScreen = false

    init() {
        position = CGPoint(x: CGFloat.random(in: 0...800), y: -20) // Start from top
        velocity = CGPoint(x: CGFloat.random(in: -2...2), y: CGFloat.random(in: 5...10))
        color = Color.random()
    }

    mutating func update() {
        position.x += velocity.x
        position.y += velocity.y
        velocity.y -= gravity // Simulate gravity

        rotation += Angle.radians(rotationSpeed)

        if position.y > 900 { // Adjust as needed for off-screen detection
            isOffScreen = true
        }
    }
}

extension Color {
    static func random() -> Color {
        return Color(
            red: .random(in: 0.2...1),
            green: .random(in: 0.2...1),
            blue: .random(in: 0.2...1)
        )
    }
}
