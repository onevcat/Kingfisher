// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "Kingfisher",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "Kingfisher", targets: ["Kingfisher"])
    ],
    targets: [
        .target(
            name: "Kingfisher",
            path: "Sources",
            exclude: ["Info.plist"],
            resources: [.process("PrivacyInfo.xcprivacy")]
        )
    ],
    swiftLanguageModes: [.v5]
)
