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
        ZStack { // ADD: ZStack to place background behind
            PastelGradientBackground() // ADD: Gradient background
            VStack {
                Text("Add New Job")
                    .font(.title2)
                    .padding()
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("JOB DETAILS")
                        TextField("Company Name", text: $viewModel.companyName)
                             .background(Material.thin.opacity(0.75)).cornerRadius(5).overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.tertiary, lineWidth: 0.5))
                            .controlSize(.large)
                            .onChange(of: viewModel.companyName) { _, _ in
                                viewModel.validateInputs()
                            }
                        TextField("Job Title", text: $viewModel.jobTitle)
                             .background(Material.thin.opacity(0.75)).cornerRadius(5).overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.tertiary, lineWidth: 0.5))
                            .controlSize(.large)
                            .onChange(of: viewModel.jobTitle) { _, _ in
                                viewModel.validateInputs()
                            }

                        sectionHeader("APPLICATION DETAILS")
                        TextField("Link to Job", text: $viewModel.linkToJob)
                             .background(Material.thin.opacity(0.75)).cornerRadius(5).overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.tertiary, lineWidth: 0.5))
                            .controlSize(.large)

                        // Salary TextField with .currency formatting
                        TextField(
                            "Salary",
                            value: $viewModel.salaryDouble, // Bind to a Double value
                            format: .currency(code: "USD") // Format salary as currency
                        )
                         .background(Material.thin.opacity(0.75))
                        .cornerRadius(5)
                        .overlay(RoundedRectangle(cornerRadius:5).strokeBorder(.tertiary, lineWidth: 0.5))
                        .controlSize(.large)


                        Picker("Location", selection: $viewModel.location) {
                            // Display all available locations
                            ForEach(locations, id: \.self) { location in
                                Text(location).tag(location) // Use `tag` to bind values
                            }
                            // Special option for adding a new location
                            Text("Add New Location").tag("Add New Location")
                        }
                        .pickerStyle(DefaultPickerStyle())
                        .onChange(of: viewModel.location) { _, newValue in
                            // When "Add New Location" is selected, reset location and open the sheet
                            if newValue == "Add New Location" {
                                viewModel.location = "" // Reset the selection
                                showAddLocationSheet = true // Trigger the sheet to add a new location
                            }
                        }

                        DatePicker("Application Date", selection: $viewModel.dateOfApplication, displayedComponents: .date)

                        Picker("Status", selection: $viewModel.status) {
                          ForEach(JobStatus.allCases, id: \.self) { status in
                              Text(status.rawValue).tag(status)
                          }
                      }

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
                                    }
                                }
                            }
                        }
                        Button("Upload Documents") {
                            isImporting = true
                        }

                        sectionHeader("JOB DESCRIPTION")
                        TextEditor(text: $viewModel.jobDescription)
                            .background(Material.thin.opacity(0.75)).cornerRadius(5)
                            .controlSize(.large)
                            .font(.body)
                            .lineSpacing(5)
                            .padding ( )
                            .frame(minHeight: 200)
                            .frame(maxWidth: .infinity)
                            .scrollContentBackground (.hidden)

                        sectionHeader("COVER LETTER")
                        TextEditor(text: $viewModel.coverLetter)
                            .background(Material.thin.opacity(0.75)).cornerRadius(5)
                            .controlSize(.large)
                            .font(.body)
                            .lineSpacing(5)
                            .padding ( )
                            .frame(minHeight: 200)
                            .frame (maxWidth: .infinity)
                            .scrollContentBackground (.hidden)

                        sectionHeader("NOTES")
                        TextEditor(text: $viewModel.notes)
                            .background(Material.thin.opacity(0.75)).cornerRadius(5)
                            .controlSize(.large)
                            .font(.body)
                            .lineSpacing(5)
                            .padding ( )
                            .frame(minHeight: 200)
                            .frame (maxWidth: .infinity)
                            .scrollContentBackground (.hidden)
                    }
                    .padding()
                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
                }
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
        .frame(minWidth: 500, minHeight: 600)
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
        .sheet(isPresented: $showAddLocationSheet) {
            NewLocationView(
                locations: $locations,
                selectedLocation: $viewModel.location,
                isPresented: $showAddLocationSheet
            )
        }
        .quickLookPreview($quickLookURL)
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
        // Clear incoming data after use to prevent re-population on subsequent appearances
        jobStore.incomingJobData = nil
    } else {
        print("AddJobView: incomingJobData is nil")
    }
}
}

private func sectionHeader(_ title: String) -> some View {
Text(title)
    .font(.headline)
    .textCase(.uppercase)
        }

private func storeImportedDocuments() -> [JobDocument] {
var savedDocs: [JobDocument] = []
for d in importedDocuments {

    if let originalURL = d.fileURL,
       let savedURL = DocumentStore.saveDocumentToAppSupport(originalURL: originalURL, fileName: d.fileName) {
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
cleanedName = cleanedName.trimmingCharacters(in: .whitespaces)
return cleanedName
    }
}


struct PastelGradientBackground: View {
    var body: some View {
        LinearGradient(gradient: Gradient(colors: [
            Color(red: 0.94, green: 0.85, blue: 1.0),    // Soft Lavender
            Color(red: 0.88, green: 0.95, blue: 0.90),    // Mint Green
            Color(red: 1.0, green: 0.94, blue: 0.9)     // Pale Yellow
        ]), startPoint: .topLeading, endPoint: .bottomTrailing)
        .edgesIgnoringSafeArea(.all) // Make it full screen
    }
}

// MARK: - NewLocationView
// -----------------------------------------------------
/**
 A small sheet to add a brand-new location with name, latitude, and longitude.
 This view is used to create a new job entry.
 If the Safari extension passes data, we can pre-populate the fields here in the ViewModel
 or by referencing jobStore.incomingJobData.
 */
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
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .controlSize(.large)
            TextField("Latitude", text: $latitude)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .controlSize(.large)
            TextField("Longitude", text: $longitude)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .controlSize(.large)
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                .tint(.red)
                Spacer()
                Button("Add") {
                    guard let lat = Double(latitude),
                          let lon = Double(longitude),
                          !newLocationName.isEmpty else { return }
                    if !locations.contains(newLocationName) {
                        locations.append(newLocationName)
                    }
                    selectedLocation = newLocationName
                    let newCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    CityCoordinateDictionary[newLocationName] = newCoordinate
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
        .padding()
        .frame(width: 300, height: 200)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
    }
}


// MARK: - EditJobView
// MARK: - EditJobView
struct EditJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var isPresented: Bool
    @StateObject private var viewModel: JobViewModel
    @State private var importedDocuments: [JobDocument] = []
    @State private var isImporting = false
    @State private var locations: [String] = []
    @State private var showAddLocationSheet = false
    @State private var quickLookURL: URL? = nil

    init(isPresented: Binding<Bool>, job: JobApplication) {
        self._isPresented = isPresented
        self._viewModel = StateObject(wrappedValue: JobViewModel(job: job))
        self._importedDocuments = State(initialValue: job.documents)
    }

    var body: some View {
        ZStack {
            GradientBackground() // Add the gradient background
                .ignoresSafeArea()

            VStack {
                Text("Edit Job")
                    .font(.title2)
                    .padding()

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Job Details")
                        TextField("Company Name", text: $viewModel.companyName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: viewModel.companyName) { _, _ in
                                viewModel.validateInputs()
                            }
                        TextField("Job Title", text: $viewModel.jobTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: viewModel.jobTitle) { _, _ in
                                viewModel.validateInputs()
                            }

                        sectionHeader("Application Details")
                        TextField("Link to Job", text: $viewModel.linkToJob)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField(
                            "Salary",
                            value: $viewModel.salaryDouble,
                            format: .currency(code: Locale.current.currency?.identifier ?? "USD")
                        )
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        Picker("Status", selection: $viewModel.status) {
                            ForEach(JobStatus.allCases, id: \.self) { status in
                                Text(status.rawValue).tag(status)
                            }
                        }
                        DatePicker("Application Date", selection: $viewModel.dateOfApplication, displayedComponents: .date)
                        Picker("Location", selection: $viewModel.location) {
                            ForEach(locations, id: \.self) { loc in
                                Text(loc).tag(loc)
                            }
                            Text("Add New Location").tag("Add New Location")
                        }
                        .onChange(of: viewModel.location) { _, newValue in
                            if newValue == "Add New Location" {
                                viewModel.location = ""
                                showAddLocationSheet = true
                            }
                        }

                        sectionHeader("Documents")
                        if !importedDocuments.isEmpty {
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(importedDocuments, id: \.id) { doc in
                                        documentView(for: doc)
                                    }
                                }
                            }
                        }
                        Button("Upload Documents") {
                            isImporting = true
                        }

                        sectionHeader("Job Description")
                        TextEditor(text: $viewModel.jobDescription)
                            .frame(minHeight: 100)
                            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.secondary, lineWidth: 0.5))

                        sectionHeader("Cover Letter")
                        TextEditor(text: $viewModel.coverLetter)
                            .frame(minHeight: 100)
                            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.secondary, lineWidth: 0.5))

                        sectionHeader("Notes")
                        TextEditor(text: $viewModel.notes)
                            .frame(minHeight: 100)
                            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.secondary, lineWidth: 0.5))
                    }
                    .padding()
                }

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
                        saveJob()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(!viewModel.isInputValid)
                }
                .padding()
            }
            .frame(minWidth: 500, minHeight: 600)
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf, .plainText, .rtf, .image],
            allowsMultipleSelection: true
        ) { handleImportedFiles(result: $0) }
        .sheet(isPresented: $showAddLocationSheet) {
            NewLocationView(
                locations: $locations,
                selectedLocation: $viewModel.location,
                isPresented: $showAddLocationSheet
            )
        }
        .onAppear {
            loadLocations()
        }
        .quickLookPreview($quickLookURL)
    }

    private func saveJob() {
        viewModel.validateInputs()
        guard viewModel.isInputValid else { return }

        let updatedJob = JobApplication(
            id: jobStore.selectedJob?.id ?? UUID(),
            companyName: viewModel.companyName,
            jobTitle: viewModel.jobTitle,
            status: viewModel.status,
            dateOfApplication: viewModel.dateOfApplication,
            location: viewModel.location,
            linkToJobString: viewModel.linkToJob.isEmpty ? nil : viewModel.linkToJob,
            salary: viewModel.salaryDouble,
            jobDescription: viewModel.jobDescription,
            coverLetter: viewModel.coverLetter,
            notes: viewModel.notes.isEmpty ? nil : viewModel.notes,
            documents: importedDocuments,
            isFavorite: jobStore.selectedJob?.isFavorite ?? false
        )
        jobStore.editJob(with: updatedJob)
        isPresented = false
    }

    private func handleImportedFiles(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                guard let data = try? Data(contentsOf: url) else { continue }
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
        case .failure(let error):
            print("Failed to import files: \(error)")
        }
    }

    private func loadLocations() {
        locations = Array(Set(jobStore.jobApplications.map { $0.location })).sorted()
    }

    private func documentView(for doc: JobDocument) -> some View {
        HStack {
            Image(systemName: "doc.text")
                .foregroundColor(.primary)
            Text(cleanFileName(doc.fileName))
                .gradientForeground(colors: [.blue, .purple])
        }
        .buttonStyle(.bordered)
        .contextMenu {
            Button("Reveal in Finder") {
                if let fileURL = doc.fileURL {
                    NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                }
            }
            Button("Delete Document") {
                if let idx = importedDocuments.firstIndex(where: { $0.id == doc.id }) {
                    importedDocuments.remove(at: idx)
                }
            }
        }
    }

    private func cleanFileName(_ filename: String) -> String {
        filename.replacingOccurrences(of: "_", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .textCase(.uppercase)
            .padding(.bottom, 5)
    }
}

struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [.purple.opacity(0.4), .blue.opacity(0.4)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
