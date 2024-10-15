
//
//  JobStore.swift
//  AppleJob
//
//  Created by Roger Lin on 10/30/24.
//


// JobStore.swift

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import AppKit

@MainActor
class JobStore: ObservableObject {
    @Published var jobApplications: [JobApplication] = []
    @Published var selectedJob: JobApplication?
    @Published var isAddingNewJob = false
    @Published var isEditingJob = false
    @Published var sorting: Sort = .recentlyApplied

    init() {
        loadJobs()
    }

    // MARK: - CRUD Operations
    func addJob(_ job: JobApplication) {
        jobApplications.append(job)
        sortJobs(by: sorting)
        saveJobs()
    }

    func editJob(with updatedJob: JobApplication) {
        if let index = jobApplications.firstIndex(where: { $0.id == updatedJob.id }) {
            jobApplications[index] = updatedJob
            sortJobs(by: sorting)
            saveJobs()
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
        let newJob = JobApplication(
            companyName: job.companyName,
            jobTitle: job.jobTitle,
            status: job.status,
            dateOfApplication: Date(),
            location: job.location,
            linkToJobString: job.linkToJobString,
            jobDescription: job.jobDescription,
            coverLetter: job.coverLetter,
            notes: job.notes,
            documents: job.documents,
            isFavorite: job.isFavorite
        )
        jobApplications.append(newJob)
        sortJobs(by: sorting)
        saveJobs()
    }

    // MARK: - Job Status and Favorite Management
    func updateJobStatus(_ id: UUID, to status: JobStatus) {
        if let index = jobApplications.firstIndex(where: { $0.id == id }) {
            jobApplications[index].status = status
            saveJobs()
        }
    }

    func toggleFavorite(for id: UUID) {
        if let index = jobApplications.firstIndex(where: { $0.id == id }) {
            jobApplications[index].isFavorite.toggle()
            saveJobs()
        }
    }

    func editJobNotes(with notes: String, for id: UUID) {
        if let index = jobApplications.firstIndex(where: { $0.id == id }) {
            jobApplications[index].notes = notes.isEmpty ? nil : notes
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

    // MARK: - Import/Export Functions
    func importBackup(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let importedJobs = try JSONDecoder().decode([JobApplication].self, from: data)
            
            // Validate imported jobs
            guard !importedJobs.isEmpty else {
                print("Failed to import backup: The JSON file is empty or does not contain valid job applications.")
                return
            }
            
            DispatchQueue.main.async {
                self.jobApplications = importedJobs
                self.sortJobs(by: self.sorting)
                self.saveJobs()
            }
            print("Backup successfully imported.")
        } catch let DecodingError.dataCorrupted(context) {
            print("Data corrupted: \(context.debugDescription)")
        } catch let DecodingError.keyNotFound(key, context) {
            print("Key '\(key)' not found: \(context.debugDescription)")
        } catch let DecodingError.typeMismatch(type, context) {
            print("Type '\(type)' mismatch: \(context.debugDescription)")
        } catch {
            print("Failed to import backup: \(error.localizedDescription)")
        }
    }

        func exportBackup(url: URL) {
            do {
                let data = try JSONEncoder().encode(jobApplications)
                try data.write(to: url)
                print("Backup successfully exported.")
            } catch {
                print("Failed to export backup: \(error.localizedDescription)")
            }
        }

    // MARK: - Persistence
    func saveJobs() {
        do {
            let data = try JSONEncoder().encode(jobApplications)
            UserDefaults.standard.set(data, forKey: "jobs")
        } catch {
            print("Failed to save jobs: \(error.localizedDescription)")
        }
    }

    func loadJobs() {
        guard let savedData = UserDefaults.standard.data(forKey: "jobs") else {
            print("No saved data found")
            return
        }
        do {
            jobApplications = try JSONDecoder().decode([JobApplication].self, from: savedData)
            sortJobs(by: sorting)
        } catch {
            print("Failed to load jobs: \(error.localizedDescription)")
        }
    }
}


// Models.swift

import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - JobApplication Model
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
        isFavorite: Bool = false
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
    }
    
    // MARK: - Search Functionality
    func matchesSearchQuery(_ query: String) -> Bool {
        let lowercasedQuery = query.lowercased()
        return companyName.lowercased().contains(lowercasedQuery) ||
            jobTitle.lowercased().contains(lowercasedQuery) ||
            location.lowercased().contains(lowercasedQuery) ||
            jobDescription.lowercased().contains(lowercasedQuery) ||
            (notes?.lowercased().contains(lowercasedQuery) ?? false)
    }
    
    // MARK: - Hashable Implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: JobApplication, rhs: JobApplication) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - JobDocument Model
struct JobDocument: Codable, Identifiable, Hashable {
    let id: UUID
    let fileName: String
    let fileData: Data
    
    init(id: UUID = UUID(), fileName: String, fileData: Data) {
        self.id = id
        self.fileName = fileName
        self.fileData = fileData
    }
    
    // MARK: - Document Types
    enum DocumentType {
        static let allowedTypes: [UTType] = [
            .pdf,
            .plainText,
            .rtf,
            .docx,
            .doc,
            .image
        ]
    }
    
    // MARK: - Hashable Implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: JobDocument, rhs: JobDocument) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - JobStatus Enum
enum JobStatus: String, Codable, CaseIterable {
    case interested = "Interested"
    case applied = "Applied"
    case interview = "Interview"
    case offer = "Offer"
    case rejection = "Rejection"
    
    var displayColor: Color {
        switch self {
        case .interested:
            return .gray
        case .applied:
            return .blue
        case .interview:
            return .orange
        case .offer:
            return .green
        case .rejection:
            return .red
        }
    }
    
    var icon: String {
        switch self {
        case .interested:
            return "star"
        case .applied:
            return "paperplane"
        case .interview:
            return "person.2.fill"
        case .offer:
            return "checkmark.circle.fill"
        case .rejection:
            return "xmark.circle.fill"
        }
    }
}

// MARK: - Sort Enum
enum Sort: String, CaseIterable {
    case title = "Job Title"
    case company = "Company Name"
    case recentlyApplied = "Recently Applied"
    
    var icon: String {
        switch self {
        case .title:
            return "textformat.size"
        case .company:
            return "building.2"
        case .recentlyApplied:
            return "calendar"
        }
    }
}

// MARK: - Document Type Extensions
extension UTType {
    static var doc: UTType {
        UTType(filenameExtension: "doc")!
    }
    
    static var docx: UTType {
        UTType(filenameExtension: "docx")!
    }
}

// MARK: - Date Extension for Formatting
extension Date {
    func formattedString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}
extension JobStatus {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = JobStatus(rawValue: rawValue) ?? .interested // Default to 'interested' or another case
    }
}
// MARK: - Notification Names
extension Notification.Name {
    static let jobAdded = Notification.Name("jobAdded")
    static let jobEdited = Notification.Name("jobEdited")
    static let jobDeleted = Notification.Name("jobDeleted")
    static let jobFavorited = Notification.Name("jobFavorited")
    static let jobStatusChanged = Notification.Name("jobStatusChanged")
    static let backupImported = Notification.Name("backupImported")
    static let backupExported = Notification.Name("backupExported")
}

// MARK: - Error Types
enum JobApplicationError: Error {
    case invalidData
    case saveFailed
    case loadFailed
    case importFailed
    case exportFailed
    case documentError
    
    var localizedDescription: String {
        switch self {
        case .invalidData:
            return "The job application data is invalid"
        case .saveFailed:
            return "Failed to save job application"
        case .loadFailed:
            return "Failed to load job applications"
        case .importFailed:
            return "Failed to import backup"
        case .exportFailed:
            return "Failed to export backup"
        case .documentError:
            return "Error handling document"
        }
    }
}



//
//  JobViewModel.swift
//  AppleJob
//
//  Created by Roger Lin on 10/30/24.
//


// JobViewModel.swift

import SwiftUI
import Combine

@MainActor
class JobViewModel: ObservableObject {
    @Published var companyName: String = ""
    @Published var jobTitle: String = ""
    @Published var status: JobStatus = .interested
    @Published var dateOfApplication: Date = Date()
    @Published var location: String = ""
    @Published var linkToJob: String = ""
    @Published var jobDescription: String = ""
    @Published var coverLetter: String = ""
    @Published var notes: String = ""
    @Published var isInputValid: Bool = false

    private var cancellables: Set<AnyCancellable> = []

    init() {
        setupValidation()
    }

    init(job: JobApplication) {
        self.companyName = job.companyName
        self.jobTitle = job.jobTitle
        self.status = job.status
        self.dateOfApplication = job.dateOfApplication
        self.location = job.location
        self.linkToJob = job.linkToJobString ?? ""
        self.jobDescription = job.jobDescription
        self.coverLetter = job.coverLetter
        self.notes = job.notes ?? ""
        setupValidation()
    }

    private func setupValidation() {
        Publishers.CombineLatest($companyName, $jobTitle)
            .map { !$0.isEmpty && !$1.isEmpty }
            .assign(to: &$isInputValid)
    }

    func addJob(to jobStore: JobStore, documents: [JobDocument]) {
        guard isInputValid else { return }

        let newJob = JobApplication(
            companyName: companyName,
            jobTitle: jobTitle,
            status: status,
            dateOfApplication: dateOfApplication,
            location: location,
            linkToJobString: linkToJob.isEmpty ? nil : linkToJob,
            jobDescription: jobDescription,
            coverLetter: coverLetter,
            notes: notes.isEmpty ? nil : notes,
            documents: documents,
            isFavorite: false
        )
        jobStore.addJob(newJob)
        resetInput()
    }

    private func resetInput() {
        companyName = ""
        jobTitle = ""
        status = .interested
        dateOfApplication = Date()
        location = ""
        linkToJob = ""
        jobDescription = ""
        coverLetter = ""
        notes = ""
    }
}



// Views.swift

import SwiftUI
import Combine
import MapKit
import Charts
import UniformTypeIdentifiers
import Foundation
import ContributionChart

// Extend Color to initialize from hex code
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 1)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: 1
        )
    }
}

//
//  applejobs.swift
//  AppleJob
//
//  Created by Roger Lin on 10/30/24.
//


// applejobs_alphaApp.swift

import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct applejobs_alphaApp: App {
    @StateObject private var jobStore = JobStore()
    @StateObject private var importExportHelper = ImportExportHelper()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(jobStore)
                .environmentObject(importExportHelper)
        }
        .commands {
            fileMenuCommands
            editMenuCommands
        }
    }

    // MARK: - Menu Commands

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
        }
    }
}
// ImportExportHelper.swift

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import AppKit

@MainActor
class ImportExportHelper: NSObject, ObservableObject {
    @Published var isImporting = false
    @Published var isExporting = false

    // Import JSON backup
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

    // Export JSON backup
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
}



import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct DocumentPicker: NSViewRepresentable {
    enum DocumentType {
        case open
        case save
    }

    let documentType: DocumentType
    let allowedContentTypes: [UTType]
    let completion: (URL) -> Void

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton(title: documentType == .open ? "Open File" : "Save File", target: context.coordinator, action: #selector(context.coordinator.showPanel))
        return button
    }

    func updateNSView(_ nsView: NSButton, context: Context) {
        // No dynamic updates needed
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(documentType: documentType, allowedContentTypes: allowedContentTypes, completion: completion)
    }

    class Coordinator: NSObject {
        let documentType: DocumentType
        let allowedContentTypes: [UTType]
        let completion: (URL) -> Void

        init(documentType: DocumentType, allowedContentTypes: [UTType], completion: @escaping (URL) -> Void) {
            self.documentType = documentType
            self.allowedContentTypes = allowedContentTypes
            self.completion = completion
        }

        @objc func showPanel() {
            let panel: NSOpenPanel
            if documentType == .open {
                panel = NSOpenPanel()
                panel.allowedContentTypes = allowedContentTypes
                panel.canChooseFiles = true
                panel.canCreateDirectories = false
                panel.allowsMultipleSelection = false
            } else {
                panel = NSSavePanel() as! NSOpenPanel
                panel.allowedContentTypes = allowedContentTypes
                panel.canCreateDirectories = true
            }

            if panel.runModal() == .OK, let url = panel.url {
                completion(url)
            }
        }
    }
}

// MARK: - ViewSection Enum
enum ViewSection: String, CaseIterable {
    case jobDetails = "Job Details"
    case stats = "Stats"
    case gitTree = "Git Tree"
    
    var icon: String {
        switch self {
        case .jobDetails: return "doc.text"
        case .stats: return "chart.bar"
        case .gitTree: return "tree"
        }
    }
}

// Define Notification Names
extension Notification.Name {
    static let addNewJob = Notification.Name("addNewJob")
    static let editJob = Notification.Name("editJob")
    static let deleteJob = Notification.Name("deleteJob")
}

// MARK: ContentView.swift
import SwiftUI
import Tree

struct ContentView: View {
    @EnvironmentObject var jobStore: JobStore
    @State private var searchText = ""
    @State private var selectedSection: ViewSection = .jobDetails
    @State private var isDarkMode: Bool = false

    // State variables for import/export
    @State private var isImporting = false
    @State private var isExporting = false

    var body: some View {
        NavigationView {
            SidebarView(selectedJob: $jobStore.selectedJob, searchText: $searchText)
                .frame(minWidth: 250, maxWidth: .infinity)
                .opacity(0.75)
            if let job = jobStore.selectedJob {
                mainContent(for: job)
            } else {
                Text("Select a job to view details")
                    .foregroundColor(.secondary)
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .toolbar {
            primaryToolbarItems
        }
        .sheet(isPresented: $jobStore.isAddingNewJob) {
                    AddJobView(isPresented: $jobStore.isAddingNewJob)
                        .environmentObject(jobStore)
                }
                .sheet(isPresented: $jobStore.isEditingJob) {
                    if let job = jobStore.selectedJob {
                        EditJobView(isPresented: $jobStore.isEditingJob, job: job)
                            .environmentObject(jobStore)
                    }
                }
            }

    
    private var primaryToolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Picker("View Section", selection: $selectedSection) {
                ForEach(ViewSection.allCases, id: \.self) { section in
                    Text(section.rawValue)
                        .tag(section)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 300)
            
            Spacer()
            
            Button(action: { jobStore.isAddingNewJob = true }) {
                Label("Add Job", systemImage: "plus")
            }
            .help("Add new job application")
            
            Button(action: deleteSelectedJob) {
                Label("Delete", systemImage: "trash")
            }
            .disabled(jobStore.selectedJob == nil)
            .help("Delete selected job application")
            
            Button(action: toggleFavorite) {
                Label("Favorite", systemImage: jobStore.selectedJob?.isFavorite == true ? "heart.fill" : "heart")
            }
            .disabled(jobStore.selectedJob == nil)
            .help("Toggle favorite status")
            
            Button(action: {
                isDarkMode.toggle()
            }) {
                Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
            }
            .help("Toggle Dark Mode")
        }
    }

    @ViewBuilder
    private func mainContent(for job: JobApplication) -> some View {
        switch selectedSection {
        case .jobDetails:
            JobDetailView(job: job)
                .environmentObject(jobStore)
        case .stats:
            StatsView(job: job)
                .environmentObject(jobStore)
        case .gitTree:
            GitTreeContainerView(job: job)
                .environmentObject(jobStore)
        }
    }
    
    private func deleteSelectedJob() {
        if let job = jobStore.selectedJob {
            jobStore.deleteJob(for: job.id)
        }
    }
    
    private func toggleFavorite() {
        if let job = jobStore.selectedJob {
            jobStore.toggleFavorite(for: job.id)
        }
    }
}
// MARK: - SidebarView
struct SidebarView: View {
    @EnvironmentObject var jobStore: JobStore
    @Binding var selectedJob: JobApplication?
    @Binding var searchText: String
    
    var filteredJobs: [JobApplication] {
        if searchText.isEmpty {
            return jobStore.jobApplications
        } else {
            return jobStore.jobApplications.filter { $0.matchesSearchQuery(searchText) }
        }
    }
    
    var body: some View {
        List(selection: $selectedJob) {
            ForEach(filteredJobs, id: \.id) { job in
                SidebarItemView(job: job, isSelected: job.id == selectedJob?.id)
                    .tag(job)
            }
            .onDelete(perform: deleteJobs)
        }
        .listStyle(SidebarListStyle())
        .searchable(text: $searchText)
        .navigationTitle("Job Applications")
        .opacity(0.75) // Adjusted opacity
    }
    
    private func deleteJobs(at offsets: IndexSet) {
        for index in offsets {
            let job = filteredJobs[index]
            jobStore.deleteJob(for: job.id)
        }
    }
}
// MARK: - SidebarItemView
struct SidebarItemView: View {
    var job: JobApplication
    var isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(job.companyName)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(job.jobTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(job.status.rawValue)
                .font(.caption)
                .padding(4)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue.opacity(0.2) : statusColor(for: job.status).opacity(0.2))
                )
                .foregroundColor(isSelected ? Color.white : statusColor(for: job.status))
        }
        .padding(.vertical, 4)
        .contextMenu {
            JobContextMenu(job: job)
        }
    }
    
    private func statusColor(for status: JobStatus) -> Color {
        switch status {
        case .interested:
            return .gray
        case .applied:
            return .blue
        case .interview:
            return .orange
        case .offer:
            return .green
        case .rejection:
            return .red
        }
    }
}
// MARK: - JobContextMenu
struct JobContextMenu: View {
    let job: JobApplication
    @EnvironmentObject var jobStore: JobStore
    
    var body: some View {
        Button(action: { jobStore.isEditingJob = true }) {
            Label("Edit", systemImage: "pencil")
        }
        Button(action: { jobStore.duplicateJob(job) }) {
            Label("Duplicate", systemImage: "plus.square.on.square")
        }
        Divider()
        Menu("Change Status") {
            ForEach(JobStatus.allCases, id: \.self) { status in
                Button(action: { jobStore.updateJobStatus(job.id, to: status) }) {
                    Label(status.rawValue, systemImage: statusIcon(for: status))
                }
            }
        }
        Divider()
        Button(action: { jobStore.toggleFavorite(for: job.id) }) {
            Label(
                job.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                systemImage: job.isFavorite ? "heart.fill" : "heart"
            )
        }
        if let linkString = job.linkToJobString,
           let url = URL(string: linkString) {
            Button(action: { openURL(url) }) {
                Label("Open Job Posting", systemImage: "safari")
            }
        }
        Divider()
        Button(role: .destructive, action: { jobStore.deleteJob(for: job.id) }) {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private func statusIcon(for status: JobStatus) -> String {
        switch status {
        case .interested:
            return "star"
        case .applied:
            return "paperplane"
        case .interview:
            return "person.crop.circle.badge.checkmark"
        case .offer:
            return "hand.thumbsup"
        case .rejection:
            return "hand.thumbsdown"
        }
    }
    
    private func openURL(_ url: URL) {
#if os(macOS)
        NSWorkspace.shared.open(url)
#else
        UIApplication.shared.open(url)
#endif
    }
}

// MARK: - JobDetailView
struct JobDetailView: View {
    @EnvironmentObject var jobStore: JobStore
    @State private var notesText = ""
    var job: JobApplication
    
    private var statusColor: Color {
        switch job.status {
        case .interested:
            return Color.gray
        case .applied:
            return Color.blue
        case .interview:
            return Color.orange
        case .offer:
            return Color.green
        case .rejection:
            return Color.red
        }
    }
    
    private var dateString: String {
        DateFormatter.localizedString(from: job.dateOfApplication, dateStyle: .long, timeStyle: .none)
    }
    
    private func configureView() {
        notesText = job.notes ?? ""
    }
    
    private func editButtonTapped() {
        jobStore.isEditingJob = true
    }
    
    private func heartButtonTapped() {
        jobStore.toggleFavorite(for: job.id)
    }
    
    private func handleNotesChange(_ newValue: String) {
        jobStore.editJobNotes(with: newValue, for: job.id)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(job.companyName)
                    .font(.largeTitle)
                    .bold()
                Text(job.jobTitle)
                    .font(.title2)
                HStack {
                    Text("Status:")
                        .bold()
                    Text(job.status.rawValue)
                        .foregroundColor(statusColor)
                }
                if let link = job.linkToJobString, let url = URL(string: link) {
                    Link("View Job Posting", destination: url)
                }
                if !job.location.isEmpty {
                    Text("Location: \(job.location)")
                }
                Text("Applied on: \(dateString)")
                if !job.jobDescription.isEmpty {
                    Divider()
                    Text("Job Description")
                        .font(.headline)
                    Text(job.jobDescription)
                }
                if !job.coverLetter.isEmpty {
                    Divider()
                    Text("Cover Letter")
                        .font(.headline)
                    Text(job.coverLetter)
                }
                Divider()
                Text("Notes")
                    .font(.headline)
                TextEditor(text: $notesText)
                    .frame(minHeight: 150)
                    .padding(5)
                    .onChange(of: notesText) { oldValue, newValue in
                        handleNotesChange(newValue)
                    }
                if !job.documents.isEmpty {
                    Divider()
                    Text("Documents")
                        .font(.headline)
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(job.documents) { document in
                                Button(action: {
                                    openDocument(document)
                                }) {
                                    Text(document.fileName)
                                        .underline()
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear(perform: configureView)
        .navigationTitle("Job Details")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItemGroup {
                Button(action: editButtonTapped) {
                    Image(systemName: "square.and.pencil")
                }
                Button(action: heartButtonTapped) {
                    Image(systemName: job.isFavorite ? "heart.fill" : "heart")
                }
            }
        }
    }
    
    private func openDocument(_ document: JobDocument) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(document.fileName)
        do {
            try document.fileData.write(to: tempURL)
#if os(macOS)
            NSWorkspace.shared.open(tempURL)
#else
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                rootVC.present(activityVC, animated: true, completion: nil)
            }
#endif
        } catch {
            print("Failed to open document: \(error.localizedDescription)")
        }
    }
}
// MARK: - AddJobView
struct AddJobView: View {
    @Environment(\.colorScheme) var colorScheme // Monitor color scheme
    @EnvironmentObject var jobStore: JobStore
    @Binding var isPresented: Bool
    @StateObject private var viewModel = JobViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var isImporting: Bool = false
    @State private var importedDocuments: [JobDocument] = []
    @State private var locations: [String] = ["New York City, NY", "Los Angeles, CA", "Chicago, IL"]
    @State private var showAddLocationSheet = false
    
        var body: some View {
            ZStack {
                (colorScheme == .dark ? Color.gray : Color(hex: "#ecebef"))
                    .edgesIgnoringSafeArea(.all)
            Group {
                VStack {
                    Text("ADD NEW JOB")
                        .font(.title2)
                        .textCase(.uppercase)
                        .foregroundColor(colorScheme == .dark ? .white : .gray) // Update text color
                        .padding()
                    ScrollView {
                        content
                    }
                    .padding()
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Label("Cancel", systemImage: "multiply.circle.fill")
                        }
                        Spacer()
                        Button(action: {
                            addJob()
                            dismiss()
                        }) {
                            Label("Add", systemImage: "plus.circle.fill")
                        }
                        .disabled(!viewModel.isInputValid)
                    }
                    .padding()
                }
                .frame(minWidth: 400, minHeight: 600)
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: JobDocument.DocumentType.allowedTypes,
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result: result)
        }
        .sheet(isPresented: $showAddLocationSheet) {
            NewLocationView(locations: $locations, selectedLocation: $viewModel.location)
        }
    }
    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Job Details Section
            Text("JOB DETAILS")
                .foregroundColor(colorScheme == .dark ? .white : .gray) // Update text color
                .font(.headline)
                .textCase(.uppercase)
                .padding(.horizontal)
            VStack(spacing: 8) {
                TextField("Company Name", text: $viewModel.companyName)
                    .padding(.horizontal)
                    .foregroundColor(colorScheme == .dark ? .white : .gray) // Update text color
                TextField("Job Title", text: $viewModel.jobTitle)
                    .foregroundColor(colorScheme == .dark ? .white : .gray) // Update text color
                    .padding(.horizontal)
                    .cornerRadius(5)

            }
            // Application Details Section
            Text("APPLICATION DETAILS")
                .font(.headline)
                .textCase(.uppercase)
                .padding(.horizontal)
                .foregroundColor(colorScheme == .dark ? .white : .gray) // Update text color
            VStack(spacing: 8) {
                TextField("Link to Job", text: $viewModel.linkToJob)
                    .padding(.horizontal)
                    .foregroundColor(colorScheme == .dark ? .white : .gray) // Update text color
                    .cornerRadius(5)
                Picker("Application Status", selection: $viewModel.status) {
                    ForEach(JobStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .padding(.horizontal)
                // Location Picker
                Picker("Location", selection: $viewModel.location) {
                    ForEach(locations, id: \.self) { location in
                        Text(location).tag(location)
                    }
                    Text("Add New Location").tag("Add New Location")
                }
                .padding(.horizontal)
                .onChange(of: viewModel.location) { oldValue, newValue in
                    if newValue == "Add New Location" {
                        viewModel.location = "" // Clear the placeholder
                        showAddLocationSheet = true
                    }
                }
                DatePicker("Application Date", selection: $viewModel.dateOfApplication, displayedComponents: .date)
                    .padding(.horizontal)
                    .cornerRadius(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            // Documents Section
            Text("DOCUMENTS")
                .font(.headline)
                .textCase(.uppercase)
                .padding(.horizontal)
            VStack(spacing: 8) {
                if !importedDocuments.isEmpty {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(importedDocuments) { document in
                                Text(document.fileName)
                                    .padding(5)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(5)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                Button("Upload Documents") {
                    isImporting = true
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding(.horizontal)
                .cornerRadius(5)

            }
            // Job Description Section
            Text("JOB DESCRIPTION")
                .font(.headline)
                .textCase(.uppercase)
                .padding(.horizontal)
                .foregroundColor(colorScheme == .dark ? .white : .gray) // Update text color
            ResizableTextEditor(text: $viewModel.jobDescription)
                .frame(minHeight: 150)
                .padding(.horizontal)
                .background(Color("textBackgroundColor"))
                .cornerRadius(5)
            // Cover Letter Section
            Text("COVER LETTER")
                .font(.headline)
                .textCase(.uppercase)
                .padding(.horizontal)
            ResizableTextEditor(text: $viewModel.coverLetter)
                .frame(minHeight: 150)
                .padding(.horizontal)
                .background(Color("textBackgroundColor"))
                .cornerRadius(5)
                .foregroundColor(colorScheme == .dark ? .white : .gray) // Update text color
                // Notes Section
            Text("NOTES")
                .font(.headline)
                .textCase(.uppercase)
                .padding(.horizontal)
            ResizableTextEditor(text: $viewModel.notes)
                .frame(minHeight: 150)
                .padding(.horizontal)
                .foregroundColor(colorScheme == .dark ? .white : .gray) // Update text color
                .background(Color("textBackgroundColor"))
                .cornerRadius(5)
                            }
                    .padding(.vertical)
                            }
                            
                            @MainActor
                            private func addJob() {
                    viewModel.addJob(to: jobStore, documents: importedDocuments)
                }
                            
                            private func handleFileImport(result: Result<[URL], Error>) {
                    do {
                        let urls = try result.get()
                        for url in urls {
                            let data = try Data(contentsOf: url)
                            let document = JobDocument(fileName: url.lastPathComponent, fileData: data)
                            importedDocuments.append(document)
                        }
                    } catch {
                        print("Failed to import files: \(error.localizedDescription)")
                    }
                }
                            }
                            
                            // MARK: - ResizableTextEditor
                            struct ResizableTextEditor: View {
                    @Binding var text: String
                    @State private var dynamicHeight: CGFloat = .zero
                    
                    var body: some View {
                        TextEditor(text: $text)
                            .frame(minHeight: dynamicHeight)
                            .background(
                                GeometryReader { geometry in
                                    Color.clear.onAppear {
                                        dynamicHeight = max(geometry.size.height, 150)
                                    }
                                }
                            )
                    }
                }
                            
                            // MARK: - NewLocationView
                            struct NewLocationView: View {
                    @Environment(\.presentationMode) var presentationMode
                    @Binding var locations: [String]
                    @Binding var selectedLocation: String
                    @State private var newLocation: String = ""
                    
                    var body: some View {
                        VStack(spacing: 20) {
                            Text("Enter Location")
                                .font(.headline)
                            Text("Add a new location to the list.")
                            TextField("Location", text: $newLocation)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
#if os(iOS)
                                .keyboardType(.default)
#endif
                                .padding()
                            HStack {
                                Button("Cancel") {
                                    newLocation = ""
                                    presentationMode.wrappedValue.dismiss()
                                }
                                Spacer()
                                Button("Add") {
                                    if !newLocation.isEmpty {
                                        if !locations.contains(newLocation) { // Prevent duplicates
                                            locations.append(newLocation)
                                        }
                                        selectedLocation = newLocation
                                        newLocation = ""
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }
                                .disabled(newLocation.isEmpty)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .frame(maxWidth: 400)
#if os(macOS)
                        .background(Color(NSColor.windowBackgroundColor))
#else
                        .background(Color(UIColor.systemBackground))
#endif
                        .cornerRadius(12)
                        .shadow(radius: 10)
                        .padding()
                    }
                }
                            
                            // MARK: - EditJobView
                            struct EditJobView: View {
                    @EnvironmentObject var jobStore: JobStore
                    @Binding var isPresented: Bool
                    @StateObject private var viewModel: JobViewModel
                    @Environment(\.dismiss) var dismiss
                    @State private var isImporting: Bool = false
                    @State private var importedDocuments: [JobDocument] = []
                    @State private var locations: [String] = ["New York City, NY", "Los Angeles, CA", "Chicago, IL"]
                    @State private var showAddLocationSheet = false
                    
                    init(isPresented: Binding<Bool>, job: JobApplication) {
                        self._isPresented = isPresented
                        _viewModel = StateObject(wrappedValue: JobViewModel(job: job))
                        _importedDocuments = State(initialValue: job.documents)
                    }
                    
                    var body: some View {
                        Group {
                            if isMacOS {
                                VStack {
                                    Text("EDIT JOB")
                                        .font(.title2)
                                        .textCase(.uppercase)
                                        .padding()
                                    ScrollView {
                                        content
                                    }
                                    .padding()
                                    HStack {
                                        Button(action: {
                                            isPresented = false
                                        }) {
                                            Label("Cancel", systemImage: "multiply.circle.fill")
                                        }
                                        Spacer()
                                        Button(action: {
                                            saveChanges()
                                            isPresented = false
                                        }) {
                                            Label("Save", systemImage: "checkmark.circle.fill")
                                        }
                                        .disabled(!viewModel.isInputValid)
                                    }
                                    .padding()
                                }
                                .frame(minWidth: 400, minHeight: 600)
                            } else {
                                NavigationView {
                                    ScrollView {
                                        content
                                    }
                                    .navigationTitle("EDIT JOB")
#if os(iOS)
                                    .navigationBarTitleDisplayMode(.inline)
#endif
                                    .toolbar {
                                        ToolbarItem(placement: .cancellationAction) {
                                            Button(action: {
                                                isPresented = false
                                            }) {
                                                Label("Cancel", systemImage: "multiply.circle.fill")
                                            }
                                        }
                                        ToolbarItem(placement: .confirmationAction) {
                                            Button(action: {
                                                saveChanges()
                                                isPresented = false
                                            }) {
                                                Label("Save", systemImage: "checkmark.circle.fill")
                                            }
                                            .disabled(!viewModel.isInputValid)
                                        }
                                    }
                                }
                            }
                        }
                        .fileImporter(
                            isPresented: $isImporting,
                            allowedContentTypes: JobDocument.DocumentType.allowedTypes,
                            allowsMultipleSelection: true
                        ) { result in
                            handleFileImport(result: result)
                        }
                        .sheet(isPresented: $showAddLocationSheet) {
                            NewLocationView(locations: $locations, selectedLocation: $viewModel.location)
                        }
                    }
                    
                    private var content: some View {
                        VStack(alignment: .leading, spacing: 16) {
                            // Job Details Section
                            Text("JOB DETAILS")
                                .font(.headline)
                                .textCase(.uppercase)
                                .padding(.horizontal)
                            VStack(spacing: 8) {
                                TextField("Company Name", text: $viewModel.companyName)
                                    .padding(.horizontal)
                                TextField("Job Title", text: $viewModel.jobTitle)
                                    .background(Color.white)
                                    .padding(.horizontal)
                            }
                            // Application Details Section
                            Text("APPLICATION DETAILS")
                                .font(.headline)
                                .textCase(.uppercase)
                                .padding(.horizontal)
                            VStack(spacing: 8) {
                                TextField("Link to Job", text: $viewModel.linkToJob)
                                    .padding(.horizontal)
                                    .background(Color.white)
                                Picker("Application Status", selection: $viewModel.status) {
                                    ForEach(JobStatus.allCases, id: \.self) { status in
                                        Text(status.rawValue).tag(status)
                                    }
                                }
                                .padding(.horizontal)
                                // Location Picker
                                Picker("Location", selection: $viewModel.location) {
                                    ForEach(locations, id: \.self) { location in
                                        Text(location).tag(location)
                                    }
                                    Text("Add New Location").tag("Add New Location")
                                }
                                .padding(.horizontal)
                                .onChange(of: viewModel.location) { oldValue, newValue in
                                    if newValue == "Add New Location" {
                                        viewModel.location = "" // Clear the placeholder
                                        showAddLocationSheet = true
                                    }
                                }
                                DatePicker("Application Date", selection: $viewModel.dateOfApplication, displayedComponents: .date)
                                    .padding(.horizontal)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            // Documents Section
                            Text("DOCUMENTS")
                                .font(.headline)
                                .textCase(.uppercase)
                                .padding(.horizontal)
                            VStack(spacing: 8) {
                                if !importedDocuments.isEmpty {
                                    ScrollView(.horizontal) {
                                        HStack {
                                            ForEach(importedDocuments) { document in
                                                Text(document.fileName)
                                                    .padding(5)
                                                    .background(Color.blue.opacity(0.1))
                                                    .cornerRadius(5)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                Button("Upload Documents") {
                                    isImporting = true
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                .padding(.horizontal)
                            }
                            // Job Description Section
                            Text("JOB DESCRIPTION")
                                .font(.headline)
                                .textCase(.uppercase)
                                .padding(.horizontal)
                            ResizableTextEditor(text: $viewModel.jobDescription)
                                .frame(minHeight: 150)
                                .padding(.horizontal)
                                .background(Color("textBackgroundColor"))
                                .cornerRadius(5)
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 1))
                            // Cover Letter Section
                            Text("COVER LETTER")
                                .font(.headline)
                                .textCase(.uppercase)
                                .padding(.horizontal)
                            ResizableTextEditor(text: $viewModel.coverLetter)
                                .frame(minHeight: 150)
                                .padding(.horizontal)
                                .background(Color("textBackgroundColor"))
                                .cornerRadius(5)
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 1))
                            // Notes Section
                            Text("NOTES")
                                .font(.headline)
                                .textCase(.uppercase)
                                .padding(.horizontal)
                            ResizableTextEditor(text: $viewModel.notes)
                                .frame(minHeight: 150)
                                .padding(.horizontal)
                                .background(Color("textBackgroundColor"))
                                .cornerRadius(5)
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 1))
                        }
                        .padding(.vertical)
                    }
                    
                    @MainActor
                    private func saveChanges() {
                        guard let selectedJob = jobStore.selectedJob else { return }
                        var updatedJob = selectedJob
                        updatedJob.companyName = viewModel.companyName
                        updatedJob.jobTitle = viewModel.jobTitle
                        updatedJob.status = viewModel.status
                        updatedJob.dateOfApplication = viewModel.dateOfApplication
                        updatedJob.location = viewModel.location
                        updatedJob.linkToJobString = viewModel.linkToJob.isEmpty ? nil : viewModel.linkToJob
                        updatedJob.jobDescription = viewModel.jobDescription
                        updatedJob.coverLetter = viewModel.coverLetter
                        updatedJob.notes = viewModel.notes.isEmpty ? nil : viewModel.notes
                        updatedJob.documents = importedDocuments
                        jobStore.editJob(with: updatedJob)
                    }
                    
                    private func handleFileImport(result: Result<[URL], Error>) {
                        do {
                            let urls = try result.get()
                            for url in urls {
                                let data = try Data(contentsOf: url)
                                let document = JobDocument(fileName: url.lastPathComponent, fileData: data)
                                importedDocuments.append(document)
                            }
                        } catch {
                            print("Failed to import files: \(error.localizedDescription)")
                        }
                    }
                    
                    // Helper to determine platform
                    private var isMacOS: Bool {
#if os(macOS)
                        return true
#else
                        return false
#endif
                    }
                }
                            //
                            //  GitTreeStore.swift
                            //  applejobs-alpha
                            //
                            //  Created by Roger Lin on 10/28/24.
                            //
                            
                            
                            // MARK: - GitTreeStore Class
                            @MainActor
                            class GitTreeStore: ObservableObject {
                    @Published var rootNode: Node<GitTreeElement>
                    @Published var selectedNode: Node<GitTreeElement>?
                    @Published var isShowingNewBranchSheet = false
                    @Published var selectedNodeForNewBranch: Node<GitTreeElement>?
                    @Published var isShowingCommitSheet = false
                    @Published var selectedBranchNodeForCommit: Node<GitTreeElement>?
                    @Published var commitMessage: String = ""
                    @Published var commitDocument: JobDocument?
                    
                    init() {
                        if let savedRootNode = GitTreeStore.loadTree() {
                            self.rootNode = savedRootNode
                        } else {
                            let mainBranchElement = GitTreeElement(
                                id: UUID(),
                                type: .branch,
                                name: "main",
                                message: nil,
                                timestamp: nil,
                                document: nil
                            )
                            self.rootNode = Node(mainBranchElement)
                            GitTreeStore.saveTree(rootNode)
                        }
                    }
                    
                    // MARK: - Branch Management
                    func createBranch(name: String, fromNode: Node<GitTreeElement>) {
                        let newBranchElement = GitTreeElement(
                            id: UUID(),
                            type: .branch,
                            name: name,
                            message: nil,
                            timestamp: nil,
                            document: nil
                        )
                        let newBranchNode = Node(newBranchElement)
                        fromNode.append(child: newBranchNode)
                        GitTreeStore.saveTree(rootNode)
                    }
                    
                    func deleteBranch(_ branchNode: Node<GitTreeElement>) {
                        guard branchNode.element.type == .branch else { return }
                        guard branchNode.element.name != "main" else { return }
                        branchNode.prune()
                        GitTreeStore.saveTree(rootNode)
                    }
                    
                    // MARK: - Commit Management
                    func addCommit(_ document: JobDocument, message: String, toBranchNode branchNode: Node<GitTreeElement>) {
                        let commitElement = GitTreeElement(
                            id: UUID(),
                            type: .commit,
                            name: nil,
                            message: message,
                            timestamp: Date(),
                            document: document
                        )
                        let commitNode = Node(commitElement)
                        branchNode.append(child: commitNode)
                        GitTreeStore.saveTree(rootNode)
                    }
                    
                    func removeCommit(_ commitNode: Node<GitTreeElement>) {
                        guard commitNode.element.type == .commit else { return }
                        commitNode.prune()
                        GitTreeStore.saveTree(rootNode)
                    }
                    
                    // MARK: - Persistence
                    private static func saveTree(_ rootNode: Node<GitTreeElement>) {
                        do {
                            let data = try encodeTree(rootNode)
                            UserDefaults.standard.set(data, forKey: "gitTree")
                        } catch {
                            print("Failed to save git tree: \(error.localizedDescription)")
                        }
                    }
                    
                    private static func loadTree() -> Node<GitTreeElement>? {
                        guard let savedData = UserDefaults.standard.data(forKey: "gitTree") else {
                            print("No saved git tree found")
                            return nil
                        }
                        do {
                            let rootNode = try decodeTree(data: savedData)
                            return rootNode
                        } catch {
                            print("Failed to load git tree: \(error.localizedDescription)")
                            return nil
                        }
                    }
                    
                    // Helper structs and methods
                    private static func encodeTree(_ node: Node<GitTreeElement>) throws -> Data {
                        let encoder = JSONEncoder()
                        let elementData = try encoder.encode(node.element)
                        var childrenData: [Data] = []
                        for child in node.children {
                            let childData = try encodeTree(child)
                            childrenData.append(childData)
                        }
                        let nodeData = NodeData(elementData: elementData, childrenData: childrenData)
                        return try encoder.encode(nodeData)
                    }
                    
                    private static func decodeTree(data: Data) throws -> Node<GitTreeElement> {
                        let decoder = JSONDecoder()
                        let nodeData = try decoder.decode(NodeData.self, from: data)
                        let element = try decoder.decode(GitTreeElement.self, from: nodeData.elementData)
                        let node = Node(element)
                        for childData in nodeData.childrenData {
                            let childNode = try decodeTree(data: childData)
                            node.append(child: childNode)
                        }
                        return node
                    }
                    
                    private struct NodeData: Codable {
                        let elementData: Data
                        let childrenData: [Data]
                    }
                }
                            
                            
                            
                            // MARK: - GitTreeElement
                            struct GitTreeElement: Identifiable, Codable {
                    let id: UUID
                    let type: ElementType
                    let name: String?
                    let message: String?
                    let timestamp: Date?
                    let document: JobDocument?
                    
                    enum ElementType: String, Codable {
                        case branch
                        case commit
                    }
                }
                            
                            // MARK: - GitTreeContainerView
                            struct GitTreeContainerView: View {
                    var job: JobApplication
                    @StateObject private var gitTreeStore = GitTreeStore()
                    
                    var body: some View {
                        GitTreeView()
                            .environmentObject(gitTreeStore)
                            .navigationTitle("Document History")
                    }
                }
                            
                            // MARK: - GitTreeView
                            struct GitTreeView: View {
                    @EnvironmentObject var gitTreeStore: GitTreeStore
                    
                    var body: some View {
                        ScrollView([.horizontal, .vertical]) {
                            VStack(alignment: .leading, spacing: 20) {
                                TreeNodeView(node: gitTreeStore.rootNode)
                            }
                            .padding()
                        }
                        .sheet(isPresented: $gitTreeStore.isShowingNewBranchSheet) {
                            NewBranchSheet(
                                branchName: .constant(""),
                                sourceNode: gitTreeStore.selectedNodeForNewBranch,
                                gitTreeStore: gitTreeStore,
                                isPresented: $gitTreeStore.isShowingNewBranchSheet
                            )
                        }
                        .sheet(isPresented: $gitTreeStore.isShowingCommitSheet) {
                            NewCommitSheet(
                                commitMessage: $gitTreeStore.commitMessage,
                                document: $gitTreeStore.commitDocument,
                                branchNode: gitTreeStore.selectedBranchNodeForCommit,
                                gitTreeStore: gitTreeStore,
                                isPresented: $gitTreeStore.isShowingCommitSheet
                            )
                        }
                        .toolbar {
                            ToolbarItem {
                                Button(action: {
                                    gitTreeStore.selectedNodeForNewBranch = gitTreeStore.rootNode
                                    gitTreeStore.isShowingNewBranchSheet = true
                                }) {
                                    Label("New Branch", systemImage: "plus")
                                }
                            }
                        }
                    }
                }
                            
                            // MARK: - TreeNodeView
                            struct TreeNodeView: View {
                    var node: Node<GitTreeElement>
                    @EnvironmentObject var gitTreeStore: GitTreeStore
                    @State private var isExpanded: Bool = true
                    
                    var body: some View {
                        VStack(alignment: .leading) {
                            HStack {
                                if node.children.isEmpty == false {
                                    Button(action: { isExpanded.toggle() }) {
                                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                            .foregroundColor(.accentColor)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                } else {
                                    Spacer()
                                        .frame(width: 16)
                                }
                                NodeContentView(node: node)
                            }
                            if isExpanded {
                                ForEach(node.children, id: \.id) { child in
                                    TreeNodeView(node: child)
                                        .padding(.leading, 20)
                                }
                            }
                        }
                    }
                }
                            
                            // MARK: - NodeContentView
                            struct NodeContentView: View {
                    var node: Node<GitTreeElement>
                    @EnvironmentObject var gitTreeStore: GitTreeStore
                    
                    var body: some View {
                        HStack {
                            switch node.element.type {
                            case .branch:
                                Text("Branch: \(node.element.name ?? "")")
                                    .font(.headline)
                                Spacer()
                                Button(action: {}) {
                                    Image(systemName: "ellipsis")
                                }
                                .contextMenu {
                                    Button(action: {
                                        gitTreeStore.selectedNodeForNewBranch = node
                                        gitTreeStore.isShowingNewBranchSheet = true
                                    }) {
                                        Label("Create New Branch", systemImage: "arrow.branch")
                                    }
                                    Button(action: {
                                        gitTreeStore.selectedBranchNodeForCommit = node
                                        gitTreeStore.isShowingCommitSheet = true
                                    }) {
                                        Label("Add Commit", systemImage: "plus.circle")
                                    }
                                    if node.element.name != "main" {
                                        Button(role: .destructive, action: {
                                            gitTreeStore.deleteBranch(node)
                                        }) {
                                            Label("Delete Branch", systemImage: "trash")
                                        }
                                    }
                                }
                            case .commit:
                                Text("Commit: \(node.element.message ?? "")")
                                    .font(.subheadline)
                                Spacer()
                                Text(node.element.timestamp?.formatted() ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Button(action: {}) {
                                    Image(systemName: "ellipsis")
                                }
                                .contextMenu {
                                    Button(action: {
                                        // Handle viewing the document
                                    }) {
                                        Label("View Document", systemImage: "doc.text.magnifyingglass")
                                    }
                                    Button(role: .destructive, action: {
                                        gitTreeStore.removeCommit(node)
                                    }) {
                                        Label("Delete Commit", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                            
                            // MARK: - NewBranchSheet
                            struct NewBranchSheet: View {
                    @Binding var branchName: String
                    let sourceNode: Node<GitTreeElement>?
                    let gitTreeStore: GitTreeStore
                    @Binding var isPresented: Bool
                    
                    var body: some View {
                        NavigationView {
                            Form {
                                Section(header: Text("New Branch")) {
                                    TextField("Branch Name", text: $branchName)
                                    if let source = sourceNode {
                                        Text("Creating from: \(source.element.name ?? "")")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .navigationTitle("Create Branch")
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Cancel") {
                                        isPresented = false
                                    }
                                }
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Create") {
                                        if let source = sourceNode {
                                            gitTreeStore.createBranch(name: branchName, fromNode: source)
                                        }
                                        branchName = ""
                                        isPresented = false
                                    }
                                    .disabled(branchName.isEmpty)
                                }
                            }
                        }
                        .frame(minWidth: 300, minHeight: 200)
                    }
                }
                            
                            // MARK: - NewCommitSheet
                            struct NewCommitSheet: View {
                    @Binding var commitMessage: String
                    @Binding var document: JobDocument?
                    let branchNode: Node<GitTreeElement>?
                    let gitTreeStore: GitTreeStore
                    @Binding var isPresented: Bool
                    @State private var isImporting: Bool = false
                    
                    var body: some View {
                        NavigationView {
                            Form {
                                Section(header: Text("Commit Details")) {
                                    TextField("Commit Message", text: $commitMessage)
                                    if let branch = branchNode {
                                        Text("On Branch: \(branch.element.name ?? "")")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Section(header: Text("Document")) {
                                    if let document = document {
                                        Text(document.fileName)
                                    }
                                    Button("Select Document") {
                                        isImporting = true
                                    }
                                }
                            }
                            .navigationTitle("Add Commit")
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Cancel") {
                                        isPresented = false
                                    }
                                }
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Add") {
                                        if let branch = branchNode, let document = document {
                                            gitTreeStore.addCommit(document, message: commitMessage, toBranchNode: branch)
                                        }
                                        commitMessage = ""
                                        document = nil
                                        isPresented = false
                                    }
                                    .disabled(commitMessage.isEmpty || document == nil)
                                }
                            }
                        }
                        .fileImporter(
                            isPresented: $isImporting,
                            allowedContentTypes: JobDocument.DocumentType.allowedTypes,
                            allowsMultipleSelection: false
                        ) { result in
                            handleFileImport(result: result)
                        }
                        .frame(minWidth: 300, minHeight: 200)
                    }
                    
                    private func handleFileImport(result: Result<[URL], Error>) {
                        do {
                            let urls = try result.get()
                            if let url = urls.first {
                                let data = try Data(contentsOf: url)
                                document = JobDocument(fileName: url.lastPathComponent, fileData: data)
                            }
                        } catch {
                            print("Failed to import file: \(error.localizedDescription)")
                        }
                    }
                }
                            // MARK: - StatsView
                            struct StatsView: View {
                    @EnvironmentObject var jobStore: JobStore
                    var job: JobApplication
                    
                    var body: some View {
                        ScrollView {
                            VStack(spacing: 24) {
                                // Map View
                                ApplicationMapView(jobStore: jobStore)
                                    .frame(height: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(radius: 2)
                                    .padding(.horizontal)
                                // Location Distribution Chart
                                LocationDistributionChart(jobStore: jobStore)
                                    .frame(height: 200)
                                    .padding(.horizontal)
                                // Contribution Chart
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Application Activity")
                                        .font(.headline)
                                    ContributionChartView(
                                        data: contributionData(),
                                        rows: 7,
                                        columns: 53,
                                        targetValue: maxContribution(),
                                        blockColor: .green
                                    )
                                    .frame(height: 120)
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical)
                        }
                        .navigationTitle("Application Stats")
                    }
                    
                    private func contributionData() -> [Double] {
                        // Generate data array for the past year
                        let calendar = Calendar.current
                        let today = Date()
                        guard let startDate = calendar.date(byAdding: .day, value: -364, to: today) else {
                            return []
                        }
                        var data: [Double] = []
                        for dayOffset in 0..<365 {
                            if let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) {
                                let count = jobStore.jobApplications.filter {
                                    calendar.isDate($0.dateOfApplication, inSameDayAs: date)
                                }.count
                                data.append(Double(count))
                            }
                        }
                        return data
                    }
                    
                    private func maxContribution() -> Double {
                        let counts = jobStore.jobApplications.reduce(into: [Date: Int]()) { result, job in
                            let date = Calendar.current.startOfDay(for: job.dateOfApplication)
                            result[date, default: 0] += 1
                        }
                        return Double(counts.values.max() ?? 1)
                    }
                }
                            
                            // MARK: - ApplicationMapView
                            import SwiftUI
                            import MapKit
                            
                            struct ApplicationMapView: View {
                    let jobStore: JobStore
                    @State private var cameraPosition = MapCameraPosition.region(
                        MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
                            span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 60)
                        )
                    )
                    
                    private let cityCoordinates: [String: (latitude: Double, longitude: Double)] = [
                        "New York City, NY": (40.7505, -73.9934),
                        "Los Angeles, CA": (34.0522, -118.2437),
                        "Chicago, IL": (41.8781, -87.6298),
                        "Newport Beach, CA": (33.6189, -117.9289),
                        "Miami, FL": (25.7617, -80.1918)
                    ]
                    
                    private var annotations: [CityAnnotation] {
                        let locationCounts = Dictionary(grouping: jobStore.jobApplications) { $0.location }
                            .mapValues { $0.count }
                        return cityCoordinates.compactMap { city, coordinates in
                            guard let count = locationCounts[city] else { return nil }
                            return CityAnnotation(
                                city: city,
                                coordinate: CLLocationCoordinate2D(
                                    latitude: coordinates.latitude,
                                    longitude: coordinates.longitude
                                ),
                                count: count
                            )
                        }
                    }
                    
                    var body: some View {
                        Map(position: $cameraPosition) {
                            ForEach(annotations) { annotation in
                                Annotation(annotation.city, coordinate: annotation.coordinate) {
                                    MapMarker(annotation: annotation)
                                }
                            }
                        }
                    }
                }
                            
                            // MARK: - MapMarker
                            struct MapMarker: View {
                    let annotation: CityAnnotation
                    
                    var body: some View {
                        VStack {
                            Circle()
                                .fill(Color.blue.opacity(0.7))
                                .frame(width: CGFloat(annotation.count) * 10 + 20,
                                       height: CGFloat(annotation.count) * 10 + 20)
                                .overlay(
                                    Text("\(annotation.count)")
                                        .foregroundColor(.white)
                                        .font(.system(.caption, design: .rounded).bold())
                                )
                            Text(annotation.city)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color("systemBackground").opacity(0.9))
                                .cornerRadius(4)
                        }
                    }
                }
                            
                            // MARK: - CityAnnotation
                            struct CityAnnotation: Identifiable {
                    let id = UUID()
                    let city: String
                    let coordinate: CLLocationCoordinate2D
                    let count: Int
                }
                            
// MARK: - LocationDistributionChart
struct LocationDistributionChart: View {
    let jobStore: JobStore

    private var locationData: [LocationData] {
        let locations = jobStore.jobApplications.map { $0.location }
        let counts = Dictionary(grouping: locations, by: { $0 })
            .mapValues { $0.count }
            .map { LocationData(city: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
        return counts
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Applications by Location")
                .font(.headline)
            Chart(locationData) { location in
                BarMark(
                    x: .value("Count", location.count),
                    y: .value("City", location.city)
                )
                .foregroundStyle(Color.blue.gradient)
                .annotation(position: .trailing) {
                    Text("\(location.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
    }
}

                    
                    // MARK: - GitHubProgressView
                    struct GitHubProgressView: View {
                        let jobStore: JobStore
                        private let calendar = Calendar.current
                        private let startDate = DateComponents(calendar: Calendar.current, year: 2024, month: 1, day: 1).date!
                        private let endDate = DateComponents(calendar: Calendar.current, year: 2024, month: 12, day: 31).date!
                        
                        var body: some View {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Application Activity")
                                    .font(.headline)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        // Month labels
                                        MonthLabelsView(startDate: startDate, endDate: endDate)
                                        // Days of week labels and contribution grid
                                        HStack(alignment: .top, spacing: 4) {
                                            WeekdayLabelsView()
                                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 15), spacing: 4)], spacing: 4) {
                                                ForEach(datesBetween(startDate, endDate), id: \.self) { date in
                                                    ContributionCell(date: date, jobStore: jobStore)
                                                }
                                            }
                                        }
                                    }
                                    .padding()
                                }
                            }
                        }
                        
                        private func datesBetween(_ start: Date, _ end: Date) -> [Date] {
                            var dates: [Date] = []
                            var currentDate = start
                            while currentDate <= end {
                                dates.append(currentDate)
                                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                            }
                            return dates
                        }
                    }
                    
                    // MARK: - MonthLabelsView
                    struct MonthLabelsView: View {
                        let startDate: Date
                        let endDate: Date
                        private let calendar = Calendar.current
                        
                        var body: some View {
                            HStack(alignment: .bottom, spacing: 0) {
                                ForEach(monthsBetween(startDate, endDate), id: \.self) { date in
                                    Text(monthAbbreviation(for: date))
                                        .font(.caption2)
                                        .frame(width: 15 * CGFloat(weeksInMonth(date)))
                                }
                            }
                            .padding(.leading, 30)
                        }
                        
                        private func monthsBetween(_ start: Date, _ end: Date) -> [Date] {
                            var dates: [Date] = []
                            var current = start
                            while current <= end {
                                dates.append(current)
                                guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: current) else { break }
                                current = nextMonth
                            }
                            return dates
                        }
                        
                        private func monthAbbreviation(for date: Date) -> String {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "MMM"
                            return formatter.string(from: date)
                        }
                        
                        private func weeksInMonth(_ date: Date) -> Int {
                            guard let range = calendar.range(of: .weekOfMonth, in: .month, for: date) else { return 0 }
                            return range.count
                        }
                    }
                    
                    // MARK: - WeekdayLabelsView
                    struct WeekdayLabelsView: View {
                        private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
                        
                        var body: some View {
                            VStack(alignment: .trailing, spacing: 4) {
                                ForEach(weekdays.indices.filter { $0 % 2 == 0 }, id: \.self) { index in
                                    Text(weekdays[index])
                                        .font(.caption2)
                                        .frame(height: 15)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    // MARK: - ContributionCell
                    struct ContributionCell: View {
                        let date: Date
                        let jobStore: JobStore
                        private var contributionCount: Int {
                            jobStore.jobApplications.filter {
                                Calendar.current.isDate($0.dateOfApplication, inSameDayAs: date)
                            }.count
                        }
                        
                        private var cellColor: Color {
                            switch contributionCount {
                            case 0: return Color.secondary.opacity(0.1)
                            case 1: return Color.green.opacity(0.3)
                            case 2: return Color.green.opacity(0.5)
                            case 3: return Color.green.opacity(0.7)
                            default: return Color.green
                            }
                        }
                        
                        var body: some View {
                            Rectangle()
                                .fill(cellColor)
                                .frame(width: 15, height: 15)
                                .cornerRadius(2)
                                .help("\(contributionCount) applications on \(date.formatted(date: .long, time: .omitted))")
                        }
                    }
                    
                    // MARK: - Data Models for StatsView
                    
                    struct LocationData: Identifiable {
                        let id = UUID()
                        let city: String
                        let count: Int
                    }
                    
                
                            
                            

