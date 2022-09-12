enum FileTemplate {
    static func packageFileContents(packageName: String) -> String {
        """
        // swift-tools-version:5.6

        import PackageDescription

        let package = Package(
            name: "\(packageName)",
            platforms: [.macOS(.v12)],
            products: [
                .executable(
                    name: "\(packageName)",
                    targets: ["\(packageName)"]),
            ],
            dependencies: [
                .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", .upToNextMajor(from: "0.5.0"))
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
         FROM swift:5.6-amazonlinux2
         RUN yum -y install git zip
        """
    }
    
    static func packageScriptFileContents() -> String {
        """
        #!/bin/bash

        ##===----------------------------------------------------------------------===##
        ##
        ## This source file is part of the SwiftAWSLambdaRuntime open source project
        ##
        ## Copyright (c) 2020 Apple Inc. and the SwiftAWSLambdaRuntime project authors
        ## Licensed under Apache License v2.0
        ##
        ## See LICENSE.txt for license information
        ## See CONTRIBUTORS.txt for the list of SwiftAWSLambdaRuntime project authors
        ##
        ## SPDX-License-Identifier: Apache-2.0
        ##
        ##===----------------------------------------------------------------------===##

        set -eu

        executable=$1

        target=".build/lambda/$executable"
        rm -rf "$target"
        mkdir -p "$target"
        cp ".build/release/$executable" "$target/"

        # add the target deps based on ldd
        ldd ".build/release/$executable" | grep swift | awk '{print $3}' | xargs cp -Lv -t "$target"

        cd "$target"
        ln -s "$executable" "bootstrap"
        zip --symlinks ../lambda.zip *
        """
    }
}
