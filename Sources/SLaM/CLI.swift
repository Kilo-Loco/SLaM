//
//  CLI.swift
//  
//
//  Created by Kilo Loco on 1/7/21.
//

import Foundation
import ShellOut

public struct CLI {
    private let arguments: [String]
    
    public init(arguments: [String] = CommandLine.arguments) {
        self.arguments = arguments
    }
    
    public func run() throws {
        guard arguments.count > 1 else {
            return outputHelpText()
        }
        
        switch arguments[1] {
        case "new":
            if !checkPrerequisites() {
                exit(-1)
            }
            try createNewLambdaProject()
            try setupDockerImage()

        case "build":
            try buildPackageInContainer()
            
        case "package":
            try packageLambda()
            
        case "export":
            let imageName = try buildPackageInContainer()
            try packageLambda(dockerImageName: imageName)
            let currentDirectory = try getCurrentDirectory()
            print("📦 Package found at: \(currentDirectory.fullPath)/.build/lambda/\(currentDirectory.currentPath)/lambda.zip")
            
        case "deploy":
            try samDeploy()

        case "invoke":
            try invoke()

        case "-h", "help", "--help":
            outputHelpText()

        default:
            outputHelpText()
        }
    }
    
    private func replaceFile(at path: String, with contents: String) throws {
        try shellOut(to: .removeFile(from: path))
        let url = URL(fileURLWithPath: path)
        try contents.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func checkToolAvailable(cmd: String, tip: String) -> Bool {
        
        var result : Bool = true
        do {
            try shellOut(to: "which \(cmd)")
        } catch {
            let error = error as! ShellOutError
            
            if !error.message.contains("not found") {
                print("'\(cmd)' is required to deploy AWS Lambda functions. You can install it with '\(tip)'")
            }
            
            result = false
        }
        
        return result
    }
    private func checkPrerequisites() -> Bool {
        return  checkToolAvailable(cmd: "aws", tip: "brew install awscli")
            && checkToolAvailable(cmd: "docker", tip: "https://docs.docker.com/docker-for-mac/install/")
            && checkToolAvailable(cmd: "sam", tip: "brew tap aws/tap && brew install aws-sam-cli")
    }
    
    private func createNewLambdaProject() throws {
        try shellOut(to: "swift package", arguments: ["init", "--type executable"])
        let currentDirectory = try getCurrentDirectory()
        
        print("🚀 Creating project....")

        // Create Dockerfile
        try replaceFile(
            at: "Dockerfile",
            with: FileTemplate.dockerFileContents()
        )
        
        // Create package.sh
        try shellOut(to: .createFolder(named: "scripts"))
        try replaceFile(
            at: "scripts/package.sh",
            with: FileTemplate.packageScriptFileContents()
        )
        try shellOut(to: "chmod", arguments: ["+x", "scripts/package.sh"])
        
        // Create Package.swift
        try replaceFile(
            at: "Package.swift",
            with: FileTemplate.packageFileContents(
                packageName: currentDirectory.currentPath
            )
        )
        
        // Create main.swift
        try replaceFile(
            at: "Sources/\(currentDirectory.currentPath)/main.swift",
            with: FileTemplate.mainFileContents()
        )
        
        // Remove test file
        let testFileName = currentDirectory.currentPath
            .replacingOccurrences(of: "-", with: "_")
            .appending("Tests.swift")
        try shellOut(to: .removeFile(from: "Tests/\(currentDirectory.currentPath)Tests/\(testFileName)"))
        
        // create SAM template to easily deploy the lambda function
        try replaceFile(
            at: "scripts/sam.yml",
            with: FileTemplate.SAMTemplate(
                packageName: currentDirectory.currentPath
            )
        )
        
        // Create HTTP API v2 test event
        try replaceFile(
            at: "event.json",
            with: FileTemplate.HTTPAPIEventTemplate()
        )

        print("🚀 Project created")

        // create S3 deployment bucket
        try createDeploymentBucket(
            bucketName: "\(currentDirectory.currentPath.lowercased())-samclisourcebucket"
        )

    }
    
    private func getDockerImageName() throws -> String {
        let currentDirectory = try getCurrentDirectory()
        let imageName = currentDirectory.currentPath.lowercased()
        
        return "\(imageName)-builder"
    }
    
    @discardableResult
    private func setupDockerImage() throws -> String {
        
        let imageName = try getDockerImageName()
        
        print("🛠 Preparing docker image (\(imageName))...")
        
        try shellOut(to: "docker", arguments: ["build", "-t", imageName, "."])
        
        print("🐳 Successfully setup image: \(imageName)")
        
        return imageName
    }
    
    private func getCurrentDirectory() throws -> (fullPath: String, currentPath: String) {
        let fullPath = try shellOut(to: "pwd")
        guard let currentPath = fullPath.components(separatedBy: "/").last else {
            throw Error.invalidPath
        }
        return (fullPath, currentPath)
    }
    
    @discardableResult
    private func buildPackageInContainer() throws -> String {
        let currentDirectory = try getCurrentDirectory()
        let imageName = try getDockerImageName()

        print("🛠 Building package...")
        
        let output = try shellOut(
            to: "docker",
            arguments: [
                "run",
                "--rm",
                "--volume \"\(currentDirectory.fullPath)/:/src\"",
                "--workdir \"/src/\"",
                imageName,
                "swift build --product \(currentDirectory.currentPath) -c release"
            ]
        )
        print(output)
        
        print("🐳 Package built in container")
        
        return imageName
    }
    
    private func packageLambda(dockerImageName: String? = nil) throws {
        let currentDirectory = try getCurrentDirectory()
        let imageName = try getDockerImageName()

        print("🗳 Packaging...")
        
        let output = try shellOut(
            to: "docker",
            arguments: [
                "run",
                "--rm",
                "--volume \"\(currentDirectory.fullPath)/:/src\"",
                "--workdir \"/src/\"",
                imageName,
                "scripts/package.sh \(currentDirectory.currentPath)"
            ]
        )
        print(output)
        
        print("📦 Lambda Packaged")
    }
    
    private func samDeploy() throws {
        print("🐿 Deploying with SAM...")
        
        let currentDirectory = try getCurrentDirectory()
        
        do {
            let _ = try shellOut(
                to: "sam",
                arguments: [
                    "deploy",
                    "--template",
                    "./scripts/sam.yml",
                    "--stack-name",
                    "\(currentDirectory.currentPath)",
                    "--s3-bucket",
                    "\(currentDirectory.currentPath.lowercased())-samclisourcebucket",
                    "--capabilities",
                    "CAPABILITY_IAM"
                ]
            )
        } catch {
            let error = error as! ShellOutError
            
            if !error.message.starts(with: "Error: No changes to deploy") {
                print("\(error)")
            }
        }
        
        print("🐿 ƛ AWS Lambda function deployed")

        let output = try shellOut(
            to: "aws",
            arguments: [
                "cloudformation",
                "describe-stacks",
                "--stack-name",
                "\(currentDirectory.currentPath)",
                "--query",
                "Stacks[].Outputs[].OutputValue",
                "--output",
                "text"
            ]
        )
        
        print("You can now call your AWS Lambda at : \(output)" )
        
    }
    
    private func createDeploymentBucket(bucketName: String) throws {
        
        print("🪣 Creating deployment bucket '\(bucketName)' if it does not exist")

        do {
            let _ = try shellOut(
                to: "aws",
                arguments: [
                    "s3",
                    "mb",
                    "s3://\(bucketName)"
                ]
            )
        } catch {
            let error = error as! ShellOutError
            
            if !error.message.contains("BucketAlreadyOwnedByYou"){
                print("\(error)")
                throw error
            }

        }
        print("🪣 Done")

    }
    
    // produce a local (macOS) build of the AWS Lambda function
    // and start it using LOCAL_LAMBDA_SERVER_ENABLED= true environment variable
    private func invoke() throws {
        
        let currentDirectory = try getCurrentDirectory()

        // produce a local (macOS) build of the AWS Lambda function
        try shellOut(to: .buildSwiftPackage(withConfiguration: .debug))
        
        print("To start the test server, type: LOCAL_LAMBDA_SERVER_ENABLED=true .build/debug/\(currentDirectory.currentPath)")
        print("Type CTRL-C to stop the server")
        print("")
        print("To invoke your function, open another Terminal tab and type : curl -v -X POST --data-binary @./event.json http://localhost:7000/invoke")

        
        // TODO : start the server as a daemon and provide a mechanism to stop it
        // ideally :
        // - start the server
        // - pass the event
        // - stop the server
        // - collect stdout /stderr for debugging
        
        //start it using LOCAL_LAMBDA_SERVER_ENABLED=true environment variable
        //try shellOut(to: "LOCAL_LAMBDA_SERVER_ENABLED=true .build/debug/\(currentDirectory.currentPath)")
        
    }
}

private extension CLI {
    func outputHelpText() {
        print("""
        SLaM Command Line Interface
        ------------------------------

        Interact with the SLaM (Swift AWS Lambda Maker) from
        the command line, to create new Swift AWS Lambda projects,
        package your AWS Lambda functions into a zip file,
        or deploy your code to AWS Lambda.

        Available commands:
        - new: Create a new Swift AWS Lambda Package.
        - build: Build Swift AWS Lambda function (inside Docker image).
        - package: Package Swift AWS Lambda function
        - export: Build and package Swift AWS Lambda function
        - deploy: Deploy to AWS Lambda
        - invoke: invoke the AWS Lambda function locally (simulates an event sent by HTTP API Gateway)
        """)
    }
    
    enum Error: LocalizedError {
        case inputError
        case invalidPath
        
        var errorDescription: String? {
            switch self {
            case .inputError:
                return "Invalid input. Please try again."
            case .invalidPath:
                return "The path specified doesn't exist."
            }
        }
    }
}
