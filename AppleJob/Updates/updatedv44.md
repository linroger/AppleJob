import SwiftUI
import Charts
import MapKit
import CoreLocation

// ------------------------------------
// MARK: - EnhancedStatsView
// ------------------------------------
/**
 The Stats & Analytics View:
   • Dynamically determined year picker (from earliest to latest), plus an "All" option
   • Tooltips (via annotations) for each chart
   • No placeholders
*/
struct EnhancedStatsView: View {
    @EnvironmentObject var jobStore: JobStore

    // A region for the map
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 50)
    )

    // Pins for the map (city-based)
    @State private var cityPins: [CityPin] = []

    // Two “GitHub-style” contribution data sets
    @State private var yearContributionData: [Contribution] = []
    @State private var appsContributionData: [Contribution] = []

    // Time range enum for barLineData
    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case sixmonth = "Six Months"
        case year = "Year"
        var id: String { rawValue }
    }

    @AppStorage("StatsViewTimeRange") private var selectedTimeRangeRaw: String = TimeRange.month.rawValue
    @State private var selectedTimeRange: TimeRange = .month

    // Instead of hard-coding 2021...2025, we do a dynamic approach:
    @State private var selectedYearForCharts: Int = -1 // -1 means "All"

    // The data for the bar/line charts
    @State private var barLineData: [DailyApps] = []

    // For stacked bar charts, etc.
    @State private var monthlyCityData: [MonthlyCityData] = []

    // Convenience computed property to find all years present in the data
    private var availableYears: [Int] {
        let allYears = jobStore.jobApplications.map {
            Calendar.current.component(.year, from: $0.dateOfApplication)
        }
        let uniqueYears = Set(allYears)
        let sorted = uniqueYears.sorted()
        return sorted
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                mapSection
                statsRowSection

                // -----------------------------------------
                // MARK: Year Picker (Dynamic + "All")
                // -----------------------------------------
                yearPickerSection

                // -----------------------------------------
                // MARK: GitHub-Style Contribution Charts
                // -----------------------------------------
                githubChartsSection

                timeRangePickerSection

                // -----------------------------------------
                // MARK: Bar/Line Charts
                // -----------------------------------------
                barLineChartsSection

                // -----------------------------------------
                // MARK: Horizontally Stacked Bar Chart
                // -----------------------------------------
                horizontallyStackedBarChartSection

                // -----------------------------------------
                // MARK: Single-Column Vertically Stacked
                // -----------------------------------------
                singleColumnVerticallyStackedBarChartSection

                // -----------------------------------------
                // MARK: Top 20 Companies
                // -----------------------------------------
                top20CompaniesBarSection

                citiesByFrequencySection
                companiesByFrequencySection

                // -----------------------------------------
                // MARK: Pie Charts
                // -----------------------------------------
                pieChartsSection
            }
            .padding()
        }
        .onAppear {
            // Initialize states
            // If we have no years, default selectedYearForCharts to -1 (All)
            if availableYears.isEmpty {
                selectedYearForCharts = -1
            } else {
                // If we already have something in selectedYearForCharts that doesn't exist, fallback to -1
                if !availableYears.contains(selectedYearForCharts), selectedYearForCharts != -1 {
                    selectedYearForCharts = -1
                }
            }
            if let time = TimeRange(rawValue: selectedTimeRangeRaw) {
                selectedTimeRange = time
            } else {
                selectedTimeRange = .month
            }

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
        .onChange(of: selectedYearForCharts) { _, _ in
            computeYearContribution()
            computeAppsContribution()
            computeMonthlyCityData()
        }
        .navigationTitle("Stats & Analytics")
    }

    // -----------------------------------------
    // MARK: - Map Section
    // -----------------------------------------
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Applications Map")
                .font(.headline)

            Map {
                ForEach(cityPins) { cityPin in
                    // A simple circle for each city, sized by the count
                    Annotation(cityPin.city, coordinate: cityPin.coordinate) {
                        Circle()
                            .fill(Color.red.opacity(0.5))
                            .frame(width: max(10, 2 * CGFloat(cityPin.count)),
                                   height: max(10, 2 * CGFloat(cityPin.count)))
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

    // -----------------------------------------
    // MARK: - Stats Row
    // -----------------------------------------
    private var statsRowSection: some View {
        let totalApps = jobStore.jobApplications.count
        let appliedCount = jobStore.jobApplications.filter { $0.status == .applied }.count
        let interestedCount = jobStore.jobApplications.filter { $0.status == .interested }.count
        let interviewCount = jobStore.jobApplications.filter { $0.status == .interview }.count
        let distinctCities = Set(jobStore.jobApplications.map { $0.location }).count
        let topCompany = topCompanyName()
        let topCityData = topCity()

        let gradient = LinearGradient(colors: [.blue, .pink], startPoint: .leading, endPoint: .trailing)

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 32) {
                VStack {
                    Text("Total Apps")
                    Text("\(totalApps)")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(gradient)
                }
                VStack {
                    Text("Applied")
                    Text("\(appliedCount)")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(gradient)
                }
                VStack {
                    Text("Interested")
                    Text("\(interestedCount)")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(gradient)
                }
                VStack {
                    Text("Interviews")
                    Text("\(interviewCount)")
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
                    Text("\(topCityData.name)")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(gradient)
                    Text("\(topCityData.count)")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(gradient)
                }
                .font(.callout)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // -----------------------------------------
    // MARK: - Year Picker (Dynamic + All)
    // -----------------------------------------
    private var yearPickerSection: some View {
        HStack {
            Text("Select Year:")
            Picker("Year", selection: $selectedYearForCharts) {
                Text("All").tag(-1)  // This represents "All"
                ForEach(availableYears, id: \.self) { yr in
                    Text("\(yr)").tag(yr)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // -----------------------------------------
    // MARK: - GitHub-Style Contribution Charts
    // -----------------------------------------
    private var githubChartsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("GitHub-Style Contribution Charts")
                .font(.headline)
            // Requires macOS 13.0+ for Swift Charts
            if #available(macOS 13.0, *) {
                // 1) First chart (yearContributionData)
                Chart(yearContributionData) { item in
                    RectangleMark(
                        x: .value("WeekOfYear", item.date, unit: .weekOfYear),
                        y: .value("DayOfWeek", weekday(for: item.date))
                    )
                    .foregroundStyle(by: .value("Count", item.count))
                    .clipShape(RoundedRectangle(cornerRadius: 1))
                    // Tooltip: The user wants the **date** for the first chart
                    .annotation(position: .top) {
                        Text("\(item.date, format: .dateTime.year().month().day())")
                            .font(.caption2)
                            .foregroundColor(.primary)
                    }
                }
                .chartForegroundStyleScale(range: Gradient(colors: chartColors))
                .chartYAxis {
                    AxisMarks(values: [1, 3, 5, 7]) { value in
                        if let val = value.as(Int.self), let label = shortWeekdaySymbol(val) {
                            AxisValueLabel(label)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) {
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .frame(height: 180)

                // 2) Second chart (appsContributionData)
                Chart(appsContributionData) { item in
                    RectangleMark(
                        x: .value("WeekOfYear", item.date, unit: .weekOfYear),
                        y: .value("DayOfWeek", weekday(for: item.date))
                    )
                    .foregroundStyle(by: .value("Count", item.count))
                    .clipShape(RoundedRectangle(cornerRadius: 1))
                    // Tooltip: Show the **number of applications** for second chart
                    .annotation(position: .top) {
                        Text("\(item.count) apps")
                            .font(.caption2)
                            .foregroundColor(.primary)
                    }
                }
                .chartForegroundStyleScale(range: Gradient(colors: chartColors))
                .chartYAxis {
                    AxisMarks(values: [1, 3, 5, 7]) { value in
                        if let val = value.as(Int.self), let label = shortWeekdaySymbol(val) {
                            AxisValueLabel(label)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) {
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .frame(height: 180)

            } else {
                Text("Contribution charts require macOS 13.0+.")
            }
        }
        .frame(maxWidth: .infinity)
    }

    // -----------------------------------------
    // MARK: - Time Range Picker
    // -----------------------------------------
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

    // -----------------------------------------
    // MARK: - Bar/Line Charts
    // -----------------------------------------
    private var barLineChartsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Applications Frequency (Selected Time Range)")
                .font(.headline)
            if #available(macOS 13.0, *) {
                Chart(barLineData) { dayItem in
                    BarMark(
                        x: .value("Date", dayItem.date),
                        y: .value("Applications", dayItem.count)
                    )
                    // Third chart => show both date and # of apps
                    .annotation(position: .top) {
                        VStack(spacing: 2) {
                            Text("\(dayItem.date, format: .dateTime.year().month().day())")
                                .font(.caption2)
                            Text("\(dayItem.count) apps")
                                .font(.caption2)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .frame(height: 300)
            } else {
                Text("Charts require macOS 13.0+.")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // -----------------------------------------
    // MARK: - Horizontally Stacked Bar Chart
    // -----------------------------------------
    @ViewBuilder
    private var horizontallyStackedBarChartSection: some View {
        if #available(macOS 13.0, *) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Applications by City - Horizontally Stacked Bar")
                    .font(.headline)
                Chart(monthlyCityDataFilteredForSelectedYear()) { item in
                    BarMark(
                        x: .value("Month", item.monthKey),
                        y: .value("Count", item.count)
                    )
                    .position(by: .value("City", item.city))
                    .foregroundStyle(by: .value("City", item.city))
                    // Fourth chart => show the city
                    .annotation(position: .top) {
                        Text(item.city)
                            .font(.caption2)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) {
                        AxisValueLabel()
                    }
                }
                .chartYAxis {
                    AxisMarks()
                }
                .frame(height: 300)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Text("Stacked bar chart requires macOS 13.0+.")
        }
    }

    // -----------------------------------------
    // MARK: - Single-Column Vertically Stacked
    // -----------------------------------------
    @ViewBuilder
    private var singleColumnVerticallyStackedBarChartSection: some View {
        if #available(macOS 13.0, *) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Applications by City - Single Column Vertically Stacked")
                    .font(.headline)
                Chart(monthlyCityDataFilteredForSelectedYear()) { item in
                    BarMark(
                        x: .value("Month", item.monthKey),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(by: .value("City", item.city))
                    // Fifth chart => show the city for that portion
                    .annotation(position: .top) {
                        Text(item.city)
                            .font(.caption2)
                    }
                }
                .chartXAxis {
                    AxisMarks()
                }
                .chartYAxis {
                    AxisMarks()
                }
                .frame(height: 300)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Text("Stacked bar chart requires macOS 13.0+.")
        }
    }

    // -----------------------------------------
    // MARK: - Top 20 Companies (Sixth Chart)
    // -----------------------------------------
    private var top20CompaniesBarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top 20 Companies by Frequency (All Years)")
                .font(.headline)
            if #available(macOS 13.0, *) {
                let topCompanies = buildTop20CompanyFreq()
                Chart(topCompanies) { item in
                    BarMark(
                        x: .value("Company", item.name),
                        y: .value("Count", item.count)
                    )
                    // Sixth chart => show the company and the # of applications
                    .annotation(position: .top) {
                        Text("\(item.name): \(item.count)")
                            .font(.caption2)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic)
                }
                .chartYAxis {
                    AxisMarks()
                }
                .frame(height: 180)
            } else {
                Text("Bar chart requires macOS 13.0+.")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // -----------------------------------------
    // MARK: - Cities By Frequency
    // -----------------------------------------
    private var citiesByFrequencySection: some View {
        let cityCounts = cityFreqList()
        return VStack(alignment: .leading, spacing: 12) {
            Text("Cities By Frequency")
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
                        .padding(6)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }

    // -----------------------------------------
    // MARK: - Companies By Frequency
    // -----------------------------------------
    private var companiesByFrequencySection: some View {
        let companies = companyFreqList()
        return VStack(alignment: .leading, spacing: 12) {
            Text("Companies By Frequency")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 24) {
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
                        .padding(6)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // -----------------------------------------
    // MARK: - Pie Charts
    // -----------------------------------------
    @ViewBuilder
    private var pieChartsSection: some View {
        if #available(macOS 13.0, *) {
            VStack(alignment: .center, spacing: 16) {
                Text("Application Shares (Pie Charts)")
                    .font(.headline)

                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(alignment: .center, spacing: 32) {

                        // 1) Pie Chart by Month (the "first" pie chart)
                        VStack {
                            Text("Share by Month (\(selectedYearText()))")
                                .font(.subheadline)

                            let monthData = monthlyShareData()
                            Chart(monthData) { item in
                                SectorMark(
                                    angle: .value("Count", item.count),
                                    innerRadius: .ratio(0.5)
                                )
                                .foregroundStyle(by: .value("Month", item.monthKey))
                                // Show month & year & # of apps
                                .annotation(position: .overlay) {
                                    if item.count > 0 {
                                        Text("\(item.monthKey) \(selectedYearText())\n\(item.count)")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .chartLegend(position: .bottom)
                            .frame(width: 400, height: 400)
                        }

                        // 2) Pie Chart by City (the "second" pie chart)
                        VStack {
                            Text("Share by City (\(selectedYearText()))")
                                .font(.subheadline)

                            let cityData = cityShareData()
                            Chart(cityData) { item in
                                SectorMark(
                                    angle: .value("Count", item.count),
                                    innerRadius: .ratio(0.5)
                                )
                                .foregroundStyle(by: .value("City", item.city))
                                // Show city & # of apps
                                .annotation(position: .overlay) {
                                    if item.count > 0 {
                                        Text("\(item.city)\n\(item.count)")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .chartLegend(position: .bottom)
                            .frame(width: 400, height: 400)
                        }

                        // 3) Pie Chart by Year (not explicitly requested, but kept for completeness)
                        VStack {
                            Text("Share by Year")
                                .font(.subheadline)

                            let yearData = yearlyShareData()
                            Chart(yearData) { item in
                                SectorMark(
                                    angle: .value("Count", item.count),
                                    innerRadius: .ratio(0.5)
                                )
                                .foregroundStyle(by: .value("Year", item.year))
                                .annotation(position: .overlay) {
                                    if item.count > 0 {
                                        Text("\(item.year)\n\(item.count)")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .chartLegend(position: .bottom)
                            .frame(width: 400, height: 400)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            Text("Pie charts require macOS 13.0+.")
        }
    }

    // -----------------------------------------
    // MARK: - Data Computation
    // -----------------------------------------
    private func computeCityPins() {
        var cityCount: [String: Int] = [:]
        for job in jobStore.jobApplications {
            cityCount[job.location, default: 0] += 1
        }
        cityPins = cityCount.map { (city, ct) in
            let coord = CityCoordinateDictionary[city] ?? CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795)
            return CityPin(city: city, coordinate: coord, count: ct)
        }
    }

    private func computeYearContribution() {
        let cal = Calendar.current

        // If user selected "All," we gather from earliest date to latest date in the store
        let allDates = jobStore.jobApplications.map { cal.startOfDay(for: $0.dateOfApplication) }
        guard !allDates.isEmpty else {
            yearContributionData = []
            return
        }

        let overallMinDate = allDates.min()!
        let overallMaxDate = allDates.max()!

        // If selectedYearForCharts == -1 => show the entire range
        // Otherwise build a range from Jan 1 to Dec 31 of that year
        var startOfRange: Date
        var endOfRange: Date

        if selectedYearForCharts == -1 {
            startOfRange = overallMinDate
            endOfRange = overallMaxDate
        } else {
            guard let yearStart = cal.date(from: DateComponents(year: selectedYearForCharts, month: 1, day: 1)),
                  let yearEnd = cal.date(from: DateComponents(year: selectedYearForCharts, month: 12, day: 31))
            else {
                yearContributionData = []
                return
            }
            startOfRange = yearStart
            endOfRange = min(yearEnd, overallMaxDate)
        }

        var dayCursor = cal.startOfDay(for: startOfRange)
        var allDays: [Contribution] = []
        while dayCursor <= endOfRange {
            // For demonstration, we set count=1 if dayCursor is in range (like a placeholder).
            // The user might want 0 or 1. 
            // We'll do 1 if dayCursor <= now, else 0:
            if dayCursor <= Date() {
                allDays.append(Contribution(date: dayCursor, count: 1))
            } else {
                allDays.append(Contribution(date: dayCursor, count: 0))
            }
            guard let nextDay = cal.date(byAdding: .day, value: 1, to: dayCursor) else { break }
            dayCursor = nextDay
        }
        yearContributionData = allDays
    }

    private func computeAppsContribution() {
        let cal = Calendar.current

        let allDates = jobStore.jobApplications.map { cal.startOfDay(for: $0.dateOfApplication) }
        guard !allDates.isEmpty else {
            appsContributionData = []
            return
        }

        let overallMinDate = allDates.min()!
        let overallMaxDate = allDates.max()!

        var startOfRange: Date
        var endOfRange: Date

        if selectedYearForCharts == -1 {
            startOfRange = overallMinDate
            endOfRange = overallMaxDate
        } else {
            guard let yearStart = cal.date(from: DateComponents(year: selectedYearForCharts, month: 1, day: 1)),
                  let yearEnd = cal.date(from: DateComponents(year: selectedYearForCharts, month: 12, day: 31))
            else {
                appsContributionData = []
                return
            }
            startOfRange = yearStart
            endOfRange = min(yearEnd, overallMaxDate)
        }

        // Count the number of apps per day in that range
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
            results.append(Contribution(date: dayCursor, count: dateCount[dayCursor, default: 0]))
            guard let nextDay = cal.date(byAdding: .day, value: 1, to: dayCursor) else { break }
            dayCursor = nextDay
        }
        appsContributionData = results
    }

    private func computeBarLineData() {
        let now = Date()
        let cal = Calendar.current

        var earliestDate: Date?
        switch selectedTimeRange {
        case .week:
            earliestDate = cal.date(byAdding: .day, value: -7, to: now)
        case .month:
            earliestDate = cal.date(byAdding: .month, value: -1, to: now)
        case .sixmonth:
            earliestDate = cal.date(byAdding: .month, value: -6, to: now)
        case .year:
            earliestDate = cal.date(byAdding: .year, value: -1, to: now)
        }

        guard let start = earliestDate else {
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
        let cal = Calendar.current
        let allApps = jobStore.jobApplications

        // 1) If user picked "All," gather from earliest to latest
        //    else gather from 1 Jan to 31 Dec for that year
        let dates = allApps.map { cal.startOfDay(for: $0.dateOfApplication) }
        guard !dates.isEmpty else {
            monthlyCityData = []
            return
        }
        let overallMinDate = dates.min()!
        let overallMaxDate = dates.max()!

        var startOfYear: Date
        var endOfYear: Date
        if selectedYearForCharts == -1 {
            startOfYear = overallMinDate
            endOfYear = overallMaxDate
        } else {
            guard let s = cal.date(from: DateComponents(year: selectedYearForCharts, month: 1, day: 1)),
                  let e = cal.date(from: DateComponents(year: selectedYearForCharts, month: 12, day: 31))
            else {
                monthlyCityData = []
                return
            }
            startOfYear = s
            endOfYear = min(e, overallMaxDate)
        }

        // Build month boundaries from startOfYear to endOfYear
        var months: [Date] = []
        var cursor = startOfYear
        while cursor <= endOfYear {
            months.append(cursor)
            guard let nxt = cal.date(byAdding: .month, value: 1, to: cursor) else { break }
            if nxt > endOfYear { break }
            cursor = nxt
        }

        let appsInRange = allApps.filter {
            $0.dateOfApplication >= startOfYear && $0.dateOfApplication <= endOfYear
        }

        var temp: [MonthlyCityData] = []
        for i in 0..<months.count {
            let monthStart = months[i]
            let comps = cal.dateComponents([.year, .month], from: monthStart)
            let mKey = "\(monthName(comps.month)) \(comps.year!)"

            // The next boundary is either months[i+1] or endOfYear + 1 day
            let nextMonth: Date
            if i+1 < months.count {
                nextMonth = months[i+1]
            } else {
                // last boundary is endOfYear + 1 day
                guard let eom = cal.date(byAdding: .day, value: 1, to: endOfYear) else { continue }
                nextMonth = eom
            }

            let appsInMonth = appsInRange.filter {
                let day = cal.startOfDay(for: $0.dateOfApplication)
                return day >= monthStart && day < nextMonth
            }
            let cityCount = Dictionary(grouping: appsInMonth, by: { $0.location }).mapValues { $0.count }

            for (city, ct) in cityCount {
                temp.append(MonthlyCityData(
                    monthKey: mKey,
                    city: city,
                    count: ct,
                    date: monthStart
                ))
            }
        }

        temp.sort { $0.date < $1.date }
        monthlyCityData = temp
    }

    // We do not further filter by month because we already used a narrower range
    private func monthlyCityDataFilteredForSelectedYear() -> [MonthlyCityData] {
        monthlyCityData
    }

    // For the "first" pie chart, each month has a sum
    private func monthlyShareData() -> [MonthlyCityData] {
        let groups = Dictionary(grouping: monthlyCityDataFilteredForSelectedYear()) { $0.monthKey }
        let results = groups.map { (monthKey, records) -> MonthlyCityData in
            let sum = records.reduce(0) { $0 + $1.count }
            return MonthlyCityData(monthKey: monthKey, city: "", count: sum, date: Date())
        }
        return results.sorted { $0.monthKey < $1.monthKey }
    }

    // For the "second" pie chart, city-based
    private func cityShareData() -> [MonthlyCityData] {
        let groups = Dictionary(grouping: monthlyCityDataFilteredForSelectedYear()) { $0.city }
        let results = groups.map { (city, records) -> MonthlyCityData in
            let sum = records.reduce(0) { $0 + $1.count }
            return MonthlyCityData(monthKey: "", city: city, count: sum, date: Date())
        }
        return results.sorted { $0.count > $1.count }
    }

    // For the "Share by Year" pie chart
    private func yearlyShareData() -> [YearlyData] {
        let applications = jobStore.jobApplications
        let groupedByYear = Dictionary(grouping: applications) {
            Calendar.current.component(.year, from: $0.dateOfApplication)
        }
        return groupedByYear.map { (year, apps) in
            YearlyData(year: String(year), count: apps.count)
        }
        .sorted { $0.year < $1.year }
    }

    // For the “Top 20 Companies” chart
    private func buildTop20CompanyFreq() -> [CompanyFreq] {
        var freq: [String: Int] = [:]
        for app in jobStore.jobApplications {
            freq[app.companyName, default: 0] += 1
        }
        let sorted = freq.sorted { $0.value > $1.value }
        return sorted.prefix(20).map { CompanyFreq(name: $0.key, count: $0.value) }
    }

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

    // Color ramp for the GitHub-style chart
    @available(macOS 13.0, *)
    private var chartColors: [Color] {
        [
            Color.green.opacity(0.2),
            Color.green.opacity(0.35),
            Color.green.opacity(0.5),
            Color.green.opacity(0.65),
            Color.green.opacity(0.8),
            Color.green
        ]
    }

    private func weekday(for date: Date) -> Int {
        Calendar.current.component(.weekday, from: date)
    }

    private func shortWeekdaySymbol(_ weekday: Int) -> String? {
        let symbols = Calendar.current.shortWeekdaySymbols
        guard weekday - 1 >= 0, weekday - 1 < symbols.count else { return nil }
        return symbols[weekday - 1]
    }

    private func topCompanyName() -> String {
        let all = jobStore.jobApplications.map { $0.companyName }
        let freq = Dictionary(grouping: all, by: { $0 }).mapValues { $0.count }
        let sorted = freq.sorted { $0.value > $1.value }
        return sorted.first?.key ?? "N/A"
    }

    private func topCity() -> (name: String, count: Int) {
        let all = jobStore.jobApplications.map { $0.location }
        let freq = Dictionary(grouping: all, by: { $0 }).mapValues { $0.count }
        let sorted = freq.sorted { $0.value > $1.value }
        if let first = sorted.first {
            return (first.key, first.value)
        }
        return ("N/A", 0)
    }

    private func monthName(_ m: Int?) -> String {
        guard let m = m else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        // We ignore day=1 or year if needed
        if m >= 1 && m <= 12 {
            return formatter.string(from: Calendar.current.date(from: DateComponents(year: 2023, month: m, day: 1))!)
        }
        return ""
    }

    private func selectedYearText() -> String {
        if selectedYearForCharts == -1 {
            return "All"
        } else {
            return "\(selectedYearForCharts)"
        }
    }
}

// ------------------------------------
// MARK: - Supporting Models
// ------------------------------------
/**
 Simple struct for the “GitHub-Style” daily chart.
*/
struct Contribution: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
}

/**
 For the bar/line data
*/
struct DailyApps: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

/**
 For stacked city-month data
*/
struct MonthlyCityData: Identifiable {
    let id = UUID()
    let monthKey: String  // e.g. "Jan 2024"
    let city: String
    let count: Int
    let date: Date
}

/**
 For a "Share by Year" pie chart
*/
struct YearlyData: Identifiable {
    let id = UUID()
    let year: String
    let count: Int
}

/**
 For "Top 20 Companies" bar chart
*/
struct CompanyFreq: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
}

/**
 For city map pins
*/
struct CityPin: Identifiable {
    let id = UUID()
    let city: String
    let coordinate: CLLocationCoordinate2D
    let count: Int
}