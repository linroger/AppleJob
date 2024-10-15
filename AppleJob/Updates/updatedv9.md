//
//  AppleJob.swift
//  Updated to address new onChange/Map usage in macOS 14, and remove .environmentObject call in DocumentSidebarBackgroundModifier
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

    // We skip the custom decode/encode here for brevity; assume they match your original code.

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
        }
        .sheet(isPresented: $jobStore.isEditingJob) {
            if let job = jobStore.selectedJob {
                EditJobView(isPresented: $jobStore.isEditingJob, job: job)
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
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(job.status.rawValue)
                .padding(4)
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
            }
            Button("Duplicate") {
                jobStore.duplicateJob(job)
            }
            Divider()
            // ...
        }
    }
}

// MARK: - DocumentsSidebarView

struct DocumentsSidebarView: View {
    @EnvironmentObject var docStore: DocumentStore

    var body: some View {
        List(selection: $docStore.selectedDocument) {
            Section {
                DisclosureGroup("All Documents") {
                    ForEach(uncategorizedDocuments, id: \.id) { doc in
                        documentSidebarItem(doc)
                    }
                }
                .font(.headline)
                .foregroundColor(.primary)
            }

            ForEach($docStore.categories, id: \.id) { $category in
                DisclosureGroup(isExpanded: $category.isExpanded) {
                    ForEach(docsForCategory(category.id), id: \.id) { doc in
                        documentSidebarItem(doc)
                    }
                } label: {
                    Text(category.name).font(.headline)
                }
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Documents")
    }

    private var uncategorizedDocuments: [JobDocument] {
        docStore.documents.filter { $0.categoryID == nil }
    }
    private func docsForCategory(_ catID: UUID) -> [JobDocument] {
        docStore.documents.filter { $0.categoryID == catID }
    }

    private func documentSidebarItem(_ doc: JobDocument) -> some View {
        HStack {
            Text(cleanFileName(doc.fileName))
            Spacer()
            Menu("Move to Category") {
                ForEach(docStore.categories, id: \.id) { cat in
                    Button(cat.name) {
                        docStore.assignDocument(doc, to: cat)
                    }
                }
                Button("Uncategorized") {
                    docStore.unassignDocument(doc)
                }
            }
        }
        .contentShape(Rectangle())
        .listRowBackground(docStore.selectedDocument == doc ? Color.accentColor.opacity(0.4) : Color.clear)
        .onTapGesture {
            docStore.selectedDocument = doc
        }
    }

    private func cleanFileName(_ filename: String) -> String {
        var cleaned = filename
        let removeList = ["Roger Lin", "Position", "2024", "Cover Letter"]
        for s in removeList {
            cleaned = cleaned.replacingOccurrences(of: s, with: "")
        }
        // ...
        return cleaned.trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - DocumentsMainView

struct DocumentsMainView: View {
    @EnvironmentObject var docStore: DocumentStore

    var body: some View {
        ZStack {
            if docStore.documents.isEmpty {
                Text("No Documents")
            } else if let doc = docStore.selectedDocument {
                PDFKitEmbeddedView(fileData: doc.fileData)
            } else {
                Text("Select a document")
            }
        }
    }
}

struct PDFKitEmbeddedView: NSViewRepresentable {
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
        if let newDoc = PDFDocument(data: fileData) {
            nsView.document = newDoc
        }
    }
}

// MARK: - EnhancedStatsView

struct EnhancedStatsView: View {
    @EnvironmentObject var jobStore: JobStore
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 50)
    )
    @State private var cityPins: [CityPin] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Applications Map")
                .font(.headline)
            // Updated approach for maps in macOS 14:
            if #available(macOS 14.0, *) {
                Map {
                    ForEach(cityPins) { pin in
                        Annotation(pin.city, coordinate: pin.coordinate) {
                            Circle()
                                .fill(Color.red.opacity(0.5))
                                .frame(width: max(10, CGFloat(pin.count * 2)),
                                       height: max(10, CGFloat(pin.count * 2)))
                                .overlay(
                                    Text("\(pin.count)")
                                        .foregroundColor(.white)
                                        .font(.system(size: 10))
                                )
                        }
                    }
                }
                .mapStyle(.standard)
                .defaultMapRect(computeMapRect())
                .frame(height: 300)
                .cornerRadius(8)
            } else {
                // Fallback for macOS 13 or older:
                Map(coordinateRegion: $region,
                    annotationItems: cityPins) { cityPin in
                    MapAnnotation(coordinate: cityPin.coordinate) {
                        Circle()
                            .fill(Color.red.opacity(0.5))
                            .frame(width: max(10, CGFloat(cityPin.count * 2)),
                                   height: max(10, CGFloat(cityPin.count * 2)))
                            .overlay(
                                Text("\(cityPin.count)")
                                    .foregroundColor(.white)
                                    .font(.system(size: 10))
                            )
                    }
                }
                .frame(height: 300)
                .cornerRadius(8)
            }

            Text("Other Stats Here...")
        }
        .onAppear {
            computeCityPins()
        }
    }

    private func computeCityPins() {
        // ...
    }

    private func computeMapRect() -> MKMapRect {
        // Compute an MKMapRect that includes all cityPins, or a default region.
        var rect = MKMapRect.null
        for pin in cityPins {
            let point = MKMapPoint(pin.coordinate)
            let mapSize = MKMapSize(width: 0.1, height: 0.1)
            let mapRect = MKMapRect(origin: point, size: mapSize)
            rect = rect.union(mapRect)
        }
        return rect.isNull ? MKMapRect(x: 0, y: 0, width: 10000, height: 10000) : rect
    }
}

// MARK: - AddJobView, EditJobView (similarly updated onChange usage)

struct AddJobView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = JobViewModel()

    var body: some View {
        VStack {
            Text("Add Job")
            TextField("Company Name", text: $viewModel.companyName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                // New onChange usage (no-arg version, if you just re-validate):
                .onChange(of: viewModel.companyName) {
                    viewModel.validateInputs()
                }
            // ...
        }
        .padding()
    }
}

struct EditJobView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel: JobViewModel

    init(isPresented: Binding<Bool>, job: JobApplication) {
        self._isPresented = isPresented
        _viewModel = StateObject(wrappedValue: JobViewModel(job: job))
    }

    var body: some View {
        VStack {
            Text("Edit Job")
            TextField("Company Name", text: $viewModel.companyName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                // If you need the old/new values:
                .onChange(of: viewModel.companyName, initial: false) { oldVal, newVal in
                    // Compare oldVal vs newVal, etc.
                    if !newVal.isEmpty {
                        viewModel.validateInputs()
                    }
                }
            // ...
        }
        .padding()
    }
}

// MARK: - Minimal ViewModel

class JobViewModel: ObservableObject {
    @Published var companyName: String = ""
    // ...
    func validateInputs() { /* ... */ }

    init() { }
    init(job: JobApplication) {
        self.companyName = job.companyName
        // ...
    }
}
