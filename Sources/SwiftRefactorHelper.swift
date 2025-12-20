//
//  SwiftRefactorHelper.swift
//  SwiftRefactorUtil
//
//  Created by WangLuofan on 2025/12/12.
//
import SwiftSyntax

class SwiftRefactorHelper {
    
    static func isMemberVariable(_ node: VariableDeclSyntax) -> Bool {
        var currentNode: Syntax? = Syntax(node)
        
        while let parent = currentNode?.parent {
            switch parent.kind {
            case .classDecl, .structDecl, .enumDecl, .extensionDecl:
                return true
            case .functionDecl, .closureExpr, .codeBlock, .ifExpr, .forStmt, .whileStmt, .repeatStmt, .switchExpr:
                return false
            default:
                currentNode = parent
            }
        }
        
        return false
    }
}

extension DeclModifierSyntax {
    var accessControl: SwiftSourceAccessControl {
        if self.name.text == "open" {
            return .Open
        } else if self.name.text == "public" {
            return .Public
        } else if self.name.text == "fileprivate" {
            return .FilePrivate
        } else if self.name.text == "private" {
            return .Private
        } else if self.name.text == "package" {
            return .Package
        }
        
        return .Internal
    }
    
    var isStatic: Bool {
        return self.name.text == "static"
    }
    
    var isOverride: Bool {
        return self.name.text == "override"
    }
    
    var isClass: Bool {
        return self.name.text == "class"
    }
    
    var isFinal: Bool {
        return self.name.text == "final"
    }
}
