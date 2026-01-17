//
//  SwiftSourceScope.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2026/1/12.
//

class SwiftSourceScopeManager {
    nonisolated(unsafe) static let sharedManager: SwiftSourceScopeManager = SwiftSourceScopeManager()
    
    var currentScope: SwiftSourceScope?
    private var globalScope: SwiftSourceScope = SwiftSourceScope()
    
    init() {
        self.currentScope = self.globalScope
    }
    
    func pushScope() {
        let scope: SwiftSourceScope = SwiftSourceScope()
        
        scope.prev = self.currentScope
        self.currentScope?.next.append(scope)
        
        self.currentScope = scope
    }
    
    func popScope() {
        if self.currentScope?.prev == nil {
            return
        }
        
        self.currentScope = self.currentScope?.prev
    }
}

class SwiftSourceScope {
    
    lazy var symbols: [String: SwiftSourceSymbol] = [String: SwiftSourceSymbol]()
    
    var prev: SwiftSourceScope?
    lazy var next: [SwiftSourceScope] = [SwiftSourceScope]()
    
    func pushSymbol(_ symbol: SwiftSourceSymbol) {
        guard let identifier = symbol.identifier else {
            return
        }
        
        self.symbols[identifier] = symbol
    }
    
}
