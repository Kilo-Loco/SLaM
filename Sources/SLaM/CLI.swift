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
            try createNewLambdaProject()
            
        case "setup-image":
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
            
        default:
            outputHelpText()
        }
    }
    
    private func replaceFile(at path: String, with contents: String) throws {
        try shellOut(to: .removeFile(from: path))
        let url = URL(fileURLWithPath: path)
        try contents.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func createNewLambdaProject() throws {
        try shellOut(to: "swift package", arguments: ["init", "--type executable"])
        let currentDirectory = try getCurrentDirectory()
        
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
        
        print("🚀 Project created")
    }
    
    private func promptImageName() throws -> String {
        print("Enter the name of your image:")
        
        guard let imageName = readLine() else { throw Error.inputError }
        
        return imageName
    }
    
    @discardableResult
    private func setupDockerImage() throws -> String {
        let imageName = try promptImageName()
        
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
    private func buildPackageInContainer(dockerImageName: String? = nil) throws -> String {
        let imageName = try dockerImageName ?? promptImageName()
        let currentDirectory = try getCurrentDirectory()
        
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
        let imageName = try dockerImageName ?? promptImageName()
        let currentDirectory = try getCurrentDirectory()
        
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
}

private extension CLI {
    func outputHelpText() {
        print("""
        SLaM Command Line Interface
        ------------------------------
        Interact with the SLaM (Swift Lambda Maker) from
        the command line, to create new Swift Lambda projects,
        or package your Lambda into a zip file.
        Available commands:
        - new: Create a new Swift Lambda Package.
        - setup-image: Create a Docker image.
        - build: Build Swift Lambda inside Docker image.
        - package: Package Swift Lambda
        - export: Builds and packages Swift Lambda
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
