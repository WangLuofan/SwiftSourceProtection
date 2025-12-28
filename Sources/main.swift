//
//  main.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2025/10/28.
//

import Foundation
import SwiftSyntax
import SwiftParser

// 查找项目根目录
func findProjectPath(for filePath: String) -> String? {
    var isDirectory: ObjCBool = ObjCBool(booleanLiteral: false)
    let exists = FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory)
    
    if exists && isDirectory.boolValue == true {
        return filePath
    }
    
    var currentDir = URL(fileURLWithPath: filePath).deletingLastPathComponent()
    
    // 向上查找包含 Package.swift 或 .git 的目录
    while currentDir.path != "/" {
        let packageSwift = currentDir.appendingPathComponent("Package.swift")
        let gitDir = currentDir.appendingPathComponent(".git")
        
        if FileManager.default.fileExists(atPath: packageSwift.path) ||
           FileManager.default.fileExists(atPath: gitDir.path) {
            return currentDir.path
        }
        
        currentDir.deleteLastPathComponent()
    }
    
    // 如果没有找到项目根目录，使用文件所在目录
    return URL(fileURLWithPath: filePath).deletingLastPathComponent().path
}

func main() {
    guard let path = CommandLineParser.parseCommandLine() else {
        print("Usage ./SwiftSourceProtection [file/directory]")
        return
    }
    
    guard let projectPath = findProjectPath(for: path) else {
        return
    }
    
    let sourceFiles = FileHelper(path, excludePaths: ["Pods"]).sourceFiles
    var sourceTreeDict: [String: SourceFileSyntax] = [String: SourceFileSyntax]()
    
    sourceFiles.forEach { sourceFile in
        guard let sourceCode: String = try? String(contentsOfFile: sourceFile, encoding: .utf8), !sourceCode.isEmpty else {
            return
        }
        
        let sourceTree = Parser.parse(source: sourceCode)
        
        let sourceColletion: SwiftSourceCollection = SwiftSourceCollection(sourceFile: sourceFile)
        sourceColletion.walk(sourceTree)
        
        sourceTreeDict[sourceFile] = sourceTree
    }
    
    let isCurrentGlobalScope = SwiftSourceScopeManager.shared.isCurrentGlobalScope()
    let scope = SwiftSourceScopeManager.shared.currentScope
    
    sourceTreeDict.forEach { sourceFile, sourceTree in
        if let confusedFileContent: String =
            SwiftSourceProtection(sourceFile: sourceFile,
                                  sourceTree: sourceTree,
                                  projectPath: projectPath).confuse() {
            
//            try? confusedFileContent.write(toFile: sourceFile, atomically: true, encoding: .utf8)
            
        }
    }
    
}

main()
