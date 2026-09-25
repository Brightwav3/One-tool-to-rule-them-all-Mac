// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OneTool",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(name: "OneTool", path: "Sources/OneTool"),
        .testTarget(name: "OneToolTests", dependencies: ["OneTool"], path: "Tests/OneToolTests"),
    ]
)
