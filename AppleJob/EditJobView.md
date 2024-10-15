// --------------------------------------------------
// MARK: - EditJobView
// --------------------------------------------------
struct EditJobView: View {
   @EnvironmentObject var jobStore: JobStore
   @EnvironmentObject var docStore: DocumentStore
   @Binding var isPresented: Bool

   @StateObject var viewModel: JobViewModel
   @State private var importedDocuments: [JobDocument] = []
   @State private var locations: [String] = CityCoordinateDictionary.keys.sorted()

   init(isPresented: Binding<Bool>, job: JobApplication) {
       self._isPresented = isPresented
       let vm = JobViewModel(job: job, availableSkills: [])
       _viewModel = StateObject(wrappedValue: vm)
   }

   var body: some View {
       VStack {
           Text("Edit Job")
               .font(.title2)
               .padding()
           ScrollView {
               VStack(alignment: .leading, spacing: 12) {
                   // Company
                   Text("Company Name").font(.headline)
                   TextField("Company Name", text: $viewModel.companyName)
                       .textFieldStyle(.roundedBorder)
                       .onChange(of: viewModel.companyName) {_, _ in
                           viewModel.validateInputs()
                       }

                   // Title
                   Text("Job Title").font(.headline)
                   TextField("Job Title", text: $viewModel.jobTitle)
                       .textFieldStyle(.roundedBorder)
                       .onChange(of: viewModel.jobTitle) {_, _ in
                           viewModel.validateInputs()
                       }

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
                   Text("Job Description").font(.headline)
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
                       Button("Save") {
                           if let original = jobStore.jobApplications.first(where: { $0.id == viewModelUpdateID }) {
                               viewModel.updateJob(with: original, in: jobStore, documents: importedDocuments)
                               isPresented = false
                           } else {
                               // fallback
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
           // Refresh the skill suggestions from the store
           viewModel.updateSkillSuggestions(availableSkills: jobStore.availableSkills)
       }
   }

   private var viewModelUpdateID: UUID? {
       jobStore.selectedJobIDs.first
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
           .textFieldStyle(.roundedBorder)

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
           .buttonStyle(.plain)
       }
       .padding(.horizontal, 8)
       .padding(.vertical, 4)
       .background(Color.gray.opacity(0.2))
       .cornerRadius(8)
   }
}



struct TranslucentTextFieldStyle: ViewModifier {
   func body(content: Content) -> some View {
       content
           .background(
               ZStack {
                   PastelGradientBackground()
                   Color.clear.background(Material.ultraThin)
               }
               .opacity(0.5)
           )
           .overlay(RoundedRectangle(cornerRadius: 5)
               .strokeBorder(.tertiary, lineWidth: 0.5))
   }
}

struct TranslucentTextEditorStyle: ViewModifier {
   func body(content: Content) -> some View {
       content
           .padding(6)
           .background(
               ZStack {
                   PastelGradientBackground()
                   Color.clear.background(Material.ultraThin)
               }
               .opacity(0.5)
               .clipShape(RoundedRectangle(cornerRadius: 5))
           )
           .overlay(RoundedRectangle(cornerRadius: 5)
               .strokeBorder(.tertiary, lineWidth: 0.5))

   }
}


/// A view displaying a pastel gradient background that we only use
/// behind individual TextFields and TextEditors for a frosted effect.
struct PastelGradientBackground: View {
   var body: some View {
       LinearGradient(
           gradient: Gradient(colors: [
               Color(red: 0.94, green: 0.85, blue: 1.0).opacity(0.7),  // Soft Lavender
               Color(red: 0.88, green: 0.95, blue: 0.90).opacity(0.7), // Mint Green
               Color(red: 1.0,  green: 0.94, blue: 0.9).opacity(0.7)    // Pale Yellow
           ]),
           startPoint: .topLeading,
           endPoint: .bottomTrailing
       )
   }
}
