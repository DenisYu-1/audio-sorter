import Cocoa

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
        
        let selectButton = NSButton(title: "Choose Folder...", target: self, action: #selector(selectFolder))
        selectButton.frame = NSRect(x: 450, y: 310, width: 120, height: 30)
        view.addSubview(selectButton)
        
        // Book ID section
        let bookIdSectionLabel = NSTextField(labelWithString: "Book/Album Name (Optional):")
        bookIdSectionLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        bookIdSectionLabel.frame = NSRect(x: 30, y: 270, width: 200, height: 20)
        view.addSubview(bookIdSectionLabel)
        
        bookIdField = NSTextField(string: "AudioBook")
        bookIdField.frame = NSRect(x: 30, y: 245, width: 200, height: 25)
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
        logTextView.textColor = .labelColor
        logTextView.backgroundColor = .controlBackgroundColor
        
        scrollView.documentView = logTextView
        view.addSubview(scrollView)
        
        // Set book ID from field
        bookId = bookIdField.stringValue
        updateProcessButtonState()
        
        addLogMessage("Welcome! Drag a folder with numbered MP3 files or click 'Choose Folder...'")
    }
    
    @objc private func selectFolder() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.prompt = "Select Music Folder"
        openPanel.message = "Choose a folder containing numbered MP3 files (e.g., 001_track.mp3)"
        
        if openPanel.runModal() == .OK {
            if let url = openPanel.url {
                selectedFolderURL = url
                folderLabel.stringValue = url.path
                updateProcessButtonState()
                addLogMessage("📁 Folder selected: \(url.lastPathComponent)")
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
        guard let directoryURL = selectedFolderURL else {
            addLogMessage("❌ No folder selected")
            return
        }
        
        if bookId.isEmpty {
            addLogMessage("❌ Please enter a book/album name")
            return
        }
        
        // Disable UI during processing
        processButton.isEnabled = false
        progressIndicator.isHidden = false
        progressIndicator.startAnimation(nil)
        
        addLogMessage("🚀 Starting processing...")
        addLogMessage("📂 Directory: \(directoryURL.path)")
        addLogMessage("📚 Book ID: '\(bookId)'")
        addLogMessage("")
        
        // Process in background
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let processor = AudioFileProcessor()
            let results = processor.processDirectorySync(directoryURL, bookId: self.bookId) { [weak self] message in
                DispatchQueue.main.async {
                    self?.addLogMessage(message)
                }
            }
            
            DispatchQueue.main.async {
                // Re-enable UI
                self.progressIndicator.stopAnimation(nil)
                self.progressIndicator.isHidden = true
                self.updateProcessButtonState()
                
                // Show summary
                self.addLogMessage("")
                self.addLogMessage("📊 Processing Summary:")
                self.addLogMessage("   • Files renamed: \(results.filesRenamed)")
                self.addLogMessage("   • Tags updated: \(results.tagsUpdated)")
                if results.errors > 0 {
                    self.addLogMessage("   • Errors: \(results.errors)")
                }
                self.addLogMessage("✅ Processing complete!")
                
                // Auto-scroll to bottom
                self.logTextView.scrollToEndOfDocument(nil)
            }
        }
    }
    
    private func addLogMessage(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let timestamp = DateFormatter.timeFormatter.string(from: Date())
            let logEntry = "[\(timestamp)] \(message)\n"
            
            self.logTextView.textStorage?.append(NSAttributedString(string: logEntry))
            self.logTextView.scrollToEndOfDocument(nil)
        }
    }
}

// MARK: - MainViewController + DragDropViewDelegate
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

// MARK: - DateFormatter Extension
private extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}
