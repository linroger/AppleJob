
#  <#Title#>

 
 

// --------------------------------------------------
// MARK: - ContentView
// 
enum ViewSection: String, CaseIterable, CaseNameDisplayable {
    case jobDetails = "Job Details"
    case stats = "Stats"
    case documents = "Documents"

   var displayName: String {
       return self.caseNameForDisplay()
   }
}
 
struct ContentView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @EnvironmentObject var importExportHelper: ImportExportHelper
    @State private var selectedSection: ViewSection = .jobDetails
    @State private var searchText: String = ""
    @State private var isDarkMode: Bool = false
    @State private var showDocInfoPopover = false
    @State private var isDirectlyPresentingAddJobView = false // ADD THIS STATE VARIABLE
 
    var body: some View {
        NavigationView {
            sidebar
                .frame(minWidth: 250)
                .background(
                    Color.black.opacity(0.03)
                        .blur(radius: 3)
                )
            mainContent
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
                                docStore.uploadDocuments(from: openPanel.urls)
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
        .sheet(isPresented: $jobStore.isAddingNewJob) {
            AddJobView(isPresented: $jobStore.isAddingNewJob)
                .environmentObject(jobStore)
                .environmentObject(docStore)
                .onAppear {
                    print("ContentView: Presenting AddJobView sheet because jobStore.isAddingNewJob is \(jobStore.isAddingNewJob)")
                }
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
                    .id(job.id)
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
  
 
 
/**
 A view model used for AddJobView and EditJobView. Plain text only.
 */
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
    @Published var salaryString: String = "" // String for UI input/output
   @Published var salaryDouble: Double? = nil
   @Published var jobType: JobType = .none
   @Published var desiredSkillText: String = ""
   @Published var selectedDesiredSkills: [String] = []
   @Published var availableSkillSuggestions: [String] = []
   @Published var isAddingAlias = false
   @Published var skillToAddAlias: String? = nil
 
    @Published var isInputValid: Bool = false
 
    init() {
        validateInputs()
    }
 
    
   init(job: JobApplication, availableSkills: [DesiredSkill]) {
        companyName = job.companyName
        jobTitle = job.jobTitle
        status = job.status
        dateOfApplication = job.dateOfApplication
        location = job.location
        salaryDouble = job.salary
        salaryString = formatSalaryAsInteger(job.salary)
        linkToJob = job.linkToJobString ?? ""
        jobDescription = job.jobDescription
        coverLetter = job.coverLetter
        notes = job.notes ?? ""
        
        if let salary = job.salary {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = Locale.current.currency?.identifier ?? "USD" // Use the user's locale or fallback to USD
            salaryString = formatter.string(from: NSNumber(value: salary)) ?? ""
        } else {
            salaryString = ""
        }
       jobType = job.jobType
       selectedDesiredSkills = job.desiredSkillNames
       self.availableSkillSuggestions = availableSkills.map { $0.name }.sorted()
       validateInputs()
   }
        
   init() {
        validateInputs()
    }
 
    func validateInputs() {
        DispatchQueue.main.async {
            self.isInputValid = !(self.companyName.isEmpty || self.jobTitle.isEmpty)
        }
    }
    // Format salary as an integer (e.g., $50,000)
       func formatSalaryAsInteger(_ value: Double?) -> String {
           guard let value = value else { return "" }
           let formatter = NumberFormatter()
           formatter.numberStyle = .currency
           formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
           formatter.maximumFractionDigits = 0 // No decimals for integer formatting
           return formatter.string(from: NSNumber(value: value)) ?? ""
       }
 
       // Parse a formatted string back into a Double
       func parseSalary(_ value: String) -> Double? {
           let formatter = NumberFormatter()
           formatter.numberStyle = .currency
           formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
           return formatter.number(from: value)?.doubleValue
       }
 
       // Update salaryString and salaryDouble when the user edits the field
       func updateSalary(fromString newValue: String) {
           salaryString = newValue
           salaryDouble = parseSalary(newValue)
       }

   func updateSkillSuggestions(availableSkills: [DesiredSkill]) {
       // Filter suggestions based on what's typed
       availableSkillSuggestions = availableSkills
           .map { $0.name }
           .filter { $0.lowercased().contains(desiredSkillText.lowercased()) }
           .sorted()
   }

   /**
    Add a skill (or multiple skills if the user typed comma-separated)
    - If new, store it in the global jobStore
    - Then add it to the local selectedDesiredSkills
    */
   func addSelectedSkill(skillName: String, jobStore: JobStore) {
       // Check if user typed comma-separated list
       let skillParts = skillName.components(separatedBy: ",")
       for part in skillParts {
           let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
           guard !trimmed.isEmpty else { continue }

           // If skill doesn't exist globally, add it
           if !jobStore.availableSkills.contains(where: { $0.name.lowercased() == trimmed.lowercased() }) {
               let newSkill = DesiredSkill(name: trimmed)
               jobStore.addSkill(newSkill)
           }

           // Add to this job's local selection
           if !self.selectedDesiredSkills.contains(trimmed) {
               self.selectedDesiredSkills.append(trimmed)
           }
       }
       // Clear the text field after commit
       self.desiredSkillText = ""
       // Re-update suggestions
       self.updateSkillSuggestions(availableSkills: jobStore.availableSkills)
   }

   func removeSelectedSkill(skillName: String) {
       selectedDesiredSkills.removeAll { $0 == skillName }
   }

    func addJob(to store: JobStore, documents: [JobDocument]) {
        guard isInputValid else { return }
        let newJob = JobApplication(
            companyName: companyName,
            jobTitle: jobTitle,
            status: status,
            dateOfApplication: dateOfApplication,
            applicationDeadline: applicationDeadline,
            location: location,
            linkToJobString: linkToJob.isEmpty ? nil : linkToJob,
            salary: salaryDouble, // Step 2.7: Use salaryDouble
            jobDescription: jobDescription,
            coverLetter: coverLetter,
            notes: notes,
            documents: documents,
            isFavorite: false
           jobType: jobType,
           desiredSkillNames: selectedDesiredSkills
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
           applicationDeadline: applicationDeadline,
           location: location,
           linkToJobString: linkToJob.isEmpty ? nil : linkToJob,
           salary: salaryDouble,
           jobDescription: jobDescription,
           coverLetter: coverLetter,
           notes: notes,
           documents: documents,
           isFavorite: originalJob.isFavorite,
           jobType: jobType,
           desiredSkillNames: selectedDesiredSkills
       )
       store.editJob(with: updatedJob)
       reset()
   }

    func reset() {
        companyName = ""
        jobTitle = ""
        status = .interested
        dateOfApplication = Date()
        dateOfApplication = Date()
        location = ""
        linkToJob = ""
        jobDescription = ""
        coverLetter = ""
        notes = ""
        salaryString = "" // Step 2.9: Reset salaryString
       jobType = .none
       selectedDesiredSkills = []
        validateInputs()
    }
}


/**
A single row in the sidebar. We show a right-click menu for duplicating, editing, changing job status,
changing job type for all selected, etc.
*/
 
 
// --------------------------------------------------
// MARK: - JobDetailView
// --------------------------------------------------
struct JobDetailView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    let job: JobApplication
 
    @State private var windowRef: NSWindow?
    @State private var quickLookURL: URL? = nil
 
    let markdownParser = MarkdownParser() // Initialize MarkdownParser - Step 1.3
 
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(job.companyName)
                    .font(.largeTitle)
                    .bold()
                Text(job.jobTitle)
                    .font(.title2)
                HStack {
                    Text("Status: ")
                        .bold()
                    Text(job.status.rawValue)
                        .foregroundColor(job.status.displayColor)
                }
                if let link = job.linkToJobString, let url = URL(string: link) {
                    Link("View Job Posting", destination: url)
                       .accessibilityLabel("View job posting link")
               } else {
                   Text("No job link available")
                       .foregroundColor(.secondary)
                }
                if !job.location.isEmpty {
                    Text("Location: \(job.location)")
                        .font(.headline)
               } else {
                   Text("No location specified")
                       .foregroundColor(.secondary)
                }
                Text("Applied on: \(job.dateOfApplication.formatted(date: .abbreviated, time: .omitted))")
                                }
                Text("Application Deadline: \(job.applicationDeadline.formatted(date: .abbreviated, time: .omitted))")
               // Salary
                if let salary = job.salary {
                    let salaryAsInt = Int(salary) // Convert salary to Int
                    Text("Salary: \(salaryAsInt.formatted(.currency(code: "USD")))")
                        .font(.headline)
                }

               // Documents Section
                if !job.documents.isEmpty {
                    Divider()
                    Text("Documents")
                        .font(.headline)
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(job.documents, id: \.id) { doc in
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
                                }
                                .contextMenu {
                                    Button("Reveal in Finder") {
                                        revealInFinder(doc)
                                    }
                                    Button("Delete Document") {
                                        docStore.deleteDocument(doc)
                                    }
                                    Divider()
                                    Button("Edit Metadata") {
                                        docStore.beginEditMetadata(for: doc)
                                    }
                                }
                            }
                        }
                    }
                }
 
               // Desired Skills (chips)
               if !job.desiredSkillNames.isEmpty {
                   Divider()
                   Text("Desired Skills")
                       .font(.headline)
                   ScrollView(.horizontal, showsIndicators: false) {
                       HStack(spacing: 8) {
                           ForEach(job.desiredSkillNames, id: \.self) { skillName in
                               if let skillObj = jobStore.availableSkills.first(where: { $0.name == skillName }) {
                                   SkillChipView(skill: skillObj)
                                       .environmentObject(jobStore)
                               } else {
                                   Text(skillName)
                                       .padding(.horizontal, 8)
                                       .padding(.vertical, 4)
                                       .background(Color.gray.opacity(0.2))
                                       .cornerRadius(8)
                               }
                           }
                       }
                       .padding(.vertical, 4)
                   }
               }

               // Job Description Section
                if !job.jobDescription.isEmpty {
                    Divider()
                   HStack {
                    Text("Job Description")
                        .font(.headline)
 
                       // NEW: Copy button
                    // Use MarkdownParser to parse jobDescription
                       Button("Copy") {
                           let pb = NSPasteboard.general
                           pb.declareTypes([.string], owner: nil)
                           pb.setString(job.jobDescription, forType: .string)
                    let attributedString = markdownParser.parse(job.jobDescription) // Step 1.3: Directly use the returned NSAttributedString
                       }
                       .help("Copy job description to clipboard")
                   }

                   // Use the same font size as notes (which is typically .body)
                   let attributedString = markdownParser.parse(job.jobDescription)
                    Text(AttributedString(attributedString)) // Convert NSAttributedString to SwiftUI AttributedString
                       .font(.body) // ADDED: match notes font size
                        .padding(4)
                }

               // Cover Letter
                if !job.coverLetter.isEmpty {
                    Divider()
                    Text("Cover Letter")
                        .font(.headline)
                    Text(job.coverLetter)
                       .font(.body)  // keep consistency
                        .padding(4)
                }

               // Notes
                Divider()
                Text("Notes")
                    .font(.headline)
                if let notes = job.notes, !notes.isEmpty {
                    Text(notes)
                       .font(.body) // keep same size as job description
                        .padding(4)
                } else {
                    Text("No notes provided.")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
        .toolbar {
            ToolbarItemGroup {
                Button {
                    jobStore.isEditingJob = true
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
                if let keyWindow = NSApp.windows.first(where: { $0.isKeyWindow }) {
                    windowRef = keyWindow
                }
            }
            updateWindowTitle()
        }
        .onChange(of: job.id) { _, _ in
            updateWindowTitle()
        }
        .quickLookPreview($quickLookURL)
    }
 
    func updateWindowTitle() {
        guard let window = windowRef else { return }
        window.title = "\(job.companyName) \(job.jobTitle)"
    }
 
    func cleanFileName(_ filename: String) -> String {
        var cleanedName = filename
        let stringsToRemove = ["Roger Lin", "Position", "2024", "Cover Letter"]
        for s in stringsToRemove {
            cleanedName = cleanedName.replacingOccurrences(of: s, with: "")
        }
        let exts = [".pdf", ".docx", ".pages", ".rtf", ".txt"]
        for e in exts {
            if cleanedName.hasSuffix(e) {
                cleanedName = String(cleanedName.dropLast(e.count))
                break
            }
        }
        return cleanedName.trimmingCharacters(in: .whitespaces)
    }
 
    func openQuickLook(_ doc: JobDocument) {
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
 
    func revealInFinder(_ doc: JobDocument) {
        if let fileURL = doc.fileURL {
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        }
    }
}
 /**
A clickable skill chip in the job details.
*/

struct SkillChipView: View {
   @EnvironmentObject var jobStore: JobStore
   let skill: DesiredSkill
   @State private var isSelected: Bool = false

   var body: some View {
       Text(skill.name)
           .foregroundColor(isSelected ? .white : .primary)
           .padding(.horizontal, 8)
           .padding(.vertical, 4)
           .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
           .cornerRadius(8)
           .onTapGesture {
               isSelected.toggle()
           }
           .contextMenu {
               Button("Add Alias") {
                   jobStore.beginEditAlias(for: skill.name)
               }
               Button("Edit Alias") {
                   jobStore.beginEditAlias(for: skill.name)
               }
               Button("Delete Alias", role: .destructive) {
                   var cleared = skill
                   cleared.aliases = []
                   jobStore.updateSkill(cleared)
               }
               Divider()
               Button("Add New Skill") {
                   jobStore.isAddingNewSkill = true
               }
               Button("Delete Skill", role: .destructive) {
                   jobStore.deleteSkill(skill)
               }
           }
   }
}


//
//  AddJobView+EditJobView.swift
//  AppleJob
//
//  Created by Roger Lin on 1/26/25.
//
 
//
//  AddJobView+EditJobView+NewLocationView.swift
//  AppleJob
//
//  Created by Roger Lin on 1/26/25.
//
 
 //
//  AddJobView+EditJobView.swift
//  AppleJob
//
//  Created by Roger Lin on 1/26/25.
//
 
//
//  AddJobView+EditJobView+NewLocationView.swift
//  AppleJob
//
//  Created by Roger Lin on 1/26/25.
//
 
 
 
 
/**
 A sheet to create a new job entry. If the user came from a custom URL,
 we can pre-populate the fields from `jobStore.incomingJobData`.
 */
/*****************************************************
 *               ADD JOB VIEW
 *****************************************************/
 
/// A sheet to create a new job entry. If the user came from a custom URL,
/// we can pre-populate the fields from `jobStore.incomingJobData`.
struct AddJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var isPresented: Bool
 
    @StateObject private var viewModel: JobViewModel = JobViewModel()
    @State private var importedDocuments: [JobDocument] = []
    @State private var locations: [String] = CityCoordinateDictionary.keys.sorted()
    @State private var showAddLocationSheet = false
    @State private var isImporting = false
    @State private var quickLookURL: URL? = nil
 
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
 
    var body: some View {
        // ZStack places our pastel gradient behind the main content,
        // letting text fields and text editors show partial translucency.
        ZStack {
            // This gradient is "hidden" behind our text fields / text editors.
            PastelGradientBackground()
 
            // The main container with a lightly opaque window color background.
            VStack {
                Text("Add New Job")
                    .font(.title2)
                    .padding()
 
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                   // Company Name
                        sectionHeader("JOB DETAILS")
 
                        // COMPANY NAME
                   Text("Company Name").font(.headline)
                        TextField("Company Name", text: $viewModel.companyName)
                            // Thin material plus partial opacity
                            .background(Material.ultraThin.opacity(0.5))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(.tertiary, lineWidth: 0.5))
                            .controlSize(.large)
                            .onChange(of: viewModel.companyName) { _, _ in
                                viewModel.validateInputs()
                            }
 
                        // JOB TITLE
                   Text("Job Title").font(.headline)
                        TextField("Job Title", text: $viewModel.jobTitle)
                            .background(Material.ultraThin.opacity(0.5))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(.tertiary, lineWidth: 0.5))
                            .controlSize(.large)
                            .onChange(of: viewModel.jobTitle) { _, _ in
                                viewModel.validateInputs()
                            }
 
                        sectionHeader("APPLICATION DETAILS")
 
                        // LINK TO JOB
                        TextField("Link to Job", text: $viewModel.linkToJob)
                            .background(Material.ultraThin.opacity(0.5))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(.tertiary, lineWidth: 0.5))
                            .controlSize(.large)
 
                        // SALARY
                        TextField(
                            "Salary",
                            value: $viewModel.salaryDouble,
                            format: .currency(code: "USD")
                        )
                        .background(Material.ultraThin.opacity(0.5))
                        .cornerRadius(5)
                        .overlay(RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(.tertiary, lineWidth: 0.5))
                        .controlSize(.large)
 
                   // Status
                        // LOCATION PICKER
                   Text("Status").font(.headline)
                   Picker("Status", selection: $viewModel.status) {
                       ForEach(JobStatus.allCases, id: \.self) { st in
                           Text(st.rawValue).tag(st)
                        Picker("Location", selection: $viewModel.location) {
                            ForEach(locations, id: \.self) { location in
                                Text(location).tag(location)
                            }
                            Text("Add New Location").tag("Add New Location")
                        }
                        .pickerStyle(DefaultPickerStyle())

                   // Job Type
                   Text("Job Type").font(.headline)
                   Picker("Job Type", selection: $viewModel.jobType) {
                       ForEach(JobType.allCases, id: \.self) { jt in
                        .onChange(of: viewModel.location) { _, newValue in
                            if newValue == "Add New Location" {
                                viewModel.location = ""
                           Text(jt.rawValue).tag(jt)
                                showAddLocationSheet = true
                            }
                        }
                   .pickerStyle(.segmented)
 
                        // DATE PICKER
                   Text("Date of Application").font(.headline)
                        DatePicker("Application Date", selection: $viewModel.dateOfApplication, displayedComponents: .date)
                       .labelsHidden()
                       
                                               // DATE PICKER
                   Text("Application Deadline").font(.headline)
                        DatePicker("Application Deadline", selection: $viewModel.applicationDeadline, displayedComponents: .date)
                       .labelsHidden()
 
                   // Location
                   Text("Location").font(.headline)
                   Picker("Location", selection: $viewModel.location) {
                       ForEach(locations, id: \.self) { loc in
                           Text(loc).tag(loc)
                            }
                        }
                   .labelsHidden()
 
    // Salary
                   Text("Salary").font(.headline)
                   TextField("Salary", text: $viewModel.salaryString)
                       .textFieldStyle(.roundedBorder)
                       .onChange(of: viewModel.salaryString) {_, newVal in
                           viewModel.updateSalary(fromString: newVal)
                       }

 
                        // DOCUMENT PREVIEW SCROLLER
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
                                    }
                                }
                            }
                        }
   
   // BUTTON TO IMPORT DOCUMENTS
                        Button("Upload Documents") {
                            isImporting = true
                        }
 
                        // JOB DESCRIPTION
                        sectionHeader("JOB DESCRIPTION")
                        TextEditor(text: $viewModel.jobDescription)
                            .frame(minHeight: 200)
                            .background(Material.ultraThin.opacity(0.5))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(.tertiary, lineWidth: 0.5))
                            .scrollContentBackground(.hidden)
                            .onChange(of: viewModel.jobDescription) { newValue in
                                // 1) Find any line that starts with "http"
                                //    If `linkToJob` is empty, set it to that link.
                                if viewModel.linkToJob.isEmpty {
                                    let lines = newValue.components(separatedBy: .newlines)
                                    for line in lines {
                                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                                        // Check case-insensitive if line starts with "http"
                                        if trimmed.lowercased().hasPrefix("http") {
                                            viewModel.linkToJob = trimmed
                                            break
                                        }
                                    }
                                }
                                // 2) Check existing job applications for a matching company name
                                //    If `companyName` is empty, fill it with the first found match.
                                if viewModel.companyName.isEmpty {
                                    for existingApp in jobStore.jobApplications {
                                        if newValue.localizedCaseInsensitiveContains(existingApp.companyName) {
                                            viewModel.companyName = existingApp.companyName
                                            break
                                        }
                                    }
                                }
                            }
 
                        // COVER LETTER
                        sectionHeader("COVER LETTER")
                        TextEditor(text: $viewModel.coverLetter)
                            .frame(minHeight: 200)
                            .background(Material.ultraThin.opacity(0.5))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(.tertiary, lineWidth: 0.5))
                            .scrollContentBackground(.hidden)
 
                        // NOTES
                        sectionHeader("NOTES")
                        TextEditor(text: $viewModel.notes)
                            .frame(minHeight: 200)
                            .background(Material.ultraThin.opacity(0.5))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(.tertiary, lineWidth: 0.5))
                            .scrollContentBackground(.hidden)
 
                    } // End of VStack
                    .padding()
                    // Keep the same color for the scroll area background
                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
                } // End of ScrollView
 
                // SAVE/CANCEL BUTTONS
                HStack {
                    Button(role: .cancel) {
                        isPresented = false
                    } label: {
                        Text("Cancel")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
 
                    Spacer()
 
                    Button("Save") {
                        viewModel.validateInputs()
                        if viewModel.isInputValid {
                            let finalDocs = storeImportedDocuments()
                            docStore.mergeDocuments(finalDocs)
                            viewModel.addJob(to: jobStore, documents: finalDocs)
                            isPresented = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(!viewModel.isInputValid)
                }
                .padding()
            }
        }
        // Frame & background for the entire AddJobView content
        .frame(minWidth: 500, minHeight: 600)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
        // File importer for documents
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
        // Sheet to add a new location
        .sheet(isPresented: $showAddLocationSheet) {
            NewLocationView(
                locations: $locations,
                selectedLocation: $viewModel.location,
                isPresented: $showAddLocationSheet
            )
        }
        // Quick Look preview for documents
        .quickLookPreview($quickLookURL)
        // On appear, fill fields if we have incomingJobData
        .onAppear {
            print("AddJobView: onAppear called")
            if let incoming = jobStore.incomingJobData {
                print("AddJobView: incomingJobData is not nil: \(incoming)")
                if viewModel.jobTitle.isEmpty {
                    viewModel.jobTitle = incoming["jobTitle"] as? String ?? ""
                }
                if viewModel.linkToJob.isEmpty {
                    viewModel.linkToJob = incoming["url"] as? String ?? ""
                }
                if viewModel.jobDescription.isEmpty {
                    viewModel.jobDescription = incoming["jobDescription"] as? String ?? ""
                }
                // Clear incoming data after use
                jobStore.incomingJobData = nil
            } else {
                print("AddJobView: incomingJobData is nil")
            }
        }
    }
 
    // Helper method for header text
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .textCase(.uppercase)
    }
 
    // Storing imported documents in the application's own directory
    private func storeImportedDocuments() -> [JobDocument] {
        var savedDocs: [JobDocument] = []
        for d in importedDocuments {
            if let originalURL = d.fileURL,
               let savedURL = DocumentStore.saveDocumentToAppSupport(
                   originalURL: originalURL,
                   fileName: d.fileName
               ) {
                let newDoc = JobDocument(
                    fileName: d.fileName,
                    fileData: d.fileData,
                    fileURL: savedURL,
                    creation: d.creationDate,
                    lastModified: d.lastModifiedDate
                )
                savedDocs.append(newDoc)
            } else {
                savedDocs.append(d)
            }
        }
        return savedDocs
    }
 
    // For Quick Look
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
 
    // Cleans up displayed file name
    private func cleanFileName(_ filename: String) -> String {
        var cleanedName = filename
        cleanedName = cleanedName.replacingOccurrences(of: "_", with: " ")
        cleanedName = cleanedName.replacingOccurrences(of: "-", with: " ")
        cleanedName = cleanedName.replacingOccurrences(of: "\\d", with: "", options: .regularExpression)
        let toRemove = ["Roger Lin", "Position", "2024", "Cover Letter"]
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
 
 
/// A view displaying a pastel gradient background.
/// We use this as a "hidden layer" behind text fields/editors to allow
/// partial translucency to show softly through.
struct PastelGradientBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.94, green: 0.85, blue: 1.0),  // Soft Lavender
                Color(red: 0.88, green: 0.95, blue: 0.90), // Mint Green
                Color(red: 1.0,  green: 0.94, blue: 0.9)    // Pale Yellow
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .edgesIgnoringSafeArea(.all)
    }
}
 
    // Desired Skills
                   Text("Desired Skills").font(.headline)
                   SkillComboBoxField(
                       text: $viewModel.desiredSkillText,
                       suggestions: $viewModel.availableSkillSuggestions
                   ) {
                       // When user presses return, call addSelectedSkill
                       viewModel.addSelectedSkill(skillName: viewModel.desiredSkillText, jobStore: jobStore)
                   }
                   ScrollView(.horizontal, showsIndicators: false) {
                       HStack {
                           ForEach(viewModel.selectedDesiredSkills, id: \.self) { skillName in
                               SkillTag(
                                   skillName: skillName,
                                   removeAction: {
                                       viewModel.removeSelectedSkill(skillName: skillName)
                                   }
                               )
                           }
                       }
                   }
                   .padding(.vertical, 4)

                   Divider()
                   HStack {
                       Button("Cancel") {
                           isPresented = false
                       }
                       Spacer()
                       Button("Add Job") {
                           if viewModel.isInputValid {
                               viewModel.addJob(to: jobStore, documents: importedDocuments)
                               isPresented = false
                           }
                       }
                       .disabled(!viewModel.isInputValid)
                   }
               }
               .padding()
           }
       }
       .frame(minWidth: 500, minHeight: 700)
       .onAppear {
           viewModel.updateSkillSuggestions(availableSkills: jobStore.availableSkills)
       }
   }
}



// MARK: - TranslucentGradientBackground ViewModifier
struct TranslucentGradientBackground: ViewModifier {
   func body(content: Content) -> some View {
       content
           .background(
               ZStack {
                   LinearGradient(
                       colors: [
                           Color.pink.opacity(0.3),
                           Color.blue.opacity(0.3)
                       ],
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing
                   )
                   .blur(radius: 5)
                   .background(.ultraThinMaterial)
               }
               .clipShape(RoundedRectangle(cornerRadius: 5))
           )
   }
}

struct WindowAccessor: NSViewRepresentable {
   @State var window: NSWindow? = nil
   let configure: (NSWindow?) -> Void

   init(configure: @escaping (NSWindow?) -> Void) {
       self.configure = configure
   }

   func makeNSView(context: Context) -> NSView {
       let view = NSView()
       DispatchQueue.main.async {
           self.window = view.window
           configure(window)
       }
       return view
   }

   func updateNSView(_ nsView: NSView, context: Context) {
       configure(window)
   }
}

