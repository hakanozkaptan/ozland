// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OzLand",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "OzLand",
            targets: ["OzLand"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.12.0"),
    ],
    targets: [
        .executableTarget(
            name: "OzLand",
            dependencies: []
        ),
        .testTarget(
            name: "OzLandTests",
            dependencies: [
                "OzLand",
                .product(name: "Testing", package: "swift-testing"),
            ]
        ),
    ]
)

