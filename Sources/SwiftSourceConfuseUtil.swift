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
    private var sourceTree: SourceFileSyntax
    private lazy var sourceRewritter: SwiftASTSyntaxRewriter = SwiftASTSyntaxRewriter(sourceInfo: self.sourceInfo)
    private let sourceInfo: SwiftSourceInfo
    
    init(sourceFile: String, sourceInfo: SwiftSourceInfo, sourceTree: SourceFileSyntax) {
        self.sourceFile = sourceFile
        self.sourceInfo = sourceInfo
        self.sourceTree = sourceTree
    }
    
    public func confuse() -> String? {
        
        let rewritten = sourceRewritter.visit(sourceTree)
        print(rewritten.description)
        
        return rewritten.description
    }
}
