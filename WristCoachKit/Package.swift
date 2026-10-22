// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WristCoachKit",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v14)
    ],
    products: [
        .library(name: "WristCoachKit", targets: ["WristCoachKit"])
    ],
    targets: [
        .target(name: "WristCoachKit"),
        .testTarget(name: "WristCoachKitTests", dependencies: ["WristCoachKit"])
    ]
)
