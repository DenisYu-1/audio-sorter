import SwiftUI
import AudioSorterCore
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = AudioSorterViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            headerSection
            
            Divider()
            
            folderSelectionSection
            
            bookIdSection
            
            infoSection
            
            processButtonSection
            
            logSection
        }
        .padding(30)
        .background(DropTargetView(isTargeted: $viewModel.isDragOver) {
            viewModel.handleDrop($0)
        })
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("🎵 Audio Sorter")
                .font(.system(size: 24, weight: .bold))
            
            Text("Rename numbered audio files: 1.mp3 → 001 <Book ID>.mp3")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Text("💡 Drag a music folder here or use the button below")
                .font(.system(size: 11))
                .foregroundColor(Color(nsColor: .tertiaryLabelColor))
        }
    }
    
    private var folderSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Music Folder:")
                .font(.system(size: 14, weight: .medium))
            
            HStack {
                Text(viewModel.selectedFolderPath ?? "No folder selected")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                Button("Choose Folder...") {
                    viewModel.selectFolder()
                }
            }
        }
    }
    
    private var bookIdSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Book/Album Name (Optional):")
                .font(.system(size: 14, weight: .medium))
            
            HStack(spacing: 10) {
                TextField("Enter book or album name", text: $viewModel.bookId, onCommit: {
                    viewModel.applyBookId()
                })
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 200, maxWidth: 300)
                
                Button("Apply") {
                    viewModel.applyBookId()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
        }
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What this app does:")
                .font(.system(size: 14, weight: .medium))
            
            VStack(alignment: .leading, spacing: 4) {
                InfoRow(text: "Finds files starting with track numbers (1.mp3, 001_title.mp3, etc.)")
                InfoRow(text: "Renames to clean format: '001 Book Title.mp3'")
                InfoRow(text: "Updates MP3 track numbers using Music app")
            }
            .padding(.leading, 20)
        }
    }
    
    private var processButtonSection: some View {
        HStack {
            Spacer()
            
            if viewModel.isProcessing {
                ProgressView()
                    .scaleEffect(0.8)
            }
            
            Button("Sort Audio Files") {
                viewModel.processAudioFiles()
            }
            .disabled(!viewModel.canProcess || viewModel.isProcessing)
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
    }
    
    private var logSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Log:")
                .font(.system(size: 14, weight: .medium))
            
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(viewModel.logMessages) { message in
                            Text(message.text)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(message.id)
                        }
                    }
                    .onChange(of: viewModel.logMessages.count) { _ in
                        if let lastMessage = viewModel.logMessages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .frame(height: 80)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(4)
        }
    }
}

struct InfoRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Text("✓")
                .foregroundColor(.green)
            Text(text)
                .font(.system(size: 12))
        }
    }
}

struct DropTargetView<Content: View>: View {
    @Binding var isTargeted: Bool
    let onDrop: ([URL]) -> Void
    let content: Content
    
    init(isTargeted: Binding<Bool>, onDrop: @escaping ([URL]) -> Void, @ViewBuilder content: () -> Content) {
        self._isTargeted = isTargeted
        self.onDrop = onDrop
        self.content = content()
    }
    
    var body: some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        Color.accentColor.opacity(isTargeted ? 0.5 : 0),
                        lineWidth: 2
                    )
                    .background(
                        Color.accentColor.opacity(isTargeted ? 0.1 : 0)
                    )
                    .padding(10)
            )
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                Task {
                    let urls = await withTaskGroup(of: URL?.self) { group in
                        for provider in providers {
                            group.addTask {
                                try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? URL
                            }
                        }
                        
                        var results: [URL] = []
                        for await url in group {
                            if let url = url {
                                results.append(url)
                            }
                        }
                        return results
                    }
                    
                    if !urls.isEmpty {
                        onDrop(urls)
                    }
                }
                return true
            }
    }
}

extension DropTargetView where Content == EmptyView {
    init(isTargeted: Binding<Bool>, onDrop: @escaping ([URL]) -> Void) {
        self._isTargeted = isTargeted
        self.onDrop = onDrop
        self.content = EmptyView()
    }
}

#Preview {
    ContentView()
        .frame(width: 600, height: 500)
}

