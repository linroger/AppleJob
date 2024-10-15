
//
//  AppleJob.swift
//  Complete Single-File Codebase with All Sections
//
//  NOTE: This file reflects the complete codebase with requested modifications:
//
//    1) **Document-Job Associations**
//       - Ensured that `associatedCompany`, `associatedJobTitle`, and `associatedApplicationDate` in `JobDocument`
//         are tied to `companyName`, `jobTitle`, and `dateOfApplication` from each `JobApplication`.
//
//    2) **Include Older Jobs in Charts & Visualizations**
//       - We now parse older jobs' salary strings upon load if numeric `salaryMin` and `salaryMax` are missing.
//
//    3) **Salary TextField Parsing**
//       - Updated the salary parsing to handle "K" suffix as thousands (e.g., "70K" → "70000"),
//         and remove patterns like "/", "year", "yr", "per" from the salary text before numeric parsing.
//
//    4) **MarkdownUI (Replacing MarkdownKit)**
//       - Removed `import MarkdownKit` and replaced it with `import MarkdownUI` for rendering the job description,
//         cover letter, and notes in `JobDetailView`.
//
//    5) **Stats View Crash Fix**
//       - Fixed thread safety issues in EnhancedStatsView that were causing crashes.
//       - Added proper error handling around potential crash points.
//       - Added better state management to prevent race conditions.
//
//    6) **AI Integration Improvements**
//       - Added dedicated AI Resume and AI Cover Letter buttons to toolbar
//       - Created modal windows for AI interactions with custom prompts
//       - Implemented progress view with stopwatch during API calls
//       - Added proper display of AI-generated content with copy buttons
//       - Fixed visibility issues with AI-generated content
//
//    7) **Other General Improvements**
//       - Better error handling throughout the app
//       - Improved thread safety for background operations
//       - Enhanced UI feedback during long-running operations
//
//  All other code remains intact or only minimally changed to accommodate these updates.
//

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
import MarkdownUI
import SwiftData

// MARK: - SwiftData Models
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
    var tailoredResumes: [String]?
    var tailoredCoverLetters: [String]?
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
        crossJobSkillNames: [String] = [],
        tailoredResumes: [String]? = nil,
        tailoredCoverLetters: [String]? = nil
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
        self.tailoredResumes = tailoredResumes
        self.tailoredCoverLetters = tailoredCoverLetters
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
            crossJobSkillNames: crossJobSkillNames,
            tailoredResumes: tailoredResumes,
            tailoredCoverLetters: tailoredCoverLetters
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

// MARK: - Constants
struct Constants {
    static let jobsKey = "jobs"
    static let skillsKey = "desiredSkills"
    static let documentsKey = "documents"
    static let documentCategoriesKey = "documentCategories"
    static let resumeKey = "userResume"
    static let aiApiKey = "sk-e5528df49b794732bb7817ce06786f72" // Replace with your actual API key
    static let aiApiEndpoint = "https://api.deepseek.com/v1/chat/completions" // DeepSeek OpenAI-compatible endpoint
}

// MARK: - Protocol: CaseNameDisplayable
protocol CaseNameDisplayable: RawRepresentable, CaseIterable where RawValue == String, AllCases: Collection {
    func caseNameForDisplay() -> String
}

extension CaseNameDisplayable {
    func caseNameForDisplay() -> String {
        return self.rawValue
    }
}

// MARK: - Enums: JobType, JobStatus, Sort, ViewSection
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

// MARK: - Model: DesiredSkill
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

// MARK: - Model: JobDocument
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

// MARK: - Model: DocumentCategory
struct DocumentCategory: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var isExpanded: Bool = true
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

// MARK: - Model: JobApplication
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
    // Skills auto-added from older logic; we're no longer updating these for new jobs,
    // but we keep them so existing cross-job references remain visible.
    var crossJobSkillNames: [String]
    
    // Arrays to store multiple AI-generated tailored content
    var tailoredResumes: [String]?
    var tailoredCoverLetters: [String]?

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
        crossJobSkillNames: [String] = [],
        tailoredResumes: [String]? = nil,
        tailoredCoverLetters: [String]? = nil
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
        self.tailoredResumes = tailoredResumes
        self.tailoredCoverLetters = tailoredCoverLetters
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
        case tailoredResumes
        case tailoredCoverLetters
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
        if let tailoredResumes = tailoredResumes { dict["tailoredResumes"] = tailoredResumes }
        if let tailoredCoverLetters = tailoredCoverLetters { dict["tailoredCoverLetters"] = tailoredCoverLetters }
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
        let tailoredResumes = dict["tailoredResumes"] as? [String]
        let tailoredCoverLetters = dict["tailoredCoverLetters"] as? [String]
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
            crossJobSkillNames: crossSkillNames,
            tailoredResumes: tailoredResumes,
            tailoredCoverLetters: tailoredCoverLetters
        )
    }

    static func == (lhs: JobApplication, rhs: JobApplication) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Helper Data Structures for Charts
struct CompanyFreq: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
}

struct CityPin: Identifiable, Equatable {
    let id = UUID()
    let city: String
    let coordinate: CLLocationCoordinate2D
    let count: Int

    static func == (lhs: CityPin, rhs: CityPin) -> Bool {
        return lhs.id == rhs.id && lhs.city == rhs.city && lhs.count == rhs.count
    }
}

struct MonthlyCityData: Identifiable, Equatable {
    let id = UUID()
    let monthKey: String
    let city: String
    let count: Int
    let date: Date

    static func == (lhs: MonthlyCityData, rhs: MonthlyCityData) -> Bool {
        return lhs.id == rhs.id
    }
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

struct DailyApps: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let count: Int

    static func == (lhs: DailyApps, rhs: DailyApps) -> Bool {
        return lhs.id == rhs.id && lhs.date == rhs.date && lhs.count == rhs.count
    }
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

// MARK: - City-Coordinate Dictionary
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

// MARK: - Model: Resume
struct Resume: Codable {
    var content: String

    init(content: String = "") {
        self.content = content
    }

    static func load() -> Resume {
        guard let data = UserDefaults.standard.data(forKey: Constants.resumeKey) else {
            return Resume(content: defaultResumeContent)
        }

        do {
            return try JSONDecoder().decode(Resume.self, from: data)
        } catch {
            print("Error loading resume: \(error)")
            return Resume(content: defaultResumeContent)
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaults.standard.set(data, forKey: Constants.resumeKey)
        } catch {
            print("Error saving resume: \(error)")
        }
    }

    static var defaultResumeContent: String {
        """
        # **Roger Lin**

        1330 E 53rd St. Chicago, IL, 60615| 646-354-1035 | linroger023@uchicago.edu

        ## **EDUCATION**

        ## **University of Chicago - Harris School of Public Policy** *September 2022 - June 2024*

        Master of Public Policy | Finance and Policy Track **GPA :** 3.79
        *Coursework Includes: Credit Markets; Fixed Income Asset Pricing; Financial Markets and Institutions; Financial Instruments; Advanced Microeconomics for Public Policy; Bank Regulation and Management; Corporate Finance; Financial Investments for Public Policy; Macroeconomic Policymaking; Statistics for Data Analysis; International Trade, Banking, and Capital Markets, Macro Finance* 

        ## **University of California - San Diego** *September 2018 - May 2022*

        Bachelor of Arts in Philosophy and Economics **GPA :** 3.83
        *Coursework Includes: Advanced Econometrics; Development Economics; Economic Stabilization; International Monetary Relations; Linear Algebra; Micro and Macroeconomics; Monetary Economics; Multivariable Calculus* 

        ## **PROFESSIONAL EXPERIENCE**
        ## **Becker Friedman Institute, University of Chicago Chicago, IL**
        **Research Professional**
        *June 2023 - Current*
        - Undertook thorough examination of existing research on inflation-asset return dynamics, synthesizing findings from numerous publications and identifying specific gaps for future investigation.
        - Compiled, refined, and analyzed over 50 years of historical data on inflation, stock market valuations, Treasury yields, and inflation expectations to explore the coevolution of inflation and returns on various asset classes.
        - Replicated methodologies from earlier seminal works investigating relationship between asset returns and inflation using recent data.
        - Analyzed market data for inflation swaps, nominal Treasuries, and TIPS to project future path of CPI and extract the market's forward implied inflation expectations.
        - Prepared data visualizations and summaries of statistical tests to illustrate key research findings, enhancing clarity and impact of results. Composed additional materials for a research brief summarizing the study's key points, tailored for both an academic audience and policy stakeholders.

        ### **Bainbridge Strategic Consulting San Diego, CA**

        *Business Analyst Intern June 2021 - August 2021*

        - Performed in-depth industry research and peer company assessments, leveraging Porter's Five Forces framework to extract actionable intelligence on the client's unique market position and potential growth avenues.
        - Built dynamic financial models forecasting company performance under various growth scenarios, crossreferencing industry benchmarks to provide enhanced strategic recommendations.
        - Conducted in-depth scenario analysis to assess possible outcomes across diverse market conditions, pinpointing key success drivers and potential pitfalls for thorough risk evaluation.
        - Drafted detailed business plan detailing growth initiatives and operational enhancements, contributing to a 16% revenue uptick and a 12% rise in customer acquisition over two quarters.
        - Consolidated research insights into a comprehensive presentation featuring data visualizations, quantifying a $50+ million opportunity in a new market segment primed for strategic entry.

        ## **LEADERSHIP ACTIVITIES / SELECTED PROJECTS**

        ## **JPMorgan Chase & Co. Quantitative Research Virtual Experience Program - Forage**
        *December 2024*
        - Analyzed and modeled customer loan data to estimate the Probability of Default (PD), applying statistical techniques to guide loss provisions and risk assessment.
        - Developed predictive models, including logistic regression and decision tree classifiers, to calculate PD for retail loans, achieving near-perfect ROC AUC scores in model evaluation.
        - Designed and implemented dynamic programming algorithms to optimize the categorization of FICO scores, creating discrete buckets that maximized log-likelihood functions for accurate default prediction.
        - Utilized Python and machine learning libraries (e.g., scikit-learn, NumPy, pandas) for data preprocessing, feature engineering, and model training, showcasing proficiency in data analysis and programming

        ## **Triton Business Review** | UC San Diego's Premier Undergraduate Business Journal **San Diego, CA**
        **Founder and Editor-in-Chief**
        *September 2018 – June 2022*
        - Founded and grew Triton Business Review into the premier undergraduate business publication at UC San Diego
        - Led recruitment initiatives and social media strategy, boosting awareness and increasing writer and editor headcount by 140% over four years
        - Streamlined end-to-end publication process, reducing turnaround by 20% while maintaining consistent weekly publication schedule by introducing editorial board and peer review process
        - Spearheaded data analytics integration, implementing dashboard tracking reader engagement metrics and trending topics, driving improvements in content relevance and overall viewership.
        - Launched digital-first strategy, creating mobile-responsive website and newsletter reaching 8,000+ subscribers with over 40% average open rate
        - Secured $15,000 in overall funding through strategic partnerships with student organizations, reader donations, and successful pitches to academic departments and college councils, while reducing reliance on one-time grants from 80% to 30% of budget
        - Applied research and analysis skills to evaluate near and long-term ramifications of global events. Published 12+ analytical articles communicating complex insights in clear and engaging manner on Triton Business Review's Medium page: [https://medium.com/triton-business-review.](https://medium.com/triton-business-review)

        ## **TECHNICAL SKILLS**

        **Technical Skills:** Quantitative Finance, Credit Research, Financial Analysis and Valuation, Modeling, Fixed Income Asset Pricing, Relative Value Trading, Derivatives Pricing, Microsoft Office, Data Analysis and Visualization, Research **Technologies:** RStudio, Python - numpy, pandas, scipy, sympy, scikit-learn, Jupyter Notebooks 
        **Languages:** English (native fluency), Mandarin (native fluency), Spanish (conversational fluency) 
        **Hobbies:** Photography, Traveling, Reading, Hiking, importing pandas as pd
        """
    }
}

// MARK: - AIService for API calls to tailor resumes and cover letters
class AIService {
    private let apiKey: String
    private let apiEndpoint: String
    
    init(apiKey: String = Constants.aiApiKey, apiEndpoint: String = Constants.aiApiEndpoint) {
        self.apiKey = apiKey
        self.apiEndpoint = apiEndpoint
    }
    
    func generateTailoredResume(prompt: String, jobDescription: String, resume: String, skills: [String]) async throws -> (thinking: String, output: String) {
        var finalPrompt = prompt.isEmpty ? 
        """
        # Task
        Read through my resume and the job description, then tailor my resume to the job based on the details found in the job description.
        
        # Instructions
        1. Analyze the job description to identify required skills, experience, and qualifications.
        2. Modify my resume to highlight relevant experience and skills that match the job requirements.
        3. Use keywords from the job posting in the tailored resume.
        4. Present me as the best candidate for the role without being arrogant.
        5. Format the response in markdown.
        6. Don't summarize - include the same level of detail as the original resume.
        """ : prompt
        
        finalPrompt += """
        
        # Job Description
        ```
        \(jobDescription)
        ```
        
        # My Resume
        ```
        \(resume)
        ```
        """
        
        if !skills.isEmpty {
            finalPrompt += """
            
            # Desired Skills
            \(skills.joined(separator: ", "))
            """
        }
        
        finalPrompt += """
        
        First, show your thinking process on how you're analyzing the job requirements and matching them to my experience.
        Then provide the tailored resume in markdown format.
        """
        
        let messages: [[String: Any]] = [
            ["role": "user", "content": finalPrompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": "deepseek-reasoner",
            "messages": messages,
            "temperature": 1.5,
            "max_tokens": 8192,
            "frequency_penalty": 0.25,
            "presence_penalty": 0.0,
            "top_p": 0.95
        ]
        
        let response = try await makeAPIRequest(requestBody: requestBody)
        let content = response.content
        
        // Split the response into thinking and final output
        let parts = splitThinkingAndOutput(content)
        return parts
    }
    
    func generateTailoredCoverLetter(prompt: String, jobDescription: String, existingCoverLetter: String, skills: [String]) async throws -> (thinking: String, output: String) {
        var finalPrompt = prompt.isEmpty ? 
        """
        # Task
        Read through my existing cover letter and the job description, then tailor my cover letter to better match the job based on the details in the job description.
        
        # Instructions
        1. Analyze the job description to identify key requirements, values, and qualifications.
        2. Adjust my existing cover letter to highlight relevant experience and skills that match these requirements.
        3. Use keywords from the job posting in the tailored cover letter.
        4. Make the cover letter more specific to this role and company.
        5. Format the response in markdown.
        6. Maintain my original voice and style as much as possible.
        """ : prompt
        
        finalPrompt += """
        
        # Job Description
        ```
        \(jobDescription)
        ```
        
        # My Existing Cover Letter
        ```
        \(existingCoverLetter)
        ```
        """
        
        if !skills.isEmpty {
            finalPrompt += """
            
            # Desired Skills
            \(skills.joined(separator: ", "))
            """
        }
        
        finalPrompt += """
        
        First, show your thinking process on how you're analyzing the job requirements and how to improve the cover letter.
        Then provide the tailored cover letter in markdown format.
        """
        
        let messages: [[String: Any]] = [
            ["role": "user", "content": finalPrompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": "deepseek-reasoner",
            "messages": messages,
            "temperature": 1.5,
            "max_tokens": 8192,
            "frequency_penalty": 0.25,
            "presence_penalty": 0.0,
            "top_p": 0.95
        ]
        
        let response = try await makeAPIRequest(requestBody: requestBody)
        let content = response.content
        
        // Split the response into thinking and final output
        let parts = splitThinkingAndOutput(content)
        return parts
    }
    
    private func makeAPIRequest(requestBody: [String: Any]) async throws -> (content: String) {
        guard let url = URL(string: apiEndpoint) else {
            throw NSError(domain: "AIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
        } catch {
            throw NSError(domain: "AIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize request body"])
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AIService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorJson?["error"] as? [String: Any]
            let message = errorMessage?["message"] as? String ?? "Unknown error"
            throw NSError(domain: "AIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw NSError(domain: "AIService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
            }
            
            return (content: content)
        } catch {
            throw NSError(domain: "AIService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response: \(error.localizedDescription)"])
        }
    }
    
    private func splitThinkingAndOutput(_ content: String) -> (thinking: String, output: String) {
        // Look for markers that might separate thinking from output
        let possibleSeparators = [
            "# Tailored Resume",
            "## Tailored Resume",
            "### Tailored Resume",
            "Here's the tailored resume:",
            "Tailored Resume:",
            "# Tailored Cover Letter",
            "## Tailored Cover Letter",
            "### Tailored Cover Letter",
            "Here's the tailored cover letter:",
            "Tailored Cover Letter:"
        ]
        
        for separator in possibleSeparators {
            if let range = content.range(of: separator) {
                let thinking = String(content[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                let output = String(content[range.lowerBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                return (thinking, output)
            }
        }
        
        // If no clear separator is found, try to find the first markdown header
        if let range = content.range(of: "^#+ ", options: .regularExpression) {
            let prevContent = String(content[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !prevContent.isEmpty {
                return (prevContent, String(content[range.lowerBound...]).trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        
        // If we can't clearly separate, return the whole content as output
        return ("", content)
    }
}

// MARK: - JobStore
// MARK: - Updated JobStore with SwiftData Integration
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
    @Published var userResume: Resume = Resume.load()
    @Published var isShowingResumeEditor = false

    // Variables for AI Resume & Cover Letter Enhancement
    @Published var isGeneratingTailoredResume = false
    @Published var isGeneratingTailoredCoverLetter = false
    @Published var aiThinkingSteps: String = ""
    @Published var isShowingAIResumeWindow = false
    @Published var isShowingAICoverLetterWindow = false

    private let modelContext: ModelContext
    private let aiService = AIService()

    init(documentStore: DocumentStore? = nil, modelContext: ModelContext) {
        self.modelContext = modelContext
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

    // Add, Edit, Duplicate, Delete
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
            crossJobSkillNames: job.crossJobSkillNames,
            tailoredResumes: job.tailoredResumes,
            tailoredCoverLetters: job.tailoredCoverLetters
        )
        jobApplications.append(newJob)
        sortJobs(by: sorting)
        saveJobs()
    }

    // Status, Type, Favorite
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

    // Sorting
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

    // Save & Load
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
                    crossJobSkillNames: job.crossJobSkillNames,
                    tailoredResumes: job.tailoredResumes,
                    tailoredCoverLetters: job.tailoredCoverLetters
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

    // Backup Import / Export
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

    // Skills
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

    // Skill Parsing (Single Job Only)
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
        // For each job, see if the skill or any aliases is in that job's description
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

    // AI Resume & Cover Letter Enhancement
    func generateTailoredResume(prompt: String, jobDescription: String, resume: String, skills: [String]) async -> (Bool, String) {
        do {
            await MainActor.run {
                isGeneratingTailoredResume = true
                aiThinkingSteps = "Starting AI processing..."
            }
            
            let result = try await aiService.generateTailoredResume(
                prompt: prompt,
                jobDescription: jobDescription,
                resume: resume,
                skills: skills
            )
            
            await MainActor.run {
                self.aiThinkingSteps = result.thinking
            }
            
            return (true, result.output)
        } catch {
            let errorMessage = "Error: \(error.localizedDescription)"
            await MainActor.run {
                self.aiThinkingSteps = errorMessage
                self.isGeneratingTailoredResume = false
            }
            return (false, errorMessage)
        }
    }
    
    func addTailoredResumeToJob(jobId: UUID, tailoredResume: String) {
        if let index = jobApplications.firstIndex(where: { $0.id == jobId }) {
            // Initialize the array if it doesn't exist
            if jobApplications[index].tailoredResumes == nil {
                jobApplications[index].tailoredResumes = []
            }
            
            // Add the new tailored resume to the array
            jobApplications[index].tailoredResumes?.append(tailoredResume)
            saveJobs()
            
            // Reset the generating state
            isGeneratingTailoredResume = false
        }
    }

    func generateTailoredCoverLetter(prompt: String, jobDescription: String, coverLetter: String, skills: [String]) async -> (Bool, String) {
        do {
            await MainActor.run {
                isGeneratingTailoredCoverLetter = true
                aiThinkingSteps = "Starting AI processing..."
            }
            
            let result = try await aiService.generateTailoredCoverLetter(
                prompt: prompt,
                jobDescription: jobDescription,
                existingCoverLetter: coverLetter,
                skills: skills
            )
            
            await MainActor.run {
                self.aiThinkingSteps = result.thinking
            }
            
            return (true, result.output)
        } catch {
            let errorMessage = "Error: \(error.localizedDescription)"
            await MainActor.run {
                self.aiThinkingSteps = errorMessage
                self.isGeneratingTailoredCoverLetter = false
            }
            return (false, errorMessage)
        }
    }
    
    func addTailoredCoverLetterToJob(jobId: UUID, tailoredCoverLetter: String) {
        if let index = jobApplications.firstIndex(where: { $0.id == jobId }) {
            // Initialize the array if it doesn't exist
            if jobApplications[index].tailoredCoverLetters == nil {
                jobApplications[index].tailoredCoverLetters = []
            }
            
            // Add the new tailored cover letter to the array
            jobApplications[index].tailoredCoverLetters?.append(tailoredCoverLetter)
            saveJobs()
            
            // Reset the generating state
            isGeneratingTailoredCoverLetter = false
        }
    }

    func saveResume() {
        userResume.save()
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
    private let modelContext: ModelContext

    // Variables to track memory usage
    private var cachedPDFDocuments: [UUID: PDFDocument] = [:]

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

    /// Merges a set of new documents into our store, ignoring duplicates.
    func mergeDocuments(_ newDocs: [JobDocument]) {
        for doc in newDocs {
            if !documents.contains(doc) {
                documents.append(doc)
            }
        }

        saveDocuments()
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
                documents = swiftDataDocs.map { $0.toJobDocument() }
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

// MARK: - ImportExportHelper
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

// MARK: - JobViewModel
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

        // Also hold onto job's min/max if present
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
        let parts = trimmed.components(separatedBy: ["-", "–"])
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
            crossJobSkillNames: originalJob.crossJobSkillNames,
            tailoredResumes: originalJob.tailoredResumes,
            tailoredCoverLetters: originalJob.tailoredCoverLetters
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
        
        // Additional window for AI Resume
        WindowGroup(id: "aiResumeWindow", for: UUID.self) { $jobId in
            if let id = jobId, let job = jobStore.jobApplications.first(where: { $0.id == id }) {
                AIResumeWindow(job: job)
                    .environmentObject(jobStore)
            }
        }
        
        // Additional window for AI Cover Letter
        WindowGroup(id: "aiCoverLetterWindow", for: UUID.self) { $jobId in
            if let id = jobId, let job = jobStore.jobApplications.first(where: { $0.id == id }) {
                AICoverLetterWindow(job: job)
                    .environmentObject(jobStore)
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
                    docStore.uploadDocumentsNonAsync(from: urls)
                }
            }

            Button("Export Documents...") {
                importExportHelper.exportDocuments { url in
                    exportAllDocumentsToZip(url: url)
                }
            }

            Divider()

            Button("Edit Resume...") {
                jobStore.isShowingResumeEditor = true
                let vc = NSHostingController(
                    rootView: ResumeEditorView()
                        .environmentObject(jobStore)
                )
                let window = NSWindow(contentViewController: vc)
                window.title = "Edit Resume"
                window.styleMask = [.titled, .closable, .resizable]
                window.makeKeyAndOrderFront(nil)
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

// MARK: - AI-enhanced Windows
struct AIResumeWindow: View {
    @EnvironmentObject var jobStore: JobStore
    let job: JobApplication
    
    @State private var customPrompt: String = ""
    @State private var jobDescriptionText: String
    @State private var resumeText: String
    @State private var isLoading = false
    @State private var startTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var generatedContent: String = ""
    @State private var errorMessage: String = ""
    
    init(job: JobApplication) {
        self.job = job
        _jobDescriptionText = State(initialValue: job.jobDescription)
        _resumeText = State(initialValue: Resume.load().content)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("AI-Enhanced Resume for \(job.companyName) - \(job.jobTitle)")
                .font(.headline)
            
            // Custom prompt section
            VStack(alignment: .leading) {
                Text("Custom Prompt (Optional)").font(.headline)
                TextEditor(text: $customPrompt)
                    .font(.system(size: 14))
                    .frame(height: 100)
                    .padding(8)
                    .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.gray.opacity(0.5), lineWidth: 1))
            }
            
            // Job description section
            VStack(alignment: .leading) {
                Text("Job Description").font(.headline)
                TextEditor(text: $jobDescriptionText)
                    .font(.system(size: 14))
                    .frame(height: 150)
                    .padding(8)
                    .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.gray.opacity(0.5), lineWidth: 1))
            }
            
            // Resume section
            VStack(alignment: .leading) {
                Text("Your Resume").font(.headline)
                TextEditor(text: $resumeText)
                    .font(.system(size: 14))
                    .frame(height: 150)
                    .padding(8)
                    .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.gray.opacity(0.5), lineWidth: 1))
            }
            
            // Skills section
            VStack(alignment: .leading) {
                Text("Desired Skills").font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(job.desiredSkillNames, id: \.self) { skillName in
                            Text(skillName)
                                .padding(6)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                }
                .frame(height: 40)
            }
            
            if isLoading {
                // Loading state with timer
                VStack {
                    ProgressView("Generating tailored resume...")
                    
                    if let startTime = startTime {
                        Text("Elapsed: \(formattedElapsedTime(from: startTime))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .onAppear {
                                startTimer()
                            }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            } else if !errorMessage.isEmpty {
                // Error message
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Buttons
            HStack {
                Button("Close") {
                    closeWindow()
                }
                .buttonStyle(.bordered)
                .tint(.red)
                
                Spacer()
                
                Button("Generate Tailored Resume") {
                    generateResumeAction()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
            }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 700)
        .onDisappear {
            stopTimer()
        }
    }
    
    private func generateResumeAction() {
        isLoading = true
        startTime = Date()
        errorMessage = ""
        
        Task {
            let (success, result) = await jobStore.generateTailoredResume(
                prompt: customPrompt,
                jobDescription: jobDescriptionText,
                resume: resumeText,
                skills: job.desiredSkillNames
            )
            
            await MainActor.run {
                isLoading = false
                stopTimer()
                
                if success {
                    generatedContent = result
                    jobStore.addTailoredResumeToJob(jobId: job.id, tailoredResume: result)
                    closeWindow()
                } else {
                    errorMessage = result
                }
            }
        }
    }
    
    private func closeWindow() {
        NSApp.keyWindow?.close()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let st = startTime {
                elapsedTime = Date().timeIntervalSince(st)
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formattedElapsedTime(from date: Date) -> String {
        let timeInterval = Date().timeIntervalSince(date)
        let seconds = Int(timeInterval) % 60
        let minutes = Int(timeInterval) / 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct AICoverLetterWindow: View {
    @EnvironmentObject var jobStore: JobStore
    let job: JobApplication
    
    @State private var customPrompt: String = ""
    @State private var jobDescriptionText: String
    @State private var coverLetterText: String
    @State private var isLoading = false
    @State private var startTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var generatedContent: String = ""
    @State private var errorMessage: String = ""
    
    init(job: JobApplication) {
        self.job = job
        _jobDescriptionText = State(initialValue: job.jobDescription)
        _coverLetterText = State(initialValue: job.coverLetter)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("AI-Enhanced Cover Letter for \(job.companyName) - \(job.jobTitle)")
                .font(.headline)
            
            // Custom prompt section
            VStack(alignment: .leading) {
                Text("Custom Prompt (Optional)").font(.headline)
                TextEditor(text: $customPrompt)
                    .font(.system(size: 14))
                    .frame(height: 100)
                    .padding(8)
                    .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.gray.opacity(0.5), lineWidth: 1))
            }
            
            // Job description section
            VStack(alignment: .leading) {
                Text("Job Description").font(.headline)
                TextEditor(text: $jobDescriptionText)
                    .font(.system(size: 14))
                    .frame(height: 150)
                    .padding(8)
                    .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.gray.opacity(0.5), lineWidth: 1))
            }
            
            // Cover Letter section
            VStack(alignment: .leading) {
                Text("Your Cover Letter").font(.headline)
                TextEditor(text: $coverLetterText)
                    .font(.system(size: 14))
                    .frame(height: 150)
                    .padding(8)
                    .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.gray.opacity(0.5), lineWidth: 1))
            }
            
            // Skills section
            VStack(alignment: .leading) {
                Text("Desired Skills").font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(job.desiredSkillNames, id: \.self) { skillName in
                            Text(skillName)
                                .padding(6)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                }
                .frame(height: 40)
            }
            
            if isLoading {
                // Loading state with timer
                VStack {
                    ProgressView("Generating tailored cover letter...")
                    
                    if let startTime = startTime {
                        Text("Elapsed: \(formattedElapsedTime(from: startTime))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .onAppear {
                                startTimer()
                            }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            } else if !errorMessage.isEmpty {
                // Error message
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Buttons
            HStack {
                Button("Close") {
                    closeWindow()
                }
                .buttonStyle(.bordered)
                .tint(.red)
                
                Spacer()
                
                Button("Generate Tailored Cover Letter") {
                    generateCoverLetterAction()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
            }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 700)
        .onDisappear {
            stopTimer()
        }
    }
    
    private func generateCoverLetterAction() {
        isLoading = true
        startTime = Date()
        errorMessage = ""
        
        Task {
            let (success, result) = await jobStore.generateTailoredCoverLetter(
                prompt: customPrompt,
                jobDescription: jobDescriptionText,
                coverLetter: coverLetterText,
                skills: job.desiredSkillNames
            )
            
            await MainActor.run {
                isLoading = false
                stopTimer()
                
                if success {
                    generatedContent = result
                    jobStore.addTailoredCoverLetterToJob(jobId: job.id, tailoredCoverLetter: result)
                    closeWindow()
                } else {
                    errorMessage = result
                }
            }
        }
    }
    
    private func closeWindow() {
        NSApp.keyWindow?.close()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let st = startTime {
                elapsedTime = Date().timeIntervalSince(st)
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formattedElapsedTime(from date: Date) -> String {
        let timeInterval = Date().timeIntervalSince(date)
        let seconds = Int(timeInterval) % 60
        let minutes = Int(timeInterval) / 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - ContentView
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
                JobDetailView(job: job)
                    .id(job.id) // Force view refresh when job changes
            } else {
                Text("Select a job to view details")
                    .foregroundColor(.secondary)
            }
        case .stats:
            StatsScrollView()
        case .documents:
            DocumentsMainView()
        }
    }
}

// MARK: - StatsScrollView (Wrapper to avoid crashes)
struct StatsScrollView: View {
    @State private var didLoadStats = false
    
    var body: some View {
        // This wrapper prevents immediate loading of EnhancedStatsView which might cause a crash
        ZStack {
            if didLoadStats {
                EnhancedStatsView()
            } else {
                ProgressView("Loading stats...")
                    .onAppear {
                        // Delay the loading of stats view to ensure proper initialization
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            didLoadStats = true
                        }
                    }
            }
        }
    }
}

// MARK: - JobSidebarView
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

// MARK: - Add & Edit Job Windows
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

// MARK: - AddJobView
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
