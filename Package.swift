// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Kingfisher",
    platforms: [.iOS(.v10), .macOS(.v10_12), .tvOS(.v10), .watchOS(.v3)],
    products: [
        .library(name: "Kingfisher", targets: ["Kingfisher"]),
        .library(name: "KingfisherSwiftUI", targets: ["KingfisherSwiftUI"]),
        
        .library(name: "KingfisherDynamic", type: .dynamic, targets: ["Kingfisher"]),
        .library(name: "KingfisherSwiftUIDynamic", type: .dynamic, targets: ["KingfisherSwiftUI"]),
        
        .library(name: "KingfisherStatic", type: .static, targets: ["Kingfisher"]),
        .library(name: "KingfisherSwiftUIStatic", type: .static, targets: ["KingfisherSwiftUI"])
    ],
    targets: [
        .target(
            name: "Kingfisher",
            path: "Sources",
            exclude: ["SwiftUI"]
        ),
        .target(
            name: "KingfisherSwiftUI",
            dependencies: ["Kingfisher"],
            path: "Sources",
            sources: ["SwiftUI"]
        )
    ]
)
