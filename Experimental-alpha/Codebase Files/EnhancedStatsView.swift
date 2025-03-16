//
//  EnhancedStatsView.swift
//  Experimental-alpha
//
//  Created by Roger Lin on 3/14/25.
//


// -----------------------------------------------------------------------------
// MARK: - EnhancedStatsView
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


// --------------------------------------------------
// MARK: - EnhancedStatsView
// --------------------------------------------------
import SwiftUI
import Charts
import MapKit

// --------------------------------------------------
// MARK: - EnhancedStatsView
// --------------------------------------------------
struct EnhancedStatsView: View {
    // Environment objects
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore
    
    // MARK: - State Variables
    
    // General selection/hover states
    @State private var selectedSalaryValue: Double?
    @State private var hoveredJobID: UUID? = nil         // For salary chart tooltip (from snippet one)
    @State private var hoveredPieJobID: UUID? = nil        // For pie chart hover (from snippet two)
    @State private var hoveredSalaryItemID: UUID? = nil    // Additional hover state (from snippet two)
    @State private var selectedSalaryItem: SalaryRangeItem? = nil
    
    // Year and time-range states
    @State private var selectedYear: Int = -1
    @State private var availableYears: [Int] = []
    @State private var selectedTimeRange: TimeRange = .month
    @AppStorage("StatsViewTimeRange") private var selectedTimeRangeRaw: String = TimeRange.month.rawValue
    
    // Data storage arrays
    @State private var cityPins: [CityPin] = []
    @State private var barLineData: [DailyApps] = []
    @State private var yearContributionData: [Contribution] = []
    @State private var appsContributionData: [Contribution] = []
    @State private var monthlyCityData: [MonthlyCityData] = []
    @State private var filteredMonthlyCityData: [MonthlyCityData] = []
    @State private var salaryRangeData: [SalaryRangeItem] = []
    
    // Selected chart dates
    @State private var barLineSelectedDate: Date? = nil
    @State private var yearChartSelectedDate: Date? = nil
    @State private var appsChartSelectedDate: Date? = nil
    
    // Map region
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 50)
    )
    
    // Time range options
    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case sixmonth = "Six Months"
        case year = "Year"
        var id: String { rawValue }
    }
    
    // --------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------
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
                HorizontalStackedBarChartIfAvailable(monthlyCityData: filteredMonthlyCityData)
                singleColumnVerticallyStackedBarChartSection
                top20CompaniesBarSection
                citiesByFrequencySection
                companiesByFrequencySection
                pieChartsSection
                Divider()
                salaryRangeChartSection
            }
            .padding()
        }
        .onAppear {
            setupViewOnAppear()
            asyncComputeBarLineData()
        }
        .onChange(of: selectedTimeRange) { _, _ in
            selectedTimeRangeRaw = selectedTimeRange.rawValue
            asyncComputeBarLineData()
        }
        .onChange(of: selectedYear) { _, _ in
            refreshYearDependentData()
        }
        .onChange(of: monthlyCityData) { _, _ in
            filterMonthlyCityDataForSelectedYear()
        }
    }
    
    private func jobDetailTooltip(for item: SalaryRangeItem) -> some View {
        VStack(alignment: .leading) {
            Text(item.jobTitle)
                .font(.headline)
            Text(item.company)
                .font(.subheadline)
            Text("Salary Range: \(item.minSalary.formatted(.currency(code: "USD"))) - \(item.maxSalary.formatted(.currency(code: "USD")))")
                .font(.subheadline)
            Text("Date: \(item.date.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // --------------------------------------------------
    // MARK: - Setup Methods
    // --------------------------------------------------
    private func setupViewOnAppear() {
        if let tr = TimeRange(rawValue: selectedTimeRangeRaw) {
            selectedTimeRange = tr
        } else {
            selectedTimeRange = .month
        }
        setupAvailableYears()
        refreshYearDependentData()
    }
    
    private func refreshYearDependentData() {
        asyncComputeCityPins()
        asyncComputeYearContribution()
        asyncComputeAppsContribution()
        asyncComputeMonthlyCityData()
        asyncComputeSalaryRangeData()
    }
    
    // --------------------------------------------------
    // MARK: - Async Data Computations
    // --------------------------------------------------
    private func asyncComputeCityPins() {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = buildCityPins()
            DispatchQueue.main.async {
                self.cityPins = result
            }
        }
    }
    
    private func asyncComputeYearContribution() {
        DispatchQueue.global(qos: .userInitiated).async {
            let data = buildYearContribution()
            DispatchQueue.main.async {
                self.yearContributionData = data
            }
        }
    }
    
    private func asyncComputeAppsContribution() {
        DispatchQueue.global(qos: .userInitiated).async {
            let data = buildAppsContribution()
            DispatchQueue.main.async {
                self.appsContributionData = data
            }
        }
    }
    
    private func asyncComputeBarLineData() {
        DispatchQueue.global(qos: .userInitiated).async {
            let data = buildBarLineData()
            DispatchQueue.main.async {
                self.barLineData = data
            }
        }
    }
    
    private func asyncComputeMonthlyCityData() {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = buildMonthlyCityData()
            DispatchQueue.main.async {
                self.monthlyCityData = result
                self.filterMonthlyCityDataForSelectedYear()
            }
        }
    }
    
    private func asyncComputeSalaryRangeData() {
        DispatchQueue.global(qos: .userInitiated).async {
            let data = buildSalaryRangeData()
            DispatchQueue.main.async {
                self.salaryRangeData = data
            }
        }
    }
    // -----------------------------
    // Time Range Picker
    // -----------------------------
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
    // --------------------------------------------------
    // MARK: - Data Building Methods
    // --------------------------------------------------
    private func buildCityPins() -> [CityPin] {
        var cityCount: [String: Int] = [:]
        for job in jobStore.jobApplications {
            cityCount[job.location, default: 0] += 1
        }
        return cityCount.map { (city, ct) in
            let coord = CityCoordinateDictionary[city]
            ?? CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795)
            return CityPin(city: city, coordinate: coord, count: ct)
        }
    }
    
    private func buildYearContribution() -> [Contribution] {
        guard !jobStore.jobApplications.isEmpty else {
            return []
        }
        let cal = Calendar.current
        let allDates = jobStore.jobApplications.map { $0.dateOfApplication }
        
        if selectedYear == -1 {
            guard let end = allDates.max() else {
                return []
            }
            let start = cal.date(byAdding: .month, value: -12, to: end) ?? end
            var contributionMap: [Date: Int] = [:]
            for job in jobStore.jobApplications {
                if job.dateOfApplication >= start && job.dateOfApplication <= end {
                    let day = cal.startOfDay(for: job.dateOfApplication)
                    contributionMap[day, default: 0] += 1
                }
            }
            var allDays: [Date] = []
            var day = cal.startOfDay(for: start)
            while day <= end {
                allDays.append(day)
                if let nxt = cal.date(byAdding: .day, value: 1, to: day) {
                    day = nxt
                } else { break }
            }
            return allDays.map { d in
                Contribution(date: d, count: contributionMap[d] ?? 0)
            }
        } else {
            guard let s = cal.date(from: DateComponents(year: selectedYear, month: 1, day: 1)),
                  let e = cal.date(from: DateComponents(year: selectedYear, month: 12, day: 31))
            else { return [] }
            var contributionMap: [Date: Int] = [:]
            for job in jobStore.jobApplications {
                if job.dateOfApplication >= s && job.dateOfApplication <= e {
                    let day = cal.startOfDay(for: job.dateOfApplication)
                    contributionMap[day, default: 0] += 1
                }
            }
            var allDays: [Date] = []
            var day = cal.startOfDay(for: s)
            while day <= e {
                allDays.append(day)
                if let nxt = cal.date(byAdding: .day, value: 1, to: day) {
                    day = nxt
                } else { break }
            }
            return allDays.map { d in
                Contribution(date: d, count: contributionMap[d] ?? 0)
            }
        }
    }
    
    private func buildAppsContribution() -> [Contribution] {
        let cal = Calendar.current
        let allDates = jobStore.jobApplications.map { $0.dateOfApplication }
        guard !allDates.isEmpty else { return [] }
        
        if selectedYear == -1 {
            guard let end = allDates.max() else { return [] }
            let start = cal.date(byAdding: .month, value: -12, to: end) ?? end
            var appsMap: [Date: Int] = [:]
            for job in jobStore.jobApplications {
                if job.dateOfApplication >= start && job.dateOfApplication <= end {
                    let day = cal.startOfDay(for: job.dateOfApplication)
                    appsMap[day, default: 0] += 1
                }
            }
            var allDays: [Date] = []
            var day = cal.startOfDay(for: start)
            while day <= end {
                allDays.append(day)
                if let nxt = cal.date(byAdding: .day, value: 1, to: day) {
                    day = nxt
                } else { break }
            }
            return allDays.map { d in
                Contribution(date: d, count: appsMap[d] ?? 0)
            }
        } else {
            guard let s = cal.date(from: DateComponents(year: selectedYear, month: 1, day: 1)),
                  let e = cal.date(from: DateComponents(year: selectedYear, month: 12, day: 31))
            else { return [] }
            var appsMap: [Date: Int] = [:]
            for job in jobStore.jobApplications {
                if job.dateOfApplication >= s && job.dateOfApplication <= e {
                    let day = cal.startOfDay(for: job.dateOfApplication)
                    appsMap[day, default: 0] += 1
                }
            }
            var allDays: [Date] = []
            var day = cal.startOfDay(for: s)
            while day <= e {
                allDays.append(day)
                if let nxt = cal.date(byAdding: .day, value: 1, to: day) {
                    day = nxt
                } else { break }
            }
            return allDays.map { d in
                Contribution(date: d, count: appsMap[d] ?? 0)
            }
        }
    }
    
    private func buildBarLineData() -> [DailyApps] {
        let cal = Calendar.current
        let now = Date()
        var startDate: Date?
        switch selectedTimeRange {
        case .week:
            startDate = cal.date(byAdding: .day, value: -7, to: now)
        case .month:
            startDate = cal.date(byAdding: .month, value: -1, to: now)
        case .sixmonth:
            startDate = cal.date(byAdding: .month, value: -6, to: now)
        case .year:
            startDate = cal.date(byAdding: .year, value: -1, to: now)
        }
        guard let start = startDate else { return [] }
        var dailyMap: [Date: Int] = [:]
        for job in jobStore.jobApplications {
            if job.dateOfApplication >= start && job.dateOfApplication <= now {
                let day = cal.startOfDay(for: job.dateOfApplication)
                dailyMap[day, default: 0] += 1
            }
        }
        var allDays: [Date] = []
        var day = cal.startOfDay(for: start)
        while day <= now {
            allDays.append(day)
            guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return allDays.map { d in
            DailyApps(date: d, count: dailyMap[d] ?? 0)
        }
    }
    
    private func buildMonthlyCityData() -> [MonthlyCityData] {
        var results: [MonthlyCityData] = []
        let cal = Calendar.current
        
        for job in jobStore.jobApplications {
            let jobYear = cal.component(.year, from: job.dateOfApplication)
            if selectedYear != -1, jobYear != selectedYear { continue }
            let month = cal.component(.month, from: job.dateOfApplication)
            let monthKey = "\(cal.shortMonthSymbols[month - 1])"
            results.append(
                MonthlyCityData(
                    monthKey: monthKey,
                    city: job.location,
                    count: 1,
                    date: job.dateOfApplication
                )
            )
        }
        var grouped: [String: MonthlyCityData] = [:]
        for item in results {
            let key = item.monthKey + "_" + item.city
            if let existing = grouped[key] {
                grouped[key] = MonthlyCityData(
                    monthKey: existing.monthKey,
                    city: existing.city,
                    count: existing.count + 1,
                    date: existing.date
                )
            } else {
                grouped[key] = item
            }
        }
        let final = grouped.map { $0.value }.sorted {
            let monthOrder = Calendar.current.shortMonthSymbols
            guard
                let idxA = monthOrder.firstIndex(of: $0.monthKey),
                let idxB = monthOrder.firstIndex(of: $1.monthKey)
            else { return false }
            return idxA < idxB
        }
        return final
    }
    
    private func filterMonthlyCityDataForSelectedYear() {
        let cal = Calendar.current
        if selectedYear == -1 {
            filteredMonthlyCityData = monthlyCityData
        } else {
            filteredMonthlyCityData = monthlyCityData.filter {
                cal.component(.year, from: $0.date) == selectedYear
            }
        }
    }
    
    private func buildSalaryRangeData() -> [SalaryRangeItem] {
        let cal = Calendar.current
        let filteredApps = jobStore.jobApplications.filter {
            selectedYear == -1 || cal.component(.year, from: $0.dateOfApplication) == selectedYear
        }
        let sortedApps = filteredApps.sorted { $0.dateOfApplication < $1.dateOfApplication }
        var result: [SalaryRangeItem] = []
        for (idx, app) in sortedApps.enumerated() {
            guard let minVal = app.salaryMin, minVal > 0,
                  let maxVal = app.salaryMax, maxVal > 0
            else { continue }
            let item = SalaryRangeItem(
                jobID: app.id,
                company: app.companyName,
                jobTitle: app.jobTitle,
                date: app.dateOfApplication,
                minSalary: minVal,
                maxSalary: maxVal,
                orderIndex: idx
            )
            result.append(item)
        }
        return result
    }
    
    private func setupAvailableYears() {
        let allDates = jobStore.jobApplications.map { $0.dateOfApplication }
        guard !allDates.isEmpty else {
            self.availableYears = []
            self.selectedYear = -1
            return
        }
        let cal = Calendar.current
        guard let minDate = allDates.min(), let maxDate = allDates.max() else { return }
        let minYear = cal.component(.year, from: minDate)
        let maxYear = cal.component(.year, from: maxDate)
        self.availableYears = minYear <= maxYear ? Array(minYear...maxYear) : []
        if !self.availableYears.contains(selectedYear) && selectedYear != -1 {
            self.selectedYear = -1
        }
    }
    
    // --------------------------------------------------
    // MARK: - Helper Functions for Frequency Lists
    // --------------------------------------------------
    private func topCompanyName() -> String {
        let sorted = companyFreqList()
        guard let first = sorted.first else { return "N/A" }
        return first.name
    }
    
    private func topCity() -> (String, Int) {
        let sorted = cityFreqList()
        guard let first = sorted.first else { return ("N/A", 0) }
        return first
    }
    
    private func cityFreqList() -> [(city: String, count: Int)] {
        var map: [String: Int] = [:]
        for job in jobStore.jobApplications {
            map[job.location, default: 0] += 1
        }
        return map.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }
    
    private func companyFreqList() -> [(name: String, count: Int)] {
        var map: [String: Int] = [:]
        for job in jobStore.jobApplications {
            map[job.companyName, default: 0] += 1
        }
        return map.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }
    
    private func yearFreqList() -> [(year: String, count: Int)] {
        var yearCounts: [String: Int] = [:]
        let cal = Calendar.current
        for job in jobStore.jobApplications {
            let yearString = String(cal.component(.year, from: job.dateOfApplication))
            yearCounts[yearString, default: 0] += 1
        }
        return yearCounts.map { (year: $0.key, count: $0.value) }.sorted { $0.year < $1.year }
    }
    
    private func computeAverage(for data: [DailyApps]) -> Double? {
        let nonZeroData = data.filter { $0.count > 0 }
        guard !nonZeroData.isEmpty else { return nil }
        let totalApplications = nonZeroData.reduce(0) { $0 + $1.count }
        return Double(totalApplications) / Double(nonZeroData.count)
    }
    
    private func weekday(for date: Date) -> Int {
        Calendar.current.component(.weekday, from: date)
    }
    
    private var chartColors: [Color] {
        [
            .green.opacity(0.2),
            .green.opacity(0.4),
            .green.opacity(0.6),
            .green.opacity(0.8),
            .green
        ]
    }
    
    // --------------------------------------------------
    // MARK: - View Sections
    // --------------------------------------------------
    
    // -----------------------------
    // Map Section
    // -----------------------------
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Applications Map")
                .font(.headline)
            
            Map {
                ForEach(cityPins) { cityPin in
                    Annotation(cityPin.city, coordinate: cityPin.coordinate) {
                        Circle()
                            .fill(Color.red.opacity(0.5))
                            .frame(
                                width: circleSize(for: cityPin.count),
                                height: circleSize(for: cityPin.count)
                            )
                            .overlay(
                                Text("\(cityPin.count)")
                                    .foregroundColor(.white)
                                    .font(.system(size: 10))
                            )
                    }
                }
            }
            .frame(height: 300)
            .cornerRadius(20)
        }
        .padding()
    }
    
    private func circleSize(for count: Int) -> CGFloat {
        let base: CGFloat = 5
        let scale: CGFloat = 10
        return log10(CGFloat(count) * base) * scale
    }
    
    private var appliedCompaniesAndRolesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(jobStore.jobApplications.sorted(by: { $0.dateOfApplication > $1.dateOfApplication })) { job in
                    Button {
                        jobStore.selectedJobIDs = [job.id]
                    } label: {
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
                        .background(job == jobStore.selectedJob ? Color.blue.opacity(0.2) : Color.white.opacity(0.1))
                        .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // -----------------------------
    // Stats row
    // -----------------------------
    private var statsRowSection: some View {
        let total = jobStore.jobApplications.count
        let applied = jobStore.jobApplications.filter { $0.status == .applied }.count
        let interested = jobStore.jobApplications.filter { $0.status == .interested }.count
        let interviewed = jobStore.jobApplications.filter { $0.status == .interview }.count
        let distinctCities = Set(jobStore.jobApplications.map { $0.location }).count
        let topCompany = topCompanyName()
        let (topCityName, topCityCount) = topCity()
        let internshipCount = jobStore.jobApplications.filter { $0.jobType == .internship }.count
        let fullTimeCount = jobStore.jobApplications.filter { $0.jobType == .fullTime }.count
        
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
                VStack {
                    Text("Internships")
                    Text("\(internshipCount)")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(gradient)
                }
                VStack {
                    Text("Full-Time")
                    Text("\(fullTimeCount)")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(gradient)
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
    }
    
    
    // -----------------------------
    // Year Picker
    // -----------------------------
    private var dynamicYearPickerSection: some View {
        let sortedYears = availableYears.sorted()
        let yearsWithAll = sortedYears + [-1]
        return HStack {
            Text("Select Year:")
            Picker("Year", selection: $selectedYear) {
                ForEach(yearsWithAll, id: \.self) { yr in
                    if yr == -1 {
                        Text("All Years").tag(yr)
                    } else {
                        Text(verbatim: "\(yr)").tag(yr)
                    }
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
    }
    
    
    private func isLeapYear(_ date: Date) -> Bool {
        let year = Calendar.current.component(.year, from: date)
        return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
    }
    // -----------------------------
    // GitHub-Style Charts
    // -----------------------------
    private var githubChartsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("GitHub-Style Contribution Charts")
                .font(.headline)
                .padding(.bottom, 5)
            
            if #available(macOS 13.0, *) {
                // Year Progress Chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Year Progress Chart")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    // Using current year (2025) for special coloring
                    
                    Chart(yearContributionData) { item in
                        let isToday = Calendar.current.isDateInToday(item.date)
                        let isPast = item.date < Date()
                        let itemYear = Calendar.current.component(.year, from: item.date)
                        
                        // Special coloring for 2025 (current year) when showing all years
                        let is2025Cell = itemYear == 2025
                        let showSpecialColoring = selectedYear == -1 && is2025Cell
                        
                        RectangleMark(
                            x: .value("WeekOfYear", item.date, unit: .weekOfYear),
                            y: .value("DayOfWeek", weekday(for: item.date))
                        )
                        .foregroundStyle(
                            showSpecialColoring ?
                                (isPast ?
                                    (isToday ? Color.green : Color.green.opacity(0.6)) :
                                    Color.green.opacity(0.1)) :
                                (isPast ?
                                    (isToday ? Color.green : Color.green.opacity(0.6)) :
                                    Color.blue.opacity(0.2))
                        )
                        .cornerRadius(2)
                    }
                    .chartXSelection(value: $yearChartSelectedDate)
                    .frame(height: 240) // Increased height to prevent clipping
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) {
                            AxisValueLabel(format: .dateTime.month(.abbreviated))
                            AxisGridLine()
                            AxisTick()
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic) {
                            AxisValueLabel(format: .dateTime.weekday(.narrow))
                            AxisGridLine()
                            AxisTick()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .overlay(alignment: .topTrailing) {
                        if let sel = yearChartSelectedDate {
                            let dayStr = sel.formatted(date: .abbreviated, time: .omitted)
                            let selYear = Calendar.current.component(.year, from: sel)
                            let yearStartDate = Calendar.current.date(from: DateComponents(year: selYear, month: 1, day: 1))!
                            let dayOfYear = Calendar.current.dateComponents([.day], from: yearStartDate, to: sel).day ?? 0
                            let totalDays = isLeapYear(sel) ? 366.0 : 365.0
                            let percentage = Double(dayOfYear) / totalDays * 100
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(dayStr)
                                    .font(.headline)
                                Text("\(String(format: "%.1f", percentage))% of year")
                                    .font(.subheadline)
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                            .padding(8)
                        }
                    }
                }
                .padding(.bottom, 16)
                
                // Applications Chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Applications Per Day")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Chart(appsContributionData) { item in
                        RectangleMark(
                            x: .value("WeekOfYear", item.date, unit: .weekOfYear),
                            y: .value("DayOfWeek", weekday(for: item.date))
                        )
                        .foregroundStyle(
                            Color.green.opacity(
                                item.count > 0 ?
                                Double(min(item.count, 5)) / 5.0 * 0.8 + 0.2 :
                                    0.1
                            )
                        )
                        .cornerRadius(2)
                    }
                    .chartXSelection(value: $appsChartSelectedDate)
                    .frame(height: 240) // Increased height to prevent clipping
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) {
                            AxisValueLabel(format: .dateTime.month(.abbreviated))
                            AxisGridLine()
                            AxisTick()
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic) {
                            AxisValueLabel(format: .dateTime.weekday(.narrow))
                            AxisGridLine()
                            AxisTick()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .overlay(alignment: .topTrailing) {
                        if let sel = appsChartSelectedDate,
                           let count = appsContributionData.first(where: { $0.date == sel })?.count {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(sel.formatted(date: .abbreviated, time: .omitted))
                                    .font(.headline)
                                Text("\(count) application\(count == 1 ? "" : "s")")
                                    .font(.subheadline)
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                            .padding(8)
                        }
                    }
                }
            }
        }
    }
    
    
    
    
    
    // -----------------------------
    // Bar/Line Chart
    // -----------------------------
    // Bar chart with standardized styling and selection
    private var barLineChartsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Applications Frequency (Last \(selectedTimeRange.rawValue))")
                .font(.headline)
                .padding(.bottom, 5)
            
            let average = computeAverage(for: barLineData)
            
            Chart {
                ForEach(barLineData) { dayItem in
                    // Main bar marks for each date
                    BarMark(
                        x: .value("Date", dayItem.date),
                        y: .value("Applications", dayItem.count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.7), .blue]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(8) // Standardized rounded corners
                    
                    // Add selection rule mark if this date is selected
                    if let selectedDate = barLineSelectedDate,
                       Calendar.current.isDate(dayItem.date, inSameDayAs: selectedDate) {
                        RuleMark(
                            x: .value("Selected Date", dayItem.date)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5,5]))
                        .foregroundStyle(.orange.opacity(0.5))
                    }
                }
                
                // Average line overlay
                if let avg = average {
                    RuleMark(y: .value("Average", avg))
                        .lineStyle(StrokeStyle(lineWidth: 2.5, dash: [5]))
                        .foregroundStyle(Color.red.opacity(0.7))
                        .annotation(position: .trailing) {
                            Text("Avg: \(String(format: "%.1f", avg))")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .padding(4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.8))
                                )
                        }
                }
            }
            .chartXSelection(value: $barLineSelectedDate)
            .chartLegend(position: .bottom) // Standardized legend position
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .frame(height: 300)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(10)
            
            // Selection details overlay
            if let selectedDate = barLineSelectedDate,
               let selectedData = barLineData.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedDate.formatted(date: .long, time: .omitted))
                            .font(.headline)
                        
                        Text("\(selectedData.count) application\(selectedData.count == 1 ? "" : "s")")
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                        
                        if let avg = average {
                            Text(selectedData.count > Int(avg) ? "Above average" : "Below average")
                                .font(.caption)
                                .foregroundColor(selectedData.count > Int(avg) ? .green : .secondary)
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
    }
    
    // -----------------------------
    // Single Column Stacked Chart
    // -----------------------------
    private var singleColumnVerticallyStackedBarChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Applications by City - Monthly Distribution")
                .font(.headline)
                .padding(.bottom, 5)
            
            if #available(macOS 13.0, *) {
                Chart(filteredMonthlyCityData) { item in
                    BarMark(
                        x: .value("Month", item.monthKey),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(by: .value("City", item.city))
                    .cornerRadius(8) // Standardized rounded corners
                }
                .chartXAxis {
                    AxisMarks() { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .chartYAxis {
                    AxisMarks() { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .chartLegend(position: .bottom) // Standardized legend position
                .frame(height: 300)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(10)
            } else {
                Text("Requires macOS 13.0+.")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 10)
    }
    
    private var top20CompaniesBarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top 20 Companies by Application Frequency (All Years)")
                .font(.headline)
                .padding(.bottom, 5)
            
            if #available(macOS 13.0, *) {
                let freq = buildTop20CompanyFreq()
                let maxValue = freq.map { $0.count }.max() ?? 0
                let average = Double(freq.reduce(0) { $0 + $1.count }) / Double(max(1, freq.count))
                
                Chart(freq) { item in
                    BarMark(
                        x: .value("Company", item.name),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.7), .blue]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(8) // Standardized rounded corners
                }
                .chartXAxis {
                    AxisMarks() { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                            .font(.system(size: 9))
                    }
                }
                .chartYAxis {
                    AxisMarks() { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .chartYScale(domain: 0...(maxValue + 1))
                .chartLegend(position: .bottom) // Standardized legend position
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        let lineY = proxy.position(forY: average) ?? 0
                        
                        Rectangle()
                            .fill(.red.opacity(0.6))
                            .frame(height: 2)
                            .position(x: geometry.size.width / 2, y: lineY)
                            
                        Text("Avg: \(String(format: "%.1f", average))")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.8))
                                    .padding(.horizontal, -4)
                            )
                            .position(x: geometry.size.width - 50, y: lineY - 15)
                    }
                }
                .frame(height: 300)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(10)
            } else {
                Text("Requires macOS 13.0+.")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 10)
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
    
    private var citiesByFrequencySection: some View {
        let cityCounts = cityFreqList()
        return VStack(alignment: .leading) {
            Text("Cities by Frequency (All Years)")
                .font(.headline)
                .padding(.bottom, 5)
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
    
    private var companiesByFrequencySection: some View {
        let companies = companyFreqList()
        return VStack(alignment: .leading, spacing: 10) {
            Text("Companies By Frequency")
                .font(.headline)
                .padding(.bottom, 5)
            
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
    
    
    // -----------------------------
    // Pie Charts Section
    // -----------------------------
    private var pieChartsSection: some View {
        let monthData = filteredMonthlyCityData.groupedByMonth
        let cityData = MonthlyCityData.groupByCity(filteredMonthlyCityData)
        let yearData = yearFreqList()
        let selectedYearText = selectedYear == -1 ? "All Years" : "\(selectedYear)"
        
        return PieChartsSectionView(
            monthlyData: monthData,
            cityData: cityData,
            yearData: yearData,
            selectedYearText: selectedYearText
        )
    }
    
    
    // Vertical salary range chart with improved styling and annotations
    private var salaryRangeChartSection: some View {
        let sortedData: [SalaryRangeItem] = {
            var tempData = salaryRangeData.sorted { $0.date > $1.date }
            return tempData.enumerated().map { index, item in
                SalaryRangeItem(
                    jobID: item.jobID,
                    company: item.company,
                    jobTitle: item.jobTitle,
                    date: item.date,
                    minSalary: item.minSalary,
                    maxSalary: item.maxSalary,
                    orderIndex: index // Assign index without mutating array
                )
            }
        }()

        let midpoints = sortedData.map { ($0.minSalary + $0.maxSalary) / 2 }
        let avgMidpoint = midpoints.reduce(0, +) / Double(max(1, midpoints.count))

        return VStack(alignment: .leading) {
            Text("Salary Ranges for Job Applications")
                .font(.headline)
                .padding(.bottom, 5)
            
            Chart(sortedData) { item in
                RectangleMark(
                    xStart: .value("Min Salary", item.minSalary),
                    xEnd: .value("Max Salary", item.maxSalary),
                    y: .value("Job", item.orderIndex),
                    height: .fixed(16)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue.opacity(0.7), .blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
            }
            .chartXAxis {
                AxisMarks(position: .bottom) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .currency(code: "USD").notation(.compactName))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let idx = value.as(Int.self), idx >= 0 && idx < sortedData.count {
                            let item = sortedData[idx]
                            VStack(alignment: .leading) {
                                Text(item.company)
                                    .font(.system(size: 10))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .frame(width: 100, alignment: .leading)
                        } else {
                            Text("")
                        }
                    }
                    AxisGridLine()
                    AxisTick()
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.red.opacity(0.6))
                        .frame(width: 2)
                        .position(x: proxy.position(forX: avgMidpoint) ?? 0, y: geometry.size.height / 2)
                    
                    Text("Avg: \(avgMidpoint.formatted(.currency(code: "USD").notation(.compactName)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.8))
                                .padding(.horizontal, -4)
                        )
                        .position(x: (proxy.position(forX: avgMidpoint) ?? 0) + 50, y: 20)
                }
            }
            .chartXSelection(value: $selectedSalaryValue)
            .frame(height: max(CGFloat(sortedData.count) * 35, 400))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            
            if let selected = selectedSalaryValue,
               let item = sortedData.first(where: { $0.minSalary...$0.maxSalary ~= selected }) {
                jobDetailTooltip(for: item)
                    .padding(.top, 8)
            }
        }
        .padding(.vertical, 8)
    }
}

// --------------------------------------------------
// MARK: - HorizontalStackedBarChartIfAvailable
// --------------------------------------------------
@available(macOS 13.0, *)
struct HorizontalStackedBarChartIfAvailable: View {
    let monthlyCityData: [MonthlyCityData]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Applications by City - Horizontally Stacked Bar Chart")
                .font(.headline)
                .padding(.bottom, 5)
            Chart(monthlyCityData) { item in
                BarMark(
                    x: .value("Month", item.monthKey),
                    y: .value("Count", item.count)
                )
                .position(by: .value("City", item.city))
                .foregroundStyle(by: .value("City", item.city))
                .cornerRadius(8) // Standardized rounded corners
            }
            .chartXAxis {
                AxisMarks() { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks() { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartLegend(position: .bottom) // Standardized legend position
            .frame(height: 300)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(10)
        }
    }
}

//-----------------------------------------------------------------------------------------------------//

// --------------------------------------------------
// MARK: - PieChartsSectionView
// --------------------------------------------------
struct PieChartsSectionView: View {
    @State private var selectedMonthAngle: Double? = nil
    @State private var selectedCityAngle: Double? = nil
    @State private var selectedYearAngle: Double? = nil

    let monthlyData: [(monthKey: String, count: Int)]
    let cityData: [(city: String, count: Int)]
    let yearData: [(year: String, count: Int)]
    let selectedYearText: String

    var body: some View {
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
                .padding(.bottom, 8)

            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .top, spacing: 32) {
                    // 1) Month Pie
                    VStack(spacing: 10) {
                        Text("Share by Month (\(selectedYearText))")
                            .font(.subheadline)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.green, .teal]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        PieChartView(
                            data: monthlyData.map { (key: $0.monthKey, count: $0.count) },
                            selectedAngle: $selectedMonthAngle,
                            centerLabel: "Months"
                        )
                        .frame(width: 350, height: 350)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(10)
                        .padding(.vertical, 4)
                    }

                    // 2) City Pie
                    VStack(spacing: 10) {
                        Text("Share by City (\(selectedYearText))")
                            .font(.subheadline)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.pink, .orange]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        PieChartView(
                            data: cityData.map { (key: $0.city, count: $0.count) },
                            selectedAngle: $selectedCityAngle,
                            centerLabel: "Cities",
                            showLegend: true
                        )
                        .frame(width: 400, height: 350)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(10)
                        .padding(.vertical, 4)
                    }

                    // 3) Year Pie
                    VStack(spacing: 10) {
                        Text("Share by Year")
                            .font(.subheadline)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.indigo, .cyan]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        PieChartView(
                            data: yearData.map { (key: $0.year, count: $0.count) },
                            selectedAngle: $selectedYearAngle,
                            centerLabel: "Years"
                        )
                        .frame(width: 350, height: 350)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(10)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 8)
        }
    }
}

fileprivate struct AngleRangeItem {
    let key: String
    let range: Range<Double>
    let count: Int
}

// A Swift Charts “Pie” subview
// Update PieChartView to include centerpiece text and standardized styling
struct PieChartView: View {
    let data: [(key: String, count: Int)]
    @Binding var selectedAngle: Double?
    let centerLabel: String
    var showLegend: Bool = false
    var legendPosition: AnnotationPosition = .bottom  // Always use bottom for consistency

    var body: some View {
        if #available(macOS 13.0, *) {
            Chart(data, id: \.key) { item in
                SectorMark(
                    angle: .value("Count", item.count),
                    innerRadius: .ratio(0.618), // Golden ratio for aesthetics
                    angularInset: 1.5
                )
                .cornerRadius(8) // Standardized rounded corners
                .foregroundStyle(by: .value("Key", item.key))
                .opacity(item.key == selectedItemLabel(selectedAngle)?.key ? 1 : 0.65)
            }
            .chartLegend(position: .bottom) // Consistently anchor legend to bottom
            .chartAngleSelection(value: $selectedAngle)
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if let anchor = chartProxy.plotFrame {
                        let frame = geometry[anchor]
                        let selItem = selectedItemLabel(selectedAngle)
                        let label = selItem?.key ?? centerLabel
                        let count = selItem?.count ?? data.reduce(0) { $0 + $1.count }
                        let percentage = selItem != nil ? 
                            Double(selItem!.count) / Double(data.reduce(0) { $0 + $1.count }) * 100 : 100.0

                        VStack(spacing: 4) {
                            Text(label)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                            Text("\(count) apps")
                                .font(.title2.bold())
                                .foregroundStyle(.primary)
                            Text("\(Int(percentage))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: frame.width * 0.7)
                        .multilineTextAlignment(.center)
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
            }
            .frame(height: 350) // Standardized height
        } else {
            Text("Pie Chart requires macOS 13.0+")
                .foregroundColor(.secondary)
        }
    }

    private func selectedItemLabel(_ angle: Double?) -> (key: String, count: Int)? {
        guard let angle else { return nil }
        let ranges = buildAngleRanges(for: data)
        return ranges.first { $0.range.contains(angle) }
            .map { (key: $0.key, count: $0.count) }
    }

    private func buildAngleRanges(for entries: [(key: String, count: Int)]) -> [AngleRangeItem] {
        var result: [AngleRangeItem] = []
        var runningTotal: Double = 0
        for entry in entries {
            let start = runningTotal
            let end = runningTotal + Double(entry.count)
            result.append(
                AngleRangeItem(
                    key: entry.key,
                    range: start..<end,
                    count: entry.count
                )
            )
            runningTotal = end
        }
        return result
    }
}

// Utility extension for grouping monthly city data
extension Array where Element == MonthlyCityData {
    var groupedByMonth: [(monthKey: String, count: Int)] {
        let grouped = Dictionary(grouping: self, by: { $0.monthKey })
        return grouped.map { key, values in
            (monthKey: key, count: values.reduce(0) { $0 + $1.count })
        }.sorted {
            (Calendar.current.shortMonthSymbols.firstIndex(of: $0.monthKey) ?? 0) <
            (Calendar.current.shortMonthSymbols.firstIndex(of: $1.monthKey) ?? 0)
        }
    }
}

extension MonthlyCityData {
    static func groupByCity(_ data: [MonthlyCityData]) -> [(city: String, count: Int)] {
        let grouped = Dictionary(grouping: data, by: { $0.city })
        return grouped.map { ($0.key, $0.value.reduce(0) { $0 + $1.count }) }
    }
}

// GradientForeground
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

