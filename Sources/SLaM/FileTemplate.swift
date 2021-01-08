enum FileTemplate {
    static func packageFileContents(packageName: String) -> String {
        """
        // swift-tools-version:5.3

        import PackageDescription

        let package = Package(
            name: "\(packageName)",
            platforms: [.macOS(.v10_13)],
            products: [
                .executable(
                    name: "\(packageName)",
                    targets: ["\(packageName)"]),
            ],
            dependencies: [
                .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", .upToNextMajor(from: "0.3.0"))
            ],
            targets: [
                .target(
                    name: "\(packageName)",
                    dependencies: [
                        .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                        .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-runtime")
                    ]),
                .testTarget(
                    name: "\(packageName)Tests",
                    dependencies: ["\(packageName)"]),
            ]
        )
        """
    }
    
    static func mainFileContents() -> String {
        """
        import AWSLambdaEvents
        import AWSLambdaRuntime
        import Foundation

        Lambda.run { (context, payload: String, completion: @escaping (Result<String, Error>) -> Void) in
            completion(.success("Hello, \\(payload)"))
        }
        """
    }
    
    static func dockerFileContents() -> String {
        """
         FROM swiftlang/swift:nightly-5.3-amazonlinux2
         RUN yum -y install git \\
         libuuid-devel \\
         libicu-devel \\
         libedit-devel \\
         libxml2-devel \\
         sqlite-devel \\
         python-devel \\
         ncurses-devel \\
         curl-devel \\
         openssl-devel \\
         tzdata \\
         libtool \\
         jq \\
         tar \\
         zip
        """
    }
    
    static func packageScriptFileContents() -> String {
        """
        #!/bin/bash

        set -eu

        executable=$1

        target=.build/lambda/$executable
        rm -rf "$target"
        mkdir -p "$target"
        cp ".build/release/$executable" "$target/"
        cp -Pv /usr/lib/swift/linux/lib*so* "$target"
        cd "$target"
        ln -s "$executable" "bootstrap"
        zip --symlinks lambda.zip *
        """
    }
}
