// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "SLaM",
    products: [
        .executable(name: "slam", targets: ["SLaM"])
    ],
    dependencies: [
        .package(name: "ShellOut", url: "https://github.com/johnsundell/shellout.git", from: "2.3.0"),
    ],
    targets: [
        .target(
            name: "SLaM",
            dependencies: ["ShellOut"]
        ),
        .testTarget(
            name: "SLaMTests",
            dependencies: ["SLaM"]),
    ]
)
