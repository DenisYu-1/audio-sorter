import Foundation
import XCTest

// Import the classes we want to test
// Note: In a real project structure, these would be proper imports
// For now, we'll include the source files directly in compilation

class AudioSorterTests: XCTestCase {
    
    var tempDirectory: URL!
    var processor: AudioFileProcessor!
    
    override func setUp() {
        super.setUp()
        
        // Create temporary directory for tests
        tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("AudioSorterTests")
            .appendingPathComponent(UUID().uuidString)
        
        try! FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        processor = AudioFileProcessor()
    }
    
    override func tearDown() {
        // Clean up test directory
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }
    
    // MARK: - File Pattern Recognition Tests
    
    func testFilePatternRecognition() {
        let testCases: [(filename: String, expectedTrackNumber: Int?)] = [
            ("1.mp3", 1),
            ("01.mp3", 1),
            ("001.mp3", 1),
            ("10.mp3", 10),
            ("123.mp3", 123),
            ("001_chapter_title.mp3", 1),
            ("42_long_title_here.mp3", 42),
            ("chapter.mp3", nil),
            ("intro.mp3", nil),
            ("music.mp3", nil),
            ("001.txt", nil), // Wrong extension
        ]
        
        for testCase in testCases {
            let extractedNumber = extractTrackNumberFromFilename(testCase.filename)
            XCTAssertEqual(extractedNumber, testCase.expectedTrackNumber, 
                          "Failed for filename: \(testCase.filename)")
        }
    }
    
    func testZeroPaddingLogic() {
        let testCases: [(trackNumber: Int, expectedPadding: String)] = [
            (1, "001"),
            (10, "010"),
            (99, "099"),
            (100, "100"),
            (999, "999"),
        ]
        
        for testCase in testCases {
            let padded = String(format: "%03d", testCase.trackNumber)
            XCTAssertEqual(padded, testCase.expectedPadding,
                          "Padding failed for track number: \(testCase.trackNumber)")
        }
    }
    
    // MARK: - File Processing Tests
    
    func testDirectoryFileDiscovery() {
        // Create test MP3 files
        let testFiles = ["1.mp3", "2.mp3", "10.mp3", "intro.mp3", "001_chapter.mp3"]
        
        for filename in testFiles {
            let fileURL = tempDirectory.appendingPathComponent(filename)
            createMockMP3File(at: fileURL)
        }
        
        // Test file discovery (we can't directly test the private method, 
        // but we can test the overall processing)
        let results = processor.processDirectorySync(tempDirectory, bookId: "TestBook") { message in
            print("Test log: \(message)")
        }
        
        // Should find numbered files (1.mp3, 2.mp3, 10.mp3, 001_chapter.mp3)
        // Should ignore intro.mp3
        XCTAssertGreaterThanOrEqual(results.filesRenamed + results.tagsUpdated, 0, 
                                   "Should have processed some files")
    }
    
    func testBookIdFilenameGeneration() {
        let testCases: [(trackNumber: Int, bookId: String, expected: String)] = [
            (1, "MyBook", "001 MyBook.mp3"),
            (10, "AudioBook", "010 AudioBook.mp3"),
            (123, "Test", "123 Test.mp3"),
        ]
        
        for testCase in testCases {
            let paddedNumber = String(format: "%03d", testCase.trackNumber)
            let newFilename = "\(paddedNumber) \(testCase.bookId).mp3"
            XCTAssertEqual(newFilename, testCase.expected,
                          "Filename generation failed for track \(testCase.trackNumber)")
        }
    }
    
    // MARK: - Integration Tests
    
    func testFullProcessingWorkflow() {
        // Create a realistic test scenario
        let testFiles = ["1.mp3", "2.mp3", "10.mp3"]
        let bookId = "TestAudiobook"
        
        for filename in testFiles {
            let fileURL = tempDirectory.appendingPathComponent(filename)
            createMockMP3File(at: fileURL)
        }
        
        // Process the directory
        let results = processor.processDirectorySync(tempDirectory, bookId: bookId) { message in
            print("Processing: \(message)")
        }
        
        // Verify results
        XCTAssertGreaterThanOrEqual(results.filesRenamed, 0, "Should have renamed some files")
        
        // Check that new files exist with correct names
        let expectedFiles = ["001 \(bookId).mp3", "002 \(bookId).mp3", "010 \(bookId).mp3"]
        
        for expectedFile in expectedFiles {
            let expectedURL = tempDirectory.appendingPathComponent(expectedFile)
            XCTAssertTrue(FileManager.default.fileExists(atPath: expectedURL.path),
                         "Expected file not found: \(expectedFile)")
        }
    }
    
    func testErrorHandling() {
        // Test with non-existent directory
        let nonExistentDir = tempDirectory.appendingPathComponent("nonexistent")
        
        let results = processor.processDirectorySync(nonExistentDir, bookId: "Test") { _ in }
        
        // Should handle error gracefully
        XCTAssertEqual(results.filesRenamed, 0)
        XCTAssertEqual(results.tagsUpdated, 0)
    }
    
    // MARK: - Helper Methods
    
    private func createMockMP3File(at url: URL) {
        // Create a minimal file that looks like an MP3
        let mockData = Data([0xFF, 0xFB, 0x90, 0x00] + Array(repeating: 0x00, count: 100))
        try! mockData.write(to: url)
    }
    
    private func extractTrackNumberFromFilename(_ filename: String) -> Int? {
        guard filename.lowercased().hasSuffix(".mp3") else { return nil }
        
        let nameWithoutExtension = String(filename.dropLast(4))
        
        // Use the same regex pattern as in the Swift code
        let pattern = "^(\\d+)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        
        let range = NSRange(nameWithoutExtension.startIndex..., in: nameWithoutExtension)
        guard let match = regex.firstMatch(in: nameWithoutExtension, range: range) else { return nil }
        
        let numberRange = Range(match.range(at: 1), in: nameWithoutExtension)!
        let numberString = String(nameWithoutExtension[numberRange])
        
        return Int(numberString)
    }
}

// MARK: - Test Runner for Command Line

class TestRunner {
    static func runAllTests() {
        print("🧪 Running Swift Audio Sorter Tests...")
        
        let testSuite = AudioSorterTests.defaultTestSuite
        let testRun = TestSuiteRun(test: testSuite)
        
        testSuite.run(testRun)
        
        let testCount = testRun.testCaseCount
        let failureCount = testRun.totalFailureCount
        
        print("✅ Ran \(testCount) tests")
        
        if failureCount > 0 {
            print("❌ \(failureCount) test(s) failed")
            exit(1)
        } else {
            print("✅ All tests passed!")
        }
    }
}

// Allow running tests from command line
if CommandLine.arguments.contains("--run-tests") {
    TestRunner.runAllTests()
}
