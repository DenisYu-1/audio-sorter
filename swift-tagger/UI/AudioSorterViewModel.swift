import SwiftUI
import AudioSorterCore
import AppKit

struct LogMessage: Identifiable {
    let id = UUID()
    let text: String
    let timestamp: Date
}

@MainActor
class AudioSorterViewModel: ObservableObject {
    @Published var selectedFolderURL: URL?
    @Published var bookId: String = "AudioBook"
    @Published var logMessages: [LogMessage] = []
    @Published var isProcessing: Bool = false
    @Published var isDragOver: Bool = false
    
    var selectedFolderPath: String? {
        selectedFolderURL?.path
    }
    
    var canProcess: Bool {
        selectedFolderURL != nil && !bookId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    init() {
        addLogMessage("Welcome! Drag a folder with numbered MP3 files or click 'Choose Folder...'")
    }
    
    func selectFolder() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.prompt = "Select Music Folder"
        openPanel.message = "Choose a folder containing numbered MP3 files (e.g., 1.mp3, 001_track.mp3)"
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            selectedFolderURL = url
            addLogMessage("📁 Folder selected: \(url.lastPathComponent)")
        }
    }
    
    func applyBookId() {
        let trimmedBookId = bookId.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedBookId.isEmpty {
            addLogMessage("📚 Book/Album name set to: '\(trimmedBookId)'")
        }
    }
    
    func handleDrop(_ urls: [URL]) {
        guard let url = urls.first else { return }
        
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            addLogMessage("⚠️ Please drop a folder, not a file")
            return
        }
        
        selectedFolderURL = url
        addLogMessage("📁 Folder dropped: \(url.lastPathComponent)")
    }
    
    func processAudioFiles() {
        guard let directoryURL = selectedFolderURL else {
            addLogMessage("❌ No folder selected")
            return
        }
        
        let trimmedBookId = bookId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBookId.isEmpty else {
            addLogMessage("❌ Please enter a book/album name")
            return
        }
        
        isProcessing = true
        addLogMessage("🚀 Starting processing...")
        addLogMessage("📂 Directory: \(directoryURL.path)")
        addLogMessage("📚 Book ID: '\(trimmedBookId)'")
        addLogMessage("")
        
        Task.detached(priority: .userInitiated) { @MainActor [weak self] in
            guard let self else { return }
            
            let processor = AudioFileProcessor()
            let results = processor.processDirectorySync(directoryURL, bookId: trimmedBookId) { message in
                Task { @MainActor [weak self] in
                    self?.addLogMessage(message)
                }
            }
            
            self.isProcessing = false
            
            self.addLogMessage("")
            self.addLogMessage("📊 Processing Summary:")
            self.addLogMessage("   • Files renamed: \(results.filesRenamed)")
            self.addLogMessage("   • Tags updated: \(results.tagsUpdated)")
            if results.errors > 0 {
                self.addLogMessage("   • Errors: \(results.errors)")
            }
            self.addLogMessage("✅ Processing complete!")
        }
    }
    
    func addLogMessage(_ message: String) {
        let timestamp = Date()
        let timeString = DateFormatter.timeFormatter.string(from: timestamp)
        let logEntry = LogMessage(
            text: "[\(timeString)] \(message)",
            timestamp: timestamp
        )
        logMessages.append(logEntry)
    }
}

private extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}

