//
//  SafariExtensionHandler.swift
//  AppleJobSafariExtension
//
//  Created by Roger Lin on [Date].
//  Implements a Safari app extension that parses job data from a webpage's schema 
//  and sends it to the macOS app via a custom URL scheme (applejob://).
//

import SafariServices
import Combine

// --------------------------------------------------------
// MARK: - SafariExtensionHandler
// --------------------------------------------------------
class SafariExtensionHandler: SFSafariExtensionHandler {

    // Called when the user clicks your toolbar button in Safari.
    override func toolbarItemClicked(in window: SFSafariWindow) {
        window.getActiveTab { [weak self] (activeTab) in
            guard let tab = activeTab else { return }
            
            // Inject JavaScript to parse the current webpage's schema
            tab.getActivePage { page in
                page?.dispatchMessageToScript(withName: "extractJobData", userInfo: nil)
            }
        }
    }
    
    // Called when your content script sends a message back to the extension.
    // We expect it to contain the job data we parsed from the webpage.
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        guard messageName == "jobDataExtracted" else { return }

        // userInfo should contain companyName, jobTitle, jobDescription, and url
        if let info = userInfo as? [String: String] {
            // Convert to JSON
            let payload: [String: String] = [
                "companyName": info["companyName"] ?? "",
                "jobTitle": info["jobTitle"] ?? "",
                "jobDescription": info["jobDescription"] ?? "",
                "url": info["url"] ?? ""
            ]
            if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
               let jsonString = String(data: jsonData, encoding: .utf8)?
                                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {

                // Construct the custom URL -> applejob://?json=...
                // Opening this URL will launch the macOS app, 
                // which is configured to handle the applejob:// scheme.
                let customURLString = "applejob://?json=\(jsonString)"
                if let customURL = URL(string: customURLString) {
                    // Safari won't directly open it in the extension, but 
                    // we can request to open it, prompting the user to confirm.
                    SFSafariApplication.openWindow(with: customURL) { _ in
                        // Optionally do something after opening...
                    }
                }
            }
        }
    }
    
    // You could also override other extension methods if needed (e.g., validateToolbarItem).
}

// --------------------------------------------------------
// MARK: - Content Script Injection (Inline Example)
// --------------------------------------------------------
/**
 Normally, you'd store your content script in a separate .js file inside the extension's 
 Resources folder and reference it in your Extension's Info.plist under `SFSafariContentScript`.
 For demonstration, here's the essential logic as an inline string:

 - We listen for "extractJobData" from the extension.
 - We parse the DOM for JSON-LD or microdata about the job posting.
 - We send the extracted data back with message name "jobDataExtracted".

 Below is a minimal outline. In practice, you'd parse the actual schema more robustly.
 */
let contentScriptSource = """
(function() {
    // Listen for the extension's message
    safari.runtime.onMessage.addListener((message, sender, sendResponse) => {
        if (message.name === 'extractJobData') {
            // Attempt to find JSON-LD script with type "application/ld+json"
            let jobData = {
                companyName: '',
                jobTitle: '',
                jobDescription: '',
                url: window.location.href
            };
            
            // 1) Grab all <script type="application/ld+json"> blocks
            const ldJsonScripts = document.querySelectorAll('script[type="application/ld+json"]');
            for (const script of ldJsonScripts) {
                try {
                    const dataObj = JSON.parse(script.innerText);
                    // dataObj might be an array or an object, so handle both
                    const items = Array.isArray(dataObj) ? dataObj : [dataObj];
                    for (const item of items) {
                        // Heuristically check if it's a job posting schema
                        if (item['@type'] && (item['@type'].toLowerCase() === 'jobposting')) {
                            jobData.companyName = item.hiringOrganization?.name || item.name || '';
                            jobData.jobTitle = item.title || '';
                            jobData.jobDescription = item.description || '';
                            break;
                        }
                    }
                } catch(e) {
                    // Ignore JSON parse errors
                }
            }

            // 2) Or optionally parse microdata / RDFa if needed (omitted for brevity)
            // ...

            // Send job data to the extension background script
            safari.runtime.sendMessage({
                name: 'jobDataExtracted',
                userInfo: jobData
            });
        }
    });
})();
""";

/**
 You add the above `contentScriptSource` to your extension's Info.plist as a content script, 
 or store it in a .js file in the extension’s Resources, 
 ensuring it's injected into every page or specifically matched domains.

 That injection method is determined by your Safari Extension target setup in Xcode's 
 “Build Settings” and Info.plist under `SFSafariContentScript`.
 */