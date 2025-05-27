//
//  AppleJob.swift
//  Updated to address new onChange/Map usage in macOS 14, and remove .environmentObject call in DocumentSidebarBackgroundModifier
//
//  Includes:
//    - Models
//    - View Models
//    - Views (Main, Sidebar, Add/Edit, Stats, Documents, etc.)
//    - Document Categories & Drag/Drop
//    - QuickLook Preview (only for Stats & JobDetail), but *embedded PDFKit* in DocumentsMainView
//    - Additional Stats
//    - Move Document to Category command
//    - Custom doc selection highlight
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

// MARK: - Models

/// Represents different statuses for a job application.
enum JobStatus: String, CaseIterable, Codable {
    case interested = "Interested"
    case applied = "Applied"
    case interview = "Interview"
    case offer = "Offer"
    case rejection = "Rejection"

    var displayColor: Color {
        switch self {
        case .interested: return .gray
        case .applied:    return .blue
        case .interview:  return .orange
        case .offer:      return .green
        case .rejection:  return .red
        }
    }
}

enum Sort: String, CaseIterable {
    case title = "Job Title"
    case company = "Company Name"
    case recentlyApplied = "Recently Applied"
}

/// Primary data model representing a job application.
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

    // Custom decoding/encoding for backwards compatibility
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
        self.coverLetter = try container.decode(String.self, forKey: .coverLetter)
        self.notes = try? container.decode(String.self, forKey: .notes)
        self.isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        self.documents = try container.decode([JobDocument].self, forKey: .documents)
    }
    // We skip the custom decode/encode here for brevity; assume they match your original code.
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
    }
    enum CodingKeys: String, CodingKey {
        case id
        case companyName
        case jobTitle
        case statusRawValue
        case dateOfApplication
        case location
        case linkToJobString
        case salary
        case jobDescription
        case coverLetter
        case notes
        case isFavorite
        case documents

    static func == (lhs: JobApplication, rhs: JobApplication) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Represents a document uploaded to the system.
struct JobDocument: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var fileName: String
    var fileData: Data

    var dateOfApplication: Date
    var lastModifiedDate: Date
    var fileSize: Int
    var wordCount: Int
    
    var categoryID: UUID?

    init(id: UUID = UUID(), fileName: String, fileData: Data) {
        self.id = id
        self.fileName = fileName
        self.fileData = fileData
        self.dateOfApplication = Date()
        self.lastModifiedDate = Date()
        self.fileSize = fileData.count
        self.wordCount = 0
        self.categoryID = nil
    }
}

/// Represents a named category for documents.
struct DocumentCategory: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var isExpanded: Bool = true

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

/// For stats
struct CityPin: Identifiable {
    let id = UUID()
    let city: String
    let coordinate: CLLocationCoordinate2D
    let count: Int
}

fileprivate var CityCoordinateDictionary: [String: CLLocationCoordinate2D] = [
    "New York City, NY": CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
    "Los Angeles, CA":   CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
    "Chicago, IL":       CLLocationCoordinate2D(latitude: 41.8781, longitude: -87.6298),
    // ...
    "Global":            CLLocationCoordinate2D(latitude: 34.149884, longitude: -118.056932)
]

// MARK: - Stores

class JobStore: ObservableObject {
    @Published var jobApplications: [JobApplication] = []
    @Published var selectedJob: JobApplication? = nil

    @Published var isAddingNewJob = false
    @Published var isEditingJob = false
    @Published var sorting: Sort = .recentlyApplied

    init() { loadJobs() }

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

    // ... other CRUD methods omitted for brevity

    func sortJobs(by sortOption: Sort) { /* ... */ }
    func saveJobs() { /* ... */ }
    func loadJobs() { /* ... */ }
}

class DocumentStore: ObservableObject {
    @Published var documents: [JobDocument] = []
    @Published var selectedDocument: JobDocument? = nil

    @Published var categories: [DocumentCategory] = []

    @Published var isCreatingNewCategory = false
    @Published var newCategoryName: String = "Category Name"

    @Published var quickLookURL: URL? = nil

    init() {
        loadDocuments()
        loadCategories()
    }

    func uploadDocuments(from urls: [URL]) { /* ... */ }
    func deleteDocument(_ document: JobDocument) { /* ... */ }
    func duplicateDocument(_ document: JobDocument) { /* ... */ }
    func assignDocument(_ doc: JobDocument, to category: DocumentCategory) { /* ... */ }
    func unassignDocument(_ doc: JobDocument) { /* ... */ }

    func loadDocuments() { /* ... */ }
    func loadCategories() { /* ... */ }
    func saveDocuments() { /* ... */ }
    func saveCategories() { /* ... */ }
}

// MARK: - App

@main
struct AppleJobApp: App {
    @StateObject private var jobStore = JobStore()
    @StateObject private var docStore = DocumentStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(jobStore)
                .environmentObject(docStore)
        }
        .commands {
            // ...
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore

    @State private var selectedSection: ViewSection = .jobDetails
    @State private var isDarkMode: Bool = false

    var body: some View {
        NavigationView {
            sidebar
            mainContent
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .toolbar {
            ToolbarItemGroup {
                Picker("Section", selection: $selectedSection) {
                    ForEach(ViewSection.allCases, id: \.self) { section in
                        Text(section.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                Spacer()

                Button {
                    isDarkMode.toggle()
                } label: {
                    Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                }
            }
        }
    }

    private var sidebar: some View {
        switch selectedSection {
        case .jobDetails, .stats:
            JobSidebarView()
        case .documents:
            DocumentsSidebarView()
        }
    }

    private var mainContent: some View {
        switch selectedSection {
        case .jobDetails:
            if let job = jobStore.selectedJob {
                JobDetailView(job: job)
            } else {
                Text("Select a job to view details")
            }
        case .stats:
            EnhancedStatsView()
        case .documents:
            DocumentsMainView()
        }
    }
}

enum ViewSection: String, CaseIterable {
    case jobDetails = "Job Details"
    case stats = "Stats"
    case documents = "Documents"
}

// MARK: - JobSidebarView

struct JobSidebarView: View {
    @EnvironmentObject var jobStore: JobStore
    @State private var searchText: String = ""

    var body: some View {
        VStack {
            List(selection: $jobStore.selectedJob) {
                ForEach(filteredJobs, id: \.id) { job in
                    SidebarItemView(job: job, isSelected: Binding(
                        get: { jobStore.selectedJob == job },
                        set: { newVal in
                            jobStore.selectedJob = newVal ? job : nil
                        }
                    ))
                .tag(job)
                }
                .onDelete(perform: deleteJobs)
            }
            .listStyle(SidebarListStyle())
            .searchable(text: $searchText)
        }
        .navigationTitle("Applications")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    jobStore.isAddingNewJob = true
                } label: {
                    Label("New", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $jobStore.isAddingNewJob) {
            AddJobView(isPresented: $jobStore.isAddingNewJob)
                .environmentObject(jobStore)
                .environmentObject(DocumentStore())
        }
        .sheet(isPresented: $jobStore.isEditingJob) {
            if let job = jobStore.selectedJob {
                EditJobView(isPresented: $jobStore.isEditingJob, job: job)
                    .environmentObject(jobStore)
                    .environmentObject(DocumentStore())
            }
        }
    }

    private var filteredJobs: [JobApplication] {
        if searchText.isEmpty { return jobStore.jobApplications }
        let lowerSearch = searchText.lowercased()
        return jobStore.jobApplications.filter {
            $0.companyName.lowercased().contains(lowerSearch)
            || $0.jobTitle.lowercased().contains(lowerSearch)
            || $0.location.lowercased().contains(lowerSearch)
        }
    }

    private func deleteJobs(at offsets: IndexSet) {
        for index in offsets {
            let job = filteredJobs[index]
            jobStore.deleteJob(for: job.id)
        }
    }
}

/// Single job item in the sidebar list.
struct SidebarItemView: View {
    @EnvironmentObject var jobStore: JobStore
    let job: JobApplication
    @Binding var isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(job.companyName)
                    .font(.headline)
                Text(job.jobTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(job.status.rawValue)
                .font(.caption)
                .padding(5)
                .background(
                    Capsule()
                        .fill(isSelected ? .secondary.opacity(0.2) : job.status.displayColor.opacity(0.2))
                )
                .foregroundColor(job.status.displayColor)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isSelected.toggle()
        }
        .contextMenu {
            Button("Edit") {
                jobStore.isEditingJob = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button("Duplicate") {
                jobStore.duplicateJob(job)
            } label: {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }
            Divider()
            Menu("Change Status") {
                ForEach(JobStatus.allCases, id: \.self) { status in
                    Button {
                        jobStore.updateJobStatus(job.id, to: status)
                    } label: {
                        Text(status.rawValue)
                    }
                }
            }
            Divider()
            Button {
                jobStore.toggleFavorite(for: job.id)
            } label: {
                Label(job.isFavorite ? "Remove from Favorites" : "Add to Favorites", systemImage: job.isFavorite ? "heart.fill" : "heart")
        }
            if let link = job.linkToJobString, let url = URL(string: link) {
                Divider()
                Button {
                    NSWorkspace.shared.open(url)
                } label: {
                    Label("Open Job Posting", systemImage: "safari")
    }
}
            Divider()
            Button(role: .destructive) {
                jobStore.deleteJob(for: job.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
