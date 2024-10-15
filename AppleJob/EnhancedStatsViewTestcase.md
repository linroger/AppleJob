
//
//  EnhancedStatsView.swift
//  AppleJob
//
//  Created by Roger Lin on 1/26/25.
//

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
   @State private var selectedYear: Int = -1  // -1 means “All Years”

   // MARK: - Data for Bar/Line
   @State private var barLineData: [DailyApps] = []
   @State private var barLineSelectedDate: Date? = nil

   // MARK: - City-based Data
   @State private var monthlyCityData: [MonthlyCityData] = []

   // MARK: - Body
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

               // Horizontally Stacked Bar Chart (isolated subview):
               if #available(macOS 13.0, *) {
                   HorizontalStackedBarChartView(
                       monthlyCityData: monthlyCityDataFilteredForSelectedYear()
                   )
               } else {
                   Text("Horizontally Stacked Bar Chart requires macOS 13+")
                       .foregroundColor(.secondary)
               }

               singleColumnVerticallyStackedBarChartSection

               top20CompaniesBarSection
               citiesByFrequencySection
               companiesByFrequencySection

               // Pie Charts (isolated subview):
               if #available(macOS 14.0, iOS 17.0, *) {
                   PieChartsSectionView(
                       monthlyData: monthlyShareData(),
                       cityData: cityShareData(),
                       yearData: yearlyShareData(),
                       selectedYearText: selectedYearText()
                   )
               } else {
                   Text("Interactive Pie Charts require macOS 14.0+.")
                       .foregroundColor(.secondary)
               }
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

   // MARK: - Map Section
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
                               width: max(10, CGFloat(cityPin.count) * 1.5),
                               height: max(10, CGFloat(cityPin.count) * 1.5)
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

   // MARK: - Recently Applied
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
                       .background(
                           jobStore.selectedJobIDs.contains(job.id)
                           ? Color.blue.opacity(0.2)
                           : Color.white.opacity(0.1)
                       )
                       .cornerRadius(5)
                   }
                   .buttonStyle(.plain)
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
       let sortedYears = availableYears.sorted()
       let yearsWithAll = sortedYears + [-1]  // -1 => "All Years"

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
       .padding(.horizontal)
   }

   // MARK: - GitHub-Style Charts
   // MARK: - GitHub-Style Charts
   private var githubChartsSection: some View {
       VStack(alignment: .leading, spacing: 24) {
           Text("GitHub-Style Contribution Charts")
               .font(.headline)
               .padding(.vertical)

           if #available(macOS 13.0, *) {
               // 1) Year Contribution
               Chart(yearContributionData) { item in
                   RectangleMark(
                       x: .value("WeekOfYear", item.date, unit: .weekOfYear),
                       y: .value("DayOfWeek", weekday(for: item.date))
                   )
                   .foregroundStyle(by: .value("Count", item.count))
                   .clipShape(RoundedRectangle(cornerRadius: 2)) // Rounded rectangles
                   .annotation { // Added annotation for each rectangle
                       if item.count > 0 {
                           Text("\(item.count)")
                               .font(.system(size: 8).bold())
                               .foregroundColor(.black.opacity(0.7))
                               .offset(y: -8) // Adjust annotation position
                       }
                   }
               }
               .chartXSelection(value: $yearChartSelectedDate)
               .chartForegroundStyleScale(range: Gradient(colors: enhancedChartColors)) // Using enhanced colors
               .chartYAxis {
                   AxisMarks(values: [1, 3, 5, 7]) { val in
                       if let i = val.as(Int.self), let label = shortWeekdaySymbol(i) {
                           AxisValueLabel(label)
                               .foregroundStyle(Color.secondary) // Axis labels in secondary color
                       }
                   }
               }
               .chartXAxis {
                   AxisMarks(values: .stride(by: .month)) {
                       AxisValueLabel(format: .dateTime.month(.abbreviated))
                           .foregroundStyle(Color.secondary) // Axis labels in secondary color
                   }
               }
               .chartPlotStyle { plotArea in
                   plotArea
                       .background(Color.gray.opacity(0.05)) // Subtle plot area background
               }
               .ifShouldScrollHorizontally(selectedYear: selectedYear)
               .frame(height: 200)
               .overlay {
                   if let sel = yearChartSelectedDate {
                       GeometryReader { geo in
                           let dayStr = sel.formatted(date: .abbreviated, time: .omitted)
                           let c = yearContributionData.first(where: { $0.date == sel })?.count ?? 0
                           Text("\(c) apps on \(dayStr)")
                               .font(.headline)
                               .padding(8) // Increased padding
                               .background(Color.green.opacity(0.3)) // Slightly different selection color
                               .cornerRadius(6) // Rounded selection background
                               .position(x: geo.size.width * 0.5, y: 15) // Adjusted position
                       }
                   }
               }

               // 2) Apps Contribution - similar styling as above, can be further customized if needed
               Chart(appsContributionData) { item in
                   RectangleMark(
                       x: .value("WeekOfYear", item.date, unit: .weekOfYear),
                       y: .value("DayOfWeek", weekday(for: item.date))
                   )
                   .foregroundStyle(by: .value("Count", item.count))
                   .clipShape(RoundedRectangle(cornerRadius: 2)) // Rounded rectangles
                   .annotation { // Added annotation for each rectangle
                       if item.count > 0 {
                           Text("\(item.count)")
                               .font(.system(size: 8).bold())
                               .foregroundColor(.black.opacity(0.7))
                               .offset(y: -8) // Adjust annotation position
                       }
                   }
               }
               .chartXSelection(value: $appsChartSelectedDate)
               .chartForegroundStyleScale(range: Gradient(colors: enhancedChartColors)) // Using enhanced colors
               .chartYAxis {
                   AxisMarks(values: [1, 3, 5, 7]) { val in
                       if let i = val.as(Int.self), let label = shortWeekdaySymbol(i) {
                           AxisValueLabel(label)
                               .foregroundStyle(Color.secondary)
                       }
                   }
               }
               .chartXAxis {
                   AxisMarks(values: .stride(by: .month)) {
                       AxisValueLabel(format: .dateTime.month(.abbreviated))
                           .foregroundStyle(Color.secondary)
                   }
               }
               .chartPlotStyle { plotArea in
                   plotArea
                       .background(Color.gray.opacity(0.05)) // Subtle plot area background
               }
               .padding(.vertical)
               .frame(height: 200)
               .ifShouldScrollHorizontally(selectedYear: selectedYear)
               .overlay {
                   if let sel = appsChartSelectedDate {
                       GeometryReader { geo in
                           let dayStr = sel.formatted(date: .abbreviated, time: .omitted)
                           let c = appsContributionData.first(where: { $0.date == sel })?.count ?? 0
                           Text("\(c) apps on \(dayStr)")
                               .font(.headline)
                               .padding(8) // Increased padding
                               .background(Color.blue.opacity(0.3)) // Slightly different selection color
                               .cornerRadius(6) // Rounded selection background
                               .position(x: geo.size.width * 0.5, y: 15) // Adjusted position
                       }
                   }
               }

           } else {
               Text("Charts require macOS 13.0+.")
                   .foregroundColor(.secondary)
           }
       }
       .frame(maxHeight: .infinity)
       .frame(maxWidth: .infinity)
   }

   // Enhanced color scale for GitHub charts
   var enhancedChartColors: [Color] {
       [.white, Color(red: 0.8, green: 0.9, blue: 0.8), Color(red: 0.6, green: 0.8, blue: 0.6), Color(red: 0.4, green: 0.7, blue: 0.4), Color(red: 0.2, green: 0.6, blue: 0.2)]
   }

   // MARK: - Time Range Picker
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

   // MARK: - Bar+Line Chart
   // MARK: - Bar+Line Chart
   // MARK: - Bar+Line Chart
   @ViewBuilder
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
                   .foregroundStyle(
                       LinearGradient(
                           gradient: Gradient(colors: [.blue.opacity(0.7), .blue]),
                           startPoint: .top,
                           endPoint: .bottom
                       )
                   )
                   .cornerRadius(3) // Add rounded corners to bars
               }
               .chartXSelection(value: $barLineSelectedDate)
               .chartXAxis {
                   AxisMarks(values: .stride(by: .month)) {
                       AxisGridLine(stroke: StrokeStyle(dash: [2])) // Style the grid line
                           .foregroundStyle(Color.gray.opacity(0.3))
                       AxisTick() // AxisTick - No direct styling needed here for stroke
                       AxisValueLabel(format: .dateTime.month(.abbreviated))
                           .foregroundStyle(Color.secondary)
                   }
                   // Removed .foregroundStyle from here - not for styling AxisMarks content directly
               }
               .chartYAxis {
                   AxisMarks() {
                       AxisGridLine() // Style the grid line if you want Y-axis grid lines
                           .foregroundStyle(Color.gray.opacity(0.3)) // Example for Y-axis grid lines
                       AxisTick() // AxisTick - No direct styling needed here for stroke
                   }
                   // Removed .foregroundStyle from here - not for styling AxisMarks content directly
               }
               .chartPlotStyle { plotArea in
                   plotArea
                       .background(Color.gray.opacity(0.05)) // Very subtle plot area background
               }
               .frame(height: 300)
               .overlay {
                   if let sel = barLineSelectedDate {
                       GeometryReader { geo in
                           let dayStr = sel.formatted(date: .abbreviated, time: .omitted)
                           let c = barLineData.first(where: { $0.date == sel })?.count ?? 0
                           Text("\(c) apps on \(dayStr)")
                               .font(.headline)
                               .padding(8) // Increased padding
                               .background(Color.green.opacity(0.3)) // Slightly different selection color
                               .cornerRadius(6) // Rounded selection background
                               .position(x: geo.size.width * 0.5, y: 15) // Adjusted position
                       }
                   }
               }
           } else {
               Text("Charts require macOS 13.0+.")
                   .foregroundColor(.secondary)
           }
       }
       .frame(maxWidth: .infinity)
   }
   // MARK: - Single Column Vertically Stacked Bar
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
               .ifShouldScrollHorizontally(selectedYear: selectedYear)
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
   }

   // MARK: - Top 20 Companies
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
               .chartXAxis {
                   AxisMarks(values: .automatic)
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
   }

   // MARK: - Cities by Frequency
   private var citiesByFrequencySection: some View {
       let cityCounts = cityFreqList()
       return VStack(alignment: .leading) {
           Text("Cities by Frequency (All Years)")
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
                       .padding(5)
                   }
               }
               .padding(.horizontal, 15)
               .padding(.bottom, 25)
               .frame(maxWidth: .infinity)
           }
       }
   }

   // MARK: - Companies by Frequency
   private var companiesByFrequencySection: some View {
       let companies = companyFreqList()
       return VStack(alignment: .leading, spacing: 10) {
           Text("Companies By Frequency")
               .font(.headline)

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
           // Use known dictionary for lat/long or fallback to a default
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
       guard let overallMin = allDates.min(), let overallMax = allDates.max() else {
           yearContributionData = []
           return
       }

       // Determine day range
       let (startOfRange, endOfRange): (Date, Date)
       if selectedYear == -1 {
           startOfRange = cal.startOfDay(for: overallMin)
           endOfRange   = overallMax
       } else {
           guard let s = cal.date(from: DateComponents(year: selectedYear, month: 1, day: 1)),
                 let e = cal.date(from: DateComponents(year: selectedYear, month: 12, day: 31))
           else {
               yearContributionData = []
               return
           }
           startOfRange = s
           endOfRange   = e
       }

       // Build day-based counts
       var contributionMap: [Date: Int] = [:]
       for job in jobStore.jobApplications {
           if job.dateOfApplication >= startOfRange && job.dateOfApplication <= endOfRange {
               let day = cal.startOfDay(for: job.dateOfApplication)
               contributionMap[day, default: 0] += 1
           }
       }

       // Convert to [Contribution]
       var allDays: [Date] = []
       var day = cal.startOfDay(for: startOfRange)
       while day <= endOfRange {
           allDays.append(day)
           if let next = cal.date(byAdding: .day, value: 1, to: day) {
               day = next
           } else {
               break
           }
       }

       yearContributionData = allDays.map { d in
           Contribution(date: d, count: contributionMap[d] ?? 0)
       }
   }

   private func computeAppsContribution() {
       // Similar logic to computeYearContribution, but could differ if you track "apps" differently.
       // For the snippet, we treat them similarly
       guard !jobStore.jobApplications.isEmpty else {
           appsContributionData = []
           return
       }

       let cal = Calendar.current
       let allDates = jobStore.jobApplications.map { $0.dateOfApplication }
       guard let overallMin = allDates.min(), let overallMax = allDates.max() else {
           appsContributionData = []
           return
       }

       let (startOfRange, endOfRange): (Date, Date)
       if selectedYear == -1 {
           startOfRange = cal.startOfDay(for: overallMin)
           endOfRange   = overallMax
       } else {
           guard let s = cal.date(from: DateComponents(year: selectedYear, month: 1, day: 1)),
                 let e = cal.date(from: DateComponents(year: selectedYear, month: 12, day: 31))
           else {
               appsContributionData = []
               return
           }
           startOfRange = s
           endOfRange   = e
       }

       var appsMap: [Date: Int] = [:]
       for job in jobStore.jobApplications {
           if job.dateOfApplication >= startOfRange && job.dateOfApplication <= endOfRange {
               let day = cal.startOfDay(for: job.dateOfApplication)
               appsMap[day, default: 0] += 1
           }
       }

       var allDays: [Date] = []
       var day = cal.startOfDay(for: startOfRange)
       while day <= endOfRange {
           allDays.append(day)
           if let next = cal.date(byAdding: .day, value: 1, to: day) {
               day = next
           } else {
               break
           }
       }

       appsContributionData = allDays.map { d in
           Contribution(date: d, count: appsMap[d] ?? 0)
       }
   }

   private func computeBarLineData() {
       // Build daily totals for last X months or the chosen time range
       let cal = Calendar.current
       var startDate: Date?
       let now = Date()

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

       guard let start = startDate else {
           barLineData = []
           return
       }

       // Collect daily counts
       var dailyMap: [Date: Int] = [:]
       for job in jobStore.jobApplications {
           if job.dateOfApplication >= start && job.dateOfApplication <= now {
               let day = cal.startOfDay(for: job.dateOfApplication)
               dailyMap[day, default: 0] += 1
           }
       }

       // Fill in zeroes for missing days
       var allDays: [Date] = []
       var day = cal.startOfDay(for: start)
       while day <= now {
           allDays.append(day)
           guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
           day = next
       }

       barLineData = allDays.map { d in
           DailyApps(date: d, count: dailyMap[d] ?? 0)
       }
   }

   private func computeMonthlyCityData() {
       // Summarize number of applications per (month, city)
       // Filter by selectedYear if needed
       var results: [MonthlyCityData] = []
       let cal = Calendar.current

       for job in jobStore.jobApplications {
           let jobYear = cal.component(.year, from: job.dateOfApplication)
           if selectedYear != -1, jobYear != selectedYear {
               continue
           }
           let month = cal.component(.month, from: job.dateOfApplication)
           let monthKey = "\(cal.shortMonthSymbols[month-1])"
           results.append(
               MonthlyCityData(
                   monthKey: monthKey,
                   city: job.location,
                   count: 1,
                   date: job.dateOfApplication
               )
           )
       }

       // Combine duplicates with same (monthKey, city)
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
       monthlyCityData = grouped.map { $0.value }
   }

   // MARK: - Data Helpers
   func monthlyCityDataFilteredForSelectedYear() -> [MonthlyCityData] {
       // We already filter in computeMonthlyCityData
       // So we can just return monthlyCityData
       monthlyCityData
   }

   // Return top 20 by count
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

   func cityFreqList() -> [(city: String, count: Int)] {
       var map: [String: Int] = [:]
       for job in jobStore.jobApplications {
           map[job.location, default: 0] += 1
       }
       return map.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
   }

   func companyFreqList() -> [(name: String, count: Int)] {
       var map: [String: Int] = [:]
       for job in jobStore.jobApplications {
           map[job.companyName, default: 0] += 1
       }
       return map.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
   }

   func topCompanyName() -> String {
       let sorted = companyFreqList()
       guard let first = sorted.first else { return "N/A" }
       return first.name
   }

   func topCity() -> (String, Int) {
       let sorted = cityFreqList()
       guard let first = sorted.first else { return ("N/A", 0) }
       return first
   }

   // MARK: - Helper for GitHub chart
   func shortWeekdaySymbol(_ dayInt: Int) -> String? {
       // dayInt is 1...7
       // 1 => Sunday, 2 => Monday, ...
       // but we might want M, W, F only or so. This is just an example:
       switch dayInt {
       case 1: return "Sun"
       case 2: return "Mon"
       case 3: return "Tue"
       case 4: return "Wed"
       case 5: return "Thu"
       case 6: return "Fri"
       case 7: return "Sat"
       default: return nil
       }
   }

   func weekday(for date: Date) -> Int {
       let w = Calendar.current.component(.weekday, from: date)
       // Sunday=1 ... Saturday=7
       return w
   }

   // Color scale for GitHub charts
   var chartColors: [Color] {
       [.white, .green, .yellow, .orange, .red]
   }

   // MARK: - Pie Chart Helpers
   func monthlyShareData() -> [(monthKey: String, count: Int)] {
       // Count how many apps in each month for the selectedYear
       let cal = Calendar.current
       var map: [String: Int] = [:]
       for job in jobStore.jobApplications {
           let jobYear = cal.component(.year, from: job.dateOfApplication)
           if selectedYear != -1, jobYear != selectedYear { continue }
           let m = cal.component(.month, from: job.dateOfApplication)
           let key = cal.shortMonthSymbols[m-1]
           map[key, default: 0] += 1
       }
       return map.map { (monthKey: $0.key, count: $0.value) }
           .sorted { $0.monthKey < $1.monthKey }
   }

   func cityShareData() -> [(city: String, count: Int)] {
       // Summarize city counts for selectedYear
       let cal = Calendar.current
       var map: [String: Int] = [:]
       for job in jobStore.jobApplications {
           let jobYear = cal.component(.year, from: job.dateOfApplication)
           if selectedYear != -1, jobYear != selectedYear { continue }
           map[job.location, default: 0] += 1
       }
       return map.map { (city: $0.key, count: $0.value) }
           .sorted { $0.count > $1.count }
   }

   func yearlyShareData() -> [(year: String, count: Int)] {
       // Summarize all years
       var map: [String: Int] = [:]
       let cal = Calendar.current
       for job in jobStore.jobApplications {
           let y = cal.component(.year, from: job.dateOfApplication)
           map["\(y)", default: 0] += 1
       }
       return map.map { (year: $0.key, count: $0.value) }
           .sorted { ($0.year) < ($1.year) }
   }

   func selectedYearText() -> String {
       if selectedYear == -1 {
           return "All Years"
       } else {
           return "\(selectedYear)"
       }
   }
}

// --------------------------------------------------
// MARK: - Subview for Horizontally Stacked Bar
// --------------------------------------------------
@available(macOS 13.0, *)
struct HorizontalStackedBarChartView: View {
   @State private var horizontalPlotSelection: String? = nil
   let monthlyCityData: [MonthlyCityData]

   var body: some View {
       VStack(alignment: .leading, spacing: 12) {
           Text("Applications by City - Horizontally Stacked Bar Chart")
               .font(.headline)

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
           .chartXSelection(value: $horizontalPlotSelection)
           .frame(height: 300)
           .overlay(alignment: Alignment.top) { // Fix for incorrect alignment
               if let selection = horizontalPlotSelection {
                   if let selectedData = monthlyCityData.first(where: { $0.monthKey == selection }) {
                       Text("\(selectedData.city): \(selectedData.count) Applications")
                           .padding(8)
                           .background(Color.gray.opacity(0.8))
                           .foregroundColor(.white)
                           .cornerRadius(8)
                           .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                           .padding(.top, 4)
                   }
               }
           }
       }
   }
}

// --------------------------------------------------
// MARK: - Subview for Pie Charts
// --------------------------------------------------
@available(macOS 14.0, iOS 17.0, *)
struct PieChartsSectionView: View {
   // Each pie chart uses local states for angle selection, so only the pie subview re-renders
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

           ScrollView(.horizontal, showsIndicators: true) {
               HStack(alignment: .center, spacing: 32) {
                   // 1) Month Pie
                   VStack {
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
                       .frame(minWidth: 350, minHeight: 350)
                   }

                   // 2) City Pie
                   VStack {
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
                       .frame(minWidth: 700, minHeight: 350)
                   }

                   // 3) Year Pie
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
                       PieChartView(
                           data: yearData.map { (key: $0.year, count: $0.count) },
                           selectedAngle: $selectedYearAngle,
                           centerLabel: "Years",
                           legendPosition: .bottom
                       )
                       .frame(minWidth: 350, minHeight: 350)
                   }
               }
               .padding(.horizontal, 10)
           }
       }
   }
}

// --------------------------------------------------
// MARK: - Reusable Swift Charts “Pie” subview
// --------------------------------------------------
@available(macOS 14.0, iOS 17.0, *)
struct PieChartView: View {
   // Data is an array of (key: String, count: Int)
   let data: [(key: String, count: Int)]
   @Binding var selectedAngle: Double?
   let centerLabel: String
   var showLegend: Bool = false
   var legendPosition: AnnotationPosition = .bottom
   var body: some View {
       // Sum up everything
       let totalCount = data.reduce(0) { $0 + $1.count }

       Chart(data, id: \.key) { item in
           SectorMark(
               angle: .value("Count", item.count),
               innerRadius: .ratio(0.5),
               angularInset: 1
           )
           .cornerRadius(4)
           .foregroundStyle(by: .value("Key", item.key))
           .opacity(item.key == selectedItemLabel(selectedAngle)?.key ? 1 : 0.65)
       }
       .chartLegend(position: showLegend ? legendPosition : .automatic)
       .chartAngleSelection(value: $selectedAngle)
       .chartBackground { chartProxy in
           GeometryReader { geometry in
               if let anchor = chartProxy.plotFrame {
                   let frame = geometry[anchor]
                   let selItem = selectedItemLabel(selectedAngle)
                   let label   = selItem?.key ?? centerLabel
                   let count   = selItem?.count ?? totalCount

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
   }

   // Convert angle to item
   private func selectedItemLabel(_ angle: Double?) -> (key: String, count: Int)? {
       guard let angle else { return nil }
       let ranges = buildAngleRanges(for: data)
       return ranges.first { $0.range.contains(angle) }
           .map { (key: $0.key, count: $0.count) }
   }

   // Build angle ranges from data
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

// A small helper struct for the angle range logic
@available(macOS 14.0, iOS 17.0, *)
fileprivate struct AngleRangeItem {
   let key: String
   let range: Range<Double>
   let count: Int
}

// --------------------------------------------------
// MARK: - Chart View Modifier for Horizontal Scrolling
// --------------------------------------------------
@available(macOS 13.0, *)
extension View {
   @ViewBuilder
   func ifShouldScrollHorizontally(selectedYear: Int) -> some View {
       // If we have multiple months/days, enable a horizontal scroll with a min width
       // that forces horizontal scrolling. This is optional.
       // We can do something like if user picks "All Years," we have more data => wide chart.
       if selectedYear == -1 {
           self
               .frame(minWidth: 1000) // Forces horizontal scroll if chart is wide
               .scrollDisabled(false)
       } else {
           self
       }
   }
}
