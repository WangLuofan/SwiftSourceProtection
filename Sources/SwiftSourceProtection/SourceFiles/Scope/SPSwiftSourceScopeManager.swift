//
//  SPSwiftSourceScopeManager.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/8.
//

import Foundation

class SPSwiftSourceScopeManager {
    private static var scopeIndex: Int = 0
    static var sharedManager: SPSwiftSourceScopeManager = SPSwiftSourceScopeManager()
    
    private var globalScope: SPSwiftSourceScope = SPSwiftSourceScope(SPSwiftSourceScopeManager.scopeIndex)
    lazy var currentScope: SPSwiftSourceScope? = self.globalScope
    
    func pushScope(_ bNew: Bool = true) {
        guard self.currentScope != nil else {
            return
        }
        
        if bNew {
            SPSwiftSourceScopeManager.scopeIndex += 1
            let newScope: SPSwiftSourceScope = SPSwiftSourceScope(SPSwiftSourceScopeManager.scopeIndex)
            self.currentScope?.nextScope.append(newScope)
            self.currentScope = newScope
            
            return
        }
        
        if (self.currentScope?.nextScope.count ?? 0) > 0 {
            self.currentScope = self.currentScope?.nextScope.first
        }
    }
    
    func popScope(_ bRemove: Bool = false) {
        guard let prevScope: SPSwiftSourceScope = self.currentScope?.prevScope else {
            return
        }
        
        let leavingScope = self.currentScope
        self.currentScope = prevScope
        
        if bRemove,
           let leavingScope,
           let scopeIndex = self.currentScope?.nextScope.firstIndex(of: leavingScope) {
            self.currentScope?.nextScope.remove(at: scopeIndex)
        }
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
