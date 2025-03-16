// -----------------------------------------------------------------------------
// MARK: - JobSidebar+AddJobView+EditJobView+NewLocationView+JobDetailsView
// -----------------------------------------------------------------------------
//
//  JobSidebarView.swift
//  Experimental-alpha
//
//  Created by Roger Lin on 3/14/25.
//


// -----------------------------------------------------------------------------
// MARK: - JobSidebar+AddJobView+EditJobView+NewLocationView+JobDetailsView
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

    @State private var importedDocuments: [JobDocument] = []
    @State private var isImporting = false
    @State private var locations: [String] = CityCoordinateDictionary.keys.sorted()
    @State private var showNewLocationWindow = false
    @State private var quickLookURL: URL? = nil

    @State private var windowRef: NSWindow?
    @State private var showInsightsImporter = false
    @State private var linkedInInsightsData: LinkedInInsightsData? = nil
    @StateObject private var viewModel: JobViewModel

       init(isPresented: Binding<Bool>) {
           self._isPresented = isPresented
           let vm = JobViewModel(
               job: JobApplication(
                   id: UUID(),
                   companyName: "",
                   jobTitle: "",
                   status: .applied,
                   dateOfApplication: Date(),
                   location: "",
                   linkToJobString: nil,
                   salaryString: nil,
                   jobDescription: "",
                   coverLetter: "",
                   notes: "",
                   documents: [],
                   jobType: .fullTime,
                   desiredSkillNames: []
               ),
               availableSkills: []
           )
           _viewModel = StateObject(wrappedValue: vm)
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
                        
                        // LinkedIn Insights Button with file importer
                        Button(action: {
                            showInsightsImporter = true
                        }) {
                            Label("LinkedIn Insights", systemImage: "chart.bar.fill")
                        }
                        .help("Import LinkedIn Insights")
                    }
                    
                    // Add LinkedIn Insights file importer
                    .fileImporter(
                        isPresented: $showInsightsImporter,
                        allowedContentTypes: [.html],
                        allowsMultipleSelection: false
                    ) { result in
                        switch result {
                        case .success(let urls):
                            if let url = urls.first {
                                do {
                                    // 1. Security-scoped resource handling
                                    guard url.startAccessingSecurityScopedResource() else { 
                                        throw NSError(domain: "LinkedInInsightsParser", code: 1, 
                                                    userInfo: [NSLocalizedDescriptionKey: "Failed to access the security scoped resource"])
                                    }
                                    
                                    defer { url.stopAccessingSecurityScopedResource() }
                                    
                                    // 2. Read the HTML content
                                    let html = try String(contentsOf: url, encoding: .utf8)
                                    
                                    // 3. Parse the data
                                    let data = try extractData(from: html)
                                    
                                    // 4. Update the ViewModel
                                    DispatchQueue.main.async {
                                        linkedInInsightsData = data
                                        viewModel.linkedInInsightsData = data
                                    }
                                } catch {
                                    print("Failed to parse LinkedIn Insights: \(error)")
                                }
                            }
                        case .failure(let error):
                            print("Failed to select file: \(error)")
                        }
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
    @State private var showInsightsImporter = false
    @State private var linkedInInsightsData: LinkedInInsightsData? = nil

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
                        
                        // LinkedIn Insights Button with file importer
                        Button(action: {
                            showInsightsImporter = true
                        }) {
                            Label("LinkedIn Insights", systemImage: "chart.bar.fill")
                        }
                        .help("Import LinkedIn Insights")
                    }
                    
                    // Add LinkedIn Insights file importer
                    .fileImporter(
                        isPresented: $showInsightsImporter,
                        allowedContentTypes: [.html],
                        allowsMultipleSelection: false
                    ) { result in
                        switch result {
                        case .success(let urls):
                            if let url = urls.first {
                                do {
                                    // 1. Security-scoped resource handling
                                    guard url.startAccessingSecurityScopedResource() else { 
                                        throw NSError(domain: "LinkedInInsightsParser", code: 1, 
                                                    userInfo: [NSLocalizedDescriptionKey: "Failed to access the security scoped resource"])
                                    }
                                    
                                    defer { url.stopAccessingSecurityScopedResource() }
                                    
                                    // 2. Read the HTML content
                                    let html = try String(contentsOf: url, encoding: .utf8)
                                    
                                    // 3. Parse the data
                                    let data = try extractData(from: html)
                                    
                                    // 4. Update the ViewModel
                                    DispatchQueue.main.async {
                                        linkedInInsightsData = data
                                        viewModel.linkedInInsightsData = data
                                    }
                                } catch {
                                    print("Failed to parse LinkedIn Insights: \(error)")
                                }
                            }
                        case .failure(let error):
                            print("Failed to select file: \(error)")
                        }
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

//-----------------------------------------------------------------------------------------------------//

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
                        // 1. Security-scoped resource handling
                        guard url.startAccessingSecurityScopedResource() else { 
                            throw NSError(domain: "LinkedInInsightsParser", code: 1, 
                                        userInfo: [NSLocalizedDescriptionKey: "Failed to access the security scoped resource"])
                        }
                        
                        defer { url.stopAccessingSecurityScopedResource() }
                        
                        // 2. Read the HTML content
                        let html = try String(contentsOf: url, encoding: .utf8)
                        
                        // 3. Parse the data
                        let parsedData = try extractData(from: html)
                        self.linkedInInsightsData = parsedData
                        
                        // 4. Save insights data to job notes
                        let encoder = JSONEncoder()
                        let jsonData = try encoder.encode(parsedData)
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