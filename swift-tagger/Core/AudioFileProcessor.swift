import Foundation

public class AudioFileProcessor {
    
    public init() {}
    
    public func processDirectorySync(_ directoryURL: URL, bookId: String, logger: @escaping (String) -> Void) -> ProcessingResults {
        
        var filesRenamed = 0
        var tagsUpdated = 0
        var errors = 0
        
        do {
            // Find MP3 files
            let mp3Files = try findMP3Files(in: directoryURL)
            
            if mp3Files.isEmpty {
                logger("No numbered MP3 files found (looking for files starting with numbers like 1.mp3, 001_title.mp3, etc.)")
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
                
                // Check filename pattern for track number (supports 1.mp3, 01.mp3, 001.mp3, 001_title.mp3, etc.)
                if let range = nameWithoutExtension.range(of: "^(\\d+)", options: .regularExpression) {
                    let numberPart = String(nameWithoutExtension[range])
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
    
    private func findPythonScript() -> URL? {
        let scriptName = "update-mp3-tags.py"
        
        let candidatePaths = [
            URL(fileURLWithPath: Bundle.main.bundlePath)
                .deletingLastPathComponent()
                .appendingPathComponent(scriptName),
            
            URL(fileURLWithPath: #file)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent(scriptName),
            
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(scriptName)
        ]
        
        for path in candidatePaths {
            if FileManager.default.fileExists(atPath: path.path) {
                return path
            }
        }
        
        return nil
    }
    
    private func readExistingTags(from fileURL: URL) -> (trackNumber: Int?, album: String?, title: String?) {
        guard let scriptPath = findPythonScript() else {
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
        
        guard let scriptPath = findPythonScript() else {
            logger("⚠️ Tag update script not found: update-mp3-tags.py")
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
