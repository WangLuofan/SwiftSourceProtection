//
//  ConfuseHelper.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2026/1/17.
//

import SwiftSyntax
import SwiftOperators

class ConfuseHelper {
    nonisolated(unsafe) private static var confusedTable: [String: String] = [String: String]()
    nonisolated(unsafe) private static var reversedTable: [String: String] = [String: String]()
    
    static func confuseSymbol(_ symbol: SPSwiftSourceSymbol) {
        guard let originalSymbolName: String = symbol.originalSymbolName,
              self.shouldConfuseSymbol(symbol) else {
            return
        }
        
        if symbol.nodeKind == .function,
           let funcSymbol: SPSwiftSourceFunctionSymbol = symbol as? SPSwiftSourceFunctionSymbol {
            if let funcName: String = funcSymbol.functionName {
                (symbol as? SPSwiftSourceFunctionSymbol)?.confusedFunctionName = self.confusedSymbolName(funcName)
            }
            
            for label in funcSymbol.labels {
                (symbol as? SPSwiftSourceFunctionSymbol)?.confusedLabels.append(self.confusedSymbolName(label))
            }
        } else {
            symbol.confusedSymbolName = self.confusedSymbolName(originalSymbolName)
        }
        
    }
    
    private static func shouldConfuseSymbol(_ symbol: SPSwiftSourceSymbol) -> Bool {
        guard let originalSymbolName: String = symbol.originalSymbolName,
              !originalSymbolName.isEmpty else {
            return false
        }
        
        if symbol.nodeKind == .class ||
            symbol.nodeKind == .enum || symbol.nodeKind == .enumCase ||
            symbol.nodeKind == .protocol || symbol.nodeKind == .struct {
            return true
        }
        
        if symbol.nodeKind == .function,
           let funcSymbol: SPSwiftSourceFunctionSymbol = symbol as? SPSwiftSourceFunctionSymbol {
            if funcSymbol.variableKind == .global ||
                funcSymbol.variableKind == .local ||
                funcSymbol.isStaticSymbol ||
                funcSymbol.accessLevel == .private {
                return true
            }
        } else if symbol.nodeKind == .variable,
                  let varSymbol: SPSwiftSourceVariableSymbol = symbol as? SPSwiftSourceVariableSymbol {
            if varSymbol.variableKind == .global ||
                varSymbol.variableKind == .local ||
                varSymbol.isStaticSymbol ||
                varSymbol.accessLevel == .private {
                return true
            }
        }

        return false
    }

    static func confusedSymbolName(_ symbol: String, minLength: Int = 1, maxLength: Int = 31) -> String {
        if symbol.isSwiftKeyWord {
            return symbol
        }
        
        if let confusedSymbolName: String = self.confusedTable[symbol] {
            return confusedSymbolName
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
        
        if self.reversedTable[randomSymbolName] != nil || randomSymbolName.isSwiftKeyWord {
            return self.confusedSymbolName(symbol)
        }
        
        self.confusedTable[symbol] = randomSymbolName
        self.reversedTable[randomSymbolName] = symbol
        
        return randomSymbolName
    }
    
    static func getConfusedOriginalSymbolName(_ symbolName: String) -> String {
        guard let originalSymbolName: String = self.reversedTable[symbolName] else {
            return symbolName
        }
        
        return originalSymbolName
    }
    
    static func generateFunctionSignature(_ node: FunctionDeclSyntax) -> String {
        var sigComps: [String] = [node.name.text]
        node.signature.parameterClause.parameters.forEach { parameter in
            sigComps.append(parameter.firstName.text)
        }
        
        return sigComps.joined(separator: "_")
    }
}
