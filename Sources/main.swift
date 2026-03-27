//
//  main.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2025/10/28.
//

/// 第一步：收集全局符号、成员符号
/// 第二步：合并extension
/// 第三步：类型推导、符号混淆

import Foundation
import SwiftSyntax
import SwiftParser
import SwiftOperators

// 查找项目根目录
func findProjectDirectory(for filePath: String) -> (String?, String?) {
    var isDirectory: ObjCBool = ObjCBool(booleanLiteral: false)
    let exists = FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory)
    
    if !exists || isDirectory.boolValue == false {
        return (nil, "Project Path Not Exists.")
    }
    
    var currentDir = URL(fileURLWithPath: filePath)
    
    guard let contents = try? FileManager.default.contentsOfDirectory(at: currentDir, includingPropertiesForKeys: nil) else {
        return (nil, "Empty Project Path.")
    }
    
    guard let projFile = contents.first(where: { $0.pathExtension == "xcworkspace" || $0.pathExtension == "xcodeproj" }) else {
        return (nil, "No .xcworkspace or .xcodeproj Found.")
    }
    
    return (projFile.path(), nil)
}

func main() {
    guard let (path, target) = CommandLineParser.parseCommandLine(),
          let path, let target else {
        print("Usage: ./SwiftSourceProtection [ProjectPath] [target]")
        return
    }
    
    var (projectPath, errorMessage) = findProjectDirectory(for: path)
    projectPath?.removeLast()
    
    guard let projectPath else {
        print(errorMessage ?? "Unknown Error.")
        return
    }

    SwiftConfusedHelper.sourcekittenHandler = SourceKittenHandler(projectPath: projectPath, projectTarget: target)
    guard let _ = SwiftConfusedHelper.sourcekittenHandler else {
        print("SourceKitten initizlize failed, please check it.")
        return
    }
    print("SourceKitten initialized successfully")

    let sourceFiles = FileHelper(path, excludePaths: ["Pods"]).sourceFiles
    var sourceTreeDict: [String: SourceFileSyntax] = [String: SourceFileSyntax]()
    
    /// 第一步：收集全局符号、成员符号
    sourceFiles.forEach { sourceFile in
        if !sourceFile.contains("TestFile.swift") {
            return
        }
        
        guard let sourceCode: String = try? String(contentsOfFile: sourceFile, encoding: .utf8), !sourceCode.isEmpty else {
            return
        }
        
        let sourceTree: SourceFileSyntax = Parser.parse(source: sourceCode)
        let foldedSourceTree: SourceFileSyntax? = try? OperatorTable.standardOperators.foldAll(sourceTree).cast(SourceFileSyntax.self)
        
        let parsedSourceTree = foldedSourceTree ?? sourceTree
        let sourceCollector: SwiftSourceCollector = SwiftSourceCollector(sourceFile: sourceFile, sourceKitten: nil)
        sourceCollector.walk(parsedSourceTree)
        
        sourceTreeDict[sourceFile] = foldedSourceTree
    }
    
    /// 第三步：类型推导、符号混淆
    sourceFiles.forEach { sourceFile in
        guard let sourceTree: SourceFileSyntax = sourceTreeDict[sourceFile] else {
            return
        }
        
        if let confusedFileContent: String =
            SwiftSourceProtector(sourceFile: sourceFile,
                                 sourceTree: sourceTree,
                                 projectPath: projectPath).confuse() {
            
//            try? confusedFileContent.write(toFile: sourceFile, atomically: true, encoding: .utf8)
        }
    }
}

main()
