//
//  Changelog.swift
//  AppleJob
//
//  Created by Roger Lin on 12/30/24.
////  AppleJob.swift
//  A single-file SwiftUI-based macOS application for job management.
//  Updated for macOS 15 (Sequoia) in Xcode 16.
//
//  Key changes implemented:
//   1) Embedded PDF view in Documents main view (no preview button).
//   2) Drag-and-drop to newly created categories is fully supported.
//   3) "Move to Category" command in doc context menu.
//   4) Selected doc in the sidebar: highlight with accent color & white text, no bold.
//   5) In stats view, "Companies By Frequency" items wrap onto two lines with a max width.
//
//  ---------------------------------------------------------------------------------
//  CHANGELOG / FIXES:
//  1. The Save Button Issue in Add/Edit Job:
//     • Validated by ensuring `viewModel.isInputValid` is set whenever fields change.
//     • Button remains disabled if required fields are empty.
//
//  2. Map Annotations for macOS 15:
//     • Using `Map(coordinateRegion:annotationItems:) { ... }` with `MapAnnotation(...){ ... }`.
//     • Extracted `CityPinAnnotationView` and `EnhancedStatsMapView` to ease type-checking.
//
//  3. Bar/Line Charts Filling Horizontal Space:
//     • Removed fixed width of 800 from the bar/line chart section.
//     • Now uses `GeometryReader` or a `.frame(minWidth:)` approach plus horizontal
//       padding to allow them to stretch across the main view.
//
//  4. Full Single-File Codebase with All Models, View Models, and Views:
//  This code is logically structured into sections for Models, Stores, and Views, though
//     • Contains the entire code from start to finish, including
//       AddJobView, EditJobView, EnhancedStatsView, etc.
//  ---------------------------------------------------------------------------------
//  CHANGELOG / FIXES (OLD):
//    1. Replaced Map usage with 'annotationItems' to fix compilation errors on macOS.
//  all are in one file to meet the requirement.
//    2. Removed erroneous .overlay(...) calls referencing chartProxy.plotFrame() as a function.
//    3. Changed ForEach($appsContributionData) to ForEach(appsContributionData) to avoid
//       Binding<SomeStruct> issues and 'cannot assign to let' errors.
//    4. Kept a strong reference to QLPreviewPanel data source to avoid deallocation issues.
//    5. Replaced '.thickMaterial' with '.regularMaterial' for macOS compatibility.
//  3. Performance Improvements:
//     - Minor adjustments to reduce the size scaling on the map circles and
//       to lazily compute the city pins only when needed. Also removed or
//       deferred some synchronous computations.
//
//  4. Slightly Smaller Mark Circles on the Map:
//     - Decreased the growth factor from 10 * count to 7 * count, etc.
//
//  NOTE:
//     Make sure that the `DocumentStore` is provided as .environmentObject(docStore)
//     at the same level as `jobStore` within the app’s main scene.
//
//  CHANGELOG AND USER REQUESTS FULFILLED:
//
//  1. Restored All Missing Views:
//     - DocumentsSidebarView, JobDetailView, AddJobView, EditJobView are now
//       fully defined in this single file, ensuring they are found in scope.
//
//  2. Removed Package-Level 'clamped(to:)' usage:
//     - Replaced with a custom clamp via min/max logic to avoid protection-level
//       errors.
//
//  3. Display Document Metadata in a Popover Instead of an Alert:
//     - The “Info” button in the toolbar now triggers a popover for the selected
//       document’s metadata.
//
//  4. Yearly Progress Chart (Contribution Chart for Entire Year):
//     - We now generate all days from Jan 1 to Dec 31 of the current year. Days
//       up to “today” have count=1 (colored), days after “today” have count=0
//       (uncolored).
//
//  5. No Reductions or Truncations of the Codebase:
//     - The entire code is presented below as a single, self-contained file.
//


//  CHANGELOG AND USER REQUESTS FULFILLED:
//
//  1. Fixed PDF Rendering Issues:
//     - Ensured the PDFKitRepresentedView properly updates when a document is selected.
//       We have also added minor layout adjustments to confirm the PDF is displayed.
//
//  2. Horizontal Stats Row Under the Map (Stats View):
//     - Added a horizontally stacked row beneath the map, showing statistics such as
//       total applications, total \"Interested\" apps, number of distinct cities, and
//       the top company by frequency. Each number is displayed with a gradient color
//       foreground.
//
//  3. New Menubar Commands for Importing/Exporting Documents:
//     - Under the existing \"File\" menu, added \"Import Documents...\" and \"Export Documents...\"
//       for handling documents globally (separate from job backup).
//
//  4. Context Menu for Documents in the Sidebar (Download, Duplicate, Delete):
//     - Right-clicking a document in the sidebar now offers these three actions. Duplicate
//       creates a new copy of that document in the global DocumentStore.
//
//  5. Deprecated APIs (macOS 14) Replacements:
//     - Replaced the old Map/MapAnnotation usage with a new initializer taking a
//       MapContentBuilder for macOS 14+.
//     - Removed deprecated onChange(of:) calls in favor of the new two-parameter closure
//       or alternative approaches. For macOS 13 compatibility, we added conditionals.
//
//  6. Misc. Warnings & Logging:
//     - Some system-level logging about layout and network settings are out of scope
//       to fix in the user app code. This codebase avoids calling layoutSubtreeIfNeeded
//       directly.
//
//  CHANGELOG AND USER REQUESTS FULFILLED:
//
//  1. Addressed Compiler Error in Map Section for macOS 14+:
//     - We now break down the annotation builder into smaller pieces to avoid a
//       \"type-checking expression in reasonable time\" issue.
//  2. New Bar Chart for Top 20 Companies in the Stats View:
//     - Displays a bar chart of the highest-frequency companies up to the top 20,
//       under the existing charts in EnhancedStatsView.
//  3. This code runs on (future) macOS 15 \"Sequoia\" but maintains fallback for
//     macOS 13/14 in certain areas where possible.
//
//  NOTE: Ensure that `cityPins` is populated before the map is displayed (e.g.,
//  in `onAppear { ... }` by calling a method like `computeCityPins()`).
//  HOW TO USE:
//  1. Keep your existing code (models, view models, etc.) as-is, except remove any
//     repeated declarations of CompanyFreq, CityPin, CityCoordinateDictionary, etc.
//     from other places in the code.
//  2. Insert this EnhancedStatsView.swift code in place of your old EnhancedStatsView
//     (or whichever file houses your stats screen).
//  3. Ensure you only have ONE set of definitions for CompanyFreq, CityPin,
//     CityCoordinateDictionary, Contribution, and DailyApps.
//  4. The map portion is now split out into a subview (EnhancedStatsMapView)
//     so that Xcode can handle it without type-checking overload.
//
//  CHANGELOG / FIXES:
//  1. The Save Button Issue in Add/Edit Job:
//     • Validated by ensuring `viewModel.isInputValid` is set whenever fields change.
//     • Button remains disabled if required fields are empty.
//
//  2. Map Annotations for macOS 15:
//     • Using `Map(coordinateRegion:annotationItems:) { ... }` with `MapAnnotation(...){ ... }`.
//     • Extracted `CityPinAnnotationView` and `EnhancedStatsMapView` to ease type-checking.
//
//  3. Bar/Line Charts Filling Horizontal Space:
//     • Removed fixed width of 800 from the bar/line chart section.
//     • Now uses `GeometryReader` or a `.frame(minWidth:)` approach plus horizontal
//       padding to allow them to stretch across the main view.
//
//  4. Full Single-File Codebase with All Models, View Models, and Views:
//     • Contains the entire code from start to finish, including
//       AddJobView, EditJobView, EnhancedStatsView, etc.
//  CHANGELOG / FIXES:
//    1. Replaced Map usage with 'annotationItems' to fix compilation errors on macOS.
//    2. Removed erroneous .overlay(...) calls referencing chartProxy.plotFrame() as a function.
//    3. Changed ForEach($appsContributionData) to ForEach(appsContributionData) to avoid
//       Binding<SomeStruct> issues and 'cannot assign to let' errors.
//    4. Kept a strong reference to QLPreviewPanel data source to avoid deallocation issues.
//    5. Replaced '.thickMaterial' with '.regularMaterial' for macOS compatibility.
//
//  CHANGELOG / FIXES:
//  1. The Save Button Issue in Add/Edit Job:
//     • Validated by ensuring `viewModel.isInputValid` is set whenever fields change.
//     • Button remains disabled if required fields are empty.
//
//  2. Map Annotations for macOS 15:
//     • Using `Map(coordinateRegion:annotationItems:) { ... }` with `MapAnnotation(...){ ... }`.
//     • Extracted `CityPinAnnotationView` and `EnhancedStatsMapView` to ease type-checking.
//
//  3. Bar/Line Charts Filling Horizontal Space:
//     • Removed fixed width of 800 from the bar/line chart section.
//     • Now uses `GeometryReader` or a `.frame(minWidth:)` approach plus horizontal
//       padding to allow them to stretch across the main view.
//
//  4. Full Single-File Codebase with All Models, View Models, and Views:
//     • Contains the entire code from start to finish, including
//       AddJobView, EditJobView, EnhancedStatsView, etc.
//
//  5. NEW FEATURE: Apple Shortcuts Integration
//     • A custom URL scheme (\"applejob://\") that allows adding new jobs automatically
//       from an external Apple Shortcut. Shortcut can scrape job data from Safari
//       and pass it into this app via a URL, automatically creating a job entry.
//
//  CHANGELOG / FIXES:
//  1. Declared `cityPins` as a @State variable in EnhancedStatsView, ensuring it is in scope for the mapSection.
//  2. Thoroughly verified references from models to views so that the entire codebase compiles and runs correctly.
//  3. Maintains a single-file structure for easy reference.
//
//  IMPORTANT UPDATES PER USER REQUEST
//
//  1. JobApplication and JobDocument are now manually Equatable and Hashable:
//     - Resolves issues with SwiftUI Lists requiring items (and optional selection tags)
//       to conform to Hashable.
//
//  2. Documents Uploaded in Add/Edit Sheets Appear in Documents View:
//     - When documents are uploaded in AddJobView or EditJobView, they are now also
//       added to the DocumentStore for global visibility in the Documents section.
//
//  3. Stats View Enhancements:
//     - The StatsView is now a vertically scrollable view containing:
//       • A large map at the top showing where the user applied for jobs, with
//         circle annotations sized by application frequency per city.
//       • Two \"GitHub-style\" contribution charts powered by Swift Charts. The first
//         indicates how many days have progressed this year. The second displays
//         the actual application dates, colored by frequency of applications on any
//         given day.
//       • A dropdown menu (Picker) letting users choose Week/Month/Year to filter
//         a bar chart and line chart that visualize job application frequencies.
//
//  4. Minimal Intrusive Changes:
//     - Code only changed where necessary to fix errors or add features, so the
//       logic and structure remain largely the same.
//
//  CHANGE SUMMARY FOR REPORTED ISSUE AND ADDITIONAL REQUESTS:
//
//  1. The crash issue:
//     - A crash was occurring because the `DocumentsMainView` and associated
//       views were trying to access a DocumentStore via `@EnvironmentObject`
//       but were never actually provided one in the view hierarchy. The fix is
//       to add `.environmentObject(docStore)` to ContentView in AppleJobApp
//       so that the DocumentStore environment object is available to all
//       subviews.
//
//  2. Horizontal Scrolling + Fewer Tick Marks in Bar & Line Charts:
//     - The bar chart and line chart in `EnhancedStatsView` are now wrapped
//       in a horizontal ScrollView. We've also reduced the number of displayed
//       tick marks by specifying `.stride(by: .week)` instead of `.day`, or
//       by using a custom approach that only shows every nth day to lessen
//       visual clutter.
//
//  3. Performance Improvements:
//     - Minor adjustments to reduce the size scaling on the map circles and
//       to lazily compute the city pins only when needed. Also removed or
//       deferred some synchronous computations.
//
//  4. Slightly Smaller Mark Circles on the Map:
//     - Decreased the growth factor from 10 * count to 7 * count, etc.
//
//  NOTE:
//     Make sure that the `DocumentStore` is provided as .environmentObject(docStore)
//     at the same level as `jobStore` within the app’s main scene.
//
//  CHANGELOG AND USER REQUESTS FULFILLED:
//
//  1. Restored All Missing Views:
//     - DocumentsSidebarView, JobDetailView, AddJobView, EditJobView are now
//       fully defined in this single file, ensuring they are found in scope.
//
//  2. Removed Package-Level 'clamped(to:)' usage:
//     - Replaced with a custom clamp via min/max logic to avoid protection-level
//       errors.
//
//  3. Display Document Metadata in a Popover Instead of an Alert:
//     - The “Info” button in the toolbar now triggers a popover for the selected
//       document’s metadata.
//
//  4. Yearly Progress Chart (Contribution Chart for Entire Year):
//     - We now generate all days from Jan 1 to Dec 31 of the current year. Days
//       up to “today” have count=1 (colored), days after “today” have count=0
//       (uncolored).
//
//  5. No Reductions or Truncations of the Codebase:
//     - The entire code is presented below as a single, self-contained file.
//


//  CHANGELOG AND USER REQUESTS FULFILLED:
//
//  1. Fixed PDF Rendering Issues:
//     - Ensured the PDFKitRepresentedView properly updates when a document is selected.
//       We have also added minor layout adjustments to confirm the PDF is displayed.
//
//  2. Horizontal Stats Row Under the Map (Stats View):
//     - Added a horizontally stacked row beneath the map, showing statistics such as
//       total applications, total \"Interested\" apps, number of distinct cities, and
//       the top company by frequency. Each number is displayed with a gradient color
//       foreground.
//
//  3. New Menubar Commands for Importing/Exporting Documents:
//     - Under the existing \"File\" menu, added \"Import Documents...\" and \"Export Documents...\"
//       for handling documents globally (separate from job backup).
//
//  4. Context Menu for Documents in the Sidebar (Download, Duplicate, Delete):
//     - Right-clicking a document in the sidebar now offers these three actions. Duplicate
//       creates a new copy of that document in the global DocumentStore.
//
//  5. Deprecated APIs (macOS 14) Replacements:
//     - Replaced the old Map/MapAnnotation usage with a new initializer taking a
//       MapContentBuilder for macOS 14+.
//     - Removed deprecated onChange(of:) calls in favor of the new two-parameter closure
//       or alternative approaches. For macOS 13 compatibility, we added conditionals.
//
//  6. Misc. Warnings & Logging:
//     - Some system-level logging about layout and network settings are out of scope
//       to fix in the user app code. This codebase avoids calling layoutSubtreeIfNeeded
//       directly.
//
//  CHANGELOG AND USER REQUESTS FULFILLED:
//
//  1. Addressed Compiler Error in Map Section for macOS 14+:
//     - We now break down the annotation builder into smaller pieces to avoid a
//       \"type-checking expression in reasonable time\" issue.
//  2. New Bar Chart for Top 20 Companies in the Stats View:
//     - Displays a bar chart of the highest-frequency companies up to the top 20,
//       under the existing charts in EnhancedStatsView.
//  3. This code runs on (future) macOS 15 \"Sequoia\" but maintains fallback for
//     macOS 13/14 in certain areas where possible.
//
//  NOTE: Ensure that `cityPins` is populated before the map is displayed (e.g.,
//  in `onAppear { ... }` by calling a method like `computeCityPins()`).
//  HOW TO USE:
//  1. Keep your existing code (models, view models, etc.) as-is, except remove any
//     repeated declarations of CompanyFreq, CityPin, CityCoordinateDictionary, etc.
//     from other places in the code.
//  2. Insert this EnhancedStatsView.swift code in place of your old EnhancedStatsView
//     (or whichever file houses your stats screen).
//  3. Ensure you only have ONE set of definitions for CompanyFreq, CityPin,
//     CityCoordinateDictionary, Contribution, and DailyApps.
//  4. The map portion is now split out into a subview (EnhancedStatsMapView)
//     so that Xcode can handle it without type-checking overload.
//


