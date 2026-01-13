//
//  SwiftSourceScope.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2026/1/12.
//

class SwiftSourceScopeManager {
    nonisolated(unsafe) static let sharedManager: SwiftSourceScopeManager = SwiftSourceScopeManager()
    private lazy var globalScope: [SwiftSourceScope] = [SwiftSourceScope]()
    
    var currentScope: SwiftSourceScope?
    
    func pushScope() {
        let scope: SwiftSourceScope = SwiftSourceScope()
        if self.currentScope == nil {
            self.globalScope.append(scope)
        } else {
            scope.prev = self.currentScope
            self.currentScope?.next.append(scope)
        }
        
        self.currentScope = scope
    }
    
    func popScope() {
        self.currentScope = self.currentScope?.prev
    }
}

class SwiftSourceScope {
    
    lazy var symbols: [String: SwiftSourceSymbol] = [String: SwiftSourceSymbol]()
    
    var prev: SwiftSourceScope?
    lazy var next: [SwiftSourceScope] = [SwiftSourceScope]()
    
}
