
Okay, let's address each error systematically as planned.

**1. Error Parsing and Source Analysis:**

Here's a breakdown of the errors and their likely causes based on the file path and line numbers:

*   **/Users/rogerlin/Downloads/Files/AppleJob/AppleJob/AppleJob.swift:1993:56 Cannot find 'doc' in scope, 1996:65 Cannot find 'doc' in scope, 2000:73 Cannot find 'doc' in scope:**
    *   **Source:** `JobDetailView`, within the `ForEach(job.documents)` loop, inside `Button` and `contextMenu` closures.
    *   **Analysis:** The variable `doc` from the `ForEach` loop is not being correctly captured or accessed inside the nested closures of the `Button` and `contextMenu`.

*   **/Users/rogerlin/Downloads/Files/AppleJob/AppleJob/AppleJob.swift:2038:9 Expected declaration:**
    *   **Source:** Line after the closing brace of `JobDetailView`.
    *   **Analysis:** Likely a syntax error immediately after the `JobDetailView` struct definition.  Often caused by a missing closing brace `}` or extra code where it shouldn't be.

*   **/Users/rogerlin/Downloads/Files/AppleJob/AppleJob/AppleJob.swift:2068:28 Cannot find 'windowRef' in scope, 2069:27 Cannot find 'job' in scope, 2069:46 Cannot find 'job' in scope:**
    *   **Source:** `DocumentsMainView`, within `.onAppear` and `.onChange(of: docStore.selectedDocument)` modifiers.
    *   **Analysis:** `windowRef` and `job` (likely a typo for `doc`) are state variables in `DocumentsMainView` but are not being captured correctly within the closures of `.onAppear` and `.onChange`.

*   **/Users/rogerlin/Downloads/Files/AppleJob/AppleJob/AppleJob.swift:2090:13 Cannot find 'quickLookURL' in scope, 2095:17 Cannot find 'quickLookURL' in scope:**
    *   **Source:** `DocumentsMainView`, within `.onAppear` and `.onChange(of: docStore.selectedDocument)` modifiers.
    *   **Analysis:**  `quickLookURL` state variable in `DocumentsMainView` not captured in `.onAppear` and `.onChange` closures.

*   **/Users/rogerlin/Downloads/Files/AppleJob/AppleJob/AppleJob.swift:2327:13 Cannot find 'NewLocationView' in scope:**
    *   **Source:** `AddJobView`, attempting to use `NewLocationView` in a `.sheet` modifier.
    *   **Analysis:**  SwiftUI might not be able to find the `NewLocationView` struct definition at this point in the file parsing. Scope or declaration order issue could be at play.

*   **/Users/rogerlin/Downloads/Files/AppleJob/AppleJob/AppleJob.swift:3679:9 The compiler is unable to type-check this expression in reasonable time; try breaking up the expression into distinct sub-expressions:**
    *   **Source:** `EnhancedStatsView`, line 3679.
    *   **Analysis:**  A very complex SwiftUI expression that's overwhelming the compiler's type-checking capabilities. Likely within a `Chart` or a complex view composition.

*   **/Users/rogerlin/Downloads/Files/AppleJob/AppleJob/AppleJob.swift:3955:5 Attribute 'private' can only be used in a non-local scope, 3969:5 Attribute 'private' can only be used in a non-local scope, 3975:5 Attribute 'private' can only be used in a non-local scope, 3995:5 Attribute 'private' can only be used in a non-local scope:**
    *   **Source:** `EnhancedStatsView`, lines 3955, 3969, 3975, 3995.
    *   **Analysis:** Incorrect use of `private` access modifier within local scopes, such as inside computed properties or view builder closures. `private` should be used for struct/class members.

*   **/Users/rogerlin/Downloads/Files/AppleJob/AppleJob/AppleJob.swift:4067:1 Expected '}' in struct To match this opening '{':**
    *   **Source:** End of `NewLocationView` struct definition.
    *   **Analysis:** Missing closing brace `}` for the `NewLocationView` struct.

**2. Formulate Resolution Plans:**

Let's create a step-by-step plan for each error:

1.  **Scope Errors in `JobDetailView` (Lines 1993, 1996, 2000):**
    *   **Plan:**  Explicitly capture `doc` in the closures by using `let currentDoc = doc` at the beginning of the `ForEach` loop's body, and then use `currentDoc` inside the closures. This ensures `doc`'s value is captured for each iteration.

2.  **`Expected Declaration` in `JobDetailView` (Line 2038):**
    *   **Plan:** Carefully examine line 2038 and the code immediately following `JobDetailView`. Ensure there are no missing closing braces `}` for structs or views defined earlier. If the error is right after `JobDetailView`, double-check if the closing brace of `JobDetailView` itself is present and correctly placed.

3.  **Scope Errors in `DocumentsMainView` (Lines 2068, 2069 x2):**
    *   **Plan:** For `windowRef` and `quickLookURL`, ensure they are defined as `@State` variables within `DocumentsMainView`. Inside `.onAppear` and `.onChange`, use `self.windowRef` and `self.quickLookURL` to refer to the state variables correctly. For the `job` typo, change it to `doc` in the `updateWindowTitle` calls within these modifiers.

4.  **`Cannot find 'NewLocationView'` (Line 2327):**
    *   **Plan:**  Check the spelling of `NewLocationView`. Verify that `NewLocationView` struct is indeed defined in the codebase (it is, at the end of the provided code). If the declaration order is causing issues, try moving the `NewLocationView` struct definition to be earlier in the file, although in Swift this is usually not necessary within the same file.

5.  **`Compiler unable to type-check` (Line 3679):**
    *   **Plan:** Examine the code around line 3679 in `EnhancedStatsView`, particularly within the `Chart` or any complex view modifiers. Break down the potentially long expression. For example, if there's a chain of modifiers, try assigning intermediate results to local variables to simplify the overall expression. If it's in a `Chart`, simplify the marks or data transformations. *After inspecting the code, this error is likely related to the `Chart` in `EnhancedStatsView`, specifically the `Chart(barLineData)` part. It might be struggling with the data type or the complexity of the `BarMark`.* Let's try to simplify the `Chart` definition slightly.

6.  **`Attribute 'private' can only be used in a non-local scope` (Lines 3955, 3969, 3975, 3995):**
    *   **Plan:** Review the code in `EnhancedStatsView` around lines 3955, 3969, 3975, 3995. Identify where `private` is used. If it's within a computed property's implementation or a view builder closure, remove the `private` keyword. `private` is meant for instance variables and methods at the struct/class level. *Upon inspection, these errors are indeed within computed properties inside `EnhancedStatsView`. Remove the `private` keywords from these computed properties.*

7.  **`Expected '}' in struct` (Line 4067):**
    *   **Plan:** Go to line 4067 (or the end of the `NewLocationView` definition). Ensure there's a closing brace `}` to match the opening brace of the `NewLocationView` struct. If missing, add it. *After checking, the closing brace is indeed missing at the end of `NewLocationView`.*

**3. Systematic Error Resolution:**

Now, let's implement the fixes in the provided codebase. I will go through each error and apply the planned solution.

**Fix 1: Scope Errors in `JobDetailView` (Lines 1993, 1996, 2000):**

```swift
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
                // ... other code ...

                if !job.documents.isEmpty {
                    Divider()
                    Text("Documents")
                        .font(.headline)
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(job.documents, id: \.id) { doc in
                                let currentDoc = doc // Capture doc for use in closures
                                Button {
                                    openQuickLook(currentDoc)
                                } label: {
                                    HStack {
                                        Image(systemName: "doc.text")
                                            .foregroundColor(.primary)
                                        Text(cleanFileName(currentDoc.fileName))
                                            .gradientForeground(colors: [.blue, .purple])
                                    }
                                }
                                    .buttonStyle(.bordered)
                                }
                                .contextMenu {
                                    Button("Reveal in Finder") {
                                        revealInFinder(currentDoc)
                                    }
                                    Button("Delete Document") {
                                        docStore.deleteDocument(currentDoc)
                                    }
                                    Divider()
                                    Button("Edit Metadata") {
                                        docStore.beginEditMetadata(for: currentDoc)
                                    }
                                }
                            }
                        }
                    }
                }

                // ... rest of JobDetailView ...
            }
            .padding()
        }
        // ... rest of JobDetailView ...
    }

    // ... rest of JobDetailView methods ...
}
```
**Explanation:** Inside the `ForEach(job.documents)` loop, we added `let currentDoc = doc`. Now, within the `Button` and `.contextMenu` closures, we use `currentDoc` instead of `doc`. This explicitly captures the document for each iteration, resolving the scope issue.

**Fix 2: `Expected Declaration` in `JobDetailView` (Line 2038):**

After reviewing the code around line 2038, it seems the issue was actually the *missing closing brace* for the `ScrollView` in `JobDetailView`'s `body`. Let's add that:

```swift
struct JobDetailView: View {
    // ... body ...
        ScrollView { // Opening brace for ScrollView
            VStack(alignment: .leading, spacing: 12) {
                // ... content ...
            }
            .padding()
        } // Closing brace for ScrollView - ADDED THIS
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
        // ... rest of modifiers ...
    }
    // ... rest of struct ...
}
```
**Explanation:** A closing brace `}` was missing for the `ScrollView` in `JobDetailView`. Adding this resolves the "Expected declaration" error because the SwiftUI view hierarchy is now correctly formed.

**Fix 3: Scope Errors in `DocumentsMainView` (Lines 2068, 2069 x2):**

```swift
struct DocumentsMainView: View {
    @EnvironmentObject var docStore: DocumentStore

    @State private var windowRef: NSWindow?
    @State private var quickLookURL: URL? = nil

    var body: some View {
        ZStack {
            // ... content ...
        }
        .onAppear {
            if self.windowRef == nil { // Use self.windowRef
                if let keyWindow = NSApp.windows.first(where: { $0.isKeyWindow }) {
                    self.windowRef = keyWindow // Use self.windowRef
                }
            }
            updateWindowTitle(doc: docStore.selectedDocument) // Correct 'job' to 'doc'
        }
        .onChange(of: docStore.selectedDocument) { _, newDoc in
            updateWindowTitle(doc: newDoc) // Correct 'job' to 'doc'
        }
        // ... rest of modifiers ...
    }

    private func updateWindowTitle(doc: JobDocument?) { // Parameter is doc, not job
        guard let window = windowRef else { return } // windowRef is already captured
        if let doc = doc {
            window.title = cleanFileName(doc.fileName)
        } else {
            window.title = "Documents"
        }
    }

    // ... rest of DocumentsMainView ...
}
```
**Explanation:** In `.onAppear` and `.onChange`, we now use `self.windowRef` to correctly reference the state variable. Also, in the `updateWindowTitle` function calls within these modifiers, I've ensured we are passing `doc: docStore.selectedDocument` and `doc: newDoc` respectively, and corrected the parameter name in `updateWindowTitle` to `doc: JobDocument?`.

**Fix 4: `Cannot find 'NewLocationView'` (Line 2327):**

This error is a bit puzzling because `NewLocationView` is indeed defined later in the file. However, sometimes Xcode's compiler might have issues with forward declarations in complex SwiftUI files.  A simple fix is to move the `NewLocationView` struct definition to *before* `AddJobView`. Let's relocate the entire `NewLocationView` struct definition to be placed just before the `AddJobView` struct in the code file.

*(Move the entire `NewLocationView` struct definition from the end of the file to just before the `struct AddJobView: View {` declaration.)*

**Explanation:** By moving the `NewLocationView` definition earlier in the file, we ensure that the compiler has already processed its definition when it encounters `NewLocationView` in `AddJobView`. This resolves the "Cannot find 'NewLocationView' in scope" error.

**Fix 5: `Compiler unable to type-check` (Line 3679):**

The error is in `EnhancedStatsView`, likely within the `Chart(barLineData)` section. Let's try to simplify the `Chart` definition slightly by explicitly specifying the value type for `y` axis:

```swift
struct EnhancedStatsView: View {
    // ... other code ...

    @ViewBuilder
    private var barLineChartsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Applications Frequency (Last 12 Months / Range)")
                .font(.headline)

            if #available(macOS 13.0, *) {
                Chart(barLineData) { dayItem in
                    BarMark(
                        x: .value("Date", dayItem.date),
                        y: .value("Applications", dayItem.count as NSNumber) // Explicitly cast to NSNumber
                    )
                }
                .chartXSelection(value: $barLineSelectedDate)
                // ... rest of chart modifiers ...
            } else {
                Text("Charts require macOS 13.0+.")
            }
        }
        .frame(maxWidth: .infinity)
    }

    // ... rest of EnhancedStatsView ...
}
```
**Explanation:** By explicitly casting `dayItem.count` to `NSNumber` for the `y: .value("Applications", ...)` in `BarMark`, we provide more type information to the Swift Charts framework. This can sometimes help the compiler resolve type-checking issues in complex expressions.

**Fix 6: `Attribute 'private' can only be used in a non-local scope` (Lines 3955, 3969, 3975, 3995):**

In `EnhancedStatsView`, let's remove the `private` keywords from the computed properties that are causing issues. These are likely within the `pieChartsSection` or related computed properties.

```swift
struct EnhancedStatsView: View {
    // ... other code ...

    // MARK: - Pie Charts (Updated for Interactive Angle Selection)
    @State private var selectedMonthAngle: Double? = nil
    @State private var selectedCityAngle: Double? = nil
    @State private var selectedYearAngle: Double? = nil

    struct AngleRangeItem { // Changed to struct, private not applicable here either
        let key: String
        let range: Range<Double>
        let count: Int
    }

    func buildAngleRanges(for entries: [(key: String, count: Int)]) -> [AngleRangeItem] { // Removed private
        var result: [AngleRangeItem] = []
        var runningTotal: Double = 0
        for entry in entries {
            let start = runningTotal
            let end   = runningTotal + Double(entry.count)
            result.append(AngleRangeItem(key: entry.key, range: start..<end, count: entry.count))
            runningTotal = end
        }
        return result
    }

    func selectedMonthItem(_ angle: Double?) -> AngleRangeItem? { // Removed private
        guard let angle else { return nil }
        let monthData = monthlyShareData().map { (key: $0.monthKey, count: $0.count) }
        let monthRanges = buildAngleRanges(for: monthData)
        return monthRanges.first { $0.range.contains(angle) }
    }

    func selectedCityItem(_ angle: Double?) -> AngleRangeItem? { // Removed private
        guard let angle else { return nil }
        let cityData = cityShareData().map { (key: $0.city, count: $0.count) }
        let cityRanges = buildAngleRanges(for: cityData)
        return cityRanges.first { $0.range.contains(angle) }
    }

    func selectedYearItem(_ angle: Double?) -> AngleRangeItem? { // Removed private
        guard let angle else { return nil }
        let yearData = yearlyShareData().map { (key: $0.year, count: $0.count) }
        let yearRanges = buildAngleRanges(for: yearData)
        return yearRanges.first { $0.range.contains(angle) }
    }

    @ViewBuilder
    var pieChartsSection: some View {
        // ... rest of pieChartsSection ...
    }

    // ... rest of EnhancedStatsView ...
}
```
**Explanation:**  The `private` keywords were incorrectly used with the functions `buildAngleRanges`, `selectedMonthItem`, `selectedCityItem`, and `selectedYearItem` within `EnhancedStatsView`. These functions are methods of the `EnhancedStatsView` struct, not local variables inside a function. Removing `private` makes the access modifiers correct. Also, the `AngleRangeItem` was marked as `private struct`, which is not necessary within the scope of `EnhancedStatsView`, so I removed `private` from its declaration as well.

**Fix 7: `Expected '}' in struct` (Line 4067):**

Go to the end of the `NewLocationView` struct definition and add the missing closing brace `}`:

```swift
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
    } // ADDED CLOSING BRACE HERE
}
```
**Explanation:**  Added the missing closing brace `}` at the end of the `NewLocationView` struct definition. This resolves the syntax error.

**4. Comprehensive Code Review Post-Fixes:**

After applying all the fixes, the complete corrected codebase is as follows:

```swift
import SwiftUI
import AppKit
import UniformTypeIdentifiers
import PDFKit
import MapKit
import Charts
import Quartz
import QuickLook
import QuickLookUI
import MarkdownKit // Import MarkdownKit - Step 1.2

/**

 */
/**
 The AppDelegate handles custom URLs:
 We rely on application(_:open:) to capture applejob:// URLs.
 */
class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        print("AppDelegate: application(_:open:) called with URL: \(urls)") // ADD THIS PRINT
        guard let url = urls.first else { return }
        NotificationCenter.default.post(name: .didOpenCustomURL, object: url)
    }
}



extension Notification.Name {
    static let didOpenCustomURL = Notification.Name("didOpenCustomURL")
}


/**
 Represents the status of a job application.
 */
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
        case .interview:  return .purple
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

/**
 A model representing a single job application.

 Removed older RTF fields. We only keep plain text for jobDescription, coverLetter, and notes.
 */
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
        self.coverLetter    = try container.decode(String.self, forKey: .coverLetter)
        self.notes          = try? container.decode(String.self, forKey: .notes)

        self.isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        self.documents  = try container.decode([JobDocument].self, forKey: .documents)
    }

    func encode(to encoder: Encoder) throws {
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
    }

    static func == (lhs: JobApplication, rhs: JobApplication) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/**
 A model for uploaded documents. Preserves file metadata and data.
 */
struct JobDocument: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var fileName: String
    var fileURL: URL?
    var fileData: Data

    var creationDate: Date
    var lastModifiedDate: Date

    var fileSize: Int
    var wordCount: Int
    var categoryID: UUID?

    init(
        id: UUID = UUID(),
        fileName: String,
        fileData: Data,
        fileURL: URL? = nil,
        creation: Date = Date(),
        lastModified: Date = Date(),
        fileSize: Int? = nil,
        wordCount: Int? = nil,
        categoryID: UUID? = nil
    ) {
        self.id = id
        self.fileName = fileName
        self.fileURL = fileURL
        self.fileData = fileData
        self.creationDate = creation
        self.lastModifiedDate = lastModified
        self.fileSize = fileSize ?? fileData.count
        self.wordCount = wordCount ?? 0
        self.categoryID = categoryID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.fileName = try container.decode(String.self, forKey: .fileName)
        self.fileData = try container.decode(Data.self, forKey: .fileData)
        self.fileURL = try? container.decode(URL.self, forKey: .fileURL)
        self.creationDate = try container.decodeIfPresent(Date.self, forKey: .creationDate) ?? Date()
        self.lastModifiedDate = try container.decodeIfPresent(Date.self, forKey: .lastModifiedDate) ?? Date()
        self.fileSize = try container.decodeIfPresent(Int.self, forKey: .fileSize) ?? fileData.count
        self.wordCount = try container.decodeIfPresent(Int.self, forKey: .wordCount) ?? 0
        self.categoryID = try container.decodeIfPresent(UUID.self, forKey: .categoryID)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case fileName
        case fileData
        case fileURL
        case creationDate
        case lastModifiedDate
        case fileSize
        case wordCount
        case categoryID
    }
}

struct DocumentCategory: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var isExpanded: Bool = true

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

struct CompanyFreq: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
}

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
    "San Francisco, CA": CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    "Seattle, WA":       CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321),
    "Boston, MA":        CLLocationCoordinate2D(latitude: 42.3601, longitude: -71.0589),
    "Austin, TX":        CLLocationCoordinate2D(latitude: 30.2672, longitude: -97.7431),
    "Atlanta, GA":       CLLocationCoordinate2D(latitude: 33.7490, longitude: -84.3880),
    "Washington DC":     CLLocationCoordinate2D(latitude: 38.9072, longitude: -77.0369),
    "Hong Kong SAR":     CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694),
    "London, UK":        CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
    "Shanghai, CN":      CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
    "Singapore":         CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198),
    "Greenwich, CT":     CLLocationCoordinate2D(latitude: 41.0262, longitude: -73.6282),
    "Remote":            CLLocationCoordinate2D(latitude: 34.149884, longitude: -118.056932),
    "Newport Beach, CA": CLLocationCoordinate2D(latitude: 33.6189, longitude: -117.9298),
    "Shenzhen, CN":      CLLocationCoordinate2D(latitude: 22.5431, longitude: 114.0579),
    "Century City, CA":  CLLocationCoordinate2D(latitude: 34.0618409, longitude: -118.415054),
    "Las Vegas, NV":     CLLocationCoordinate2D(latitude: 36.1188, longitude: -115.1776),
    "Westport, CT":      CLLocationCoordinate2D(latitude: 41.126426, longitude: -73.329076),
    "Miami, FL":         CLLocationCoordinate2D(latitude: 25.7619089, longitude: -80.1912006),
    "Menlo Park, CA":    CLLocationCoordinate2D(latitude: 37.4519671, longitude: -122.177992),
    "Dallas, TX":        CLLocationCoordinate2D(latitude: 32.7762719, longitude: -96.7968559),
    "Global":            CLLocationCoordinate2D(latitude: 34.149884, longitude: -118.056932)
]

struct MonthlyCityData: Identifiable {
    let id = UUID()
    let monthKey: String
    let city: String
    let count: Int
    let date: Date
}

struct YearlyData: Identifiable {
    let id = UUID()
    let year: String
    let count: Int
}

struct Contribution: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
}

struct DailyApps: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

extension View {
    func gradientForeground(colors: [Color]) -> some View {
        self.overlay(
            LinearGradient(
                gradient: Gradient(colors: colors),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .mask(self)
    }
}

/**
 Manages a collection of JobApplication items, including load/save from UserDefaults.
 */
class JobStore: ObservableObject {
    @Published var jobApplications: [JobApplication] = []
    @Published var selectedJob: JobApplication? = nil
    @Published var isAddingNewJob = false
    @Published var isEditingJob = false
    @Published var sorting: Sort = .recentlyApplied
    @Published var incomingJobData: [String: Any]? = nil

    init() {
        loadJobs()
    }

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
            salary: job.salary,
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

    func saveJobs() {
        do {
            let data = try JSONEncoder().encode(jobApplications)
            UserDefaults.standard.set(data, forKey: "jobs")
        } catch {
            print("Failed to save jobs: \(error.localizedDescription)")
        }
    }

    func loadJobs() {
        guard let savedData = UserDefaults.standard.data(forKey: "jobs") else { return }
        do {
            let loadedApps = try JSONDecoder().decode([JobApplication].self, from: savedData)
            jobApplications = loadedApps
            sortJobs(by: sorting)
        } catch {
            print("Failed to load jobs: \(error.localizedDescription)")
        }
    }

    func importBackup(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let importedJobs = try JSONDecoder().decode([JobApplication].self, from: data)
            guard !importedJobs.isEmpty else { return }
            DispatchQueue.main.async {
                self.jobApplications = importedJobs
                self.sortJobs(by: self.sorting)
                self.saveJobs()
            }
        } catch {
            print("Error importing jobs: \(error)")
        }
    }

    func exportBackup(url: URL) {
        do {
            let data = try JSONEncoder().encode(jobApplications)
            try data.write(to: url)
            print("Exported backup.")
        } catch {
            print("Error exporting jobs: \(error)")
        }
    }
}

/**
 Manages a collection of JobDocument items, as well as categories.
 */
class DocumentStore: ObservableObject {
    @Published var documents: [JobDocument] = []
    @Published var selectedDocument: JobDocument? = nil

    @Published var categories: [DocumentCategory] = []
    @Published var isCreatingNewCategory = false
    @Published var newCategoryName: String = "Category Name"

    @Published var quickLookURL: URL? = nil

    @Published var isEditingMetadata = false
    @Published var documentToEdit: JobDocument? = nil

    init() {
        loadDocuments()
        loadCategories()
    }

    func uploadDocuments(from urls: [URL]) {
        for url in urls {
            do {
                let data = try Data(contentsOf: url)
                var creation = Date()
                var modified = Date()

                if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) {
                    if let cdate = attributes[.creationDate] as? Date {
                        creation = cdate
                    }
                    if let mdate = attributes[.modificationDate] as? Date {
                        modified = mdate
                    }
                }

                if let savedURL = DocumentStore.saveDocumentToAppSupport(
                    originalURL: url,
                    fileName: url.lastPathComponent
                ) {
                    let newDoc = JobDocument(
                        fileName: url.lastPathComponent,
                        fileData: data,
                        fileURL: savedURL,
                        creation: creation,
                        lastModified: modified
                    )
                    if !documents.contains(newDoc) {
                        documents.append(newDoc)
                    }
                } else {
                    print("Failed to save document to app support directory.")
                }
            } catch {
                print("Error reading document: \(error)")
            }
        }
        saveDocuments()
    }

    func downloadSelectedDocument() {
        guard let doc = selectedDocument else { return }
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = doc.fileName
        savePanel.begin { response in
            if response == .OK, let selectedURL = savePanel.url {
                do {
                    try doc.fileData.write(to: selectedURL)
                } catch {
                    print("Error saving document: \(error)")
                }
            }
        }
    }

    func duplicateDocument(_ document: JobDocument) {
        guard let savedURL = DocumentStore.saveDocumentToAppSupport(
            originalURL: document.fileURL ?? URL(fileURLWithPath: ""),
            fileName: document.fileName
        ) else {
            print("Failed to save duplicated document.")
            return
        }
        let newDoc = JobDocument(
            fileName: "\(document.fileName)-copy",
            fileData: document.fileData,
            fileURL: savedURL,
            creation: document.creationDate,
            lastModified: document.lastModifiedDate,
            fileSize: document.fileSize,
            wordCount: document.wordCount,
            categoryID: document.categoryID
        )
        documents.append(newDoc)
        saveDocuments()
    }

    func deleteDocument(_ document: JobDocument) {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents.remove(at: index)
            if let fileURL = document.fileURL {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                } catch {
                    print("Failed to delete file at \(fileURL): \(error)")
                }
            }
        }
        if selectedDocument?.id == document.id {
            selectedDocument = nil
        }
        saveDocuments()
    }

    func mergeDocuments(_ newDocs: [JobDocument]) {
        for doc in newDocs {
            if !documents.contains(doc) {
                documents.append(doc)
            }
        }
        saveDocuments()
    }

    func saveDocuments() {
        do {
            let data = try JSONEncoder().encode(documents)
            UserDefaults.standard.set(data, forKey: "documents")
        } catch {
            print("Failed to save documents: \(error.localizedDescription)")
        }
    }

    func loadDocuments() {
        guard let savedData = UserDefaults.standard.data(forKey: "documents") else { return }
        do {
            let loadedDocs = try JSONDecoder().decode([JobDocument].self, from: savedData)
            documents = loadedDocs
        } catch {
            print("Failed to load documents: \(error.localizedDescription)")
        }
    }

    func saveCategories() {
        do {
            let data = try JSONEncoder().encode(categories)
            UserDefaults.standard.set(data, forKey: "documentCategories")
        } catch {
            print("Failed to save categories: \(error.localizedDescription)")
        }
    }

    func loadCategories() {
        guard let savedData = UserDefaults.standard.data(forKey: "documentCategories") else { return }
        do {
            let loaded = try JSONDecoder().decode([DocumentCategory].self, from: savedData)
            categories = loaded
        } catch {
            print("Failed to load categories: \(error.localizedDescription)")
        }
    }

    func createNewCategory(name: String) {
        guard !name.isEmpty else { return }
        let newCat = DocumentCategory(name: name)
        categories.append(newCat)
        saveCategories()
    }

    func assignDocument(_ doc: JobDocument, to category: DocumentCategory) {
        if let idx = documents.firstIndex(where: { $0.id == doc.id }) {
            documents[idx].categoryID = category.id
            saveDocuments()
        }
    }

    func unassignDocument(_ doc: JobDocument) {
        if let idx = documents.firstIndex(where: { $0.id == doc.id }) {
            documents[idx].categoryID = nil
            saveDocuments()
        }
    }

    func beginEditMetadata(for doc: JobDocument) {
        self.documentToEdit = doc
        self.isEditingMetadata = true
    }

    static func saveDocumentToAppSupport(originalURL: URL, fileName: String) -> URL? {
        guard let appSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first else {
            return nil
        }
        let documentsDirectory = appSupportURL.appendingPathComponent("Documents", isDirectory: true)
        do {
            try FileManager.default.createDirectory(
                at: documentsDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            print("Failed to create Documents directory: \(error)")
            return nil
        }
        let uniqueFileName = UUID().uuidString + "_" + fileName
        let destinationURL = documentsDirectory.appendingPathComponent(uniqueFileName)
        do {
            try FileManager.default.copyItem(at: originalURL, to: destinationURL)
            return destinationURL
        } catch {
            print("Failed to copy file to Documents directory: \(error)")
            return nil
        }
    }
}

class ImportExportHelper: NSObject, ObservableObject {
    @Published var isImporting = false
    @Published var isExporting = false

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

    func importDocuments(completion: @escaping ([URL]) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.pdf, .image, .plainText, .rtf]
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.begin { response in
            if response == .OK {
                completion(openPanel.urls)
            }
        }
    }

    func exportDocuments(completion: @escaping (URL) -> Void) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.zip]
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "DocumentsExport.zip"
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                completion(url)
            }
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
        @Published var salaryDouble: Double? = nil // Numeric value for calculations

    @Published var isInputValid: Bool = false

    init() {
        validateInputs()
    }

    
    init(job: JobApplication) {
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
    func addJob(to store: JobStore, documents: [JobDocument]) {
        guard isInputValid else { return }
        let newJob = JobApplication(
            companyName: companyName,
            jobTitle: jobTitle,
            status: status,
            dateOfApplication: dateOfApplication,
            location: location,
            linkToJobString: linkToJob.isEmpty ? nil : linkToJob,
            salary: salaryDouble, // Step 2.7: Use salaryDouble
            jobDescription: jobDescription,
            coverLetter: coverLetter,
            notes: notes,
            documents: documents,
            isFavorite: false
        )
        store.addJob(newJob)
        reset()
    }

    func reset() {
        companyName = ""
        jobTitle = ""
        status = .interested
        dateOfApplication = Date()
        location = ""
        linkToJob = ""
        jobDescription = ""
        coverLetter = ""
        notes = ""
        salaryString = "" // Step 2.9: Reset salaryString
        validateInputs()
    }
}

@main
// --------------------------------------------------
// MARK: - Helper Classes & Observables (ImportExportHelper, JobViewModel, etc.)
// --------------------------------------------------
// All same as your original snippet, omitted here for brevity.
// ...

// --------------------------------------------------
// MARK: - The Main App + handleIncomingURL Modification
// --------------------------------------------------
struct AppleJobApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var jobStore = JobStore()
    @StateObject private var docStore = DocumentStore()
    @StateObject private var importExportHelper = ImportExportHelper()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(jobStore)
                .environmentObject(docStore)
                .environmentObject(importExportHelper)
                .onReceive(NotificationCenter.default.publisher(for: .didOpenCustomURL)) { notification in
                    print("AppleJobApp: Notification received: \(notification)") // ADD THIS PRINT
                    if let url = notification.object as? URL {
                        handleIncomingURL(url)
                    }
                }
        }
        .commands {
            fileMenuCommands
            editMenuCommands
        }
    }

    // -------------- handleIncomingURL --------------
    /**
     Now we decode the Base64 JSON on the main thread, parse it, and
     set jobStore.incomingJobData + jobStore.isAddingNewJob = true
     so AddJobView will appear with fields auto-filled.
     */
    private func handleIncomingURL(_ url: URL) {
        print("handleIncomingURL: URL received: \(url)")
        guard url.scheme == "applejob" else {
            print("handleIncomingURL: Scheme is not applejob, returning")
            return
        }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("handleIncomingURL: URLComponents failed, returning")
            return
        }

        guard let host = components.host else {
            print("handleIncomingURL: Host is missing, returning")
            return
        }

        if host == "x-callback-url" { // Check for x-callback-url base path
            let path = components.path // Directly access the path
            if path.isEmpty {
                print("handleIncomingURL: x-callback-url path missing, returning")
                return
            }

            let action = path.dropFirst() // Remove leading "/"
            print("handleIncomingURL: x-callback-url action: \(action)")

            switch action {
            case "add-job": // Handle the "add-job" action
                handleAddJobAction(queryItems: components.queryItems)
            case "open-stats": // Example for another potential action
                handleOpenStatsAction(queryItems: components.queryItems)
            default:
                print("handleIncomingURL: Unknown x-callback-url action: \(action)")
            }
        } else if host == "addjob" { // Keep handling the old "addjob" host for backward compatibility (optional)
            handleLegacyAddJob(components: components) // Separate legacy handling into a function
        } else {
            print("handleIncomingURL: Unknown host: \(host)")
        }
    }

    private func handleOpenStatsAction(queryItems: [URLQueryItem]?) {
        print("handleOpenStatsAction: Action not implemented yet.")
        // Add logic here if needed in the future
    }

    private func handleLegacyAddJob(components: URLComponents) {
        print("handleLegacyAddJob: Handling legacy add-job URL.")
        // Add logic here if needed in the future
    }

        // --- New Functions to Handle Actions ---

        /**
         Handles the "add-job" x-callback-url action.
         Expects parameters to be passed as query items, including jsonBase64.
         */
        private func handleAddJobAction(queryItems: [URLQueryItem]?) {
            print("handleAddJobAction: Handling add-job action")
            guard let rawBase64 = queryItems?.first(where: { $0.name == "jsonBase64" })?.value else {
                print("handleAddJobAction: jsonBase64 parameter missing")
                return
            }
            print("handleAddJobAction: Found jsonBase64 parameter: \(rawBase64)")
            DispatchQueue.main.async {
                guard let decodedData = Data(base64Encoded: rawBase64) else {
                    print("handleAddJobAction: Base64 decoding failed")
                    print("Base64 String was: \(rawBase64)")
                    return
                }
                do {
                    let jobData = try JSONDecoder().decode([String: String].self, from: decodedData)
                    print("handleAddJobAction: JSON decoding successful: \(jobData)")

                    // Extract fields:
                    let title   = jobData["jobTitle"] ?? ""
                    let urlString = jobData["URL"] ?? ""
                    let desc    = jobData["jobDescription"] ?? ""

                    // Store them in the jobStore:
                    jobStore.incomingJobData = [
                        "jobTitle": title,
                        "url": urlString,
                        "jobDescription": desc
                    ]
                    // Trigger AddJobView:
                    jobStore.isAddingNewJob = true
                    print("handleAddJobAction: Set jobStore.isAddingNewJob = true")

                } catch {
                    print("handleAddJobAction: JSON decoding error: \(error)")
                    if let jsonString = String(data: decodedData, encoding: .utf8) {
                        print("Data that failed to decode: \(jsonString)")
                    } else {
                        print("Data that failed to decode could not be converted to string")
                    }
                }
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
                    docStore.uploadDocuments(from: urls)
                }
            }
            Button("Export Documents...") {
                importExportHelper.exportDocuments { url in
                    exportAllDocumentsToZip(url: url)
                }
            }
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
            throw NSError(domain: "ZipError",
                          code: Int(process.terminationStatus),
                          userInfo: [NSLocalizedDescriptionKey: "Zip process failed."])
        }
    }
}

enum ViewSection: String, CaseIterable {
    case jobDetails = "Job Details"
    case stats = "Stats"
    case documents = "Documents"
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

struct DocumentInfoPopover: View {
    let document: JobDocument?
    @EnvironmentObject var docStore: DocumentStore

    @State private var showEditMetadataSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Document Information")
                .font(.headline)
            if let doc = document {
                Text("File Name: \(doc.fileName)")
                Text("Created: \(doc.creationDate.formatted(date: .abbreviated, time: .omitted))")
                Text("Last Modified: \(doc.lastModifiedDate.formatted(date: .abbreviated, time: .omitted))")
                Text("File Size: \(doc.fileSize) bytes")
                Text("Word Count: \(doc.wordCount)")

                Divider()
                Button("Edit Metadata") {
                    docStore.beginEditMetadata(for: doc)
                    showEditMetadataSheet = true
                }
                .sheet(isPresented: $showEditMetadataSheet) {
                    if let docToEdit = docStore.documentToEdit {
                        DocumentMetadataEditView(doc: docToEdit)
                            .environmentObject(docStore)
                    }
                }
            } else {
                Text("No document selected.")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(minWidth: 250)
    }
}

struct DocumentMetadataEditView: View {
    @EnvironmentObject var docStore: DocumentStore
    @Environment(\.presentationMode) var presentationMode

    @State var doc: JobDocument

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edit Document Metadata")
                .font(.headline)
            TextField("File Name", text: $doc.fileName)
                .textFieldStyle(.roundedBorder)
            DatePicker("Creation Date", selection: $doc.creationDate, displayedComponents: .date)
            DatePicker("Last Modified Date", selection: $doc.lastModifiedDate, displayedComponents: .date)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    presentationMode.wrappedValue.dismiss()
                }
                Button("Save") {
                    if let idx = docStore.documents.firstIndex(where: { $0.id == doc.id }) {
                        docStore.documents[idx].fileName = doc.fileName
                        docStore.documents[idx].creationDate = doc.creationDate
                        docStore.documents[idx].lastModifiedDate = doc.lastModifiedDate
                        docStore.saveDocuments()
                    }
                    presentationMode.wrappedValue.dismiss()
                    docStore.isEditingMetadata = false
                }
            }
            .padding(.top, 12)
        }
        .padding()
        .frame(minWidth: 400)
    }
}

struct JobSidebarView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var searchText: String

    var body: some View {
        List(selection: $jobStore.selectedJob) {
            ForEach(filteredJobs, id: \.id) { job in
                SidebarItemView(
                    job: job,
                    isSelected: Binding(
                        get: { jobStore.selectedJob == job },
                        set: { newValue in
                            if newValue { jobStore.selectedJob = job }
                            else if jobStore.selectedJob == job {
                                jobStore.selectedJob = nil
                            }
                        }
                    )
                )
                .tag(job)
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
                } label: {
                    Label("New", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $jobStore.isAddingNewJob) {
            AddJobView(isPresented: $jobStore.isAddingNewJob)
                .environmentObject(jobStore)
                .environmentObject(docStore)
                .onAppear {
                    print("JobSidebarView: Presenting AddJobView sheet because jobStore.isAddingNewJob is \(jobStore.isAddingNewJob)")
                }
        }
        .sheet(isPresented: $jobStore.isEditingJob) {
            if let job = jobStore.selectedJob {
                EditJobView(isPresented: $jobStore.isEditingJob, job: job)
                    .environmentObject(jobStore)
                    .environmentObject(docStore)
            }
        }
    }

    private var filteredJobs: [JobApplication] {
        if searchText.isEmpty {
            return jobStore.jobApplications
        } else {
            let lower = searchText.lowercased()
            return jobStore.jobApplications.filter {
                $0.companyName.lowercased().contains(lower)
                || $0.jobTitle.lowercased().contains(lower)
                || $0.location.lowercased().contains(lower)
            }
        }
    }

    private func deleteJobs(at offsets: IndexSet) {
        for index in offsets {
            let job = filteredJobs[index]
            jobStore.deleteJob(for: job.id)
        }
    }
}

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
                    Capsule().fill(
                        isSelected
                            ? Color(nsColor: .selectedTextBackgroundColor).opacity(0.6)
                            : job.status.displayColor.opacity(0.2)
                    )
                )
                .foregroundColor(job.status.displayColor)
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
                            jobStore.updateJobStatus(selectedJob.id, to: status)
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
            isSelected.toggle()
        }
    }
}

struct DocumentsSidebarView: View {
    @EnvironmentObject var docStore: DocumentStore

    @State private var isEditingCategory: Bool = false
    @State private var categoryToEdit: DocumentCategory? = nil
    @State private var categoryNameForEdit: String = ""

    var body: some View {
        List(selection: $docStore.selectedDocument) {
            Section {
                DisclosureGroup {
                    ForEach(uncategorizedDocuments, id: \.id) { doc in
                        documentSidebarItem(doc)
                            .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 0))
                    }
                } label: {
                    Text("All Documents")
                        .font(.headline)
                }
            }
            ForEach($docStore.categories, id: \.id) { $category in
                DisclosureGroup(isExpanded: $category.isExpanded) {
                    ForEach(docsForCategory(category.id), id: \.id) { doc in
                        documentSidebarItem(doc)
                            .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 0))
                    }
                } label: {
                    Text(category.name)
                        .font(.headline)
                }
                .contextMenu {
                    Button("Edit Category") {
                        categoryToEdit = category
                        categoryNameForEdit = category.name
                        isEditingCategory = true
                    }
                    Button("Delete Category", role: .destructive) {
                        for idx in docStore.documents.indices {
                            if docStore.documents[idx].categoryID == category.id {
                                docStore.documents[idx].categoryID = nil
                            }
                        }
                        docStore.saveDocuments()
                        if let catIndex = docStore.categories.firstIndex(where: { $0.id == category.id }) {
                            docStore.categories.remove(at: catIndex)
                            docStore.saveCategories()
                        }
                    }
                }
            }
            .onMove(perform: moveCategories)
        }
        .listStyle(SidebarListStyle())
        .background(
            Color.black.opacity(0.02).blur(radius: 1.0)
        )
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    docStore.newCategoryName = "Category Name"
                    docStore.isCreatingNewCategory = true
                } label: {
                    Label("New Category", systemImage: "folder.badge.plus")
                }
            }
        }
        .contextMenu {
            Button("Create New Category") {
                docStore.newCategoryName = "Category Name"
                docStore.isCreatingNewCategory = true
            }
        }
        .sheet(isPresented: $docStore.isCreatingNewCategory) {
            NewCategorySheet()
                .environmentObject(docStore)
        }
        .sheet(isPresented: $isEditingCategory) {
            VStack {
                TextField("Category Name", text: $categoryNameForEdit)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                HStack {
                    Button("Cancel", role: .cancel) {
                        isEditingCategory = false
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    Spacer()
                    Button("Save") {
                        if let catToEdit = categoryToEdit,
                           let idx = docStore.categories.firstIndex(where: { $0.id == catToEdit.id }) {
                            docStore.categories[idx].name = categoryNameForEdit
                            docStore.saveCategories()
                        }
                        isEditingCategory = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
                .padding()
            }
            .frame(width: 300, height: 150)
            .padding()
        }
        .quickLookPreview($docStore.quickLookURL)
    }

    private var uncategorizedDocuments: [JobDocument] {
        docStore.documents
            .filter { $0.categoryID == nil }
            .sorted { $0.lastModifiedDate > $1.lastModifiedDate }
    }

    private func moveCategories(from offsets: IndexSet, to destination: Int) {
        docStore.categories.move(fromOffsets: offsets, toOffset: destination)
        docStore.saveCategories()
    }

    private func docsForCategory(_ catID: UUID) -> [JobDocument] {
        docStore.documents
            .filter { $0.categoryID == catID }
            .sorted { $0.lastModifiedDate > $1.lastModifiedDate }
    }

    @ViewBuilder
    private func documentSidebarItem(_ doc: JobDocument) -> some View {
        Label {
            Text(cleanFileName(doc.fileName))
                .font(.system(size: 12))
        } icon: {
            Image(systemName: "doc.text")
                .font(.system(size: 18))
                .foregroundColor(.blue)
        }
        .contextMenu {
            Button("Duplicate Document") {
                docStore.duplicateDocument(doc)
            }
            Divider()
            Menu("Move to Category...") {
                ForEach(docStore.categories, id: \.id) { category in
                    Button(category.name) {
                        docStore.assignDocument(doc, to: category)
                    }
                }
            }
            Button("Create New Category") {
                docStore.newCategoryName = "Category Name"
                docStore.isCreatingNewCategory = true
            }
            Divider()
            Button("Edit Document Info") {
                docStore.beginEditMetadata(for: doc)
            }
            Button("Delete Document", role: .destructive) {
                docStore.deleteDocument(doc)
            }
        }
        .tag(doc)
    }

    private func cleanFileName(_ filename: String) -> String {
        var cleanedName = filename
        let stringsToRemove = ["Roger Lin", "Position", "2024", "Cover Letter"]
        for stringToRemove in stringsToRemove {
            cleanedName = cleanedName.replacingOccurrences(of: stringToRemove, with: "")
        }
        cleanedName = cleanedName.trimmingCharacters(in: .whitespaces)
        let fileExtensions = [".pdf", ".docx", ".pages", ".rtf", ".txt"]
        for ext in fileExtensions {
            if cleanedName.hasSuffix(ext) {
                cleanedName = String(cleanedName.dropLast(ext.count))
                break
            }
        }
        return cleanedName
    }
}

struct NewCategorySheet: View {
    @EnvironmentObject var docStore: DocumentStore
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            TextField("Category Name", text: $docStore.newCategoryName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            HStack {
                Button("Cancel", role: .cancel) {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.bordered)
                .tint(.red)
                Spacer()
                Button("Save") {
                    docStore.createNewCategory(name: docStore.newCategoryName)
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            .padding()
        }
        .frame(width: 300, height: 150)
        .padding()
    }
}

struct DocumentsMainView: View {
    @EnvironmentObject var docStore: DocumentStore

    @State private var windowRef: NSWindow?
    @State private var quickLookURL: URL? = nil

    var body: some View {
        ZStack {
            if docStore.documents.isEmpty {
                VStack {
                    Spacer()
                    Button("Upload") {
                        showDocumentPicker { urls in
                            docStore.uploadDocuments(from: urls)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    Spacer()
                }
            }
            else if docStore.selectedDocument == nil {
                Text("Select a document to view.")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            else if let doc = docStore.selectedDocument {
                PDFInlineViewer(fileURL: doc.fileURL, fileData: doc.fileData)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if self.windowRef == nil {
                if let keyWindow = NSApp.windows.first(where: { $0.isKeyWindow }) {
                    self.windowRef = keyWindow
                }
            }
            updateWindowTitle(doc: docStore.selectedDocument)
        }
        .onChange(of: docStore.selectedDocument) { _, newDoc in
            updateWindowTitle(doc: newDoc)
        }
        .sheet(isPresented: $docStore.isEditingMetadata) {
            if let docToEdit = docStore.documentToEdit {
                DocumentMetadataEditView(doc: docToEdit)
                    .environmentObject(docStore)
            }
        }
        .quickLookPreview($quickLookURL)
    }

    private func showDocumentPicker(completion: @escaping ([URL]) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.pdf, .image, .plainText, .rtf]
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = true
        openPanel.begin { result in
            if result == .OK {
                completion(openPanel.urls)
            }
        }
    }

    private func updateWindowTitle(doc: JobDocument?) {
        guard let window = windowRef else { return }
        if let doc = doc {
            window.title = cleanFileName(doc.fileName)
        } else {
            window.title = "Documents"
        }
    }

    private func cleanFileName(_ filename: String) -> String {
        var cleanedName = filename
        let stringsToRemove = ["Roger Lin", "Position", "2024", "Cover Letter"]
        for removal in stringsToRemove {
            cleanedName = cleanedName.replacingOccurrences(of: removal, with: "")
        }
        let fileExtensions = [".pdf", ".docx", ".pages", ".rtf", ".txt"]
        for ext in fileExtensions {
            if cleanedName.hasSuffix(ext) {
                cleanedName = String(cleanedName.dropLast(ext.count))
                break
            }
        }
        return cleanedName.trimmingCharacters(in: .whitespaces)
    }
}

struct PDFInlineViewer: NSViewRepresentable {
    let fileURL: URL?
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
        guard let currentDoc = nsView.document else {
            nsView.document = PDFDocument(data: fileData)
            return
        }
        let existingData = currentDoc.dataRepresentation() ?? Data()
        if existingData != fileData {
            nsView.document = PDFDocument(data: fileData)
        }
    }
}


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

                // Job Location
                if !job.location.isEmpty {
                    Text("Location: \(job.location)")
                        .font(.headline)
                } else {
                    Text("No location specified")
                        .foregroundColor(.secondary)
                }

                // Application Date
                Text("Applied on: \(job.dateOfApplication.formatted(date: .abbreviated, time: .omitted))")
                if let salary = job.salary {
                    let salaryAsInt = Int(salary) // Convert salary to Int
                    Text("Salary: \(salaryAsInt.formatted(.currency(code: "USD")))")
                        .font(.headline)
                }
                if !job.documents.isEmpty {
                    Divider()
                    Text("Documents")
                        .font(.headline)
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(job.documents, id: \.id) { doc in
                                let currentDoc = doc // Capture doc for use in closures
                                Button {
                                    openQuickLook(currentDoc)
                                } label: {
                                    HStack {
                                        Image(systemName: "doc.text")
                                            .foregroundColor(.primary)
                                        Text(cleanFileName(currentDoc.fileName))
                                            .gradientForeground(colors: [.blue, .purple])
                                    }
                                }
                                    .buttonStyle(.bordered)
                                }
                                .contextMenu {
                                    Button("Reveal in Finder") {
                                        revealInFinder(currentDoc)
                                    }
                                    Button("Delete Document") {
                                        docStore.deleteDocument(currentDoc)
                                    }
                                    Divider()
                                    Button("Edit Metadata") {
                                        docStore.beginEditMetadata(for: currentDoc)
                                    }
                                }
                            }
                        }
                    }
                }

                if !job.jobDescription.isEmpty {
                    Divider()
                    Text("Job Description")
                        .font(.headline)

                    // Use MarkdownParser to parse jobDescription
                    let attributedString = markdownParser.parse(job.jobDescription) // Step 1.3: Directly use the returned NSAttributedString
                    Text(AttributedString(attributedString)) // Convert NSAttributedString to SwiftUI AttributedString
                        .padding(4)
                }
                if !job.coverLetter.isEmpty {
                    Divider()
                    Text("Cover Letter")
                        .font(.headline)
                    Text(job.coverLetter)
                        .padding(4)
                }
                Divider()
                Text("Notes")
                    .font(.headline)
                if let notes = job.notes, !notes.isEmpty {
                    Text(notes)
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

import SwiftUI
import Charts
import MapKit

struct EnhancedStatsView: View {
    @EnvironmentObject var jobStore: JobStore

    // MARK: - Region & City Pins
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 50)
    )
    @State private var cityPins: [CityPin] = []

    // MARK: - GitHub-Style Data
    @State private var yearContributionData: [Contribution] = []
    @State private var appsContributionData: [Contribution] = []

    // Selections for GitHub Charts
    @State private var yearChartSelectedDate: Date? = nil
    @State private var appsChartSelectedDate: Date? = nil

    // MARK: - Time Range
    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case sixmonth = "Six Months"
        case year = "Year"
        var id: String { rawValue }
    }
    @AppStorage("StatsViewTimeRange") private var selectedTimeRangeRaw: String = TimeRange.month.rawValue
    @State private var selectedTimeRange: TimeRange = .month

    // MARK: - Year Picker
    @State private var availableYears: [Int] = []
    @State var selectedYear: Int = -1  // -1 means “All Years”

    // MARK: - Data for Bar/Line
    @State private var barLineData: [DailyApps] = []
    @State private var barLineSelectedDate: Date? = nil

    // MARK: - City-based Data
    @State private var monthlyCityData: [MonthlyCityData] = []

    // For macOS 14+ selection on bar charts (string-based)
    // Realistically, Swift Charts doesn’t support a direct “string selection” binding,
    // so these are placeholders to show a hover highlight if desired.
    @State private var horizontalPlotSelection: String? = nil
    @State private var singleColumnPlotSelection: String? = nil

    // MARK: - Top 20 Company selection
    @State private var top20CompanySelection: String? = nil

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                mapSection
                appliedCompaniesAndRolesView
                statsRowSection

                dynamicYearPickerSection

                githubChartsSection

                timeRangePickerSection

                barLineChartsSection

                horizontallyStackedBarChartSection

                singleColumnVerticallyStackedBarChartSection

                top20CompaniesBarSection

                citiesByFrequencySection
                companiesByFrequencySection

                pieChartsSection
            }
            .padding()
        }
        .onAppear {
            // Initialize time range from app storage.
            if let tr = TimeRange(rawValue: selectedTimeRangeRaw) {
                selectedTimeRange = tr
            } else {
                selectedTimeRange = .month
            }
            // Build up year array, city pins, chart data, etc.
            setupAvailableYears()
            computeCityPins()
            computeYearContribution()
            computeAppsContribution()
            computeBarLineData()
            computeMonthlyCityData()
        }
        .onChange(of: selectedTimeRange) { _, newVal in
            selectedTimeRangeRaw = newVal.rawValue
            computeBarLineData()
        }
        .onChange(of: selectedYear) { _, _ in
            computeYearContribution()
            computeAppsContribution()
            computeMonthlyCityData()
        }
        .navigationTitle("Stats & Analytics")
    }

// MARK: - Map
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Applications Map")
                .font(.headline)

            Map {
                ForEach(cityPins) { cityPin in
                    Annotation("City: \(cityPin.city)", coordinate: cityPin.coordinate) {
                        Circle()
                            .fill(Color.red.opacity(0.5))
                            .frame(width: max(10, CGFloat(cityPin.count) * 1.5), height: max(10, CGFloat(cityPin.count) * 1.5))
                            .overlay(
                                Text("\(cityPin.count)")
                                    .foregroundColor(.white)
                                    .font(.system(size: 10))
                            )
                    }
                }
            }
            .frame(height: 500)
            .cornerRadius(5)
        }
    }

    
    
    
    
    
    // MARK: - Stats Row
    private var statsRowSection: some View {
        let total = jobStore.jobApplications.count
        let applied = jobStore.jobApplications.filter { $0.status == .applied }.count
        let interested = jobStore.jobApplications.filter { $0.status == .interested }.count
        let interviewed = jobStore.jobApplications.filter { $0.status == .interview }.count
        let distinctCities = Set(jobStore.jobApplications.map { $0.location }).count
        let topCompany = topCompanyName()
        let (topCityName, topCityCount) = topCity()

        let gradient = LinearGradient(
            colors: [.blue, .pink],
            startPoint: .leading,
            endPoint: .trailing
        )

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 32) {
                VStack {
                    Text("Total Apps")
                    Text("\(total)")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(gradient)
                }
                VStack {
                    Text("Applied")
                    Text("\(applied)")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(gradient)
                }
                VStack {
                    Text("Interested")
                    Text("\(interested)")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(gradient)
                }
                VStack {
                    Text("Interviews")
                    Text("\(interviewed)")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(gradient)
                }
                VStack {
                    Text("Distinct Cities")
                    Text("\(distinctCities)")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(gradient)
                }
                VStack {
                    Text("Top Company")
                    Text(topCompany)
                        .font(.title3)
                        .bold()
                        .foregroundStyle(gradient)
                }
                VStack {
                    Text("Top City")
                    Text(topCityName)
                        .font(.title3)
                        .bold()
                        .foregroundStyle(gradient)
                    Text("\(topCityCount)")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(gradient)
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
    }

    /**
    // MARK: - Dynamic Year Picker
     Displays a segmented picker with all real years plus a final “All Years.”
     Example: [2022, 2023, 2024, -1]
     The user can switch to “All Years” or back to a specific year at any time.
     */
    private var dynamicYearPickerSection: some View {
        // Build a list from earliest to latest year, then add -1 for “All Years.”
        let sortedYears = availableYears.sorted()
        let yearsWithAll = sortedYears + [-1]

        return HStack {
            Text("Select Year:")
            
            Picker("Year", selection: $selectedYear) {
                ForEach(yearsWithAll, id: \.self) { yr in
                    if yr == -1 {
                        Text("All Years").tag(yr)
                    } else {
                        Text(verbatim:"\(yr)").tag(yr)
                    }
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.horizontal)
    }

    // MARK: - GitHub-Style Charts
    private var githubChartsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("GitHub-Style Contribution Charts")
                .font(.headline)
                .padding(.vertical)

            if #available(macOS 13.0, *) {
                // 1) Year Contribution
                Chart(yearContributionData) { item in
                    RectangleMark(
                        x: .value("WeekOfYear", item.date, unit: .weekOfYear),
                        y: .value("DayOfWeek", weekday(for: item.date))
                    )
                    .foregroundStyle(by: .value("Count", item.count))
                    .clipShape(RoundedRectangle(cornerRadius: 1))
                }
                .chartXSelection(value: $yearChartSelectedDate)
                .chartForegroundStyleScale(range: Gradient(colors: chartColors))
                .chartYAxis {
                    AxisMarks(values: [1, 3, 5, 7]) { val in
                        if let i = val.as(Int.self), let label = shortWeekdaySymbol(i) {
                            AxisValueLabel(label)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) {
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .ifShouldScrollHorizontally(selectedYear: selectedYear)
                .frame(height: 200)
                .overlay {
                    if let sel = yearChartSelectedDate {
                        GeometryReader { geo in
                            let dayStr = sel.formatted(date: .abbreviated, time: .omitted)
                            Text("Selected: \(dayStr)")
                                .font(.headline)
                                .padding(5)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(5)
                                .position(x: geo.size.width * 0.5, y: 10)

                        }
                    }
                }

                // 2) Apps Contribution
                Chart(appsContributionData) { item in
                    RectangleMark(
                        x: .value("WeekOfYear", item.date, unit: .weekOfYear),
                        y: .value("DayOfWeek", weekday(for: item.date))
                    )
                    .foregroundStyle(by: .value("Count", item.count))
                    .clipShape(RoundedRectangle(cornerRadius: 0.5))
                }
                .chartXSelection(value: $appsChartSelectedDate)
                .chartForegroundStyleScale(range: Gradient(colors: chartColors))
                .chartYAxis {
                    AxisMarks(values: [1, 3, 5, 7]) { val in
                        if let i = val.as(Int.self), let label = shortWeekdaySymbol(i) {
                            AxisValueLabel(label)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) {
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .padding(.vertical)
                .frame(height: 200)
                .ifShouldScrollHorizontally(selectedYear: selectedYear)
                .overlay {
                    if let sel = appsChartSelectedDate {
                        GeometryReader { geo in
                            let dayStr = sel.formatted(date: .abbreviated, time: .omitted)
                            let c = appsContributionData.first(where: { $0.date == sel })?.count ?? 0
                            Text("\(c) apps on \(dayStr)")
                                .font(.headline)
                                .padding(5)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(5)
                                .position(x: geo.size.width * 0.5, y: 10)

                        }
                    }
                }

            }
        }
        .frame(maxHeight: .infinity)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Recently Applied
    private var appliedCompaniesAndRolesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(jobStore.jobApplications.sorted(by: { $0.dateOfApplication > $1.dateOfApplication })) { job in
                    Button {
                        jobStore.selectedJob = job // Step 1.3: Set selectedJob in JobStore
                    } label: { // Step 1.2: Wrap VStack in Button
                        VStack(alignment: .center, spacing: 5) {
                            Text(job.companyName)
                                .font(.title3)
                                .bold()
                                .multilineTextAlignment(.center)
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 125)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(job.jobTitle)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.teal, .green]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 150)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(job == jobStore.selectedJob ? Color.blue.opacity(0.2) : Color.white.opacity(0.1)) // Step 1.4: Visual indicator
                        .cornerRadius(5)
                    }
                    .buttonStyle(.plain) // To remove button styling
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Time Range Picker
    private var timeRangePickerSection: some View {
        HStack {
            Text("Select Time Range:")
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Bar+Line Chart
    // MARK: - Bar+Line Chart
    @ViewBuilder
    private var barLineChartsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Applications Frequency (Last 12 Months / Range)")
                .font(.headline)

            if #available(macOS 13.0, *) {
                Chart(barLineData) { dayItem in
                    BarMark(
                        x: .value("Date", dayItem.date),
                        y: .value("Applications", dayItem.count as NSNumber)
                    )
                }
                .chartXSelection(value: $barLineSelectedDate)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .frame(height: 300)
                .overlay {
                    if let sel = barLineSelectedDate {
                        GeometryReader { geo in
                            let dayStr = sel.formatted(date: .abbreviated, time: .omitted)
                            let c = barLineData.first(where: { $0.date == sel })?.count ?? 0
                            Text("\(c) apps on \(dayStr)")
                                .font(.headline)
                                .padding(5)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(5)
                        }
                    }
                }
            } else {
                Text("Charts require macOS 13.0+.")
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Horizontally Stacked Bar
    @ViewBuilder
    private var horizontallyStackedBarChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Applications by City - Horizontally Stacked Bar Chart")
                .font(.headline)

            if #available(macOS 13.0, *) {
                Chart(monthlyCityDataFilteredForSelectedYear()) { item in
                    BarMark(
                        x: .value("Month", item.monthKey),
                        y: .value("Count", item.count),
                        width: 10
                    )
                    .position(by: .value("City", item.city))
                    .foregroundStyle(by: .value("City", item.city))
                }
                // In Swift Charts 5.9 or macOS 14, we can’t do a direct string binding selection.
                // For demonstration, we skip interactive selection, or you can implement a .onChartContinuousSelection{} approach.
                .chartXSelection(value: $horizontalPlotSelection) // Feature 3: chartXSelection for tooltips
                .ifShouldScrollHorizontally(selectedYear: selectedYear)
                .chartXAxis {
                    AxisMarks()
                }
                .chartYAxis {
                    AxisMarks()
                }
                .frame(height: 300)
                .overlay(alignment: .top) { // Feature 3: Tooltip overlay
                    if let selection = horizontalPlotSelection,
                       let selectedData = monthlyCityDataFilteredForSelectedYear().first(where: { $0.monthKey == selection }) {
                        Text("\(selectedData.city): \(selectedData.count) Applications")
                            .padding(8)
                            .background(Color.gray.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
    }

 
    // MARK: - Single Column Vertically Stacked Bar
    @ViewBuilder
    private var singleColumnVerticallyStackedBarChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Applications by City - Single Column Vertically Stacked Bar Chart")
                .font(.headline)

            if #available(macOS 13.0, *) {
                Chart(monthlyCityDataFilteredForSelectedYear()) { item in
                    BarMark(
                        x: .value("Month", item.monthKey),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(by: .value("City", item.city))
                }
                .ifShouldScrollHorizontally(selectedYear: selectedYear)
                .chartXAxis {
                    AxisMarks()
                }
                .chartYAxis {
                    AxisMarks()
                }
                .frame(height: 300)

            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)

    }

    // MARK: - Top 20 Companies
    private var top20CompaniesBarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top 20 Companies by Application Frequency (All Years)")
                .font(.headline)

            if #available(macOS 13.0, *) {
                let freq = buildTop20CompanyFreq()
                Chart(freq) { item in
                    BarMark(
                        x: .value("Company", item.name),
                        y: .value("Count", item.count)
                    )
                }
                .chartXAxis {
                    AxisMarks(values: .automatic)
                }
                .chartYAxis {
                    AxisMarks()
                }
                .frame(height: 300)

            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Cities by Frequency
    private var citiesByFrequencySection: some View {
        let cityCounts = cityFreqList()
        return VStack(alignment: .leading) {
            Text("Cities by Frequency (All Years)")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 24) {
                    ForEach(cityCounts, id: \.city) { item in
                        VStack {
                            Text(item.city)
                                .font(.headline)
                                .frame(width: 100)
                                .gradientForeground(colors: [.blue, .purple])
                                .multilineTextAlignment(.center)
                            Text("\(item.count)")
                                .font(.title3)
                        }
                        .padding(5)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 25)
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Companies by Frequency
    private var companiesByFrequencySection: some View {
        let companies = companyFreqList()
        return VStack(alignment: .leading, spacing: 10) {
            Text("Companies By Frequency")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 20) {
                    ForEach(companies, id: \.name) { item in
                        VStack {
                            Text(item.name)
                                .font(.headline)
                                .frame(width: 100)
                                .gradientForeground(colors: [.blue, .purple])
                                .multilineTextAlignment(.center)
                            Text("\(item.count)")
                                .font(.title3)
                        }
                        .padding(5)
                    }
                }
                .padding(.horizontal, 15)
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Pie Charts (Updated for Interactive Angle Selection)
    // MARK: - Pie Charts (Updated for Interactive Angle Selection)
    @State private var selectedMonthAngle: Double? = nil
        @State private var selectedCityAngle: Double? = nil
        @State private var selectedYearAngle: Double? = nil

        struct AngleRangeItem {
            let key: String
            let range: Range<Double>
            let count: Int
        }

        func buildAngleRanges(for entries: [(key: String, count: Int)]) -> [AngleRangeItem] {
            var result: [AngleRangeItem] = []
            var runningTotal: Double = 0
            for entry in entries {
                let start = runningTotal
                let end   = runningTotal + Double(entry.count)
                result.append(AngleRangeItem(key: entry.key, range: start..<end, count: entry.count))
                runningTotal = end
            }
            return result
        }

        func selectedMonthItem(_ angle: Double?) -> AngleRangeItem? {
            guard let angle else { return nil }
            let monthData = monthlyShareData().map { (key: $0.monthKey, count: $0.count) }
            let monthRanges = buildAngleRanges(for: monthData)
            return monthRanges.first { $0.range.contains(angle) }
        }

        func selectedCityItem(_ angle: Double?) -> AngleRangeItem? {
            guard let angle else { return nil }
            let cityData = cityShareData().map { (key: $0.city, count: $0.count) }
            let cityRanges = buildAngleRanges(for: cityData)
            return cityRanges.first { $0.range.contains(angle) }
        }

        func selectedYearItem(_ angle: Double?) -> AngleRangeItem? {
            guard let angle else { return nil }
            let yearData = yearlyShareData().map { (key: $0.year, count: $0.count) }
            let yearRanges = buildAngleRanges(for: yearData)
            return yearRanges.first { $0.range.contains(angle) }
        }

        @ViewBuilder
    private var pieChartsSection: some View {
        
        if #available(macOS 14.0, iOS 17.0, *) {
            VStack(alignment: .center, spacing: 16) {
                Text("Application Shares (Pie Charts)")
                    .font(.headline)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(alignment: .center, spacing: 32) {
                        
                        VStack {
                            Text("Share by Month (\(selectedYearText()))")
                                .font(.subheadline)
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.green, .teal]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            let monthData = monthlyShareData().map { (key: $0.monthKey, count: $0.count) }
                            let monthRanges = buildAngleRanges(for: monthData)
                            let monthTotal  = monthRanges.reduce(0) { $0 + $1.count }
                            
                            Chart(monthData, id: \.key) { item in
                                SectorMark(
                                    angle: .value("Count", item.count),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1
                                )
                                .cornerRadius(4)
                                .foregroundStyle(by: .value("Month", item.key))
                                
                                .opacity(item.key == selectedMonthItem(selectedMonthAngle)?.key ? 1 : 0.75)
                            }
                            .chartLegend(.hidden)
                            .chartAngleSelection(value: $selectedMonthAngle)
                            .chartBackground { chartProxy in
                                GeometryReader { geometry in
                                    if let anchor = chartProxy.plotFrame {
                                        let frame = geometry[anchor]
                                        
                                        let selItem = selectedMonthItem(selectedMonthAngle)
                                        let label   = selItem?.key ?? "Months"
                                        let count   = selItem?.count ?? monthTotal
                                        
                                        VStack {
                                            Text(label)
                                                .font(.headline)
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [.blue, .purple]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                            Text("\(count) apps")
                                                .font(.title2)
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [.orange, .red]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                        }
                                        .position(x: frame.midX, y: frame.midY)
                                    }
                                }
                            }
                            .frame(minWidth: 350, minHeight: 350)
                        }
                        
                        VStack {
                            Text("Share by City (\(selectedYearText()))")
                                .font(.subheadline)
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.pink, .orange]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            let cityData = cityShareData().map { (key: $0.city, count: $0.count) }
                            let cityRanges = buildAngleRanges(for: cityData)
                            let cityTotal  = cityRanges.reduce(0) { $0 + $1.count }
                            
                            Chart(cityData, id: \.key) { item in
                                SectorMark(
                                    angle: .value("Count", item.count),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 1
                                )
                                .cornerRadius(3)
                                .foregroundStyle(by: .value("City", item.key))
                                .opacity(item.key == selectedCityItem(selectedCityAngle)?.key ? 1 : 0.5)
                            }
                            .frame(minWidth: 350, minHeight: 350)
                            .chartLegend(position: .trailing)
                            .chartAngleSelection(value: $selectedCityAngle)
                            .chartBackground { chartProxy in
                                GeometryReader { geometry in
                                    if let anchor = chartProxy.plotFrame {
                                        let frame = geometry[anchor]
                                        
                                        let selItem = selectedCityItem(selectedCityAngle)
                                        let label   = selItem?.key ?? "Cities"
                                        let count   = selItem?.count ?? cityTotal
                                        
                                        VStack {
                                            Text(label)
                                                .font(.headline)
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [.blue, .purple]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                            Text("\(count) apps")
                                                .font(.title2)
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [.orange, .red]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                        }
                                        .position(x: frame.midX, y: frame.midY)
                                    }
                                }
                            }
                            .frame(minWidth: 700)
                        }
                        
                        VStack {
                            Text("Share by Year")
                                .font(.subheadline)
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.indigo, .cyan]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            let yearData = yearlyShareData().map { (key: $0.year, count: $0.count) }
                            let yearRanges = buildAngleRanges(for: yearData)
                            let yearTotal  = yearRanges.reduce(0) { $0 + $1.count }
                            
                            Chart(yearData, id: \.key) { item in
                                SectorMark(
                                    angle: .value("Count", item.count),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 2
                                )
                                .cornerRadius(4)
                                .foregroundStyle(by: .value("Year", item.key))
                                .opacity(item.key == selectedYearItem(selectedYearAngle)?.key ? 1 : 0.5)
                            }
                            .chartLegend(position: .bottom)
                            .chartAngleSelection(value: $selectedYearAngle)
                            .chartBackground { chartProxy in
                                GeometryReader { geometry in
                                    if let anchor = chartProxy.plotFrame {
                                        let frame = geometry[anchor]
                                        
                                        let selItem = selectedYearItem(selectedYearAngle)
                                        let label   = selItem?.key ?? "Years"
                                        let count   = selItem?.count ?? yearTotal
                                        
                                        VStack {
                                            Text(label)
                                                .font(.headline)
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [.pink, .purple]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                            Text("\(count) apps")
                                                .font(.title2)
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [.yellow, .orange]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                        }
                                        .position(x: frame.midX, y: frame.midY)
                                    }
                                }
                            }
                            .frame(minWidth: 350, minHeight: 350)
                        }
                    }
                    .padding(.horizontal, 10)
                }
            }
        }
    }
    // MARK: - Setup & Compute Methods

    private func setupAvailableYears() {
        let allDates = jobStore.jobApplications.map { $0.dateOfApplication }
        guard !allDates.isEmpty else {
            self.availableYears = []
            self.selectedYear = -1
            return
        }
        let cal = Calendar.current
        let minYear = cal.component(.year, from: allDates.min()!)
        let maxYear = cal.component(.year, from: allDates.max()!)

        if minYear <= maxYear {
            self.availableYears = Array(minYear...maxYear)
        } else {
            self.availableYears = []
        }
        // If current selectedYear is not in the available range, default to All Years.
        if !self.availableYears.contains(selectedYear) && selectedYear != -1 {
            self.selectedYear = -1
        }
    }

    private func computeCityPins() {
        // Build cityPin data from all job applications
        var cityCount: [String: Int] = [:]
        for job in jobStore.jobApplications {
            cityCount[job.location, default: 0] += 1
        }
        cityPins = cityCount.map { (city, ct) in
            // Optional dictionary to get lat/long from city:
            let coord = CityCoordinateDictionary[city]
                ?? CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795)
            return CityPin(city: city, coordinate: coord, count: ct)
        }
    }

    private func computeYearContribution() {
        guard !jobStore.jobApplications.isEmpty else {
            yearContributionData = []
            return
        }
        let cal = Calendar.current
        let allDates = jobStore.jobApplications.map { $0.dateOfApplication }
        let overallMin = allDates.min()!
        let overallMax = allDates.max()!

        // Determine day range
        let (startOfRange, endOfRange): (Date, Date)
        if selectedYear == -1 {
            startOfRange = cal.startOfDay(for: overallMin)
            endOfRange = overallMax
        } else {
            guard let s = cal.date(from: DateComponents(year: selectedYear, month: 1, day: 1)),
                  let e = cal.date(from: DateComponents(year: selectedYear, month: 12, day: 31))
            else {
                yearContributionData = []
                return
            }
            startOfRange = cal.startOfDay(for: s)
            endOfRange = e
        }

        var results: [Contribution] = []
        var dayCursor = startOfRange
        while dayCursor <= endOfRange {
            // Count is just placeholder logic; adjust as you like.
            // For example, you might want to put actual daily counts here
            // or simply fill the squares to reflect the calendar layout.
            let dayVal = cal.startOfDay(for: dayCursor)
            results.append(Contribution(date: dayVal, count: 1))
            if let nextDay = cal.date(byAdding: .day, value: 1, to: dayCursor) {
                dayCursor = nextDay
            } else {
                break
            }
        }
        yearContributionData = results
    }

    private func computeAppsContribution() {
        // Example: actual daily counts of submitted apps in that date range
        guard !jobStore.jobApplications.isEmpty else {
            appsContributionData = []
            return
        }
        let cal = Calendar.current
        let allDates = jobStore.jobApplications.map { $0.dateOfApplication }
        let overallMin = allDates.min()!
        let overallMax = allDates.max()!

        let (startOfRange, endOfRange): (Date, Date)
        if selectedYear == -1 {
            startOfRange = cal.startOfDay(for: overallMin)
            endOfRange = overallMax
        } else {
            guard let s = cal.date(from: DateComponents(year: selectedYear, month: 1, day: 1)),
                  let e = cal.date(from: DateComponents(year: selectedYear, month: 12, day: 31))
            else {
                appsContributionData = []
                return
            }
            startOfRange = cal.startOfDay(for: s)
            endOfRange = e
        }

        // Tally real apps on each day
        var dateCount: [Date: Int] = [:]
        for job in jobStore.jobApplications {
            let day = cal.startOfDay(for: job.dateOfApplication)
            if day >= startOfRange && day <= endOfRange {
                dateCount[day, default: 0] += 1
            }
        }

        var results: [Contribution] = []
        var dayCursor = startOfRange
        while dayCursor <= endOfRange {
            let c = dateCount[dayCursor, default: 0]
            results.append(Contribution(date: dayCursor, count: c))
            if let nextDay = cal.date(byAdding: .day, value: 1, to: dayCursor) {
                dayCursor = nextDay
            } else {
                break
            }
        }
        appsContributionData = results
    }

    private func computeBarLineData() {
        let now = Date()
        let cal = Calendar.current
        var earliest: Date?

        switch selectedTimeRange {
        case .week:
            earliest = cal.date(byAdding: .day, value: -7, to: now)
        case .month:
            earliest = cal.date(byAdding: .month, value: -1, to: now)
        case .sixmonth:
            earliest = cal.date(byAdding: .month, value: -6, to: now)
        case .year:
            earliest = cal.date(byAdding: .year, value: -1, to: now)
        }

        guard let start = earliest else {
            barLineData = []
            return
        }
        var dailyCount: [Date: Int] = [:]
        let filtered = jobStore.jobApplications.filter { $0.dateOfApplication >= start }
        for job in filtered {
            let day = cal.startOfDay(for: job.dateOfApplication)
            dailyCount[day, default: 0] += 1
        }
        let sortedKeys = dailyCount.keys.sorted()
        barLineData = sortedKeys.map { d in
            DailyApps(date: d, count: dailyCount[d] ?? 0)
        }
    }

    private func computeMonthlyCityData() {
        guard !jobStore.jobApplications.isEmpty else {
            monthlyCityData = []
            return
        }
        let cal = Calendar.current
        let allDates = jobStore.jobApplications.map { $0.dateOfApplication }
        let overallMin = allDates.min()!
        let overallMax = allDates.max()!

        let (startOfYear, endOfYear): (Date, Date)
        if selectedYear == -1 {
            startOfYear = cal.startOfDay(for: overallMin)
            endOfYear = overallMax
        } else {
            guard let s = cal.date(from: DateComponents(year: selectedYear, month: 1, day: 1)),
                  let e = cal.date(from: DateComponents(year: selectedYear, month: 12, day: 31))
            else {
                monthlyCityData = []
                return
            }
            startOfYear = cal.startOfDay(for: s)
            endOfYear = e
        }

        // Build list of all the first-of-month boundaries in that year range
        var months: [Date] = []
        var cursor = startOfYear
        while cursor <= endOfYear {
            months.append(cursor)
            if let nxt = cal.date(byAdding: .month, value: 1, to: cursor) {
                cursor = nxt
            } else {
                break
            }
        }

        let appsInRange = jobStore.jobApplications.filter {
            $0.dateOfApplication >= startOfYear && $0.dateOfApplication <= endOfYear
        }
        var temp: [MonthlyCityData] = []
        for monthStart in months {
            guard let comps = cal.dateComponents([.year, .month], from: monthStart).month,
                  let yearVal = cal.dateComponents([.year], from: monthStart).year
            else { continue }
            let mKey = "\(monthName(comps)) \(yearVal)"

            guard let nextMonth = cal.date(byAdding: .month, value: 1, to: monthStart) else { continue }

            let appsInMonth = appsInRange.filter {
                $0.dateOfApplication >= monthStart && $0.dateOfApplication < nextMonth
            }
            // Group by city
            let cityGrouped = Dictionary(grouping: appsInMonth, by: \.location)
            for (city, group) in cityGrouped {
                temp.append(MonthlyCityData(
                    monthKey: mKey,
                    city: city,
                    count: group.count,
                    date: monthStart
                ))
            }
        }
        temp.sort { $0.date < $1.date }
        monthlyCityData = temp
    }

    private func monthlyCityDataFilteredForSelectedYear() -> [MonthlyCityData] {
        monthlyCityData  // already filtered inside computeMonthlyCityData
    }

    // MARK: - Pie Chart Data
    private func monthlyShareData() -> [MonthlyCityData] {
        let grouped = Dictionary(grouping: monthlyCityDataFilteredForSelectedYear()) { $0.monthKey }
        return grouped.map { (mKey, recs) in
            let sum = recs.reduce(0) { $0 + $1.count }
            return MonthlyCityData(monthKey: mKey, city: "", count: sum, date: Date())
        }
        .sorted { $0.monthKey < $1.monthKey }
    }

    private func cityShareData() -> [MonthlyCityData] {
        let grouped = Dictionary(grouping: monthlyCityDataFilteredForSelectedYear()) { $0.city }
        return grouped.map { (city, recs) in
            let sum = recs.reduce(0) { $0 + $1.count }
            return MonthlyCityData(monthKey: "", city: city, count: sum, date: Date())
        }
        .sorted { $0.count > $1.count }
    }

    private func yearlyShareData() -> [YearlyData] {
        let cal = Calendar.current
        let allApps = jobStore.jobApplications
        if selectedYear == -1 {
            // Group all apps by year
            let grouped = Dictionary(grouping: allApps) {
                cal.component(.year, from: $0.dateOfApplication)
            }
            return grouped.map { (yearVal, arr) in
                YearlyData(year: String(yearVal), count: arr.count)
            }
            .sorted { $0.year < $1.year }
        } else {
            let sameYear = allApps.filter {
                cal.component(.year, from: $0.dateOfApplication) == selectedYear
            }
            return [YearlyData(year: "\(selectedYear)", count: sameYear.count)]
        }
    }

    private func buildTop20CompanyFreq() -> [CompanyFreq] {
        var freq: [String: Int] = [:]
        for job in jobStore.jobApplications {
            freq[job.companyName, default: 0] += 1
        }
        return freq
            .sorted { $0.value > $1.value }
            .prefix(20)
            .map { CompanyFreq(name: $0.key, count: $0.value) }
    }

    // MARK: - City/Company Frequencies
    private func cityFreqList() -> [(city: String, count: Int)] {
        let allCities = jobStore.jobApplications.map { $0.location }
        let freq = Dictionary(grouping: allCities, by: { $0 }).mapValues { $0.count }
        let arr = freq.map { ($0.key, $0.value) }
        return arr.sorted { $0.1 > $1.1 }
    }

    private func companyFreqList() -> [(name: String, count: Int)] {
        let allCompanies = jobStore.jobApplications.map { $0.companyName }
        let freq = Dictionary(grouping: allCompanies, by: { $0 }).mapValues { $0.count }
        let arr = freq.map { ($0.key, $0.value) }
        return arr.sorted { $0.1 > $1.1 }
    }

    // MARK: - Simple Helpers
    private func topCompanyName() -> String {
        let freq = companyFreqList()
        return freq.first?.name ?? "N/A"
    }

    private func topCity() -> (String, Int) {
        let freq = cityFreqList()
        if let top = freq.first {
            return (top.city, top.count)
        }
        return ("N/A", 0)
    }

    private func weekday(for date: Date) -> Int {
        Calendar.current.component(.weekday, from: date)
    }

    private func shortWeekdaySymbol(_ weekday: Int) -> String? {
        let syms = Calendar.current.shortWeekdaySymbols
        guard weekday - 1 >= 0, weekday - 1 < syms.count else { return nil }
        return syms[weekday - 1]
    }



    private func monthName(_ m: Int) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"
        if let d = Calendar.current.date(from: DateComponents(year: 2023, month: m, day: 1)) {
            return fmt.string(from: d)
        }
        return ""
    }

    private func selectedYearText() -> String {
        selectedYear == -1 ? "All" : "\(selectedYear)"
    }

    // For the squares in the GitHub chart, choose a gradient
    @available(macOS 13.0, *)
    private var chartColors: [Color] {
        [
            .green.opacity(0.2),
            .green.opacity(0.4),
            .green.opacity(0.6),
            .green.opacity(0.8),
            .green
        ]
    }
}

// MARK: - Extension: Horizontal Scrolling for “All Years”
@available(macOS 13.0, *)
extension View {
    /// Conditionally enable horizontal scrolling on macOS 14+ if `selectedYear == -1`.
    @ViewBuilder
    func ifShouldScrollHorizontally(selectedYear: Int) -> some View {
        if #available(macOS 14.0, *), selectedYear == -1 {
            self.chartScrollableAxes(.horizontal)
        } else {
            self
        }
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
          .onAppear {
            locations = CityCoordinateDictionary.keys.sorted()
        }
         .quickLookPreview($quickLookURL)
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

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .textCase(.uppercase)
    }
}
```

After applying these changes, please rebuild the Xcode project. All the listed errors should be resolved.

**5. Documentation of Changes:**

Here's a summary of the changes made and why:

*   **`JobDetailView` Scope Fix (Lines 1993, 1996, 2000):**
    *   **Issue:** "Cannot find 'doc' in scope" errors within `Button` and `contextMenu` closures inside `ForEach(job.documents)`.
    *   **Solution:** Captured `doc` explicitly using `let currentDoc = doc` within the `ForEach` loop and used `currentDoc` in the closures.
    *   **Reasoning:** Resolved a scoping issue where the `doc` variable from `ForEach` was not correctly accessible within nested closures.

*   **`JobDetailView` Missing Brace (Line 2038):**
    *   **Issue:** "Expected declaration" error after `JobDetailView`.
    *   **Solution:** Added a closing brace `}` to the `ScrollView` in `JobDetailView`'s `body`.
    *   **Reasoning:** Corrected a syntax error caused by a missing closing brace, ensuring a valid SwiftUI view hierarchy.

*   **`DocumentsMainView` Scope Fix (Lines 2068, 2069 x2, 2090, 2095):**
    *   **Issue:** "Cannot find 'windowRef'", "Cannot find 'job'", "Cannot find 'quickLookURL'" in `DocumentsMainView`'s `.onAppear` and `.onChange`.
    *   **Solution:** Used `self.windowRef` and `self.quickLookURL` to correctly reference state variables and corrected typo `job` to `doc` in `updateWindowTitle` calls.
    *   **Reasoning:** Ensured state variables were correctly accessed within the closures and corrected a parameter name typo.

*   **`NewLocationView` Not Found (Line 2327):**
    *   **Issue:** "Cannot find 'NewLocationView' in scope" in `AddJobView`.
    *   **Solution:** Moved the `NewLocationView` struct definition to be declared *before* `AddJobView` in the file.
    *   **Reasoning:** While not strictly necessary in Swift in most cases, in complex SwiftUI files, moving the definition earlier can resolve potential compiler parsing order issues.

*   **`EnhancedStatsView` Type-Check Timeout (Line 3679):**
    *   **Issue:** "Compiler unable to type-check this expression in reasonable time".
    *   **Solution:** Explicitly cast `dayItem.count` to `NSNumber` in `BarMark` of `barLineChartsSection` in `EnhancedStatsView`.
    *   **Reasoning:** Provided more explicit type information to the Swift Charts framework, helping the compiler with type inference in a complex expression.

*   **`EnhancedStatsView` Incorrect `private` Usage (Lines 3955, 3969, 3975, 3995):**
    *   **Issue:** "Attribute 'private' can only be used in a non-local scope" errors in `EnhancedStatsView`.
    *   **Solution:** Removed the `private` keywords from the functions `buildAngleRanges`, `selectedMonthItem`, `selectedCityItem`, `selectedYearItem` and `AngleRangeItem` struct declaration within `EnhancedStatsView`.
    *   **Reasoning:** Corrected the misuse of `private` access modifier which is not applicable in local scopes like computed properties' implementations or for nested structs within a view's scope.

*   **`NewLocationView` Missing Brace (Line 4067):**
    *   **Issue:** "Expected '}' in struct" for `NewLocationView`.
    *   **Solution:** Added a closing brace `}` at the end of the `NewLocationView` struct definition.
    *   **Reasoning:** Corrected a basic syntax error by adding the missing closing brace, completing the struct definition.

After these fixes, the codebase should be error-free and ready to build and run on Xcode 16 targeting macOS Sequoia. Please test the application to ensure all functionalities are working as expected.
