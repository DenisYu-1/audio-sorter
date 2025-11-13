import Foundation

public struct ProcessingResults {
    public let filesRenamed: Int
    public let tagsUpdated: Int
    public let errors: Int
    
    public init(filesRenamed: Int, tagsUpdated: Int, errors: Int) {
        self.filesRenamed = filesRenamed
        self.tagsUpdated = tagsUpdated
        self.errors = errors
    }
}
