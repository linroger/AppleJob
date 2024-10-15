

// Content from: Trips-Coexistence/TripsWidget/PreviewSampleData.swift
/*
Abstract:
The preview sample data actor which provides an in-memory model container.
*/
import SwiftData
import SwiftUI
/**
 Preview sample data.
 */
actor PreviewSampleData {
    @MainActor
    static var container: ModelContainer = {
        let schema = Schema([Trip.self, BucketListItem.self, LivingAccommodation.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        let sampleData: [any PersistentModel] = [
            Trip.preview, BucketListItem.preview, LivingAccommodation.preview
        ]
        sampleData.forEach {
            container.mainContext.insert($0)
        }
        return container
    }()
}

// Content from: Trips-Coexistence/TripsWidget/TripsWidget.swift
/*
Abstract:
The types that provide timeline entries for the widget.
*/
import WidgetKit
import SwiftUI
import SwiftData
struct TripsWidget: Widget {
    let kind: String = "TripsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TripsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Future Trips")
        .description("See your upcoming trips.")
    }
}
struct Provider: TimelineProvider {
    private let modelContainer: ModelContainer
    
    init() {
        let appGroupContainerID = "group.com.example.apple-samplecode.SampleTrips"
        guard let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupContainerID) else {
            fatalError("Shared file container could not be created.")
        }
        let url = appGroupContainer.appendingPathComponent("Trips.sqlite")
        do {
            modelContainer = try ModelContainer(for: Trip.self, configurations: ModelConfiguration(url: url))
        } catch {
            fatalError("Failed to create the model container: \(error)")
        }
    }
    func placeholder(in context: Context) -> SimpleEntry {
        return SimpleEntry.placeholderEntry
    }
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry.placeholderEntry)
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        /**
         modelContainer.mainContext requires main actor.
         This method returns immediately, but calls the completion handler at the end of the task.
         */
        Task { @MainActor in
            var fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Trip.startDate, order: .forward)])
            let now = Date.now
            fetchDescriptor.predicate = #Predicate { $0.endDate >= now }
            if let upcomingTrips = try? modelContainer.mainContext.fetch(fetchDescriptor) {
                if let trip = upcomingTrips.first {
                    let newEntry = SimpleEntry(date: .now,
                                               startDate: trip.startDate,
                                               endDate: trip.endDate,
                                               name: trip.name,
                                               destination: trip.destination)
                    let timeline = Timeline(entries: [newEntry], policy: .after(newEntry.endDate))
                    completion(timeline)
                    return
                }
            }
            /**
             Return "No Trips" entry with .never policy when there is no upcoming trip.
             The main app triggers a widget update when adding a new trip.
             */
            let newEntry = SimpleEntry(date: .now,
                                       startDate: .now,
                                       endDate: .now,
                                       name: "No Trips",
                                       destination: "")
            let timeline = Timeline(entries: [newEntry], policy: .never)
            completion(timeline)
        }
    }
}
struct SimpleEntry: TimelineEntry {
    let date: Date
    
    let startDate: Date
    let endDate: Date
    let name: String
    let destination: String
    
    static var placeholderEntry: SimpleEntry {
        let now = Date()
        let sevenDaysAfter = Calendar.current.date(byAdding: .day, value: 7, to: now)
        return SimpleEntry(date: now, startDate: now, endDate: sevenDaysAfter ?? Date(), name: "Honeymoon", destination: "Hawaii")
    }
}
struct TripsWidgetEntryView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "car.circle")
                        .imageScale(.large)
                    Text(entry.name)
                        .font(.system(.title2).weight(.semibold))
                        .minimumScaleFactor(0.5)
                    Spacer()
                }
                .foregroundColor(.green)
                
                Divider()
                if !entry.destination.isEmpty {
                    Text(entry.destination)
                        .font(.system(.title3).weight(.semibold))
                        .minimumScaleFactor(0.5)
                    Text(entry.startDate, style: .date)
                        .foregroundColor(.gray)
                    Text(entry.endDate, style: .date)
                        .foregroundColor(.gray)
                }
            }
        }
        .containerBackground(for: .widget) {
            Color.white
        }
    }
}
#Preview(as: .systemSmall) {
    TripsWidget()
} timeline: {
    SimpleEntry.placeholderEntry
}

// Content from: Trips-Coexistence/TripsWidget/Trip.swift
/*
Abstract:
The model class of trips.
*/
import Foundation
import SwiftData
import Observation
@Model
final class Trip {
    var destination: String
    var endDate: Date
    var name: String
    var startDate: Date
    
    @Relationship(deleteRule: .cascade, inverse: \BucketListItem.trip)
    var bucketList: [BucketListItem]
    
    @Relationship(deleteRule: .cascade, inverse: \LivingAccommodation.trip)
    var livingAccommodation: LivingAccommodation?
    
    init(name: String, destination: String, startDate: Date = .now, endDate: Date = .distantFuture) {
        self.name = name
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
        self.bucketList = []
    }
}
extension Trip {
    static var preview: Trip {
        Trip(name: "Trip Name", destination: "Trip destination",
             startDate: .now, endDate: .now.addingTimeInterval(4 * 3600))
    }
}

// Content from: Trips-Coexistence/TripsWidget/LivingAccommodation.swift
/*
Abstract:
The model class of a living accommodation.
*/
import SwiftData
@Model
final class LivingAccommodation {
    var address: String
    var placeName: String
    var trip: Trip?
    init(address: String, placeName: String) {
        self.address = address
        self.placeName = placeName
    }
}
extension LivingAccommodation {
    static var preview: LivingAccommodation {
        LivingAccommodation(address: "Yosemite National Park, CA 95389", placeName: "Yosemite National Park")
    }
}

// Content from: Trips-Coexistence/TripsWidget/BucketListItem.swift
/*
Abstract:
The model class of bucket list items.
*/
import SwiftData
@Model
final class BucketListItem {
    var details: String
    var hasReservation: Bool
    var isInPlan: Bool
    var title: String
    var trip: Trip?
    
    init(title: String, details: String, hasReservation: Bool, isInPlan: Bool) {
        self.title = title
        self.details = details
        self.hasReservation = hasReservation
        self.isInPlan = isInPlan
    }
}
extension BucketListItem {
    static var preview: BucketListItem {
        let item = BucketListItem(
            title: "A bucket list item title",
            details: "Details of my bucket list item",
            hasReservation: true, isInPlan: true)
        item.trip = .preview
        return item
    }
}

// Content from: Trips-Coexistence/TripsWidget/TripsWidgetBundle.swift
/*
Abstract:
The widget bundle.
*/
import WidgetKit
import SwiftUI
@main
struct TripsWidgetBundle: WidgetBundle {
    var body: some Widget {
        TripsWidget()
    }
}

// Content from: Trips-Coexistence/Trips/CDBucketListItem+Extension.swift
/*
Abstract:
The model class of a bucket list item.
*/
import Foundation
extension CDBucketListItem {
    var displayTitle: String {
        guard let title, !title.isEmpty
        else { return "Untitled bucket list item" }
        return title
    }
    
    var displayDetails: String {
        guard let details, !details.isEmpty
        else { return "No details" }
        return details
    }
    
    static var preview: CDBucketListItem {
        let result = PersistenceController.preview
        let viewContext = result.container.viewContext
        let item = CDBucketListItem(context: viewContext)
        item.title = "A bucket list item title"
        item.details = "Details of my bucket list item"
        item.hasReservation = true
        item.isInPlan = true
        return item
    }
}

// Content from: Trips-Coexistence/Trips/Persistence.swift
/*
Abstract:
A class that sets up the Core Data stack.
*/
import CoreData
import SwiftData
struct PersistenceController {
    let appGroupContainerID = "group.com.example.apple-samplecode.SampleTrips"
    static let shared = PersistenceController()
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        let newTrip = CDTrip(context: viewContext)
        newTrip.name = "Trip Name"
        newTrip.destination = "Trip destination"
        newTrip.startDate = .now
        newTrip.endDate = .now.addingTimeInterval(4 * 3600)
        
        let newBucketListItem = CDBucketListItem(context: viewContext)
        newBucketListItem.title = "A bucket list item title"
        newBucketListItem.details = "Details of my bucket list item"
        newBucketListItem.hasReservation = true
        newBucketListItem.isInPlan = true
        newBucketListItem.trip = newTrip
        
        let livingAccommodations = CDLivingAccommodation(context: viewContext)
        livingAccommodations.address = "A new address"
        livingAccommodations.placeName = "A place name"
        livingAccommodations.trip = newTrip
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    let container: NSPersistentContainer
    init(inMemory: Bool = false) {
        guard let modelURL = Bundle.main.url(forResource: "Trips", withExtension: "momd") else {
            fatalError("Unable to find Trips data model in the bundle.")
        }
        
        guard let coreDataModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Unable to create the Trips Core Data model.")
        }
        
        container = NSPersistentContainer(name: "Trips", managedObjectModel: coreDataModel)
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            guard let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupContainerID) else {
                fatalError("Shared file container could not be created.")
            }
            
            let url = appGroupContainer.appendingPathComponent("Trips.sqlite")
            if let description = container.persistentStoreDescriptions.first {
                description.url = url
                description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            }
        }
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

// Content from: Trips-Coexistence/Trips/AddTripView.swift
/*
Abstract:
A SwiftUI view that adds a new trip.
*/
import SwiftUI
import WidgetKit
struct AddTripView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.dismiss) private var dismiss
    @Environment(\.timeZone) private var timeZone
    @Environment(\.managedObjectContext) private var viewContext
    @State private var name = ""
    @State private var destination = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    var dateRange: ClosedRange<Date> {
        let start = Date.now
        let components = DateComponents(calendar: calendar, timeZone: timeZone, year: 1)
        let end = calendar.date(byAdding: components, to: start)!
        return start ... end
    }
    
    var body: some View {
        TripForm {
            Section(header: Text("Trip Title")) {
                TripGroupBox {
                    TextField("Enter title here…", text: $name)
                }
            }
            
            Section(header: Text("Trip Destination")) {
                TripGroupBox {
                    TextField("Enter destination here…", text: $destination)
                }
            }
            
            Section(header: Text("Trip Dates")) {
                TripGroupBox {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Start Date:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            DatePicker(selection: $startDate, in: dateRange,
                                       displayedComponents: .date) {
                                Label("Start Date", systemImage: "calendar")
                            }
                            .labelsHidden()
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("End Date:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            DatePicker(selection: $endDate, in: dateRange,
                                       displayedComponents: .date) {
                                Label("End Date", systemImage: "calendar")
                            }
                            .labelsHidden()
                        }
                    }
                }
            }
        }
        .frame(idealWidth: LayoutConstants.sheetIdealWidth,
               idealHeight: LayoutConstants.sheetIdealHeight)
        .navigationTitle("Add Trip")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Dismiss") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Done") {
                    addTrip()
                    WidgetCenter.shared.reloadTimelines(ofKind: "TripsWidget")
                    dismiss()
                }
                .disabled(name.isEmpty || destination.isEmpty)
            }
        }
    }
    
    private func addTrip() {
        withAnimation {
            let newTrip = CDTrip(context: viewContext)
            newTrip.name = name
            newTrip.destination = destination
            newTrip.startDate = startDate
            newTrip.endDate = endDate
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError)")
        }
    }
}
#Preview {
    AddTripView()
        .environment(\.managedObjectContext,
                      PersistenceController.preview.container.viewContext)
}

// Content from: Trips-Coexistence/Trips/TripDetailView.swift
/*
Abstract:
A SwiftUI view that shows the details of a trip.
*/
import SwiftUI
import CoreData
struct TripDetailView: View {
    var trip: CDTrip
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.startDate)])
    private var trips: FetchedResults<CDTrip>
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.title)])
    private var bucketList: FetchedResults<CDBucketListItem>
    
    var body: some View {
        List {
            #if os(macOS)
            tripInfoViewForMac()
            #else
            tripInfoViewForiOS()
            #endif
        }
        .navigationTitle(Text("Trip Details"))
    }
    
    @ViewBuilder
    private func tripInfoViewForMac() -> some View {
        Section {
            TripGroupBox {
                HStack {
                    VStack(alignment: .leading) {
                        Text(trip.displayDestination)
                        if case let (start?, end?) = (trip.startDate, trip.endDate) {
                            HStack {
                                Text(start, style: .date)
                                Image(systemName: "arrow.right")
                                Text(end, style: .date)
                            }
                        }
                    }
                    Spacer()
                }
            }
        } header: {
            HStack {
                Text(trip.displayName)
                    .font(.title)
                Spacer()
                NavigationLink {
                    UpdateTripView(trip: trip)
                } label: {
                    Label("Edit", systemImage: "chevron.right").labelStyle(.iconOnly)
                }
            }
        }
        Section {
            TripGroupBox {
                HStack {
                    VStack(alignment: .leading) {
                        if let livingAccommodation = trip.livingAccommodation {
                            Text(livingAccommodation.placeName ?? "No Place")
                            Text(livingAccommodation.address ?? "No Address")
                        } else {
                            Text("<No living accommodations>")
                        }
                    }
                    Spacer()
                }
            }
        } header: {
            HStack {
                Text("Living Accommodations").font(.headline)
                Spacer()
                NavigationLink {
                    EditlivingAccommodationView(trip: trip)
                } label: {
                    Label("Edit", systemImage: "chevron.right").labelStyle(.iconOnly)
                }
            }
        }
        Section {
        } header: {
            HStack {
                Text("Bucket List").font(.headline)
                Spacer()
                NavigationLink {
                    BucketListView(trip: trip)
                } label: {
                    Label("View", systemImage: "chevron.right").labelStyle(.iconOnly)
                }
            }
        }
    }
    @ViewBuilder
    private func tripInfoViewForiOS() -> some View {
        VStack(alignment: .leading) {
            Text(trip.displayName)
                .font(.title)
                .bold()
            Text(trip.displayDestination)
            if case let (start?, end?) = (trip.startDate, trip.endDate) {
                HStack {
                    Text(start, style: .date)
                    Image(systemName: "arrow.right")
                    Text(end, style: .date)
                }
            }
        }
        NavigationLink {
            UpdateTripView(trip: trip)
        } label: {
            Text("Change Trip Details")
        }
        Section {
            VStack(alignment: .leading) {
                if let livingAccommodation = trip.livingAccommodation {
                    Text(livingAccommodation.placeName ?? "No Place")
                    Text(livingAccommodation.address ?? "No Address")
                } else {
                    Text("<No Living Accommodations>")
                }
            }
            NavigationLink {
                EditlivingAccommodationView(trip: trip)
            } label: {
                Text("Change Living Accommodations")
            }
        } header: {
            Text("Living Accommodations")
        }
        Section {
            NavigationLink {
                BucketListView(trip: trip)
            } label: {
                Text("View Bucket List")
            }
        } header: {
            Text("Bucket List")
        }
    }
}
#Preview {
    TripDetailView(trip: .preview)
        .environment(\.managedObjectContext,
                      PersistenceController.preview.container.viewContext)
}

// Content from: Trips-Coexistence/Trips/BucketListItemView.swift
/*
Abstract:
A SwiftUI view that shows a bucket list item.
*/
import SwiftUI
struct BucketListItemView: View {
    var item: CDBucketListItem
    
    var body: some View {
        TripForm {
            Section {
                VStack(alignment: .leading) {
                    TripGroupBox {
                        HStack {
                            Text(item.displayDetails)
                            Spacer()
                        }
                    }
                    TripGroupBox {
                        HStack {
                            Text("Reservations made: ")
                            Spacer()
                            if item.hasReservation {
                                Text("YES")
                            } else {
                                Text("NO")
                            }
                        }
                        HStack {
                            Text("Already in plan: ")
                            Spacer()
                            if item.isInPlan {
                                Text("YES")
                            } else {
                                Text("NO")
                            }
                        }
                    }
                }
            } header: {
                Text("Bucket List Item Details")
            }
        }
        .navigationTitle(item.displayTitle)
    }
}
#Preview {
    BucketListItemView(item: .preview)
        .environment(\.managedObjectContext,
                      PersistenceController.preview.container.viewContext)
}

// Content from: Trips-Coexistence/Trips/SwiftUIHelper.swift
/*
Abstract:
Extensions that add convenience methods to SwiftUI.
*/
import SwiftUI
#if os(macOS)
typealias EditButton = EmptyView
typealias TripForm = List
typealias TripGroupBox = GroupBox
#else
typealias TripForm = Form
typealias TripGroupBox = Group
#endif
extension Color {
    static var tripGray: Color {
        #if os(iOS)
        return Color(.systemGray6)
        #else
        return Color.gray
        #endif
    }
}
extension ToolbarItemPlacement {
    #if os(macOS)
    static let navigationBarLeading = automatic
    static let navigationBarTrailing = automatic
    static let bottomBar = automatic
    #endif
}
/**
 Layout constants.
 */
struct LayoutConstants {
    static let sheetIdealWidth = 400.0
    static let sheetIdealHeight = 500.0
}

// Content from: Trips-Coexistence/Trips/TripListItem.swift
/*
Abstract:
A SwiftUI list item view that shows trip metadata.
*/
import SwiftUI
struct TripListItem: View {
    /**
     This view needs to update when the trip changes.
     */
    @ObservedObject var trip: CDTrip
    var body: some View {
        NavigationLink(value: trip) {
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(trip.color)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Text(String(trip.displayName.first!))
                            .font(.system(size: 48))
                            .foregroundStyle(.background)
                    }
                    .padding(.trailing)
                
                VStack(alignment: .leading) {
                    Text(trip.displayName)
                        .font(.headline)
                    Text(trip.displayDestination)
                        .font(.subheadline)
                    
                    if case let (start?, end?) = (trip.startDate, trip.endDate) {
                        Divider()
                        HStack {
                            Text(start, style: .date)
                            Image(systemName: "arrow.right")
                            Text(end, style: .date)
                        }
                        .font(.caption)
                    }
                }
            }
        }
    }
}
#Preview {
    TripListItem(trip: .preview)
        .environment(\.managedObjectContext,
                      PersistenceController.preview.container.viewContext)
}

// Content from: Trips-Coexistence/Trips/CDTrip+Extension.swift
/*
Abstract:
The model class of trips.
*/
import SwiftUI
extension CDTrip {
    var color: Color {
        let seed = name?.hashValue ?? 8
        var generator: RandomNumberGenerator = SeededRandomGenerator(seed: seed)
        return .random(using: &generator)
    }
    
    var displayName: String {
        guard let name, !name.isEmpty
        else { return "Untitled Trip" }
        return name
    }
    
    var displayDestination: String {
        guard let destination, !destination.isEmpty
        else { return "Untitled Destination" }
        return destination
    }
    
    static var preview: CDTrip {
        let result = PersistenceController.preview
        let viewContext = result.container.viewContext
        let trip = CDTrip(context: viewContext)
        trip.name = "Trip Name"
        trip.destination = "Trip destination"
        trip.startDate = .now
        trip.endDate = .now.addingTimeInterval(4 * 3600)
        return trip
    }
}
private struct SeededRandomGenerator: RandomNumberGenerator {
    init(seed: Int) {
        srand48(seed)
    }
    
    func next() -> UInt64 {
        UInt64(drand48() * Double(UInt64.max))
    }
}
private extension Color {
    static var random: Color {
        var generator: RandomNumberGenerator = SystemRandomNumberGenerator()
        return random(using: &generator)
    }
    
    static func random(using generator: inout RandomNumberGenerator) -> Color {
        let red = Double.random(in: 0..<1, using: &generator)
        let green = Double.random(in: 0..<1, using: &generator)
        let blue = Double.random(in: 0..<1, using: &generator)
        return Color(red: red, green: green, blue: blue)
    }
}

// Content from: Trips-Coexistence/Trips/AddBucketListItemView.swift
/*
Abstract:
A SwiftUI view that adds an item to the bucket list.
*/
import SwiftUI
struct AddBucketListItemView: View {
    var trip: CDTrip
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var title = ""
    @State private var details = ""
    @State private var hasReservations = false
    @State private var isInPlan = false
    
    var body: some View {
        NavigationStack {
            TripForm {
                Section {
                    TripGroupBox {
                        TextField("Enter title here…", text: $title)
                    }
                } header: {
                    Text("Bucket List Item Title")
                }
                
                Section {
                    VStack(alignment: .leading) {
                        TripGroupBox {
                            TextField("Enter details here…", text: $details)
                        }
                        TripGroupBox {
                            Toggle("Is this activity in the plan?", isOn: $isInPlan)
                            Toggle("Are reservations made?", isOn: $hasReservations)
                        }
                    }
                } header: {
                    Text("Bucket List Item Details")
                }
            }
            .navigationTitle("Add Bucket List Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        addItem()
                        dismiss()
                    }
                }
            }
        }
        .frame(idealWidth: LayoutConstants.sheetIdealWidth,
               idealHeight: LayoutConstants.sheetIdealHeight)
    }
    
    private func addItem() {
        withAnimation {
            let newItem = CDBucketListItem(context: viewContext)
            newItem.title = title
            newItem.details = details
            newItem.isInPlan = isInPlan
            newItem.hasReservation = hasReservations
            newItem.trip = trip
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError)")
        }
    }
}
#Preview {
    AddBucketListItemView(trip: .preview)
        .environment(\.managedObjectContext,
                      PersistenceController.preview.container.viewContext)
}

// Content from: Trips-Coexistence/Trips/EditLivingAccommodationsView.swift
/*
Abstract:
A SwiftUI view that edits living accommodations.
*/
import SwiftUI
struct EditlivingAccommodationView: View {
    var trip: CDTrip
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var placeName = ""
    @State private var address = ""
    
    var body: some View {
        TripForm {
            Section(header: Text("Name of Living Accommodation")) {
                TripGroupBox {
                    TextField(namePlaceholder, text: $placeName)
                }
            }
            
            Section(header: Text("Address of Living Accommodation")) {
                TripGroupBox {
                    TextField(addressPlaceholder, text: $address)
                }
            }
        }
        .background(Color.tripGray)
        .navigationTitle("Edit Living Accommodations")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Done") {
                    addLiving()
                    dismiss()
                }
                .disabled(placeName.isEmpty || address.isEmpty)
            }
        }
        .onAppear {
            placeName = trip.livingAccommodation?.placeName ?? ""
            address = trip.livingAccommodation?.address ?? ""
        }
    }
    
    var namePlaceholder: String {
        trip.livingAccommodation?.placeName ?? "Enter place name here…"
    }
    
    var addressPlaceholder: String {
        trip.livingAccommodation?.address ?? "Enter address here…"
    }
    
    private func addLiving() {
        withAnimation {
            if let livingAccommodation = trip.livingAccommodation {
                livingAccommodation.address = address
                livingAccommodation.placeName = placeName
            } else {
                let newLivingAccommodation = CDLivingAccommodation(
                    context: viewContext)
                newLivingAccommodation.address = address
                newLivingAccommodation.placeName = placeName
                newLivingAccommodation.trip = trip
            }
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError)")
        }
    }
}
#Preview {
    EditlivingAccommodationView(trip: .preview)
        .environment(\.managedObjectContext,
                      PersistenceController.preview.container.viewContext)
}

// Content from: Trips-Coexistence/Trips/UpdateTripView.swift
/*
Abstract:
A SwiftUI view that updates a trip.
*/
import SwiftUI
import WidgetKit
struct UpdateTripView: View {
    var trip: CDTrip
    @Environment(\.calendar) private var calendar
    @Environment(\.dismiss) private var dismiss
    @Environment(\.timeZone) private var timeZone
    @Environment(\.managedObjectContext) private var viewContext
    @State private var name: String = ""
    @State private var destination: String = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    var dateRange: ClosedRange<Date> {
        let start = Date.now
        let components = DateComponents(calendar: calendar,
                                        timeZone: timeZone, year: 1)
        let end = calendar.date(byAdding: components, to: start)!
        return start ... end
    }
    
    var body: some View {
        TripForm {
            Section(header: Text("Trip Title")) {
                TripGroupBox {
                    TextField(trip.name ?? "Enter title here…", text: $name)
                }
            }
            
            Section(header: Text("Trip Destination")) {
                TripGroupBox {
                    TextField(trip.destination ?? "Enter destination here…",
                              text: $destination)
                }
            }
            
            Section(header: Text("Trip Dates")) {
                TripGroupBox {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Start Date:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            DatePicker(selection: $startDate,
                                       in: dateRange, displayedComponents: .date) {
                                Label("Start Date", systemImage: "calendar")
                            }
                            .labelsHidden()
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("End Date:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            DatePicker(selection: $endDate,
                                       in: dateRange, displayedComponents: .date) {
                                Label("End Date", systemImage: "calendar")
                            }
                            .labelsHidden()
                        }
                    }
                }
            }
        }
        .onAppear {
            /**
             Populate the start and end date of the trip.
             */
            startDate = trip.startDate ?? Date()
            endDate = trip.endDate ?? Date()
        }
        .navigationTitle("Update Trip")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Done") {
                    updateTrip()
                    WidgetCenter.shared.reloadTimelines(ofKind: "TripsWidget")
                    dismiss()
                }
            }
        }
    }
    
    private func updateTrip() {
        withAnimation {
            if !name.isEmpty {
                trip.name = name
            }
            
            if !destination.isEmpty {
                trip.destination = destination
            }
            
            trip.startDate = startDate
            trip.endDate = endDate
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError)")
        }
    }
}
#Preview {
    UpdateTripView(trip: .preview)
        .environment(\.managedObjectContext,
                      PersistenceController.preview.container.viewContext)
}

// Content from: Trips-Coexistence/Trips/ContentView.swift
/*
Abstract:
A SwiftUI view that shows the main UI.
*/
import SwiftUI
import CoreData
import WidgetKit
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.startDate)])
    private var trips: FetchedResults<CDTrip>
    @State private var showAddTrip = false
    @State private var selection: CDTrip?
    @State private var path: [CDTrip] = []
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(trips) { trip in
                    TripListItem(trip: trip)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteTrip(trip)
                                WidgetCenter.shared.reloadTimelines(ofKind: "TripsWidget")
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .onDelete(perform: deleteTrips(at:))
            }
            .overlay {
                if trips.isEmpty {
                    ContentUnavailableView {
                         Label("No Trips", systemImage: "car.circle")
                    } description: {
                         Text("New trips you create will appear here.")
                    }
                }
            }
            .navigationTitle("Upcoming Trips")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                        .disabled(trips.isEmpty)
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Spacer()
                    Button {
                        showAddTrip = true
                    } label: {
                        Label("Add trip", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let selection = selection {
                NavigationStack {
                    TripDetailView(trip: selection)
                }
            }
        }
        .sheet(isPresented: $showAddTrip) {
            NavigationStack {
                AddTripView()
            }
            .presentationDetents([.medium, .large])
        }
    }
    private func deleteTrips(at offsets: IndexSet) {
        withAnimation {
            offsets.map { trips[$0] }.forEach(deleteTrip)
        }
    }
     
    private func deleteTrip(_ trip: CDTrip) {
        /**
         Unselect the item before deleting it.
         */
        if trip.objectID == selection?.objectID {
            selection = nil
        }
        viewContext.delete(trip)
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError)")
        }
    }
}
#Preview {
    ContentView()
        .environment(\.managedObjectContext,
                      PersistenceController.preview.container.viewContext)
}

// Content from: Trips-Coexistence/Trips/BucketListView.swift
/*
Abstract:
A SwiftUI view that shows the bucket list.
*/
import SwiftUI
import CoreData
struct BucketListView: View {
    var trip: CDTrip
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest private var bucketList: FetchedResults<CDBucketListItem>
    
    @State private var showAddItem = false
    @State private var searchText = ""
    
    init(trip: CDTrip) {
        self.trip = trip
        self._bucketList = FetchRequest<CDBucketListItem>(sortDescriptors: [SortDescriptor(\.title)],
                                                          predicate: NSPredicate(format: "trip.name = %@", trip.name ?? ""))
    }
    
    var body: some View {
        TripForm {
            ForEach(bucketList) { item in
                TripGroupBox {
                    NavigationLink {
                        BucketListItemView(item: item)
                    } label: {
                        HStack {
                            Text(item.title ?? "Untitled Bucket List Item")
                            Spacer()
                            BucketListItemToggle(item: item)
                            #if os(macOS)
                            Image(systemName: "chevron.right").font(Font.system(.footnote).weight(.semibold))
                            #endif
                        }
                    }
                }
            }
            .onDelete(perform: deleteItems(at:))
        }
        .searchable(text: $searchText)
        .onChange(of: searchText) { oldValue, newValue in
            bucketList.nsPredicate = newValue.isEmpty ? nil : searchPredicate
        }
        .navigationTitle("Bucket List")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
                    .disabled(bucketList.isEmpty)
            }
            ToolbarItemGroup(placement: .bottomBar) {
                Spacer()
                Button {
                    showAddItem.toggle()
                } label: {
                    Label("Add", systemImage: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showAddItem) {
            NavigationStack {
                AddBucketListItemView(trip: trip)
                    .presentationDetents([.medium, .large])
            }
        }
    }
    
    var searchPredicate: NSPredicate {
        let bucketListPredicate = NSPredicate(format: "ANY title CONTAINS[c] %@", searchText)
        let tripPredicate = NSPredicate(format: "trip.name = %@", trip.name ?? "")
        let compoundPredicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [bucketListPredicate, tripPredicate])
        return compoundPredicate
    }
    
    private func deleteItems(at offsets: IndexSet) {
        withAnimation {
            offsets.map { bucketList[$0] }.forEach(viewContext.delete)
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError)")
        }
    }
}
struct BucketListItemToggle: View {
    var item: CDBucketListItem
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isOn: Bool = false
    
    var body: some View {
        Toggle("Bucket list item is in plan", isOn: $isOn)
            .labelsHidden()
            .onAppear { isOn = item.isInPlan }
            .onChange(of: isOn) { oldValue, newValue in
                item.isInPlan = newValue
                saveContext()
            }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError)")
        }
    }
}
#Preview {
    BucketListView(trip: .preview)
        .environment(\.managedObjectContext,
                      PersistenceController.preview.container.viewContext)
}

// Content from: Trips-Coexistence/Trips/TripsApp.swift
/*
Abstract:
The SwiftUI app.
*/
import SwiftUI
@main
struct TripsApp: App {
    let persistenceController = PersistenceController.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext,
                              persistenceController.container.viewContext)
        }
    }
}

// Content from: Trips-SwiftData/Shared/PreviewSampleData.swift
/*
Abstract:
The preview sample data actor which provides an in-memory model container.
*/
import SwiftData
import SwiftUI
/**
 Preview sample data.
 */
struct SampleData: PreviewModifier {
    static func makeSharedContext() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Trip.self,
            configurations: config
        )
        SampleData.createSampleData(into: container.mainContext)
        return container
    }
    
    func body(content: Content, context: ModelContainer) -> some View {
          content.modelContainer(context)
    }
    
    static func createSampleData(into modelContext: ModelContext) {
        Task { @MainActor in
            let sampleDataTrips: [Trip] = Trip.previewTrips
            let sampleDataLA: [LivingAccommodation] = LivingAccommodation.preview
            let sampleDataBLT: [BucketListItem] = BucketListItem.previewBLTs
            let sampleData: [any PersistentModel] = sampleDataTrips + sampleDataLA + sampleDataBLT
            sampleData.forEach {
                modelContext.insert($0)
            }
            
            if let firstTrip = sampleDataTrips.first,
               let firstLivingAccommodation = sampleDataLA.first,
               let firstBucketListItem = sampleDataBLT.first {
                firstTrip.livingAccommodation = firstLivingAccommodation
                firstTrip.bucketList.append(firstBucketListItem)
            }
            if let lastTrip = sampleDataTrips.last,
               let lastBucketListItem = sampleDataBLT.last {
                lastTrip.bucketList.append(lastBucketListItem)
            }
            try? modelContext.save()
        }
    }
}
@available(iOS 18.0, *)
extension PreviewTrait where T == Preview.ViewTraits {
    @MainActor static var sampleData: Self = .modifier(SampleData())
}

// Content from: Trips-SwiftData/Shared/DataModel.swift
/*
Abstract:
An actor that provides a SwiftData model container for the whole app and widget,
 and implements actor-isolated tasks like SwiftData history processing.
*/
import SwiftUI
import SwiftData
actor DataModel {
    struct TransactionAuthor {
        static let widget = "widget"
    }
    static let shared = DataModel()
    private init() {}
    
    nonisolated lazy var modelContainer: ModelContainer = {
        let modelContainer: ModelContainer
        do {
            modelContainer = try ModelContainer(for: Trip.self)
        } catch {
            fatalError("Failed to create the model container: \(error)")
        }
        return modelContainer
    }()
}

// Content from: Trips-SwiftData/Shared/Trip.swift
/*
Abstract:
The model class of trips.
*/
import Foundation
import SwiftUI
import SwiftData
@Model class Trip {
    #Index<Trip>([\.name], [\.startDate], [\.endDate], [\.name, \.startDate, \.endDate])
    #Unique<Trip>([\.name, \.startDate, \.endDate])
    
    @Attribute(.preserveValueOnDeletion)
    var name: String
    var destination: String
    
    @Attribute(.preserveValueOnDeletion)
    var startDate: Date
    
    @Attribute(.preserveValueOnDeletion)
    var endDate: Date
    @Relationship(deleteRule: .cascade, inverse: \BucketListItem.trip)
    var bucketList: [BucketListItem] = [BucketListItem]()
    
    @Relationship(deleteRule: .cascade, inverse: \LivingAccommodation.trip)
    var livingAccommodation: LivingAccommodation?
    
    init(name: String, destination: String, startDate: Date = .now, endDate: Date = .distantFuture) {
        self.name = name
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
    }
}
 
extension Trip {
    var color: Color {
        let seed = name.hashValue
        var generator: RandomNumberGenerator = SeededRandomGenerator(seed: seed)
        return .random(using: &generator)
    }
    
    var displayName: String {
        name.isEmpty ? "Untitled Trip" : name
    }
    
    var displayDestination: String {
        destination.isEmpty ? "Untitled Destination" : destination
    }
    
    static var preview: Trip {
        Trip(name: "Trip Name", destination: "Trip destination",
             startDate: .now, endDate: .now.addingTimeInterval(4 * 3600))
    }
    
    private static func date(calendar: Calendar = Calendar(identifier: .gregorian),
                             timeZone: TimeZone = TimeZone.current,
                             year: Int, month: Int, day: Int) -> Date {
        let dateComponent = DateComponents(calendar: calendar, timeZone: timeZone,
                                           year: year, month: month, day: day)
        let date = Calendar.current.date(from: dateComponent)
        return date ?? Date.now
    }
    
    static var previewTrips: [Trip] {
        [
            Trip(name: "Camping!", destination: "Yosemite",
                 startDate: date(year: 2024, month: 6, day: 27),
                 endDate: date(year: 2024, month: 7, day: 1)),
            Trip(name: "Bridalveil Falls", destination: "Yosemite",
                 startDate: date(year: 2024, month: 6, day: 28),
                 endDate: date(year: 2024, month: 6, day: 28))
        ]
    }
}
private struct SeededRandomGenerator: RandomNumberGenerator {
    init(seed: Int) {
        srand48(seed)
    }
    
    func next() -> UInt64 {
        UInt64(drand48() * Double(UInt64.max))
    }
}
private extension Color {
    static var random: Color {
        var generator: RandomNumberGenerator = SystemRandomNumberGenerator()
        return random(using: &generator)
    }
    
    static func random(using generator: inout RandomNumberGenerator) -> Color {
        let red = Double.random(in: 0..<1, using: &generator)
        let green = Double.random(in: 0..<1, using: &generator)
        let blue = Double.random(in: 0..<1, using: &generator)
        return Color(red: red, green: green, blue: blue)
    }
}

// Content from: Trips-SwiftData/Shared/LivingAccommodation.swift
/*
Abstract:
The model class of a living accommodation.
*/
import Foundation
import SwiftData
@Model class LivingAccommodation {
    var address: String
    var placeName: String
    var isConfirmed: Bool = false
    var trip: Trip?
    init(address: String, placeName: String, isConfirmed: Bool) {
        self.address = address
        self.placeName = placeName
        self.isConfirmed = isConfirmed
    }
}
extension LivingAccommodation {
    var displayAddress: String {
        address.isEmpty ? "No Address" : address
    }
    var displayPlaceName: String {
        placeName.isEmpty ? "No Place" : placeName
    }
    
    static var preview: [LivingAccommodation] {
        [.init(address: "Yosemite National Park, CA 95389", placeName: "Yosemite", isConfirmed: true)]
    }
}

// Content from: Trips-SwiftData/Shared/BucketListItem.swift
/*
Abstract:
The model class of bucket list items.
*/
import Foundation
import SwiftData
@Model class BucketListItem {
    var title: String
    var details: String
    var hasReservation: Bool
    var isInPlan: Bool
    var trip: Trip?
    
    init(title: String, details: String, hasReservation: Bool, isInPlan: Bool) {
        self.title = title
        self.details = details
        self.hasReservation = hasReservation
        self.isInPlan = isInPlan
    }
}
extension BucketListItem {
    static var preview: BucketListItem {
        let item = BucketListItem(
            title: "A bucket list item title",
            details: "Details of my bucket list item",
            hasReservation: true, isInPlan: true)
        item.trip = .preview
        return item
    }
    
    static var previewBLTs: [BucketListItem] {
        [
            BucketListItem(
            title: "See Half Dome",
            details: "try to climb Half Dome",
            hasReservation: true, isInPlan: false),
            BucketListItem(
            title: "Picture at the falls",
            details: "get a lot of them!",
            hasReservation: true, isInPlan: false)
        ]
    }
}

// Content from: Trips-SwiftData/Shared/DataModel+UnreadTrips.swift
/*
Abstract:
An exention of DataModel that provides supports for unread trips.
*/
import SwiftUI
import SwiftData
extension DataModel {
    struct UserDefaultsKey {
        static let unreadTripIdentifiers = "unreadTripIdentifiers"
        static let historyToken = "historyToken"
    }
    /**
     Getter and setter of the unread trip identifiers in the standard `UserDefaults`. This makes the identifiers avaiable for the next launch session.
     DataModel is isolated, and `setUnreadTripIdentifiersInUserDefaults` provides a way to set the value using `await`.
     */
    var unreadTripIdentifiersInUserDefaults: [PersistentIdentifier] {
        guard let data = UserDefaults.standard.data(forKey: UserDefaultsKey.unreadTripIdentifiers) else {
            return []
        }
        let tripIdentifers = try? JSONDecoder().decode([PersistentIdentifier].self, from: data)
        return tripIdentifers ?? []
    }
    
    func setUnreadTripIdentifiersInUserDefaults(_ newValue: [PersistentIdentifier]) {
        let data = try? JSONEncoder().encode(newValue)
        UserDefaults.standard.set(data, forKey: UserDefaultsKey.unreadTripIdentifiers)
    }
    
    /**
     Find the unread trip identifiers by parsing the history.
     */
    func findUnreadTripIdentifiers() -> [PersistentIdentifier] {
        let unreadTrips = findUnreadTrips()
        return Array(unreadTrips).map { $0.persistentModelID }
    }
    
    private func findUnreadTrips() -> Set<Trip> {
        let tokenData = UserDefaults.standard.data(forKey: UserDefaultsKey.historyToken)
        
        var historyToken: DefaultHistoryToken? = nil
        if let data = tokenData {
            historyToken = try? JSONDecoder().decode(DefaultHistoryToken.self, from: data)
        }
        let transactions = findTransactions(after: historyToken, author: TransactionAuthor.widget)
        let (unreadTrips, newToken) = findTrips(in: transactions)
        
        if let token = newToken {
            let newTokenData = try? JSONEncoder().encode(token)
            UserDefaults.standard.set(newTokenData, forKey: UserDefaultsKey.historyToken)
        }
        return unreadTrips
    }
    
    private func findTransactions(after historyToken: DefaultHistoryToken?, author: String) -> [DefaultHistoryTransaction] {
        var historyDescriptor = HistoryDescriptor<DefaultHistoryTransaction>()
        if let token = historyToken {
            historyDescriptor.predicate = #Predicate { transaction in
                (transaction.token > token) && (transaction.author == author)
            }
        }
        var transactions: [DefaultHistoryTransaction] = []
        let taskContext = ModelContext(modelContainer)
        do {
            transactions = try taskContext.fetchHistory(historyDescriptor)
        } catch let error {
            print(error)
        }
        return transactions
    }
    
    private func findTrips(in transactions: [DefaultHistoryTransaction]) -> (Set<Trip>, DefaultHistoryToken?) {
        let taskContext = ModelContext(modelContainer)
        var resultTrips: Set<Trip> = []
        
        for transaction in transactions {
            for change in transaction.changes where isLivingAccommodationChange(change: change) {
                /**
                 Fetch the trip using the model ID of the changed living accommodation.
                 */
                let modelID = change.changedPersistentIdentifier
                let fetchDescriptor = FetchDescriptor<Trip>(predicate: #Predicate {
                    $0.livingAccommodation?.persistentModelID == modelID
                })
                if let matchedTrip = try? taskContext.fetch(fetchDescriptor).first {
                    switch change {
                    case .insert:
                        resultTrips.insert(matchedTrip)
                    case .update:
                        resultTrips.update(with: matchedTrip)
                    case .delete:
                        resultTrips.remove(matchedTrip)
                    default:
                        break
                    }
                }
            }
        }
        return (resultTrips, transactions.last?.token)
    }
    
    private func isLivingAccommodationChange(change: HistoryChange) -> Bool {
        switch change {
        case .insert(let historyInsert):
            if historyInsert is any HistoryInsert<LivingAccommodation> {
                return true
            }
        case .update(let historyUpdate):
            if historyUpdate is any HistoryUpdate<LivingAccommodation> {
                return true
            }
        case .delete(let historyDelete):
            if historyDelete is any HistoryDelete<LivingAccommodation> {
                return true
            }
        default:
            break
        }
        return false
    }
}

// Content from: Trips-SwiftData/TripsWidget/AccommodationIntent.swift
/*
Abstract:
The app intent for confirming trip accommodations from the widget.
*/
import AppIntents
import SwiftData
struct AccommodationIntent: AppIntent {
    static var title: LocalizedStringResource {
        return "Trip accommodation"
    }
    static var description: IntentDescription {
        return IntentDescription("Confirm trip accommodation.")
    }
    
    @Parameter(title: "Trip name")
    var tripName: String
    
    @Parameter(title: "Trip start date")
    var startDate: Date
    @Parameter(title: "Trip end date")
    var endDate: Date
    init(tripName: String, startDate: Date, endDate: Date) {
        self.tripName = tripName
        self.startDate = startDate
        self.endDate = endDate
    }
    
    init() {
    }
    func perform() async throws -> some IntentResult {
        let modelContext = ModelContext(DataModel.shared.modelContainer)
        modelContext.author = DataModel.TransactionAuthor.widget //"widget"
        
        let fetchDescripor = FetchDescriptor(predicate: #Predicate<Trip> {
            ($0.name == tripName) && ($0.startDate == startDate) && ($0.endDate == endDate)
        })
        guard let trip = try? modelContext.fetch(fetchDescripor).first,
              let livingAccomodation = trip.livingAccommodation else {
            return .result()
        }
        livingAccomodation.isConfirmed = !livingAccomodation.isConfirmed
        do {
            try modelContext.save()
        } catch {
            print("Failed to save model context: \(error)")
        }
        return .result()
    }
}

// Content from: Trips-SwiftData/TripsWidget/TripsWidget.swift
/*
Abstract:
The types that provide timeline entries for the widget.
*/
import WidgetKit
import SwiftUI
import SwiftData
struct TripsWidget: Widget {
    let kind: String = "TripsWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TripsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Future Trips")
        .description("See your upcoming trips.")
    }
}
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        return SimpleEntry.placeholderEntry
    }
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry.placeholderEntry)
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        var fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Trip.startDate, order: .forward)])
        let now = Date.now
        fetchDescriptor.predicate = #Predicate { $0.endDate >= now }
        let modelContext = ModelContext(DataModel.shared.modelContainer)
        
        if let upcomingTrips = try? modelContext.fetch(fetchDescriptor) {
            if let trip = upcomingTrips.first {
                var accommodationStatus: AccommodationStatus = .noAccommodation
                if let livingAccommodation = trip.livingAccommodation {
                    accommodationStatus = livingAccommodation.isConfirmed ? .confirmed : .notConfirmed
                }
                let newEntry = SimpleEntry(date: .now,
                                           startDate: trip.startDate,
                                           endDate: trip.endDate,
                                           name: trip.name,
                                           destination: trip.destination,
                                           accommodationStatus: accommodationStatus)
                let timeline = Timeline(entries: [newEntry], policy: .after(newEntry.endDate))
                completion(timeline)
                return
            }
        }
        /**
         Return "No Trips" entry with `.never` policy when there is no upcoming trip.
         The main app triggers a widget update when adding a new trip.
         */
        let newEntry = SimpleEntry(date: .now,
                                   startDate: .now,
                                   endDate: .now,
                                   name: "No Trips",
                                   destination: "",
                                   accommodationStatus: .noAccommodation)
        let timeline = Timeline(entries: [newEntry], policy: .never)
        completion(timeline)
    }
}
enum AccommodationStatus {
    case noAccommodation, notConfirmed, confirmed
}
struct SimpleEntry: TimelineEntry {
    let date: Date
    
    let startDate: Date
    let endDate: Date
    let name: String
    let destination: String
    let accommodationStatus: AccommodationStatus
    
    static var placeholderEntry: SimpleEntry {
        let now = Date()
        let sevenDaysAfter = Calendar.current.date(byAdding: .day, value: 7, to: now)
        return SimpleEntry(date: now, startDate: now, endDate: sevenDaysAfter ?? Date(),
                           name: "Honeymoon", destination: "Hawaii", accommodationStatus: .confirmed)
    }
}
struct TripsWidgetEntryView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "car.circle")
                        .imageScale(.large)
                    Text(entry.name)
                        .font(.system(.title2).weight(.semibold))
                        .minimumScaleFactor(0.5)
                    Spacer()
                }
                .foregroundColor(.green)
                
                Divider()
                if !entry.destination.isEmpty {
                    Group {
                        Text(entry.destination)
                            .font(.system(.title3).weight(.semibold))
                        Text(entry.startDate, style: .date)
                        Text(entry.endDate, style: .date)
                        Spacer()
                        
                        if entry.accommodationStatus != .noAccommodation {
                            Button(intent: AccommodationIntent(tripName: entry.name, startDate: entry.startDate, endDate: entry.endDate)) {
                                HStack {
                                    Text("Accommodation")
                                    Image(systemName: entry.accommodationStatus == .confirmed ? "checkmark.circle" : "circle")
                                }
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(entry.accommodationStatus == .confirmed ? .green :  .red)
                        } else {
                            Text("No accommondation.")
                        }
                    }
                    .foregroundColor(.gray)
                    .minimumScaleFactor(0.5)
                }
            }
        }
        .containerBackground(for: .widget) {
            Color.white
        }
    }
}
#Preview(as: .systemSmall) {
    TripsWidget()
} timeline: {
    SimpleEntry.placeholderEntry
}

// Content from: Trips-SwiftData/TripsWidget/TripsWidgetBundle.swift
/*
Abstract:
The widget bundle.
*/
import WidgetKit
import SwiftUI
@main
struct TripsWidgetBundle: WidgetBundle {
    var body: some Widget {
        TripsWidget()
    }
}

// Content from: Trips-SwiftData/Trips/AddTripView.swift
/*
Abstract:
A SwiftUI view that adds a new trip.
*/
import SwiftUI
import WidgetKit
struct AddTripView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.calendar) private var calendar
    @Environment(\.dismiss) private var dismiss
    @Environment(\.timeZone) private var timeZone
    @State private var name: String = ""
    @State private var destination: String = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    var dateRange: ClosedRange<Date> {
        let start = Date.now
        let components = DateComponents(calendar: calendar, timeZone: timeZone, year: 1)
        let end = calendar.date(byAdding: components, to: start)!
        return start ... end
    }
    
    var body: some View {
        TripForm {
            Section(header: Text("Trip Title")) {
                TripGroupBox {
                    TextField("Enter title here…", text: $name)
                }
            }
            
            Section(header: Text("Trip Destination")) {
                TripGroupBox {
                    TextField("Enter destination here…", text: $destination)
                }
            }
            
            Section(header: Text("Trip Dates")) {
                TripGroupBox {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Start Date:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            DatePicker(selection: $startDate, in: dateRange,
                                       displayedComponents: .date) {
                                Label("Start Date", systemImage: "calendar")
                            }
                            .labelsHidden()
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("End Date:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            DatePicker(selection: $endDate, in: dateRange,
                                       displayedComponents: .date) {
                                Label("End Date", systemImage: "calendar")
                            }
                            .labelsHidden()
                        }
                    }
                }
            }
        }
        .frame(idealWidth: LayoutConstants.sheetIdealWidth,
               idealHeight: LayoutConstants.sheetIdealHeight)
        .navigationTitle("Add Trip")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Dismiss") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Done") {
                    addTrip()
                    WidgetCenter.shared.reloadTimelines(ofKind: "TripsWidget")
                    dismiss()
                }
                .disabled(name.isEmpty || destination.isEmpty)
            }
        }
    }
    private func addTrip() {
        withAnimation {
            let newTrip = Trip(name: name, destination: destination, startDate: startDate, endDate: endDate)
            modelContext.insert(newTrip)
        }
    }
}
#Preview(traits: .sampleData) {
    AddTripView()
}

// Content from: Trips-SwiftData/Trips/TripDetailView.swift
/*
Abstract:
A SwiftUI view that shows the details of a trip.
*/
import SwiftUI
import SwiftData
struct TripDetailView: View {
    var trip: Trip
    
    var body: some View {
        List {
            #if os(macOS)
            tripInfoViewForMac()
            #else
            tripInfoViewForiOS()
            #endif
        }
        .navigationTitle(Text("Trip Details"))
    }
    
    @ViewBuilder
    private func tripInfoViewForMac() -> some View {
        Section {
            TripGroupBox {
                HStack {
                    VStack(alignment: .leading) {
                        Text(trip.displayDestination)
                        if case let (start?, end?) = (trip.startDate, trip.endDate) {
                            HStack {
                                Text(start, style: .date)
                                Image(systemName: "arrow.right")
                                Text(end, style: .date)
                            }
                        }
                    }
                    Spacer()
                }
            }
        } header: {
            HStack {
                Text(trip.displayName)
                    .font(.title)
                Spacer()
                NavigationLink {
                    UpdateTripView(trip: trip)
                } label: {
                    Label("Edit", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                }
            }
        }
        Section {
            TripGroupBox {
                HStack {
                    VStack(alignment: .leading) {
                        livingAccommodationInfoView()
                    }
                    Spacer()
                }
            }
        } header: {
            HStack {
                Text("Living Accommodations").font(.headline)
                Spacer()
                NavigationLink {
                    EditLivingAccommodationsView(trip: trip)
                } label: {
                    Label("Edit", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                }
            }
        }
        Section {
        } header: {
            HStack {
                Text("Bucket List").font(.headline)
                Spacer()
                NavigationLink {
                    BucketListView(trip: trip)
                } label: {
                    Label("View", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                }
            }
        }
    }
    @ViewBuilder
    private func tripInfoViewForiOS() -> some View {
        VStack(alignment: .leading) {
            Text(trip.displayName)
                .font(.title)
                .bold()
            Text(trip.displayDestination)
            if case let (start?, end?) = (trip.startDate, trip.endDate) {
                HStack {
                    Text(start, style: .date)
                    Image(systemName: "arrow.right")
                    Text(end, style: .date)
                }
            }
        }
        NavigationLink {
            UpdateTripView(trip: trip)
        } label: {
            Text("Change Trip Details")
        }
        Section {
            VStack(alignment: .leading) {
                livingAccommodationInfoView()
            }
            NavigationLink {
                EditLivingAccommodationsView(trip: trip)
            } label: {
                Text("Change Living Accommodations")
            }
        } header: {
            Text("Living Accommodations")
        }
        Section {
            NavigationLink {
                BucketListView(trip: trip)
            } label: {
                Text("View Bucket List")
            }
        } header: {
            Text("Bucket List")
        }
    }
    
    @ViewBuilder
    private func livingAccommodationInfoView() -> some View {
        if let livingAccommodation = trip.livingAccommodation {
            Text(livingAccommodation.displayPlaceName)
            Text(livingAccommodation.displayAddress)
            Divider()
            HStack {
                Text("Confirmation")
                Spacer()
                Image(systemName: livingAccommodation.isConfirmed ? "checkmark.circle" : "circle")
            }
        } else {
            Text("<No Living Accommodations>")
        }
    }
}
#Preview(traits: .sampleData) {
    @Previewable @Query var trips: [Trip]
    TripDetailView(trip: trips.first!)
}

// Content from: Trips-SwiftData/Trips/BucketListItemView.swift
/*
Abstract:
A SwiftUI view that shows a bucket list item.
*/
import SwiftUI
struct BucketListItemView: View {
    var item: BucketListItem
    
    var body: some View {
        TripForm {
            Section {
                VStack(alignment: .leading) {
                    TripGroupBox {
                        HStack {
                            Text(item.details.isEmpty ? "<No details>" : item.details)
                            Spacer()
                        }
                    }
                    TripGroupBox {
                        HStack {
                            Text("Reservations made: ")
                            Spacer()
                            if item.hasReservation {
                                Text("YES")
                            } else {
                                Text("NO")
                            }
                        }
                        HStack {
                            Text("Already in plan: ")
                            Spacer()
                            if item.isInPlan {
                                Text("YES")
                            } else {
                                Text("NO")
                            }
                        }
                    }
                }
            } header: {
                Text("Bucket List Item Details")
            }
        }
        .navigationTitle(item.title)
    }
}
#Preview(traits: .sampleData) {
    BucketListItemView(item: .preview)
}

// Content from: Trips-SwiftData/Trips/SwiftUIHelper.swift
/*
Abstract:
Extensions that add convenience methods to SwiftUI.
*/
import SwiftUI
#if os(macOS)
typealias EditButton = EmptyView
typealias TripForm = List
typealias TripGroupBox = GroupBox
#else
typealias TripForm = Form
typealias TripGroupBox = Group
#endif
extension Color {
    static var tripGray: Color {
        #if os(iOS)
        return Color(.systemGray6)
        #else
        return Color.gray
        #endif
    }
}
@MainActor
extension ToolbarItemPlacement {
    #if os(macOS)
    static let topBarLeading = automatic
    static let topBarTrailing = automatic
    static let bottomBar = automatic
    #endif
}
/**
 Layout constants.
 */
struct LayoutConstants {
    static let sheetIdealWidth = 400.0
    static let sheetIdealHeight = 500.0
}

// Content from: Trips-SwiftData/Trips/TripListItem.swift
/*
Abstract:
A SwiftUI list item view that shows trip metadata.
*/
import SwiftUI
import SwiftData
struct TripListItem: View {
    var trip: Trip
    let isUnread: Bool
    
    var body: some View {
        NavigationLink(value: trip) {
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(trip.color)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Text(String(trip.displayName.first!))
                            .font(.system(size: 48))
                            .foregroundStyle(.background)
                    }
                
                Circle()
                    .fill(isUnread ? .blue : .clear)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading) {
                    Text(trip.displayName)
                        .font(.headline)
                    Text(trip.displayDestination)
                        .font(.subheadline)
                    
                    if case let (start?, end?) = (trip.startDate, trip.endDate) {
                        Divider()
                        HStack {
                            Text(start, style: .date)
                            Image(systemName: "arrow.right")
                            Text(end, style: .date)
                        }
                        .font(.caption)
                    }
                }
            }
        }
    }
}
#Preview(traits: .sampleData) {
    @Previewable @Query var trips: [Trip]
    List {
        TripListItem(trip: trips.first!, isUnread: true)
    }
}

// Content from: Trips-SwiftData/Trips/AddBucketListItemView.swift
/*
Abstract:
A SwiftUI view that adds an item to the bucket list.
*/
import SwiftUI
import SwiftData
struct AddBucketListItemView: View {
    @Environment(\.modelContext) private var modelContext
    var trip: Trip
    
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var details: String = ""
    @State private var hasReservations = false
    @State private var isInPlan = false
    
    var body: some View {
        NavigationStack {
            TripForm {
                Section {
                    TripGroupBox {
                        TextField("Enter title here…", text: $title)
                    }
                } header: {
                    Text("Bucket List Item Title")
                }
                
                Section {
                    VStack(alignment: .leading) {
                        TripGroupBox {
                            TextField("Enter details here…", text: $details)
                        }
                        TripGroupBox {
                            Toggle("Is this activity in the plan?", isOn: $isInPlan)
                            Toggle("Are reservations made?", isOn: $hasReservations)
                        }
                    }
                } header: {
                    Text("Bucket List Item Details")
                }
            }
            .navigationTitle("Add Bucket List Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        addItem()
                        dismiss()
                    }
                }
            }
        }
        .frame(idealWidth: LayoutConstants.sheetIdealWidth,
               idealHeight: LayoutConstants.sheetIdealHeight)
    }
    private func addItem() {
        withAnimation {
            let newItem = BucketListItem(title: title, details: details, hasReservation: hasReservations, isInPlan: isInPlan)
            modelContext.insert(newItem)
            newItem.trip = trip
            trip.bucketList.append(newItem)
        }
    }
}
#Preview(traits: .sampleData) {
    @Previewable @Query var trips: [Trip]
    AddBucketListItemView(trip: trips.first!)
}

// Content from: Trips-SwiftData/Trips/EditLivingAccommodationsView.swift
/*
Abstract:
A SwiftUI view that edits living accommodations.
*/
import SwiftUI
import WidgetKit
import SwiftData
struct EditLivingAccommodationsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var placeName = ""
    @State private var address = ""
    @State private var isConfirmed = false
    
    var trip: Trip
    
    var body: some View {
        TripForm {
            Section(header: Text("Name of Living Accommodation")) {
                TripGroupBox {
                    TextField(namePlaceholder, text: $placeName)
                }
            }
            
            Section(header: Text("Address of Living Accommodation")) {
                TripGroupBox {
                    TextField(addressPlaceholder, text: $address)
                }
            }
            
            Section(header: Text("Confirmation")) {
                TripGroupBox {
                    Toggle(isOn: $isConfirmed) {
                        Text("Get confirmed")
                    }
                }
            }
        }
        .background(Color.tripGray)
        .navigationTitle("Edit Living Accommodations")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Done") {
                    addLiving()
                    dismiss()
                }
                .disabled(placeName.isEmpty || address.isEmpty)
            }
        }
        .onAppear {
            placeName = trip.livingAccommodation?.placeName ?? ""
            address = trip.livingAccommodation?.address ?? ""
            isConfirmed = trip.livingAccommodation?.isConfirmed ?? false
        }
    }
    var namePlaceholder: String {
        trip.livingAccommodation?.placeName ?? "Enter place name here…"
    }
    
    var addressPlaceholder: String {
        trip.livingAccommodation?.address ?? "Enter address here…"
    }
    
    private func addLiving() {
        withAnimation {
            if let livingAccommodation = trip.livingAccommodation {
                livingAccommodation.address = address
                livingAccommodation.placeName = placeName
                livingAccommodation.isConfirmed = isConfirmed
            } else {
                let newLivingAccommodation = LivingAccommodation(address: address,
                                                                 placeName: placeName,
                                                                 isConfirmed: isConfirmed)
                newLivingAccommodation.trip = trip
            }
            /**
             Save the context immediately to make sure that the widget gets the latest data.
             */
            do {
                try modelContext.save()
            } catch {
                print("Failed to save model context: \(error)")
            }
            WidgetCenter.shared.reloadTimelines(ofKind: "TripsWidget")
        }
    }
}
#Preview(traits: .sampleData) {
    @Previewable @Query var trips: [Trip]
    EditLivingAccommodationsView(trip: trips.first!)
}

// Content from: Trips-SwiftData/Trips/UpdateTripView.swift
/*
Abstract:
A SwiftUI view that updates a trip.
*/
import SwiftUI
import SwiftData
import WidgetKit
struct UpdateTripView: View {
    var trip: Trip
    
    @Environment(\.calendar) private var calendar
    @Environment(\.dismiss) private var dismiss
    @Environment(\.timeZone) private var timeZone
    @State private var name: String = ""
    @State private var destination: String = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    var dateRange: ClosedRange<Date> {
        let start = Date.now
        let components = DateComponents(calendar: calendar,
                                        timeZone: timeZone, year: 1)
        let end = calendar.date(byAdding: components, to: start)!
        return start ... end
    }
    
    var body: some View {
        TripForm {
            Section(header: Text("Trip Title")) {
                TripGroupBox {
                    TextField(trip.name.isEmpty ? "Enter title here…" : trip.name,
                              text: $name)
                }
            }
            
            Section(header: Text("Trip Destination")) {
                TripGroupBox {
                    TextField(trip.destination.isEmpty ? "Enter destination here…" : trip.destination,
                              text: $destination)
                }
            }
            
            Section(header: Text("Trip Dates")) {
                TripGroupBox {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Start Date:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            DatePicker(selection: $startDate,
                                       in: dateRange, displayedComponents: .date) {
                                Label("Start Date", systemImage: "calendar")
                            }
                            .labelsHidden()
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("End Date:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            DatePicker(selection: $endDate,
                                       in: dateRange, displayedComponents: .date) {
                                Label("End Date", systemImage: "calendar")
                            }
                            .labelsHidden()
                        }
                    }
                }
            }
        }
        .onAppear {
            /**
             Populate the start and end dates of the trip.
             */
            startDate = trip.startDate
            endDate = trip.endDate
        }
        .navigationTitle("Update Trip")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Done") {
                    updateTrip()
                    WidgetCenter.shared.reloadTimelines(ofKind: "TripsWidget")
                    dismiss()
                }
            }
        }
    }
    private func updateTrip() {
        if !name.isEmpty {
            trip.name = name
        }
        
        if !destination.isEmpty {
            trip.destination = destination
        }
        
        trip.startDate = startDate
        trip.endDate = endDate
    }
}
#Preview(traits: .sampleData) {
    @Previewable @Query var trips: [Trip]
    UpdateTripView(trip: trips.first!)
}

// Content from: Trips-SwiftData/Trips/TripListView.swift
/*
Abstract:
A SwiftUI view that shows the trip list.
*/
import SwiftUI
import SwiftData
import WidgetKit
struct TripListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.startDate, order: .forward)
    var trips: [Trip]
    @Binding var selection: Trip?
    @Binding var tripCount: Int
    @Binding var unreadTripIdentifiers: [PersistentIdentifier]
    init(selection: Binding<Trip?>, tripCount: Binding<Int>,
         unreadTripIdentifiers: Binding<[PersistentIdentifier]>,
         searchText: String) {
        _selection = selection
        _tripCount = tripCount
        _unreadTripIdentifiers = unreadTripIdentifiers
        let predicate = #Predicate<Trip> {
            searchText.isEmpty ? true : $0.name.contains(searchText)
        }
        _trips = Query(filter: predicate, sort: \Trip.startDate)
    }
    var body: some View {
        List(selection: $selection) {
            ForEach(trips) { trip in
                TripListItem(trip: trip, isUnread: unreadTripIdentifiers.contains(trip.persistentModelID))
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteTrip(trip)
                            WidgetCenter.shared.reloadTimelines(ofKind: "TripsWidget")
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
            .onDelete(perform: deleteTrips(at:))
        }
        .overlay {
            if trips.isEmpty {
                ContentUnavailableView {
                     Label("No Trips", systemImage: "car.circle")
                } description: {
                     Text("New trips you create will appear here.")
                }
            }
        }
        .navigationTitle("Upcoming Trips")
        .onChange(of: trips) {
            tripCount = trips.count
        }
        .onAppear {
            tripCount = trips.count
        }
    }
}
extension TripListView {
    private func deleteTrips(at offsets: IndexSet) {
        withAnimation {
            do {
                try offsets.map { trips[$0] }.forEach(deleteTrip)
            } catch let error {
                print("Failed to delete trips: \(error)")
            }
        }
    }
    
    private func deleteTrip(_ trip: Trip) {
        /**
         Unselect the item before deleting it.
         */
        if trip.persistentModelID == selection?.persistentModelID {
            selection = nil
        }
        modelContext.delete(trip)
    }
}

// Content from: Trips-SwiftData/Trips/ContentView.swift
/*
Abstract:
A SwiftUI view that shows the main UI.
*/
import SwiftUI
import SwiftData
import WidgetKit
struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var showAddTrip = false
    @State private var selection: Trip?
    @State private var searchText: String = ""
    @State private var tripCount = 0
    @State private var unreadTripIdentifiers: [PersistentIdentifier] = []
    var body: some View {
        NavigationSplitView {
            TripListView(selection: $selection, tripCount: $tripCount,
                         unreadTripIdentifiers: $unreadTripIdentifiers,
                         searchText: searchText)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                        .disabled(tripCount == 0)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Spacer()
                    Button {
                        showAddTrip = true
                    } label: {
                        Label("Add trip", systemImage: "plus")
                    }
                }
            }
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 200, ideal: 250)
            #endif
        } detail: {
            if let selection = selection {
                NavigationStack {
                    TripDetailView(trip: selection)
                }
            }
        }
        .task {
            let tripIdentifiers = await DataModel.shared.unreadTripIdentifiersInUserDefaults
            unreadTripIdentifiers = tripIdentifiers
        }
        .searchable(text: $searchText, placement: .sidebar)
        .sheet(isPresented: $showAddTrip) {
            NavigationStack {
                AddTripView()
            }
            .presentationDetents([.medium, .large])
        }
        .onChange(of: selection) { _, newValue in
            if let newSelection = newValue {
                if let index = unreadTripIdentifiers.firstIndex(where: {
                    $0 == newSelection.persistentModelID
                }) {
                    unreadTripIdentifiers.remove(at: index)
                }
            }
        }
        .onChange(of: scenePhase) { _, newValue in
            Task {
                if newValue == .active {
                    unreadTripIdentifiers += await DataModel.shared.findUnreadTripIdentifiers()
                } else {
                    // Persist the unread trip identifiers for the next launch session.
                    let tripIdentifiers = unreadTripIdentifiers
                    await DataModel.shared.setUnreadTripIdentifiersInUserDefaults(tripIdentifiers)
                }
            }
        }
        #if os(macOS)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task {
                unreadTripIdentifiers += await DataModel.shared.findUnreadTripIdentifiers()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            Task {
                let tripIdentifiers = unreadTripIdentifiers
                await DataModel.shared.setUnreadTripIdentifiersInUserDefaults(tripIdentifiers)
            }
        }
        #endif
    }
}
#Preview(traits: .sampleData) {
    ContentView()
}

// Content from: Trips-SwiftData/Trips/BucketListView.swift
/*
Abstract:
A SwiftUI view that shows the bucket list.
*/
import SwiftUI
import SwiftData
struct BucketListView: View {
    var trip: Trip
    @Environment(\.modelContext) private var modelContext
    
    @State private var showAddItem = false
    @State private var searchText = ""
        
    var body: some View {
        TripForm {
            ForEach(filteredBucketList, id: \.self) { item in
                TripGroupBox {
                    NavigationLink {
                        BucketListItemView(item: item)
                    } label: {
                        HStack {
                            Text(item.title)
                            Spacer()
                            BucketListItemToggle(item: item)
                            #if os(macOS)
                            Image(systemName: "chevron.right")
                                .font(.system(.footnote).weight(.semibold))
                            #endif
                        }
                    }
                }
            }
            .onDelete(perform: deleteItems(at:))
        }
        .searchable(text: $searchText)
        .navigationTitle("Bucket List")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
                    .disabled(filteredBucketList.isEmpty)
            }
            ToolbarItemGroup(placement: .bottomBar) {
                Spacer()
                Button {
                    showAddItem.toggle()
                } label: {
                    Label("Add", systemImage: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showAddItem) {
            NavigationStack {
                AddBucketListItemView(trip: trip)
                    .presentationDetents([.medium, .large])
            }
        }
    }
    
    var filteredBucketList: [BucketListItem] {
        if searchText.isEmpty {
            return trip.bucketList
        }
        
        var descriptor = FetchDescriptor<BucketListItem>()
        let tripName = trip.name
        descriptor.predicate = #Predicate { item in
            item.title.contains(searchText) && tripName == item.trip?.name
        }
        let filteredList = try? modelContext.fetch(descriptor)
        return filteredList ?? []
    }
    
    private func deleteItems(at offsets: IndexSet) {
        withAnimation {
            offsets.forEach {
                let item = trip.bucketList[$0]
                modelContext.delete(item)
            }
        }
    }
}
struct BucketListItemToggle: View {
    @Bindable var item: BucketListItem
    
    var body: some View {
        Toggle("Bucket list item is in plan", isOn: $item.isInPlan)
            .labelsHidden()
    }
}
#Preview(traits: .sampleData) {
    @Previewable @Query var trips: [Trip]
    NavigationStack {
        BucketListView(trip: trips.first!)
    }
}

// Content from: Trips-SwiftData/Trips/TripsApp.swift
/*
Abstract:
The SwiftUI app.
*/
import SwiftUI
import SwiftData
@main
struct TripsApp: App {
    let modelContainer = DataModel.shared.modelContainer
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}

// Content from: Trips-CoreData/Trips/BucketListItem+Extension.swift
/*
Abstract:
The model class of bucket list item.
*/
import Foundation
extension BucketListItem {
    static var preview: BucketListItem {
        let result = PersistenceController.preview
        let viewContext = result.container.viewContext
        let item = BucketListItem(context: viewContext)
        item.title = "A bucket list item title"
        item.details = "Details of my bucket list item"
        item.hasReservation = true
        item.isInPlan = true
        return item
    }
}

// Content from: Trips-CoreData/Trips/Persistence.swift
/*
Abstract:
A class that sets up the Core Data stack.
*/
import CoreData
struct PersistenceController {
    static let shared = PersistenceController()
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        let newTrip = Trip(context: viewContext)
        newTrip.name = "Trip Name"
        newTrip.destination = "Trip destination"
        newTrip.startDate = .now
        newTrip.endDate = .now.addingTimeInterval(4 * 3600)
        
        let newBucketListItem = BucketListItem(context: viewContext)
        newBucketListItem.title = "A bucket list item title"
        newBucketListItem.details = "Details of my bucket list item"
        newBucketListItem.hasReservation = true
        newBucketListItem.isInPlan = true
        newBucketListItem.trip = newTrip
        
        let livingAccommodations = LivingAccommodation(context: viewContext)
        livingAccommodations.address = "A new address"
        livingAccommodations.placeName = "A place name"
        livingAccommodations.trip = newTrip
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return result
    }()
    let container: NSPersistentContainer
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Trips")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions.first!.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

// Content from: Trips-CoreData/Trips/AddTripView.swift
/*
Abstract:
A SwiftUI view that adds a new trip.
*/
import SwiftUI
struct AddTripView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.dismiss) private var dismiss
    @Environment(\.timeZone) private var timeZone
    @Environment(\.managedObjectContext) private var viewContext
    @State private var name = ""
    @State private var destination = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    var dateRange: ClosedRange<Date> {
        let start = Date.now
        let components = DateComponents(calendar: calendar, timeZone: timeZone, year: 1)
        let end = calendar.date(byAdding: components, to: start)!
        return start ... end
    }
    
    var body: some View {
        TripForm {
            Section(header: Text("Trip Title")) {
                TripGroupBox {
                    TextField("Enter title here…", text: $name)
                }
            }
            
            Section(header: Text("Trip Destination")) {
                TripGroupBox {
                    TextField("Enter destination here…", text: $destination)
                }
            }
            
            Section(header: Text("Trip Dates")) {
                TripGroupBox {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Start Date:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            DatePicker(selection: $startDate, in: dateRange,
                                       displayedComponents: .date) {
                                Label("Start Date", systemImage: "calendar")
                            }
                            .labelsHidden()
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("End Date:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            DatePicker(selection: $endDate, in: dateRange,
                                       displayedComponents: .date) {
                                Label("End Date", systemImage: "calendar")
                            }
                            .labelsHidden()
                        }
                    }
                }
            }
        }
        .frame(idealWidth: LayoutConstants.sheetIdealWidth,
               idealHeight: LayoutConstants.sheetIdealHeight)
        .navigationTitle("Add Trip")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Dismiss") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Done") {
                    addTrip()
                    dismiss()
                }
                .disabled(name.isEmpty || destination.isEmpty)
            }
        }
    }
    
    private func addTrip() {
        withAnimation {
            let newTrip = Trip(context: viewContext)
            newTrip.name = name
            newTrip.destination = destination
            newTrip.startDate = startDate
            newTrip.endDate = endDate
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            /**
             Real-world apps should consider better handling the error in a way that fits their UI.
            */
            let nsError = error as NSError
            fatalError("Failed to save Core Data changes: \(nsError)")
        }
    }
}
#Preview {
    AddTripView()
        .environment(\.managedObjectContext,
                      PersistenceController.preview.container.viewContext)
}

// Content from: Trips-CoreData/Trips/TripDetailView.swift
/*
Abstract:
A SwiftUI view that shows the details of a trip.
*/
import SwiftUI
import CoreData
struct TripDetailView: View {
    var trip: Trip
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(sortDescriptors: [.init(\.startDate)])
    private var trips: FetchedResults<Trip>
    @FetchRequest
    private var livingAccommodations: FetchedResults<LivingAccommodation>
    
    @FetchRequest(sortDescriptors: [.init(\.title)])
    private var bucketList: FetchedResults<BucketListItem>
    
    init(trip: Trip) {
        self.trip = trip
        _livingAccommodations = FetchRequest<LivingAccommodation>(
            sortDescriptors: [.init(\.placeName)],
            predicate: NSPredicate(format: "(trip = %@)", trip))
    }
    
    var body: some View {
        List {
            #if os(macOS)
            tripInfoViewForMac()
            #else
            tripInfoViewForiOS()
            #endif
        }
        .navigationTitle(Text("Trip Details"))
    }
    
    @ViewBuilder
    private func tripInfoViewForMac() -> some View {
        Section {
            TripGroupBox {
                HStack {
                    VStack(alignment: .leading) {
                        Text(trip.displayDestination)
                        if case let (start?, end?) = (trip.startDate, trip.endDate) {
                            HStack {
                                Text(start, style: .date)
                                Image(systemName: "arrow.right")
                                Text(end, style: .date)
                            }
                        }
                    }
                    Spacer()
                }
            }
        } header: {
            HStack {
                Text(trip.displayName)
                    .font(.title)
                Spacer()
                NavigationLink {
                    UpdateTripView(trip: trip)
                } label: {
                    Label("Edit", systemImage: "chevron.right").labelStyle(.iconOnly)
                }
            }
        }
        Section {
            TripGroupBox {
                HStack {
                    VStack(alignment: .leading) {
                        if let livingAccommodations = livingAccommodations.first(where: { $0.trip == trip }) {
                            Text(livingAccommodations.placeName ?? "No Place")
                            Text(livingAccommodations.address ?? "No Address")
                        } else {
                            Text("<No Living Accommodations>")
                        }
                    }
                    Spacer()
                }
            }
        } header: {
            HStack {
                Text("Living Accommodations").font(.headline)
                Spacer()
                NavigationLink {
                    EditLivingAccommodationsView(trip: trip)
                } label: {
                    Label("Edit", systemImage: "chevron.right").labelStyle(.iconOnly)
                }
            }
        }
        Section {
        } header: {
            HStack {
                Text("Bucket List").font(.headline)
                Spacer()
                NavigationLink {
                    BucketListView(trip: trip)
                } label: {
                    Label("View", systemImage: "chevron.right").labelStyle(.iconOnly)
                }
            }
        }
    }
    @ViewBuilder
    private func tripInfoViewForiOS() -> some View {
        VStack(alignment: .leading) {
            Text(trip.displayName)
                .font(.title)
                .bold()
            Text(trip.displayDestination)
            if case let (start?, end?) = (trip.startDate, trip.endDate) {
                HStack {
                    Text(start, style: .date)
                    Image(systemName: "arrow.right")
                    Text(end, style: .date)
                }
            }
        }
        NavigationLink {
            UpdateTripView(trip: trip)
        } label: {
            Text("Change Trip Details")
        }
        Section {
            VStack(alignment: .leading) {
                if let livingAccommodations = livingAccommodations.first(where: { $0.trip == trip }) {
                    Text(livingAccommodations.placeName ?? "No Place")
                    Text(livingAccommodations.address ?? "No Address")
                } else {
                    Text("<No Living Accommodations>")
                }
            }
            NavigationLink {
                EditLivingAccommodationsView(trip: trip)
            } label: {
                Text("Change Living Accommodations")
            }
        } header: {
            Text("Living Accommodations")
        }
        Section {
            NavigationLink {
                BucketListView(trip: trip)
            } label: {
                Text("View Bucket List")
            }
        } header: {
            Text("Bucket List")
        }
    }
}
#Preview {
    TripDetailView(trip: .preview)
        .environment(\.managedObjectContext,
                      PersistenceController.preview.container.viewContext)
}

// Content from: Trips-CoreData/Trips/BucketListItemView.swift
/*
Abstract:
A SwiftUI view that shows a bucket list item.
*/
import SwiftUI
struct BucketListItemView: View {
    var item: BucketListItem
    
    var body: some View {
        TripForm {
            Section {
                VStack(alignment: .leading) {
                    TripGroupBox {
                        HStack {
                            Text(item.details?.isEmpty ?? false ? "<No details>" : item.details!)
                            Spacer()
                        }
                    }
                    TripGroupBox {
                        HStack {
                            Text("Reservations made: ")
                            Spacer()
                            if item.hasReservation {
                                Text("YES")
                            } else {
                                Text("NO")
                            }
                        }
                        HStack {
                            Text("Already in plan: ")
                            Spacer()
                            if item.isInPlan {
                                Text("YES")
                            } else {
                                Text("NO")
                            }
                        }
                    }
                }
            } header: {
                Text("Bucket List Item Details")
            }
        }
        .navigationTitle(item.title ?? "Untitled bucket list item")
    }
}
#Preview {
    BucketListItemView(item: .preview)
        .environment(\.managedObjectContext,
                      PersistenceController.preview.container.viewContext)
}

// Content from: Trips-CoreData/Trips/SwiftUIHelper.swift
/*
Abstract:
Extensions that add convenience methods to SwiftUI.
*/
import SwiftUI
#if os(macOS)
typealias EditButton = EmptyView
typealias TripForm = List
typealias TripGroupBox = GroupBox
#else
typealias TripForm = Form
typealias TripGroupBox = Group
#endif
extension Color {
    static var tripGray: Color {
        #if os(iOS)
        return Color(.systemGray6)
        #else
        return Color.gray
        #endif
    }
}
extension ToolbarItemPlacement {
    #if os(macOS)
    static let navigationBarLeading = automatic
    static let navigationBarTrailing = automatic
    static let bottomBar = automatic
    #endif
}
/**
 Layout constants.
 */
struct LayoutConstants {
    static let sheetIdealWidth = 400.0
    static let sheetIdealHeight = 500.0
}

// Content from: Trips-CoreData/Trips/TripListItem.swift
/*
Abstract:
A SwiftUI list item view that shows trip metadata.
*/
import SwiftUI
struct TripListItem: View {
    /**
     This view needs to update when the trip changes.
     */
    @ObservedObject var trip: Trip
    
    var body: some View {
        NavigationLink(value: trip) {
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(trip.color)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Text(String(trip.displayName.first!))
                            .font(.system(size: 48))
                            .foregroundStyle(.background)
                    }
                    .padding(.trailing)
                
                VStack(alignment: .leading) {
                    Text(trip.displayName)
                        .font(.headline)
                    Text(trip.displayDestination)
                        .font(.subheadline)
                    
                    if case let (start?, end?) = (trip.startDate, trip.endDate) {
                        Divider()
                        HStack {
                            Text(start, style: .date)
                            Image(systemName: "arrow.right")
                            Text(end, style: .date)
                        }
                        .font(.caption)
                    }
                }
            }
        }
    }
}
#Preview {
    TripListItem(trip: .preview)
        .environment(\.managedObjectContext,
                      PersistenceController.preview.container.viewContext)
}

// Content from: Trips-CoreData/Trips/AddBucketListItemView.swift
/*
Abstract:
A SwiftUI view that adds an item to the bucket list.
*/
import SwiftUI
struct AddBucketListItemView: View {
    var trip: Trip
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var title: String = ""
    @State private var details: String = ""
    @State private var hasReservations: Bool = false
    @State private var isInPlan: Bool = false
    
    var body: some View {
        NavigationStack {
            TripForm {
                Section {
                    TripGroupBox {
                        TextField("Enter title here…", text: $title)
                    }
                } header: {
                    Text("Bucket List Item Title")
                }
                
                Section {
                    VStack(alignment: .leading) {
                        TripGroupBox {
                            TextField("Enter details here…", text: $details)
                        }
                        TripGroupBox {
                            Toggle("Is this activity in the plan?", isOn: $isInPlan)
                            Toggle("Are reservations made?", isOn: $hasReservations)
                        }
                    }
                } header: {
                    Text("Bucket List Item Details")
                }
            }
            .navigationTitle("Add Bucket List Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        addItem()
                        dismiss()
                    }
                }
            }
        }
        .frame(idealWidth: LayoutConstants.sheetIdealWidth,
               idealHeight: LayoutConstants.sheetIdealHeight)
    }
    
    private func addItem() {
        withAnimation {
            let newItem = BucketListItem(context: viewContext)
            newItem.title = title
            newItem.details = details
            newItem.isInPlan = isInPlan
            newItem.hasReservation = hasReservations
            newItem.trip = trip
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            /**
             Real-world apps should consider better handling the error in a way that fits their UI.
            */
            let nsError = error as NSError
            fatalError("Failed to save Core Data changes: \(nsError)")
        }
    }
}
#Preview {
    AddBucketListItemView(trip: .preview)
        .environment(\.managedObjectContext,
                      PersistenceController.preview.container.viewContext)
}

// Content from: Trips-CoreData/Trips/EditLivingAccommodationsView.swift
/*
Abstract:
A SwiftUI view that edits living place.
*/
import SwiftUI
struct EditLivingAccommodationsView: View {
    var trip: Trip
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var placeName = ""
    @State private var address = ""
    
    var body: some View {
        TripForm {
            Section(header: Text("Name of Living Accommodation")) {
                TripGroupBox {
                    TextField(namePlaceholder, text: $placeName)
                }
            }
            
            Section(header: Text("Address of Living Accommodation")) {
                TripGroupBox {
                    TextField(addressPlaceholder, text: $address)
                }
            }
        }
        .background(Color.tripGray)
        .navigationTitle("Edit Living Accommodations")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Done") {
                    addLiving()
                    dismiss()
                }
                .disabled(placeName.isEmpty || address.isEmpty)
            }
        }
        .onAppear {
            placeName = trip.livingAccommodation?.placeName ?? ""
            address = trip.livingAccommodation?.address ?? ""
        }
    }
    
    var namePlaceholder: String {
        trip.livingAccommodation?.placeName ?? "Enter place name here…"
    }
    
    var addressPlaceholder: String {
        trip.livingAccommodation?.address ?? "Enter address here…"
    }
    
    private func addLiving() {
        withAnimation {
            if let livingAccommodation = trip.livingAccommodation {
                livingAccommodation.address = address
                livingAccommodation.placeName = placeName
            } else {
                let newLivingAccommodation = LivingAccommodation(context: viewContext)
                newLivingAccommodation.address = address
                newLivingAccommodation.placeName = placeName
                newLivingAccommodation.trip = trip
            }
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            /**
             Real-world apps should consider better handling the error in a way that fits their UI.
            */
            let nsError = error as NSError
            fatalError("Failed to save Core Data changes: \(nsError)")
        }
    }
}
#Preview {
    EditLivingAccommodationsView(trip: .preview)
        .environment(\.managedObjectContext,
                      PersistenceController.preview.container.viewContext)
}

// Content from: Trips-CoreData/Trips/UpdateTripView.swift
/*
Abstract:
A SwiftUI view that updates a trip.
*/
import SwiftUI
struct UpdateTripView: View {
    var trip: Trip
    @Environment(\.calendar) private var calendar
    @Environment(\.dismiss) private var dismiss
    @Environment(\.timeZone) private var timeZone
    @Environment(\.managedObjectContext) private var viewContext
    @State private var name: String = ""
    @State private var destination: String = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    var dateRange: ClosedRange<Date> {
        let start = Date.now
        let components = DateComponents(calendar: calendar,
                                        timeZone: timeZone, year: 1)
        let end = calendar.date(byAdding: components, to: start)!
        return start ... end
    }
    
    var body: some View {
        TripForm {
            Section(header: Text("Trip Title")) {
                TripGroupBox {
                    TextField(trip.name ?? "Enter title here…", text: $name)
                }
            }
            
            Section(header: Text("Trip Destination")) {
                TripGroupBox {
                    TextField(trip.destination ?? "Enter destination here…",
                              text: $destination)
                }
            }
            
            Section(header: Text("Trip Dates")) {
                TripGroupBox {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Start Date:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            DatePicker(selection: $startDate,
                                       in: dateRange, displayedComponents: .date) {
                                Label("Start Date", systemImage: "calendar")
                            }
                            .labelsHidden()
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("End Date:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            DatePicker(selection: $endDate,
                                       in: dateRange, displayedComponents: .date) {
                                Label("End Date", systemImage: "calendar")
                            }
                            .labelsHidden()
                        }
                    }
                }
            }
        }
        .onAppear {
            /**
             Populate the start and end date of the trip.
             */
            startDate = trip.startDate ?? Date()
            endDate = trip.endDate ?? Date()
        }
        .navigationTitle("Update Trip")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Done") {
                    updateTrip()
                    dismiss()
                }
            }
        }
    }
    
    private func updateTrip() {
        withAnimation {
            if !name.isEmpty {
                trip.name = name
            }
            
            if !destination.isEmpty {
                trip.destination = destination
            }
            
            trip.startDate = startDate
            trip.endDate = endDate
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            /**
             Real-world apps should consider better handling the error in a way that fits their UI.
            */
            let nsError = error as NSError
            fatalError("Failed to save Core Data changes: \(nsError)")
        }
    }
}
#Preview {
    UpdateTripView(trip: .preview)
        .environment(\.managedObjectContext,
                      PersistenceController.preview.container.viewContext)
}

// Content from: Trips-CoreData/Trips/ContentView.swift
/*
Abstract:
A SwiftUI view that shows the main UI.
*/
import SwiftUI
import CoreData
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.startDate)])
    private var trips: FetchedResults<Trip>
    @State private var showAddTrip = false
    @State private var selection: Trip?
    @State private var path: [Trip] = []
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(trips) { trip in
                    TripListItem(trip: trip)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteTrip(trip)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .onDelete(perform: deleteTrips(at:))
            }
            .overlay {
                if trips.isEmpty {
                    ContentUnavailableView {
                         Label("No Trips", systemImage: "car.circle")
                    } description: {
                         Text("New trips you create will appear here.")
                    }
                }
            }
            .navigationTitle("Upcoming Trips")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                        .disabled(trips.isEmpty)
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Spacer()
                    Button {
                        showAddTrip = true
                    } label: {
                        Label("Add trip", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let selection = selection {
                NavigationStack {
                    TripDetailView(trip: selection)
                }
            }
        }
        .sheet(isPresented: $showAddTrip) {
            NavigationStack {
                AddTripView()
            }
            .presentationDetents([.medium, .large])
        }
    }
    private func deleteTrips(at offsets: IndexSet) {
        withAnimation {
            offsets.map { trips[$0] }.forEach(deleteTrip)
        }
    }
     
    private func deleteTrip(_ trip: Trip) {
        /**
         Unselect the item before deleting it.
         */
        if trip.objectID == selection?.objectID {
            selection = nil
        }
        viewContext.delete(trip)
        do {
            try viewContext.save()
        } catch {
            /**
             Real-world apps should consider better handling the error in a way that fits their UI.
            */
            let nsError = error as NSError
            fatalError("Failed to save Core Data changes: \(nsError), \(nsError.userInfo)")
        }
    }
}
#Preview {
    ContentView()
        .environment(\.managedObjectContext,
                      PersistenceController.preview.container.viewContext)
}

// Content from: Trips-CoreData/Trips/BucketListView.swift
/*
Abstract:
A SwiftUI view that shows the bucket list.
*/
import SwiftUI
import CoreData
struct BucketListView: View {
    var trip: Trip
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest private var bucketList: FetchedResults<BucketListItem>
    
    init(trip: Trip) {
        self.trip = trip
        self._bucketList = FetchRequest<BucketListItem>(sortDescriptors: [SortDescriptor(\.title)],
                                                        predicate: NSPredicate(format: "trip.name = %@", trip.name ?? ""))
    }
    
    @State private var showAddItem = false
    @State private var searchText = ""
    
    var body: some View {
        TripForm {
            ForEach(bucketList) { item in
                TripGroupBox {
                    NavigationLink {
                        BucketListItemView(item: item)
                    } label: {
                        HStack {
                            Text(item.title ?? "Untitled Bucket List Item")
                            Spacer()
                            BucketListItemToggle(item: item)
                            #if os(macOS)
                            Image(systemName: "chevron.right").font(Font.system(.footnote).weight(.semibold))
                            #endif
                        }
                    }
                }
            }
            .onDelete(perform: deleteItems(at:))
        }
        .searchable(text: $searchText)
        .onChange(of: searchText) { oldValue, newValue in
            bucketList.nsPredicate = newValue.isEmpty ? nil : searchPredicate
        }
        .navigationTitle("Bucket List")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
                    .disabled(bucketList.isEmpty)
            }
            ToolbarItemGroup(placement: .bottomBar) {
                Spacer()
                Button {
                    showAddItem.toggle()
                } label: {
                    Label("Add", systemImage: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showAddItem) {
            NavigationStack {
                AddBucketListItemView(trip: trip)
                    .presentationDetents([.medium, .large])
            }
        }
    }
    
    var searchPredicate: NSPredicate {
        let bucketListPredicate = NSPredicate(format: "ANY title CONTAINS[c] %@", searchText)
        let tripPredicate = NSPredicate(format: "trip.name = %@", trip.name ?? "")
        let compoundPredicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [bucketListPredicate, tripPredicate])
        return compoundPredicate
    }
    
    private func deleteItems(at offsets: IndexSet) {
        withAnimation {
            offsets.map { bucketList[$0] }.forEach(viewContext.delete)
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            /**
             Real-world apps should consider better handling the error in a way that fits their UI.
            */
            let nsError = error as NSError
            fatalError("Failed to save Core Data changes: \(nsError)")
        }
    }
}
struct BucketListItemToggle: View {
    var item: BucketListItem
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isOn: Bool = false
    
    var body: some View {
        Toggle("Bucket list item is in plan", isOn: $isOn)
            .labelsHidden()
            .onAppear { isOn = item.isInPlan }
            .onChange(of: isOn) { oldValue, newValue in
                item.isInPlan = newValue
                saveContext()
            }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            /**
             Real-world apps should consider better handling the error in a way that fits their UI.
            */
            let nsError = error as NSError
            fatalError("Failed to save Core Data changes: \(nsError)")
        }
    }
}
#Preview {
    BucketListView(trip: .preview)
        .environment(\.managedObjectContext,
                      PersistenceController.preview.container.viewContext)
}

// Content from: Trips-CoreData/Trips/TripsApp.swift
/*
Abstract:
The SwiftUI app.
*/
import SwiftUI
@main
struct TripsApp: App {
    let persistenceController = PersistenceController.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext,
                              persistenceController.container.viewContext)
        }
    }
}

// Content from: Trips-CoreData/Trips/Trip+Extension.swift
/*
Abstract:
The model class of trips.
*/
import SwiftUI
extension Trip {
    var color: Color {
        let seed = name?.hashValue ?? 8
        var generator: RandomNumberGenerator = SeededRandomGenerator(seed: seed)
        return .random(using: &generator)
    }
    
    var displayName: String {
        guard let name, !name.isEmpty
        else { return "Untitled Trip" }
        return name
    }
    
    var displayDestination: String {
        guard let destination, !destination.isEmpty
        else { return "Untitled Destination" }
        return destination
    }
    
    static var preview: Trip {
        let result = PersistenceController.preview
        let viewContext = result.container.viewContext
        let trip = Trip(context: viewContext)
        trip.name = "Trip Name"
        trip.destination = "Trip destination"
        trip.startDate = .now
        trip.endDate = .now.addingTimeInterval(4 * 3600)
        return trip
    }
}
private struct SeededRandomGenerator: RandomNumberGenerator {
    init(seed: Int) {
        srand48(seed)
    }
    
    func next() -> UInt64 {
        UInt64(drand48() * Double(UInt64.max))
    }
}
private extension Color {
    static var random: Color {
        var generator: RandomNumberGenerator = SystemRandomNumberGenerator()
        return random(using: &generator)
    }
    
    static func random(using generator: inout RandomNumberGenerator) -> Color {
        let red = Double.random(in: 0..<1, using: &generator)
        let green = Double.random(in: 0..<1, using: &generator)
        let blue = Double.random(in: 0..<1, using: &generator)
        return Color(red: red, green: green, blue: blue)
    }
}
