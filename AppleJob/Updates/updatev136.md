// --------------------------------------------------
// MARK: - EnhancedStatsView
// --------------------------------------------------
import SwiftUI
import Charts
import MapKit

// Define SalaryChartDisplayOption enum here, inside or outside the struct, as needed
enum SalaryChartDisplayOption: String, CaseIterable, Identifiable {
    case `default` = "Default"
    case city = "City"
    case year = "Year"
    var id: String { rawValue }
}

// --------------------------------------------------
// MARK: - EnhancedStatsView (Updated)
// --------------------------------------------------
struct EnhancedStatsView: View {
    // Environment objects
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var docStore: DocumentStore

    // MARK: - State Variables

    // General selection/hover states
    @State private var selectedSalaryValue: Double?
    @State private var salaryRangeData: [SalaryRangeItem] = []
    @State private var hoveredJobID: UUID? = nil
    @State private var hoveredPieJobID: UUID? = nil
    @State private var hoveredSalaryItemID: UUID? = nil
    @State private var selectedSalaryChartOption: SalaryChartDisplayOption = .default
    @State private var lastUpdateTimestamp = Date() // For forced redraws

    // Year and time-range states
    // Dedicated state for salary chart only
    @State private var selectedYear: Int = -1
    @State private var availableYears: [Int] = []
    @State private var salaryChartState = SalaryChartState()
    @State private var selectedTimeRange: TimeRange = .month
    @AppStorage("StatsViewTimeRange") private var selectedTimeRangeRaw: String = TimeRange.month.rawValue

    // Data storage arrays (using @State for isolated redraws)
    @State private var cityPins: [CityPin] = []
    @State private var barLineData: [DailyApps] = []
    @State private var yearContributionData: [Contribution] = []
    @State private var appsContributionData: [Contribution] = []
    @State private var monthlyCityData: [MonthlyCityData] = []
    @State private var filteredMonthlyCityData: [MonthlyCityData] = []
    @State private var salaryRangeData: [SalaryRangeItem] = [] //  @State for isolated redraws


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
                salaryRangeSection // Salary Range Chart Section - Isolated Section
            }
            .padding()
        }
        .onAppear(perform: setupViewOnAppear)
        .onChange(of: selectedTimeRange) { _, _ in
            selectedTimeRangeRaw = selectedTimeRange.rawValue
            asyncDataComputations()
        }
        .onChange(of: selectedYear) { _, _ in
            refreshYearDependentData()
        }
        .onChange(of: monthlyCityData) { _, _ in
            filterMonthlyCityDataForSelectedYear()
        }
        .onChange(of: jobStore.jobApplications) { _, _ in // React to job application changes
            asyncComputeSalaryRangeData() // Refresh salary chart data specifically on job changes
        }
    }
            
            salaryRangeSection
                .id(lastUpdateTimestamp) // Force redraw when needed
        }
        .onAppear {
            asyncComputeSalaryRangeData()
        }
        .onChange(of: jobStore.jobApplications) { _, _ in
            asyncComputeSalaryRangeData()
        }
    }
    
    // MARK: - Salary Range Section (Fixed Implementation)
    // MARK: - The Salary Range Section (Fixed)
    @ViewBuilder
    private var salaryRangeSection: some View {
        VStack(alignment: .leading) {
            headerSection
            chartContainer
        }
        .padding(.horizontal)
    }
    
    // MARK: - Chart Components
    private var headerSection: some View {
        HStack {
            Text("Salary Ranges for Job Applications")
                .font(.headline)
                .padding(.bottom, 5)
            Spacer()
            colorPicker
        }
    }
    
    private var colorPicker: some View {
        Picker("Color By", selection: $selectedSalaryChartOption) {
            ForEach(SalaryChartDisplayOption.allCases, id: \.self) { option in
                Text(option.rawValue).tag(option)
            }
        }
        .pickerStyle(.menu)
        .animation(.easeInOut, value: selectedSalaryChartOption)
        .onChange(of: selectedSalaryChartOption) { 
            salaryChartState.colorMapping = chartColorScale()
        }
    }
    
    private var chartContainer: some View {
        ZStack(alignment: .topTrailing) {
            chartContent
            legendOverlay
        }
        .frame(height: 500)
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private var chartContent: some View {
        Chart(salaryRangeData, id: \.id) { item in
            BarMark(
                xStart: .value("Min Salary", item.minSalary),
                xEnd: .value("Max Salary", item.maxSalary),
                y: .value("Order", item.orderIndex)
            )
            .foregroundStyle(by: .value("Color", barColorIdentifier(for: item)))
            .cornerRadius(4)
            .annotation(
                position: .overlay,
                alignment: .topTrailing,
                spacing: 0
            ) {
                if hoveredSalaryItemID == item.id {
                    jobDetailTooltip(for: item)
                        .fixedSize()
                        .offset(x: 20, y: -20) // Pinned to top-right
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: .stride(by: 1)) // Force discrete bands
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 20000)) {
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .currency(code: "USD"))
            }
        }
        .chartForegroundStyleScale(
            domain: salaryChartState.colorMapping.keys.sorted(),
            range: salaryChartState.colorMapping.values.sorted(by: { $0.key < $1.key })
        )
        .chartLegend(.hidden)
        .chartOverlay { proxy in
            Color.clear
                .onContinuousHover { phase in
                    handleHover(phase, proxy: proxy)
                }
        }
    }
    
    @ViewBuilder
    private var legendOverlay: some View {
        if selectedSalaryChartOption != .default {
            VStack(alignment: .leading) {
                ForEach(legendItems, id: \.0) { key, color in
                    HStack {
                        Circle()
                            .fill(color)
                            .frame(width: 12, height: 12)
                        Text(key)
                            .font(.caption)
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(8)
            .padding(.trailing)
        }
    }
    
    // MARK: - Data Processing
    private func asyncComputeSalaryRangeData() {
        DispatchQueue.global(qos: .userInitiated).async {
            let newData = buildSalaryRangeData()
            DispatchQueue.main.async {
                salaryRangeData = newData
                salaryChartState.colorMapping = chartColorScale()
                lastUpdateTimestamp = Date()
            }
        }
    }
    
    private func buildSalaryRangeData() -> [SalaryRangeItem] {
        let cal = Calendar.current
        let sortedApps = jobStore.jobApplications
            .filter { $0.hasValidSalary }
            .sorted { $0.dateOfApplication > $1.dateOfApplication } // Newest first
        
        return sortedApps.enumerated().map { index, app in
            SalaryRangeItem(
                jobID: app.id,
                company: app.companyName,
                jobTitle: app.jobTitle,
                date: app.dateOfApplication,
                minSalary: app.salaryMin ?? 0,
                maxSalary: app.salaryMax ?? 0,
                orderIndex: index, // Direct index mapping for even spacing
                city: app.location,
                year: cal.component(.year, from: app.dateOfApplication)
            )
        }
    }
    
    // MARK: - Helper Functions
    private func handleHover(_ phase: HoverPhase, proxy: ChartProxy) {
        switch phase {
        case .active(let location):
            if let yValue = proxy.value(atY: location.y, as: Int.self) {
                let foundItem = salaryRangeData.first { $0.orderIndex == yValue }
                hoveredSalaryItemID = foundItem?.id
            }
        case .ended:
            hoveredSalaryItemID = nil
        }
    }
    
    private var legendItems: [(String, Color)] {
        salaryChartState.colorMapping.map { ($0.key, $0.value) }
            .sorted(by: { $0.0 < $1.0 })
    }
    
    private func barColorIdentifier(for item: SalaryRangeItem) -> String {
        switch selectedSalaryChartOption {
        case .city: return "City: \(item.city)"
        case .year: return "Year: \(item.year)"
        default: return "Default"
        }
    }
    
    private func chartColorScale() -> [String: Color] {
        switch selectedSalaryChartOption {
        case .city:
            return Dictionary(uniqueKeysWithValues: salaryRangeData
                .map { $0.city }
                .uniqued()
                .map { ("City: \($0)", cityColor(for: $0)) }
            )
        case .year:
            return Dictionary(uniqueKeysWithValues: salaryRangeData
                .map { String($0.year) }
                .uniqued()
                .map { ("Year: \($0)", yearColor(for: Int($0)!)) }
            )
        default:
            return ["Default": .blue]
        }
    }
    
    // ... (Keep existing cityColor/yearColor implementations)
}

// MARK: - Helper Extensions
extension JobApplication {
    var hasValidSalary: Bool {
        guard let min = salaryMin, let max = salaryMax else { return false }
        return min > 0 && max > 0 && max >= min
    }
}

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

// MARK: - State Management
private class SalaryChartState {
    var colorMapping: [String: Color] = [:]
}

// MARK: - Tooltip Implementation (Unchanged)
extension EnhancedStatsView {
    private func jobDetailTooltip(for item: SalaryRangeItem) -> some View {
        // Keep existing implementation
    }
}
