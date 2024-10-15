import SwiftUI
import Charts
import MapKit

struct EnhancedStatsView: View {
    @EnvironmentObject var jobStore: JobStore

    // MARK: - Region & City Pins
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 50)
    )
    @State private var cityPins: [CityPin] = []

    // MARK: - GitHub-Style Data
    @State private var yearContributionData: [Contribution] = []
    @State private var appsContributionData: [Contribution] = []

    // Selections for GitHub Charts
    @State private var yearChartSelectedDate: Date? = nil
    @State private var appsChartSelectedDate: Date? = nil

    // MARK: - Time Range
    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case sixmonth = "Six Months"
        case year = "Year"
        var id: String { rawValue }
    }
    @AppStorage("StatsViewTimeRange") private var selectedTimeRangeRaw: String = TimeRange.month.rawValue
    @State private var selectedTimeRange: TimeRange = .month

    // MARK: - Year Picker
    @State private var availableYears: [Int] = []
    @State var selectedYear: Int = -1  // -1 means “All Years”

    // MARK: - Data for Bar/Line
    @State private var barLineData: [DailyApps] = []
    @State private var barLineSelectedDate: Date? = nil

    // MARK: - City-based Data
    @State private var monthlyCityData: [MonthlyCityData] = []

    // For macOS 14+ selection on bar charts
    @State private var horizontalPlotSelection: String? = nil
    @State private var singleColumnPlotSelection: String? = nil

    // MARK: - Top 20 Company selection
    @State private var top20CompanySelection: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                mapSection

                // New horizontally scrollable container
                appliedCompaniesAndRolesView

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
                    .padding(.bottom, 32) // Extra spacing so they don’t overlap with subsequent charts
            }
            .padding()
        }
        .onAppear {
            // Initialize time range from app storage.
            if let tr = TimeRange(rawValue: selectedTimeRangeRaw) {
                selectedTimeRange = tr
            } else {
                selectedTimeRange = .month
            }
            // Build up year array, city pins, chart data, etc.
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

    // MARK: - Map
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

    // MARK: - Horizontally Scrollable Companies & Roles
    private var appliedCompaniesAndRolesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // Sort from newest date to oldest
                ForEach(jobStore.jobApplications.sorted(by: { $0.dateOfApplication > $1.dateOfApplication })) { job in
                    VStack(alignment: .center, spacing: 6) {
                        Text(job.companyName)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 120)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(job.jobTitle)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.teal, .green]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 120)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Stats Row
    private var statsRowSection: some View {
        let total = jobStore.jobApplications.count
        let applied = jobStore.jobApplications.filter { $0.status == .applied }.count
        let interested = jobStore.jobApplications.filter { $0.status == .interested }.count
        let interviewed = jobStore.jobApplications.filter { $0.status == .interview }.count
        let distinctCities = Set(jobStore.jobApplications.map { $0.location }).count
        let topCompany = topCompanyName()
        let (topCityName, topCityCount) = topCity()

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
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Dynamic Year Picker
    private var dynamicYearPickerSection: some View {
        // Build a list from earliest to latest year, then add -1 for “All Years.”
        let sortedYears = availableYears.sorted()
        let yearsWithAll = sortedYears + [-1]

        return HStack {
            Text("Select Year:")

            Picker("Year", selection: $selectedYear) {
                ForEach(yearsWithAll, id: \.self) { yr in
                    if yr == -1 {
                        Text("All Years").tag(yr)
                    } else {
                        Text("\(yr)").tag(yr)
                    }
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - GitHub-Style Charts
    private var githubChartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("GitHub-Style Contribution Heatmap")
                .font(.headline)

            // 1) “Year” Chart
            if #available(macOS 14.0, iOS 17.0, *) {
                Chart(yearContributionData, id: \.date) { item in
                    RectangleMark(
                        x: .value("Date", item.date),
                        y: .value("Contributions", 0),
                        height: .fixed(16)
                    )
                    .foregroundStyle(colorForCount(item.count))
                    .annotation(position: .top, alignment: .center) {
                        if yearChartSelectedDate == item.date {
                            Text("\(item.count)")
                                .font(.caption2)
                        }
                    }
                }
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 14))
                }
                .frame(height: 200) // Increased to avoid clipping top cells
                .ifShouldScrollHorizontally(selectedYear: selectedYear)
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        if let date: Date = proxy.value(atX: value.location.x) {
                                            yearChartSelectedDate = date
                                        }
                                    }
                                    .onEnded { _ in }
                            )
                    }
                }
            } else {
                Text("Requires macOS 14+ or iOS 17+ for advanced charts.")
            }

            // 2) “Apps” Chart
            if #available(macOS 14.0, iOS 17.0, *) {
                Chart(appsContributionData, id: \.date) { item in
                    RectangleMark(
                        x: .value("Date", item.date),
                        y: .value("Contributions", 0),
                        height: .fixed(16)
                    )
                    .foregroundStyle(colorForCount(item.count))
                    .annotation(position: .top, alignment: .center) {
                        if appsChartSelectedDate == item.date {
                            Text("\(item.count)")
                                .font(.caption2)
                        }
                    }
                }
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 14))
                }
                .frame(height: 200) // Increased to avoid clipping top cells
                .ifShouldScrollHorizontally(selectedYear: selectedYear)
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        if let date: Date = proxy.value(atX: value.location.x) {
                                            appsChartSelectedDate = date
                                        }
                                    }
                                    .onEnded { _ in }
                            )
                    }
                }
            } else {
                Text("Requires macOS 14+ or iOS 17+ for advanced charts.")
            }
        }
    }

    // MARK: - Time Range Picker
    private var timeRangePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Applications Frequency (Last 12 Months / Range)")
                .font(.headline)
            Picker("Range:", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases) { tr in
                    Text(tr.rawValue).tag(tr)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Bar/Line Charts
    private var barLineChartsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if #available(macOS 14.0, iOS 17.0, *) {
                Chart(barLineData, id: \.id) { item in
                    BarMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(.blue)
                    .barStyle(.rounded)
                    .cornerRadius(3)
                    .width(16) // Thicker bars
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(minimumStride: .day))
                }
                .frame(height: 300)
                .chartScrollableAxes(.horizontal) // Scroll horizontally
            } else {
                Text("Requires macOS 14+ or iOS 17+ for advanced charts.")
            }
        }
    }

    // MARK: - Horizontally Stacked Bar Chart
    private var horizontallyStackedBarChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Applications by Month (Horizontally Stacked Bar)")
                .font(.headline)

            if #available(macOS 14.0, iOS 17.0, *) {
                let filtered = monthlyCityDataFilteredForSelectedYear()
                let grouped = Dictionary(grouping: filtered) { $0.monthKey }
                Chart {
                    ForEach(grouped.keys.sorted(), id: \.self) { mKey in
                        if let recs = grouped[mKey] {
                            BarMark(
                                x: .value("Count", recs.reduce(0) { $0 + $1.count }),
                                y: .value("Month", mKey)
                            )
                            .annotation(position: .overlay) {
                                Text("\(recs.reduce(0) { $0 + $1.count })")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            .foregroundStyle(.blue.gradient)
                            .width(20) // Make them wider
                        }
                    }
                }
                .frame(height: 400)
            } else {
                Text("Requires macOS 14+ or iOS 17+ for advanced charts.")
            }
        }
        .padding(.bottom, 32) // Add spacing so it doesn’t overlap other elements
    }

    // MARK: - Single Column Vertical Stacked Bar
    private var singleColumnVerticallyStackedBarChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly City Breakdown (Single Column)")
                .font(.headline)

            if #available(macOS 14.0, iOS 17.0, *) {
                let filtered = monthlyCityDataFilteredForSelectedYear()
                let grouped = Dictionary(grouping: filtered) { $0.monthKey }

                Chart {
                    ForEach(grouped.keys.sorted(), id: \.self) { monthKey in
                        if let recs = grouped[monthKey] {
                            ForEach(recs.indices, id: \.self) { idx in
                                BarMark(
                                    x: .value("Month", monthKey),
                                    y: .value("Count", Double(recs[idx].count))
                                )
                                .foregroundStyle(by: .value("City", recs[idx].city))
                                .annotation(position: .overlay) {
                                    if recs[idx].count > 2 {
                                        Text("\(recs[idx].count)")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                    }
                }
                .chartLegend(position: .bottom)
                .frame(height: 400)
            } else {
                Text("Requires macOS 14+ or iOS 17+ for advanced charts.")
            }
        }
        .padding(.bottom, 32)
    }

    // MARK: - Top 20 Companies
    private var top20CompaniesBarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top 20 Companies")
                .font(.headline)

            let top20 = buildTop20CompanyFreq()
            if top20.isEmpty {
                Text("No company data available.")
                    .foregroundColor(.secondary)
            } else {
                if #available(macOS 14.0, iOS 17.0, *) {
                    Chart(top20, id: \.name) { item in
                        BarMark(
                            x: .value("Count", item.count),
                            y: .value("Company", item.name)
                        )
                        .annotation(position: .overlay) {
                            Text("\(item.count)")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .foregroundStyle(.purple.gradient)
                    }
                    .chartLegend(.hidden)
                    .frame(height: 400)
                } else {
                    Text("Requires macOS 14+ or iOS 17+ for advanced charts.")
                }
            }
        }
    }

    // MARK: - City & Company Freq
    private var citiesByFrequencySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cities by Frequency")
                .font(.headline)
            let cityFreq = cityFreqList()
            if cityFreq.isEmpty {
                Text("No data.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(cityFreq.prefix(10), id: \.city) { item in
                    HStack {
                        Text(item.city)
                        Spacer()
                        Text("\(item.count)")
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var companiesByFrequencySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Companies by Frequency")
                .font(.headline)
            let companyFreq = companyFreqList()
            if companyFreq.isEmpty {
                Text("No data.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(companyFreq.prefix(10), id: \.name) { item in
                    HStack {
                        Text(item.name)
                        Spacer()
                        Text("\(item.count)")
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Pie Charts (Updated for Interactive Angle Selection)
    @State private var selectedMonthAngle: Double? = nil
    @State private var selectedCityAngle: Double? = nil
    @State private var selectedYearAngle: Double? = nil

    /// A helper struct to track partial-sum angle ranges.
    private struct AngleRangeItem {
        let key: String
        let range: Range<Double>
        let count: Int
    }

    /// Builds partial-sum angle ranges from any list of (key, count) pairs.
    private func buildAngleRanges(for entries: [(key: String, count: Int)]) -> [AngleRangeItem] {
        var result: [AngleRangeItem] = []
        var runningTotal: Double = 0
        for entry in entries {
            let start = runningTotal
            let end   = runningTotal + Double(entry.count)
            result.append(AngleRangeItem(key: entry.key, range: start..<end, count: entry.count))
            runningTotal = end
        }
        return result
    }

    /// Derive which segment is selected from the angle for the month pie chart.
    private func selectedMonthItem(_ angle: Double?) -> AngleRangeItem? {
        guard let angle else { return nil }
        let monthData = monthlyShareData().map { (key: $0.monthKey, count: $0.count) }
        let monthRanges = buildAngleRanges(for: monthData)
        return monthRanges.first { $0.range.contains(angle) }
    }

    /// Derive which segment is selected from the angle for the city pie chart.
    private func selectedCityItem(_ angle: Double?) -> AngleRangeItem? {
        guard let angle else { return nil }
        let cityData = cityShareData().map { (key: $0.city, count: $0.count) }
        let cityRanges = buildAngleRanges(for: cityData)
        return cityRanges.first { $0.range.contains(angle) }
    }

    /// Derive which segment is selected from the angle for the year pie chart.
    private func selectedYearItem(_ angle: Double?) -> AngleRangeItem? {
        guard let angle else { return nil }
        // Show all years (not tied to selectedYear).
        let yearData = yearlyShareData().map { (key: $0.year, count: $0.count) }
        let yearRanges = buildAngleRanges(for: yearData)
        return yearRanges.first { $0.range.contains(angle) }
    }

    @ViewBuilder
    private var pieChartsSection: some View {
        // Note: Requires macOS 14 or iOS 17 for .chartAngleSelection.
        if #available(macOS 14.0, iOS 17.0, *) {
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

                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(alignment: .center, spacing: 32) {
                        // -------------------------------------------
                        // 1) Donut Chart: Share by Month
                        // -------------------------------------------
                        VStack {
                            Text("Share by Month (\(selectedYearText()))")
                                .font(.subheadline)
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.green, .teal]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            let monthData = monthlyShareData().map { (key: $0.monthKey, count: $0.count) }
                            let monthRanges = buildAngleRanges(for: monthData)
                            let monthTotal  = monthRanges.reduce(0) { $0 + $1.count }

                            Chart(monthData, id: \.key) { item in
                                SectorMark(
                                    angle: .value("Count", item.count),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 2
                                )
                                .cornerRadius(4)
                                .foregroundStyle(by: .value("Month", item.key))
                                .opacity(item.key == selectedMonthItem(selectedMonthAngle)?.key ? 1 : 0.5)
                            }
                            .chartLegend(.hidden)
                            .chartAngleSelection(value: $selectedMonthAngle)
                            .chartBackground { chartProxy in
                                GeometryReader { geometry in
                                    if let anchor = chartProxy.plotFrame {
                                        let frame = geometry[anchor]
                                        let selItem = selectedMonthItem(selectedMonthAngle)
                                        let label   = selItem?.key ?? "Months"
                                        let count   = selItem?.count ?? monthTotal

                                        VStack {
                                            Text(label)
                                                .font(.headline)
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [.blue, .purple]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                            Text("\(count) apps")
                                                .font(.title2)
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [.orange, .red]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                        }
                                        .position(x: frame.midX, y: frame.midY)
                                    }
                                }
                            }
                            .frame(minWidth: 350, minHeight: 350)
                        }

                        // -------------------------------------------
                        // 2) Donut Chart: Share by City
                        // -------------------------------------------
                        VStack {
                            Text("Share by City (\(selectedYearText()))")
                                .font(.subheadline)
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.pink, .orange]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            let cityData = cityShareData().map { (key: $0.city, count: $0.count) }
                            let cityRanges = buildAngleRanges(for: cityData)
                            let cityTotal  = cityRanges.reduce(0) { $0 + $1.count }

                            Chart(cityData, id: \.key) { item in
                                SectorMark(
                                    angle: .value("Count", item.count),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 2
                                )
                                .cornerRadius(4)
                                .foregroundStyle(by: .value("City", item.key))
                                .opacity(item.key == selectedCityItem(selectedCityAngle)?.key ? 1 : 0.5)
                            }
                            .chartLegend(position: .bottom)
                            .chartAngleSelection(value: $selectedCityAngle)
                            .chartBackground { chartProxy in
                                GeometryReader { geometry in
                                    if let anchor = chartProxy.plotFrame {
                                        let frame = geometry[anchor]
                                        let selItem = selectedCityItem(selectedCityAngle)
                                        let label   = selItem?.key ?? "Cities"
                                        let count   = selItem?.count ?? cityTotal

                                        VStack {
                                            Text(label)
                                                .font(.headline)
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [.blue, .purple]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                            Text("\(count) apps")
                                                .font(.title2)
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [.orange, .red]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                        }
                                        .position(x: frame.midX, y: frame.midY)
                                    }
                                }
                            }
                            .frame(minWidth: 350, minHeight: 350)
                        }

                        // -------------------------------------------
                        // 3) Donut Chart: Share by Year (All Years)
                        // -------------------------------------------
                        VStack {
                            Text("Share by Year")
                                .font(.subheadline)
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.indigo, .cyan]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            // Because we always show all years here, ignoring selectedYear:
                            let yearData = yearlyShareData().map { (key: $0.year, count: $0.count) }
                            let yearRanges = buildAngleRanges(for: yearData)
                            let yearTotal  = yearRanges.reduce(0) { $0 + $1.count }

                            Chart(yearData, id: \.key) { item in
                                SectorMark(
                                    angle: .value("Count", item.count),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 2
                                )
                                .cornerRadius(4)
                                .foregroundStyle(by: .value("Year", item.key))
                                .opacity(item.key == selectedYearItem(selectedYearAngle)?.key ? 1 : 0.5)
                            }
                            .chartLegend(position: .bottom)
                            .chartAngleSelection(value: $selectedYearAngle)
                            .chartBackground { chartProxy in
                                GeometryReader { geometry in
                                    if let anchor = chartProxy.plotFrame {
                                        let frame = geometry[anchor]
                                        let selItem = selectedYearItem(selectedYearAngle)
                                        let label   = selItem?.key ?? "Years"
                                        let count   = selItem?.count ?? yearTotal

                                        VStack {
                                            Text(label)
                                                .font(.headline)
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [.pink, .purple]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                            Text("\(count) apps")
                                                .font(.title2)
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [.yellow, .orange]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                        }
                                        .position(x: frame.midX, y: frame.midY)
                                    }
                                }
                            }
                            .frame(minWidth: 350, minHeight: 350)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            } else {
                Text("Pie charts require macOS 14.0+ or iOS 17.0+.")
            }
        }
    }

    // MARK: - Setup & Compute Methods
    private func setupAvailableYears() {
        let allDates = jobStore.jobApplications.map { $0.dateOfApplication }
        guard !allDates.isEmpty else {
            self.availableYears = []
            self.selectedYear = -1
            return
        }
        let cal = Calendar.current
        let minYear = cal.component(.year, from: allDates.min()!)
        let maxYear = cal.component(.year, from: allDates.max()!)

        if minYear <= maxYear {
            self.availableYears = Array(minYear...maxYear)
        } else {
            self.availableYears = []
        }
        // If current selectedYear is not in the available range, default to All Years.
        if !self.availableYears.contains(selectedYear) && selectedYear != -1 {
            self.selectedYear = -1
        }
    }

    private func computeCityPins() {
        // Build cityPin data from all job applications
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

        // Determine day range
        let (startOfRange, endOfRange): (Date, Date)
        if selectedYear == -1 {
            startOfRange = cal.startOfDay(for: overallMin)
            endOfRange = overallMax
        } else {
            guard let s = cal.date(from: DateComponents(year: selectedYear, month: 1, day: 1)),
                  let e = cal.date(from: DateComponents(year: selectedYear, month: 12, day: 31))
            else {
                yearContributionData = []
                return
            }
            startOfRange = cal.startOfDay(for: s)
            endOfRange = e
        }

        var results: [Contribution] = []
        var dayCursor = startOfRange
        while dayCursor <= endOfRange {
            let dayVal = cal.startOfDay(for: dayCursor)
            results.append(Contribution(date: dayVal, count: 1))
            if let nextDay = cal.date(byAdding: .day, value: 1, to: dayCursor) {
                dayCursor = nextDay
            } else {
                break
            }
        }
        yearContributionData = results
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

        let (startOfRange, endOfRange): (Date, Date)
        if selectedYear == -1 {
            startOfRange = cal.startOfDay(for: overallMin)
            endOfRange = overallMax
        } else {
            guard let s = cal.date(from: DateComponents(year: selectedYear, month: 1, day: 1)),
                  let e = cal.date(from: DateComponents(year: selectedYear, month: 12, day: 31))
            else {
                appsContributionData = []
                return
            }
            startOfRange = cal.startOfDay(for: s)
            endOfRange = e
        }

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

        let (startOfYear, endOfYear): (Date, Date)
        if selectedYear == -1 {
            startOfYear = cal.startOfDay(for: overallMin)
            endOfYear = overallMax
        } else {
            guard let s = cal.date(from: DateComponents(year: selectedYear, month: 1, day: 1)),
                  let e = cal.date(from: DateComponents(year: selectedYear, month: 12, day: 31))
            else {
                monthlyCityData = []
                return
            }
            startOfYear = cal.startOfDay(for: s)
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
            guard let comps = cal.dateComponents([.year, .month], from: monthStart).month,
                  let yearVal = cal.dateComponents([.year], from: monthStart).year
            else { continue }
            let mKey = "\(monthName(comps)) \(yearVal)"

            guard let nextMonth = cal.date(byAdding: .month, value: 1, to: monthStart) else { continue }

            let appsInMonth = appsInRange.filter {
                $0.dateOfApplication >= monthStart && $0.dateOfApplication < nextMonth
            }
            let cityGrouped = Dictionary(grouping: appsInMonth, by: \.location)
            for (city, group) in cityGrouped {
                temp.append(MonthlyCityData(
                    monthKey: mKey,
                    city: city,
                    count: group.count,
                    date: monthStart
                ))
            }
        }
        temp.sort { $0.date < $1.date }
        monthlyCityData = temp
    }

    private func monthlyCityDataFilteredForSelectedYear() -> [MonthlyCityData] {
        monthlyCityData  // already filtered inside computeMonthlyCityData
    }

    // MARK: - Pie Chart Data
    private func monthlyShareData() -> [MonthlyCityData] {
        let grouped = Dictionary(grouping: monthlyCityDataFilteredForSelectedYear()) { $0.monthKey }
        return grouped.map { (mKey, recs) in
            let sum = recs.reduce(0) { $0 + $1.count }
            return MonthlyCityData(monthKey: mKey, city: "", count: sum, date: Date())
        }
        .sorted { $0.monthKey < $1.monthKey }
    }

    private func cityShareData() -> [MonthlyCityData] {
        let grouped = Dictionary(grouping: monthlyCityDataFilteredForSelectedYear()) { $0.city }
        return grouped.map { (city, recs) in
            let sum = recs.reduce(0) { $0 + $1.count }
            return MonthlyCityData(monthKey: "", city: city, count: sum, date: Date())
        }
        .sorted { $0.count > $1.count }
    }

    /// This now always shows the share of all years, ignoring the selectedYear.
    private func yearlyShareData() -> [YearlyData] {
        let cal = Calendar.current
        let allApps = jobStore.jobApplications
        // Group all apps by year (never filtered by selectedYear).
        let grouped = Dictionary(grouping: allApps) {
            cal.component(.year, from: $0.dateOfApplication)
        }
        return grouped.map { (yearVal, arr) in
            YearlyData(year: String(yearVal), count: arr.count)
        }
        .sorted { $0.year < $1.year }
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

    // MARK: - City/Company Frequencies
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

    // MARK: - Simple Helpers
    private func topCompanyName() -> String {
        let freq = companyFreqList()
        return freq.first?.name ?? "N/A"
    }

    private func topCity() -> (String, Int) {
        let freq = cityFreqList()
        if let top = freq.first {
            return (top.city, top.count)
        }
        return ("N/A", 0)
    }

    private func weekday(for date: Date) -> Int {
        Calendar.current.component(.weekday, from: date)
    }

    private func shortWeekdaySymbol(_ weekday: Int) -> String? {
        let syms = Calendar.current.shortWeekdaySymbols
        guard weekday - 1 >= 0, weekday - 1 < syms.count else { return nil }
        return syms[weekday - 1]
    }

    private func monthName(_ m: Int) -> String {
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

    // For the squares in the GitHub chart, choose a gradient
    @available(macOS 13.0, *)
    private var chartColors: [Color] {
        [
            .green.opacity(0.2),
            .green.opacity(0.4),
            .green.opacity(0.6),
            .green.opacity(0.8),
            .green
        ]
    }

    @available(macOS 13.0, *)
    private func colorForCount(_ count: Int) -> Color {
        // Adjust these thresholds to your taste.
        switch count {
        case 0:
            return .green.opacity(0.15)
        case 1:
            return .green.opacity(0.35)
        case 2:
            return .green.opacity(0.55)
        case 3:
            return .green.opacity(0.75)
        default:
            return .green
        }
    }
}