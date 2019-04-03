// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "Kingfisher",
    // platforms: [.iOS("10.0"), .macOS("10.12"), tvOS("10.0"), .watchOS("3.0")],
    products: [
        .library(name: "Kingfisher", targets: ["Kingfisher"])
    ],
    targets: [
        .target(
            name: "Kingfisher",
            path: "Sources"
        )
    ]
)
