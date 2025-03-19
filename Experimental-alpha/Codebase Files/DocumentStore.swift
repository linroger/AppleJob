//
//  DocumentStore.swift
//  Experimental-alpha
//
//  Created by Roger Lin on 3/14/25.
//


// -----------------------------------------------------------------------------
// MARK: - DocumentStore
// -----------------------------------------------------------------------------

import SwiftUI
import AppKit
import UniformTypeIdentifiers
import PDFKit
import MapKit
import Charts
import Quartz
import QuickLook
import QuickLookUI
import MarkdownUI  // Replacing MarkdownKit with MarkdownUI
import SwiftData
import SwiftSoup  // For LinkedIn HTML parsing
import WebKit     // For WebView to automate LinkedIn access

//
//  DocumentStore.swift
//  Experimental-alpha
//
//  Created by Roger Lin on 3/4/25.
//
// MARK: - DocumentStore
class DocumentStore: ObservableObject {
    @Published var documents: [JobDocument] = []
    @Published var selectedDocument: JobDocument? = nil
    @Published var categories: [DocumentCategory] = []
    @Published var isCreatingNewCategory = false
    @Published var newCategoryName: String = "Category Name"
    @Published var quickLookURL: URL? = nil
    @Published var isEditingMetadata = false
    @Published var documentToEdit: JobDocument? = nil
    public let modelContext: ModelContext
    // Variables to track memory usage
    private var cachedPDFDocuments: [UUID: PDFDocument] = [:]
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadDocuments()
        loadCategories()
        deduplicateDocuments()
    }
    private func loadFromUserDefaults() {
        guard let jsonString = UserDefaults.standard.string(forKey: Constants.documentsKey),
              let jsonData = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
              let docsArray = jsonObject as? [[String: Any]]
        else {
            return
        }
        var loadedDocs: [JobDocument] = []
        for dict in docsArray {
            if let doc = JobDocument.fromDictionary(dict) {
                loadedDocs.append(doc)
            }
        }
        documents = loadedDocs
        deduplicateDocuments()
    }
    // For non-async usage
    func uploadDocumentsNonAsync(from urls: [URL]) {
        for url in urls {
            do {
                let data = try Data(contentsOf: url)
                var creation = Date()
                var modified = Date()
                if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) {
                    if let cdate = attributes[.creationDate] as? Date {
                        creation = cdate
                    }
                    if let mdate = attributes[.modificationDate] as? Date {
                        modified = mdate
                    }
                }
                if let savedURL = DocumentStore.saveDocumentToAppSupport(
                    originalURL: url,
                    fileName: url.lastPathComponent
                ) {
                    let newDoc = JobDocument(
                        fileName: url.lastPathComponent,
                        fileData: data,
                        fileURL: savedURL,
                        creation: creation,
                        lastModified: modified
                    )
                    if !documents.contains(newDoc) {
                        documents.append(newDoc)
                    }
                }
            } catch {
                print("Error reading document: \(error)")
            }
        }
        saveDocuments()
        deduplicateDocuments()
    }
    func downloadSelectedDocument() {
        guard let doc = selectedDocument else { return }
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = doc.fileName
        savePanel.begin { response in
            if response == .OK, let selectedURL = savePanel.url {
                do {
                    try doc.fileData.write(to: selectedURL)
                } catch {
                    print("Error saving document: \(error)")
                }
            }
        }
    }
    func duplicateDocument(_ document: JobDocument) {
        guard let savedURL = DocumentStore.saveDocumentToAppSupport(
            originalURL: document.fileURL ?? URL(fileURLWithPath: ""),
            fileName: document.fileName
        ) else {
            print("Failed to save duplicated document.")
            return
        }
        let newDoc = JobDocument(
            fileName: "\(document.fileName)-copy",
            fileData: document.fileData,
            fileURL: savedURL,
            creation: document.creationDate,
            lastModified: document.lastModifiedDate,
            fileSize: document.fileSize,
            wordCount: document.wordCount,
            categoryID: document.categoryID,
            associatedCompany: document.associatedCompany,
            associatedJobTitle: document.associatedJobTitle,
            associatedApplicationDate: document.associatedApplicationDate
        )
        documents.append(newDoc)
        saveDocuments()
        deduplicateDocuments()
    }
    func deleteDocument(_ document: JobDocument) {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents.remove(at: index)
            // Clean up cached PDF if it exists
            cachedPDFDocuments[document.id] = nil
            if let fileURL = document.fileURL {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                } catch {
                    print("Failed to delete file at \(fileURL): \(error)")
                }
            }
        }
        if selectedDocument?.id == document.id {
            selectedDocument = nil
        }
        saveDocuments()
    }
    func deduplicateDocuments() {
        // Group documents by filename
        var fileNameMap: [String: [JobDocument]] = [:]
        for doc in documents {
            if fileNameMap[doc.fileName] == nil {
                fileNameMap[doc.fileName] = [doc]
            } else {
                fileNameMap[doc.fileName]?.append(doc)
            }
        }
        // For each filename, keep only the most recent document
        var deduplicated: [JobDocument] = []
        for (_, docs) in fileNameMap {
            if docs.count > 1 {
                // Sort by last modified date (newest first) and take the first one
                if let newest = docs.sorted(by: { $0.lastModifiedDate > $1.lastModifiedDate }).first {
                    deduplicated.append(newest)
                }
            } else if let doc = docs.first {
                deduplicated.append(doc)
            }
        }
        documents = deduplicated
        saveDocuments()
    }
    /// Merges a set of new documents into our store, ignoring duplicates.
    func mergeDocuments(_ newDocs: [JobDocument]) {
        for doc in newDocs {
            if !documents.contains(where: { $0.id == doc.id }) {
                documents.append(doc)
            }
        }
        saveDocuments()
        deduplicateDocuments()
    }
    // Save & Load Documents
    func saveDocuments() {
        saveToSwiftData()
        let docsArray = documents.map { $0.toDictionary() } // Keep UserDefaults backup for now
        if let jsonData = try? JSONSerialization.data(withJSONObject: docsArray, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            UserDefaults.standard.set(jsonString, forKey: Constants.documentsKey)
        }
    }
    func loadDocuments() {
        // First try SwiftData
        let descriptor = FetchDescriptor<SwiftDataJobDocument>()
        do {
            let swiftDataDocs = try modelContext.fetch(descriptor)
            if !swiftDataDocs.isEmpty {
                documents = SwiftDataJobDocument.toJobDocuments(from: swiftDataDocs)
                deduplicateDocuments()
                return
            }
            // Fallback to UserDefaults if SwiftData is empty
            loadFromUserDefaults()
            saveToSwiftData() // Migrate to SwiftData on first load from UserDefaults
        } catch {
            print("SwiftData fetch failed: \(error)")
            loadFromUserDefaults()
        }
    }
    private func saveToSwiftData() {
        do {
            // Correctly delete existing documents: fetch them first, then delete them individually
            let descriptor = FetchDescriptor<SwiftDataJobDocument>()
            let existingDocs = try modelContext.fetch(descriptor)
            for doc in existingDocs {
                modelContext.delete(doc)
            }
            
            // Now insert our documents
            for doc in documents {
                let sdDoc = SwiftDataJobDocument(
                    id: doc.id,
                    fileName: doc.fileName,
                    fileData: doc.fileData,
                    fileURL: doc.fileURL,
                    creation: doc.creationDate,
                    lastModified: doc.lastModifiedDate,
                    fileSize: doc.fileSize,
                    wordCount: doc.wordCount,
                    categoryID: doc.categoryID,
                    associatedCompany: doc.associatedCompany,
                    associatedJobTitle: doc.associatedJobTitle,
                    associatedApplicationDate: doc.associatedApplicationDate
                )
                modelContext.insert(sdDoc)
            }
            try modelContext.save()
        } catch {
            print("SwiftData document save failed: \(error)")
        }
    }
    // Categories
    func saveCategories() {
        let catsArray = categories.map {
            [
                "id": $0.id.uuidString,
                "name": $0.name,
                "isExpanded": $0.isExpanded
            ] as [String: Any]
        }
        if let jsonData = try? JSONSerialization.data(withJSONObject: catsArray, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            UserDefaults.standard.set(jsonString, forKey: Constants.documentCategoriesKey)
        }
    }
    func loadCategories() {
        guard let jsonString = UserDefaults.standard.string(forKey: Constants.documentCategoriesKey),
              let jsonData = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
              let catsArray = jsonObject as? [[String: Any]]
        else {
            return
        }
        var loadedCats: [DocumentCategory] = []
        for dict in catsArray {
            if let idStr = dict["id"] as? String,
               let id = UUID(uuidString: idStr),
               let name = dict["name"] as? String,
               let isExpanded = dict["isExpanded"] as? Bool {
                var cat = DocumentCategory(id: id, name: name)
                cat.isExpanded = isExpanded
                loadedCats.append(cat)
            }
        }
        categories = loadedCats
    }
    func createNewCategory(name: String) {
        guard !name.isEmpty else { return }
        let newCat = DocumentCategory(name: name)
        categories.append(newCat)
        saveCategories()
    }
    func assignDocument(_ doc: JobDocument, to category: DocumentCategory) {
        if let idx = documents.firstIndex(where: { $0.id == doc.id }) {
            documents[idx].categoryID = category.id
            saveDocuments()
        }
    }
    func unassignDocument(_ doc: JobDocument) {
        if let idx = documents.firstIndex(where: { $0.id == doc.id }) {
            documents[idx].categoryID = nil
            saveDocuments()
        }
    }
    func beginEditMetadata(for doc: JobDocument) {
        self.documentToEdit = doc
        self.isEditingMetadata = true
    }
    // Move/copy documents into Application Support
    static func saveDocumentToAppSupport(originalURL: URL, fileName: String) -> URL? {
        guard let appSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first else {
            return nil
        }
        let documentsDirectory = appSupportURL.appendingPathComponent("Documents", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
        } catch {
            print("Failed to create Documents directory: \(error)")
            return nil
        }
        let uniqueFileName = UUID().uuidString + "_" + fileName
        let destinationURL = documentsDirectory.appendingPathComponent(uniqueFileName)
        do {
            try FileManager.default.copyItem(at: originalURL, to: destinationURL)
            return destinationURL
        } catch {
            print("Failed to copy file to Documents directory: \(error)")
            return nil
        }
    }
    // Memory Management - Get cached PDF document or create one
    func getPDFDocument(for document: JobDocument) -> PDFDocument? {
        // Check if we have a cached version
        if let cachedPDF = cachedPDFDocuments[document.id] {
            return cachedPDF
        }
        // Create a new PDF document
        let pdfDoc = PDFDocument(data: document.fileData)
        // Cache it for future use
        if let pdfDoc = pdfDoc {
            cachedPDFDocuments[document.id] = pdfDoc
            // Clear cache if it gets too large (over 10 items)
            if cachedPDFDocuments.count > 10 {
                // Keep the 5 most recently accessed items
                let recentDocIDs = Array(cachedPDFDocuments.keys.suffix(5))
                cachedPDFDocuments = cachedPDFDocuments.filter { recentDocIDs.contains($0.key) }
            }
        }
        return pdfDoc
    }
    // Memory Management - Clear caches
    func clearCaches() {
        cachedPDFDocuments.removeAll()
    }
}

//-----------------------------------------------------------------------------------------------------//



