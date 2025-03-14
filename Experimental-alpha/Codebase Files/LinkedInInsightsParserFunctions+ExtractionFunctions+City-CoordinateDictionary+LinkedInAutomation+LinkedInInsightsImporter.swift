//
//  LinkedInAutomationManager.swift
//  Experimental-alpha
//
//  Created by Roger Lin on 3/14/25.
//


// MARK: - LinkedInInsightsParserFunctions+ExtractionFunctions+City-CoordinateDictionary+LinkedInAutomation+LinkedInInsightsImporter

// -----------------------------------------------------------------------------

// MARK: - Imports

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


// --------------------------------------------------
// MARK: - LinkedIn Insights Parser Functions
// --------------------------------------------------
// --------------------------------------------------
// MARK: - LinkedIn Insights Parser Functions
// --------------------------------------------------

// --------------------------------------------------
// MARK: - LinkedIn Insights Parser Functions
// --------------------------------------------------

// -------------------------------------
// MARK: - Helper Functions
// -------------------------------------

/// Cleans up duplicated or extraneous growth strings like "5%5% increase", "4%4% increase", etc.
func cleanGrowthString(_ growthStr: String) -> String {
    // First, check for duplicate percentages like "5%5% increase"
    let duplicatePattern = #"(-?\d+%)(?:\s*-?)?\1\s*(\b.*)"#
    let regex1 = try! NSRegularExpression(pattern: duplicatePattern)
    let range = NSRange(growthStr.startIndex..<growthStr.endIndex, in: growthStr)

    if let match = regex1.firstMatch(in: growthStr, range: range),
       let percentRange = Range(match.range(at: 1), in: growthStr),
       let trendRange = Range(match.range(at: 2), in: growthStr) {
        let percent = String(growthStr[percentRange])
        let trend = String(growthStr[trendRange]).trimmingCharacters(in: .whitespaces)
        return trend.isEmpty ? percent : "\(percent) \(trend)"
    }

    // Otherwise, parse with a more general pattern
    let pattern = #"(.*?)(-?\d+%)\s*(\b.*)"#
    let regex2 = try! NSRegularExpression(pattern: pattern)

    if let match = regex2.firstMatch(in: growthStr, range: range),
       let percentRange = Range(match.range(at: 2), in: growthStr),
       let trendRange = Range(match.range(at: 3), in: growthStr) {
        let percent = String(growthStr[percentRange])
        let trend = String(growthStr[trendRange]).trimmingCharacters(in: .whitespaces)
        return trend.isEmpty ? percent : "\(percent) \(trend)"
    }

    return growthStr
}

/// Parses a string like "4% increase" or "10% decrease" and returns an integer growth percentage.
/// Returns 0 if it contains "No change".
func parseGrowthPercentage(_ growthStr: String) -> Int? {
    if growthStr.contains("No change") { return 0 }
    let pattern = #"(\d+)%"#
    let regex = try! NSRegularExpression(pattern: pattern)
    let range = NSRange(growthStr.startIndex..<growthStr.endIndex, in: growthStr)
    if let match = regex.firstMatch(in: growthStr, range: range),
       let percentRange = Range(match.range(at: 1), in: growthStr) {
        var percent = Int(growthStr[percentRange])!
        if growthStr.lowercased().contains("decrease") {
            percent = -percent
        }
        return percent
    }
    return nil
}

/// Calculates how many employees were "added" based on a current count and a growth percent.
func calculateAdded(current: String, growthPercent: Int?) -> Int? {
    guard let growthPercent = growthPercent,
          let n = Int(current.replacingOccurrences(of: ",", with: "")) else { return nil }
    if growthPercent == 0 { return 0 }
    let previous = Double(n) / (1.0 + Double(growthPercent) / 100.0)
    let added = Double(n) - previous
    return Int(added.rounded())
}

/// Attempts to guess the company name from the LinkedIn HTML document.
func extractCompanyName(from doc: Document) -> String? {
    // 1. From the page title
    if let title = try? doc.title() {
        let components = title.components(separatedBy: " | ")
        if !components.isEmpty {
            let possibleName = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            if !possibleName.isEmpty && !possibleName.lowercased().contains("linkedin") {
                return possibleName
            }
        }
    }
    // 2. From meta property="og:title"
    if let metaCompany = try? doc.select("meta[property='og:title']").first(),
       let content = try? metaCompany.attr("content") {
        let parts = content.components(separatedBy: " | ")
        if !parts.isEmpty {
            let possibleName = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            if !possibleName.isEmpty && !possibleName.lowercased().contains("linkedin") {
                return possibleName
            }
        }
    }
    // 3. From a company header
    if let companyHeader = try? doc.select("h1.org-top-card-summary__title").first() {
        let textVal = try? companyHeader.text().trimmingCharacters(in: .whitespacesAndNewlines)
        if let name = textVal, !name.isEmpty {
            return name
        }
    }
    // Fallback: nil if not found
    return nil
}

// -------------------------------------
// MARK: - Extraction Functions
// -------------------------------------

func extractEmployeeGrowth(from doc: Document) throws -> [EmployeeGrowth] {
    var data: [EmployeeGrowth] = []
    guard let group = try doc.select("g[class*=highcharts-markers]").first() else { return data }
    let paths = try group.select("path[aria-label]")

    // This pattern attempts to capture a highcharts data label like:
    // "1. Wednesday, Mar 5, 14:00, 1,253 employees, +3% growth"
    let pattern = #"^\d+\.\s+([^,]+),\s+([^,]+)\s+(\d+),\s+([^,]+),\s+([\d,]+) employees(?:, (.+))?$"#
    let regex = try NSRegularExpression(pattern: pattern)

    for path in paths {
        let label = try path.attr("aria-label")
        let range = NSRange(label.startIndex..<label.endIndex, in: label)

        if let match = regex.firstMatch(in: label, range: range), match.numberOfRanges >= 6 {
            guard
                let dayRange = Range(match.range(at: 1), in: label),
                let monthRange = Range(match.range(at: 2), in: label),
                let dayNumRange = Range(match.range(at: 3), in: label),
                let timeRange = Range(match.range(at: 4), in: label),
                let countRange = Range(match.range(at: 5), in: label)
            else { continue }

            let dayOfWeek = String(label[dayRange])
            let month = String(label[monthRange])
            let day = String(label[dayNumRange])
            let time = String(label[timeRange])
            let countStr = String(label[countRange]).replacingOccurrences(of: ",", with: "")
            let employeeCount = Int(countStr) ?? 0

            let growth: String
            if match.numberOfRanges > 6, let growthRange = Range(match.range(at: 6), in: label) {
                growth = String(label[growthRange])
            } else {
                growth = ""
            }

            data.append(
                EmployeeGrowth(
                    dayOfWeek: dayOfWeek,
                    month: month,
                    day: day,
                    time: time,
                    employeeCount: employeeCount,
                    growth: growth,
                    year: nil
                )
            )
        }
    }

    // Approximate approach to assign a year to each data point
    let monthMap: [String: Int] = [
        "Jan": 1, "Feb": 2, "Mar": 3, "Apr": 4, "May": 5,
        "Jun": 6, "Jul": 7, "Aug": 8, "Sep": 9,
        "Oct": 10, "Nov": 11, "Dec": 12
    ]
    if let lastIndex = data.indices.reversed().first(where: { monthMap[data[$0].month] != nil }) {
        // Assume the last item is from the current year (e.g. 2025)
        data[lastIndex].year = 2025
        for i in (0..<lastIndex).reversed() {
            if
                let currentMonth = monthMap[data[i].month],
                let nextMonth = monthMap[data[i + 1].month],
                let nextYear = data[i + 1].year
            {
                data[i].year = (nextMonth == 1 && currentMonth == 12) ? (nextYear - 1) : nextYear
            }
        }
    }

    return data
}

func extractFunctionDistribution(from doc: Document) throws -> FunctionDistribution {
    var distribution: [String: String] = [:]
    guard let tableDiv = try doc.select("div.org-function-percentage-table").first() else { return distribution }
    let rows = try tableDiv.select("tr")
    for row in rows {
        if let td = try row.select("td").first(),
           let strong = try td.select("strong").first() {
            let percentage = try strong.text().trimmingCharacters(in: .whitespaces)
            let text = try td.text().trimmingCharacters(in: .whitespaces)
            let parts = text.split(separator: "·").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count >= 2 {
                distribution[parts[1]] = percentage
            }
        }
    }
    return distribution
}

func extractHeadcountGrowth(from doc: Document) throws -> [HeadcountGrowth] {
    var growthData: [HeadcountGrowth] = []
    guard let table = try doc.select("table[summary*=Headcount growth by function]").first() else { return growthData }
    // Skip the header row
    let rows = try table.select("tr").array()[1...]
    for row in rows {
        let cells = try row.select("td").array()
        if cells.count >= 5 {
            let function = try cells[0].text().trimmingCharacters(in: .whitespaces)
            let numEmployees = try cells[1].text().trimmingCharacters(in: .whitespaces)
            let percentage = try cells[2].text().trimmingCharacters(in: .whitespaces)
            let growth6m = cleanGrowthString(try cells[3].text().trimmingCharacters(in: .whitespaces))
            let growth1y = cleanGrowthString(try cells[4].text().trimmingCharacters(in: .whitespaces))

            growthData.append(
                HeadcountGrowth(
                    function: function,
                    numEmployees: numEmployees,
                    percentage: percentage,
                    growth6m: growth6m,
                    growth1y: growth1y,
                    added6m: nil,
                    added1y: nil
                )
            )
        }
    }
    return growthData
}

func extractNewHires(from doc: Document) throws -> [NewHire] {
    var hires: [NewHire] = []
    guard let table = try doc.select("table[summary*=Senior hires over time]").first() else { return hires }
    let rows = try table.select("tr").array()[1...] // skip header
    for row in rows {
        let cells = try row.select("td").array()
        if cells.count >= 3 {
            let date = try cells[0].text().trimmingCharacters(in: .whitespaces)
            let seniorHires = try cells[1].text().trimmingCharacters(in: .whitespaces)
            let otherHires = try cells[2].text().trimmingCharacters(in: .whitespaces)
            hires.append(NewHire(date: date, seniorHires: seniorHires, otherHires: otherHires))
        }
    }
    return hires
}

func extractJobOpenings(from doc: Document) throws -> JobOpenings {
    var distribution: [String: String] = [:]
    var openingsDetails: [JobOpeningDetail] = []
    var jobOpeningsGrowth: [JobOpeningGrowth] = []

    guard let jobModule = try doc.select("section[class*=org-insights-jobs-module]").first() else {
        return JobOpenings(distribution: distribution, openingsDetails: openingsDetails, jobOpeningsGrowth: jobOpeningsGrowth)
    }

    // Distribution
    if let distTable = try jobModule.select("div.org-function-percentage-table").first() {
        let rows = try distTable.select("tr")
        for row in rows {
            if let td = try row.select("td").first(),
               let strong = try td.select("strong").first() {
                let percentage = try strong.text().trimmingCharacters(in: .whitespaces)
                let text = try td.text().trimmingCharacters(in: .whitespaces)
                let parts = text.split(separator: "·").map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count >= 2 {
                    distribution[parts[1]] = percentage
                }
            }
        }
    }

    // Openings details
    if let detailsTable = try jobModule.select("table[id=function-growth__a11y-jobs-table]").first() {
        let rows = try detailsTable.select("tr").array()[1...] // skip header
        for row in rows {
            let cells = try row.select("td").array()
            if cells.count >= 5 {
                let function = try cells[0].text().trimmingCharacters(in: .whitespaces)
                let numEmployees = try cells[1].text().trimmingCharacters(in: .whitespaces)
                let percentage = try cells[2].text().trimmingCharacters(in: .whitespaces)
                let growth3m = cleanGrowthString(try cells[3].text().trimmingCharacters(in: .whitespaces))
                let growth6m = cleanGrowthString(try cells[4].text().trimmingCharacters(in: .whitespaces))

                openingsDetails.append(
                    JobOpeningDetail(
                        function: function,
                        numEmployees: numEmployees,
                        percentage: percentage,
                        growth3m: growth3m,
                        growth6m: growth6m
                    )
                )
            }
        }
    }

    // Job openings growth
    if let growthTable = try jobModule.select("table[class*=org-insights-functions-growth__table]").first() {
        let rows = try growthTable.select("tr").array()[1...] // skip header
        for row in rows {
            let cells = try row.select("td").array()
            if cells.count >= 3 {
                let function = try cells[0].text().trimmingCharacters(in: .whitespaces)
                let growth3m = cleanGrowthString(try cells[1].text().trimmingCharacters(in: .whitespaces))
                let growth6m = cleanGrowthString(try cells[2].text().trimmingCharacters(in: .whitespaces))
                jobOpeningsGrowth.append(
                    JobOpeningGrowth(
                        function: function,
                        growth3m: growth3m,
                        growth6m: growth6m
                    )
                )
            }
        }
    }

    return JobOpenings(
        distribution: distribution,
        openingsDetails: openingsDetails,
        jobOpeningsGrowth: jobOpeningsGrowth
    )
}

func extractJobOpeningsPlainText(from doc: Document) throws -> [JobOpeningPlainText] {
    var result: [JobOpeningPlainText] = []
    guard
        let growthDiv = try doc.select("div.org-function-growth-table").first(),
        let table = try growthDiv.select("table[id=function-growth__a11y-jobs-table]").first()
    else {
        return result
    }
    let rows = try table.select("tr").array()[1...] // skip header
    for row in rows {
        let cells = try row.select("td").array()
        if cells.count >= 5 {
            let function = try cells[0].text().trimmingCharacters(in: .whitespaces)
            let numEmployees = try cells[1].text().trimmingCharacters(in: .whitespaces)
            let growth3m = cleanGrowthString(try cells[3].text().trimmingCharacters(in: .whitespaces))
            let growth6m = cleanGrowthString(try cells[4].text().trimmingCharacters(in: .whitespaces))

            result.append(
                JobOpeningPlainText(
                    function: function,
                    numEmployees: numEmployees,
                    growth3m: growth3m,
                    growth6m: growth6m
                )
            )
        }
    }
    return result
}

func extractMedianTenure(from doc: Document) -> String? {
    let text = try? doc.text()
    let pattern = #"Median employee tenure.*?([\d.]+) years"#
    let regex = try! NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
    if
        let text = text,
        let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
        let valRange = Range(match.range(at: 1), in: text)
    {
        return String(text[valRange]) + " years"
    }
    return nil
}

func extractTotalEmployees(from doc: Document) throws -> [String: String] {
    var result: [String: String] = [:]
    guard let table = try doc.select("table[summary=Total employee count]").first() else { return result }

    // Overall total employees
    if let totalSpan = try table.select("span.t-bold").first() {
        result["total_employees"] = try totalSpan.text().trimmingCharacters(in: .whitespaces)
    }

    // Growth by time range
    let headers = try table.select("th.t-normal")
    let values = try table.select("td.t-bold")
    for (header, value) in zip(headers, values) {
        let key = try header.text().trimmingCharacters(in: .whitespaces).lowercased()
        if let growthSpan = try value.select("span.visually-hidden").first() {
            let growth = cleanGrowthString(try growthSpan.text().trimmingCharacters(in: .whitespaces))
            result[key] = growth
        }
    }
    return result
}

// -------------------------------------
// MARK: - Master Extract Function
// -------------------------------------

/// Parses raw HTML from a LinkedIn company insights page into a `LinkedInInsightsData` object.
/// This version includes company-name extraction and an import timestamp.
func extractData(from html: String) throws -> LinkedInInsightsData {
    do {
        let doc = try SwiftSoup.parse(html)

        // 1. Attempt to extract the company name
        let guessedCompanyName = extractCompanyName(from: doc)

        // 2. For each category, parse in a do/catch so one failure won't break everything
        let employeeGrowth: [EmployeeGrowth]
        do {
            employeeGrowth = try extractEmployeeGrowth(from: doc)
        } catch {
            print("Error extracting employee growth: \(error)")
            employeeGrowth = []
        }

        let functionDistribution: FunctionDistribution
        do {
            functionDistribution = try extractFunctionDistribution(from: doc)
        } catch {
            print("Error extracting function distribution: \(error)")
            functionDistribution = [:]
        }

        var headcountGrowth: [HeadcountGrowth]
        do {
            headcountGrowth = try extractHeadcountGrowth(from: doc)
        } catch {
            print("Error extracting headcount growth: \(error)")
            headcountGrowth = []
        }

        let newHires: [NewHire]
        do {
            newHires = try extractNewHires(from: doc)
        } catch {
            print("Error extracting new hires: \(error)")
            newHires = []
        }

        let jobOpenings: JobOpenings
        do {
            jobOpenings = try extractJobOpenings(from: doc)
        } catch {
            print("Error extracting job openings: \(error)")
            jobOpenings = JobOpenings(distribution: [:], openingsDetails: [], jobOpeningsGrowth: [])
        }

        let jobOpeningsPlainText: [JobOpeningPlainText]
        do {
            jobOpeningsPlainText = try extractJobOpeningsPlainText(from: doc)
        } catch {
            print("Error extracting job openings plain text: \(error)")
            jobOpeningsPlainText = []
        }

        let medianTenure = extractMedianTenure(from: doc)

        let totalEmployees: [String: String]
        do {
            totalEmployees = try extractTotalEmployees(from: doc)
        } catch {
            print("Error extracting total employees: \(error)")
            totalEmployees = [:]
        }

        // 3. Compute added employees for headcount growth
        headcountGrowth = headcountGrowth.map { item in
            let g6 = parseGrowthPercentage(item.growth6m)
            let g1 = parseGrowthPercentage(item.growth1y)
            let a6 = calculateAdded(current: item.numEmployees, growthPercent: g6)
            let a1 = calculateAdded(current: item.numEmployees, growthPercent: g1)
            return HeadcountGrowth(
                function: item.function,
                numEmployees: item.numEmployees,
                percentage: item.percentage,
                growth6m: item.growth6m,
                growth1y: item.growth1y,
                added6m: a6,
                added1y: a1
            )
        }

        // 4. Assemble and return final object with companyName + importDate
        return LinkedInInsightsData(
            employeeGrowth: employeeGrowth,
            functionDistribution: functionDistribution,
            headcountGrowth: headcountGrowth,
            newHires: newHires,
            jobOpenings: jobOpenings,
            jobOpeningsPlainText: jobOpeningsPlainText,
            medianTenure: medianTenure,
            totalEmployees: totalEmployees,
            companyName: guessedCompanyName,
            importDate: Date()
        )

    } catch {
        print("Critical error in LinkedIn Insights parsing: \(error)")
        // Return an empty dataset rather than throwing, to avoid crashing the flow
        return LinkedInInsightsData(
            employeeGrowth: [],
            functionDistribution: [:],
            headcountGrowth: [],
            newHires: [],
            jobOpenings: JobOpenings(distribution: [:], openingsDetails: [], jobOpeningsGrowth: []),
            jobOpeningsPlainText: [],
            medianTenure: nil,
            totalEmployees: [:],
            companyName: nil,
            importDate: Date()
        )
    }
}


// --------------------------------------------------
// MARK: - City-Coordinate Dictionary
// --------------------------------------------------

public var CityCoordinateDictionary: [String: CLLocationCoordinate2D] = [
    "New York City, NY": CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
    "Los Angeles, CA":   CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
    "Chicago, IL":       CLLocationCoordinate2D(latitude: 41.8781, longitude: -87.6298),
    "San Francisco, CA": CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    "Seattle, WA":       CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321),
    "Beijing, CN":       CLLocationCoordinate2D(latitude: 39.916668, longitude: 116.383331),
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
    "Manila, PH":        CLLocationCoordinate2D(latitude: 14.58834, longitude: 121.05949),
    "Tampa, FL":         CLLocationCoordinate2D(latitude: 27.9517, longitude: -82.4588),
    "San Diego, CA":     CLLocationCoordinate2D(latitude: 32.7157, longitude: -117.1611),
    "Singapore, SG":     CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198),
    "Global":            CLLocationCoordinate2D(latitude: 34.149884, longitude: -118.056932)
]

//---------------------------------------------------------------------------------------------------------//
//
//  DocumentStore.swift
//  Experimental-alpha
//
//  Created by Roger Lin on 3/4/25.
//


// --------------------------------------------------
// MARK: - LinkedIn Automation
// --------------------------------------------------

// --------------------------------------------------
// MARK: - LinkedIn Automation
// --------------------------------------------------

class LinkedInAutomationManager: NSObject, WKNavigationDelegate, WKUIDelegate {
    private var webView: WKWebView!
    private var url: URL
    private var completionHandler: ((String?, Error?) -> Void)?
    private var navigationCompletedHandler: (() -> Void)?
    private var username: String
    private var password: String
    private var isLoggedIn = false
    private var isDownloading = false

    init(url: URL, username: String, password: String) {
        self.url = url
        self.username = username
        self.password = password
        super.init()
        setupWebView()
    }

    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = prefs

        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1200, height: 800), configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
    }

    func startAutomation(completion: @escaping (String?, Error?) -> Void) {
        self.completionHandler = completion

        // Navigate to LinkedIn’s login page
        let request = URLRequest(url: URL(string: "https://www.linkedin.com/login")!)
        webView.load(request)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.url?.absoluteString.contains("linkedin.com/login") == true && !isLoggedIn {
            // On login screen, inject credentials
            performLogin { [weak self] success in
                if success {
                    self?.isLoggedIn = true
                    self?.navigateToInsightsPage()
                } else {
                    self?.completionHandler?(nil, NSError(domain: "LinkedInAutomation", code: 1001,
                                                          userInfo: [NSLocalizedDescriptionKey: "Failed to log in to LinkedIn"]))
                }
            }
        }
        else if let currentURL = webView.url?.absoluteString, currentURL.contains(url.absoluteString) {
            // Once on the target insights page, wait a moment before extracting HTML
            if !isDownloading {
                isDownloading = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                    self?.extractHTMLFromWebView()
                }
            }
        }
        else if navigationCompletedHandler != nil {
            navigationCompletedHandler?()
            navigationCompletedHandler = nil
        }
    }

    private func performLogin(completion: @escaping (Bool) -> Void) {
        let loginScript = """
        document.getElementById('username').value = '\(username)';
        document.getElementById('password').value = '\(password)';
        document.querySelector('button[type="submit"]').click();
        true;
        """

        webView.evaluateJavaScript(loginScript) { _, error in
            if let error = error {
                print("Login script error: \(error)")
                completion(false)
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                completion(true)
            }
        }
    }

    private func navigateToInsightsPage() {
        // Once logged in, load the actual insights page
        self.navigationCompletedHandler = { [weak self] in
            // Remove the unrelated data processing code
            self?.isDownloading = false
        }
        webView.load(URLRequest(url: url))
    }

    private func extractHTMLFromWebView() {
        webView.evaluateJavaScript("document.documentElement.outerHTML") { [weak self] (result, error) in
            if let error = error {
                self?.completionHandler?(nil, error)
                return
            }
            guard let htmlString = result as? String else {
                self?.completionHandler?(
                    nil,
                    NSError(domain: "LinkedInAutomation", code: 1002,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to extract HTML content"])
                )
                return
            }

            // Return final HTML
            self?.completionHandler?(htmlString, nil)
        }
    }
}




//-----------------------------------------------------------------------------------------------------//

// MARK: - LinkedInInsightsImporter
struct LinkedInInsightsImporter: View {
    @EnvironmentObject var jobStore: JobStore
    @Binding var job: JobApplication
    @State private var isShowingImportDialog = false
    @State private var isShowingAutomationDialog = false
    @State private var linkedInURL = ""
    @State private var username = "linroger023@gmail.com"
    @State private var password = "Belgravia11!"
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        VStack {
            if jobStore.isLoadingLinkedInData {
                ProgressView("Loading LinkedIn data...").padding()
            } else {
                HStack {
                    Button("Import LinkedIn Insight") {
                        isShowingImportDialog = true
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Import from URL") {
                        isShowingAutomationDialog = true
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 5)
            }
        }
        .fileImporter(isPresented: $isShowingImportDialog, allowedContentTypes: [.html], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    do {
                        let htmlContent = try String(contentsOf: url, encoding: .utf8)
                        jobStore.importLinkedInInsightsForJob(id: job.id, from: htmlContent)
                        if let updatedJob = jobStore.jobApplications.first(where: { $0.id == job.id }) {
                            job = updatedJob
                        }
                    } catch {
                        errorMessage = "Failed to read HTML file: \(error.localizedDescription)"
                        showError = true
                    }
                }
            case .failure(let error):
                errorMessage = "File import failed: \(error.localizedDescription)"
                showError = true
            }
        }
        .sheet(isPresented: $isShowingAutomationDialog) {
            VStack(spacing: 20) {
                Text("Import LinkedIn Insights from URL").font(.title2).bold()
                TextField("LinkedIn Company Insights URL", text: $linkedInURL)
                    .textFieldStyle(.roundedBorder)
                TextField("LinkedIn Username", text: $username)
                    .textFieldStyle(.roundedBorder)
                SecureField("LinkedIn Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                Text("Note: This uses your LinkedIn credentials to log in and scrape insights data.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                HStack {
                    Button("Cancel") {
                        isShowingAutomationDialog = false
                    }
                    .buttonStyle(.bordered)
                    Button("Import") {
                        isShowingAutomationDialog = false
                        isLoading = true
                        jobStore.automaticallyImportLinkedInInsights(forJobID: job.id, fromURL: linkedInURL, username: username, password: password) { success, message in
                            isLoading = false
                            if !success {
                                errorMessage = message
                                showError = true
                            } else {
                                if let updatedJob = jobStore.jobApplications.first(where: { $0.id == job.id }) {
                                    job = updatedJob
                                }
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(linkedInURL.isEmpty)
                }
            }
            .padding()
            .frame(width: 400, height: 320)
        }
        .alert("Import Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
}

//-----------------------------------------------------------------------------------------------------//
