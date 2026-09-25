// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OneTool",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "OneTool", path: "Sources/OneTool",
            // SwiftPM stamps the deployment target as the SDK version, and macOS only
            // gives apps linked against the 26+ SDK the Liquid Glass window chrome.
            linkerSettings: [.unsafeFlags(["-Xlinker", "-platform_version", "-Xlinker", "macos", "-Xlinker", "15.0", "-Xlinker", "27.0"])]
        ),
        .testTarget(name: "OneToolTests", dependencies: ["OneTool"], path: "Tests/OneToolTests"),
    ]
)
