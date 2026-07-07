//
//  SPSwiftSourceScope.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/8.
//

import Foundation
import SwiftSyntax

class SPSwiftSourceScope {
    private var symbols: [String: SPSwiftSourceSymbol] = [:]
    
    private var nextScope: [SPSwiftSourceScope] = []
    private var prevScope: SPSwiftSourceScope?
    
    init() {
        
    }
    
    func pushScope() -> SPSwiftSourceScope {
        let scope: SPSwiftSourceScope = SPSwiftSourceScope()
        scope.prevScope = self
        self.nextScope.append(scope)
        
        return scope
    }
    
    func popScope() -> SPSwiftSourceScope {
        guard let prevScope = self.prevScope else {
            return self
        }
        
        return prevScope
    }
    
    func pushSymbol(_ symbol: SPSwiftSourceSymbol) {
        guard !symbol.originalSymbolName.isEmpty  else {
            return
        }
        
        if let funcSymbol: SPSwiftSourceFunctionSymbol = symbol as? SPSwiftSourceFunctionSymbol {
            self.symbols[funcSymbol.signature] = symbol
        } else {
            self.symbols[symbol.originalSymbolName] = symbol
        }
    }
    
    func findSymbolWithUSR(_ usr: String) -> SPSwiftSourceSymbol? {
        var curScope: SPSwiftSourceScope? = self
        
        while curScope != nil {
            if let symbols = curScope?.symbols {
                for (_, symbol) in symbols {
                    if symbol.symbolUSR == usr {
                        return symbol
                    }
                }
            }
            
            curScope = curScope?.prevScope
        }
        
        return nil
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
