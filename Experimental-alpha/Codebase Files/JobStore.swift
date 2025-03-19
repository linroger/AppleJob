//
//  JobStore.swift
//  Experimental-alpha
//
//  Created by Roger Lin on 3/14/25.
//


// -----------------------------------------------------------------------------
// MARK: - JobStore
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
            // Instead of trying to delete the model type, fetch all existing records and delete them individually
            let descriptor = FetchDescriptor<SwiftDataJobApplication>()
            let existingJobs = try ctx.fetch(descriptor)
            for job in existingJobs {
                ctx.delete(job)
            }
            
            // Now insert our new jobs
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


//-----------------------------------------------------------------------------------------------------//
