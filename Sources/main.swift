//
//  main.swift
//  SwiftRefactorUtil
//
//  Created by 王落凡 on 2025/10/28.
//

import Foundation

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
        print("Usage ./SwiftRefactorUtil [file/directory]")
        return
    }
    
    guard let projectPath = findProjectPath(for: path) else {
        return
    }
    
    let sourceFiles = FileHelper(path, excludePaths: ["Pods"]).sourceFiles
    
    sourceFiles.forEach { file in
        if let newFileContent = SwiftRefactorUtil(sourceFile: file).rewrite() {
            try? newFileContent.write(toFile: file, atomically: true, encoding: .utf8)
        }
    }
    
}

main()
