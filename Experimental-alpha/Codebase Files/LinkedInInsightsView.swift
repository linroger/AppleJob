//
//  LinkedInInsightsView.swift
//  Experimental-alpha
//
//  Created by Roger Lin on 3/14/25.
//


// -----------------------------------------------------------------------------
// MARK: - LinkedInInsightsView
// -----------------------------------------------------------------------------
import SwiftUI
import AppKit
import UniformTypeIdentifiers
import PDFKit
import MapKit
import Charts
import Quartz
import QuickLook
import QuickLookUI
import MarkdownUI  // Replacing MarkdownKit with MarkdownUI
import SwiftData
import SwiftSoup  // For LinkedIn HTML parsing
import WebKit     // For WebView to automate LinkedIn access


// MARK: - LinkedInInsightsView


struct LinkedInInsightsView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    let insightsData: LinkedInInsightsData
    @State private var selectedTab = 0
    @State private var chartHeight: CGFloat = 250
    @State private var selectedHeadcountDate: Date?
    @State private var selectedHiringDate: Date?
    @State private var selectedDataPoint: (String, Double)?

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("LinkedIn Insights: \(insightsData.companyName ?? "")")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                if let importDate = insightsData.importDate {
                    Text("Imported: \(formatDate(importDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)

            TabView(selection: $selectedTab) {
                // Growth
                employeeGrowthView
                    .tabItem {
                        Label("Growth", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(0)
                // Composition
                compositionView
                    .tabItem {
                        Label("Composition", systemImage: "chart.pie")
                    }
                    .tag(1)
                // Hiring
                hiringView
                    .tabItem {
                        Label("Hiring", systemImage: "person.badge.plus")
                    }
                    .tag(2)
                // Jobs
                jobsView
                    .tabItem {
                        Label("Jobs", systemImage: "briefcase")
                    }
                    .tag(3)
            }
            .frame(height: 350)
            .padding(.vertical)
            .cornerRadius(10)
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private var employeeGrowthView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Employee Growth").font(.title3).bold()
            if !insightsData.employeeGrowth.isEmpty,
               insightsData.employeeGrowth.contains(where: { $0.date != nil }) {
                if #available(macOS 13.0, *) {
                    // Enhanced chart using EmployeeGrowthChart for macOS 13+
                    EmployeeGrowthChart(employeeGrowth: insightsData.employeeGrowth)
                } else {
                    // Basic chart for earlier macOS versions
                    Chart {
                        ForEach(insightsData.employeeGrowth.filter { $0.date != nil }, id: \.id) { item in
                            if let dt = item.date {
                                LineMark(x: .value("Date", dt), y: .value("Employees", item.employeeCount))
                                    .foregroundStyle(.blue)
                                    .interpolationMethod(.catmullRom)
                                PointMark(x: .value("Date", dt), y: .value("Employees", item.employeeCount))
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .chartYScale(domain: .automatic(includesZero: false))
                    .chartYAxis {
                        AxisMarks(position: .leading) {
                            AxisValueLabel()
                            AxisGridLine()
                            AxisTick()
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) {
                            AxisValueLabel(format: .dateTime.month().year())
                            AxisGridLine()
                            AxisTick()
                        }
                    }
                    .frame(height: chartHeight)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
            } else {
                Text("No employee growth data available").foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if let totalEmp = insightsData.totalEmployees["total_employees"] {
                    Text("Total Employees: \(totalEmp)")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                if let median = insightsData.medianTenure {
                    Text("Median Tenure: \(median)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding(.top, 8)
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.2))
        .cornerRadius(10)
    }

    private var compositionView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Company Composition").font(.title3).bold()
            if !insightsData.functionDistribution.isEmpty {
                if #available(macOS 13.0, *) {
                    // Enhanced chart with new FunctionDistributionChart
                    FunctionDistributionChart(distribution: insightsData.functionDistribution)
                } else {
                    // Fallback grid layout for earlier macOS versions
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                            ForEach(insightsData.functionDistribution.sorted { $0.value > $1.value }, id: \.key) { (funcName, pct) in
                                HStack {
                                    Text(funcName)
                                        .lineLimit(1)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(pct)
                                        .bold()
                                        .foregroundColor(.blue)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .frame(height: 280)
                }
            } else {
                Text("No composition data available").foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.2))
        .cornerRadius(10)
    }

    private var hiringView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Hiring Trends").font(.title3).bold()
            if !insightsData.newHires.isEmpty {
                if #available(macOS 13.0, *) {
                    NewHiresChart(newHires: insightsData.newHires)
                        .frame(height: 320)
                } else {
                    // Fallback table view for macOS 12 and earlier
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(insightsData.newHires.sorted { $0.date > $1.date }) { hire in
                                HStack {
                                    Text(hire.date)
                                        .frame(width: 100, alignment: .leading)
                                        .fontWeight(.medium)
                                    Divider()
                                    VStack(alignment: .leading) {
                                        if hire.seniorHires != "0" {
                                            HStack {
                                                Circle()
                                                    .fill(Color.orange)
                                                    .frame(width: 8, height: 8)
                                                Text("Senior: \(hire.seniorHires)")
                                                    .foregroundColor(.orange)
                                            }
                                        }
                                        HStack {
                                            Circle()
                                                .fill(Color.green)
                                                .frame(width: 8, height: 8)
                                            Text("Other: \(hire.otherHires)")
                                                .foregroundColor(.green)
                                        }
                                        
                                        if let senior = Int(hire.seniorHires), let other = Int(hire.otherHires) {
                                            Text("Total: \(senior + other)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(.top, 2)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .padding(.bottom, 4)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .frame(height: 280)
                }
            } else {
                Text("No hiring data available").foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.2))
        .cornerRadius(10)
    }

    private var jobsView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Job Openings").font(.title3).bold()
            if !insightsData.jobOpenings.openingsDetails.isEmpty {
                if #available(macOS 13.0, *) {
                    // Use the enhanced table view for macOS 13+
                    JobOpeningsDetailsTable(details: insightsData.jobOpenings.openingsDetails)
                } else {
                    // Fallback table view for earlier macOS versions
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(insightsData.jobOpenings.openingsDetails) { detail in
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(detail.function)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    HStack {
                                        Text("Count: \(detail.numEmployees)")
                                            .font(.subheadline)
                                        Spacer()
                                        HStack(spacing: 4) {
                                            Image(systemName: detail.growth3m.contains("increase") ? "arrow.up" : detail.growth3m.contains("decrease") ? "arrow.down" : "minus")
                                                .font(.caption2)
                                            Text("3m: \(cleanDuplicatedText(detail.growth3m))")
                                        }
                                        .foregroundColor(detail.growth3m.contains("increase") ? .green : detail.growth3m.contains("decrease") ? .red : .primary)
                                        Spacer()
                                        HStack(spacing: 4) {
                                            Image(systemName: detail.growth6m.contains("increase") ? "arrow.up" : detail.growth6m.contains("decrease") ? "arrow.down" : "minus")
                                                .font(.caption2)
                                            Text("6m: \(cleanDuplicatedText(detail.growth6m))")
                                        }
                                        .foregroundColor(detail.growth6m.contains("increase") ? .green : detail.growth6m.contains("decrease") ? .red : .primary)
                                    }
                                    .font(.caption)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .padding(.bottom, 4)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .frame(height: 280)
                }
            } else if !insightsData.jobOpeningsPlainText.isEmpty {
                if #available(macOS 13.0, *) {
                    // Use the enhanced bottom table view for macOS 13+
                    JobOpeningsBottomTable(plainText: insightsData.jobOpeningsPlainText)
                } else {
                    // Fallback table view for earlier macOS versions
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(insightsData.jobOpeningsPlainText) { detail in
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(detail.function)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    HStack {
                                        Text("Count: \(detail.numEmployees)")
                                            .font(.subheadline)
                                        Spacer()
                                        HStack(spacing: 4) {
                                            Image(systemName: detail.growth3m.contains("increase") ? "arrow.up" : detail.growth3m.contains("decrease") ? "arrow.down" : "minus")
                                                .font(.caption2)
                                            Text("3m: \(cleanDuplicatedText(detail.growth3m))")
                                        }
                                        .foregroundColor(detail.growth3m.contains("increase") ? .green : detail.growth3m.contains("decrease") ? .red : .primary)
                                        Spacer()
                                        HStack(spacing: 4) {
                                            Image(systemName: detail.growth6m.contains("increase") ? "arrow.up" : detail.growth6m.contains("decrease") ? "arrow.down" : "minus")
                                                .font(.caption2)
                                            Text("6m: \(cleanDuplicatedText(detail.growth6m))")
                                        }
                                        .foregroundColor(detail.growth6m.contains("increase") ? .green : detail.growth6m.contains("decrease") ? .red : .primary)
                                    }
                                    .font(.caption)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .padding(.bottom, 4)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .frame(height: 280)
                }
            } else {
                Text("No job openings data available").foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.2))
        .cornerRadius(10)
    }

    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: date)
    }
}


// --------------------------------------------------
// MARK: - LinkedIn Insights Import and Visualization

// Helper function to parse LinkedIn insights HTML files
func parseLinkedInInsights(from url: URL, completion: @escaping (Result<LinkedInInsightsData, Error>) -> Void) {
    do {
        // First, get security-scoped access to the file
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access the security scoped resource")
            completion(.failure(NSError(domain: "LinkedInInsightsParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to access the security scoped resource"])))
            return
        }
        
        // Read the HTML content and parse it
        let html = try String(contentsOf: url, encoding: .utf8)
        
        // Log the file path and size for debugging
        print("Successfully read HTML file: \(url.path)")
        print("HTML content size: \(html.count) characters")
        
        // Parse the data from the HTML string
        parseLinkedInInsightsFromHTML(html, completion: completion)
        
        // Stop accessing the security-scoped resource
        url.stopAccessingSecurityScopedResource()
    } catch {
        // Stop accessing in case of error
        url.stopAccessingSecurityScopedResource()
        print("Error processing HTML file: \(error)")
        completion(.failure(error))
    }
}

// Helper function to parse LinkedIn insights from HTML string
func parseLinkedInInsightsFromHTML(_ html: String, completion: @escaping (Result<LinkedInInsightsData, Error>) -> Void) {
    do {
        // Try to parse the data
        let data = try extractData(from: html)
        
        // Log successful parsing
        print("Successfully parsed LinkedIn insights data")
        print("Employee growth points: \(data.employeeGrowth.count)")
        print("Function distribution categories: \(data.functionDistribution.count)")
        if let totalEmployees = data.totalEmployees["total_employees"] {
            print("Total employees: \(totalEmployees)")
        }
        
        completion(.success(data))
    } catch {
        print("Error parsing LinkedIn insights: \(error)")
        completion(.failure(error))
    }
}

// A debug view that lets you input a sample HTML to test parsing
struct LinkedInInsightsDebugView: View {
    @State private var sampleHTML = "<!-- Paste LinkedIn Insights HTML here -->"
    @State private var parsedData: LinkedInInsightsData?
    @State private var errorMessage: String?
    @State private var isParsing = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("LinkedIn Insights HTML Debugger")
                .font(.title)
                .padding(.top)
            
            Text("Enter LinkedIn Insights HTML below:")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            TextEditor(text: $sampleHTML)
                .font(.system(.body, design: .monospaced))
                .frame(height: 200)
                .border(Color.gray, width: 1)
                .padding(.horizontal)
            
            Button(action: {
                errorMessage = nil
                parsedData = nil
                isParsing = true
                
                // Parse the HTML
                parseLinkedInInsightsFromHTML(sampleHTML) { result in
                    isParsing = false
                    switch result {
                    case .success(let data):
                        parsedData = data
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }) {
                Text("Parse HTML")
                    .frame(width: 150)
            }
            .buttonStyle(.borderedProminent)
            .disabled(sampleHTML.isEmpty || isParsing)
            
            if isParsing {
                ProgressView("Parsing...")
            } else if let errorMessage = errorMessage {
                VStack {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                }
            } else if let data = parsedData {
                VStack(alignment: .leading) {
                    Text("Parsing Successful!")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    if let totalEmployees = data.totalEmployees["total_employees"] {
                        Text("Total Employees: \(totalEmployees)")
                    }
                    
                    if !data.employeeGrowth.isEmpty {
                        Text("Employee Growth Data Points: \(data.employeeGrowth.count)")
                    }
                    
                    if !data.functionDistribution.isEmpty {
                        Text("Function Categories: \(data.functionDistribution.count)")
                    }
                    
                    HStack {
                        Spacer()
                        Button("View Visualizations") {
                            // Show visualizations
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }
                    .padding()
                }
                .padding()
                .background(Color(nsColor: .windowBackgroundColor))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

// Test view to verify LinkedIn Insights parsing
struct LinkedInInsightsTestView: View {
    @State private var isShowingFilePicker = false
    @State private var parsedData: LinkedInInsightsData?
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            Button("Import LinkedIn Insights HTML") {
                isShowingFilePicker = true
            }
            .buttonStyle(.bordered)
            .padding()
            
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }
            
            if let data = parsedData {
                Text("Data parsed successfully!")
                    .foregroundColor(.green)
                    .padding()
                
                ScrollView {
                    VisualizerView(data: data)
                        .padding()
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.html]
        ) { result in
            switch result {
            case .success(let url):
                errorMessage = nil
                parseLinkedInInsights(from: url) { parseResult in
                    switch parseResult {
                    case .success(let insightsData):
                        parsedData = insightsData
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
                
            case .failure(let error):
                errorMessage = "Failed to select file: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - LinkedIn Insights Visualization
// --------------------------------------------------

//
// MARK: - LinkedInInsights Visualization
// --------------------------------------------------

import SwiftUI
import Charts

// MARK: - Data Model Extension (Sample)
extension NewHire {
    var chartDate: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        return dateFormatter.date(from: date)
    }
}

// MARK: - Helper Function
private func cleanDuplicatedText(_ text: String) -> String {
    let patterns = [
        "([0-9]+%)[0-9]+% (increase|decrease)",
        "([0-9]+%) [0-9]+% (increase|decrease)"
    ]
    var result = text
    for pattern in patterns {
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let percentageRange = Range(match.range(at: 1), in: text),
           let typeRange = Range(match.range(at: 2), in: text) {
            let percentage = String(text[percentageRange])
            let type = String(text[typeRange])
            result = "\(percentage) \(type)"
        }
    }
    return result
}

// MARK: - Helper Views
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title2)
            .fontWeight(.bold)
            .padding(.top, 10)
    }
}

// MARK: - Chart Views
struct EmployeeGrowthChart: View {
    let employeeGrowth: [EmployeeGrowth]
    @State private var selectedDate: Date?
    @State private var scrollPosition: Date?
    
    private var visibleDomain: ClosedRange<Date> {
        if let start = validDataPoints.first?.date,
           let end = validDataPoints.last?.date {
            // View 6 months at a time by default
            let sixMonths = TimeInterval(60 * 60 * 24 * 30 * 6)
            if end.timeIntervalSince(start) > sixMonths {
                return (end.addingTimeInterval(-sixMonths))...end
            }
            return start...end
        }
        // Default range if we don't have data points
        let now = Date()
        let sixMonthsAgo = now.addingTimeInterval(-60 * 60 * 24 * 30 * 6)
        return sixMonthsAgo...now
    }

    private var validDataPoints: [EmployeeGrowth] {
        employeeGrowth.filter { $0.date != nil }.sorted { ($0.date ?? Date()) < ($1.date ?? Date()) }
    }

    private var yDomainRange: ClosedRange<Int> {
        if !validDataPoints.isEmpty,
           let minCount = validDataPoints.map({ $0.employeeCount }).min(),
           let maxCount = validDataPoints.map({ $0.employeeCount }).max() {
            let buffer = Double(maxCount - minCount) * 0.25
            let lowerBound = max(0, Int(Double(minCount) - buffer))
            let upperBound = Int(Double(maxCount) + buffer)
            return lowerBound...upperBound
        }
        return 0...100 // Default if no data
    }

    // Helper method to create line marks for data points
    @ChartContentBuilder
    private func chartLineMarks() -> some ChartContent {
        ForEach(validDataPoints, id: \.id) { item in
            if let itemDate = item.date {
                LineMark(
                    x: .value("Date", itemDate, unit: .day),
                    y: .value("Employee Count", item.employeeCount)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                .symbol {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                }
                .symbolSize(30)
                .interpolationMethod(.catmullRom)
            }
        }
    }
    
    // Helper method to create selection marks
    @ChartContentBuilder
    private func chartSelectionMarks() -> some ChartContent {
        if let selectedDate = selectedDate,
           let selectedItem = validDataPoints.first(where: {
               guard let itemDate = $0.date else { return false }
               return Calendar.current.isDate(itemDate, inSameDayAs: selectedDate)
           }) {
            
            RuleMark(
                x: .value("Selected", selectedDate)
            )
            .foregroundStyle(Color.gray.opacity(0.3))
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            .offset(yStart: -10)
            .zIndex(-1)
            .annotation(position: .top, spacing: 0,
                      overflowResolution: .init(
                          x: .fit(to: .chart),
                          y: .disabled
                      )) {
                AnnotationLabel(for: selectedItem)
            }
            
            PointMark(
                x: .value("Date", selectedDate),
                y: .value("Employee Count", selectedItem.employeeCount)
            )
            .foregroundStyle(Color(.systemRed))
            .symbolSize(100)
        }
    }
    
    // Helper method to create annotation label
    private func AnnotationLabel(for item: EmployeeGrowth) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(item.month) \(item.day), \(item.year ?? 2025)")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(item.employeeCount) employees")
                .font(.headline)
                .foregroundColor(.primary)
            if !item.growth.isEmpty {
                Text(item.growth)
                    .font(.caption)
                    .foregroundColor(item.growth.contains("increase") ? .green : .red)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(radius: 2)
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main chart - simplify by breaking down chart content into multiple parts
            Chart {
                // Base line chart
                chartLineMarks()
                
                // Selection marks - handle separately
                chartSelectionMarks()
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) {
                    AxisValueLabel(format: .dateTime.month().year())
                    AxisGridLine()
                    AxisTick()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisValueLabel()
                    AxisGridLine()
                    AxisTick()
                }
            }
            .chartYScale(domain: yDomainRange)
            .chartXScale(domain: visibleDomain)
            .chartXSelection(value: $selectedDate)
            .frame(height: 300)
            .padding(.horizontal, 16) // Standardized horizontal padding
            .padding(.vertical, 8)    // Standardized vertical padding
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .chartGesture { proxy in
                DragGesture(minimumDistance: 0)
                    .onChanged { proxy.selectXValue(at: $0.location.x) }
                    .onEnded { _ in /* Keep selection */ }
            }

            if let selectedDate = selectedDate,
               let item = validDataPoints.first(where: { Calendar.current.isDate($0.date!, inSameDayAs: selectedDate) }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Date: \(item.month) \(item.day), \(item.year ?? 2025)")
                            .font(.subheadline)
                        Text("Employees: \(item.employeeCount)")
                            .font(.title3)
                            .bold()
                        if !item.growth.isEmpty {
                            Text("Growth: \(item.growth)")
                                .foregroundColor(item.growth.contains("increase") ? .green : .red)
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .windowBackgroundColor).opacity(0.5)))
                .padding([.horizontal, .bottom])
            }
        }
    }
}

// MARK: - UPDATED FunctionDistributionChart
struct FunctionDistributionChart: View {
    let distribution: [String: String]
    @State private var selectedCategory: String?
    @State private var selectedAngle: Double?
    
    private var topFunction: String {
        chartData.first?.key ?? "Unknown"
    }

    private var chartData: [(key: String, value: Double)] {
        // Break into multiple steps
        let parsedValues = distribution.compactMap { key, valueStr -> (String, Double)? in
            if let value = Double(valueStr.replacingOccurrences(of: "%", with: "")) {
                return (key, value)
            }
            return nil
        }
        return parsedValues.sorted { $0.1 > $1.1 }
    }

    // Helper to create bar chart marks
    @ChartContentBuilder
    private func makeBarChartContent() -> some ChartContent {
        ForEach(chartData, id: \.key) { item in
            let itemKey = item.key
            let itemValue = item.value
            let isSelected = selectedCategory == nil || itemKey == selectedCategory
            
            BarMark(
                x: .value("Function", itemKey),
                y: .value("Percentage", itemValue)
            )
            .cornerRadius(6)
            .foregroundStyle(by: .value("Function", itemKey))
            .opacity(isSelected ? 1.0 : 0.3)
            .annotation(position: .top) {
                if itemKey == selectedCategory {
                    let percentage = Int(itemValue)
                    let text = "\(percentage)%"
                    
                    Text(text)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(nsColor: .windowBackgroundColor))
                                .shadow(radius: 1)
                        )
                }
            }
        }
    }
    
    // Extract bar chart view to a separate function
    @ViewBuilder
    private func barChartView() -> some View {
        VStack(spacing: 10) {
            Text("Function Distribution (Bar Chart)")
                .font(.headline)
            
            Chart {
                makeBarChartContent()
            }
            .chartXSelection(value: $selectedCategory)
            .chartXAxis {
                AxisMarks {
                    AxisValueLabel()
                        .font(.system(size: 10))
                    AxisGridLine()
                    AxisTick()
                }
            }
            .chartYAxis {
                AxisMarks {
                    AxisValueLabel()
                    AxisGridLine()
                    AxisTick()
                }
            }
            .chartYScale(domain: 0...100)
            .frame(height: 300)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .chartGesture { proxy in
                DragGesture(minimumDistance: 0)
                    .onChanged { proxy.selectXValue(at: $0.location.x) }
                    .onEnded { _ in /* Keep selection */ }
            }
        }
        .padding(.horizontal)
    }
    
    // Create individual bar marks
    @ViewBuilder
    private func makeBarMarks() -> some View {
        Chart {
            ForEach(chartData, id: \.key) { item in
                BarMark(
                    x: .value("Function", item.key),
                    y: .value("Percentage", item.value)
                )
                .cornerRadius(6)
                .foregroundStyle(by: .value("Function", item.key))
                .opacity(selectedCategory == nil || item.key == selectedCategory ? 1 : 0.3)
                
                if item.key == selectedCategory {
                    RuleMark(y: .value("Selected", item.value))
                        .foregroundStyle(.secondary)
                        .annotation(position: .top) {
                            Text("\(Int(item.value))%")
                                .font(.caption)
                                .padding(4)
                                .background(Color(nsColor: .windowBackgroundColor))
                                .cornerRadius(4)
                                .shadow(radius: 1)
                        }
                }
            }
        }
    }
    // Pie chart mark generator
    // MARK: - Pie Chart Content
    @State private var hoveredSector: String?

    @ChartContentBuilder
    private func makePieChartContent() -> some ChartContent {
        ForEach(chartData, id: \.key) { item in
            let isHovered = hoveredSector == nil || item.key == hoveredSector
            SectorMark(
                angle: .value("Percentage", item.value),
                innerRadius: .ratio(0.6),
                angularInset: 1
            )
            .cornerRadius(8)
            .foregroundStyle(by: .value("Function", item.key))
            .opacity(isHovered ? 1.0 : 0.3)
        }
    }

    // MARK: - Pie Chart View
    @ViewBuilder
    private func pieChartView() -> some View {
        VStack(spacing: 10) {
            Text("Function Distribution")
                .font(.headline)

            Chart {
                makePieChartContent()
            }
            .chartAngleSelection(value: $hoveredSector)
            .chartLegend(position: .bottom)
            .frame(height: 320)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if let plotFrame = chartProxy.plotFrame {
                        let frame = geometry[plotFrame]
                        VStack(spacing: 4) {
                            if let hoveredSector = hoveredSector,
                               let hoveredItem = chartData.first(where: { $0.key == hoveredSector }) {
                                Text(hoveredSector)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .frame(maxWidth: 120)
                                Text(hoveredItem.value.formatted(.percent.precision(.fractionLength(0))))
                                    .font(.title2.bold())
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Total")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("100%")
                                    .font(.title2.bold())
                                    .foregroundColor(.secondary)
                            }
                        }
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
            }
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }


    // Stacked bar mark generator
    @ChartContentBuilder
    private func makeStackedBarContent() -> some ChartContent {
        ForEach(chartData, id: \.key) { item in
            BarMark(
                x: .value("Percentage", item.value),
                stacking: .normalized
            )
            .foregroundStyle(by: .value("Function", item.key))
        }
    }

    // Stacked bar view
    @ViewBuilder
    private func stackedBarView() -> some View {
        VStack(spacing: 10) {
            Text("Function Distribution (Normalized)")
                .font(.headline)
            Chart {
                makeStackedBarContent()
            }
            .chartXAxis(.hidden)
            .chartLegend(position: .bottom)
            .frame(height: 300)
            .padding(.horizontal, 16) 
            .padding(.vertical, 8)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView {
                barChartView()
                pieChartView()
                stackedBarView()
            }
            .tabViewStyle(.automatic)
            .frame(height: 350)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
            .cornerRadius(10)

            if let category = selectedCategory,
               let value = distribution[category]?.replacingOccurrences(of: "%", with: "") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Function: \(category)").font(.headline)
                        Text("Percentage: \(value)%").font(.subheadline)
                    }
                    Spacer()
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .windowBackgroundColor).opacity(0.5)))
                .padding([.horizontal, .bottom])
            }
        }
    }
}

// MARK: - UPDATED NewHiresChart
struct NewHiresChart: View {
    let newHires: [NewHire]
    @State private var selectedDate: Date?
    @State private var selectedRange: ClosedRange<Date>?
    @State private var scrollPosition: Date?
    
    private var visibleDomain: ClosedRange<Date>? {
        guard let _ = validHires.first?.chartDate,
              let last = validHires.last?.chartDate else {
            return nil
        }
        
        // Calculate 6 months before the last date
        let sixMonthsInSeconds: TimeInterval = -60 * 60 * 24 * 30 * 6
        let startDate = last.addingTimeInterval(sixMonthsInSeconds)
        
        let defaultRange = startDate...last
        return selectedRange ?? defaultRange
    }

    private var validHires: [NewHire] {
        newHires.filter {
            if let senior = Int($0.seniorHires), let other = Int($0.otherHires) {
                return $0.chartDate != nil && (senior > 0 || other > 0)
            }
            return false
        }.sorted { ($0.chartDate ?? Date()) < ($1.chartDate ?? Date()) }
    }

    // MARK: - Trend Line Content
    @ChartContentBuilder
    private func makeSeniorHiresMarks() -> some ChartContent {
        ForEach(validHires.filter { Int($0.seniorHires) != nil && $0.chartDate != nil }, id: \.id) { hire in
            if let senior = Int(hire.seniorHires), let date = hire.chartDate {
                LineMark(
                    x: .value("Date", date, unit: .month),
                    y: .value("Senior Hires", senior)
                )
                .foregroundStyle(Color.orange)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                .interpolationMethod(.catmullRom)
                .symbol {
                    Circle()
                        .strokeBorder(Color.orange, lineWidth: 2)
                        .frame(width: 10, height: 10)
                }
            }
        }
    }

    @ChartContentBuilder
    private func makeOtherHiresMarks() -> some ChartContent {
        ForEach(validHires.filter { Int($0.otherHires) != nil && $0.chartDate != nil }, id: \.id) { hire in
            if let other = Int(hire.otherHires), let date = hire.chartDate {
                LineMark(
                    x: .value("Date", date, unit: .month),
                    y: .value("Other Hires", other)
                )
                .foregroundStyle(Color.green)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                .interpolationMethod(.catmullRom)
                .symbol {
                    Rectangle()
                        .strokeBorder(Color.green, lineWidth: 2)
                        .frame(width: 10, height: 10)
                }
            }
        }
    }

    @ViewBuilder
    private func trendLineChartView() -> some View {
        VStack(spacing: 10) {
            Text("Cumulative Hiring Trend")
                .font(.headline)

            Chart {
                makeSeniorHiresMarks()
                makeOtherHiresMarks()
            }
            .chartForegroundStyleScale([
                "Senior Hires": Color.orange,
                "Other Hires": Color.green
            ])
            .chartLegend(position: .bottom)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) {
                    AxisValueLabel(format: .dateTime.month().year())
                    AxisGridLine()
                    AxisTick()
                }
            }
            .chartYAxis {
                AxisMarks {
                    AxisValueLabel()
                    AxisGridLine()
                    AxisTick()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .frame(height: 350)
    }

    // MARK: - Interactive Bar Content
    @ChartContentBuilder
    private func makeBarChartMarks() -> some ChartContent {
        ForEach(validHires.filter {
            Int($0.seniorHires) != nil && Int($0.otherHires) != nil && $0.chartDate != nil
        }, id: \.id) { hire in
            if let senior = Int(hire.seniorHires),
               let other = Int(hire.otherHires),
               let date = hire.chartDate {
                BarMark(
                    x: .value("Date", date, unit: .month),
                    y: .value("Senior Hires", senior)
                )
                .position(by: .value("Type", "Senior"))
                .foregroundStyle(Color.orange)
                .cornerRadius(6)
                
                BarMark(
                    x: .value("Date", date, unit: .month),
                    y: .value("Other Hires", other)
                )
                .position(by: .value("Type", "Other"))
                .foregroundStyle(Color.green)
                .cornerRadius(6)
            }
        }
    }
    
    // Helper function to create selection annotations
    // Instead of defining a View Builder, we'll use this in the chart directly

    // Helper function for selection rule
    @ChartContentBuilder
    private func makeSelectionRule() -> some ChartContent {
        if let selectedDate = selectedDate,
           let hire = validHires.first(where: {
               guard let hireDate = $0.chartDate else { return false }
               return Calendar.current.isDate(hireDate, equalTo: selectedDate, toGranularity: .month)
           }),
           let date = hire.chartDate {
            RuleMark(
                x: .value("Selected", date)
            )
            .foregroundStyle(Color.gray.opacity(0.3))
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            .offset(yStart: -10)
            .zIndex(-1)
            .annotation(position: .top) {
                hiresAnnotation(for: hire)
            }
        }
    }

    // Helper function for annotation
    private func hiresAnnotation(for hire: NewHire) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(hire.date)")
                .font(.caption)
                .foregroundColor(.secondary)
            if let senior = Int(hire.seniorHires) {
                HStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text("Senior: \(senior)")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            if let other = Int(hire.otherHires) {
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Other: \(other)")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            if let senior = Int(hire.seniorHires), let other = Int(hire.otherHires) {
                Text("Total: \(senior + other)")
                    .font(.caption.bold())
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(radius: 2)
        )
    }

    // Creates the interactive bar chart view
    @ViewBuilder
    private func interactiveBarChartView() -> some View {
        VStack(spacing: 10) {
            Text("New Hires By Month (Interactive)")
                .font(.headline)
            Chart {
                makeBarChartMarks()
                makeSelectionRule()
            }
            // Configure chart styling and behavior
            .chartForegroundStyleScale(["Senior": Color.orange, "Other": Color.green])
            .chartLegend(position: .bottom) {
                HStack(spacing: 20) {
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange)
                            .frame(width: 12, height: 12)
                        Text("Senior Hires").font(.caption)
                    }
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                        Text("Other Hires").font(.caption)
                    }
                }
                .padding(.horizontal)
            }
            .chartXSelection(value: $selectedDate)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) {
                    AxisValueLabel(format: .dateTime.month().year())
                    AxisGridLine()
                    AxisTick()
                }
            }
            .chartYAxis {
                AxisMarks {
                    AxisValueLabel()
                    AxisGridLine()
                    AxisTick()
                }
            }
            .frame(height: 300)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .frame(height: 350)
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView {
                interactiveBarChartView().tag(0)
                trendLineChartView().tag(1)
            }
            .tabViewStyle(.automatic)
            .frame(height: 400)
            .padding(.horizontal)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )

            if let selectedDate = selectedDate,
               let hire = validHires.first(where: {
                   guard let hireDate = $0.chartDate else { return false }
                   return Calendar.current.isDate(hireDate, equalTo: selectedDate, toGranularity: .month)
               }) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Date: \(hire.date)").font(.subheadline)
                        if let senior = Int(hire.seniorHires) {
                            HStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.orange)
                                    .frame(width: 12, height: 12)
                                Text("Senior Hires: \(senior)")
                                    .font(.subheadline)
                                    .bold()
                            }
                        }
                        if let other = Int(hire.otherHires) {
                            HStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.green)
                                    .frame(width: 12, height: 12)
                                Text("Other Hires: \(other)")
                                    .font(.subheadline)
                                    .bold()
                            }
                        }
                        if let senior = Int(hire.seniorHires), let other = Int(hire.otherHires) {
                            Text("Total: \(senior + other)")
                                .font(.headline)
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .windowBackgroundColor).opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .padding([.horizontal, .bottom])
            }
        }
    }
}

// MARK: - Table Views





struct HeadcountGrowthTable: View {
    let headcountGrowth: [HeadcountGrowth]
    @State private var sortOrder: [KeyPathComparator<HeadcountGrowth>] = [.init(\.function, order: .forward)]

    private func growthTrend(_ growth: String) -> String {
        if growth.lowercased().contains("increase") { return "↑" }
        else if growth.lowercased().contains("decrease") { return "↓" }
        else { return "−" }
    }

    private var functionDistribution: [String: Double] {
        var distribution: [String: Double] = [:]
        let total = headcountGrowth.reduce(0) { sum, item in
            if let empCount = Int(item.numEmployees.replacingOccurrences(of: ",", with: "")) {
                return sum + empCount
            }
            return sum
        }
        for item in headcountGrowth {
            if let empCount = Int(item.numEmployees.replacingOccurrences(of: ",", with: "")) {
                distribution[item.function] = Double(empCount) / Double(total) * 100.0
            }
        }
        return distribution
    }

    var body: some View {
        VStack(spacing: 20) {
            if !functionDistribution.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Function Distribution (Current)").font(.headline)
                    Chart {
                        ForEach(functionDistribution.sorted(by: { $0.value > $1.value }), id: \.key) { item in
                            SectorMark(angle: .value("Percentage", item.value), innerRadius: .ratio(0.5), angularInset: 1)
                                .cornerRadius(4)
                                .foregroundStyle(by: .value("Function", item.key))
                        }
                    }
                    .frame(height: 250)
                    .chartLegend(position: .bottom)
                }
                .padding()
                .background(Color(nsColor: .windowBackgroundColor).opacity(0.3))
                .cornerRadius(10)
            }
            Table(headcountGrowth, sortOrder: $sortOrder) {
                TableColumn("Function", value: \.function) { item in
                    Text(item.function).lineLimit(2)
                }.width(min: 150)
                TableColumn("Employees", value: \.numEmployees) { item in
                    Text(item.numEmployees)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }.width(min: 100)
                TableColumn("6m Growth") { item in
                    HStack(spacing: 4) {
                        let isIncrease = item.growth6m.lowercased().contains("increase")
                        let isDecrease = item.growth6m.lowercased().contains("decrease")
                        let trendColor: Color = isIncrease ? .green : (isDecrease ? .red : .gray)
                        Text(growthTrend(item.growth6m))
                            .font(.caption)
                            .foregroundColor(trendColor)
                        Text(cleanDuplicatedText(item.growth6m))
                            .foregroundColor(isIncrease ? .green : (isDecrease ? .red : .primary))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }.width(min: 120)
                TableColumn("6m Added") { item in
                    Text(item.added6m != nil ? (item.added6m! > 0 ? "+\(item.added6m!)" : "\(item.added6m!)") : "N/A")
                        .foregroundColor(item.added6m != nil && item.added6m! > 0 ? .green : item.added6m != nil && item.added6m! < 0 ? .red : .primary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }.width(min: 100)
                TableColumn("1y Growth") { item in
                    HStack(spacing: 4) {
                        Text(growthTrend(item.growth1y))
                            .font(.caption)
                            .foregroundColor(item.growth1y.lowercased().contains("increase") ? .green : item.growth1y.lowercased().contains("decrease") ? .red : .gray)
                        Text(cleanDuplicatedText(item.growth1y))
                            .foregroundColor(item.growth1y.lowercased().contains("increase") ? .green : item.growth1y.lowercased().contains("decrease") ? .red : .primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }.width(min: 120)
                TableColumn("1y Added") { item in
                    Text(item.added1y != nil ? (item.added1y! > 0 ? "+\(item.added1y!)" : "\(item.added1y!)") : "N/A")
                        .foregroundColor(item.added1y != nil && item.added1y! > 0 ? .green : item.added1y != nil && item.added1y! < 0 ? .red : .primary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }.width(min: 100)
            }
            .tableStyle(.inset(alternatesRowBackgrounds: true))
            .frame(height: CGFloat(min(headcountGrowth.count * 45 + 40, 350)))
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3), lineWidth: 1))
            .font(.subheadline)
            .foregroundStyle(.primary)
            .headerProminence(.increased)
        }
    }
}

// MARK: - UPDATED JobOpeningsDetailsTable
struct JobOpeningsDetailsTable: View {
    let details: [JobOpeningDetail]
    @State private var selectedFunction: String?
    @State private var totalOpenings: Int = 0
    @State private var sortOrder = [KeyPathComparator(\JobOpeningDetail.function)]
    @State private var hoveredSector: String? = nil

    private var distributionData: [String: Double] {
        var data: [String: Double] = [:]
        var total = 0
        guard !details.isEmpty else { return data }
        for detail in details {
            if let count = Int(detail.numEmployees.replacingOccurrences(of: ",", with: "")) {
                total += count
            }
            if let percentage = Double(detail.percentage.replacingOccurrences(of: "%", with: "")) {
                data[detail.function] = percentage
            }
        }
        DispatchQueue.main.async {
            self.totalOpenings = total
        }
        return data
    }

    var body: some View {
        VStack(spacing: 20) {
            if !distributionData.isEmpty {
                JobOpeningsDistributionChart(
                    distributionData: distributionData,
                    totalOpenings: totalOpenings,
                    details: details
                )
            }
            JobOpeningsDetailsTableView(details: details)
        }
    }
}

struct JobOpeningsDistributionChart: View {
    let distributionData: [String: Double]
    let totalOpenings: Int
    let details: [JobOpeningDetail]
    @State private var hoveredSector: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Job Openings Distribution")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.horizontal)

            Chart {
                ForEach(distributionData.sorted(by: { $0.value > $1.value }), id: \.key) { item in
                    SectorMark(
                        angle: .value("Percentage", item.value),
                        innerRadius: .ratio(0.65),
                        angularInset: 4
                    )
                    .cornerRadius(8)  // Standardized corner radius
                    .foregroundStyle(by: .value("Function", item.key))
                    .opacity(hoveredSector == nil || hoveredSector == item.key ? 1 : 0.7)
                }

                PointMark(
                    x: .value("center", 0),
                    y: .value("center", 0)
                )
                .annotation(position: .overlay) {
                    if let hoveredSector = hoveredSector,
                       let hoveredItem = distributionData.first(where: { $0.key == hoveredSector }) {
                        VStack(spacing: 4) {
                            Text(hoveredSector)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .frame(maxWidth: 120)
                            Text(hoveredItem.value.formatted(.percent.precision(.fractionLength(0))))
                                .font(.title2.bold())
                                .foregroundColor(.secondary)
                            if let detail = details.first(where: { $0.function == hoveredSector }) {
                                Text(detail.numEmployees)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    } else {
                        VStack(spacing: 4) {
                            Text("Total")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("\(totalOpenings)")
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                            Text("Openings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartLegend(position: .bottom, alignment: .center, spacing: 8)
            .chartAngleSelection(value: $hoveredSector)
            .frame(height: 250)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.bottom)
    }
}

struct JobOpeningsDetailsTableView: View {
    let details: [JobOpeningDetail]
    @State private var sortOrder = [KeyPathComparator(\JobOpeningDetail.function)]

    private var sortedDetails: [JobOpeningDetail] {
        return details.sorted(using: sortOrder)
    }

    // Proper Table implementation with sortable columns and alternating rows
    var body: some View {
        Table(sortedDetails, sortOrder: $sortOrder) {
            TableColumn("Function", value: \.function) { item in
                Text(item.function)
                    .lineLimit(2)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .font(.system(size: 12))
            }
            .width(min: 150)

            TableColumn("Job Openings", value: \.numEmployees) { item in
                Text(item.numEmployees)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .font(.system(size: 12))
            }
            .width(min: 80)

            TableColumn("Share (%)", value: \.percentage) { item in
                Text(item.percentage)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .font(.system(size: 12))
            }
            .width(min: 100)

            TableColumn("3m Growth") { item in
                HStack(spacing: 4) {
                    Image(systemName: item.growth3m.contains("increase") ? "arrow.up" : item.growth3m.contains("decrease") ? "arrow.down" : "minus")
                        .font(.caption2)
                    Text(cleanDuplicatedText(item.growth3m))
                        .font(.system(size: 12))
                }
                .foregroundColor(
                    item.growth3m.contains("increase")
                        ? .green
                        : item.growth3m.contains("decrease")
                        ? .red
                        : .primary
                )
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }
            .width(min: 120)

            TableColumn("6m Growth") { item in
                HStack(spacing: 4) {
                    Image(systemName: item.growth6m.contains("increase") ? "arrow.up" : item.growth6m.contains("decrease") ? "arrow.down" : "minus")
                        .font(.caption2)
                    Text(cleanDuplicatedText(item.growth6m))
                        .font(.system(size: 12))
                }
                .foregroundColor(
                    item.growth6m.contains("increase")
                        ? .green
                        : item.growth6m.contains("decrease")
                        ? .red
                        : .primary
                )
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }
            .width(min: 120)
        }
        .alternatingRowBackgrounds(.enabled)
        .font(.subheadline)
        .foregroundStyle(.primary)
        .frame(minHeight: min(CGFloat(details.count * 44 + 44), 400))
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct JobOpeningsGrowthTable: View {
    let growth: [JobOpeningGrowth]
    @State private var sortOrder: [KeyPathComparator<JobOpeningGrowth>] = [.init(\.function, order: .forward)]

    var body: some View {
        Table(growth, sortOrder: $sortOrder) {
            TableColumn("Function", value: \.function) { item in
                Text(item.function)
                    .lineLimit(2)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .font(.system(size: 12))
            }.width(min: 150)
            TableColumn("3m Growth") { item in
                HStack(spacing: 4) {
                    Image(systemName: item.growth3m.contains("increase") ? "arrow.up" : item.growth3m.contains("decrease") ? "arrow.down" : "minus")
                        .font(.caption2)
                    Text(cleanDuplicatedText(item.growth3m))
                        .font(.system(size: 12))
                }
                .foregroundColor(
                    item.growth3m.contains("increase")
                        ? .green
                        : item.growth3m.contains("decrease")
                        ? .red
                        : .primary
                )
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }.width(min: 120)
            TableColumn("6m Growth") { item in
                HStack(spacing: 4) {
                    Image(systemName: item.growth6m.contains("increase") ? "arrow.up" : item.growth6m.contains("decrease") ? "arrow.down" : "minus")
                        .font(.caption2)
                    Text(cleanDuplicatedText(item.growth6m))
                        .font(.system(size: 12))
                }
                .foregroundColor(
                    item.growth6m.contains("increase")
                        ? .green
                        : item.growth6m.contains("decrease")
                        ? .red
                        : .primary
                )
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }.width(min: 120)
        }
        .alternatingRowBackgrounds(.enabled)
        .frame(height: CGFloat(min(growth.count * 45 + 40, 350)))
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.2), lineWidth: 1))
        .font(.subheadline)
        .foregroundStyle(.primary)
        .headerProminence(.increased)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct JobOpeningsBottomTable: View {
    let plainText: [JobOpeningPlainText]
    @State private var sortOrder: [KeyPathComparator<JobOpeningPlainText>] = [.init(\.function, order: .forward)]

    var body: some View {
        VStack(spacing: 20) {
            Table(plainText, sortOrder: $sortOrder) {
                TableColumn("Function", value: \.function) { item in
                    Text(item.function)
                        .lineLimit(2)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        .font(.system(size: 12))
                }
                .width(min: 150)

                TableColumn("Employees", value: \.numEmployees) { item in
                    Text(item.numEmployees)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        .font(.system(size: 12))
                }
                .width(min: 100)

                TableColumn("3m Growth") { item in
                    HStack(spacing: 4) {
                        Image(systemName: item.growth3m.contains("increase") ? "arrow.up" : item.growth3m.contains("decrease") ? "arrow.down" : "minus")
                            .font(.caption2)
                        Text(cleanDuplicatedText(item.growth3m))
                            .font(.system(size: 12))
                    }
                    .foregroundColor(
                        item.growth3m.contains("increase")
                            ? .green
                            : item.growth3m.contains("decrease")
                            ? .red
                            : .primary
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                }
                .width(min: 120)

                TableColumn("6m Growth") { item in
                    HStack(spacing: 4) {
                        Image(systemName: item.growth6m.contains("increase") ? "arrow.up" : item.growth6m.contains("decrease") ? "arrow.down" : "minus")
                            .font(.caption2)
                        Text(cleanDuplicatedText(item.growth6m))
                            .font(.system(size: 12))
                    }
                    .foregroundColor(
                        item.growth6m.contains("increase")
                            ? .green
                            : item.growth6m.contains("decrease")
                            ? .red
                            : .primary
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                }
                .width(min: 120)
            }
            .alternatingRowBackgrounds(.enabled)
            .font(.subheadline)
            .foregroundStyle(.primary)
            .frame(minHeight: min(CGFloat(plainText.count * 44 + 44), 400))
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Visualization View
struct VisualizerView: View {
    let data: LinkedInInsightsData

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let medianTenure = data.medianTenure {
                Text("Median Employee Tenure: \(medianTenure)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.bottom, 10)
            }
            if let totalEmployees = data.totalEmployees["total_employees"] {
                Text("Total Employees: \(totalEmployees)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.bottom, 10)
            }
            if !data.employeeGrowth.isEmpty {
                SectionHeader(title: "Employee Growth Over Time")
                EmployeeGrowthChart(employeeGrowth: data.employeeGrowth)
            }
            if !data.functionDistribution.isEmpty {
                SectionHeader(title: "Function Distribution")
                FunctionDistributionChart(distribution: data.functionDistribution)
            }
            if !data.headcountGrowth.isEmpty {
                SectionHeader(title: "Headcount Growth")
                HeadcountGrowthTable(headcountGrowth: data.headcountGrowth)
            }
            if !data.newHires.isEmpty {
                SectionHeader(title: "New Hires Over Time")
                NewHiresChart(newHires: data.newHires)
            }
            if !data.jobOpenings.distribution.isEmpty {
                SectionHeader(title: "Job Openings Distribution")
                FunctionDistributionChart(distribution: data.jobOpenings.distribution)
            }
            if !data.jobOpenings.openingsDetails.isEmpty {
                SectionHeader(title: "Job Openings Details")
                JobOpeningsDetailsTable(details: data.jobOpenings.openingsDetails)
            }
            if !data.jobOpenings.jobOpeningsGrowth.isEmpty {
                SectionHeader(title: "Job Openings Growth")
                JobOpeningsGrowthTable(growth: data.jobOpenings.jobOpeningsGrowth)
            }
            if !data.jobOpeningsPlainText.isEmpty {
                SectionHeader(title: "Job Openings Plain Text")
                JobOpeningsBottomTable(plainText: data.jobOpeningsPlainText)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: SwiftDataJobApplication.self, SwiftDataJobDocument.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)) // Use in-memory store for previews
        } catch {
            fatalError("Failed to initialize SwiftData container for previews: \(error)")
        }
        let documentStore = DocumentStore(modelContext: container.mainContext)
        let jobStore = JobStore(documentStore: documentStore)
        let importExportHelper = ImportExportHelper()

        return ContentView(showSettings: .constant(false)) // Pass a constant binding for showSettings
            .environmentObject(jobStore)
            .environmentObject(documentStore)
            .environmentObject(importExportHelper)
    }
}
#endif
