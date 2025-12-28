//
//  SwiftSourceScope.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2025/12/27.
//

class SwiftSourceScopeManager: @unchecked Sendable {
    static let shared: SwiftSourceScopeManager = SwiftSourceScopeManager()
    
    private lazy var parentStack: [SwiftSourceBaseInfo] = [SwiftSourceBaseInfo]()
    private let globalScope: SwiftSourceScope = SwiftSourceScope()
    
    lazy var currentScope: SwiftSourceScope = self.globalScope
    
    func pushScopeWithNoCreate() {
        guard let nextScope = currentScope.scopeQueue.first else {
            return
        }
        
        self.currentScope = nextScope
    }
    
    func pushScope() {
        let scope: SwiftSourceScope = SwiftSourceScope()
        
        self.currentScope.scopeQueue.append(scope)
        scope.prevScope = self.currentScope
        
        self.currentScope = scope
    }
    
    func popScope() {
        guard let prevScope = currentScope.prevScope else {
            return
        }
        
        self.currentScope = prevScope
        
        if !self.parentStack.isEmpty {
            self.parentStack.removeLast()
        }
    }
    
    func popScopeWithRemove() {
        self.popScope()
        
        if !self.currentScope.scopeQueue.isEmpty {
            self.currentScope.scopeQueue.removeFirst()
        }
    }
    
    func pushSourceInfo(_ sourceInfo: SwiftSourceBaseInfo) {
        self.currentScope.symbols[sourceInfo.symbolName] = sourceInfo
        sourceInfo.parent = self.parentStack.last
    }
    
    func isCurrentGlobalScope() -> Bool {
        return self.currentScope === self.globalScope
    }
}

class SwiftSourceScope {
    lazy var scopeQueue: [SwiftSourceScope] = [SwiftSourceScope]()
    
    var prevScope: SwiftSourceScope?
    
    lazy var symbols: [String: SwiftSourceBaseInfo] = [String: SwiftSourceBaseInfo]()
}
