//
//  SPSwiftSourceScope.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/8.
//

import Foundation

class SPSwiftSourceScope {
    private var symbols: [String: SPSwiftSourceSymbol] = [:]
    
    var nextScope: [SPSwiftSourceScope] = []
    var prevScope: SPSwiftSourceScope?
    
    func pushSymbol(_ symbol: SPSwiftSourceSymbol) {
        guard let originalSymbolName: String = symbol.originalSymbolName else {
            return
        }
        
        self.symbols[originalSymbolName] = symbol
    }
    
    func findSymbolWithSymbolName(_ symbolName: String) -> SPSwiftSourceSymbol? {
        for (name, symbol) in self.symbols {
            if name == symbolName {
                return symbol
            }
        }
        
        return nil
    }
}
