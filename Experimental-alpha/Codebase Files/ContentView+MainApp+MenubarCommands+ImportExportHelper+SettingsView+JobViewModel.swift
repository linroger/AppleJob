//
//  ContentView.swift
//  Experimental-alpha
//
//  Created by Roger Lin on 3/14/25.
//


// -----------------------------------------------------------------------------
// MARK: - ContentView+MainApp+MenubarCommands+ImportExportHelper+SettingsView+JobViewModel
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
    @EnvironmentObject var noteStore: NoteStore
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
                .frame(width: 400)

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
        case .notes:
            // Notes don't need a sidebar, so we'll show an empty view with a title
            VStack(alignment: .leading) {
                Text("Notes")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Use the main panel to view, create and manage your notes.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Spacer()
            }
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
        case .notes:
            NotesView()
        }
    }
}

//-----------------------------------------------------------------------------------------------------//




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
    @StateObject private var noteStore: NoteStore
    @StateObject private var importExportHelper = ImportExportHelper()
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: SwiftDataJobApplication.self, SwiftDataJobDocument.self, SwiftDataNote.self,
                configurations: ModelConfiguration()
            )
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }

        // Create the stores separately
        let stores = AppleJobApp.createStores(using: container)
        _docStore = StateObject(wrappedValue: stores.documentStore)
        _jobStore = StateObject(wrappedValue: stores.jobStore)
        _noteStore = StateObject(wrappedValue: stores.noteStore)
    }

    private static func createStores(using container: ModelContainer) -> (documentStore: DocumentStore, jobStore: JobStore, noteStore: NoteStore) {
        let documentStore = DocumentStore(modelContext: container.mainContext)
        let jobStore = JobStore(documentStore: documentStore)
        let noteStore = NoteStore(modelContext: container.mainContext)
        return (documentStore, jobStore, noteStore)
    }

    // Settings sheet state
    @State private var showSettings = false

    var body: some Scene {
        WindowGroup {
            ContentView(showSettings: $showSettings)
                .environmentObject(jobStore)
                .environmentObject(docStore)
                .environmentObject(noteStore)
                .environmentObject(importExportHelper)

                .sheet(isPresented: $showSettings) {
                    SettingsView(importExportHelper: importExportHelper)
                        .environmentObject(jobStore)
                        .environmentObject(docStore)
                        .environmentObject(noteStore)
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


//-----------------------------------------------------------------------------------------------------//


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

//-----------------------------------------------------------------------------------------------------//


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
 @Published var status: JobStatus = .applied  // Default to Applied
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
 @Published var jobType: JobType = .fullTime  // Default to Full Time
 @Published var desiredSkillText: String = ""
 @Published var selectedDesiredSkills: [String] = []
 @Published var availableSkillSuggestions: [String] = []
 @Published var isInputValid: Bool = false
 @Published var jobDeadline: Date? = nil
 @Published var linkedInInsightsData: LinkedInInsightsData? = nil

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
     linkedInInsightsData = job.linkedInInsightsData

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
            jobDeadline: jobDeadline,
            linkedInInsightsData: linkedInInsightsData
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
             linkedInInsightsData: linkedInInsightsData,
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
        linkedInInsightsData = nil
    }
}
