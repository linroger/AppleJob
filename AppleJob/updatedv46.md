import SwiftUI
import Charts
import MapKit

struct EnhancedStatsView: View {
    @EnvironmentObject var jobStore: JobStore

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 50)
    )
    @State private var cityPins: [CityPin] = []

    @State private var yearContributionData: [Contribution] = []
    @State private var appsContributionData: [Contribution] = []

    @State private var yearChartSelectedDate: Date? = nil
    @State private var appsChartSelectedDate: Date? = nil

    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case sixmonth = "Six Months"
        case year = "Year"
        var id: String { rawValue }
    }

    @AppStorage("StatsViewTimeRange")
    private var selectedTimeRangeRaw: String = TimeRange.month.rawValue

    @State var selectedTimeRange: TimeRange = .month

    @State private var availableYears: [Int] = []

    @State private var barLineData: [DailyApps] = []
    @State private var barLineSelectedDate: Date? = nil

    @State private var monthlyCityData: [MonthlyCityData] = []

    @State private var horizontalPlotSelection: String? = nil
    @State private var singleColumnPlotSelection: String? = nil

    @State private var top20CompanySelection: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                mapSection
                statsRowSection
                dynamicYearPickerSection
                githubChartsSection
                timeRangePickerSection
                barLineChartsSection
                horizontallyStackedBarChartSection
                singleColumnVerticallyStackedBarChartSection
                top20CompaniesBarSection
                citiesByFrequencySection
                companiesByFrequencySection
                pieChartsSection
            }
            .padding()
        }
        .onAppear {

            if let range = TimeRange(rawValue: selectedTimeRangeRaw) {
                selectedTimeRange = range
            }
            setupAvailableYears()
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
        .onChange(of: selectedYear) { _, _ in
            computeYearContribution()
            computeAppsContribution()
            computeMonthlyCityData()
        }
        .navigationTitle("Stats & Analytics")
    }

    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Applications Map")
                .font(.headline)
            Map {
                ForEach(cityPins) { cityPin in
                    Annotation("City: \(cityPin.city)", coordinate: cityPin.coordinate) {
                        Circle()
                            .fill(Color.red.opacity(0.5))
                            .frame(
                                width: max(10, 2 * CGFloat(cityPin.count)),
                                height: max(10, 2 * CGFloat(cityPin.count))
                            )
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

    private var statsRowSection: some View {
        let total = jobStore.jobApplications.count
        let applied = jobStore.jobApplications.filter { $0.status == .applied }.count
        let interested = jobStore.jobApplications.filter { $0.status == .interested }.count
        let interviewed = jobStore.jobApplications.filter { $0.status == .interview }.count
        let distinctCities = Set(jobStore.jobApplications.map { $0.location }).count
        let topCompanyNameString = topCompanyName()
        let (cityName, cityCount) = topCity()

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
                    Text(topCompanyNameString)
                        .font(.title3)
                        .bold()
                        .foregroundStyle(gradient)
                }
                VStack {
                    Text("Top City")
                    Text(cityName)
                        .font(.title3)
                        .bold()
                        .foregroundStyle(gradient)
                    Text("\(cityCount)")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(gradient)
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
    }

    private var dynamicYearPickerSection: some View {

        let sortedYears = availableYears.sorted()
        let yearsWithAll = sortedYears + [-1]

        return HStack {
            Text("Select Year:")
            Picker("Year", selection: $selectedYear) {

                ForEach(yearsWithAll, id: \.self) { yr in
                    if yr == -1 {
                        Text("All Years").tag(-1)
                    } else {
                        Text("\(yr)").tag(yr)
                    }
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var githubChartsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("GitHub-Style Contribution Charts")
                .font(.headline)

            if #available(macOS 13.0, *) {

                Chart(yearContributionData) { item in
                    RectangleMark(
                        x: .value("WeekOfYear", item.date, unit: .weekOfYear),
                        y: .value("DayOfWeek", weekday(for: item.date))
                    )
                    .foregroundStyle(by: .value("Count", item.count))
                    .clipShape(RoundedRectangle(cornerRadius: 1))
                }
                .chartXSelection(value: $yearChartSelectedDate)
                .chartForegroundStyleScale(range: Gradient(colors: chartColors))
                .chartYAxis {
                    AxisMarks(values: [1, 3, 5, 7]) { val in
                        if let i = val.as(Int.self), let label = shortWeekdaySymbol(i) {
                            AxisValueLabel(label)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) {
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .ifShouldScrollHorizontally(selectedYear: selectedYear)
                .frame(height: 180)
                .overlay {
                    if let sel = yearChartSelectedDate {
                        GeometryReader { geo in
                            let dayStr = sel.formatted(date: .abbreviated, time: .omitted)
                            Text("Selected: \(dayStr)")
                                .font(.caption2)
                                .padding(4)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(4)
                                .position(x: geo.size.width * 0.5, y: 12)
                        }
                    }
                }

                Chart(appsContributionData) { item in
                    RectangleMark(
                        x: .value("WeekOfYear", item.date, unit: .weekOfYear),
                        y: .value("DayOfWeek", weekday(for: item.date))
                    )
                    .foregroundStyle(by: .value("Count", item.count))
                    .clipShape(RoundedRectangle(cornerRadius: 1))
                }
                .chartXSelection(value: $appsChartSelectedDate)
                .chartForegroundStyleScale(range: Gradient(colors: chartColors))
                .chartYAxis {
                    AxisMarks(values: [1, 3, 5, 7]) { val in
                        if let i = val.as(Int.self), let label = shortWeekdaySymbol(i) {
                            AxisValueLabel(label)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) {
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .ifShouldScrollHorizontally(selectedYear: selectedYear)
                .frame(height: 180)
                .overlay {
                    if let sel = appsChartSelectedDate {
                        GeometryReader { geo in
                            let dayStr = sel.formatted(date: .abbreviated, time: .omitted)
                            let c = appsContributionData.first(where: { $0.date == sel })?.count ?? 0
                            Text("\(c) apps on \(dayStr)")
                                .font(.caption2)
                                .padding(4)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(4)
                                .position(x: geo.size.width * 0.5, y: 12)
                        }
                    }
                }
            } else {
                Text("Contribution charts require macOS 13.0+.")
            }
        }
        .frame(maxWidth: .infinity)
    }

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

    private var barLineChartsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Applications Frequency (Last 12 Months / Range)")
                .font(.headline)

            if #available(macOS 13.0, *) {
                Chart(barLineData) { dayItem in
                    BarMark(
                        x: .value("Date", dayItem.date),
                        y: .value("Applications", dayItem.count)
                    )
                }
                .chartXSelection(value: $barLineSelectedDate)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .frame(height: 300)
                .overlay {
                    if let sel = barLineSelectedDate {
                        GeometryReader { geo in
                            let dayStr = sel.formatted(date: .abbreviated, time: .omitted)
                            let c = barLineData.first(where: { $0.date == sel })?.count ?? 0
                            Text("\(c) apps on \(dayStr)")
                                .font(.caption2)
                                .padding(4)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(3)
                                .position(x: geo.size.width * 0.5, y: 12)
                        }
                    }
                }
            } else {
                Text("Charts require macOS 13.0+.")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var horizontallyStackedBarChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Applications by City - Horizontally Stacked Bar Chart")
                .font(.headline)

            if #available(macOS 13.0, *) {
                Chart(monthlyCityDataFilteredForSelectedYear()) { item in
                    BarMark(
                        x: .value("Month", item.monthKey),
                        y: .value("Count", item.count)
                    )
                    .position(by: .value("City", item.city))
                    .foregroundStyle(by: .value("City", item.city))
                }

                .ifShouldPlotSelect(stringBinding: $horizontalPlotSelection)
                .ifShouldScrollHorizontally(selectedYear: selectedYear)
                .chartXAxis {
                    AxisMarks(values: .automatic)
                }
                .chartYAxis {
                    AxisMarks()
                }
                .frame(height: 300)
                .overlay {
                    if let sel = horizontalPlotSelection {
                        GeometryReader { geo in
                            Text("Selected: \(sel)")
                                .font(.caption2)
                                .padding(4)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(3)
                                .position(x: geo.size.width * 0.5, y: 12)
                        }
                    }
                }
            } else {
                Text("Stacked bar chart requires macOS 13.0+.")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var singleColumnVerticallyStackedBarChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Applications by City - Single Column Vertically Stacked Bar Chart")
                .font(.headline)

            if #available(macOS 13.0, *) {
                Chart(monthlyCityDataFilteredForSelectedYear()) { item in
                    BarMark(
                        x: .value("Month", item.monthKey),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(by: .value("City", item.city))
                }
                .ifShouldPlotSelect(stringBinding: $singleColumnPlotSelection)
                .ifShouldScrollHorizontally(selectedYear: selectedYear)
                .chartXAxis {
                    AxisMarks()
                }
                .chartYAxis {
                    AxisMarks()
                }
                .frame(height: 300)
                .overlay {
                    if let sel = singleColumnPlotSelection {
                        GeometryReader { geo in
                            Text("Selected: \(sel)")
                                .font(.caption2)
                                .padding(4)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(3)
                                .position(x: geo.size.width * 0.5, y: 12)
                        }
                    }
                }
            } else {
                Text("Stacked bar chart requires macOS 13.0+.")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var top20CompaniesBarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top 20 Companies by Application Frequency (All Years)")
                .font(.headline)

            if #available(macOS 13.0, *) {
                let freq = buildTop20CompanyFreq()
                Chart(freq) { item in
                    BarMark(
                        x: .value("Company", item.name),
                        y: .value("Count", item.count)
                    )
                }
                .ifShouldPlotSelect(stringBinding: $top20CompanySelection)
                .chartXAxis {
                    AxisMarks(values: .automatic)
                }
                .chartYAxis {
                    AxisMarks()
                }
                .frame(height: 180)
                .overlay {
                    if let sel = top20CompanySelection {
                        GeometryReader { geo in
                            Text("Selected: \(sel)")
                                .font(.caption2)
                                .padding(4)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(3)
                                .position(x: geo.size.width * 0.5, y: 12)
                        }
                    }
                }
            } else {
                Text("Bar chart requires macOS 13.0+.")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var citiesByFrequencySection: some View {
        VStack(alignment: .leading) {
            Text("Cities by Frequency (All Years)")
                .font(.headline)

            let freq = buildCityFrequency()
            ForEach(freq, id: \.id) { c in
                HStack {
                    Text(c.name)
                    Spacer()
                    Text("\(c.count)")
                }
            }
        }
    }

    private var companiesByFrequencySection: some View {
        VStack(alignment: .leading) {
            Text("Companies by Frequency (All Years)")
                .font(.headline)

            let freq = buildCompanyFrequency()
            ForEach(freq, id: \.id) { c in
                HStack {
                    Text(c.name)
                    Spacer()
                    Text("\(c.count)")
                }
            }
        }
    }

    private var pieChartsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Example Pie Charts (Not Actually Interactive)")
                .font(.headline)
            Text("Pie charts remain unaffected as per instructions.")
                .foregroundColor(.secondary)
        }
    }

    private func setupAvailableYears() {

        let calendar = Calendar.current
        let years = jobStore.jobApplications.map { app in
            calendar.component(.year, from: app.dateOfApplication)
        }
        availableYears = Array(Set(years)).sorted()

        if availableYears.isEmpty {

            selectedYear = -1
        } else {

        }
    }

    private func computeCityPins() {

        var counts: [String: Int] = [:]
        for job in jobStore.jobApplications {
            counts[job.location, default: 0] += 1
        }
        cityPins = counts.map { (city, count) in
            let coord = CityCoordinateDictionary[city] ?? region.center
            return CityPin(city: city, coordinate: coord, count: count)
        }
    }

    private func computeYearContribution() {

        let allDates = jobStore.jobApplications.map { $0.dateOfApplication }
        let filteredDates: [Date]
        if selectedYear == -1 {
            filteredDates = allDates
        } else {
            filteredDates = allDates.filter { Calendar.current.component(.year, from: $0) == selectedYear }
        }

        let groupedByDay = Dictionary(grouping: filteredDates) { date -> Date in
            Calendar.current.startOfDay(for: date)
        }
        let mapped = groupedByDay.map { (day, list) in
            Contribution(date: day, count: list.count)
        }
        yearContributionData = mapped.sorted { $0.date < $1.date }
    }

    private func computeAppsContribution() {

        let allDates = jobStore.jobApplications.filter { $0.status == .applied }.map { $0.dateOfApplication }
        let filteredDates: [Date]
        if selectedYear == -1 {
            filteredDates = allDates
        } else {
            filteredDates = allDates.filter { Calendar.current.component(.year, from: $0) == selectedYear }
        }
        let groupedByDay = Dictionary(grouping: filteredDates) { date -> Date in
            Calendar.current.startOfDay(for: date)
        }
        let mapped = groupedByDay.map { (day, list) in
            Contribution(date: day, count: list.count)
        }
        appsContributionData = mapped.sorted { $0.date < $1.date }
    }

    private func computeBarLineData() {

        let now = Date()
        let cal = Calendar.current
        let startDate: Date
        switch selectedTimeRange {
        case .week:
            startDate = cal.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = cal.date(byAdding: .month, value: -1, to: now) ?? now
        case .sixmonth:
            startDate = cal.date(byAdding: .month, value: -6, to: now) ?? now
        case .year:
            startDate = cal.date(byAdding: .year, value: -1, to: now) ?? now
        }

        let filtered = jobStore.jobApplications.filter { $0.dateOfApplication >= startDate }
        let groupedByDay = Dictionary(grouping: filtered) { dateItem -> Date in
            cal.startOfDay(for: dateItem.dateOfApplication)
        }
        let daily = groupedByDay.map { (day, list) in
            DailyApps(date: day, count: list.count)
        }
        barLineData = daily.sorted { $0.date < $1.date }
    }

    private func computeMonthlyCityData() {

        let cal = Calendar.current
        let filtered: [JobApplication]
        if selectedYear == -1 {
            filtered = jobStore.jobApplications
        } else {
            filtered = jobStore.jobApplications.filter {
                cal.component(.year, from: $0.dateOfApplication) == selectedYear
            }
        }

        var temp: [ (key: String, date: Date, city: String) ] = []
        for job in filtered {
            let monthStart = cal.dateInterval(of: .month, for: job.dateOfApplication)?.start
                ?? cal.startOfDay(for: job.dateOfApplication)
            let city = job.location
            temp.append((key: city, date: monthStart, city: city))
        }

        let grouped = Dictionary(grouping: temp) { ($0.city, $0.date) }
        let monthly = grouped.map { (pair, items) -> MonthlyCityData in
            let (city, date) = pair
            return MonthlyCityData(
                monthKey: date.formatted(.dateTime.month(.abbreviated).year(.twoDigits)),
                city: city,
                count: items.count,
                date: date
            )
        }
        monthlyCityData = monthly.sorted {
            $0.date < $1.date
        }
    }

    private func monthlyCityDataFilteredForSelectedYear() -> [MonthlyCityData] {

        return monthlyCityData
    }

    private func buildTop20CompanyFreq() -> [CompanyFreq] {
        var freq: [String: Int] = [:]
        for job in jobStore.jobApplications {
            freq[job.companyName, default: 0] += 1
        }
        let sorted = freq.map { CompanyFreq(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
        return Array(sorted.prefix(20))
    }

    private func buildCityFrequency() -> [CompanyFreq] {
        var freq: [String: Int] = [:]
        for job in jobStore.jobApplications {
            freq[job.location, default: 0] += 1
        }
        let sorted = freq.map { CompanyFreq(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
        return sorted
    }

    private func buildCompanyFrequency() -> [CompanyFreq] {
        var freq: [String: Int] = [:]
        for job in jobStore.jobApplications {
            freq[job.companyName, default: 0] += 1
        }
        let sorted = freq.map { CompanyFreq(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
        return sorted
    }

    private func topCompanyName() -> String {
        let freq = buildCompanyFrequency()
        guard let top = freq.first else { return "None" }
        return top.name
    }

    private func topCity() -> (String, Int) {
        let freq = buildCityFrequency()
        guard let top = freq.first else { return ("None", 0) }
        return (top.name, top.count)
    }

    private func weekday(for date: Date) -> Int {

        let w = Calendar.current.component(.weekday, from: date)
        return w
    }

    private func shortWeekdaySymbol(_ weekday: Int) -> String? {

        let symbols = Calendar.current.shortWeekdaySymbols

        let index = weekday - 1
        guard index >= 0 && index < symbols.count else { return nil }
        return symbols[index]
    }

    private var chartColors: [Color] {
        return [
            .gray.opacity(0.2),
            .blue.opacity(0.4),
            .blue.opacity(0.7),
            .blue,
            .green,
            .purple
        ]
    }
}

extension View {

    @ViewBuilder
    func ifShouldScrollHorizontally(selectedYear: Int) -> some View {
        if #available(macOS 14.0, *), selectedYear == -1 {
            self.chartScrollableAxes(.horizontal)
        } else {
            self
        }
    }

    @ViewBuilder
    func ifShouldPlotSelect(stringBinding: Binding<String?>) -> some View {
        if #available(macOS 14.0, *), true {

            self
        } else {
            self
        }
    }
}