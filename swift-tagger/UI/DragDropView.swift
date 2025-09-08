import Cocoa

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
