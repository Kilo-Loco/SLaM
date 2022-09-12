// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "SLaM",
    platforms: [
        .macOS(.v12)
    ],     
    products: [
        .executable(name: "slam", targets: ["SLaM"])
    ],
    dependencies: [
        .package(url: "https://github.com/johnsundell/shellout.git", .upToNextMajor(from: "2.3.0")),
    ],
    targets: [
        .executableTarget(
            name: "SLaM",
            dependencies: [
                .product(name: "ShellOut", package: "ShellOut")
            ]
        ),
        .testTarget(
            name: "SLaMTests",
            dependencies: ["SLaM"]),
    ]
)
