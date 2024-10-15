

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
//         This ensures older jobs' documents appear in the Documents tab and older salary data is also recognized.
//
//    2) **Include Older Jobs in Charts & Visualizations**
//       - We now parse older jobs' salary strings upon load if numeric `salaryMin` and `salaryMax` are missing.
//         This allows older jobs to appear properly in the Salary Range chart and other stats.
//
//    3) **Salary TextField Parsing**
//       - Updated the salary parsing to handle "K" suffix as thousands (e.g., "70K" → "70000"),
//         and remove patterns like "/", "year", "yr", "per" from the salary text before numeric parsing.
//
//    4) **MarkdownUI (Replacing MarkdownKit)**
//       - Removed `import MarkdownKit` and replaced it with `import MarkdownUI` for rendering the job description,
//         cover letter, and notes in `JobDetailView`.
//
//    5) **Tooltip/Annotation for Salary Range Chart**
//       - Added additional info (company name, job title, application date) to the chart tooltip in `EnhancedStatsView`
//         so users can see which job application they're hovering over.
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
//    8) **Fixed Stats Tab Crash and Performance Issues**
//        - Fixed a thread-safety issue in EnhancedStatsView that was causing crashes.
//        - Optimized chart rendering to reduce memory and CPU usage.
//        - Added proper error handling around potential crash points.
//        - Introduced memory management improvements to reduce RAM usage.
//
//    9) **Added Document Deletion in Sidebar Context Menu**
//        - Added a "Delete Document" button to the document sidebar context menu.
//
//   10) **Integrated AI Resume & Cover Letter Enhancement**
//        - Added "Tailor Resume" and "Tailor Cover Letter" buttons to update resumes and cover letters
//        - Implemented direct API integration with DeepSeek-reasoner using OpenAI-compatible API
//        - Added new "Tailored Resume" and "Tailored Cover Letter" sections with markdown formatting and copy buttons
//        - Each new AI response is appended to the existing ones to provide version history
//
//    11) **Compile Error Fixes for macOS Build**
//        - Removed extra argument 'settings' when creating SettingsView; now we pass `importExportHelper` correctly
//        - Removed usage of any `.page(indexDisplayMode: )` calls (unavailable on macOS) and replaced with standard SwiftUI
//        - Confirmed code is suitable for macOS 15+
//
//  All other code remains intact or only minimally changed to accommodate these updates.
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
import MarkdownUI
import SwiftData
import Combine

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

    @Relationship(deleteRule: .cascade)
    var documents: [SwiftDataJobDocument]

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
    static let aiApiKeysKey = "aiApiKeys" // UserDefaults key for storing API keys

    // Default values for DeepSeek API
    static let defaultAiApiKey = "sk-e5528df49b794732bb7817ce06786f72"

    // API endpoints for different providers
    static let deepseekApiEndpoint = "https://api.deepseek.com/v1/chat/completions"
    static let openaiApiEndpoint = "https://api.openai.com/v1/chat/completions"
    static let anthropicApiEndpoint = "https://api.anthropic.com/v1/messages"
    static let geminiApiEndpoint = "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent"
}

// MARK: - AI Provider Enums

enum AIProvider: String, CaseIterable, Identifiable, Codable {
    case openai = "OpenAI"
    case anthropic = "Anthropic"
    case gemini = "Google Gemini"
    case deepseek = "DeepSeek"

    var id: String { self.rawValue }

    var endpoint: String {
        switch self {
        case .openai:
            return Constants.openaiApiEndpoint
        case .anthropic:
            return Constants.anthropicApiEndpoint
        case .gemini:
            return Constants.geminiApiEndpoint
        case .deepseek:
            return Constants.deepseekApiEndpoint
        }
    }

    var availableModels: [AIModel] {
        switch self {
        case .openai:
            return [.gpt4o, .gpt4Turbo, .gpt35Turbo]
        case .anthropic:
            return [.claude3Opus, .claude3Sonnet, .claude3Haiku]
        case .gemini:
            return [.geminiPro]
        case .deepseek:
            return [.deepseekReasoner, .deepseekCoder]
        }
    }

    var defaultModel: AIModel {
        availableModels.first ?? .gpt35Turbo
    }
}

enum AIModel: String, CaseIterable, Identifiable, Codable {
    // OpenAI models
    case gpt4o = "gpt-4o"
    case gpt4Turbo = "gpt-4-turbo"
    case gpt35Turbo = "gpt-3.5-turbo"

    // Anthropic models
    case claude3Opus = "claude-3-opus-20240229"
    case claude3Sonnet = "claude-3-sonnet-20240229"
    case claude3Haiku = "claude-3-haiku-20240307"

    // Google Gemini models
    case geminiPro = "gemini-pro"

    // DeepSeek models
    case deepseekReasoner = "deepseek-reasoner"
    case deepseekCoder = "deepseek-coder"

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .gpt4o:           return "GPT-4o"
        case .gpt4Turbo:       return "GPT-4 Turbo"
        case .gpt35Turbo:      return "GPT-3.5 Turbo"
        case .claude3Opus:     return "Claude 3 Opus"
        case .claude3Sonnet:   return "Claude 3 Sonnet"
        case .claude3Haiku:    return "Claude 3 Haiku"
        case .geminiPro:       return "Gemini Pro"
        case .deepseekReasoner:return "DeepSeek Reasoner"
        case .deepseekCoder:   return "DeepSeek Coder"
        }
    }

    var provider: AIProvider {
        switch self {
        case .gpt4o, .gpt4Turbo, .gpt35Turbo:
            return .openai
        case .claude3Opus, .claude3Sonnet, .claude3Haiku:
            return .anthropic
        case .geminiPro:
            return .gemini
        case .deepseekReasoner, .deepseekCoder:
            return .deepseek
        }
    }
}

// MARK: - AI Settings Storage

class AISettings: ObservableObject {
    @Published var selectedProvider: AIProvider = .deepseek
    @Published var selectedModel: AIModel = .deepseekReasoner
    @Published var apiKey: String = ""

    private let userDefaults = UserDefaults.standard

    init() {
        loadSettings()
    }

    func loadSettings() {
        if let providerString = userDefaults.string(forKey: "selectedAIProvider"),
           let provider = AIProvider(rawValue: providerString) {
            selectedProvider = provider
        }
        if let modelString = userDefaults.string(forKey: "selectedAIModel"),
           let model = AIModel(rawValue: modelString) {
            selectedModel = model
        }
        // Load API key for the selected provider
        let apiKeysDict = userDefaults.dictionary(forKey: Constants.aiApiKeysKey) as? [String: String] ?? [:]
        apiKey = apiKeysDict[selectedProvider.rawValue] ?? Constants.defaultAiApiKey
    }

    func saveSettings() {
        userDefaults.set(selectedProvider.rawValue, forKey: "selectedAIProvider")
        userDefaults.set(selectedModel.rawValue, forKey: "selectedAIModel")

        // Save API key for the selected provider
        var apiKeysDict = userDefaults.dictionary(forKey: Constants.aiApiKeysKey) as? [String: String] ?? [:]
        apiKeysDict[selectedProvider.rawValue] = apiKey
        userDefaults.set(apiKeysDict, forKey: Constants.aiApiKeysKey)
    }

    func updateProvider(_ provider: AIProvider) {
        selectedProvider = provider
        // If current model isn't compatible with new provider, update to default
        if !provider.availableModels.contains(where: { $0.rawValue == selectedModel.rawValue }) {
            selectedModel = provider.defaultModel
        }
        // Load saved API key for this provider
        let apiKeysDict = userDefaults.dictionary(forKey: Constants.aiApiKeysKey) as? [String: String] ?? [:]
        apiKey = apiKeysDict[provider.rawValue] ?? ""
        saveSettings()
    }

    func updateModel(_ model: AIModel) {
        selectedModel = model
        saveSettings()
    }

    func updateApiKey(_ key: String) {
        apiKey = key
        saveSettings()
    }
}

// MARK: - AI Service

class AIService: ObservableObject {
    static let shared = AIService()

    @Published var isProcessing = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var error: Error?

    private var settings = AISettings()
    private var timer: Timer?
    private var startTime: Date?

    struct AIError: Error, LocalizedError {
        let message: String
        var errorDescription: String? {
            return message
        }
    }

    enum AIRequestType {
        case resume
        case coverLetter

        var systemPrompt: String {
            switch self {
            case .resume:
                return "You are an expert resume writer. Given a job description and optionally a current resume, tailor the resume to highlight relevant skills and experience for the specific job."
            case .coverLetter:
                return "You are an expert cover letter writer. Given a job description and optionally a current cover letter, craft a compelling cover letter that matches the job requirements and highlights relevant qualifications."
            }
        }
    }

    // Process job application with AI to generate resume or cover letter
    func processJobApplicationWithAI(job: JobApplication, userInput: String, type: AIRequestType) async throws -> String {
        // Start timing and processing indicators
        DispatchQueue.main.async {
            self.startTime = Date()
            self.isProcessing = true
            self.error = nil
            self.startTimer()
        }
        do {
            let result = try await generateAIContent(job: job, userInput: userInput, type: type)
            DispatchQueue.main.async {
                self.stopTimer()
                self.isProcessing = false
            }
            return result
        } catch {
            DispatchQueue.main.async {
                self.stopTimer()
                self.isProcessing = false
                self.error = error
            }
            throw error
        }
    }

    private func generateAIContent(job: JobApplication, userInput: String, type: AIRequestType) async throws -> String {
        let provider = settings.selectedProvider
        let model = settings.selectedModel
        let apiKey = settings.apiKey.isEmpty ? Constants.defaultAiApiKey : settings.apiKey

        switch provider {
        case .openai, .deepseek:
            return try await callOpenAICompatibleAPI(
                job: job,
                userInput: userInput,
                type: type,
                endpoint: provider.endpoint,
                model: model.rawValue,
                apiKey: apiKey
            )
        case .anthropic:
            return try await callAnthropicAPI(
                job: job,
                userInput: userInput,
                type: type,
                model: model.rawValue,
                apiKey: apiKey
            )
        case .gemini:
            return try await callGeminiAPI(
                job: job,
                userInput: userInput,
                type: type,
                apiKey: apiKey
            )
        }
    }

    // For OpenAI and DeepSeek APIs (which share the same format)
    private func callOpenAICompatibleAPI(
        job: JobApplication,
        userInput: String,
        type: AIRequestType,
        endpoint: String,
        model: String,
        apiKey: String
    ) async throws -> String {

        // Prepare messages array
        var messages: [[String: Any]] = [
            ["role": "system", "content": type.systemPrompt]
        ]

        // Add job description
        messages.append([
            "role": "user",
            "content": "Here's the job description:\n\n\(job.jobDescription)"
        ])

        // Add current content if available
        if type == .resume, let resumes = job.tailoredResumes, !resumes.isEmpty {
            messages.append([
                "role": "user",
                "content": "Here's my current resume (for reference only):\n\n\(resumes.last ?? "")"
            ])
        } else if type == .coverLetter, let coverLetters = job.tailoredCoverLetters, !coverLetters.isEmpty {
            messages.append([
                "role": "user",
                "content": "Here's my current cover letter (for reference only):\n\n\(coverLetters.last ?? "")"
            ])
        }

        // Add user input as the final message
        messages.append([
            "role": "user",
            "content": userInput
        ])

        // Prepare request body
        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.7
        ]

        // Serialize to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw AIError(message: "Failed to serialize request data")
        }

        // Create URL request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Handle HTTP errors
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError(message: "Invalid response")
        }
        if httpResponse.statusCode != 200 {
            // Try to get error message from response
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorInfo = errorData["error"] as? [String: Any],
               let message = errorInfo["message"] as? String {
                throw AIError(message: "API Error (\(httpResponse.statusCode)): \(message)")
            } else {
                throw AIError(message: "API Error: HTTP \(httpResponse.statusCode)")
            }
        }

        // Parse the successful response
        guard let responseDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = responseDict["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError(message: "Failed to parse API response")
        }

        return content
    }

    // For Anthropic Claude API
    private func callAnthropicAPI(
        job: JobApplication,
        userInput: String,
        type: AIRequestType,
        model: String,
        apiKey: String
    ) async throws -> String {

        // Prepare system prompt
        let systemPrompt = type.systemPrompt

        // Prepare content for messages
        var messages: [[String: Any]] = []

        // Add job description
        messages.append([
            "role": "user",
            "content": "Here's the job description:\n\n\(job.jobDescription)"
        ])

        // Add current content if available
        if type == .resume, let resumes = job.tailoredResumes, !resumes.isEmpty {
            messages.append([
                "role": "user",
                "content": "Here's my current resume (for reference only):\n\n\(resumes.last ?? "")"
            ])
        } else if type == .coverLetter, let coverLetters = job.tailoredCoverLetters, !coverLetters.isEmpty {
            messages.append([
                "role": "user",
                "content": "Here's my current cover letter (for reference only):\n\n\(coverLetters.last ?? "")"
            ])
        }

        // Add user input as the final message
        messages.append([
            "role": "user",
            "content": userInput
        ])

        // Prepare request body
        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages,
            "system": systemPrompt,
            "max_tokens": 4000
        ]

        // Serialize to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw AIError(message: "Failed to serialize request data")
        }

        // Create URL request
        var request = URLRequest(url: URL(string: Constants.anthropicApiEndpoint)!)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "x-api-key")
        request.addValue("anthropic-swift/1.0", forHTTPHeaderField: "anthropic-version")

        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Handle HTTP errors
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError(message: "Invalid response")
        }
        if httpResponse.statusCode != 200 {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorData["error"] as? [String: Any],
               let errorMsg = message["message"] as? String {
                throw AIError(message: "API Error (\(httpResponse.statusCode)): \(errorMsg)")
            } else {
                throw AIError(message: "API Error: HTTP \(httpResponse.statusCode)")
            }
        }

        // Parse the successful response
        guard let responseDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = responseDict["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw AIError(message: "Failed to parse API response")
        }
        return text
    }

    // For Google Gemini API
    private func callGeminiAPI(
        job: JobApplication,
        userInput: String,
        type: AIRequestType,
        apiKey: String
    ) async throws -> String {

        // Prepare content string
        var contentText = "System: \(type.systemPrompt)\n\n"
        contentText += "Job Description:\n\(job.jobDescription)\n\n"

        // Add current content if available
        if type == .resume, let resumes = job.tailoredResumes, !resumes.isEmpty {
            contentText += "Current Resume (for reference only):\n\(resumes.last ?? "")\n\n"
        } else if type == .coverLetter, let coverLetters = job.tailoredCoverLetters, !coverLetters.isEmpty {
            contentText += "Current Cover Letter (for reference only):\n\(coverLetters.last ?? "")\n\n"
        }

        // Add user input
        contentText += "User Request: \(userInput)"

        // Prepare request body
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": contentText]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "topP": 0.95,
                "topK": 40
            ]
        ]

        // Serialize to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw AIError(message: "Failed to serialize request data")
        }

        // Create URL with API key
        let urlString = "\(Constants.geminiApiEndpoint)?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw AIError(message: "Invalid URL")
        }

        // Create URL request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Handle HTTP errors
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError(message: "Invalid response")
        }
        if httpResponse.statusCode != 200 {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIError(message: "API Error (\(httpResponse.statusCode)): \(message)")
            } else {
                throw AIError(message: "API Error: HTTP \(httpResponse.statusCode)")
            }
        }

        // Parse the successful response
        guard let responseDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = responseDict["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw AIError(message: "Failed to parse API response")
        }

        return text
    }

    // Timer methods
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            self.elapsedTime = Date().timeIntervalSince(startTime)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        startTime = nil
    }
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
    case visualizations = "Visualizations"
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
        if let fileURL = fileURL {
            dict["fileURL"] = fileURL.absoluteString
        }
        if let categoryID = categoryID {
            dict["categoryID"] = categoryID.uuidString
        }
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
        else {
            return nil
        }

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
    // Skills auto-added from older logic
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

struct SalaryRangeItem: Identifiable, Equatable, Hashable {
    let id: UUID
    let jobID: UUID
    let company: String
    let jobTitle: String
    let date: Date
    let minSalary: Double
    let maxSalary: Double
    let orderIndex: Int
    let city: String
    let year: Int

    static func == (lhs: SalaryRangeItem, rhs: SalaryRangeItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var displayLabel: String {
        "\(company) - \(jobTitle)"
    }

    var chartTitle: String {
        let maxLength = 30
        let combined = displayLabel
        if combined.count <= maxLength {
            return combined
        }
        return "\(combined.prefix(maxLength))..."
    }
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

// MARK: - Legacy AI API Service

class LegacyAIService {
    private let apiKey: String
    private let apiEndpoint: String
    private var cancellables: Set<AnyCancellable> = []

    init(apiKey: String = Constants.defaultAiApiKey, apiEndpoint: String = Constants.deepseekApiEndpoint) {
        self.apiKey = apiKey
        self.apiEndpoint = apiEndpoint
    }

    func generateAIContent(
        prompt: String,
        jobDescription: String,
        contentToTailor: String,
        skills: [String]
    ) async throws -> String {

        let combinedPrompt = """
        # Task
        Use the following information to create a tailored output.

        # Instructions
        \(prompt)

        # Job Description
        ```
        \(jobDescription)
        ```

        # Content to Tailor
        ```
        \(contentToTailor)
        ```

        # Relevant Skills
        \(skills.joined(separator: ", "))

        Please provide a detailed and well-formatted response.
        """

        let messages: [[String: Any]] = [
            ["role": "user", "content": combinedPrompt]
        ]

        let requestBody: [String: Any] = [
            "model": "deepseek-reasoner",
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 8192
        ]

        let (data, response) = try await URLSession.shared.data(for: createRequest(with: requestBody))

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AIService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        guard httpResponse.statusCode == 200 else {
            let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorJson?["error"] as? [String: Any]
            let message = errorMessage?["message"] as? String ?? "Unknown error"
            throw NSError(domain: "AIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "AIService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }

        return content
    }

    private func createRequest(with body: [String: Any]) throws -> URLRequest {
        guard let url = URL(string: apiEndpoint) else {
            throw NSError(domain: "AIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
}

// MARK: - Timer Helper

class StopwatchManager: ObservableObject {
    @Published var elapsedTime: TimeInterval = 0
    private var timer: Timer?
    private var startTime: Date?

    func start() {
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            self.elapsedTime = Date().timeIntervalSince(startTime)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        startTime = nil
    }

    func reset() {
        stop()
        elapsedTime = 0
    }

    deinit {
        timer?.invalidate()
    }
}

// MARK: - JobStore

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
    // AI processing state tracking
    @Published var isProcessingAI = false
    @Published var aiProgressMessage = ""

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

            var updatedJobs = jobApplications
            updatedJobs[index] = singleJobEdit
            jobApplications = updatedJobs

            sortJobs(by: sorting)
            saveJobs()

            // Force update UI by creating a copy of the array on the main thread
            let tempJobs = jobApplications
            DispatchQueue.main.async {
                self.objectWillChange.send()
                self.jobApplications = tempJobs
            }
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
        saveToSwiftData()

        // Parse salary for older jobs after loading
        for index in jobApplications.indices {
            if jobApplications[index].salaryMin == nil || jobApplications[index].salaryMax == nil {
                parseMissingSalaryMinMax(for: &jobApplications[index])
            }
        }
    }

    private func loadFromUserDefaults() {
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

    // AI Content Generation
    func processAIContent(
        prompt: String,
        jobDescription: String,
        contentToTailor: String,
        skills: [String],
        isForResume: Bool,
        jobId: UUID
    ) async {
        guard let index = jobApplications.firstIndex(where: { $0.id == jobId }) else {
            return
        }
        await MainActor.run {
            isProcessingAI = true
            aiProgressMessage = "Preparing AI request..."
        }
        do {
            let aiService = AIService.shared
            let type: AIService.AIRequestType = isForResume ? .resume : .coverLetter
            let result = try await aiService.processJobApplicationWithAI(
                job: jobApplications[index],
                userInput: prompt,
                type: type
            )
            await MainActor.run {
                if isForResume {
                    var updatedJob = jobApplications[index]
                    if updatedJob.tailoredResumes == nil {
                        updatedJob.tailoredResumes = []
                    }
                    var resumes = updatedJob.tailoredResumes ?? []
                    resumes.append(result)
                    updatedJob.tailoredResumes = resumes
                    jobApplications[index] = updatedJob
                } else {
                    var updatedJob = jobApplications[index]
                    if updatedJob.tailoredCoverLetters == nil {
                        updatedJob.tailoredCoverLetters = []
                    }
                    var coverLetters = updatedJob.tailoredCoverLetters ?? []
                    coverLetters.append(result)
                    updatedJob.tailoredCoverLetters = coverLetters
                    jobApplications[index] = updatedJob
                }
                saveJobs()
                isProcessingAI = false
                aiProgressMessage = ""
            }
        } catch {
            await MainActor.run {
                isProcessingAI = false
                aiProgressMessage = "Error: \(error.localizedDescription)"
            }
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

        if let existing = job.salaryString {
            salaryString = existing
        }
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
        var cleaned = newValue
        cleaned = cleaned.replacingOccurrences(of: "(?i)k", with: "000", options: .regularExpression)
        let patternsToRemove = ["(?i)/", "(?i)year", "(?i)yr", "(?i)per"]
        for pattern in patternsToRemove {
            cleaned = cleaned.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        salaryString = cleaned
        let (minVal, maxVal) = JobViewModel.parseSalaryRangeStatic(cleaned)
        self.salaryMin = minVal
        self.salaryMax = maxVal
    }

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
            let singleVal = parseNumeric(trimmed)
            return (singleVal, nil)
        }
    }

    private static func parseNumeric(_ string: String) -> Double? {
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

    func parseSalaryFromJobDescription() {
        let (formatted, min, max) = JobViewModel.parseSalaryCurrency(from: self.jobDescription)
        if let formatted = formatted {
            self.salaryString = formatted
            self.salaryMin = min
            self.salaryMax = max
        }
    }

    /// Parses the job description for salary information.
    static func parseSalaryCurrency(from description: String) -> (formattedSalary: String?, minSalary: Double?, maxSalary: Double?) {
        guard let salaryMarkerRange = description.range(of: "(?i)Salary:\\s*", options: .regularExpression) else {
            return (nil, nil, nil)
        }
        let substringAfterMarker = description[salaryMarkerRange.upperBound...]
        let salaryLine = substringAfterMarker.split(separator: "\n").first.map(String.init) ?? ""

        let pattern = "\\$(?=\\d{2})[\\d,\\.]+(?:[kK])?"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return (nil, nil, nil)
        }

        let matches = regex.matches(in: salaryLine, options: [], range: NSRange(location: 0, length: salaryLine.utf16.count))
        var salaryValues: [Double] = []

        for match in matches {
            if let range = Range(match.range, in: salaryLine) {
                var salaryString = String(salaryLine[range])
                salaryString = salaryString.replacingOccurrences(of: "(?i)k", with: "000", options: .regularExpression)
                salaryString = salaryString.replacingOccurrences(of: "$", with: "")
                salaryString = salaryString.replacingOccurrences(of: ",", with: "")
                salaryString = salaryString.trimmingCharacters(in: .whitespacesAndNewlines)

                if let value = Double(salaryString) {
                    salaryValues.append(value)
                }
            }
        }

        if salaryValues.isEmpty {
            return (nil, nil, nil)
        }

        let minSalary: Double
        let maxSalary: Double

        if salaryValues.count == 1 {
            minSalary = salaryValues[0]
            maxSalary = salaryValues[0]
        } else {
            minSalary = salaryValues.min() ?? salaryValues[0]
            maxSalary = salaryValues.max() ?? salaryValues[0]
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0

        let formattedMin = formatter.string(from: NSNumber(value: minSalary)) ?? ""
        let formattedMax = formatter.string(from: NSNumber(value: maxSalary)) ?? ""

        let formattedSalary: String
        if minSalary == maxSalary {
            formattedSalary = formattedMax
        } else {
            formattedSalary = "\(formattedMin) – \(formattedMax)"
        }

        return (formattedSalary, minSalary, maxSalary)
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

// MARK: - AI Content View Models

class AICoverLetterViewModel: ObservableObject {
    @Published var prompt: String = "Adapt this cover letter to match the job requirements in the job description. Make it sound professional and highlight relevant experiences and skills."
    @Published var jobDescription: String = ""
    @Published var coverLetter: String = ""
    @Published var selectedSkills: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    // AI provider settings
    @Published var selectedProvider: AIProvider = .deepseek
    @Published var selectedModel: AIModel = .deepseekReasoner
    @Published var apiKey: String = ""

    private let settings = AISettings()

    init() {
        selectedProvider = settings.selectedProvider
        selectedModel = settings.selectedModel
        apiKey = settings.apiKey
    }

    func reset(job: JobApplication) {
        jobDescription = job.jobDescription
        coverLetter = job.coverLetter
        selectedSkills = job.desiredSkillNames
        selectedProvider = settings.selectedProvider
        selectedModel = settings.selectedModel
        apiKey = settings.apiKey
    }

    func saveSettings() {
        settings.selectedProvider = selectedProvider
        settings.selectedModel = selectedModel
        settings.apiKey = apiKey
        settings.saveSettings()
    }

    func updateProvider(_ provider: AIProvider) {
        selectedProvider = provider
        if !provider.availableModels.contains(where: { $0.rawValue == selectedModel.rawValue }) {
            selectedModel = provider.defaultModel
        }
        saveSettings()
    }
}

class AIResumeViewModel: ObservableObject {
    @Published var prompt: String = "Tailor this resume to match the job requirements in the job description. Highlight relevant experiences and skills that align with what the employer is looking for."
    @Published var jobDescription: String = ""
    @Published var resume: String = ""
    @Published var selectedSkills: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    // AI provider settings
    @Published var selectedProvider: AIProvider = .deepseek
    @Published var selectedModel: AIModel = .deepseekReasoner
    @Published var apiKey: String = ""

    private let settings = AISettings()

    init() {
        selectedProvider = settings.selectedProvider
        selectedModel = settings.selectedModel
        apiKey = settings.apiKey
    }

    func reset(job: JobApplication, resumeContent: String) {
        jobDescription = job.jobDescription
        resume = resumeContent
        selectedSkills = job.desiredSkillNames
        selectedProvider = settings.selectedProvider
        selectedModel = settings.selectedModel
        apiKey = settings.apiKey
    }

    func saveSettings() {
        settings.selectedProvider = selectedProvider
        settings.selectedModel = selectedModel
        settings.apiKey = apiKey
        settings.saveSettings()
    }

    func updateProvider(_ provider: AIProvider) {
        selectedProvider = provider
        if !provider.availableModels.contains(where: { $0.rawValue == selectedModel.rawValue }) {
            selectedModel = provider.defaultModel
        }
        saveSettings()
    }
}

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @ObservedObject var importExportHelper: ImportExportHelper

    @StateObject private var aiSettings = AISettings()
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

                // AI Tab
                aiProviderSettings
                    .tabItem {
                        Label("AI Providers", systemImage: "brain")
                    }
                    .tag(2)

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
                Toggle("Autofill Job Details from URL", isOn: .constant(true))
                    .disabled(true)
                Toggle("Save Documents to Global Store", isOn: .constant(true))
                    .disabled(true)
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

    // AI Providers tab content
    private var aiProviderSettings: some View {
        Form {
            Section("AI Provider") {
                Picker("Default AI Provider", selection: $aiSettings.selectedProvider) {
                    ForEach(AIProvider.allCases) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .onChange(of: aiSettings.selectedProvider) { _, newValue in
                    aiSettings.updateProvider(newValue)
                }

                Picker("Default AI Model", selection: $aiSettings.selectedModel) {
                    ForEach(aiSettings.selectedProvider.availableModels, id: \.self) { model in
                        Text(model.displayName).tag(model)
                    }
                }
                .onChange(of: aiSettings.selectedModel) { _, _ in
                    aiSettings.saveSettings()
                }
            }

            Section("API Keys") {
                VStack(alignment: .leading) {
                    HStack {
                        Text(aiSettings.selectedProvider.rawValue)
                        Spacer()
                        SecureField("API Key", text: $aiSettings.apiKey)
                            .frame(maxWidth: 300)
                            .textFieldStyle(.roundedBorder)
                    }
                    Text("Your API key is stored securely in UserDefaults")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                .padding(.vertical, 5)
                Button("Save API Key") {
                    aiSettings.saveSettings()
                }
                .buttonStyle(.borderedProminent)
            }

            Section("AI Content Settings") {
                VStack(alignment: .leading) {
                    Text("Tailor the behavior of AI-generated content")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: .constant(0.7), in: 0.0...1.0, step: 0.1) {
                        Text("Temperature")
                    } minimumValueLabel: {
                        Text("Precise")
                    } maximumValueLabel: {
                        Text("Creative")
                    }
                    .disabled(true)
                }
                .padding(.vertical, 5)
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
}

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @EnvironmentObject var importExportHelper: ImportExportHelper

    @Binding var showSettings: Bool

    @State private var viewSection: ViewSection = .jobDetails
    @State private var searchText = ""
    @State private var isShowingBanner = false
    @State private var bannerMessage = ""
    @State private var bannerType: BannerType = .success

    enum BannerType {
        case success, warning, error
        var color: Color {
            switch self {
            case .success: return .green
            case .warning: return .orange
            case .error:   return .red
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchFilterBarView(searchText: $searchText, jobStore: jobStore)
                List(selection: $jobStore.selectedJobIDs) {
                    if jobStore.jobApplications.isEmpty {
                        Section("Getting Started") {
                            Text("Add your first job application")
                                .font(.headline)
                            Text("Click the + button below or use Cmd+N")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        ForEach(groupedJobs.keys.sorted(by: { lhs, rhs in
                            let lhsFirst = (groupedJobs[lhs]?.first?.dateOfApplication ?? .distantFuture)
                            let rhsFirst = (groupedJobs[rhs]?.first?.dateOfApplication ?? .distantFuture)
                            return lhsFirst > rhsFirst
                        }), id: \.self) { section in
                            Section(section) {
                                let filteredJobs = groupedJobs[section] ?? []
                                JobListView(
                                    jobs: filteredJobs,
                                    selection: $jobStore.selectedJobIDs
                                )
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
                .animation(.easeInOut(duration: 0.2), value: groupedJobs.keys)
                .contextMenu(forSelectionType: UUID.self) { selection in
                    if !selection.isEmpty {
                        Button("Favorite") {
                            for id in selection {
                                jobStore.toggleFavorite(for: id)
                            }
                        }
                        Menu("Update Status") {
                            ForEach(JobStatus.allCases, id: \.self) { status in
                                Button(status.rawValue) {
                                    jobStore.updateJobStatus(selection, to: status)
                                }
                            }
                        }
                        if selection.count == 1,
                           let job = jobStore.jobApplications.first(where: { selection.contains($0.id) }) {
                            Button("Edit") {
                                jobStore.selectedJobIDs = Set([job.id])
                                jobStore.isEditingJob = true
                            }
                        }
                        Button("Delete", role: .destructive) {
                            for id in selection {
                                jobStore.deleteJob(for: id)
                            }
                        }
                    }
                }
                BottomToolbarView(showAddJobWindow: {
                    jobStore.isAddingNewJob = true
                }, viewSection: $viewSection)
            }
            .frame(minWidth: 250)

            // Main Content Area
            Group {
                if jobStore.jobApplications.isEmpty && jobStore.selectedJobIDs.isEmpty {
                    WelcomeView {
                        jobStore.isAddingNewJob = true
                    }
                } else if jobStore.selectedJobIDs.isEmpty {
                    NoSelectionView()
                } else if let job = jobStore.selectedJob {
                    if viewSection == .jobDetails {
                        JobDetailView(job: job)
                    } else if viewSection == .documents {
                        DocumentsMainView()
                    } else if viewSection == .stats {
                        EnhancedStatsView()
                    }
                } else {
                    Text("Select a job in the sidebar")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(minWidth: 450)
        }
        .toolbar {
            ToolbarItemGroup {
                Picker("View", selection: $viewSection) {
                    ForEach(ViewSection.allCases, id: \.rawValue) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)

                Button(action: {
                    jobStore.isShowingResumeEditor = true
                }) {
                    Label("Edit Resume", systemImage: "doc.text")
                }

                Menu {
                    Button("Export Backup") {
                        importExportHelper.exportBackup { url in
                            jobStore.exportBackup(url: url)
                        }
                    }
                    Button("Import Backup") {
                        importExportHelper.importBackup { url in
                            jobStore.importBackup(url: url)
                        }
                    }
                    Button("Import Documents") {
                        importExportHelper.importDocuments { urls in
                            docStore.uploadDocumentsNonAsync(from: urls)
                        }
                    }
                    Divider()
                    Button("Settings") {
                        showSettings = true
                    }
                } label: {
                    Label("Options", systemImage: "gear")
                }
            }
        }
        .sheet(isPresented: $jobStore.isShowingResumeEditor) {
            ResumeEditorView()
                .environmentObject(jobStore)
        }
        .sheet(isPresented: $jobStore.isAddingNewJob) {
            AddJobWindowView()
                .environmentObject(jobStore)
                .environmentObject(docStore)
        }
        .sheet(isPresented: $jobStore.isEditingJob) {
            if let job = jobStore.selectedJob {
                EditJobWindowView(job: job)
                    .environmentObject(jobStore)
                    .environmentObject(docStore)
            }
        }
        .sheet(isPresented: $showSettings) {
            // **FIXED**: Pass importExportHelper instead of 'settings'
            SettingsView(importExportHelper: importExportHelper)
                .environmentObject(jobStore)
                .environmentObject(docStore)
        }
        .overlay(alignment: .top) {
            if isShowingBanner {
                bannerView
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
    }

    private var bannerView: some View {
        HStack {
            Image(systemName: bannerType == .success ? "checkmark.circle.fill"
                            : (bannerType == .warning ? "exclamationmark.triangle.fill" : "xmark.circle.fill"))
                .foregroundColor(.white)
            Text(bannerMessage)
                .foregroundColor(.white)
            Spacer()
            Button {
                withAnimation {
                    isShowingBanner = false
                }
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(bannerType.color)
        .cornerRadius(8)
        .padding()
    }

    // Computed property to group jobs by status
    private var groupedJobs: [String: [JobApplication]] {
        var result = [String: [JobApplication]]()
        let filteredJobs = jobStore.jobApplications.filter {
            searchText.isEmpty
            || $0.companyName.localizedCaseInsensitiveContains(searchText)
            || $0.jobTitle.localizedCaseInsensitiveContains(searchText)
            || $0.location.localizedCaseInsensitiveContains(searchText)
        }

        let byStatus = Dictionary(grouping: filteredJobs) { $0.status.rawValue }

        for status in JobStatus.allCases {
            let statusJobs = byStatus[status.rawValue] ?? []
            if !statusJobs.isEmpty {
                var sorted = [JobApplication]()
                switch jobStore.sorting {
                case .company:
                    sorted = statusJobs.sorted { $0.companyName < $1.companyName }
                case .title:
                    sorted = statusJobs.sorted { $0.jobTitle < $1.jobTitle }
                case .recentlyApplied:
                    sorted = statusJobs.sorted { $0.dateOfApplication > $1.dateOfApplication }
                }
                result[status.rawValue] = sorted
            }
        }
        return result
    }

    func showBanner(_ message: String, type: BannerType) {
        bannerMessage = message
        bannerType = type
        withAnimation {
            isShowingBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                isShowingBanner = false
            }
        }
    }
}

// MARK: - Main App

@main
struct AppleJobApp: App {
    @StateObject private var jobStore: JobStore
    @StateObject private var docStore: DocumentStore
    @StateObject private var importExportHelper = ImportExportHelper()
    @StateObject private var appSettings = AppSettings()

    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: SwiftDataJobApplication.self,
                SwiftDataJobDocument.self,
                configurations: ModelConfiguration()
            )
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }

        let stores = AppleJobApp.createStores(using: container)
        _docStore = StateObject(wrappedValue: stores.documentStore)
        _jobStore = StateObject(wrappedValue: stores.jobStore)
    }

    private static func createStores(using container: ModelContainer) -> (documentStore: DocumentStore, jobStore: JobStore) {
        let documentStore = DocumentStore(modelContext: container.mainContext)
        let jobStore = JobStore(documentStore: documentStore, modelContext: container.mainContext)
        return (documentStore, jobStore)
    }

    @State private var showSettings = false

    var body: some Scene {
        WindowGroup {
            ContentView(showSettings: $showSettings)
                .environmentObject(jobStore)
                .environmentObject(docStore)
                .environmentObject(importExportHelper)
                .sheet(isPresented: $showSettings) {
                    // Here we pass importExportHelper to fix the compile error
                    SettingsView(importExportHelper: importExportHelper)
                        .environmentObject(jobStore)
                        .environmentObject(docStore)
                }
        }
        .modelContainer(container)
        .commands {
            fileMenuCommands
            editMenuCommands
            settingsCommands
        }
    }

    private var settingsCommands: some Commands {
        CommandMenu("Settings") {
            Button("Settings...") {
                showSettings = true
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
                    .contentTransition(.opacity)
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
            .animation(.easeInOut, value: jobStore.selectedJobIDs.contains(job.id))
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
        withAnimation {
            for idx in offsets {
                let job = filteredJobs[idx]
                jobStore.deleteJob(for: job.id)
            }
        }
    }
}

// MARK: - SidebarRowItem

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
                .fontWeight(isSelected ? .bold : .regular)
                .padding(5)
                .background(
                    Capsule().fill(isSelected ? Color.white.opacity(0.7) : job.status.displayColor.opacity(0.2))
                )
                .foregroundColor(isSelected ? job.status.displayColor : job.status.displayColor)
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
            withAnimation(.easeInOut(duration: 0.15)) {
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
            .transition(.slide)
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
            .transition(.slide)
            .onDisappear {
                jobStore.isEditingJob = false
            }
    }
}

// MARK: - AICoverLetterView

struct AICoverLetterView: View {
    @EnvironmentObject var jobStore: JobStore
    @StateObject private var viewModel = AICoverLetterViewModel()
    @StateObject private var aiService = AIService.shared
    @State private var windowRef: NSWindow?
    @State private var stopwatchManager = StopwatchManager()

    let job: JobApplication

    var body: some View {
        VStack(spacing: 12) {
            Text("AI Cover Letter Generator")
                .font(.headline)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 4) {
                Text("AI Provider").font(.headline)
                Picker("AI Provider", selection: $viewModel.selectedProvider) {
                    ForEach(AIProvider.allCases) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.selectedProvider) { _, newValue in
                    viewModel.updateProvider(newValue)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("AI Model").font(.headline)
                Picker("AI Model", selection: $viewModel.selectedModel) {
                    ForEach(viewModel.selectedProvider.availableModels, id: \.self) { model in
                        Text(model.displayName).tag(model)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.selectedModel) { _, _ in
                    viewModel.saveSettings()
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("API Key").font(.headline)
                SecureField("Enter API key", text: $viewModel.apiKey)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: viewModel.apiKey) { _, _ in
                        viewModel.saveSettings()
                    }
            }
            .padding(.bottom, 8)

            Group {
                Text("Prompt").font(.headline)
                TextEditor(text: $viewModel.prompt)
                    .modifier(UltraThinMaterialTextEditorStyle())
                    .frame(height: 80)
            }

            Group {
                Text("Job Description").font(.headline)
                TextEditor(text: $viewModel.jobDescription)
                    .modifier(UltraThinMaterialTextEditorStyle())
                    .frame(height: 120)
            }

            Group {
                Text("Cover Letter").font(.headline)
                TextEditor(text: $viewModel.coverLetter)
                    .modifier(UltraThinMaterialTextEditorStyle())
                    .frame(height: 120)
            }

            Group {
                Text("Relevant Skills").font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.selectedSkills, id: \.self) { skillName in
                            ZStack {
                                Text(skillName)
                                    .padding(6)
                                    .foregroundColor(.black)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.yellow.opacity(0.5)]),
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

            HStack {
                Button("Close") {
                    closeWindow()
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Spacer()

                if aiService.isProcessing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.7)
                            .padding(.trailing, 5)
                        Text("Processing: \(formattedElapsedTime)")
                            .font(.subheadline)
                    }
                    .padding(.horizontal)
                    Button("Cancel") {
                        stopwatchManager.stop()
                        closeWindow()
                    }
                    .buttonStyle(.bordered)

                } else {
                    Button("Generate") {
                        Task {
                            stopwatchManager.reset()
                            stopwatchManager.start()
                            do {
                                let result = try await aiService.processJobApplicationWithAI(
                                    job: job,
                                    userInput: viewModel.prompt,
                                    type: .coverLetter
                                )
                                if let index = jobStore.jobApplications.firstIndex(where: { $0.id == job.id }) {
                                    var updatedJob = jobStore.jobApplications[index]
                                    var coverLetters = updatedJob.tailoredCoverLetters ?? []
                                    coverLetters.append(result)
                                    updatedJob.tailoredCoverLetters = coverLetters
                                    jobStore.editJob(with: updatedJob)
                                }
                                stopwatchManager.stop()
                                closeWindow()
                            } catch {
                                viewModel.errorMessage = error.localizedDescription
                                stopwatchManager.stop()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
            }
            .padding(.top, 10)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 8)
            }
        }
        .padding()
        .frame(width: 600, height: 800)
        .onAppear {
            viewModel.reset(job: job)
            if windowRef == nil {
                if let kWindow = NSApp.windows.first(where: { $0.isKeyWindow }) {
                    windowRef = kWindow
                }
            }
        }
        .onReceive(stopwatchManager.$elapsedTime) { _ in }
    }

    private var formattedElapsedTime: String {
        let seconds = Int(stopwatchManager.elapsedTime)
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    private func closeWindow() {
        windowRef?.close()
    }
}

// MARK: - AIResumeView

struct AIResumeView: View {
    @EnvironmentObject var jobStore: JobStore
    @StateObject private var viewModel = AIResumeViewModel()
    @StateObject private var aiService = AIService.shared
    @State private var windowRef: NSWindow?
    @State private var stopwatchManager = StopwatchManager()

    let job: JobApplication

    var body: some View {
        VStack(spacing: 12) {
            Text("AI Resume Generator")
                .font(.headline)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 4) {
                Text("AI Provider").font(.headline)
                Picker("AI Provider", selection: $viewModel.selectedProvider) {
                    ForEach(AIProvider.allCases) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.selectedProvider) { _, newValue in
                    viewModel.updateProvider(newValue)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("AI Model").font(.headline)
                Picker("AI Model", selection: $viewModel.selectedModel) {
                    ForEach(viewModel.selectedProvider.availableModels, id: \.self) { model in
                        Text(model.displayName).tag(model)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.selectedModel) { _, _ in
                    viewModel.saveSettings()
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("API Key").font(.headline)
                SecureField("Enter API key", text: $viewModel.apiKey)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: viewModel.apiKey) { _, _ in
                        viewModel.saveSettings()
                    }
            }
            .padding(.bottom, 8)

            Group {
                Text("Prompt").font(.headline)
                TextEditor(text: $viewModel.prompt)
                    .modifier(UltraThinMaterialTextEditorStyle())
                    .frame(height: 80)
            }

            Group {
                Text("Job Description").font(.headline)
                TextEditor(text: $viewModel.jobDescription)
                    .modifier(UltraThinMaterialTextEditorStyle())
                    .frame(height: 120)
            }

            Group {
                Text("Resume").font(.headline)
                TextEditor(text: $viewModel.resume)
                    .modifier(UltraThinMaterialTextEditorStyle())
                    .frame(height: 120)
            }

            Group {
                Text("Relevant Skills").font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.selectedSkills, id: \.self) { skillName in
                            ZStack {
                                Text(skillName)
                                    .padding(6)
                                    .foregroundColor(.black)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.yellow.opacity(0.5)]),
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

            HStack {
                Button("Close") {
                    closeWindow()
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Spacer()

                if aiService.isProcessing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.7)
                            .padding(.trailing, 5)
                        Text("Processing: \(formattedElapsedTime)")
                            .font(.subheadline)
                    }
                    .padding(.horizontal)
                    Button("Cancel") {
                        stopwatchManager.stop()
                        closeWindow()
                    }
                    .buttonStyle(.bordered)

                } else {
                    Button("Generate") {
                        Task {
                            stopwatchManager.reset()
                            stopwatchManager.start()
                            do {
                                let result = try await aiService.processJobApplicationWithAI(
                                    job: job,
                                    userInput: viewModel.prompt,
                                    type: .resume
                                )
                                if let index = jobStore.jobApplications.firstIndex(where: { $0.id == job.id }) {
                                    var updatedJob = jobStore.jobApplications[index]
                                    var resumes = updatedJob.tailoredResumes ?? []
                                    resumes.append(result)
                                    updatedJob.tailoredResumes = resumes
                                    jobStore.editJob(with: updatedJob)
                                }
                                stopwatchManager.stop()
                                closeWindow()
                            } catch {
                                viewModel.errorMessage = error.localizedDescription
                                stopwatchManager.stop()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
            }
            .padding(.top, 10)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 8)
            }
        }
        .padding()
        .frame(width: 600, height: 800)
        .onAppear {
            viewModel.reset(job: job, resumeContent: jobStore.userResume.content)
            if windowRef == nil {
                if let kWindow = NSApp.windows.first(where: { $0.isKeyWindow }) {
                    windowRef = kWindow
                }
            }
        }
        .onReceive(stopwatchManager.$elapsedTime) { _ in }
    }

    private var formattedElapsedTime: String {
        let seconds = Int(stopwatchManager.elapsedTime)
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    private func closeWindow() {
        windowRef?.close()
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
    @State private var showCelebration = false
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
                                viewModel.parseSalaryFromJobDescription()
                            }
                            Button("Paste") {
                                if let clip = NSPasteboard.general.string(forType: .string) {
                                    viewModel.jobDescription = clip
                                    viewModel.parseSalaryFromJobDescription()
                                }
                            }
                        }
                        TextEditor(text: $viewModel.jobDescription)
                            .modifier(UltraThinMaterialTextEditorStyle())
                            .frame(height: 180)

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
                                    docStore.mergeDocuments(importedDocuments)
                                    for i in 0..<importedDocuments.count {
                                        importedDocuments[i].associatedCompany = viewModel.companyName
                                        importedDocuments[i].associatedJobTitle = viewModel.jobTitle
                                        importedDocuments[i].associatedApplicationDate = viewModel.dateOfApplication
                                    }
                                    viewModel.addJob(to: jobStore, documents: importedDocuments)
                                    withAnimation {
                                        showCelebration = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
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
                    .transition(.scale)
                    .zIndex(1)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
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

// MARK: - EditJobView

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
    @State private var showCelebration = false
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
                                    withAnimation {
                                        showCelebration = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
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
                    .transition(.scale)
                    .zIndex(1)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
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
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: suggestions)
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
                .transition(.scale)
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
        .transition(.scale)
    }
}

// MARK: - UltraThinMaterialTextEditorStyle

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

// MARK: - NewLocationWindowView & NewLocationView

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
        .transition(.slide)
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

// MARK: - EnhancedStatsView

enum SalaryChartDisplayOption: String, CaseIterable, Identifiable {
    case `default` = "Default"
    case city = "City"
    case year = "Year"

    var id: String { rawValue }
}

struct SalaryChartState {
    var colorMapping: [String: Color] = [:]
}

struct EnhancedStatsView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore

    @State private var selectedSalaryValue: Double?
    @State private var salaryRangeData: [SalaryRangeItem] = []
    @State private var hoveredJobID: UUID? = nil
    @State private var hoveredPieJobID: UUID? = nil
    @State private var hoveredSalaryItemID: UUID? = nil
    @State private var selectedSalaryChartOption: SalaryChartDisplayOption = .default
    @State private var lastUpdateTimestamp = Date()
    @State private var salaryChartState = SalaryChartState()

    @State private var hoveredCityData: (city: String, count: Int)? = nil
    @State private var isLoadingData = false
    @State private var loadingError: Error? = nil

    @State private var selectedYear: Int = -1
    @State private var availableYears: [Int] = []
    @State private var selectedTimeRange: TimeRange = .month
    @AppStorage("StatsViewTimeRange") private var selectedTimeRangeRaw: String = TimeRange.month.rawValue

    @State private var cityPins: [CityPin] = []
    @State private var barLineData: [DailyApps] = []
    @State private var yearContributionData: [Contribution] = []
    @State private var appsContributionData: [Contribution] = []
    @State private var monthlyCityData: [MonthlyCityData] = []
    @State private var filteredMonthlyCityData: [MonthlyCityData] = []

    @State private var barLineSelectedDate: Date? = nil
    @State private var yearChartSelectedDate: Date? = nil
    @State private var appsChartSelectedDate: Date? = nil

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 50)
    )

    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case sixmonth = "Six Months"
        case year = "Year"

        var id: String { rawValue }
    }

    var body: some View {
        VStack {
            if isLoadingData {
                ProgressView("Loading data...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = loadingError {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    Text("Error loading data")
                        .font(.title)
                    Text(error.localizedDescription)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Try Again") {
                        loadingError = nil
                        setupViewOnAppear()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                BasicStatsView(
                    cityPins: cityPins,
                    selectedYear: selectedYear,
                    region: $region,
                    monthlyCityData: filteredMonthlyCityData,
                    hoveredCityData: $hoveredCityData,
                    barLineData: barLineData,
                    barLineSelectedDate: $barLineSelectedDate,
                    yearContributionData: yearContributionData,
                    appsContributionData: appsContributionData,
                    yearChartSelectedDate: $yearChartSelectedDate,
                    appsChartSelectedDate: $appsChartSelectedDate,
                    selectedTimeRange: $selectedTimeRange
                )
                .environmentObject(jobStore)
            }
        }
        .onAppear {
            setupViewOnAppear()
        }
        .onChange(of: selectedTimeRange) { _, _ in
            selectedTimeRangeRaw = selectedTimeRange.rawValue
            safeAsyncDataComputations()
        }
        .onChange(of: selectedYear) { _, _ in
            safeRefreshYearDependentData()
        }
        .onChange(of: monthlyCityData) { _, _ in
            filterMonthlyCityDataForSelectedYear()
        }
    }

    private func setupViewOnAppear() {
        isLoadingData = true
        loadingError = nil
        DispatchQueue.global(qos: .userInitiated).async {
            if let tr = TimeRange(rawValue: self.selectedTimeRangeRaw) {
                self.selectedTimeRange = tr
            } else {
                self.selectedTimeRange = .month
            }

            let availableYearsResult = self.setupAvailableYears()

            DispatchQueue.main.async {
                self.availableYears = availableYearsResult.years
                if self.selectedYear == -1 || !availableYearsResult.years.contains(self.selectedYear) {
                    self.selectedYear = availableYearsResult.defaultYear
                }
                self.safeRefreshYearDependentData()
                self.safeAsyncDataComputations()
            }
        }
    }

    private func safeRefreshYearDependentData() {
        guard !isLoadingData else { return }
        isLoadingData = true
        loadingError = nil

        DispatchQueue.global(qos: .userInitiated).async {
            let cityPinsResult = self.buildCityPins()
            let yearContributionResult = self.buildYearContribution()
            let appsContributionResult = self.buildAppsContribution()
            let monthlyCityDataResult = self.buildMonthlyCityData()

            DispatchQueue.main.async {
                self.cityPins = cityPinsResult
                self.yearContributionData = yearContributionResult
                self.appsContributionData = appsContributionResult
                self.monthlyCityData = monthlyCityDataResult
                self.filterMonthlyCityDataForSelectedYear()
                self.isLoadingData = false
            }
        }
    }

    private func setupAvailableYears() -> (years: [Int], defaultYear: Int) {
        let allDates = jobStore.jobApplications.map { $0.dateOfApplication }
        guard !allDates.isEmpty else {
            return ([], -1)
        }
        let cal = Calendar.current
        guard let minDate = allDates.min(), let maxDate = allDates.max() else {
            return ([], -1)
        }
        let minYear = cal.component(.year, from: minDate)
        let maxYear = cal.component(.year, from: maxDate)
        let years = minYear <= maxYear ? Array(minYear...maxYear) : []
        return (years, -1)
    }

    private func safeAsyncDataComputations() {
        guard !isLoadingData else { return }
        isLoadingData = true
        loadingError = nil
        Task {
            do {
                try await Task.sleep(nanoseconds: 50_000_000)
                if Task.isCancelled { return }

                async let cityPinsResult = buildCityPinsAsync()
                async let barLineDataResult = buildBarLineDataAsync()
                async let monthlyCityDataResult = buildMonthlyCityDataAsync()

                let (cityPins, barLineData, monthlyCityData) = await (
                    try cityPinsResult,
                    try barLineDataResult,
                    try monthlyCityDataResult
                )
                if Task.isCancelled { return }

                await MainActor.run {
                    self.cityPins = cityPins
                    self.barLineData = barLineData
                    self.monthlyCityData = monthlyCityData
                    self.filterMonthlyCityDataForSelectedYear()
                    self.isLoadingData = false
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.loadingError = error
                        self.isLoadingData = false
                    }
                }
            }
        }
    }

    private func buildCityPinsAsync() async throws -> [CityPin] {
        return buildCityPins()
    }
    private func buildBarLineDataAsync() async throws -> [DailyApps] {
        return buildBarLineData()
    }
    private func buildMonthlyCityDataAsync() async throws -> [MonthlyCityData] {
        return buildMonthlyCityData()
    }

    private func buildCityPins() -> [CityPin] {
        var cityCount: [String: Int] = [:]
        for job in jobStore.jobApplications {
            if selectedYear == -1 || Calendar.current.component(.year, from: job.dateOfApplication) == selectedYear {
                cityCount[job.location, default: 0] += 1
            }
        }
        return cityCount.map { (city, ct) in
            let coord = CityCoordinateDictionary[city] ??
                       CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795)
            return CityPin(city: city, coordinate: coord, count: ct)
        }
    }

    private func buildYearContribution() -> [Contribution] {
        let cal = Calendar.current
        let yearToShow = selectedYear == -1 ? cal.component(.year, from: Date()) : selectedYear
        guard let startDate = cal.date(from: DateComponents(year: yearToShow, month: 1, day: 1)),
              let endDate = cal.date(from: DateComponents(year: yearToShow, month: 12, day: 31))
        else { return [] }
        let today = cal.startOfDay(for: Date())

        var allDays: [Date] = []
        var day = cal.startOfDay(for: startDate)
        while day <= endDate {
            allDays.append(day)
            if let nxt = cal.date(byAdding: .day, value: 1, to: day) {
                day = nxt
            } else { break }
        }

        return allDays.map { date in
            let dateStatus: Int
            if cal.isDate(date, inSameDayAs: today) {
                dateStatus = 1
            } else if date < today {
                dateStatus = 2
            } else {
                dateStatus = 0
            }
            return Contribution(date: date, count: dateStatus)
        }
    }

    private func buildAppsContribution() -> [Contribution] {
        let cal = Calendar.current
        if selectedYear == -1 {
            let today = Date()
            let startDate = cal.date(byAdding: .month, value: -11, to: cal.startOfDay(for: today)) ?? today
            let endDate = today
            var appsMap: [Date: Int] = [:]
            for job in jobStore.jobApplications {
                if job.dateOfApplication >= startDate && job.dateOfApplication <= endDate {
                    let day = cal.startOfDay(for: job.dateOfApplication)
                    appsMap[day, default: 0] += 1
                }
            }
            var allDays: [Date] = []
            var day = cal.startOfDay(for: startDate)
            while day <= endDate {
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
                if cal.component(.year, from: job.dateOfApplication) == selectedYear {
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
        DispatchQueue.main.async {
            let cal = Calendar.current
            if self.selectedYear == -1 {
                self.filteredMonthlyCityData = self.monthlyCityData
            } else {
                self.filteredMonthlyCityData = self.monthlyCityData.filter {
                    cal.component(.year, from: $0.date) == self.selectedYear
                }
            }
        }
    }
}

// MARK: - AppSettings

class AppSettings: ObservableObject {
    @Published var usesDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(usesDarkMode, forKey: "usesDarkMode")
            applyAppearance()
        }
    }

    @Published var autoSaveEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoSaveEnabled, forKey: "autoSaveEnabled")
        }
    }

    @Published var autoSaveInterval: Int {
        didSet {
            UserDefaults.standard.set(autoSaveInterval, forKey: "autoSaveInterval")
        }
    }

    @Published var defaultJobStatus: JobStatus {
        didSet {
            UserDefaults.standard.set(defaultJobStatus.rawValue, forKey: "defaultJobStatus")
        }
    }

    init() {
        self.usesDarkMode = UserDefaults.standard.bool(forKey: "usesDarkMode")
        self.autoSaveEnabled = UserDefaults.standard.bool(forKey: "autoSaveEnabled")
        self.autoSaveInterval = UserDefaults.standard.integer(forKey: "autoSaveInterval")

        if let statusString = UserDefaults.standard.string(forKey: "defaultJobStatus"),
           let status = JobStatus(rawValue: statusString) {
            self.defaultJobStatus = status
        } else {
            self.defaultJobStatus = .interested
        }

        if self.autoSaveInterval == 0 {
            self.autoSaveInterval = 5
        }
        applyAppearance()
    }

    private func applyAppearance() {
        NSApp.appearance = usesDarkMode ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
    }
}

// MARK: - SearchFilterBarView

struct SearchFilterBarView: View {
    @Binding var searchText: String
    @ObservedObject var jobStore: JobStore

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search applications", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
            }

            Divider()

            Menu {
                Button("By Company Name") {
                    jobStore.sorting = .company
                }
                Button("By Job Title") {
                    jobStore.sorting = .title
                }
                Button("By Recent Application") {
                    jobStore.sorting = .recentlyApplied
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.up.arrow.down")
                    Text(sortText)
                }
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.15))
        )
        .padding([.horizontal, .top], 8)
    }

    private var sortText: String {
        switch jobStore.sorting {
        case .company: return "Company"
        case .title: return "Title"
        case .recentlyApplied: return "Recent"
        }
    }
}

// MARK: - WelcomeView

struct WelcomeView: View {
    var addAction: () -> Void

    var body: some View {
        VStack(spacing: 25) {
            Image(systemName: "briefcase.fill")
                .font(.system(size: 70))
                .foregroundColor(.blue)
            Text("Welcome to AppleJob")
                .font(.largeTitle)
                .bold()
            Text("Your job application tracking app")
                .font(.title3)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 15) {
                FeatureRow(icon: "checkmark.square.fill", title: "Track job applications", description: "Keep all your job applications in one place")
                FeatureRow(icon: "doc.fill", title: "Store documents", description: "Save your resume, cover letters, and other documents")
                FeatureRow(icon: "chart.bar.fill", title: "View statistics", description: "See data visualizations of your job search")
                FeatureRow(icon: "brain.head.profile", title: "AI Assistance", description: "Generate tailored resumes and cover letters")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1))
            )

            Button(action: addAction) {
                Text("Add Your First Job Application")
                    .font(.headline)
                    .padding()
                    .frame(width: 300)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .padding(.top, 10)

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - BottomToolbarView

struct BottomToolbarView: View {
    var showAddJobWindow: () -> Void
    @Binding var viewSection: ViewSection

    var body: some View {
        HStack {
            Button(action: showAddJobWindow) {
                Image(systemName: "plus")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("n", modifiers: .command)
            .help("Add New Job Application (⌘N)")

            Spacer()

            Picker("View", selection: $viewSection) {
                ForEach(ViewSection.allCases, id: \.self) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
        }
        .padding(8)
        .background(Color(.windowBackgroundColor))
    }
}

// MARK: - NoSelectionView

struct NoSelectionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.left.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Job Selected")
                .font(.title)
                .foregroundColor(.secondary)
            Text("Select a job application from the sidebar to view its details")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

// MARK: - ImportExportHelper

class ImportExportHelper: ObservableObject {
    @Published var isExporting = false
    @Published var isImporting = false

    func exportBackup(completion: @escaping (URL) -> Void) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "AppleJobBackup_\(Date().formatted(.dateTime.year().month().day()))"
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        panel.begin { response in
            if response == .OK, let url = panel.url {
                completion(url)
            }
        }
    }

    func importBackup(completion: @escaping (URL) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.json]
        panel.begin { response in
            if response == .OK, let url = panel.url {
                completion(url)
            }
        }
    }

    func exportDocuments(completion: @escaping (URL) -> Void) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "AppleJobDocuments_\(Date().formatted(.dateTime.year().month().day()))"
        panel.allowedContentTypes = [.zip]
        panel.canCreateDirectories = true
        panel.begin { response in
            if response == .OK, let url = panel.url {
                completion(url)
            }
        }
    }

    func importDocuments(completion: @escaping ([URL]) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.pdf, .plainText, .rtf, .image]
        panel.begin { response in
            if response == .OK {
                completion(panel.urls)
            }
        }
    }
}

// MARK: - JobListView

struct JobListView: View {
    let jobs: [JobApplication]
    @Binding var selection: Set<UUID>
    @EnvironmentObject var jobStore: JobStore

    var body: some View {
        ForEach(jobs) { job in
            SidebarRowItem(job: job)
                .tag(job.id)
        }
        .onDelete(perform: deleteJobs)
    }

    private func deleteJobs(at offsets: IndexSet) {
        withAnimation {
            for idx in offsets {
                let job = jobs[idx]
                jobStore.deleteJob(for: job.id)
            }
        }
    }
}

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
                            .contentTransition(.opacity)
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
                            .contentTransition(.opacity)
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
            Button("Delete Document", role: .destructive) {
                docStore.deleteDocument(doc)
            }
            Divider()
            Menu("Move to Category...") {
                ForEach(docStore.categories, id: \.id) { category in
                    Button(category.name) {
                        docStore.assignDocument(doc, to: category)
                    }
                }
                Divider()
                Button("No Category") {
                    docStore.unassignDocument(doc)
                }
            }
            Divider()
            Button("Edit Document Info...") {
                docStore.beginEditMetadata(for: doc)
            }
            Button("Quick Look Preview") {
                openQuickLook(doc)
            }
        }
        .tag(doc)
    }

    private func cleanFileName(_ filename: String) -> String {
        var cleanedName = filename
        cleanedName = cleanedName.replacingOccurrences(of: "_", with: " ")
        for ext in [".pdf", ".docx", ".rtf", ".txt", ".pages"] {
            if cleanedName.hasSuffix(ext) {
                cleanedName = String(cleanedName.dropLast(ext.count))
                break
            }
        }
        return cleanedName.trimmingCharacters(in: .whitespaces)
    }

    private func openQuickLook(_ doc: JobDocument) {
        if let fileURL = doc.fileURL {
            docStore.quickLookURL = fileURL
        } else {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(doc.fileName)
            do {
                try doc.fileData.write(to: tempURL)
                docStore.quickLookURL = tempURL
            } catch {
                print("Failed to open Quick Look: \(error)")
            }
        }
    }
}

// MARK: - NewCategorySheet

struct NewCategorySheet: View {
    @EnvironmentObject var docStore: DocumentStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Text("Create New Category")
                .font(.headline)

            TextField("Category Name", text: $docStore.newCategoryName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Spacer()

                Button("Create") {
                    if !docStore.newCategoryName.isEmpty {
                        docStore.createNewCategory(name: docStore.newCategoryName)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(docStore.newCategoryName.isEmpty)
            }
            .padding()
        }
        .frame(width: 300, height: 150)
        .padding()
    }
}

// MARK: - DocumentsMainView

struct DocumentsMainView: View {
    @EnvironmentObject var docStore: DocumentStore
    @State private var quickLookURL: URL? = nil
    @State private var showNoDocumentSelected = false

    var body: some View {
        ZStack {
            if showNoDocumentSelected {
                Text("Please select a document from the sidebar")
                    .font(.title3)
                    .foregroundColor(.secondary)
            } else if let selectedDoc = docStore.selectedDocument {
                documentView(for: selectedDoc)
            } else {
                Color.clear
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if docStore.selectedDocument == nil {
                                showNoDocumentSelected = true
                            }
                        }
                    }
            }
        }
        .onReceive(docStore.$selectedDocument) { _ in
            showNoDocumentSelected = false
        }
        .quickLookPreview($quickLookURL)
        .sheet(isPresented: $docStore.isEditingMetadata) {
            if let doc = docStore.documentToEdit {
                DocumentMetadataEditorView(document: doc, isPresented: $docStore.isEditingMetadata)
                    .environmentObject(docStore)
                    .frame(width: 400, height: 400)
            }
        }
    }

    @ViewBuilder
    private func documentView(for doc: JobDocument) -> some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(doc.fileName)
                        .font(.title2)
                        .bold()
                    if let company = doc.associatedCompany {
                        Text("Associated with: \(company)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    if let created = formatDate(doc.creationDate) {
                        Text("Created: \(created)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let modified = formatDate(doc.lastModifiedDate) {
                        Text("Modified: \(modified)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding()

            Divider()

            if doc.fileName.lowercased().hasSuffix(".pdf") {
                PDFInlineViewer(fileURL: doc.fileURL, fileData: doc.fileData, documentID: doc.id)
                    .environmentObject(docStore)
            } else if doc.fileName.lowercased().hasSuffix(".txt")
                   || doc.fileName.lowercased().hasSuffix(".rtf") {
                if let str = String(data: doc.fileData, encoding: .utf8) {
                    ScrollView {
                        Text(str)
                            .font(.system(size: 14, design: .monospaced))
                            .padding()
                    }
                } else {
                    Text("Cannot display text content")
                        .foregroundColor(.secondary)
                }
            } else if doc.fileName.lowercased().hasSuffix(".jpg")
                   || doc.fileName.lowercased().hasSuffix(".jpeg")
                   || doc.fileName.lowercased().hasSuffix(".png") {
                if let nsImage = NSImage(data: doc.fileData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                } else {
                    Text("Cannot display image")
                        .foregroundColor(.secondary)
                }
            } else {
                Button {
                    openQuickLook(doc)
                } label: {
                    VStack {
                        Image(systemName: "doc")
                            .font(.system(size: 60))
                        Text("Open to view this document")
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func formatDate(_ date: Date) -> String? {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
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

// MARK: - PDFInlineViewer

struct PDFInlineViewer: NSViewRepresentable {
    let fileURL: URL?
    let fileData: Data
    @EnvironmentObject var docStore: DocumentStore
    var documentID: UUID?

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        if let id = documentID,
           let cachedDoc = docStore.getPDFDocument(for: JobDocument(
               id: id,
               fileName: "",
               fileData: fileData
           )) {
            pdfView.document = cachedDoc
        } else {
            pdfView.document = PDFDocument(data: fileData)
        }
        return pdfView
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        if nsView.document == nil {
            if let id = documentID,
               let cachedDoc = docStore.getPDFDocument(for: JobDocument(
                   id: id,
                   fileName: "",
                   fileData: fileData
               )) {
                nsView.document = cachedDoc
            } else {
                nsView.document = PDFDocument(data: fileData)
            }
        }
    }
}

// MARK: - DocumentInfoPopover

struct DocumentInfoPopover: View {
    @EnvironmentObject var docStore: DocumentStore
    let document: JobDocument?

    var body: some View {
        if let doc = document {
            VStack(alignment: .leading, spacing: 10) {
                Text("Document Information")
                    .font(.headline)
                Group {
                    Text("Filename: \(doc.fileName)")
                    Text("Size: \(formatFileSize(doc.fileSize))")
                    if let created = formatDate(doc.creationDate) {
                        Text("Created: \(created)")
                    }
                    if let modified = formatDate(doc.lastModifiedDate) {
                        Text("Modified: \(modified)")
                    }
                    if let company = doc.associatedCompany {
                        Text("Associated company: \(company)")
                    }
                    if let jobTitle = doc.associatedJobTitle {
                        Text("Associated job: \(jobTitle)")
                    }
                    if let appDate = doc.associatedApplicationDate,
                       let formattedDate = formatDate(appDate) {
                        Text("Application date: \(formattedDate)")
                    }
                }
                .font(.subheadline)
                Divider()
                Button("Edit Metadata") {
                    if let doc = document {
                        docStore.beginEditMetadata(for: doc)
                    }
                }
                .buttonStyle(.bordered)

                Button("Unassociate from job") {
                    if let docID = document?.id,
                       let idx = docStore.documents.firstIndex(where: { $0.id == docID }) {
                        var updatedDoc = docStore.documents[idx]
                        updatedDoc.associatedCompany = nil
                        updatedDoc.associatedJobTitle = nil
                        updatedDoc.associatedApplicationDate = nil
                        docStore.documents[idx] = updatedDoc
                        docStore.saveDocuments()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .opacity(doc.associatedCompany != nil ? 1.0 : 0.5)
                .disabled(doc.associatedCompany == nil)
            }
            .padding()
            .frame(width: 300)
        } else {
            Text("No document selected")
                .padding()
        }
    }

    private func formatFileSize(_ size: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }

    private func formatDate(_ date: Date) -> String? {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - DocumentMetadataEditorView

struct DocumentMetadataEditorView: View {
    @EnvironmentObject var docStore: DocumentStore
    let document: JobDocument
    @Binding var isPresented: Bool

    @State private var fileName: String
    @State private var categoryID: UUID?
    @State private var associatedCompany: String
    @State private var associatedJobTitle: String
    @State private var associatedApplicationDate: Date?

    init(document: JobDocument, isPresented: Binding<Bool>) {
        self.document = document
        self._isPresented = isPresented
        _fileName = State(initialValue: document.fileName)
        _categoryID = State(initialValue: document.categoryID)
        _associatedCompany = State(initialValue: document.associatedCompany ?? "")
        _associatedJobTitle = State(initialValue: document.associatedJobTitle ?? "")
        _associatedApplicationDate = State(initialValue: document.associatedApplicationDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Edit Document Metadata")
                .font(.headline)

            VStack(alignment: .leading) {
                Text("Filename:")
                    .font(.subheadline)
                TextField("Filename", text: $fileName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            VStack(alignment: .leading) {
                Text("Category:")
                    .font(.subheadline)
                Picker("Category", selection: $categoryID) {
                    Text("No Category").tag(nil as UUID?)
                    ForEach(docStore.categories) { category in
                        Text(category.name).tag(category.id as UUID?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }

            VStack(alignment: .leading) {
                Text("Associated Company:")
                    .font(.subheadline)
                TextField("Company Name", text: $associatedCompany)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            VStack(alignment: .leading) {
                Text("Associated Job Title:")
                    .font(.subheadline)
                TextField("Job Title", text: $associatedJobTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            VStack(alignment: .leading) {
                Toggle("Has Application Date", isOn: Binding(
                    get: { associatedApplicationDate != nil },
                    set: {
                        if !$0 {
                            associatedApplicationDate = nil
                        } else if associatedApplicationDate == nil {
                            associatedApplicationDate = Date()
                        }
                    }
                ))
                if associatedApplicationDate != nil {
                    DatePicker(
                        "Application Date",
                        selection: Binding(
                            get: { associatedApplicationDate ?? Date() },
                            set: { associatedApplicationDate = $0 }
                        ),
                        displayedComponents: .date
                    )
                    .datePickerStyle(GraphicalDatePickerStyle())
                }
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Spacer()

                Button("Save") {
                    saveChanges()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
        .padding()
    }

    private func saveChanges() {
        if let index = docStore.documents.firstIndex(where: { $0.id == document.id }) {
            var updatedDoc = docStore.documents[index]
            updatedDoc.fileName = fileName
            updatedDoc.categoryID = categoryID
            updatedDoc.associatedCompany = associatedCompany.isEmpty ? nil : associatedCompany
            updatedDoc.associatedJobTitle = associatedJobTitle.isEmpty ? nil : associatedJobTitle
            updatedDoc.associatedApplicationDate = associatedApplicationDate
            docStore.documents[index] = updatedDoc
            docStore.saveDocuments()
        }
    }
}

// MARK: - JobDetailView

struct JobDetailView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    let job: JobApplication

    @State private var windowRef: NSWindow?
    @State private var quickLookURL: URL? = nil
    @Environment(\.colorScheme) var colorScheme
    @State private var showAIThinkingSteps = false
    @State private var selectedResumeVersion = 0
    @State private var selectedCoverLetterVersion = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                CompanyHeaderView(job: job)
                StatusInfoView(job: job)
                DocumentsSectionView(job: job)
                SkillsSectionView(job: job)
                DescriptionSectionView(job: job)

                if !job.coverLetter.isEmpty {
                    Divider()
                    Text("Cover Letter").font(.headline)
                    Markdown(job.coverLetter)
                } else {
                    Text("No cover letter required.")
                        .foregroundColor(.secondary)
                }

                Divider()
                Text("Notes").font(.headline)
                if let userNotes = job.notes, !userNotes.isEmpty {
                    Markdown(userNotes)
                } else {
                    Text("No notes provided.").foregroundColor(.secondary)
                }

                if let tailoredResumes = job.tailoredResumes, !tailoredResumes.isEmpty {
                    Divider()
                    tailoredResumeSection(tailoredResumes)
                }

                if let tailoredCoverLetters = job.tailoredCoverLetters, !tailoredCoverLetters.isEmpty {
                    Divider()
                    tailoredCoverLetterSection(tailoredCoverLetters)
                }
            }
            .padding()
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .toolbar {
            ToolbarItemGroup {
                Button {
                    showAICoverLetterWindow()
                } label: {
                    Label("Tailor Cover Letter", systemImage: "envelope.badge.shield.half.filled")
                }
                .help("Generate a tailored cover letter with AI")

                Button {
                    showAIResumeWindow()
                } label: {
                    Label("Tailor Resume", systemImage: "doc.badge.gearshape")
                }
                .help("Generate a tailored resume with AI")

                Divider()

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

                if jobStore.isProcessingAI {
                    ProgressView()
                        .scaleEffect(0.7)
                        .help("AI processing in progress...")
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
        .transition(.opacity)
        .id(job.id)
    }

    private func tailoredResumeSection(_ resumes: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tailored Resume").font(.headline)
                if resumes.count > 1 {
                    Picker("Version", selection: $selectedResumeVersion) {
                        ForEach(0..<resumes.count, id: \.self) { index in
                            Text("Version \(index+1)").tag(index)
                        }
                    }
                    .frame(width: 120)
                }
                Spacer()
                Button {
                    copyToClipboard(resumes[selectedResumeVersion])
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
            }
            Markdown(resumes[selectedResumeVersion])
                .padding(.top, 4)
        }
    }

    private func tailoredCoverLetterSection(_ coverLetters: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tailored Cover Letter").font(.headline)
                if coverLetters.count > 1 {
                    Picker("Version", selection: $selectedCoverLetterVersion) {
                        ForEach(0..<coverLetters.count, id: \.self) { index in
                            Text("Version \(index+1)").tag(index)
                        }
                    }
                    .frame(width: 120)
                }
                Spacer()
                Button {
                    copyToClipboard(coverLetters[selectedCoverLetterVersion])
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
            }
            Markdown(coverLetters[selectedCoverLetterVersion])
                .padding(.top, 4)
        }
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func showAICoverLetterWindow() {
        let vc = NSHostingController(
            rootView: AICoverLetterView(job: job)
                .environmentObject(jobStore)
                .environmentObject(docStore)
        )
        let window = NSWindow(contentViewController: vc)
        window.title = "AI Cover Letter Generator"
        window.styleMask = [.titled, .closable, .resizable]
        window.makeKeyAndOrderFront(nil)
    }

    private func showAIResumeWindow() {
        let vc = NSHostingController(
            rootView: AIResumeView(job: job)
                .environmentObject(jobStore)
                .environmentObject(docStore)
        )
        let window = NSWindow(contentViewController: vc)
        window.title = "AI Resume Generator"
        window.styleMask = [.titled, .closable, .resizable]
        window.makeKeyAndOrderFront(nil)
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
                .transition(.scale)
            Text(job.jobTitle)
                .font(.title2)
                .gradientForeground(colors: [.red, .orange])
                .transition(.scale)
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
        .transition(.opacity) // Add row item transition
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

// MARK: - PDFInlineViewer
struct PDFInlineViewer: NSViewRepresentable {
    let fileURL: URL?
    let fileData: Data
    @EnvironmentObject var docStore: DocumentStore
    var documentID: UUID?

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        // Try to get cached PDF document if available
        if let id = documentID, let cachedDoc = docStore.getPDFDocument(for: JobDocument(
            id: id,
            fileName: "",
            fileData: fileData
        )) {
            pdfView.document = cachedDoc
        } else {
            pdfView.document = PDFDocument(data: fileData)
        }

        return pdfView
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        if nsView.document == nil {
            if let id = documentID, let cachedDoc = docStore.getPDFDocument(for: JobDocument(
                id: id,
                fileName: "",
                fileData: fileData
            )) {
                nsView.document = cachedDoc
            } else {
                nsView.document = PDFDocument(data: fileData)
            }
        }
    }
}

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

            Button("Delete Document", role: .destructive) {
                docStore.deleteDocument(doc)
            }

            Divider()

            Menu("Move to Category...") {
                ForEach(docStore.categories, id: \.id) { category in
                    Button(category.name) {
                        docStore.assignDocument(doc, to: category)
                    }
                }

                Divider()

                Button("No Category") {
                    docStore.unassignDocument(doc)
                }
            }

            Divider()

            Button("Edit Document Info...") {
                docStore.beginEditMetadata(for: doc)
            }

            Button("Quick Look Preview") {
                openQuickLook(doc)
            }
        }
        .tag(doc)
    }

    private func cleanFileName(_ filename: String) -> String {
        var cleanedName = filename
        cleanedName = cleanedName.replacingOccurrences(of: "_", with: " ")

        for ext in [".pdf", ".docx", ".rtf", ".txt", ".pages"] {
            if cleanedName.hasSuffix(ext) {
                cleanedName = String(cleanedName.dropLast(ext.count))
                break
            }
        }

        return cleanedName.trimmingCharacters(in: .whitespaces)
    }

    private func openQuickLook(_ doc: JobDocument) {
        if let fileURL = doc.fileURL {
            docStore.quickLookURL = fileURL
        } else {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(doc.fileName)
            do {
                try doc.fileData.write(to: tempURL)
                docStore.quickLookURL = tempURL
            } catch {
                print("Failed to open Quick Look: \(error)")
            }
        }
    }
}

// MARK: - NewCategorySheet
struct NewCategorySheet: View {
    @EnvironmentObject var docStore: DocumentStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Text("Create New Category")
                .font(.headline)

            TextField("Category Name", text: $docStore.newCategoryName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Spacer()

                Button("Create") {
                    if !docStore.newCategoryName.isEmpty {
                        docStore.createNewCategory(name: docStore.newCategoryName)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(docStore.newCategoryName.isEmpty)
            }
            .padding()
        }
        .frame(width: 300, height: 150)
        .padding()
    }
}

// MARK: - DocumentsMainView
struct DocumentsMainView: View {
    @EnvironmentObject var docStore: DocumentStore
    @State private var quickLookURL: URL? = nil
    @State private var showNoDocumentSelected = false

    var body: some View {
        ZStack {
            if showNoDocumentSelected {
                Text("Please select a document from the sidebar")
                    .font(.title3)
                    .foregroundColor(.secondary)
            } else if let selectedDoc = docStore.selectedDocument {
                documentView(for: selectedDoc)
            } else {
                Color.clear
                    .onAppear {
                        // Show "no document selected" after a brief delay
                        // to avoid flashing message during loading
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if docStore.selectedDocument == nil {
                                showNoDocumentSelected = true
                            }
                        }
                    }
            }
        }
        .onReceive(docStore.$selectedDocument) { _ in
            showNoDocumentSelected = false
        }
        .quickLookPreview($quickLookURL)
        .sheet(isPresented: $docStore.isEditingMetadata) {
            if let doc = docStore.documentToEdit {
                DocumentMetadataEditorView(document: doc, isPresented: $docStore.isEditingMetadata)
                    .environmentObject(docStore)
                    .frame(width: 400, height: 400)
            }
        }
    }

    @ViewBuilder
    private func documentView(for doc: JobDocument) -> some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(doc.fileName)
                        .font(.title2)
                        .bold()

                    if let company = doc.associatedCompany {
                        Text("Associated with: \(company)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let created = formatDate(doc.creationDate) {
                        Text("Created: \(created)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let modified = formatDate(doc.lastModifiedDate) {
                        Text("Modified: \(modified)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding()

            Divider()

            if doc.fileName.lowercased().hasSuffix(".pdf") {
                PDFInlineViewer(fileURL: doc.fileURL, fileData: doc.fileData, documentID: doc.id)
                    .environmentObject(docStore)
            } else if doc.fileName.lowercased().hasSuffix(".txt") ||
                      doc.fileName.lowercased().hasSuffix(".rtf") {
                if let str = String(data: doc.fileData, encoding: .utf8) {
                    ScrollView {
                        Text(str)
                            .font(.system(size: 14, design: .monospaced))
                            .padding()
                    }
                } else {
                    Text("Cannot display text content")
                        .foregroundColor(.secondary)
                }
            } else if doc.fileName.lowercased().hasSuffix(".jpg") ||
                      doc.fileName.lowercased().hasSuffix(".jpeg") ||
                      doc.fileName.lowercased().hasSuffix(".png") {
                if let nsImage = NSImage(data: doc.fileData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                } else {
                    Text("Cannot display image")
                        .foregroundColor(.secondary)
                }
            } else {
                Button {
                    openQuickLook(doc)
                } label: {
                    VStack {
                        Image(systemName: "doc")
                            .font(.system(size: 60))
                        Text("Open to view this document")
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func formatDate(_ date: Date) -> String? {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
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

// MARK: - DocumentInfoPopover
struct DocumentInfoPopover: View {
    @EnvironmentObject var docStore: DocumentStore
    let document: JobDocument?

    var body: some View {
        if let doc = document {
            VStack(alignment: .leading, spacing: 10) {
                Text("Document Information")
                    .font(.headline)

                Group {
                    Text("Filename: \(doc.fileName)")
                    Text("Size: \(formatFileSize(doc.fileSize))")

                    if let created = formatDate(doc.creationDate) {
                        Text("Created: \(created)")
                    }

                    if let modified = formatDate(doc.lastModifiedDate) {
                        Text("Modified: \(modified)")
                    }

                    if let company = doc.associatedCompany {
                        Text("Associated company: \(company)")
                    }

                    if let jobTitle = doc.associatedJobTitle {
                        Text("Associated job: \(jobTitle)")
                    }

                    if let appDate = doc.associatedApplicationDate,
                       let formattedDate = formatDate(appDate) {
                        Text("Application date: \(formattedDate)")
                    }
                }
                .font(.subheadline)

                Divider()

                Button("Edit Metadata") {
                    docStore.beginEditMetadata(for: doc)
                }
                .buttonStyle(.bordered)

                Button("Unassociate from job") {
                    if let idx = docStore.documents.firstIndex(where: { $0.id == doc.id }) {
                        var updatedDoc = docStore.documents[idx]
                        updatedDoc.associatedCompany = nil
                        updatedDoc.associatedJobTitle = nil
                        updatedDoc.associatedApplicationDate = nil
                        docStore.documents[idx] = updatedDoc
                        docStore.saveDocuments()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .opacity(doc.associatedCompany != nil ? 1.0 : 0.5)
                .disabled(doc.associatedCompany == nil)
            }
            .padding()
            .frame(width: 300)
        } else {
            Text("No document selected")
                .padding()
        }
    }

    private func formatFileSize(_ size: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }

    private func formatDate(_ date: Date) -> String? {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - DocumentMetadataEditorView
struct DocumentMetadataEditorView: View {
    @EnvironmentObject var docStore: DocumentStore
    let document: JobDocument
    @Binding var isPresented: Bool

    @State private var fileName: String
    @State private var categoryID: UUID?
    @State private var associatedCompany: String
    @State private var associatedJobTitle: String
    @State private var associatedApplicationDate: Date?

    init(document: JobDocument, isPresented: Binding<Bool>) {
        self.document = document
        self._isPresented = isPresented

        _fileName = State(initialValue: document.fileName)
        _categoryID = State(initialValue: document.categoryID)
        _associatedCompany = State(initialValue: document.associatedCompany ?? "")
        _associatedJobTitle = State(initialValue: document.associatedJobTitle ?? "")
        _associatedApplicationDate = State(initialValue: document.associatedApplicationDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Edit Document Metadata")
                .font(.headline)

            VStack(alignment: .leading) {
                Text("Filename:")
                    .font(.subheadline)
                TextField("Filename", text: $fileName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            VStack(alignment: .leading) {
                Text("Category:")
                    .font(.subheadline)
                Picker("Category", selection: $categoryID) {
                    Text("No Category").tag(nil as UUID?)
                    ForEach(docStore.categories) { category in
                        Text(category.name).tag(category.id as UUID?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }

            VStack(alignment: .leading) {
                Text("Associated Company:")
                    .font(.subheadline)
                TextField("Company Name", text: $associatedCompany)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            VStack(alignment: .leading) {
                Text("Associated Job Title:")
                    .font(.subheadline)
                TextField("Job Title", text: $associatedJobTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            VStack(alignment: .leading) {
                Toggle("Has Application Date", isOn: Binding(
                    get: { associatedApplicationDate != nil },
                    set: { if !$0 { associatedApplicationDate = nil } else if associatedApplicationDate == nil { associatedApplicationDate = Date() } }
                ))

                if associatedApplicationDate != nil {
                    DatePicker(
                        "Application Date",
                        selection: Binding(
                            get: { associatedApplicationDate ?? Date() },
                            set: { associatedApplicationDate = $0 }
                        ),
                        displayedComponents: .date
                    )
                    .datePickerStyle(GraphicalDatePickerStyle())
                }
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Spacer()

                Button("Save") {
                    saveChanges()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
        .padding()
    }

    private func saveChanges() {
        if let index = docStore.documents.firstIndex(where: { $0.id == document.id }) {
            var updatedDoc = docStore.documents[index]
            updatedDoc.fileName = fileName
            updatedDoc.categoryID = categoryID
            updatedDoc.associatedCompany = associatedCompany.isEmpty ? nil : associatedCompany
            updatedDoc.associatedJobTitle = associatedJobTitle.isEmpty ? nil : associatedJobTitle
            updatedDoc.associatedApplicationDate = associatedApplicationDate

            docStore.documents[index] = updatedDoc
            docStore.saveDocuments()
        }
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
            EnhancedStatsView()
        case .documents:
            DocumentsMainView()
                .id(docStore.selectedDocument?.id) // Force view refresh when selected document changes
        }
    }
}

