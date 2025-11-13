// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AudioSorter",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(
            name: "SimpleAudioSorter",
            targets: ["SimpleAudioSorter"]
        ),
        .library(
            name: "AudioSorterCore",
            targets: ["AudioSorterCore"]
        )
    ],
    targets: [
        .target(
            name: "AudioSorterCore",
            path: "Core",
            exclude: []
        ),
        .executableTarget(
            name: "SimpleAudioSorter",
            dependencies: ["AudioSorterCore"],
            path: ".",
            exclude: [
                "Core",
                "Tests",
                "Audio Sorter.app",
                "Audio Sorter.zip",
                "create-gui-app-bundle.sh",
                "run_core_tests.sh",
                "test_core_functionality.py",
                "update-mp3-tags.py"
            ],
            sources: [
                "main.swift",
                "UI/DragDropView.swift",
                "UI/MainViewController.swift",
                "Utils/AppDelegate.swift"
            ]
        ),
        .testTarget(
            name: "AudioSorterCoreTests",
            dependencies: ["AudioSorterCore"],
            path: "Tests"
        )
    ]
)

