        // MARK: - EditJobView
        struct EditJobView: View {
            @EnvironmentObject var jobStore: JobStore
            @EnvironmentObject var docStore: DocumentStore
            @Binding var isPresented: Bool
            @StateObject private var viewModel: JobViewModel
            @State private var importedDocuments: [JobDocument] = []
            @State private var isImporting = false
            @State private var locations: [String] = CityCoordinateDictionary.keys.sorted()
            @State private var showAddLocationSheet = false
            @State private var quickLookURL: URL? = nil

            init(isPresented: Binding<Bool>, job: JobApplication) {
                self._isPresented = isPresented
                // Initialize with existing job
                self._viewModel = StateObject(wrappedValue: JobViewModel(job: job))
                self._importedDocuments = State(initialValue: job.documents)
            }

            var body: some View {
                ZStack { // ADD: ZStack to place background behind
                    PastelGradientBackground() // ADD: Gradient background
                    VStack {
                        Text("Edit Job")
                            .font(.title2)
                            .padding()
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                sectionHeader("JOB DETAILS")
                                TextField("Company Name", text: $viewModel.companyName)
                                     .background(Material.thin.opacity(0.75)).cornerRadius(5).overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.tertiary, lineWidth: 0.5))
                                    .controlSize(.large)
                                    .onChange(of: viewModel.companyName) {  _, _ in
                                        viewModel.validateInputs()
                                    }
                                TextField("Job Title", text: $viewModel.jobTitle)
                                     .background(Material.thin.opacity(0.75)).cornerRadius(5).overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.tertiary, lineWidth: 0.5))
                                    .controlSize(.large)
                                    .onChange(of: viewModel.jobTitle) {  _, _ in
                                        viewModel.validateInputs()
                                    }

                                sectionHeader("APPLICATION DETAILS")
                                TextField("Link to Job", text: $viewModel.linkToJob)
                                     .background(Material.thin.opacity(0.75)).cornerRadius(5).overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.tertiary, lineWidth: 0.5))
                                    .controlSize(.large)
                                
                                
                                TextField(
                                    "Salary",
                                    value: $viewModel.salaryDouble,
                                    format: .currency(code: Locale.current.currency?.identifier ?? "USD")
                                )
                                .background(Material.thin.opacity(0.75))
                                .cornerRadius(5)
                                .overlay(RoundedRectangle(cornerRadius:5).strokeBorder(.tertiary, lineWidth: 0.5))
                                .controlSize(.large)
                               
                            
                                Picker("Status", selection: $viewModel.status) {
                                    ForEach(JobStatus.allCases, id: \.self) { status in
                                        Text(status.rawValue).tag(status)
                                    }
                                }
                                
                                DatePicker("Application Date", selection: $viewModel.dateOfApplication, displayedComponents: .date)

                                
                                
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


                                sectionHeader("DOCUMENTS")
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
                                                    .contextMenu {
                                                        Button("Reveal in Finder") {
                                                            revealInFinder(doc)
                                                        }
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
                                                        Button("Delete Document") {
                                                            if let idx = importedDocuments.firstIndex(where: { $0.id == doc.id }) {
                                                                importedDocuments.remove(at: idx)
                                                                docStore.deleteDocument(doc)
                                                            }
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
                                                                .frame (maxWidth: .infinity)
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
                                    // Merge newly imported docs
                                    var savedDocs: [JobDocument] = []
                                    for d in importedDocuments {
                                        if let originalURL = d.fileURL,
                                           let savedURL = DocumentStore.saveDocumentToAppSupport(originalURL: originalURL, fileName: d.fileName) {
                                            let newDoc = JobDocument(
                                                fileName: d.fileName,
                                                fileData: d.fileData,
                                                fileURL: savedURL,
                                                creation: d.creationDate,
                                                lastModified: d.lastModifiedDate,
                                                fileSize: d.fileSize,
                                                wordCount: d.wordCount,
                                                categoryID: d.categoryID
                                            )
                                            savedDocs.append(newDoc)
                                        } else {
                                            savedDocs.append(d)
                                        }
                                    }
                                    docStore.mergeDocuments(savedDocs)
                                    let updatedJob = JobApplication(
                                        id: viewModel.companyName == jobStore.selectedJob?.companyName ? jobStore.selectedJob?.id ?? UUID() : UUID(),
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
                                        documents: savedDocs,
                                        isFavorite: jobStore.selectedJob?.isFavorite ?? false
                                    )
                                    jobStore.editJob(with: updatedJob)
                                    isPresented = false
                                }
                            } label: {
                                Text("Save")
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
                    locations = CityCoordinateDictionary.keys.sorted()
                }
            }
        }
