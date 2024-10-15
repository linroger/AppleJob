
//
//  DetailedViews.swift
//  AppleJob
//
//  Created by Your Name on YYYY/MM/DD
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers
import MarkdownKit

// --------------------------------------------------
// MARK: - Supporting Enums and Structures
// --------------------------------------------------

enum JobStatus: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }
    case interested = "Interested"
    case applied = "Applied"
    case interview = "Interview"
    case offer = "Offer"
    case rejection = "Rejection"
}

enum JobType: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }
    case internship = "Internship"
    case fullTime = "Full Time"
    case offCycleInternship = "Off-Cycle Internship"
    case none = "None"
}

/// A structure representing an application update.
struct ApplicationUpdate: Identifiable {
    let id = UUID()
    var status: JobStatus
    var date: Date
}

// --------------------------------------------------
// MARK: - Gradient Background Modifier
// --------------------------------------------------

extension View {
    /// Applies a linear gradient background to the view.
    func gradientBackground(colors: [Color]) -> some View {
        self.background(
            LinearGradient(
                gradient: Gradient(colors: colors),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

// --------------------------------------------------
// MARK: - String Extensions for Parsing
// --------------------------------------------------

extension String {
    /// Replace multiple consecutive blank lines with a single blank line.
    func replacingMultipleBlankLines() -> String {
        return self.replacingOccurrences(of: "(\n\\s*){2,}", with: "\n\n", options: .regularExpression)
    }
    
    /// Replace invalid bullet points (e.g. “•”) with “- ”.
    func replacingInvalidBullets() -> String {
        return self.replacingOccurrences(of: "•", with: "- ")
    }
    
    /// Ensure that list items (lines beginning with “- ”) are on their own line.
    func ensuringListItemsOnSeparateLines() -> String {
        return self.replacingOccurrences(of: "(?<!\\n)- ", with: "\n- ", options: .regularExpression)
    }
    
    /// Format common section headers by ensuring they start with “## ”.
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
    
    /// Extracts the first non-empty line (after trimming) as the job title.
    func extractJobTitle() -> String? {
        for line in self.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                return trimmed.replacingOccurrences(of: "## ", with: "")
            }
        }
        return nil
    }
    
    /// Extracts a URL from the first few lines if found.
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
    
    /// Extracts a salary candidate from the text.
    func extractSalary() -> String? {
        let pattern = "(\\$\\s?[\\d,]{5,7})|([\\d,]{5,7})"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsString = self as NSString
            let matches = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
            for match in matches {
                let candidate = nsString.substring(with: match.range)
                let cleaned = candidate.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
                if let val = Int(cleaned), val % 1000 == 0 {
                    return candidate
                }
            }
        }
        return nil
    }
    
    /// Extracts a location from the text given a list of city names.
    func extractLocation(from cityNames: [String]) -> String? {
        for city in cityNames {
            if self.range(of: city, options: .caseInsensitive) != nil {
                return city
            }
        }
        return nil
    }
}

// Predefined list of city names (without state/country abbreviations)
let predefinedCityNames = [
    "New York City", "Los Angeles", "San Francisco", "Seattle", "Boston", "Austin",
    "Atlanta", "Washington DC", "Hong Kong", "London", "Shanghai", "Singapore",
    "Greenwich", "Remote", "Newport Beach", "Shenzhen", "Century City",
    "Las Vegas", "Westport", "Miami", "Menlo Park", "Dallas", "Global"
]

// --------------------------------------------------
// MARK: - JobViewModel
// --------------------------------------------------

class JobViewModel: ObservableObject {
    // Basic Job Information
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
    
    // Desired qualities (used interchangeably with desired skills)
    @Published var desiredSkillText: String = ""
    @Published var selectedDesiredSkills: [String] = []
    
    // Application Updates (each with a status and date)
    @Published var updates: [ApplicationUpdate] = []
    
    var isInputValid: Bool {
        !companyName.isEmpty && !jobTitle.isEmpty
    }
    
    /// Adds a new job application to the job store.
    func addJob(to store: JobStore, documents: [JobDocument]) {
        // In a complete app, you would combine these properties into a JobApplication model.
        // For demonstration, assume that the salaryString can be converted to a Double.
        if let salary = Double(salaryString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) {
            salaryDouble = salary
        }
        let newJob = JobApplication(
            id: UUID(),
            companyName: companyName,
            jobTitle: jobTitle,
            status: status,
            dateOfApplication: dateOfApplication,
            location: location,
            linkToJobString: linkToJob,
            salary: salaryDouble,
            jobDescription: jobDescription,
            coverLetter: coverLetter,
            notes: notes,
            isFavorite: false,
            documents: documents,
            jobType: jobType,
            desiredSkillNames: selectedDesiredSkills
        )
        store.jobApplications.append(newJob)
    }
    
    /// Updates an existing job application.
    func updateJob(with original: JobApplication, in store: JobStore, documents: [JobDocument]) {
        if let index = store.jobApplications.firstIndex(where: { $0.id == original.id }) {
            if let salary = Double(salaryString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) {
                salaryDouble = salary
            }
            let updatedJob = JobApplication(
                id: original.id,
                companyName: companyName,
                jobTitle: jobTitle,
                status: status,
                dateOfApplication: dateOfApplication,
                location: location,
                linkToJobString: linkToJob,
                salary: salaryDouble,
                jobDescription: jobDescription,
                coverLetter: coverLetter,
                notes: notes,
                isFavorite: original.isFavorite,
                documents: documents,
                jobType: jobType,
                desiredSkillNames: selectedDesiredSkills
            )
            store.jobApplications[index] = updatedJob
        }
    }
    
    /// Updates the salary from the salaryString.
    func updateSalary(fromString str: String) {
        let cleaned = str.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
        if let val = Double(cleaned) {
            salaryDouble = val
        }
    }
}

// --------------------------------------------------
// MARK: - AddJobView
// --------------------------------------------------

struct AddJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @StateObject private var viewModel = JobViewModel()
    @Binding var isPresented: Bool
    
    // Markdown parser instance
    let markdownParser = MarkdownParser()
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information
                Section(header: Text("Basic Information").bold()) {
                    TextField("Company Name", text: $viewModel.companyName)
                        .gradientBackground(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)])
                    TextField("Job Title", text: $viewModel.jobTitle)
                        .gradientBackground(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)])
                    HStack {
                        DatePicker("Application Date", selection: $viewModel.dateOfApplication, displayedComponents: .date)
                        Button("Add Update") {
                            viewModel.updates.append(ApplicationUpdate(status: viewModel.status, date: Date()))
                        }
                    }
                    DatePicker("Application Deadline", selection: $viewModel.applicationDeadline, displayedComponents: .date)
                    // The location field; will be auto‑populated from the job description if a city is found.
                    TextField("Location", text: $viewModel.location)
                        .gradientBackground(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)])
                    TextField("Job Posting URL", text: $viewModel.linkToJob)
                        .gradientBackground(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)])
                }
                // Job Description
                Section(header: Text("Job Description").bold()) {
                    HStack {
                        TextEditor(text: $viewModel.jobDescription)
                            .gradientBackground(colors: [Color.green.opacity(0.3), Color.yellow.opacity(0.3)])
                            .frame(height: 150)
                        Button(action: { pasteJobDescription() }) {
                            Image(systemName: "doc.on.clipboard")
                        }
                        .help("Paste from clipboard")
                    }
                    Button("Parse Description") {
                        parseJobDescription()
                    }
                }
                // Salary & Job Type
                Section(header: Text("Salary & Job Type").bold()) {
                    TextField("Salary", text: $viewModel.salaryString, onCommit: {
                        viewModel.updateSalary(fromString: viewModel.salaryString)
                    })
                    .gradientBackground(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)])
                    Picker("Job Type", selection: $viewModel.jobType) {
                        ForEach(JobType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                // Desired Qualities
                Section(header: Text("Desired Qualities").bold()) {
                    VStack(alignment: .leading) {
                        TextField("Enter qualities separated by commas", text: $viewModel.desiredSkillText, onCommit: {
                            parseDesiredQualities()
                        })
                        .gradientBackground(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)])
                        if !viewModel.selectedDesiredSkills.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(viewModel.selectedDesiredSkills, id: \.self) { quality in
                                        Button(action: {
                                            // Set the selected filter in the job store (for sidebar filtering)
                                            jobStore.selectedQualityFilter = quality
                                        }) {
                                            Text(quality)
                                                .padding(5)
                                                .background(RoundedRectangle(cornerRadius: 5).stroke(Color.gray))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                // Application Updates (if any)
                if !viewModel.updates.isEmpty {
                    Section(header: Text("Application Updates").bold()) {
                        ForEach($viewModel.updates) { $update in
                            HStack {
                                Picker("Status", selection: $update.status) {
                                    ForEach(JobStatus.allCases) { status in
                                        Text(status.rawValue).tag(status)
                                    }
                                }
                                DatePicker("Date", selection: $update.date, displayedComponents: .date)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add New Application")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addJob(to: jobStore, documents: docStore.documents)
                        isPresented = false
                    }
                    .disabled(!viewModel.isInputValid)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
        .frame(minWidth: 700, minHeight: 800)
    }
    
    // MARK: Parsing and Paste Functions for AddJobView
    
    private func pasteJobDescription() {
        if let pasteString = NSPasteboard.general.string(forType: .string) {
            viewModel.jobDescription = pasteString
        }
    }
    
    private func parseDesiredQualities() {
        let qualities = viewModel.desiredSkillText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        for quality in qualities {
            if !viewModel.selectedDesiredSkills.contains(quality) {
                viewModel.selectedDesiredSkills.append(quality)
            }
            // Check prior job descriptions for this quality.
            for job in jobStore.jobApplications {
                if job.jobDescription.range(of: quality, options: .caseInsensitive) != nil,
                   !viewModel.selectedDesiredSkills.contains(quality) {
                    viewModel.selectedDesiredSkills.append(quality)
                }
            }
        }
        viewModel.desiredSkillText = ""
    }
    
    private func parseJobDescription() {
        var text = viewModel.jobDescription
        text = text.replacingMultipleBlankLines()
        text = text.replacingInvalidBullets()
        text = text.ensuringListItemsOnSeparateLines()
        text = text.formattingSectionHeaders()
        // If job title is empty, extract the first non-empty line.
        if viewModel.jobTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let extractedTitle = text.extractJobTitle() {
            viewModel.jobTitle = extractedTitle
        }
        // Extract URL if found.
        if let extractedURL = text.extractURL() {
            viewModel.linkToJob = extractedURL
        }
        // Extract salary.
        if let extractedSalary = text.extractSalary() {
            viewModel.salaryString = extractedSalary
        }
        // Extract location from job description.
        if let extractedLocation = text.extractLocation(from: predefinedCityNames) {
            viewModel.location = extractedLocation
        }
        viewModel.jobDescription = text
    }
}

// --------------------------------------------------
// MARK: - EditJobView
// --------------------------------------------------

struct EditJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @StateObject private var viewModel: JobViewModel
    @Binding var isPresented: Bool
    var job: JobApplication
    
    let markdownParser = MarkdownParser()
    
    init(isPresented: Binding<Bool>, job: JobApplication) {
        self._isPresented = isPresented
        self.job = job
        _viewModel = StateObject(wrappedValue: JobViewModel(job: job, availableSkills: []))
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information
                Section(header: Text("Basic Information").bold()) {
                    TextField("Company Name", text: $viewModel.companyName)
                        .gradientBackground(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)])
                    TextField("Job Title", text: $viewModel.jobTitle)
                        .gradientBackground(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)])
                    HStack {
                        DatePicker("Application Date", selection: $viewModel.dateOfApplication, displayedComponents: .date)
                        Button("Add Update") {
                            viewModel.updates.append(ApplicationUpdate(status: viewModel.status, date: Date()))
                        }
                    }
                    DatePicker("Application Deadline", selection: $viewModel.applicationDeadline, displayedComponents: .date)
                    TextField("Location", text: $viewModel.location)
                        .gradientBackground(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)])
                }
                // Job Description
                Section(header: Text("Job Description").bold()) {
                    HStack {
                        TextEditor(text: $viewModel.jobDescription)
                            .gradientBackground(colors: [Color.green.opacity(0.3), Color.yellow.opacity(0.3)])
                            .frame(height: 150)
                        Button(action: { pasteJobDescription() }) {
                            Image(systemName: "doc.on.clipboard")
                        }
                        .help("Paste from clipboard")
                    }
                    Button("Parse Description") {
                        parseJobDescription()
                    }
                }
                // Salary & Job Type
                Section(header: Text("Salary & Job Type").bold()) {
                    TextField("Salary", text: $viewModel.salaryString, onCommit: {
                        viewModel.updateSalary(fromString: viewModel.salaryString)
                    })
                    .gradientBackground(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)])
                    Picker("Job Type", selection: $viewModel.jobType) {
                        ForEach(JobType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                // Desired Qualities
                Section(header: Text("Desired Qualities").bold()) {
                    VStack(alignment: .leading) {
                        TextField("Enter qualities separated by commas", text: $viewModel.desiredSkillText, onCommit: {
                            parseDesiredQualities()
                        })
                        .gradientBackground(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)])
                        if !viewModel.selectedDesiredSkills.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(viewModel.selectedDesiredSkills, id: \.self) { quality in
                                        Button(action: {
                                            jobStore.selectedQualityFilter = quality
                                        }) {
                                            Text(quality)
                                                .padding(5)
                                                .background(RoundedRectangle(cornerRadius: 5).stroke(Color.gray))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                // Application Updates
                if !viewModel.updates.isEmpty {
                    Section(header: Text("Application Updates").bold()) {
                        ForEach($viewModel.updates) { $update in
                            HStack {
                                Picker("Status", selection: $update.status) {
                                    ForEach(JobStatus.allCases) { status in
                                        Text(status.rawValue).tag(status)
                                    }
                                }
                                DatePicker("Date", selection: $update.date, displayedComponents: .date)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Application")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update") {
                        viewModel.updateJob(with: job, in: jobStore, documents: docStore.documents)
                        isPresented = false
                    }
                    .disabled(!viewModel.isInputValid)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
        .frame(minWidth: 700, minHeight: 800)
    }
    
    // MARK: Parsing and Paste Functions for EditJobView
    
    private func pasteJobDescription() {
        if let pasteString = NSPasteboard.general.string(forType: .string) {
            viewModel.jobDescription = pasteString
        }
    }
    
    private func parseDesiredQualities() {
        let qualities = viewModel.desiredSkillText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        for quality in qualities {
            if !viewModel.selectedDesiredSkills.contains(quality) {
                viewModel.selectedDesiredSkills.append(quality)
            }
            for job in jobStore.jobApplications {
                if job.jobDescription.range(of: quality, options: .caseInsensitive) != nil,
                   !viewModel.selectedDesiredSkills.contains(quality) {
                    viewModel.selectedDesiredSkills.append(quality)
                }
            }
        }
        viewModel.desiredSkillText = ""
    }
    
    private func parseJobDescription() {
        var text = viewModel.jobDescription
        text = text.replacingMultipleBlankLines()
        text = text.replacingInvalidBullets()
        text = text.ensuringListItemsOnSeparateLines()
        text = text.formattingSectionHeaders()
        if viewModel.jobTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let extractedTitle = text.extractJobTitle() {
            viewModel.jobTitle = extractedTitle
        }
        if let extractedURL = text.extractURL() {
            viewModel.linkToJob = extractedURL
        }
        if let extractedSalary = text.extractSalary() {
            viewModel.salaryString = extractedSalary
        }
        if let extractedLocation = text.extractLocation(from: predefinedCityNames) {
            viewModel.location = extractedLocation
        }
        viewModel.jobDescription = text
    }
}

// --------------------------------------------------
// MARK: - NewLocationView
// --------------------------------------------------

struct NewLocationView: View {
    @Binding var newLocation: String
    var onSave: (String) -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Location")
                .font(.title)
                .bold()
            TextField("Enter location", text: $newLocation)
                .gradientBackground(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)])
                .padding()
            HStack {
                Button("Save") {
                    onSave(newLocation)
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
            }
        }
        .padding()
        .frame(width: 400, height: 200)
    }
}

// --------------------------------------------------
// MARK: - JobDetailView
// --------------------------------------------------

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
                // Application status as a bordered button.
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
                    Text("Job Type: ").bold()
                    Text(job.jobType.rawValue)
                }
                if let link = job.linkToJobString, let url = URL(string: link) {
                    Link("View Job Posting", destination: url)
                }
                if !job.location.isEmpty {
                    Text("Location: \(job.location)")
                        .font(.headline)
                }
                Text("Applied on: \(job.dateOfApplication.formatted(date: .abbreviated, time: .omitted))")
                Text("Application Deadline: \(formatDate(job.applicationDeadline))")
                if let salary = job.salary {
                    Text("Salary: \(formatSalary(salary)) per year")
                }
                // Display application updates as a horizontal list.
                if !jobStore.jobApplications.isEmpty, let updates = getUpdatesForJob(job) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(updates) { update in
                                VStack {
                                    Text(update.status.rawValue)
                                    Text(formatDate(update.date))
                                }
                                .padding(5)
                                .background(RoundedRectangle(cornerRadius: 5).fill(Color.gray.opacity(0.2)))
                            }
                        }
                    }
                }
                Divider()
                Text("Job Description")
                    .font(.headline)
                // Render markdown text with a larger font.
                Text(markdownParser.parse(job.jobDescription))
                    .font(.system(size: 18))
                    .padding()
                Divider()
                Text("Cover Letter")
                    .font(.headline)
                Text(job.coverLetter)
                    .padding()
                if let notes = job.notes, !notes.isEmpty {
                    Divider()
                    Text("Notes")
                        .font(.headline)
                    Text(notes)
                        .padding()
                }
                if !job.documents.isEmpty {
                    Divider()
                    Text("Documents")
                        .font(.headline)
                    ForEach(job.documents, id: \.id) { document in
                        HStack {
                            Image(systemName: "doc.text")
                            Text(document.fileName)
                        }
                    }
                }
                // Desired Qualities Chips
                if !job.desiredSkillNames.isEmpty {
                    Divider()
                    Text("Desired Qualities")
                        .font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(job.desiredSkillNames, id: \.self) { quality in
                                Button(action: {
                                    if selectedQualityFilter == quality {
                                        selectedQualityFilter = nil
                                        jobStore.selectedQualityFilter = nil
                                    } else {
                                        selectedQualityFilter = quality
                                        jobStore.selectedQualityFilter = quality
                                    }
                                }) {
                                    Text(quality)
                                        .padding(5)
                                        .background(selectedQualityFilter == quality ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                                        .cornerRadius(5)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // Helper to format salary.
    private func formatSalary(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? ""
    }
    
    // Helper to format dates.
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // Dummy function to retrieve updates for a job.
    private func getUpdatesForJob(_ job: JobApplication) -> [ApplicationUpdate]? {
        // In a complete app, the job model would include its updates.
        // For demonstration purposes, we return an empty array.
        return nil
    }
}
