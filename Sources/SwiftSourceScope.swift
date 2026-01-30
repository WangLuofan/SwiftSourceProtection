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
    
    func pushScope(symbol: SwiftSourceSymbol?) {
        let scope: SwiftSourceScope = SwiftSourceScope()
        
        scope.prev = self.currentScope
        self.currentScope?.next.append(scope)
        
        self.currentScope = scope
        symbol?.childScope = scope
    }
    
    func popScope() {
        if self.currentScope?.prev == nil {
            return
        }
        
        self.currentScope = self.currentScope?.prev
    }
    
    func findSymbol(
        _ symbolName: String,
        inScope scope: SwiftSourceScope? = nil,
        isIntance: Bool = true
    ) -> SwiftSourceSymbol? {
        
        var scope = (scope ?? self.currentScope)
        while scope != nil {
            for (_, symbol) in scope!.symbols {
                
                if symbol.identifierName == symbolName {
                    if symbol.isStatic == isIntance && symbol.isClass == isIntance {
                        continue
                    }
                    
                    return symbol
                }
            }
            
            scope = scope?.prev
        }
        
        return nil
    }
}

class SwiftSourceScope {
    
    lazy var symbols: [String: SwiftSourceSymbol] = [String: SwiftSourceSymbol]()
    
    var prev: SwiftSourceScope?
    lazy var next: [SwiftSourceScope] = [SwiftSourceScope]()
    
    func pushSymbol(_ symbol: SwiftSourceSymbol) {
        guard !symbol.identifier.isEmpty else {
            return
        }
        
        self.symbols[symbol.identifier] = symbol
    }
    
}
