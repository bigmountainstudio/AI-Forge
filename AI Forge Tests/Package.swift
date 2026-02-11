// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AIForgeTests",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "AIForgeTests", targets: ["AIForgeTests"])
    ],
    targets: [
        .testTarget(
            name: "AIForgeTests",
            path: "."
        )
    ]
)
