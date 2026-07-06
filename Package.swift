// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "GlassPomodoro",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "GlassPomodoro",
            path: "Sources/GlassPomodoro"
        )
    ]
)
