//
//  SPSwiftSourceScopeManager.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/8.
//

import Foundation

class SPSwiftSourceScopeManager {
    static var sharedManager: SPSwiftSourceScopeManager = SPSwiftSourceScopeManager()
    
    private var globalScope: SPSwiftSourceScope = SPSwiftSourceScope()
    lazy var currentScope: SPSwiftSourceScope? = self.globalScope
    
    func pushScope() {
        guard self.currentScope != nil else {
            return
        }
        
        let newScope: SPSwiftSourceScope = SPSwiftSourceScope()
        self.currentScope?.nextScope.append(newScope)
        self.currentScope = newScope
    }
    
    func popScope() {
        guard let prevScope: SPSwiftSourceScope = self.currentScope?.prevScope else {
            return
        }
        
        self.currentScope = prevScope
    }
    
    func findSymbolWithSymbolName(_ symbolName: String) -> SPSwiftSourceSymbol? {
        var curScope: SPSwiftSourceScope? = self.currentScope
        while curScope != nil {
            if let symbol: SPSwiftSourceSymbol = curScope?.findSymbolWithSymbolName(symbolName) {
                return symbol
            }
            
            curScope = curScope?.prevScope
        }
        
        return nil
    }
}
