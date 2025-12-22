//
//  SwiftConfuseHelper.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2025/12/20.
//
import Foundation
import SwiftSyntax

class SwiftConfuseHelper {
    static func confusedSymbolName(symbolName: String, sourceInfo: SwiftSourceInfo, minLength: Int = 1, maxLength: Int = 31) -> String? {
        
        if symbolName == "_" || symbolName == "self" {
            return symbolName
        }
        
        if let confusedName = sourceInfo.identifierMap[symbolName] {
            return confusedName
        }
        
        if minLength <= 0 || maxLength >= 32 {
            return nil
        }
        
        let lowercase: String = "abcdefghijklmnopqrstuvwxyz"
        let uppercase: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let digital: String = "0123456789"
        let underScore: String = "_"
        
        let randomSymbolLength: Int = Int.random(in: minLength...maxLength)
        let firstCharset: [String.Element] = Array(lowercase + uppercase + underScore)
        
        var randomSymbolName = String(firstCharset[Int.random(in: 0..<firstCharset.count)])
        let allCharacters: [String] = [lowercase, uppercase, digital]
        
        for _ in 1..<randomSymbolLength {
            let randomIndex = Int.random(in: 0..<allCharacters.count)
            if randomIndex == 3 {
                randomSymbolName += underScore
                continue
            }
            
            let randomItem = Int.random(in: 0..<allCharacters[randomIndex].count)
            
            let stringArr: [String.Element] = Array(allCharacters[randomIndex])
            randomSymbolName += String(stringArr[randomItem])
        }
        
        if sourceInfo.identifierMap[symbolName] != nil {
            return self.confusedSymbolName(symbolName: symbolName, sourceInfo: sourceInfo)
        }
        
        sourceInfo.identifierMap[symbolName] = randomSymbolName
        sourceInfo.confusedMap[randomSymbolName] = symbolName
        
        return randomSymbolName
    }
    
    static func isEqualSourceInfo(_ lhs: SwiftSourceBaseInfo, _ rhs: SwiftSourceBaseInfo) -> Bool {
        if lhs.sourceType != rhs.sourceType {
            return false
        }
        
        if lhs.name != rhs.name {
            return false
        }
        
        if let lhsFuncInfo: SwiftSourceFunctionInfo = lhs as? SwiftSourceFunctionInfo,
           let rhsFuncInfo: SwiftSourceFunctionInfo = rhs as? SwiftSourceFunctionInfo {
            return lhsFuncInfo.signature == rhsFuncInfo.signature
        }
        
        return true
    }
    
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
