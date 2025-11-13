import XCTest
@testable import AudioSorterCore

final class AudioFileProcessorTests: XCTestCase {
    
    var processor: AudioFileProcessor!
    var tempDirectory: URL!
    
    override func setUp() {
        super.setUp()
        processor = AudioFileProcessor()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        tempDirectory = nil
        processor = nil
        super.tearDown()
    }
    
    func testProcessingResultsStructure() {
        let results = ProcessingResults(filesRenamed: 5, tagsUpdated: 3, errors: 1)
        
        XCTAssertEqual(results.filesRenamed, 5)
        XCTAssertEqual(results.tagsUpdated, 3)
        XCTAssertEqual(results.errors, 1)
    }
    
    func testEmptyDirectoryReturnsZeroResults() {
        let results = processor.processDirectorySync(tempDirectory, bookId: "TestBook") { _ in }
        
        XCTAssertEqual(results.filesRenamed, 0)
        XCTAssertEqual(results.tagsUpdated, 0)
        XCTAssertEqual(results.errors, 0)
    }
    
    func testFindsMP3FilesWithNumericNames() throws {
        let testFiles = ["1.mp3", "2.mp3", "10.mp3", "25.mp3"]
        
        for filename in testFiles {
            let fileURL = tempDirectory.appendingPathComponent(filename)
            try createMinimalMP3(at: fileURL)
        }
        
        var loggedMessages: [String] = []
        _ = processor.processDirectorySync(tempDirectory, bookId: "TestBook") { message in
            loggedMessages.append(message)
        }
        
        XCTAssertGreaterThan(loggedMessages.count, 0, "Should log processing information")
        let foundFilesMessage = loggedMessages.first { $0.contains("Found") && $0.contains("MP3 files") }
        XCTAssertNotNil(foundFilesMessage, "Should report found files")
    }
    
    func testIgnoresNonMP3Files() throws {
        try createMinimalMP3(at: tempDirectory.appendingPathComponent("1.mp3"))
        
        let textFile = tempDirectory.appendingPathComponent("readme.txt")
        try "Some text".write(to: textFile, atomically: true, encoding: .utf8)
        
        let wavFile = tempDirectory.appendingPathComponent("2.wav")
        try createMinimalMP3(at: wavFile)
        
        var loggedMessages: [String] = []
        _ = processor.processDirectorySync(tempDirectory, bookId: "TestBook") { message in
            loggedMessages.append(message)
        }
        
        let foundFilesMessage = loggedMessages.first { $0.contains("Found") && $0.contains("MP3 files") }
        XCTAssertTrue(foundFilesMessage?.contains("1 numbered MP3") ?? false, "Should find only 1 MP3 file")
    }
    
    func testIgnoresFilesWithoutNumericPrefix() throws {
        try createMinimalMP3(at: tempDirectory.appendingPathComponent("song.mp3"))
        try createMinimalMP3(at: tempDirectory.appendingPathComponent("track.mp3"))
        try createMinimalMP3(at: tempDirectory.appendingPathComponent("1.mp3"))
        
        var loggedMessages: [String] = []
        _ = processor.processDirectorySync(tempDirectory, bookId: "TestBook") { message in
            loggedMessages.append(message)
        }
        
        let foundFilesMessage = loggedMessages.first { $0.contains("Found") && $0.contains("MP3 files") }
        XCTAssertTrue(foundFilesMessage?.contains("1 numbered MP3") ?? false, "Should find only files with numeric prefix")
    }
    
    func testFileRenamingWithPadding() throws {
        let testCases: [(input: String, expected: String)] = [
            ("1.mp3", "001 TestBook.mp3"),
            ("2.mp3", "002 TestBook.mp3"),
            ("10.mp3", "010 TestBook.mp3"),
            ("25.mp3", "025 TestBook.mp3"),
            ("100.mp3", "100 TestBook.mp3")
        ]
        
        for (input, expected) in testCases {
            let fileURL = tempDirectory.appendingPathComponent(input)
            try createMinimalMP3(at: fileURL)
            
            _ = processor.processDirectorySync(tempDirectory, bookId: "TestBook") { _ in }
            
            let expectedURL = tempDirectory.appendingPathComponent(expected)
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: expectedURL.path),
                "\(input) should be renamed to \(expected)"
            )
            
            try? FileManager.default.removeItem(at: expectedURL)
        }
    }
    
    func testCorrectFilenameDoesNotRename() throws {
        let correctFilename = "005 TestBook.mp3"
        let fileURL = tempDirectory.appendingPathComponent(correctFilename)
        try createMinimalMP3(at: fileURL)
        
        var loggedMessages: [String] = []
        let results = processor.processDirectorySync(tempDirectory, bookId: "TestBook") { message in
            loggedMessages.append(message)
        }
        
        XCTAssertEqual(results.filesRenamed, 0, "Should not rename already correct filename")
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path), "Original file should still exist")
        
        let foundFilesMessage = loggedMessages.first { $0.contains("Found") && $0.contains("MP3") }
        XCTAssertNotNil(foundFilesMessage, "Should find and process the file")
    }
    
    private func createMinimalMP3(at url: URL) throws {
        let id3v2Header = Data([0x49, 0x44, 0x33, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        let mp3Frame = Data([0xff, 0xfb, 0x90, 0x44]) + Data(repeating: 0x00, count: 412)
        let mp3Data = id3v2Header + mp3Frame
        
        try mp3Data.write(to: url)
    }
}

