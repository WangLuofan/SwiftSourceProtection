//
//  ConfuseHelper.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2026/1/17.
//

import SwiftSyntax
import SwiftOperators
import Foundation

class ConfuseHelper {
    nonisolated(unsafe) private static var confusedTable: [String: String] = [String: String]()
    nonisolated(unsafe) private static var reversedTable: [String: String] = [String: String]()
    
    static func confuseSymbol(_ symbol: SPSwiftSourceSymbol, confusedMap: [String: String]?) {
        guard !symbol.originalSymbolName.isEmpty,
              self.shouldConfuseSymbol(symbol) else {
            return
        }
        
        if symbol.nodeKind == .function || symbol.nodeKind == .enumCase,
           let funcSymbol: SPSwiftSourceFunctionSymbol = symbol as? SPSwiftSourceFunctionSymbol {
            funcSymbol.confusedSymbolName = self.confusedSymbolName(funcSymbol.originalSymbolName, confusedMap: confusedMap)
            for (index, label) in funcSymbol.labels.enumerated() {
                let confusedLabel: String = self.confusedSymbolName(label, confusedMap: confusedMap)
                funcSymbol.confusedLabels[index] = confusedLabel
            }
        } else {
            symbol.confusedSymbolName = self.confusedSymbolName(symbol.originalSymbolName, confusedMap: confusedMap)
        }
        
    }
    
    private static func shouldConfuseSymbol(_ symbol: SPSwiftSourceSymbol) -> Bool {
        guard !symbol.originalSymbolName.isEmpty else {
            return false
        }
        
        if symbol.nodeKind == .class || symbol.nodeKind == .enumCase {
            return true
        }
        
        if symbol.nodeKind == .function,
           let funcSymbol: SPSwiftSourceFunctionSymbol = symbol as? SPSwiftSourceFunctionSymbol {
            if funcSymbol.symbolScope == .global ||
                funcSymbol.symbolScope == .local ||
                funcSymbol.accessLevel == .private {
                return true
            }
        } else if symbol.nodeKind == .variable,
                  let varSymbol: SPSwiftSourceVariableSymbol = symbol as? SPSwiftSourceVariableSymbol {
            if varSymbol.symbolScope == .global ||
                varSymbol.symbolScope == .local ||
                varSymbol.isStaticSymbol ||
                varSymbol.accessLevel == .private {
                return true
            }
        }

        return false
    }

    static func confusedSymbolName(_ symbol: String, confusedMap: [String: String]?, minLength: Int = 1, maxLength: Int = 31) -> String {
        if symbol.isSwiftKeyWord {
            return symbol
        }
        
        if let confusedSymbolName: String = self.confusedTable[symbol] {
            return confusedSymbolName
        } else if let confusedSymbolName: String = confusedMap?[symbol] {
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
            let randomItem = Int.random(in: 0..<allCharacters[randomIndex].count)
            
            let stringArr: [String.Element] = Array(allCharacters[randomIndex])
            randomSymbolName += String(stringArr[randomItem])
        }
        
        if self.reversedTable[randomSymbolName] != nil || randomSymbolName.isSwiftKeyWord {
            return self.confusedSymbolName(symbol, confusedMap: confusedMap)
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
    
    static func generateSignature(funcName: String, parameters: any SyntaxCollection) -> String {
        var labels: [String] = []
        if let parameters: FunctionParameterListSyntax = parameters.as(FunctionParameterListSyntax.self) {
            labels = parameters.map { $0.firstName.text + ":" }
        } else if let parameters: LabeledExprListSyntax = parameters.as(LabeledExprListSyntax.self) {
            labels = parameters.map { ($0.label?.text ?? "_") + ":"}
        }
            
        return funcName + "(" + labels.joined() + ")"
    }
    
    static func dumpConfusedTable(_ path: String, fileName: String) {
        guard let jsonData: Data = try? JSONSerialization.data(withJSONObject: self.reversedTable, options: .prettyPrinted),
              let jsonContent: String = String(data: jsonData, encoding: .utf8) else {
            return
        }
        
        try? jsonContent.write(toFile: path + "/" + fileName, atomically: true, encoding: .utf8)
    }
}
