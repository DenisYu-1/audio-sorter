import Cocoa
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        createMainWindow()
    }
    
    func createMainWindow() {
        // Create window
        window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 600, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Audio Sorter"
        window.center()
        
        // Create main view
        let mainView = MainViewController()
        window.contentViewController = mainView
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

class MainViewController: NSViewController {
    private var folderLabel: NSTextField!
    private var bookIdField: NSTextField!
    private var logTextView: NSTextView!
    private var processButton: NSButton!
    private var progressIndicator: NSProgressIndicator!
    
    private var selectedFolderURL: URL?
    private var bookId: String = ""
    
    override func loadView() {
        view = DragDropView(frame: NSRect(x: 0, y: 0, width: 600, height: 500))
        (view as! DragDropView).delegate = self
        setupUI()
    }
    
    private func setupUI() {
        // Header
        let headerLabel = NSTextField(labelWithString: "🎵 Audio Sorter")
        headerLabel.font = NSFont.systemFont(ofSize: 24, weight: .bold)
        headerLabel.alignment = .center
        headerLabel.frame = NSRect(x: 50, y: 430, width: 500, height: 40)
        view.addSubview(headerLabel)
        
        let subtitleLabel = NSTextField(labelWithString: "Rename numbered audio files: 001_...mp3 → 001 <Book ID>.mp3")
        subtitleLabel.font = NSFont.systemFont(ofSize: 12)
        subtitleLabel.alignment = .center
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.frame = NSRect(x: 50, y: 405, width: 500, height: 20)
        view.addSubview(subtitleLabel)
        
        let dragLabel = NSTextField(labelWithString: "💡 Drag a music folder here or use the button below")
        dragLabel.font = NSFont.systemFont(ofSize: 11)
        dragLabel.alignment = .center
        dragLabel.textColor = .tertiaryLabelColor
        dragLabel.frame = NSRect(x: 50, y: 385, width: 500, height: 15)
        view.addSubview(dragLabel)
        
        // Folder selection
        let folderSectionLabel = NSTextField(labelWithString: "Select Music Folder:")
        folderSectionLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        folderSectionLabel.frame = NSRect(x: 30, y: 340, width: 200, height: 20)
        view.addSubview(folderSectionLabel)
        
        folderLabel = NSTextField(labelWithString: "No folder selected")
        folderLabel.font = NSFont.systemFont(ofSize: 12)
        folderLabel.textColor = .secondaryLabelColor
        folderLabel.frame = NSRect(x: 30, y: 315, width: 400, height: 20)
        view.addSubview(folderLabel)
        
        let chooseButton = NSButton(title: "Choose Folder", target: self, action: #selector(chooseFolderAction))
        chooseButton.frame = NSRect(x: 450, y: 310, width: 120, height: 30)
        view.addSubview(chooseButton)
        
        // Book ID input
        let bookIdLabel = NSTextField(labelWithString: "Book ID:")
        bookIdLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        bookIdLabel.frame = NSRect(x: 30, y: 275, width: 80, height: 20)
        view.addSubview(bookIdLabel)
        
        bookIdField = NSTextField()
        bookIdField.placeholderString = "Enter book identifier"
        bookIdField.font = NSFont.systemFont(ofSize: 12)
        bookIdField.frame = NSRect(x: 120, y: 270, width: 300, height: 25)
        bookIdField.target = self
        bookIdField.action = #selector(bookIdChanged)
        view.addSubview(bookIdField)
        
        // Options info
        let optionsLabel = NSTextField(labelWithString: "What this app does:")
        optionsLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        optionsLabel.frame = NSRect(x: 30, y: 230, width: 200, height: 20)
        view.addSubview(optionsLabel)
        
        let option1 = NSTextField(labelWithString: "✓ Finds files starting with track numbers (001_, 002_, etc.)")
        option1.font = NSFont.systemFont(ofSize: 12)
        option1.frame = NSRect(x: 50, y: 205, width: 400, height: 20)
        view.addSubview(option1)
        
        let option2 = NSTextField(labelWithString: "✓ Renames to clean format: '001 Book Title.mp3'")
        option2.font = NSFont.systemFont(ofSize: 12)
        option2.frame = NSRect(x: 50, y: 180, width: 350, height: 20)
        view.addSubview(option2)
        
        let option3 = NSTextField(labelWithString: "✓ Updates MP3 track numbers using Music app")
        option3.font = NSFont.systemFont(ofSize: 12)
        option3.frame = NSRect(x: 50, y: 155, width: 350, height: 20)
        view.addSubview(option3)
        
        // Process button
        processButton = NSButton(title: "Sort Audio Files", target: self, action: #selector(processAction))
        processButton.frame = NSRect(x: 250, y: 120, width: 120, height: 30)
        processButton.isEnabled = false
        view.addSubview(processButton)
        
        // Progress indicator
        progressIndicator = NSProgressIndicator(frame: NSRect(x: 380, y: 125, width: 20, height: 20))
        progressIndicator.style = .spinning
        progressIndicator.isHidden = true
        view.addSubview(progressIndicator)
        
        // Log text view
        let logLabel = NSTextField(labelWithString: "Log:")
        logLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        logLabel.frame = NSRect(x: 30, y: 80, width: 100, height: 20)
        view.addSubview(logLabel)
        
        let scrollView = NSScrollView(frame: NSRect(x: 30, y: 30, width: 540, height: 45))
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = false
        
        logTextView = NSTextView(frame: scrollView.contentView.bounds)
        logTextView.isEditable = false
        logTextView.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        scrollView.documentView = logTextView
        
        view.addSubview(scrollView)
        
        // Footer
        let footerLabel = NSTextField(labelWithString: "Drag this app to other Macs - no installation required!")
        footerLabel.font = NSFont.systemFont(ofSize: 10)
        footerLabel.alignment = .center
        footerLabel.textColor = .tertiaryLabelColor
        footerLabel.frame = NSRect(x: 50, y: 5, width: 500, height: 15)
        view.addSubview(footerLabel)
    }
    
    @objc private func chooseFolderAction() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.prompt = "Select Folder"
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                self.selectedFolderURL = url
                self.folderLabel.stringValue = url.path
                self.updateProcessButtonState()
                self.addLogMessage("Selected folder: \(url.lastPathComponent)")
            }
        }
    }
    
    @objc private func bookIdChanged() {
        bookId = bookIdField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        updateProcessButtonState()
    }
    
    private func updateProcessButtonState() {
        processButton.isEnabled = selectedFolderURL != nil && !bookId.isEmpty
    }
    
    @objc private func processAction() {
        guard let folderURL = selectedFolderURL else { return }
        
        processButton.isEnabled = false
        progressIndicator.isHidden = false
        progressIndicator.startAnimation(nil)
        
        addLogMessage("Starting audio file processing...")
        addLogMessage("Scanning: \(folderURL.path)")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let processor = AudioFileProcessor()
            let result = processor.processDirectorySync(folderURL, bookId: self.bookId) { message in
                DispatchQueue.main.async {
                    self.addLogMessage(message)
                }
            }
            
            DispatchQueue.main.async {
                self.processButton.isEnabled = true
                self.progressIndicator.stopAnimation(nil)
                self.progressIndicator.isHidden = true
                
                if result.filesRenamed > 0 {
                    self.addLogMessage("✅ Processing complete!")
                    self.addLogMessage("Files renamed: \(result.filesRenamed), Tags updated: \(result.tagsUpdated)")
                } else {
                    self.addLogMessage("ℹ️ No files needed processing")
                }
                
                if result.errors > 0 {
                    self.addLogMessage("⚠️ \(result.errors) errors occurred")
                }
            }
        }
    }
    
    private func addLogMessage(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)\n"
        
        logTextView.textStorage?.append(NSAttributedString(string: logMessage))
        logTextView.scrollToEndOfDocument(nil)
    }
}

struct ProcessingResults {
    let filesRenamed: Int
    let tagsUpdated: Int
    let errors: Int
}

class AudioFileProcessor {
    
    func processDirectorySync(_ directoryURL: URL, bookId: String, logger: @escaping (String) -> Void) -> ProcessingResults {
        
        var filesRenamed = 0
        var tagsUpdated = 0
        var errors = 0
        
        do {
            // Find MP3 files
            let mp3Files = try findMP3Files(in: directoryURL)
            
            if mp3Files.isEmpty {
                logger("No numbered MP3 files found (looking for files starting with numbers like 001_...)")
                return ProcessingResults(filesRenamed: 0, tagsUpdated: 0, errors: 0)
            }
            
            logger("Found \(mp3Files.count) numbered MP3 files")
            
            // Process each file
            for (fileURL, trackNumber) in mp3Files {
                let filename = fileURL.lastPathComponent
                let tagInfo = readExistingTags(from: fileURL)
                
                // Log what we found
                var statusParts: [String] = []
                statusParts.append("Track \(trackNumber) from filename")
                if let tagTrack = tagInfo.trackNumber {
                    if tagTrack == trackNumber {
                        statusParts.append("tags match")
                    } else {
                        statusParts.append("tag shows \(tagTrack)")
                    }
                } else {
                    statusParts.append("no track in tags")
                }
                
                if let tagAlbum = tagInfo.album {
                    if tagAlbum == bookId {
                        statusParts.append("album correct")
                    } else {
                        statusParts.append("album: '\(tagAlbum)'")
                    }
                } else {
                    statusParts.append("no album")
                }
                
                logger("📋 \(filename): \(statusParts.joined(separator: ", "))")
                
                // Create new filename with book ID
                let paddedNumber = String(format: "%03d", trackNumber)
                let newFilename = "\(paddedNumber) \(bookId).mp3"
                let newURL = fileURL.deletingLastPathComponent().appendingPathComponent(newFilename)
                
                let needsRename = filename != newFilename
                let needsTagUpdate = tagInfo.trackNumber != trackNumber || tagInfo.album != bookId
                
                if !needsRename && !needsTagUpdate {
                    logger("✓ Already correct: \(filename)")
                    continue
                }
                
                // Rename file if needed
                if needsRename {
                    do {
                        if FileManager.default.fileExists(atPath: newURL.path) {
                            // Remove existing file first, then move
                            try FileManager.default.removeItem(at: newURL)
                            logger("✓ Replaced existing: \(newFilename)")
                        }
                        try FileManager.default.moveItem(at: fileURL, to: newURL)
                        logger("✓ Renamed: \(filename) → \(newFilename)")
                        filesRenamed += 1
                    } catch {
                        logger("✗ Failed to rename \(filename): \(error.localizedDescription)")
                        errors += 1
                        continue
                    }
                }
                
                // Update tags (always check, even if file wasn't renamed)
                let fileToUpdate = needsRename ? newURL : fileURL
                if needsTagUpdate {
                    if updateTrackNumberSync(for: fileToUpdate, trackNumber: trackNumber, bookId: bookId, logger: logger) {
                        tagsUpdated += 1
                    }
                } else {
                    logger("✓ Tags already correct: \(fileToUpdate.lastPathComponent)")
                }
            }
            
        } catch {
            logger("Error processing directory: \(error.localizedDescription)")
            errors += 1
        }
        
        return ProcessingResults(filesRenamed: filesRenamed, tagsUpdated: tagsUpdated, errors: errors)
    }
    
    private func findMP3Files(in directoryURL: URL) throws -> [(URL, Int)] {
        let contents = try FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        )
        
        var mp3Files: [(URL, Int)] = []
        
        for fileURL in contents {
            let filename = fileURL.lastPathComponent
            
            if filename.lowercased().hasSuffix(".mp3") {
                let nameWithoutExtension = String(filename.dropLast(4))
                var trackNumberFromName: Int? = nil
                
                // Check filename pattern for track number
                if nameWithoutExtension.range(of: "^(\\d{3})([_ ].*)?$", options: .regularExpression) != nil {
                    let numberPart = String(nameWithoutExtension[nameWithoutExtension.startIndex..<nameWithoutExtension.index(nameWithoutExtension.startIndex, offsetBy: 3)])
                    trackNumberFromName = Int(numberPart)
                }
                
                // Read existing tags to get track number
                let tagInfo = readExistingTags(from: fileURL)
                
                // Decide which track number to use
                let finalTrackNumber: Int?
                if let nameTrack = trackNumberFromName {
                    // Prefer filename track number as source of truth
                    finalTrackNumber = nameTrack
                } else if let tagTrack = tagInfo.trackNumber {
                    // Fallback to tag track number if filename doesn't contain one
                    finalTrackNumber = tagTrack
                } else {
                    // No track number found in either place
                    finalTrackNumber = nil
                }
                
                if let trackNumber = finalTrackNumber {
                    mp3Files.append((fileURL, trackNumber))
                }
            }
        }
        
        return mp3Files.sorted { $0.1 < $1.1 }
    }
    
    private func readExistingTags(from fileURL: URL) -> (trackNumber: Int?, album: String?, title: String?) {
        // Get the Python script path
        let bundlePath = Bundle.main.bundlePath
        let scriptPath = URL(fileURLWithPath: bundlePath)
            .deletingLastPathComponent()
            .appendingPathComponent("update-mp3-tags.py")
        
        guard FileManager.default.fileExists(atPath: scriptPath.path) else {
            return (nil, nil, nil)
        }
        
        let process = Process()
        process.launchPath = "/usr/bin/python3"
        process.arguments = [scriptPath.path, fileURL.path, "--read-tags"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    return parseTagOutput(output)
                }
            }
        } catch {
            // Failed to read tags, return empty
        }
        
        return (nil, nil, nil)
    }
    
    private func parseTagOutput(_ output: String) -> (trackNumber: Int?, album: String?, title: String?) {
        var trackNumber: Int? = nil
        var album: String? = nil
        var title: String? = nil
        
        for line in output.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("Track: ") {
                let trackStr = String(trimmed.dropFirst(7))
                trackNumber = Int(trackStr)
            } else if trimmed.hasPrefix("Album: ") {
                album = String(trimmed.dropFirst(7))
            } else if trimmed.hasPrefix("Title: ") {
                title = String(trimmed.dropFirst(7))
            }
        }
        
        return (trackNumber, album, title)
    }
    
    private func updateTrackNumberSync(for fileURL: URL, trackNumber: Int, bookId: String, logger: @escaping (String) -> Void) -> Bool {
        
        // Get the directory where this app bundle is located
        let bundlePath = Bundle.main.bundlePath
        let scriptPath = URL(fileURLWithPath: bundlePath)
            .deletingLastPathComponent()
            .appendingPathComponent("update-mp3-tags.py")
        
        // Check if the Python script exists
        guard FileManager.default.fileExists(atPath: scriptPath.path) else {
            logger("⚠️ Tag update script not found: \(scriptPath.lastPathComponent)")
            return false
        }
        
        let process = Process()
        process.launchPath = "/usr/bin/python3"
        var arguments = [scriptPath.path, fileURL.path, "--track", String(trackNumber)]
        if !bookId.isEmpty {
            arguments.append("--album")
            arguments.append(bookId)
        }
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                logger("✓ Updated tags: \(fileURL.lastPathComponent) → Track #\(trackNumber)")
                return true
            } else {
                let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
                let errorOutput = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown error"
                logger("⚠️ Tag update failed: \(fileURL.lastPathComponent) - \(errorOutput)")
                return false
            }
        } catch {
            logger("⚠️ Tag update error: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - Drag and Drop Extension
extension MainViewController: DragDropViewDelegate {
    func dragDropView(_ view: DragDropView, didReceiveFileURL url: URL) {
        if url.hasDirectoryPath {
            selectedFolderURL = url
            folderLabel.stringValue = url.path
            updateProcessButtonState()
            addLogMessage("📁 Folder dropped: \(url.lastPathComponent)")
        } else {
            addLogMessage("⚠️ Please drop a folder, not a file")
        }
    }
}

// MARK: - Drag and Drop View
protocol DragDropViewDelegate: AnyObject {
    func dragDropView(_ view: DragDropView, didReceiveFileURL url: URL)
}

class DragDropView: NSView {
    weak var delegate: DragDropViewDelegate?
    private var isDragOver = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupDragAndDrop()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupDragAndDrop()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDragAndDrop()
    }
    
    private func setupDragAndDrop() {
        registerForDraggedTypes([.fileURL])
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Draw drop zone visual feedback
        if isDragOver {
            NSColor.controlAccentColor.withAlphaComponent(0.1).setFill()
            let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 10, dy: 10), xRadius: 8, yRadius: 8)
            path.fill()
            
            NSColor.controlAccentColor.withAlphaComponent(0.5).setStroke()
            path.lineWidth = 2
            path.stroke()
        }
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if canAcceptDrag(sender) {
            isDragOver = true
            needsDisplay = true
            return .copy
        }
        return []
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        isDragOver = false
        needsDisplay = true
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return canAcceptDrag(sender) ? .copy : []
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isDragOver = false
        needsDisplay = true
        
        guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
              let url = urls.first else {
            return false
        }
        
        delegate?.dragDropView(self, didReceiveFileURL: url)
        return true
    }
    
    private func canAcceptDrag(_ sender: NSDraggingInfo) -> Bool {
        guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
              let url = urls.first else {
            return false
        }
        
        // Accept directories only
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}

// Main entry point
let app = NSApplication.shared
app.setActivationPolicy(.regular) // Ensure it appears in Dock and can become active
let delegate = AppDelegate()
app.delegate = delegate
app.run()
