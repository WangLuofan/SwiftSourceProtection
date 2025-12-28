//
//  SwiftConfusedSymbolTable.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2025/12/28.
//

class SwiftConfusedSymbolTable: @unchecked Sendable {
    static let shared: SwiftConfusedSymbolTable = SwiftConfusedSymbolTable()
    
    lazy var confusedSymbol: [String: String] = [String: String]()
    lazy var reversedSymbol: [String: String] = [String: String]()
    
    func pushConfusedSymbol(_ original: String, _ confused: String) {
        self.confusedSymbol[original] = confused
        self.reversedSymbol[confused] = original
    }
    
    static func pushConfusedSymbol(_ original: String, _ confused: String) {
        self.shared.pushConfusedSymbol(original, confused)
    }
}
