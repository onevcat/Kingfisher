// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Kingfisher",
    platforms: [.iOS("15.0"), .macOS("12.0"), .tvOS("15.0"), .watchOS("9.0")],
    products: [
        .library(name: "Kingfisher", targets: ["Kingfisher"])
    ],
    targets: [
        .target(
            name: "Kingfisher",
            path: "Sources",
            exclude: ["Info.plist", "PrivacyInfo.xcprivacy"]
        )
    ]
)
