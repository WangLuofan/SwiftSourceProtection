//
//  main.swift
//  SwiftRefactorUtil
//
//  Created by 王落凡 on 2025/10/28.
//

import Foundation

func main() {
    guard let path = CommandLineParser.parseCommandLine() else {
        print("Usage ./SwiftRefactorUtil [file/directory]")
        return
    }
    
    FileHelper(path, excludePaths: ["Pods"]).sourceFiles.forEach { file in
        guard let fileContent = try? String(contentsOfFile: file, encoding: .utf8) else {
            return
        }
        
        let newFileContent = SwiftRefactorUtil(fileContent).rewrite()
        try? newFileContent.write(toFile: file, atomically: true, encoding: .utf8)
    }
}

main()
