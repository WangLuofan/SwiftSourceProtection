//
//  SwiftSourceConfusedTable.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2025/12/23.
//

class SwiftSourceConfusedTable: @unchecked Sendable {
    static let shared: SwiftSourceConfusedTable = SwiftSourceConfusedTable()
    
    lazy var confusedTable: [String: String] = [String: String]()
    lazy var reversedTable: [String: String] = [String: String]()
    
    static func pushSymbol(symbol: String, confusedSymbol: String) {
        if Self.shared.confusedTable[symbol] != nil {
            return
        }
        if Self.shared.reversedTable[confusedSymbol] != nil {
            return
        }
        
        Self.shared.confusedTable[symbol] = confusedSymbol
        Self.shared.reversedTable[confusedSymbol] = symbol
    }
}
