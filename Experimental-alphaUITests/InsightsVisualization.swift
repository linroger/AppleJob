import SwiftUI
import Charts

// Assume LinkedInInsightsData and its structs are defined as in the parsing script
// For brevity, they are not redefined here but should be imported or included

// MARK: - Extensions for Chart Data

extension EmployeeGrowth {
    var date: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        let dateString = "\(month) \(day), \(year ?? 2025)"
        return dateFormatter.date(from: dateString)
    }
}

extension NewHire {
    var chartDate: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        return dateFormatter.date(from: date)
    }
}

// MARK: - Visualization View

struct VisualizerView: View {
    let data: LinkedInInsightsData

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Median Tenure
                if let medianTenure = data.medianTenure {
                    Text("Median Employee Tenure: \(medianTenure)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.bottom, 10)
                }

                // Total Employees
                if let totalEmployees = data.totalEmployees["total_employees"] {
                    Text("Total Employees: \(totalEmployees)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.bottom, 10)
                }

                // Employee Growth Chart
                if !data.employeeGrowth.isEmpty {
                    SectionHeader(title: "Employee Growth Over Time")
                    EmployeeGrowthChart(employeeGrowth: data.employeeGrowth)
                }

                // Function Distribution Chart
                if !data.functionDistribution.isEmpty {
                    SectionHeader(title: "Function Distribution")
                    FunctionDistributionChart(distribution: data.functionDistribution)
                }

                // Headcount Growth Table
                if !data.headcountGrowth.isEmpty {
                    SectionHeader(title: "Headcount Growth")
                    HeadcountGrowthTable(headcountGrowth: data.headcountGrowth)
                }

                // New Hires Chart
                if !data.newHires.isEmpty {
                    SectionHeader(title: "New Hires Over Time")
                    NewHiresChart(newHires: data.newHires)
                }

                // Job Openings Distribution Chart
                if !data.jobOpenings.distribution.isEmpty {
                    SectionHeader(title: "Job Openings Distribution")
                    FunctionDistributionChart(distribution: data.jobOpenings.distribution)
                }

                // Job Openings Details Table
                if !data.jobOpenings.openingsDetails.isEmpty {
                    SectionHeader(title: "Job Openings Details")
                    JobOpeningsDetailsTable(details: data.jobOpenings.openingsDetails)
                }

                // Job Openings Growth Table
                if !data.jobOpenings.jobOpeningsGrowth.isEmpty {
                    SectionHeader(title: "Job Openings Growth")
                    JobOpeningsGrowthTable(growth: data.jobOpenings.jobOpeningsGrowth)
                }

                // Job Openings Plain Text Table
                if !data.jobOpeningsPlainText.isEmpty {
                    SectionHeader(title: "Job Openings Plain Text")
                    JobOpeningsPlainTextTable(plainText: data.jobOpeningsPlainText)
                }
            }
            .padding()
        }
    }
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

    var body: some View {
        Chart {
            ForEach(employeeGrowth.filter { $0.date != nil }, id: \.date) { item in
                LineMark(
                    x: .value("Date", item.date!),
                    y: .value("Employee Count", item.employeeCount)
                )
                .foregroundStyle(.blue)
            }
        }
        .chartXScale(domain: .automatic)
        .chartYScale(domain: .automatic)
        .frame(height: 300)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct FunctionDistributionChart: View {
    let distribution: [String: String]

    var body: some View {
        Chart {
            ForEach(distribution.keys.sorted(), id: \.self) { key in
                if let value = distribution[key], let percent = Double(value.replacingOccurrences(of: "%", with: "")) {
                    BarMark(
                        x: .value("Function", key),
                        y: .value("Percentage", percent)
                    )
                    .foregroundStyle(.purple)
                }
            }
        }
        .chartXScale(domain: .automatic)
        .chartYScale(domain: 0...100)
        .frame(height: 300)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct NewHiresChart: View {
    let newHires: [NewHire]

    var body: some View {
        Chart {
            ForEach(newHires.filter { $0.chartDate != nil }, id: \.chartDate) { hire in
                if let senior = Int(hire.seniorHires), let other = Int(hire.otherHires) {
                    LineMark(
                        x: .value("Date", hire.chartDate!),
                        y: .value("Senior Hires", senior)
                    )
                    .foregroundStyle(.orange)
                    LineMark(
                        x: .value("Date", hire.chartDate!),
                        y: .value("Other Hires", other)
                    )
                    .foregroundStyle(.green)
                }
            }
        }
        .chartXScale(domain: .automatic)
        .chartYScale(domain: .automatic)
        .chartLegend(.visible)
        .frame(height: 300)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Table Views

struct HeadcountGrowthTable: View {
    let headcountGrowth: [HeadcountGrowth]

    var body: some View {
        List(headcountGrowth) { item in
            VStack(alignment: .leading, spacing: 5) {
                Text(item.function).font(.subheadline).bold()
                HStack {
                    Text("Employees: \(item.numEmployees)")
                    Spacer()
                    Text("Percentage: \(item.percentage)%")
                }
                HStack {
                    Text("6m Growth: \(item.growth6m)")
                    Spacer()
                    Text("1y Growth: \(item.growth1y)")
                }
                if let added6m = item.added6m {
                    Text("Added 6m: \(added6m)")
                }
                if let added1y = item.added1y {
                    Text("Added 1y: \(added1y)")
                }
            }
            .padding(.vertical, 5)
        }
        .frame(height: CGFloat(headcountGrowth.count * 120))
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct JobOpeningsDetailsTable: View {
    let details: [JobOpeningDetail]

    var body: some View {
        List(details) { item in
            VStack(alignment: .leading, spacing: 5) {
                Text(item.function).font(.subheadline).bold()
                HStack {
                    Text("Openings: \(item.numEmployees)")
                    Spacer()
                    Text("Percentage: \(item.percentage)%")
                }
                HStack {
                    Text("3m Growth: \(item.growth3m)")
                    Spacer()
                    Text("6m Growth: \(item.growth6m)")
                }
            }
            .padding(.vertical, 5)
        }
        .frame(height: CGFloat(details.count * 80))
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct JobOpeningsGrowthTable: View {
    let growth: [JobOpeningGrowth]

    var body: some View {
        List(growth) { item in
            VStack(alignment: .leading, spacing: 5) {
                Text(item.function).font(.subheadline).bold()
                HStack {
                    Text("3m Growth: \(item.growth3m)")
                    Spacer()
                    Text("6m Growth: \(item.growth6m)")
                }
            }
            .padding(.vertical, 5)
        }
        .frame(height: CGFloat(growth.count * 60))
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct JobOpeningsPlainTextTable: View {
    let plainText: [JobOpeningPlainText]

    var body: some View {
        List(plainText) { item in
            VStack(alignment: .leading, spacing: 5) {
                Text(item.function).font(.subheadline).bold()
                HStack {
                    Text("Employees: \(item.numEmployees)")
                    Spacer()
                }
                HStack {
                    Text("3m Growth: \(item.growth3m)")
                    Spacer()
                    Text("6m Growth: \(item.growth6m)")
                }
            }
            .padding(.vertical, 5)
        }
        .frame(height: CGFloat(plainText.count * 80))
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Preview or Usage Example

struct VisualizerView_Previews: PreviewProvider {
    static var previews: some View {
        // Sample data for preview
        let sampleData = LinkedInInsightsData(
            employeeGrowth: [EmployeeGrowth(dayOfWeek: "Tuesday", month: "Feb", day: "28", time: "16:00", employeeCount: 3851, growth: "", year: 2023)],
            functionDistribution: ["Finance": "22%"],
            headcountGrowth: [HeadcountGrowth(function: "Finance", numEmployees: "784", percentage: "22", growth6m: "1% increase", growth1y: "1% decrease", added6m: 8, added1y: -8)],
            newHires: [NewHire(date: "March 2023", seniorHires: "0", otherHires: "16")],
            jobOpenings: JobOpenings(distribution: ["Finance": "20%"], openingsDetails: [JobOpeningDetail(function: "Finance", numEmployees: "35", percentage: "20", growth3m: "10% decrease", growth6m: "24% decrease")], jobOpeningsGrowth: [JobOpeningGrowth(function: "Finance", growth3m: "10% decrease", growth6m: "24% decrease")]),
            jobOpeningsPlainText: [JobOpeningPlainText(function: "Finance", numEmployees: "784", growth3m: "1% increase", growth6m: "1% decrease")],
            medianTenure: "5.2 years",
            totalEmployees: ["total_employees": "3603"]
        )
        VisualizerView(data: sampleData)
    }
}