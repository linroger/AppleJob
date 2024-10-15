
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
    @State private var salaryRangeData: [SalaryRangeItem] = [] // Define salaryRangeData here

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


    @State private var selectedSalaryChartOption: SalaryChartDisplayOption = .default // Define selectedSalaryChartOption here

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
                salaryRangeSection // Salary Range Chart Section
            }
            .padding()
        }
        .onAppear {
            setupViewOnAppear()
            asyncDataComputations() // Call a single async function to compute all data
        }
        .onChange(of: selectedTimeRange) { _, _ in
            selectedTimeRangeRaw = selectedTimeRange.rawValue
            asyncDataComputations() // Recompute all data on time range change
        }
        .onChange(of: selectedYear) { _, _ in
            refreshYearDependentData()
        }
        .onChange(of: monthlyCityData) { _, _ in
            filterMonthlyCityDataForSelectedYear()
        }
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
    // MARK: - Async Data Computations (Consolidated)
    // --------------------------------------------------
    private func asyncDataComputations() {
        DispatchQueue.global(qos: .userInitiated).async {
            let cityPinsResult = buildCityPins()
            let barLineDataResult = buildBarLineData()
            let monthlyCityDataResult = buildMonthlyCityData()
            DispatchQueue.main.async {
                self.cityPins = cityPinsResult
                self.barLineData = barLineDataResult
                self.monthlyCityData = monthlyCityDataResult
                self.filterMonthlyCityDataForSelectedYear() // Filter after setting monthlyCityData
            }
        }
    }

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
                orderIndex: idx,
                city: app.location, // Store city
                year: cal.component(.year, from: app.dateOfApplication) // Store year
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
        // ... (rest of mapSection code is same)
        VStack(alignment: .leading, spacing: 12) {
            Text("Applications Map")
                .font(.headline)

            Map(coordinateRegion: $region, annotationItems: cityPins) { pin in
                MapAnnotation(coordinate: pin.coordinate) {
                    ZStack {
                        Circle().fill(.red).opacity(0.3).frame(width: circleSize(for: pin.count), height: circleSize(for: pin.count))
                        Circle().stroke(.red, lineWidth: 2).frame(width: circleSize(for: pin.count), height: circleSize(for: pin.count))
                        Text("\(pin.count)").font(.caption).foregroundColor(.black)
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
        // ... (rest of appliedCompaniesAndRolesView code is same)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(jobStore.jobApplications.sorted(by: { $0.dateOfApplication > $1.dateOfApplication }), id: \.id) { job in
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
                    .transition(.scale) // Add transition for applied job items
                }
            }
            .padding(.horizontal)
        }
    }

    // -----------------------------
    // Stats row
    // -----------------------------
    private var statsRowSection: some View {
        // ... (rest of statsRowSection code is same)
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
        // ... (rest of dynamicYearPickerSection code is same)
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

    // -----------------------------
    // GitHub-Style Charts
    // -----------------------------
    private var githubChartsSection: some View {
        // ... (rest of githubChartsSection code is same)
        VStack(alignment: .leading, spacing: 24) {
            Text("GitHub-Style Contribution Charts")
                .font(.headline)
                .padding(.bottom, 5)

            if #available(macOS 13.0, *) {
                VStack(alignment: .leading) {
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
                    .frame(height: 200)
                    .padding(.horizontal)
                    .overlay(alignment: .top) {
                        if let sel = yearChartSelectedDate {
                            let dayStr = sel.formatted(date: .abbreviated, time: .omitted)
                            let yearProgress = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: sel), to: Date()).day ?? 0
                            let percentage = Double(yearProgress) / 365.0 * 100

                            VStack {
                                Text(dayStr)
                                Text("\(String(format: "%.1f", percentage))% of year")
                            }
                            .padding(8)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                }
                .transition(.move(edge: .bottom)) // Add chart transition

                VStack(alignment: .leading) {
                    Chart(appsContributionData) { item in
                        RectangleMark(
                            x: .value("WeekOfYear", item.date, unit: .weekOfYear),
                            y: .value("DayOfWeek", weekday(for: item.date))
                        )
                        .foregroundStyle(by: .value("Count", item.count))
                        .clipShape(RoundedRectangle(cornerRadius: 0.5))
                        .annotation(position: .overlay) {
                            if item.count > 0 {
                                Text("\(item.count)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .bold()
                            }
                        }
                    }
                    .chartXSelection(value: $appsChartSelectedDate)
                    .chartForegroundStyleScale(range: Gradient(colors: chartColors))
                    .frame(height: 200)
                    .padding(.horizontal)
                    .overlay(alignment: .top) {
                        if let sel = appsChartSelectedDate {
                            let dayStr = sel.formatted(date: .abbreviated, time: .omitted)
                            let c = appsContributionData.first(where: { $0.date == sel })?.count ?? 0
                            VStack {
                                Text(dayStr)
                                Text("\(c) applications")
                            }
                            .padding(8)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                }
                .transition(.move(edge: .bottom)) // Add chart transition
            }
        }
    }





    // -----------------------------
    // Bar/Line Chart
    // -----------------------------
    private var barLineChartsSection: some View {
        // ... (rest of barLineChartsSection code is same)
        VStack(alignment: .leading, spacing: 24) {
            Text("Applications Frequency (Last \(selectedTimeRange.rawValue))")
                .font(.headline)
                .padding(.bottom, 5)

            Chart {
                ForEach(barLineData) { dayItem in
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
                    .cornerRadius(3)
                }
                if let average = computeAverage(for: barLineData) {
                    RuleMark(y: .value("Average", average))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(Color.red.opacity(0.7))
                }
            }
            .chartXSelection(value: $barLineSelectedDate)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) {
                    AxisGridLine(stroke: StrokeStyle(dash: [2]))
                        .foregroundStyle(Color.gray.opacity(0.3))
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                        .foregroundStyle(Color.secondary)
                }
            }
            .chartYAxis {
                AxisMarks {
                    AxisGridLine()
                        .foregroundStyle(Color.gray.opacity(0.3))
                    AxisTick()
                }
            }
            .chartPlotStyle { plotArea in
                plotArea.background(Color.gray.opacity(0.05))
            }
            .frame(height: 300)
            .overlay {
                if let sel = barLineSelectedDate {
                    GeometryReader { geo in
                        let dayStr = sel.formatted(date: .abbreviated, time: .omitted)
                        let c = barLineData.first(where: { $0.date == sel })?.count ?? 0
                        Text("\(c) apps on \(dayStr)")
                            .font(.headline)
                            .padding(8)
                            .background(Color.green.opacity(0.3))
                            .cornerRadius(6)
                            .position(x: geo.size.width * 0.5, y: 15)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .transition(.move(edge: .bottom)) // Add chart transition
    }


    // -----------------------------
    // Single Column Stacked Chart
    // -----------------------------
    private var singleColumnVerticallyStackedBarChartSection: some View {
        // ... (rest of singleColumnVerticallyStackedBarChartSection code is same)
        VStack(alignment: .leading, spacing: 12) {
            Text("Applications by City - Single Column Vertically Stacked Bar Chart")
                .font(.headline)
                .padding(.bottom, 5)
            if #available(macOS 13.0, *) {
                Chart(filteredMonthlyCityData) { item in
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
            } else {
                Text("Requires macOS 13.0+.")
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .transition(.move(edge: .bottom)) // Add chart transition
    }

    private var top20CompaniesBarSection: some View {
        // ... (rest of top20CompaniesBarSection code is same)
        VStack(alignment: .leading, spacing: 16) {
            Text("Top 20 Companies by Application Frequency (All Years)")
                .font(.headline)
                .padding(.bottom, 5)

            if #available(macOS 13.0, *) {
                let freq = buildTop20CompanyFreq()
                Chart(freq) { item in
                    BarMark(
                        x: .value("Company", item.name),
                        y: .value("Count", item.count)
                    )
                }
                .chartXAxis {
                    AxisMarks()
                }
                .chartYAxis {
                    AxisMarks()
                }
                .frame(height: 300)
            } else {
                Text("Requires macOS 13.0+.")
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .transition(.move(edge: .bottom)) // Add chart transition
    }

    private func buildTop20CompanyFreq() -> [CompanyFreq] {
        // ... (rest of buildTop20CompanyFreq code is same)
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
        // ... (rest of citiesByFrequencySection code is same)
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
        .transition(.move(edge: .bottom)) // Add scrollview transition
    }

    private var companiesByFrequencySection: some View {
        // ... (rest of companiesByFrequencySection code is same)
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
        .transition(.move(edge: .bottom)) // Add scrollview transition
    }


    // -----------------------------
    // Pie Charts Section
    // -----------------------------
    private var pieChartsSection: some View {
        // ... (rest of pieChartsSection code is same)
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
        .transition(.move(edge: .bottom)) // Add pie chart transition
    }


    // MARK: - The Salary Range Section
    @ViewBuilder
    private var salaryRangeSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Salary Ranges for Job Applications")
                    .font(.headline)
                    .padding(.bottom, 5)
                Spacer()
                Picker("Color By", selection: $selectedSalaryChartOption) {
                    ForEach(SalaryChartDisplayOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .animation(.easeInOut, value: selectedSalaryChartOption) // Animate picker changes
            }

            ZStack(alignment: .topTrailing) {
                // Build local domain/range for the dictionary-based color scale
                let colorDict = chartColorScale()
                let sortedKeys = colorDict.keys.sorted()

                Chart(salaryRangeData, id: \.id) { item in
                    BarMark(
                        xStart: .value("Min Salary", item.minSalary),
                        xEnd:   .value("Max Salary", item.maxSalary),
                        y:      .value("Application Order", item.orderIndex)
                    )
                    // Dynamically provide an identifier for color
                    .foregroundStyle(by: .value("Color Identifier", barColorIdentifier(for: item)))
                    .cornerRadius(4)
                    .annotation(position: .topTrailing, anchor: .point(CGPoint(x: 1, y: 1))) { // Pinned annotation
                        if hoveredSalaryItemID == item.id {
                            jobDetailTooltip(for: item)
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(.automatic) // Ensure even bar spacing
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 20000.0)) {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .currency(code: "USD"))
                    }
                }
                .chartForegroundStyleScale(
                    domain: sortedKeys,
                    range: sortedKeys.compactMap { colorDict[$0] }
                )
                .chartLegend(position: .bottom, alignment: .leading, spacing: 8)
                .frame(height: 500)
                .padding(.horizontal, 16)
                .chartOverlay { proxy in
                    Color.clear
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let location):
                                if let xValue = proxy.value(atX: location.x, as: Double.self),
                                   let yValue = proxy.value(atY: location.y, as: Int.self) {
                                    let foundItem = salaryRangeData.first { item in
                                        item.orderIndex == yValue &&
                                        xValue >= item.minSalary && xValue <= item.maxSalary
                                    }
                                    hoveredSalaryItemID = foundItem?.id
                                }

                            case .ended:
                                hoveredSalaryItemID = nil
                            }
                        }
                }

                if selectedSalaryChartOption == .city {
                    chartLegend(for: .city)
                } else if selectedSalaryChartOption == .year {
                    chartLegend(for: .year)
                }

            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal)
        .transition(.move(edge: .bottom)) // Add salary range chart transition
    }

    @ViewBuilder
    func chartLegend(for option: SalaryChartDisplayOption) -> some View {
        switch option {
        case .city:
            HStack {
                ForEach(CityCoordinateDictionary.keys.sorted(), id: \.self) { city in
                    let color = cityColor(for: city)
                    HStack{
                        Circle().fill(color).frame(width: 8, height: 8)
                        Text(city).font(.caption)
                    }
                }
            }
        case .year:
            HStack {
                ForEach([2022, 2023, 2024, 2025], id: \.self) { year in
                    let color = yearColor(for: year)
                    HStack{
                        Circle().fill(color).frame(width: 8, height: 8)
                        Text(String(year)).font(.caption)
                    }
                }
            }
        default:
            EmptyView()
        }
    }


    // MARK: - Construct the bar’s color identifier
    private func barColorIdentifier(for item: SalaryRangeItem) -> String {
        switch selectedSalaryChartOption {
        case .default:
            return "default"
        case .city:
            // Tag it as `city:locationString`
            return "city:\(item.city)"
        case .year:
            // Tag it as `year:YYYY`
            return "year:\(item.year)"
        }
    }

    // MARK: - Dynamically build a [String: Color] dictionary
    private func chartColorScale() -> [String: Color] {
        /**
         Returns a dictionary keyed by the same identifier strings
         we return in `barColorIdentifier(for:)`.

         1) "default" for the default color
         2) "city:<CityName>" for city-based keys
         3) "year:<YYYY>" for year-based keys
        */
        var scaleArray: [(String, Color)] = []

        // Default color
        scaleArray.append(("default", .blue.opacity(0.7)))

        // City-based colors
        for (cityName, _) in CityCoordinateDictionary {
            scaleArray.append(("city:\(cityName)", cityColor(for: cityName)))
        }

        // Year-based colors
        let interestingYears = [2022, 2023, 2024, 2025]
        for year in interestingYears {
            scaleArray.append(("year:\(year)", yearColor(for: year)))
        }

        // Convert array to Dictionary
        return Dictionary(uniqueKeysWithValues: scaleArray)
    }

    // MARK: - City => SwiftUI Color
    private func cityColor(for city: String) -> Color {
        let baseColors: [Color] = [.red, .green, .purple, .cyan, .orange, .brown, .pink, .indigo]
        let idx = abs(city.hashValue) % baseColors.count
        return baseColors[idx].opacity(0.7)
    }

    // MARK: - Year => SwiftUI Color
    private func yearColor(for year: Int) -> Color {
        let baseColors: [Color] = [.yellow, .red, .mint, .teal, .orange, .purple, .gray]
        let idx = abs(year.hashValue) % baseColors.count
        return baseColors[idx].opacity(0.7)
    }

    // MARK: - Tooltip
    @ViewBuilder
    private func jobDetailTooltip(for item: SalaryRangeItem) -> some View {
        if let job = jobStore.jobApplications.first(where: { $0.id == item.jobID }) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(job.companyName) - \(job.jobTitle)")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Applied: \(job.dateOfApplication, format: .dateTime.month().day().year())")
                    .font(.caption)
                    .foregroundColor(.white)
                Text("💰 \(formatSalary(item.minSalary)) - \(formatSalary(item.maxSalary))")
                    .font(.body)
                    .foregroundColor(.yellow)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.green.opacity(0.7)) // Slightly darker tooltip background
            )
            .frame(maxWidth: 250)
            .transition(.opacity.combined(with: .move(edge: .top))) // Add tooltip transition
        } else {
            Text("Unknown job.")
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.red.opacity(0.6)) // Distinct color for unknown job tooltips
                )
                .frame(maxWidth: 200)
                .foregroundColor(.white)
        }
    }

    // MARK: - Format Salary
    private func formatSalary(_ salary: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: salary)) ?? "\(salary)"
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
                }
                .chartXAxis {
                    AxisMarks()
                }
                .chartYAxis {
                    AxisMarks()
                }
                .frame(height: 300)
            }
            .transition(.move(edge: .bottom)) // Add chart transition
        }
    }
