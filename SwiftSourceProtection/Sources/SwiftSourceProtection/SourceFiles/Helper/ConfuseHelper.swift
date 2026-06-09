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
    
    static func confuseSymbol(_ symbol: SPSwiftSourceSymbol) -> String? {
        guard let originalSymbolName: String = symbol.originalSymbolName,
              self.shouldConfuseSymbol(symbol) else {
            return nil
        }
        
        if let confusedSymbol = symbol.confusedSymbolName {
            return confusedSymbol
        }
        
        let confusedSymbolName: String = self.confusedSymbolName(originalSymbolName)
        return confusedSymbolName
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

        guard let symbol: SPSwiftSourceVariableSymbol = symbol as? SPSwiftSourceVariableSymbol else {
            return false
        }
        
        if symbol.variableKind == .global ||
            symbol.variableKind == .local ||
            symbol.isStaticSymbol ||
            symbol.accessLevel == .private {
            return true
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
}
