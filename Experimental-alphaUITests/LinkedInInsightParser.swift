import SwiftUI
import SwiftSoup

// MARK: - Data Structures

struct EmployeeGrowth {
    let dayOfWeek: String
    let month: String
    let day: String
    let time: String
    let employeeCount: Int
    let growth: String
    var year: Int?
}

typealias FunctionDistribution = [String: String]

struct HeadcountGrowth: Identifiable {
    let id = UUID()
    let function: String
    let numEmployees: String
    let percentage: String
    let growth6m: String
    let growth1y: String
    let added6m: Int?
    let added1y: Int?
}

struct NewHire: Identifiable {
    let id = UUID()
    let date: String
    let seniorHires: String
    let otherHires: String
}

struct JobOpenings {
    let distribution: [String: String]
    let openingsDetails: [JobOpeningDetail]
    let jobOpeningsGrowth: [JobOpeningGrowth]
}

struct JobOpeningDetail: Identifiable {
    let id = UUID()
    let function: String
    let numEmployees: String
    let percentage: String
    let growth3m: String
    let growth6m: String
}

struct JobOpeningGrowth: Identifiable {
    let id = UUID()
    let function: String
    let growth3m: String
    let growth6m: String
}

struct JobOpeningPlainText: Identifiable {
    let id = UUID()
    let function: String
    let numEmployees: String
    let growth3m: String
    let growth6m: String
}

struct LinkedInInsightsData {
    let employeeGrowth: [EmployeeGrowth]
    let functionDistribution: FunctionDistribution
    let headcountGrowth: [HeadcountGrowth]
    let newHires: [NewHire]
    let jobOpenings: JobOpenings
    let jobOpeningsPlainText: [JobOpeningPlainText]
    let medianTenure: String?
    let totalEmployees: [String: String]
}

// MARK: - Helper Functions

func cleanGrowthString(_ growthStr: String) -> String {
    let pattern = #"(.*?)(-?\d+%)\s*(\b.*)"#
    let regex = try! NSRegularExpression(pattern: pattern)
    let range = NSRange(growthStr.startIndex..<growthStr.endIndex, in: growthStr)
    if let match = regex.firstMatch(in: growthStr, range: range) {
        let percent = String(growthStr[Range(match.range(at: 2), in: growthStr)!])
        let trend = String(growthStr[Range(match.range(at: 3), in: growthStr)!]).trimmingCharacters(in: .whitespaces)
        return trend.isEmpty ? percent : "\(percent) \(trend)"
    }
    return growthStr
}

func parseGrowthPercentage(_ growthStr: String) -> Int? {
    if growthStr.contains("No change") { return 0 }
    let pattern = #"(\d+)%"#
    let regex = try! NSRegularExpression(pattern: pattern)
    let range = NSRange(growthStr.startIndex..<growthStr.endIndex, in: growthStr)
    if let match = regex.firstMatch(in: growthStr, range: range),
       let percentStr = Range(match.range(at: 1), in: growthStr) {
        var percent = Int(growthStr[percentStr])!
        if growthStr.lowercased().contains("decrease") {
            percent = -percent
        }
        return percent
    }
    return nil
}

func calculateAdded(current: String, growthPercent: Int?) -> Int? {
    guard let growthPercent = growthPercent,
          let n = Int(current.replacingOccurrences(of: ",", with: "")) else { return nil }
    if growthPercent == 0 { return 0 }
    let previous = Double(n) / (1.0 + Double(growthPercent) / 100.0)
    let added = Double(n) - previous
    return Int(added.rounded())
}

// MARK: - Extraction Functions

func extractEmployeeGrowth(from doc: Document) throws -> [EmployeeGrowth] {
    var data: [EmployeeGrowth] = []
    guard let group = try doc.select("g[class*=highcharts-markers]").first() else { return data }
    let paths = try group.select("path[aria-label]")
    let pattern = #"^\d+\.\s+([^,]+),\s+([^,]+)\s+(\d+),\s+([^,]+),\s+([\d,]+) employees(?:, (.+))?$"#
    let regex = try NSRegularExpression(pattern: pattern)

    for path in paths {
        let label = try path.attr("aria-label")
        let range = NSRange(label.startIndex..<label.endIndex, in: label)
        if let match = regex.firstMatch(in: label, range: range) {
            let dayOfWeek = String(label[Range(match.range(at: 1), in: label)!])
            let month = String(label[Range(match.range(at: 2), in: label)!])
            let day = String(label[Range(match.range(at: 3), in: label)!])
            let time = String(label[Range(match.range(at: 4), in: label)!])
            let countStr = String(label[Range(match.range(at: 5), in: label)!]).replacingOccurrences(of: ",", with: "")
            let employeeCount = Int(countStr) ?? 0
            let growth = match.numberOfRanges > 6 ? String(label[Range(match.range(at: 6), in: label)!]) : ""
            data.append(EmployeeGrowth(dayOfWeek: dayOfWeek, month: month, day: day, time: time, employeeCount: employeeCount, growth: growth, year: nil))
        }
    }

    let monthMap: [String: Int] = ["Jan": 1, "Feb": 2, "Mar": 3, "Apr": 4, "May": 5, "Jun": 6, "Jul": 7, "Aug": 8, "Sep": 9, "Oct": 10, "Nov": 11, "Dec": 12]
    if let lastIndex = data.indices.reversed().first(where: { monthMap[data[$0].month] != nil }) {
        data[lastIndex].year = 2025
        for i in (0..<lastIndex).reversed() {
            if let currentMonth = monthMap[data[i].month],
               let nextMonth = monthMap[data[i + 1].month],
               let nextYear = data[i + 1].year {
                data[i].year = nextMonth == 1 && currentMonth == 12 ? nextYear - 1 : nextYear
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
    let rows = try table.select("tr").array()[1...] // Skip header
    for row in rows {
        let cells = try row.select("td").array()
        if cells.count >= 5 {
            let function = try cells[0].text().trimmingCharacters(in: .whitespaces)
            let numEmployees = try cells[1].text().trimmingCharacters(in: .whitespaces)
            let percentage = try cells[2].text().trimmingCharacters(in: .whitespaces)
            let growth6m = cleanGrowthString(try cells[3].text().trimmingCharacters(in: .whitespaces))
            let growth1y = cleanGrowthString(try cells[4].text().trimmingCharacters(in: .whitespaces))
            growthData.append(HeadcountGrowth(function: function, numEmployees: numEmployees, percentage: percentage, growth6m: growth6m, growth1y: growth1y, added6m: nil, added1y: nil))
        }
    }
    return growthData
}

func extractNewHires(from doc: Document) throws -> [NewHire] {
    var hires: [NewHire] = []
    guard let table = try doc.select("table[summary*=Senior hires over time]").first() else { return hires }
    let rows = try table.select("tr").array()[1...] // Skip header
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
    var result = JobOpenings(distribution: [:], openingsDetails: [], jobOpeningsGrowth: [])
    guard let jobModule = try doc.select("section[class*=org-insights-jobs-module]").first() else { return result }

    // Distribution
    if let distTable = try jobModule.select("div.org-function-percentage-table").first() {
        let rows = try distTable.select("tr")
        for row in rows {
            if let td = try row.select("td").first(), let strong = try td.select("strong").first() {
                let percentage = try strong.text().trimmingCharacters(in: .whitespaces)
                let text = try td.text().trimmingCharacters(in: .whitespaces)
                let parts = text.split(separator: "·").map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count >= 2 {
                    result.distribution[parts[1]] = percentage
                }
            }
        }
    }

    // Openings Details
    if let detailsTable = try jobModule.select("table[id=function-growth__a11y-jobs-table]").first() {
        let rows = try detailsTable.select("tr").array()[1...]
        for row in rows {
            let cells = try row.select("td").array()
            if cells.count >= 5 {
                let function = try cells[0].text().trimmingCharacters(in: .whitespaces)
                let numEmployees = try cells[1].text().trimmingCharacters(in: .whitespaces)
                let percentage = try cells[2].text().trimmingCharacters(in: .whitespaces)
                let growth3m = cleanGrowthString(try cells[3].text().trimmingCharacters(in: .whitespaces))
                let growth6m = cleanGrowthString(try cells[4].text().trimmingCharacters(in: .whitespaces))
                result.openingsDetails.append(JobOpeningDetail(function: function, numEmployees: numEmployees, percentage: percentage, growth3m: growth3m, growth6m: growth6m))
            }
        }
    }

    // Job Openings Growth
    if let growthTable = try jobModule.select("table[class*=org-insights-functions-growth__table]").first() {
        let rows = try growthTable.select("tr").array()[1...]
        for row in rows {
            let cells = try row.select("td").array()
            if cells.count >= 3 {
                let function = try cells[0].text().trimmingCharacters(in: .whitespaces)
                let growth3m = cleanGrowthString(try cells[1].text().trimmingCharacters(in: .whitespaces))
                let growth6m = cleanGrowthString(try cells[2].text().trimmingCharacters(in: .whitespaces))
                result.jobOpeningsGrowth.append(JobOpeningGrowth(function: function, growth3m: growth3m, growth6m: growth6m))
            }
        }
    }
    return result
}

func extractJobOpeningsPlainText(from doc: Document) throws -> [JobOpeningPlainText] {
    var result: [JobOpeningPlainText] = []
    guard let growthDiv = try doc.select("div.org-function-growth-table").first(),
          let table = try growthDiv.select("table[id=function-growth__a11y-jobs-table]").first() else { return result }
    let rows = try table.select("tr").array()[1...]
    for row in rows {
        let cells = try row.select("td").array()
        if cells.count >= 5 {
            let function = try cells[0].text().trimmingCharacters(in: .whitespaces)
            let numEmployees = try cells[1].text().trimmingCharacters(in: .whitespaces)
            let growth3m = cleanGrowthString(try cells[3].text().trimmingCharacters(in: .whitespaces))
            let growth6m = cleanGrowthString(try cells[4].text().trimmingCharacters(in: .whitespaces))
            result.append(JobOpeningPlainText(function: function, numEmployees: numEmployees, growth3m: growth3m, growth6m: growth6m))
        }
    }
    return result
}

func extractMedianTenure(from doc: Document) -> String? {
    let text = try? doc.text()
    let pattern = #"Median employee tenure.*?([\d.]+) years"#
    let regex = try! NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
    if let text = text, let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
        let range = Range(match.range(at: 1), in: text)!
        return String(text[range]) + " years"
    }
    return nil
}

func extractTotalEmployees(from doc: Document) throws -> [String: String] {
    var result: [String: String] = [:]
    guard let table = try doc.select("table[summary=Total employee count]").first() else { return result }
    if let totalSpan = try table.select("span.t-bold").first() {
        result["total_employees"] = try totalSpan.text().trimmingCharacters(in: .whitespaces)
    }
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

func extractData(from html: String) throws -> LinkedInInsightsData {
    let doc = try SwiftSoup.parse(html)
    let employeeGrowth = try extractEmployeeGrowth(from: doc)
    let functionDistribution = try extractFunctionDistribution(from: doc)
    var headcountGrowth = try extractHeadcountGrowth(from: doc)
    let newHires = try extractNewHires(from: doc)
    let jobOpenings = try extractJobOpenings(from: doc)
    let jobOpeningsPlainText = try extractJobOpeningsPlainText(from: doc)
    let medianTenure = extractMedianTenure(from: doc)
    let totalEmployees = try extractTotalEmployees(from: doc)

    headcountGrowth = headcountGrowth.map { item in
        let growth6mPercent = parseGrowthPercentage(item.growth6m)
        let growth1yPercent = parseGrowthPercentage(item.growth1y)
        let added6m = calculateAdded(current: item.numEmployees, growthPercent: growth6mPercent)
        let added1y = calculateAdded(current: item.numEmployees, growthPercent: growth1yPercent)
        return HeadcountGrowth(function: item.function, numEmployees: item.numEmployees, percentage: item.percentage, growth6m: item.growth6m, growth1y: item.growth1y, added6m: added6m, added1y: added1y)
    }

    return LinkedInInsightsData(employeeGrowth: employeeGrowth, functionDistribution: functionDistribution, headcountGrowth: headcountGrowth, newHires: newHires, jobOpenings: jobOpenings, jobOpeningsPlainText: jobOpeningsPlainText, medianTenure: medianTenure, totalEmployees: totalEmployees)
}

// MARK: - SwiftUI View for File Selection

struct ParserView: View {
    @State private var isPresentingFileImporter = false
    @State private var parsedData: LinkedInInsightsData?

    var body: some View {
        VStack {
            Button("Select HTML File") {
                isPresentingFileImporter = true
            }
            .padding()
            .fileImporter(isPresented: $isPresentingFileImporter, allowedContentTypes: [.html]) { result in
                switch result {
                case .success(let url):
                    do {
                        let html = try String(contentsOf: url)
                        parsedData = try extractData(from: html)
                        // Pass parsedData to visualization or handle as needed
                        print("Parsed data: \(parsedData)")
                    } catch {
                        print("Error reading or parsing file: \(error)")
                    }
                case .failure(let error):
                    print("Error selecting file: \(error)")
                }
            }

            if parsedData != nil {
                Text("File processed successfully. Data ready for visualization.")
                    .foregroundColor(.green)
            } else {
                Text("Select an HTML file to process")
            }
        }
    }
}

// MARK: - App Entry Point

@main
struct LinkedInParserApp: App {
    var body: some Scene {
        WindowGroup {
            ParserView()
        }
    }
}