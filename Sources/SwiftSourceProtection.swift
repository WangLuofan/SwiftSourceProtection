//
//  SwiftSourceProtection.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2025/10/28.
//

import Foundation
import SwiftSyntax
import SwiftParser

class SwiftSourceProtection {
    private let sourceFile: String
    private let projectPath: String
    
    private var sourceTree: SourceFileSyntax
    private lazy var sourceRewritter: SwiftASTSyntaxRewriter = SwiftASTSyntaxRewriter(projectPath: self.projectPath)
    
    init(sourceFile: String, sourceTree: SourceFileSyntax, projectPath: String) {
        self.sourceFile = sourceFile
        self.sourceTree = sourceTree
        self.projectPath = projectPath
    }
    
    public func confuse() -> String? {
        
        let rewritten = sourceRewritter.visit(sourceTree)
        print(rewritten.description)
        
        return rewritten.description
    }
}
