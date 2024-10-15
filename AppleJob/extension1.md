
<AppDelegate.swift>
//
//  AppDelegate.swift
//  SafariAppExtensionTester
//
//  Created by Roger Lin on 1/16/25.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Optionally customize after application launch
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

</AppDelegate.swift>

<ContentScript.js>
//
//  ContentScript.js
//  SafariAppExtensionTester
//
//  Created by Roger Lin on 1/16/25.
//


// ContentScript.js
// This script automatically runs on pages (once the user enables "Allow on all websites" or specific domains).
// It looks for <script type="application/ld+json"> with @type=JobPosting, extracts relevant fields, 
// then dispatches a message to our Safari extension.

(function() {
    console.log("[SafariAppExtensionTester] Content script loaded on", window.location.href);

    // Minimal function that attempts to parse JSON-LD and look for JobPosting data
    function parseJobPostingsFromLDJSON() {
        const results = [];
        const scripts = document.querySelectorAll('script[type="application/ld+json"]');
        scripts.forEach(s => {
            try {
                const data = JSON.parse(s.textContent.trim());
                const items = Array.isArray(data) ? data : [data];
                items.forEach(item => {
                    if (item["@type"] === "JobPosting") {
                        // We'll store only a few fields
                        const jobObj = {
                            title: item.title || "",
                            description: item.description || "",
                            identifier: "",
                            url: item.url || ""
                        };
                        // If item.identifier is an object with .value, we grab that
                        if (typeof item.identifier === "object" && item.identifier.value) {
                            jobObj.identifier = item.identifier.value;
                        } else if (typeof item.identifier === "string") {
                            jobObj.identifier = item.identifier;
                        }
                        results.push(jobObj);
                    }
                });
            } catch (err) {
                // Could not parse JSON or it wasn't valid JobPosting data
            }
        });
        return results;
    }

    const foundJobData = parseJobPostingsFromLDJSON();
    if (foundJobData.length > 0) {
        // Dispatch to the Safari extension using the old Safari App Extension API
        safari.extension.dispatchMessage("JOB_POSTINGS", { jobData: foundJobData });
        console.log("[SafariAppExtensionTester] Found job postings:", foundJobData);
    }
})();

</ContentScript.js>

<JobPosting.swift>
import Foundation

struct JobPosting {
    var companyName: String
    var jobTitle: String
    var jobDescription: String
    var url: String
    var otherFields: [String: Any]

    init(dictionary: [String: Any]) {
        self.jobTitle = dictionary["title"] as? String ?? "Unknown Title"
        self.jobDescription = dictionary["description"] as? String ?? "No description"
        self.companyName = (dictionary["hiringOrganization"] as? [String: Any])?["name"] as? String ?? "Unknown Company"
        self.url = dictionary["url"] as? String ?? "No URL"
        self.otherFields = dictionary.filter { !["title", "description", "hiringOrganization", "url"].contains($0.key) }
    }
}

</JobPosting.swift>

<JobPostingsModel.swift>
//
//  JobPostingsModel.swift
//  SafariAppExtensionTester
//
//  Created by Roger Lin on 1/16/25.
//


import SwiftUI

class JobPostingsModel: ObservableObject {
    @Published var postings: [JobPosting] = SafariExtensionHandler.extractedJobPostings
}

struct JobPostingListView: View {
    @StateObject private var model = JobPostingsModel()

    var body: some View {
        VStack {
            if model.postings.isEmpty {
                Text("No JobPosting data found on this page.")
                    .padding()
            } else {
                ForEach(model.postings.indices, id: \.self) { index in
                    SingleJobPostingView(posting: $model.postings[index])
                    Divider().padding(.vertical, 8)
                }
            }
        }
        .onAppear {
            model.postings = SafariExtensionHandler.extractedJobPostings
        }
        .padding()
    }
}
</JobPostingsModel.swift>

<SafariExtensionHandler.swift>
import SafariServices
import os.log

class SafariExtensionHandler: SFSafariExtensionHandler {
    static var extractedJobPostings: [JobPosting] = []

    override func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem
        let profile: UUID?

        if #available(iOS 17.0, macOS 14.0, *) {
            profile = request?.userInfo?[SFExtensionProfileKey] as? UUID
        } else {
            profile = request?.userInfo?["profile"] as? UUID
        }

        os_log(.default, "beginRequest received for profile: %@", profile?.uuidString ?? "none")
    }

    override func messageReceived(withName messageName: String,
                                  from page: SFSafariPage,
                                  userInfo: [String: Any]?) {
        page.getPropertiesWithCompletionHandler { properties in
            os_log(.default,
                   "messageReceived name=%@ from page=%@ userInfo=%@",
                   messageName,
                   String(describing: properties?.url),
                   userInfo ?? [:])

            if messageName == "jobPostingData", let jobDataArray = userInfo?["jobPostings"] as? [[String: Any]] {
                var jobPostings: [JobPosting] = []

                for singleJobData in jobDataArray {
                    let jobPosting = JobPosting(dictionary: singleJobData)
                    jobPostings.append(jobPosting)
                }

                SafariExtensionHandler.extractedJobPostings = jobPostings
            }
        }
    }

    override func toolbarItemClicked(in window: SFSafariWindow) {
        os_log(.default, "The extension's toolbar item was clicked")
        window.getToolbarItem { toolbarItem in
            if let toolbarItem = toolbarItem {
                toolbarItem.showPopover()
            } else {
                os_log(.error, "Toolbar item not found")
            }
        }
    }

    override func validateToolbarItem(in window: SFSafariWindow,
                                      validationHandler: @escaping ((Bool, String) -> Void)) {
        validationHandler(true, "")
    }

    override func popoverViewController() -> SFSafariExtensionViewController {
        return SafariExtensionViewController.shared
    }
}

</SafariExtensionHandler.swift>

<SafariExtensionViewController.swift>
import SafariServices
import SwiftUI

class SafariExtensionViewController: SFSafariExtensionViewController {
    static let shared: SafariExtensionViewController = {
        let controller = SafariExtensionViewController()
        controller.preferredContentSize = NSSize(width: 400, height: 400)
        return controller
    }()

    override func loadView() {
        self.view = NSHostingView(rootView: JobPostingListView())
        self.view.wantsLayer = true
        self.view.layer?.cornerRadius = 10
    }
}

</SafariExtensionViewController.swift>

<Script.js>
function show(enabled, useSettingsInsteadOfPreferences) {
    if (useSettingsInsteadOfPreferences) {
        document.getElementsByClassName('state-on')[0].innerText =
            "SafariAppExtensionTester’s extension is currently on. You can turn it off in the Extensions section of Safari Settings.";
        document.getElementsByClassName('state-off')[0].innerText =
            "SafariAppExtensionTester’s extension is currently off. You can turn it on in the Extensions section of Safari Settings.";
        document.getElementsByClassName('state-unknown')[0].innerText =
            "You can turn on SafariAppExtensionTester’s extension in the Extensions section of Safari Settings.";
        document.getElementsByClassName('open-preferences')[0].innerText =
            "Quit and Open Safari Settings…";
    }

    // If “enabled” is a boolean, show the correct state
    if (typeof enabled === "boolean") {
        document.body.classList.toggle("state-on", enabled);
        document.body.classList.toggle("state-off", !enabled);
    } else {
        // If it's undefined, we show "unknown"
        document.body.classList.remove("state-on");
        document.body.classList.remove("state-off");
    }
}

function openPreferences() {
    // Post a message to the WKWebView “controller” to open Safari preferences
    webkit.messageHandlers.controller.postMessage("open-preferences");
}

document.querySelector("button.open-preferences").addEventListener("click", openPreferences);

</Script.js>

<SingleJobPostingView.swift>
//
//  SingleJobPostingView.swift
//  SafariAppExtensionTester
//
//  Created by Roger Lin on 1/16/25.
//


import SwiftUI

struct SingleJobPostingView: View {
    @Binding var posting: JobPosting
    @State private var showSaveConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Company Name", text: $posting.companyName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Job Title", text: $posting.jobTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("URL", text: $posting.url)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Text("Job Description:")
            TextEditor(text: $posting.jobDescription)
                .frame(minHeight: 80)
                .border(Color.gray, width: 1)

            HStack {
                Button("Cancel") {
                    NSApplication.shared.keyWindow?.close()
                }
                Spacer()
                Button("Save") {
                    self.showSaveConfirmation = true
                }
            }
        }
        .alert(isPresented: $showSaveConfirmation) {
            Alert(title: Text("Saved"),
                  message: Text("Your changes were saved."),
                  dismissButton: .default(Text("OK")))
        }
    }
}
</SingleJobPostingView.swift>

<Style.css>
* {
    -webkit-user-select: none;
    -webkit-user-drag: none;
    cursor: default;
}

:root {
    color-scheme: light dark;
    --spacing: 20px;
}

html {
    height: 100%;
}

body {
    display: flex;
    align-items: center;
    justify-content: center;
    flex-direction: column;

    gap: var(--spacing);
    margin: 0 calc(var(--spacing) * 2);
    height: 100%;

    font: -apple-system-short-body;
    text-align: center;
}

body:not(.state-on, .state-off) .state-on,
body:not(.state-on, .state-off) .state-off {
    display: none;
}

body.state-on .state-off,
body.state-on .state-unknown {
    display: none;
}

body.state-off .state-on,
body.state-off .state-unknown {
    display: none;
}

button {
    font-size: 1em;
}

</Style.css>

<ViewController.swift>
//
//  ViewController.swift
//  SafariAppExtensionTester
//
//  Created by Roger Lin on 1/16/25.
//

import Cocoa
import SafariServices
import WebKit

// Update this to match your Safari App Extension's bundle identifier!
private let extensionBundleIdentifier = "swift.linroger023.SafariAppExtensionTester.Extension"

class ViewController: NSViewController, WKNavigationDelegate {

    // Optional WKWebView if your main window loads some local HTML UI
    @IBOutlet weak var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let webView = webView {
            webView.navigationDelegate = self

            // Load a local HTML file if you want a custom UI in the host app
            // (Not strictly required unless you want to replicate the default template's Main.html)
            if let localURL = Bundle.main.url(forResource: "Main", withExtension: "html") {
                webView.loadFileURL(localURL, allowingReadAccessTo: localURL.deletingLastPathComponent())
            }
        }
    }

    // Example method to open Safari preferences for this extension
    @IBAction func openSafariExtensionPreferences(_ sender: Any) {
        SFSafariApplication.showPreferencesForExtension(withIdentifier: extensionBundleIdentifier) { error in
            if let error = error {
                NSLog("Error opening Safari extension preferences: \(error)")
            }
        }
    }
}

</ViewController.swift>

<script 2.js>
 (function() {
     const ldJsonScripts = document.querySelectorAll('script[type="application/ld+json"]');
     let jobPostings = [];

     ldJsonScripts.forEach((element) => {
         try {
             const data = JSON.parse(element.textContent);
             const dataArray = Array.isArray(data) ? data : [data];

             dataArray.forEach(obj => {
                 if (obj["@type"] && obj["@type"] === "JobPosting") {
                     jobPostings.push(obj);
                 }
             });
         } catch (e) {
             console.error("Error parsing JSON-LD: ", e);
         }
     });

     if (jobPostings.length > 0 && safari.extension) {
         safari.extension.dispatchMessage("jobPostingData", {
             jobPostings: jobPostings
         });
     }
 })();

</script 2.js>





