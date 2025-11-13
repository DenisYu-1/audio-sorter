// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AudioSorter",
    platforms: [
        .macOS(.v12)
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
            path: "Core"
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
                "AudioSorterApp.swift",
                "UI/ContentView.swift",
                "UI/AudioSorterViewModel.swift"
            ]
        ),
        .testTarget(
            name: "AudioSorterCoreTests",
            dependencies: ["AudioSorterCore"],
            path: "Tests"
        )
    ]
)

