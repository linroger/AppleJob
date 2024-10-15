
/**
 The Stats & Analytics View:
   • A persistent time range for bar+line charts
   • A year picker without thousand separators
   • Charts made wide enough to fill horizontal space
   • Properly stacked city charts
   • Pie charts with legends on the right
   • Single-column vertically stacked bar chart now uses Swift Charts recommended approach:
       .foregroundStyle(by: .value("City", item.city))
       .chartForegroundStyleScale(...) if desired
 */
struct EnhancedStatsView: View {
    @EnvironmentObject var jobStore: JobStore

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 50)
    )

    @State private var cityPins: [CityPin] = []

    @State private var yearContributionData: [Contribution] = []
    @State private var appsContributionData: [Contribution] = []

    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case sixmonth = "Six Months"
        case year = "Year"
        var id: String { rawValue }
    }

    @AppStorage("StatsViewTimeRange") private var selectedTimeRangeRaw: String = TimeRange.month.rawValue
    @State private var selectedTimeRange: TimeRange = .month

    @AppStorage("StatsViewSelectedYear") private var selectedYearForCharts: Int = {
        let current = Calendar.current.component(.year, from: Date())
        return min(max(current, 2021), 2025)
    }()

    @State private var barLineData: [DailyApps] = []

    @State private var monthlyCityData: [MonthlyCityData] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                mapSection
                statsRowSection

                yearPickerSection

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
        .onChange(of: selectedTimeRange) { _ , newVal in
            selectedTimeRangeRaw = newVal.rawValue
            computeBarLineData()
        }
        .onChange(of: selectedYearForCharts) {  _, _ in
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
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity

            )
            .padding(.vertical, 8)
        }
    }

    private var yearPickerSection: some View {
        HStack {
            Text("Select Year:")
            Picker("Year", selection: $selectedYearForCharts) {
                Text("All Years").tag(-1) // Adding the "All Years" option with a special tag
                ForEach(2021...2025, id: \.self) { yr in

                    Text(verbatim:"\(yr)").tag(yr)
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

                Chart(appsContributionData) { item in
                    RectangleMark(
                        x: .value("WeekOfYear", item.date, unit: .weekOfYear),
                        y: .value("DayOfWeek", weekday(for: item.date))
                    )
                    .foregroundStyle(by: .value("Count", item.count))
                    .clipShape(RoundedRectangle(cornerRadius: 1))
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
                Text("Contribution chart requires macOS 13.0+.")
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
                            VStack(alignment: .leading) {

                                Chart(barLineData) { dayItem in
                                    BarMark(
                                        x: .value("Date", dayItem.date),
                                        y: .value("Applications", dayItem.count)
                                    )
                                }
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: .month)) {
                                        AxisGridLine()
                                        AxisTick()
                                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                                    }
                                }
                                .frame(height: 300)
                            }
            } else {
                Text("Charts require macOS 13.0+.")
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity

        )

    }

    @ViewBuilder
    private var horizontallyStackedBarChartSection: some View {
        if #available(macOS 13.0, *) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Applications by City - Horizontally Stacked Bar Chart")
                    .font(.headline)
                    Chart(monthlyCityDataFilteredForSelectedYear()) { item in
                        BarMark(
                            x: .value("Month", item.monthKey),
                            y: .value("Count", item.count)
                        )
                        .position(by: .value("City", item.city))
                        .foregroundStyle(by: .value("City", item.city))
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
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity

            )
                 }
        else {
            Text("Stacked bar chart requires macOS 13.0+.")
        }
    }

    @ViewBuilder
    private var singleColumnVerticallyStackedBarChartSection: some View {
        if #available(macOS 13.0, *) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Applications by City - Single Column Vertically Stacked Bar Chart")
                    .font(.headline)
                    Chart(monthlyCityDataFilteredForSelectedYear()) { item in

                        BarMark(
                            x: .value("Month", item.monthKey),
                            y: .value("Count", item.count)
                        )
                        .foregroundStyle(by: .value("City", item.city))
                    }

                    .chartXAxis {
                        AxisMarks()
                    }
                    .chartYAxis {
                        AxisMarks()
                    }
                    .frame(height: 300)

            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
                   }
        else {
            Text("Stacked bar chart requires macOS 13.0+.")
        }
    }

    private var top20CompaniesBarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top 20 Companies by Application Frequency (All Years)")
                .font(.headline)
            if #available(macOS 13.0, *) {
                        Chart(buildTop20CompanyFreq()) { item in
                            BarMark(
                                x: .value("Company", item.name),
                                y: .value("Count", item.count)
                            )
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
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity

        )
       }

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
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity

                )
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
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
                                .frame(maxWidth: 100)
                            Text("\(item.count)")
                                .font(.title3)
                        }
                        .padding(6)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity

                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Pie Charts
    @ViewBuilder
    private var pieChartsSection: some View {
        if #available(macOS 13.0, *) {
            VStack(alignment: .center, spacing: 16) {
                Text("Application Shares (Pie Charts)")
                    .font(.headline)

                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(alignment: .center, spacing: 32) {
                        // Pie Chart by Month
                        VStack {
                            Text("Share by Month (\(selectedYearForCharts))")
                                .font(.subheadline)

                            Chart(monthlyShareData()) { item in
                                SectorMark(
                                    angle: .value("Count", item.count),
                                    innerRadius: .ratio(0.5)
                                )
                                .foregroundStyle(by: .value("Month", item.monthKey))
                                .annotation(position: .overlay) { // Labels placed on the segments
                                    if item.count > 0 {
                                        Text("\(item.monthKey)\n\(item.count)")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .chartLegend(position: .bottom) // Move legend below the chart
                            .frame(width: 400, height: 400)
                        }

                        // Pie Chart by City
                        VStack {
                            Text("Share by City (\(selectedYearForCharts))")
                                .font(.subheadline)

                            Chart(cityShareData()) { item in
                                SectorMark(
                                    angle: .value("Count", item.count),
                                    innerRadius: .ratio(0.5)
                                )
                                .foregroundStyle(by: .value("City", item.city))
                                .annotation(position: .overlay) { // Labels placed on the segments
                                    if item.count > 0 {
                                        Text("\(item.city)\n\(item.count)")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .chartLegend(position: .bottom) // Move legend below the chart
                            .frame(width: 400, height: 400)
                        }

                        // Pie Chart by Year
                        VStack {
                            Text("Share by Year")
                                .font(.subheadline)

                            Chart(yearlyShareData()) { item in
                                SectorMark(
                                    angle: .value("Count", item.count),
                                    innerRadius: .ratio(0.5)
                                )
                                .foregroundStyle(by: .value("Year", item.year))
                                .annotation(position: .overlay) { // Labels placed on the segments
                                    if item.count > 0 {
                                        Text("\(item.year)\n\(item.count)")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .chartLegend(position: .bottom) // Move legend below the chart
                            .frame(width: 400, height: 400)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .frame(maxWidth: .infinity)
        }
        else {
            Text("Pie charts require macOS 13.0+.")
        }
    }


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
        guard let startOfYear = cal.date(from: DateComponents(year: selectedYearForCharts, month: 1, day: 1)),
              let endOfYear = cal.date(from: DateComponents(year: selectedYearForCharts, month: 12, day: 31)) else {
            yearContributionData = []
            return
        }
        let now = Date()
        var dayCursor = startOfYear
        var allDays: [Contribution] = []
        while dayCursor <= endOfYear {
            if dayCursor <= now {
                allDays.append(Contribution(date: dayCursor, count: 1))
            } else {
                allDays.append(Contribution(date: dayCursor, count: 0))
            }
            if let nextDay = cal.date(byAdding: .day, value: 1, to: dayCursor) {
                dayCursor = nextDay
            } else {
                break
            }
        }
        yearContributionData = allDays
    }

    private func computeAppsContribution() {
        let cal = Calendar.current
        guard let startOfYear = cal.date(from: DateComponents(year: selectedYearForCharts, month: 1, day: 1)),
              let endOfYear = cal.date(from: DateComponents(year: selectedYearForCharts, month: 12, day: 31)) else {
            appsContributionData = []
            return
        }
        var dateCount: [Date: Int] = [:]
        for job in jobStore.jobApplications {
            let day = cal.startOfDay(for: job.dateOfApplication)
            if day >= startOfYear && day <= endOfYear {
                dateCount[day, default: 0] += 1
            }
        }
        var results: [Contribution] = []
        var dayCursor = startOfYear
        while dayCursor <= endOfYear {
            results.append(Contribution(date: dayCursor, count: dateCount[dayCursor, default: 0]))
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
        guard let startOfYear = Calendar.current.date(
            from: DateComponents(year: selectedYearForCharts, month: 1, day: 1)),
              let endOfYear = Calendar.current.date(
                from: DateComponents(year: selectedYearForCharts, month: 12, day: 31))
        else {
            monthlyCityData = []
            return
        }
        let cal = Calendar.current
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
        let allApps = jobStore.jobApplications.filter {
            $0.dateOfApplication >= startOfYear && $0.dateOfApplication <= endOfYear
        }
        var temp: [MonthlyCityData] = []
        for monthStart in months {
            let comps = cal.dateComponents([.year, .month], from: monthStart)
            let mKey = "\(monthName(comps.month)) \(comps.year!)"
            guard let nextMonth = cal.date(byAdding: .month, value: 1, to: monthStart) else { continue }
            let appsInMonth = allApps.filter {
                $0.dateOfApplication >= monthStart && $0.dateOfApplication < nextMonth
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

    private func monthlyCityDataFilteredForSelectedYear() -> [MonthlyCityData] {
        monthlyCityData
    }

    private func monthlyShareData() -> [MonthlyCityData] {
        let groups = Dictionary(grouping: monthlyCityDataFilteredForSelectedYear()) { $0.monthKey }
        let results = groups.map { (monthKey, records) -> MonthlyCityData in
            let sum = records.reduce(0) { $0 + $1.count }
            return MonthlyCityData(monthKey: monthKey, city: "", count: sum, date: Date())
        }
        return results.sorted { $0.monthKey < $1.monthKey }
    }
    private func yearlyShareData() -> [YearlyData] {
        let applications = jobStore.jobApplications
        let groupedByYear = Dictionary(grouping: applications, by: { Calendar.current.component(.year, from: $0.dateOfApplication) })
        return groupedByYear.map { (year, apps) in
            YearlyData(year: String(year), count: apps.count)
        }.sorted { $0.year < $1.year }
    }

    struct YearlyData: Identifiable {
        let id = UUID()
        let year: String
        let count: Int
    }
    private func cityShareData() -> [MonthlyCityData] {
        let groups = Dictionary(grouping: monthlyCityDataFilteredForSelectedYear()) { $0.city }
        let results = groups.map { (city, records) -> MonthlyCityData in
            let sum = records.reduce(0) { $0 + $1.count }
            return MonthlyCityData(monthKey: "", city: city, count: sum, date: Date())
        }
        return results.sorted { $0.count > $1.count }
    }

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
        if let date = Calendar.current.date(from: DateComponents(year: selectedYearForCharts, month: m, day: 1)) {
            return formatter.string(from: date)
        }
        return ""
    }
}
