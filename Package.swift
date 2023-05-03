// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "KVOSequence",
    platforms: [.iOS(.v15), .macCatalyst(.v15), .macOS(.v12)],
    products: [
        .library(name: "KVOSequence", targets: ["KVOSequence"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections", .upToNextMinor(from: "1.0.4")),
    ],
    targets: [
        .target(
            name: "KVOSequence",
            dependencies: [
                .product(name: "DequeModule", package: "swift-collections"),
            ]
        ),
        .testTarget(name: "KVOSequenceTests", dependencies: ["KVOSequence"]),
    ]
)
