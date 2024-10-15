
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

    @State private var selectedTimeRange: TimeRange = .month

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

            if let tr = TimeRange(rawValue: selectedTimeRangeRaw) {
                selectedTimeRange = tr
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

    private var statsRowSection: some View {
        let total = jobStore.jobApplications.count
        let applied = jobStore.jobApplications.filter { $0.status == .applied }.count
        let interested = jobStore.jobApplications.filter { $0.status == .interested }.count
        let interviewed = jobStore.jobApplications.filter { $0.status == .interview }.count
        let distinctCities = Set(jobStore.jobApplications.map { $0.location }).count
        let topCompany = topCompanyName()
        let (topCityName, topCityCount) = topCity()

        let gradient = LinearGradient(colors: [.blue, .pink],
                                      startPoint: .leading, endPoint: .trailing)

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
                .font(.callout)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
    }

    /**
     Displays a segmented picker with all real years plus a final “All Years.”
     Example: [2022, 2023, 2024, -1]
     The user can switch to “All Years” or back to a specific year at any time.
     */
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

    @ViewBuilder
    private var barLineChartsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Applications Frequency (Last 12 Months / Range)")
                .font(.headline)
            if #available(macOS 13.0, *) {
                VStack(alignment: .leading) {
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
                }
            } else {
                Text("Charts require macOS 13.0+.")
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
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
                    AxisMarks(values: .automatic) {
                        AxisValueLabel()
                    }
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

    @ViewBuilder
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
        let cityCounts = cityFreqList()
        VStack(alignment: .leading) {
            Text("Cities by Frequency (All Years)")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: true) {
            let freq = buildCityFrequency()
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
                .frame(maxWidth: .infinity)
            }
        }
    }

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
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private var pieChartsSection: some View {
        if #available(macOS 13.0, *) {
            VStack(alignment: .center, spacing: 16) {
                Text("Application Shares (Pie Charts)")
                    .font(.headline)

                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(alignment: .center, spacing: 32) {

                        VStack {
                            Text("Share by Month (\(selectedYearText()))")
                                .font(.subheadline)

                            Chart(monthlyShareData()) { item in
                                SectorMark(
                                    angle: .value("Count", item.count),
                                    innerRadius: .ratio(0.5)
                                )
                                .foregroundStyle(by: .value("Month", item.monthKey))
                                .annotation(position: .overlay) {
                                    if item.count > 0 {
                                        Text("\(item.monthKey)\n\(item.count)")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .chartLegend(position: .bottom)
                            .frame(width: 400, height: 400)
                        }

                        VStack {
                            Text("Share by City (\(selectedYearText()))")
                                .font(.subheadline)

                            Chart(cityShareData()) { item in
                                SectorMark(
                                    angle: .value("Count", item.count),
                                    innerRadius: .ratio(0.5)
                                )
                                .foregroundStyle(by: .value("City", item.city))
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

                        VStack {
                            Text("Share by Year")
                                .font(.subheadline)

                            Chart(yearlyShareData()) { item in
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

    private func setupAvailableYears() {
        let allDates = jobStore.jobApplications.map { $0.dateOfApplication }
        guard !allDates.isEmpty else {

            self.availableYears = []
            self.selectedYear = -1
            return
        }
        let minDate = allDates.min()!
        let maxDate = allDates.max()!
        let cal = Calendar.current
        let minYear = cal.component(.year, from: minDate)
        let maxYear = cal.component(.year, from: maxDate)
        if minYear <= maxYear {

            self.availableYears = Array(minYear...maxYear)
        } else {
            self.availableYears = []
        }
        if !self.availableYears.contains(selectedYear) && selectedYear != -1 {

            self.selectedYear = -1
        }
    }

    private func computeCityPins() {
        var cityCount: [String: Int] = [:]
        for job in jobStore.jobApplications {
            cityCount[job.location, default: 0] += 1
        }
        cityPins = cityCount.map { (city, ct) in
            let coord = CityCoordinateDictionary[city]
                ?? CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795)
            return CityPin(city: city, coordinate: coord, count: ct)
        }
    }

    private func computeYearContribution() {
        guard !jobStore.jobApplications.isEmpty else {
            yearContributionData = []
            return
        }
        let cal = Calendar.current
        let allDates = jobStore.jobApplications.map { $0.dateOfApplication }
        let overallMin = allDates.min()!
        let overallMax = allDates.max()!

        var startOfRange: Date
        var endOfRange: Date
        if selectedYear == -1 {
            startOfRange = cal.startOfDay(for: overallMin)
            endOfRange = overallMax
        } else {
            guard let s = cal.date(from: DateComponents(year: selectedYear, month: 1, day: 1)),
                  let e = cal.date(from: DateComponents(year: selectedYear, month: 12, day: 31)) else {
                yearContributionData = []
                return
            }
            startOfRange = s
            endOfRange = e
        }

        let now = Date()
        var dayCursor = startOfRange
        var result: [Contribution] = []
        while dayCursor <= endOfRange {
            if dayCursor <= now {
                result.append(Contribution(date: dayCursor, count: 1))
            } else {
                result.append(Contribution(date: dayCursor, count: 0))
            }
            if let nextDay = cal.date(byAdding: .day, value: 1, to: dayCursor) {
                dayCursor = nextDay
            } else {
                break
            }
        }
        yearContributionData = result
    }

    private func computeAppsContribution() {
        guard !jobStore.jobApplications.isEmpty else {
            appsContributionData = []
            return
        }
        let cal = Calendar.current
        let allDates = jobStore.jobApplications.map { $0.dateOfApplication }
        let overallMin = allDates.min()!
        let overallMax = allDates.max()!

        var startOfRange: Date
        var endOfRange: Date
        if selectedYear == -1 {
            startOfRange = cal.startOfDay(for: overallMin)
            endOfRange = overallMax
        } else {
            guard let s = cal.date(from: DateComponents(year: selectedYear, month: 1, day: 1)),
                  let e = cal.date(from: DateComponents(year: selectedYear, month: 12, day: 31)) else {
                appsContributionData = []
                return
            }
            startOfRange = s
            endOfRange = e
        }

        var dateCount: [Date: Int] = [:]
        for job in jobStore.jobApplications {
            let d = cal.startOfDay(for: job.dateOfApplication)
            if d >= startOfRange && d <= endOfRange {
                dateCount[d, default: 0] += 1
            }
        }
        var results: [Contribution] = []
        var dayCursor = startOfRange
        while dayCursor <= endOfRange {
            let c = dateCount[dayCursor, default: 0]
            results.append(Contribution(date: dayCursor, count: c))
            if let nextDay = cal.date(byAdding: .day, value: 1, to: dayCursor) {
                dayCursor = nextDay
            } else {
                break
            }
        }
        appsContributionData = results
    }

    private func computeBarLineData() {
        let now = Date()
        let cal = Calendar.current
        var earliest: Date?

        switch selectedTimeRange {
        case .week:
            earliest = cal.date(byAdding: .day, value: -7, to: now)
        case .month:
            earliest = cal.date(byAdding: .month, value: -1, to: now)
        case .sixmonth:
            earliest = cal.date(byAdding: .month, value: -6, to: now)
        case .year:
            earliest = cal.date(byAdding: .year, value: -1, to: now)
        }
        guard let start = earliest else {
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
        guard !jobStore.jobApplications.isEmpty else {
            monthlyCityData = []
            return
        }
        let cal = Calendar.current
        let allDates = jobStore.jobApplications.map { $0.dateOfApplication }
        let overallMin = allDates.min()!
        let overallMax = allDates.max()!

        var startOfYear: Date
        var endOfYear: Date
        if selectedYear == -1 {
            startOfYear = cal.startOfDay(for: overallMin)
            endOfYear = overallMax
        } else {
            guard let s = cal.date(from: DateComponents(year: selectedYear, month: 1, day: 1)),
                  let e = cal.date(from: DateComponents(year: selectedYear, month: 12, day: 31)) else {
                monthlyCityData = []
                return
            }
            startOfYear = s
            endOfYear = e
        }
        var months: [Date] = []
        var cursor = startOfYear
        while cursor <= endOfYear {
            months.append(cursor)
            if let nxt = cal.date(byAdding: .month, value: 1, to: cursor) {
                cursor = nxt
            } else {
                break
            }
        }
        let appsInRange = jobStore.jobApplications.filter {
            $0.dateOfApplication >= startOfYear && $0.dateOfApplication <= endOfYear
        }
        var temp: [MonthlyCityData] = []
        for monthStart in months {
            let comps = cal.dateComponents([.year, .month], from: monthStart)
            let mKey = "\(monthName(comps.month)) \(comps.year!)"
            guard let nextMonth = cal.date(byAdding: .month, value: 1, to: monthStart) else { continue }

            let appsInMonth = appsInRange.filter {
                $0.dateOfApplication >= monthStart && $0.dateOfApplication < nextMonth
            }
            let cCount = Dictionary(grouping: appsInMonth, by: \.location).mapValues { $0.count }
            for (city, ct) in cCount {
                temp.append(MonthlyCityData(monthKey: mKey, city: city, count: ct, date: monthStart))
            }
        }
        temp.sort { $0.date < $1.date }
        monthlyCityData = temp
    }

    private func monthlyCityDataFilteredForSelectedYear() -> [MonthlyCityData] {
        monthlyCityData
    }

    private func monthlyShareData() -> [MonthlyCityData] {
        let groups = Dictionary(grouping: monthlyCityDataFilteredForSelectedYear()) { $0.monthKey }
        let results = groups.map { (k, recs) -> MonthlyCityData in
            let sum = recs.reduce(0) { $0 + $1.count }
            return MonthlyCityData(monthKey: k, city: "", count: sum, date: Date())
        }
        return results.sorted { $0.monthKey < $1.monthKey }
    }

    private func yearlyShareData() -> [YearlyData] {
        let cal = Calendar.current
        let allApps = jobStore.jobApplications
        if selectedYear == -1 {

            let groupedByYear = Dictionary(grouping: allApps) {
                cal.component(.year, from: $0.dateOfApplication)
            }
            return groupedByYear.map { (y, arr) in
                YearlyData(year: String(y), count: arr.count)
            }
            .sorted { $0.year < $1.year }
        } else {

            let sameYear = allApps.filter {
                cal.component(.year, from: $0.dateOfApplication) == selectedYear
            }
            return [YearlyData(year: "\(selectedYear)", count: sameYear.count)]
        }
    }

    private func cityShareData() -> [MonthlyCityData] {
        let grouped = Dictionary(grouping: monthlyCityDataFilteredForSelectedYear()) { $0.city }
        let arr = grouped.map { (city, recs) -> MonthlyCityData in
            let sum = recs.reduce(0) { $0 + $1.count }
            return MonthlyCityData(monthKey: "", city: city, count: sum, date: Date())
        }
        return arr.sorted { $0.count > $1.count }
    }

    private func buildTop20CompanyFreq() -> [CompanyFreq] {
        var freq: [String: Int] = [:]
        for job in jobStore.jobApplications {
            freq[job.companyName, default: 0] += 1
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

    @available(macOS 13.0, *)
    private var chartColors: [Color] {
        [
            Color.green.opacity(0.2),
            Color.green.opacity(0.3),
            Color.green.opacity(0.4),
            Color.green.opacity(0.5),
            Color.green.opacity(0.6),
            Color.green.opacity(0.7),
            Color.green.opacity(0.8),
            Color.green
        ]
    }

    private func weekday(for date: Date) -> Int {
        Calendar.current.component(.weekday, from: date)
    }

    private func shortWeekdaySymbol(_ weekday: Int) -> String? {
        let syms = Calendar.current.shortWeekdaySymbols
        guard weekday-1 >= 0, weekday-1 < syms.count else { return nil }
        return syms[weekday-1]
    }

    private func topCompanyName() -> String {
        let all = jobStore.jobApplications.map { $0.companyName }
        let freq = Dictionary(grouping: all, by: { $0 }).mapValues { $0.count }
        let sorted = freq.sorted { $0.value > $1.value }
        return sorted.first?.key ?? "N/A"
    }

    private func topCity() -> (String, Int) {
        let all = jobStore.jobApplications.map { $0.location }
        let freq = Dictionary(grouping: all, by: { $0 }).mapValues { $0.count }
        let sorted = freq.sorted { $0.value > $1.value }
        if let top = sorted.first {
            return (top.key, top.value)
        }
        return ("N/A", 0)
    }

    private func monthName(_ m: Int?) -> String {
        guard let m = m else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"
        if let d = Calendar.current.date(from: DateComponents(year: 2023, month: m, day: 1)) {
            return fmt.string(from: d)
        }
        return ""
    }

    private func selectedYearText() -> String {
        selectedYear == -1 ? "All" : "\(selectedYear)"
    }
}

@available(macOS 13.0, *)
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
    func ifShouldPlotSelect(_ binding: Binding<String?>) -> some View {
        if #available(macOS 14.0, *) {
            self.chartPlotSelection(value: binding)
        } else {
            self
        }
    }
}

/**
 Condition-based view modifier for scrolling horizontally if on macOS 14+ and user selected “All Years.”
 */
@available(macOS 13.0, *)
fileprivate extension View {
    @ViewBuilder
    func ifShouldScrollHorizontally(_ view: EnhancedStatsView? = nil) -> some View {

        if #available(macOS 14.0, *),
           let root = view,
           root.selectedYear == -1 {
            self.chartScrollableAxes(.horizontal)
        } else if #available(macOS 14.0, *),

        {

            self
        } else {

        }
    }

    /**
     If on macOS 14, apply .chartPlotSelection(value:).
     For a string-based axis, we need a string binding.
     Otherwise do nothing on older OS.
     */
    @ViewBuilder
    func ifShouldPlotSelect(stringBinding: Binding<String?>) -> some View {
        if #available(macOS 14.0, *) {
            self.chartPlotSelection(value: stringBinding)
        } else {
            self
        }
    }
}
