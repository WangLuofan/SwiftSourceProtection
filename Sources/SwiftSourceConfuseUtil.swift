//
//  SwiftSourceConfuseUtil.swift
//  SwiftSourceConfuseUtil
//
//  Created by 王落凡 on 2025/10/28.
//

import Foundation
import SwiftSyntax
import SwiftParser

class SwiftSourceConfuseUtil {
    private let sourceFile: String
    private let projectPath: String
    
    private var sourceTree: SourceFileSyntax
    private lazy var sourceRewritter: SwiftASTSyntaxRewriter = SwiftASTSyntaxRewriter(sourceInfo: self.sourceInfo, projectPath: self.projectPath)
    private let sourceInfo: SwiftSourceInfo
    
    init(sourceFile: String, sourceInfo: SwiftSourceInfo, sourceTree: SourceFileSyntax, projectPath: String) {
        self.sourceFile = sourceFile
        self.sourceInfo = sourceInfo
        self.sourceTree = sourceTree
        self.projectPath = projectPath
    }
    
    public func confuse() -> String? {
        
        let rewritten = sourceRewritter.visit(sourceTree)
        print(rewritten.description)
        
        return rewritten.description
    }
}
