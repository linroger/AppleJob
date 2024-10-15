// --------------------------------------------------
// MARK: - AddJobView
// --------------------------------------------------
struct AddJobView: View {
   @EnvironmentObject var jobStore: JobStore
   @EnvironmentObject var docStore: DocumentStore
   @Binding var isPresented: Bool

   @StateObject private var viewModel: JobViewModel = JobViewModel()
   @State private var importedDocuments: [JobDocument] = []
   @State private var locations: [String] = CityCoordinateDictionary.keys.sorted()

   var body: some View {
       VStack {
           Text("Add New Job")
               .font(.title2)
               .padding()
           ScrollView {
               VStack(alignment: .leading, spacing: 12) {
                   // Company Name
                   Text("Company Name").font(.headline)
                   TextField("Company Name", text: $viewModel.companyName)
                       .textFieldStyle(.roundedBorder)
                       .onChange(of: viewModel.companyName) {_, _ in viewModel.validateInputs() }

                   // Job Title
                   Text("Job Title").font(.headline)
                   TextField("Job Title", text: $viewModel.jobTitle)
                       .textFieldStyle(.roundedBorder)
                       .onChange(of: viewModel.jobTitle) { _,_ in viewModel.validateInputs() }

                   // Status
                   Text("Status").font(.headline)
                   Picker("Status", selection: $viewModel.status) {
                       ForEach(JobStatus.allCases, id: \.self) { st in
                           Text(st.rawValue).tag(st)
                       }
                   }
                   .pickerStyle(.segmented)

                   // Job Type
                   Text("Job Type").font(.headline)
                   Picker("Job Type", selection: $viewModel.jobType) {
                       ForEach(JobType.allCases, id: \.self) { jt in
                           Text(jt.rawValue).tag(jt)
                       }
                   }
                   .pickerStyle(.segmented)

                   // Date
                   Text("Date of Application").font(.headline)
                   DatePicker("Date", selection: $viewModel.dateOfApplication, displayedComponents: .date)
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

                   // Link
                   Text("Link to Job").font(.headline)
                   TextField("Link to Job", text: $viewModel.linkToJob)
                       .textFieldStyle(.roundedBorder)

                   // Job Description
                   HStack {
                       Text("Job Description").font(.headline)

                       // NEW: Paste Button
                       Button("Paste") {
                           if let clipboardText = NSPasteboard.general.string(forType: .string) {
                               viewModel.jobDescription = clipboardText
                           }
                       }
                       .help("Paste from Clipboard")
                   }
                   TextEditor(text: $viewModel.jobDescription)
                       .frame(height: 100)
                       .border(Color.gray, width: 1)

                   // Cover Letter
                   Text("Cover Letter").font(.headline)
                   TextEditor(text: $viewModel.coverLetter)
                       .frame(height: 100)
                       .border(Color.gray, width: 1)

                   // Notes
                   Text("Notes").font(.headline)
                   TextEditor(text: $viewModel.notes)
                       .frame(height: 60)
                       .border(Color.gray, width: 1)

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

