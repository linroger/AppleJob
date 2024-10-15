// Place these imports at the top
import SwiftUI
import AppKit
import Cocoa

// Existing code...

// Add the AppDelegate class
class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        NotificationCenter.default.post(name: .didOpenCustomURL, object: url)
    }
}

// Add this extension for notification name
extension Notification.Name {
    static let didOpenCustomURL = Notification.Name("didOpenCustomURL")
}

@main
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
                    if let url = notification.object as? URL {
                        handleIncomingURL(url)
                    }
                }
        }
        .commands {
            // Existing commands...
        }
    }
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "applejob" else { return }
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let jsonParam = components.queryItems?.first(where: { $0.name == "json" })?.value,
           let jsonDecoded = jsonParam.removingPercentEncoding?.data(using: .utf8) {
            do {
                if let dict = try JSONSerialization.jsonObject(with: jsonDecoded, options: []) as? [String: Any] {
                    jobStore.incomingJobData = dict
                    jobStore.isAddingNewJob = true
                }
            } catch {
                print("Error parsing job data from extension: \(error)")
            }
        }
    }
    // Existing code...
}

// Modify JobStore
class JobStore: ObservableObject {
    @Published var jobApplications: [JobApplication] = []
    @Published var selectedJob: JobApplication? = nil
    @Published var isAddingNewJob = false
    @Published var isEditingJob = false
    @Published var sorting: Sort = .recentlyApplied
    @Published var incomingJobData: [String: Any]? = nil

    // Existing methods...
}

// Modify JobViewModel
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
    @Published var jobDescriptionRTF: NSAttributedString = NSAttributedString(string: "")
    @Published var coverLetterRTF: NSAttributedString = NSAttributedString(string: "")
    @Published var notesRTF: NSAttributedString = NSAttributedString(string: "")
    @Published var isInputValid: Bool = false

    init() {
        validateInputs()
    }

    init(jobData: [String: Any]) {
        companyName = jobData["companyName"] as? String ?? ""
        jobTitle = jobData["jobTitle"] as? String ?? ""
        linkToJob = jobData["url"] as? String ?? ""
        jobDescription = jobData["jobDescription"] as? String ?? ""
        jobDescriptionRTF = NSAttributedString(string: jobDescription)
        validateInputs()
    }

    func validateInputs() {
        DispatchQueue.main.async {
            self.isInputValid = !(self.companyName.isEmpty || self.jobTitle.isEmpty)
        }
    }

    // Existing methods...
}

// Modify AddJobView
struct AddJobView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var isPresented: Bool
    @StateObject private var viewModel: JobViewModel

    init(isPresented: Binding<Bool>, jobData: [String: Any]? = nil) {
        self._isPresented = isPresented
        if let data = jobData {
            _viewModel = StateObject(wrappedValue: JobViewModel(jobData: data))
        } else {
            _viewModel = StateObject(wrappedValue: JobViewModel())
        }
    }

    var body: some View {
        // Existing UI code...
    }
}

// Modify JobSidebarView
struct JobSidebarView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    @Binding var searchText: String

    var body: some View {
        // Existing code...

        .sheet(isPresented: $jobStore.isAddingNewJob) {
            AddJobView(isPresented: $jobStore.isAddingNewJob, jobData: jobStore.incomingJobData)
                .environmentObject(jobStore)
                .environmentObject(docStore)
                .onDisappear {
                    jobStore.incomingJobData = nil
                }
        }

        // Existing code...
    }

    // Existing methods...
}

// Modify buildJobFromDictionary (if you still need it)
private func buildJobFromDictionary(_ dict: [String: Any]) -> JobApplication {
    let jobTitle = dict["jobTitle"] as? String ?? "Untitled"
    let company = dict["companyName"] as? String ?? "(Unknown)"
    let link = dict["url"] as? String
    let jobDescription = dict["jobDescription"] as? String ?? ""
    return JobApplication(
        companyName: company,
        jobTitle: jobTitle,
        status: .interested,
        dateOfApplication: Date(),
        location: "",
        linkToJobString: link,
        jobDescription: jobDescription,
        coverLetter: "",
        notes: nil,
        jobDescriptionRTFData: nil,
        coverLetterRTFData: nil,
        notesRTFData: nil,
        documents: [],
        isFavorite: false
    )
}

// Existing code continues...

