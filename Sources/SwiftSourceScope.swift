//
//  SwiftSourceScope.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2025/12/22.
//

class SwiftSourceScopeManager: @unchecked Sendable {
    private static let shared: SwiftSourceScopeManager = SwiftSourceScopeManager()
    
    private let globalScope: SwiftSourceScope = SwiftSourceScope()
    
    lazy var currentScope: SwiftSourceScope = globalScope
    
    static func pushScope() {
        let scope: SwiftSourceScope = SwiftSourceScope()
        
        self.shared.currentScope.nextScope = scope
        scope.prevScope = self.shared.currentScope
    }
    
    static func popScope() {
        self.shared.currentScope = self.shared.currentScope.prevScope ?? self.shared.globalScope
    }
    
    static func pushSymbol(_ symbolName: String, sourceInfo: SwiftSourceBaseInfo) {
        self.shared.currentScope.symbols[symbolName] = sourceInfo
    }
    
    static func resetScope() {
        self.shared.currentScope = self.shared.globalScope
    }
}

class SwiftSourceScope: @unchecked Sendable {
    
    var prevScope: SwiftSourceScope?
    var nextScope: SwiftSourceScope?
    
    lazy var symbols: [String: SwiftSourceBaseInfo] = [String: SwiftSourceBaseInfo]()

}
