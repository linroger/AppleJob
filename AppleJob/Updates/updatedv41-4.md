private var yearPickerSection: some View {
    HStack {
        Text("Select Year:")
        Picker("Year", selection: $selectedYearForCharts) {
            Text("All Years").tag(-1) // Adding the "All Years" option with a special tag
            ForEach(2021...2025, id: \.self) { yr in
                Text(verbatim: "\(yr)").tag(yr)
            }
        }
        .pickerStyle(.segmented)
    }
}

// Updated methods to handle "All Years" option

private func computeYearContribution() {
    let cal = Calendar.current

    if selectedYearForCharts == -1 { // Handle "All Years"
        let allApplications = jobStore.jobApplications
        let groupedByYear = Dictionary(grouping: allApplications, by: { cal.component(.year, from: $0.dateOfApplication) })

        yearContributionData = groupedByYear.keys.flatMap { year in
            guard let startOfYear = cal.date(from: DateComponents(year: year, month: 1, day: 1)),
                  let endOfYear = cal.date(from: DateComponents(year: year, month: 12, day: 31)) else { return [] }
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

            // Count contributions
            let filteredApps = allApplications.filter {
                $0.dateOfApplication >= startOfYear && $0.dateOfApplication <= endOfYear
            }
            for job in filteredApps {
                let day = cal.startOfDay(for: job.dateOfApplication)
                if let index = allDays.firstIndex(where: { $0.date == day }) {
                    allDays[index].count += 1
                }
            }

            return allDays
        }.sorted(by: { $0.date < $1.date })

    } else { // Handle specific year
        guard let startOfYear = cal.date(from: DateComponents(year: selectedYearForCharts, month: 1, day: 1)),
              let endOfYear = cal.date(from: DateComponents(year: selectedYearForCharts, month: 12, day: 31)) else {
            yearContributionData = []
            return
        }
        yearContributionData = generateContributions(startDate: startOfYear, endDate: endOfYear)
    }
}

private func computeAppsContribution() {
    let cal = Calendar.current

    if selectedYearForCharts == -1 { // Handle "All Years"
        var dateCount: [Date: Int] = [:]
        for job in jobStore.jobApplications {
            let day = cal.startOfDay(for: job.dateOfApplication)
            dateCount[day, default: 0] += 1
        }
        appsContributionData = dateCount.keys.sorted().map { date in
            Contribution(date: date, count: dateCount[date] ?? 0)
        }

    } else { // Handle specific year
        guard let startOfYear = cal.date(from: DateComponents(year: selectedYearForCharts, month: 1, day: 1)),
              let endOfYear = cal.date(from: DateComponents(year: selectedYearForCharts, month: 12, day: 31)) else {
            appsContributionData = []
            return
        }
        appsContributionData = generateDailyCounts(startDate: startOfYear, endDate: endOfYear)
    }
}

private func computeMonthlyCityData() {
    if selectedYearForCharts == -1 { // Handle "All Years"
        let groupedApps = Dictionary(grouping: jobStore.jobApplications, by: { app in
            Calendar.current.dateComponents([.year, .month], from: app.dateOfApplication)
        })

        monthlyCityData = groupedApps.flatMap { (key, apps) in
            let monthKey = "\(monthName(key.month)) \(key.year!)"
            let cityCounts = Dictionary(grouping: apps, by: { $0.location }).mapValues { $0.count }
            return cityCounts.map { MonthlyCityData(monthKey: monthKey, city: $0.key, count: $0.value, date: apps.first?.dateOfApplication ?? Date()) }
        }.sorted(by: { $0.date < $1.date })

    } else { // Handle specific year
        guard let startOfYear = Calendar.current.date(from: DateComponents(year: selectedYearForCharts, month: 1, day: 1)),
              let endOfYear = Calendar.current.date(from: DateComponents(year: selectedYearForCharts, month: 12, day: 31)) else {
            monthlyCityData = []
            return
        }
        monthlyCityData = generateMonthlyData(startDate: startOfYear, endDate: endOfYear)
    }
}

// Helper Methods
private func generateContributions(startDate: Date, endDate: Date) -> [Contribution] {
    let cal = Calendar.current
    var results: [Contribution] = []
    var cursor = startDate
    while cursor <= endDate {
        results.append(Contribution(date: cursor, count: 0)) // Initialize with 0
        if let nextDay = cal.date(byAdding: .day, value: 1, to: cursor) {
            cursor = nextDay
        } else {
            break
        }
    }
    return results
}

private func generateDailyCounts(startDate: Date, endDate: Date) -> [Contribution] {
    let cal = Calendar.current
    var dateCount: [Date: Int] = [:]
    for job in jobStore.jobApplications {
        if job.dateOfApplication >= startDate && job.dateOfApplication <= endDate {
            let day = cal.startOfDay(for: job.dateOfApplication)
            dateCount[day, default: 0] += 1
        }
    }
    return dateCount.keys.sorted().map { date in
        Contribution(date: date, count: dateCount[date] ?? 0)
    }
}

private func generateMonthlyData(startDate: Date, endDate: Date) -> [MonthlyCityData] {
    let cal = Calendar.current
    var cursor = startDate
    var results: [MonthlyCityData] = []

    while cursor <= endDate {
        let components = cal.dateComponents([.year, .month], from: cursor)
        let monthKey = "\(monthName(components.month)) \(components.year!)"
        guard let nextMonth = cal.date(byAdding: .month, value: 1, to: cursor) else { continue }

        let filteredApps = jobStore.jobApplications.filter {
            $0.dateOfApplication >= cursor && $0.dateOfApplication < nextMonth
        }
        let cityCounts = Dictionary(grouping: filteredApps, by: { $0.location }).mapValues { $0.count }
        results.append(contentsOf: cityCounts.map { MonthlyCityData(monthKey: monthKey, city: $0.key, count: $0.value, date: cursor) })

        cursor = nextMonth
    }
    return results
}