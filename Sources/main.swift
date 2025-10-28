//
//  main.swift
//  SwiftRefactorUtil
//
//  Created by 王落凡 on 2025/10/28.
//

import Foundation
import SwiftSyntax
import SwiftParser
import SwiftSyntaxBuilder

func main() {
    guard let path = CommandLineParser.parseCommandLine() else {
        print("Usage ./SwiftRefactorUtil [file/directory]")
        return
    }
    
    FileHelper(path, excludePaths: ["Pods"]).sourceFiles.forEach { file in
        print(file)
    }
}

main()
