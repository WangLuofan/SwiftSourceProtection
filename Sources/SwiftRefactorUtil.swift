//
//  SwiftRefactorUtil.swift
//  SwiftRefactorUtil
//
//  Created by 王落凡 on 2025/10/28.
//

import Foundation
import SwiftSyntax
import SwiftParser

class SwiftSourceInfo: @unchecked Sendable {
    static let shared: SwiftSourceInfo = SwiftSourceInfo()
    lazy var sourceInfoList: [String: SwiftSourceBaseInfo] = [String: SwiftSourceBaseInfo]()
    private lazy var sourceStack: [SwiftSourceBaseInfo] = [SwiftSourceBaseInfo]()
    
    init() {
        
    }
    
    func appendSourceInfo(_ sourceInfo: SwiftSourceBaseInfo) {
        
        if self.sourceStack.isEmpty {
            self.sourceInfoList[sourceInfo.name] = sourceInfo
        } else {
            if sourceInfo.sourceType == .Class, let classInfo: SwiftSourceClassInfo = sourceInfo as? SwiftSourceClassInfo {
                self.sourceStack.last?.children.append(classInfo)
            } else if sourceInfo.sourceType == .Function, let functionInfo: SwiftSourceFunctionInfo = sourceInfo as? SwiftSourceFunctionInfo {
                self.sourceStack.last?.children.append(functionInfo)
            } else if sourceInfo.sourceType == .Property, let propertyInfo: SwiftSourcePropertyInfo = sourceInfo as? SwiftSourcePropertyInfo {
                guard let classInfo: SwiftSourceClassInfo = self.sourceStack.last as? SwiftSourceClassInfo else {
                    return
                }
                
                classInfo.children.append(propertyInfo)
            }
        }
        
        self.sourceStack.append(sourceInfo)
    }
    
    func popSourceInfo() {
        if self.sourceStack.isEmpty {
            return
        }
        
        self.sourceStack.removeLast()
    }
}

class SwiftRefactorUtil {
    private let sourceFile: String
    private var sourceTree: SourceFileSyntax?
    private var sourceRewritter: SwiftASTSyntaxRewriter?
    
    init(sourceFile: String) {
        self.sourceFile = sourceFile
        
        if let sourceCode = try? String(contentsOfFile: self.sourceFile, encoding: .utf8) {
            self.sourceTree = Parser.parse(source: sourceCode)
            if let sourceTree {
                let sourceColletion: SwiftSourceCollection = SwiftSourceCollection(sourceFile: sourceFile)
                sourceColletion.walk(sourceTree)
                
                let info = SwiftSourceInfo.shared.sourceInfoList
                let i = 0
//                self.sourceRewritter = SwiftASTSyntaxRewriter()
            }
        }
    }
    
    public func rewrite() -> String? {
        guard let sourceRewritter, let sourceTree else {
            return nil
        }
        
        let rewritten = sourceRewritter.visit(sourceTree)
        print(rewritten.description)
        
        return rewritten.description
    }
}
