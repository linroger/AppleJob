//
//  Item.swift
//  Experimental-alpha
//
//  Created by Roger Lin on 2/28/25.
//

import Foundation
import SwiftData
import SwiftUI
import Charts
import SwiftSoup

// Create a simple test view to verify LinkedIn insights import
struct LinkedInInsightsTester: View {
    @State private var isImporting = false
    @State private var parsedData: LinkedInInsightsData?
    @State private var errorMessage: String?
    @State private var rawHTML: String?
    @State private var showRawHTML = false
    
    var body: some View {
        VStack {
            Text("LinkedIn Insights Import Tester")
                .font(.title)
                .padding()
            
            Button("Import HTML File") {
                isImporting = true
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
                
                if let rawHTML = rawHTML, !rawHTML.isEmpty {
                    Button("Show Raw HTML") {
                        showRawHTML.toggle()
                    }
                    .padding()
                    
                    if showRawHTML {
                        ScrollView {
                            Text(rawHTML.prefix(500) + "...")
                                .font(.system(.body, design: .monospaced))
                                .padding()
                        }
                        .frame(height: 200)
                    }
                }
            }
            
            if let data = parsedData {
                Text("Data parsed successfully!")
                    .foregroundColor(.green)
                    .padding()
                
                // Display simple information to verify data is parsed correctly
                VStack(alignment: .leading) {
                    if let totalEmployees = data.totalEmployees["total_employees"] {
                        Text("Total Employees: \(totalEmployees)")
                    }
                    
                    if let medianTenure = data.medianTenure {
                        Text("Median Tenure: \(medianTenure)")
                    }
                    
                    if !data.employeeGrowth.isEmpty {
                        Text("Employee Growth Points: \(data.employeeGrowth.count)")
                    }
                    
                    if !data.functionDistribution.isEmpty {
                        Text("Function Distribution Categories: \(data.functionDistribution.count)")
                    }
                }
                .padding()
                
                ScrollView {
                    VisualizerView(data: data)
                        .padding()
                }
            } else {
                Text("No data imported yet")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.html]
        ) { result in
            switch result {
            case .success(let url):
                errorMessage = nil
                
                // Ensure we have access to the security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    errorMessage = "Failed to access the security scoped resource"
                    return
                }
                
                // Use defer to ensure we stop accessing the resource at the end of this scope
                defer {
                    url.stopAccessingSecurityScopedResource()
                }
                
                do {
                    // Read the file contents
                    let html = try String(contentsOf: url, encoding: .utf8)
                    rawHTML = html
                    
                    // Use the parseLinkedInInsights function that's properly defined in the main app file
                    parseLinkedInInsights(from: url) { result in
                        switch result {
                        case .success(let data):
                            self.parsedData = data
                        case .failure(let error):
                            self.errorMessage = "Parse error: \(error.localizedDescription)"
                        }
                    }
                } catch {
                    errorMessage = "Error reading file: \(error.localizedDescription)"
                }
                
            case .failure(let error):
                errorMessage = "Failed to select file: \(error.localizedDescription)"
            }
        }
    }
}

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

struct LinkedInInsightsPreviewApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                LinkedInInsightsTester()
                    .tabItem {
                        Label("File Import Test", systemImage: "doc.text.magnifyingglass")
                    }
                
                LinkedInInsightsDebugView()
                    .tabItem {
                        Label("HTML Debug", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
            }
        }
    }
}
