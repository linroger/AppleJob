
// MARK: - NewLocationView
// -----------------------------------------------------
/**
A small sheet to add a brand-new location with name, latitude, and longitude.
This view is used to create a new job entry.
If the Safari extension passes data, we can pre-populate the fields here in the ViewModel
or by referencing jobStore.incomingJobData.
*/

/*****************************************************
*               NEW LOCATION VIEW
*****************************************************/

/// A small sheet to add a brand-new location with name, latitude, and longitude.

struct NewLocationView: View {
   @Binding var locations: [String]
   @Binding var selectedLocation: String
   @Binding var isPresented: Bool

   @State private var newLocationName: String = ""
   @State private var latitude: String = ""
   @State private var longitude: String = ""

   var body: some View {
       VStack {
           Text("Add a New Location")
               .font(.headline)

           // LOCATION NAME
           TextField("Location Name", text: $newLocationName)
               .modifier(TranslucentGradientBackground())
               .overlay(RoundedRectangle(cornerRadius: 5)
                   .strokeBorder(Color.gray.opacity(0.5), lineWidth: 1))

           // LATITUDE
           TextField("Latitude", text: $latitude)
               .modifier(TranslucentGradientBackground())
               .overlay(RoundedRectangle(cornerRadius: 5)
                   .strokeBorder(Color.gray.opacity(0.5), lineWidth: 1))

           // LONGITUDE
           TextField("Longitude", text: $longitude)
               .modifier(TranslucentGradientBackground())
               .overlay(RoundedRectangle(cornerRadius: 5)
                   .strokeBorder(Color.gray.opacity(0.5), lineWidth: 1))

           HStack {
               Button("Cancel") {
                   isPresented = false
               }
               .buttonStyle(.bordered)
               .tint(.red)

               Spacer()

               Button("Add") {
                   guard let lat = Double(latitude),
                         let lon = Double(longitude),
                         !newLocationName.isEmpty else { return }
                   if !locations.contains(newLocationName) {
                       locations.append(newLocationName)
                   }
                   selectedLocation = newLocationName
                   let newCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                   CityCoordinateDictionary[newLocationName] = newCoordinate
                   isPresented = false
               }
               .buttonStyle(.borderedProminent)
               .tint(.blue)
           }
           .padding()
       }
       .frame(width: 300, height: 250)
       .background(
           Color(nsColor: .windowBackgroundColor).opacity(0.8)
       )
       .background(
           WindowAccessor { window in
               window?.isMovableByWindowBackground = true
           }
       )
   }
}

// MARK: - TranslucentGradientBackground ViewModifier
struct TranslucentGradientBackground: ViewModifier {
   func body(content: Content) -> some View {
       content
           .background(
               ZStack {
                   LinearGradient(
                       colors: [
                           Color.pink.opacity(0.3),
                           Color.blue.opacity(0.3)
                       ],
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing
                   )
                   .blur(radius: 5)
                   .background(.ultraThinMaterial)
               }
               .clipShape(RoundedRectangle(cornerRadius: 5))
           )
   }
}

struct WindowAccessor: NSViewRepresentable {
   @State var window: NSWindow? = nil
   let configure: (NSWindow?) -> Void

   init(configure: @escaping (NSWindow?) -> Void) {
       self.configure = configure
   }

   func makeNSView(context: Context) -> NSView {
       let view = NSView()
       DispatchQueue.main.async {
           self.window = view.window
           configure(window)
       }
       return view
   }

   func updateNSView(_ nsView: NSView, context: Context) {
       configure(window)
   }
}

