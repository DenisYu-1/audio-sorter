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
                "create-gui-app-bundle.sh",
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

