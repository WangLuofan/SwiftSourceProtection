//
//  SPSwiftSourceScope.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/8.
//

import Foundation

class SPSwiftSourceScope {
    private var symbols: [String: SPSwiftSourceSymbol] = [:]
    
    private var nextScope: [SPSwiftSourceScope] = []
    private var prevScope: SPSwiftSourceScope?
    
    init() {
        
    }
    
    func pushScope(_ create: Bool) -> SPSwiftSourceScope {
        if !create {
            guard !self.nextScope.isEmpty,
                  let nextScope: SPSwiftSourceScope = self.nextScope.first else {
                return self
            }
            
            return nextScope
        }
        
        let scope: SPSwiftSourceScope = SPSwiftSourceScope()
        scope.prevScope = self
        self.nextScope.append(scope)
        
        return scope
    }
    
    func popScope(_ delete: Bool) -> SPSwiftSourceScope {
        guard let prevScope = self.prevScope else {
            return self
        }
        
        if delete {
            prevScope.nextScope.removeFirst()
        }
        
        return prevScope
    }
    
    func pushSymbol(_ symbol: SPSwiftSourceSymbol) {
        guard !symbol.originalSymbolName.isEmpty  else {
            return
        }
        
        self.symbols[symbol.originalSymbolName] = symbol
    }
    
    func findSymbolWithSymbolName(_ symbolName: String) -> SPSwiftSourceSymbol? {
        var curScope: SPSwiftSourceScope? = self
        
        while curScope != nil {
            if let symbols = curScope?.symbols {
                for (name, symbol) in symbols {
                    if name == symbolName {
                        return symbol
                    }
                }
            }
            curScope = curScope?.prevScope
        }
        
        return nil
    }
}
