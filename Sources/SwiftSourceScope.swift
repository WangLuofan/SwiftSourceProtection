//
//  SwiftSourceScope.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2026/1/12.
//

import SwiftSyntax

class SwiftSourceScopeManager {
    nonisolated(unsafe) static let sharedManager: SwiftSourceScopeManager = SwiftSourceScopeManager()
    
    var currentScope: SwiftSourceScope?
    private var globalScope: SwiftSourceScope = SwiftSourceScope()
    
    init() {
        self.currentScope = self.globalScope
    }
    
    func isCurrentGlobalScope() -> Bool {
        return self.currentScope === self.globalScope
    }
    
    func pushScope() {
        let scope: SwiftSourceScope = SwiftSourceScope()
        scope.prev = self.currentScope
        self.currentScope?.next.append(scope)
        self.currentScope = scope          // 直接指向新建的 scope
    }

    func popScope() {
        guard let prev = self.currentScope?.prev else { return }
        
        let leavingScope = self.currentScope
        self.currentScope = prev
        
        if let leavingScope {
            self.currentScope?.next.removeAll { $0 === leavingScope }
        }
    }
    
    func findSymbol( _ node: SyntaxProtocol?, inFile: String) -> SwiftSourceSymbol? {
        guard let node = node else { return nil }
        let nodeID = node.id

        var scope = self.currentScope
        while scope != nil {
            for (_, symbol) in scope!.symbols {
                if let astNode = symbol.ASTNode,
                   symbol.symbolFilePath == inFile {
                    if astNode.id.indexInTree == nodeID.indexInTree {
                        return symbol
                    }
                }
            }

            scope = scope?.prev
        }

        return nil
    }
    
    func findSymbol(_ symbolName: String?, inScope scope: SwiftSourceScope? = nil) -> SwiftSourceSymbol? {
        guard let symbolName else {
            return nil
        }
        
        var scope = (scope ?? self.currentScope)
        while scope != nil {
            for (_, symbol) in scope!.symbols {
                if SwiftConfusedHelper.getConfusedOriginalSymbolName(symbol.originalSymbol) == SwiftConfusedHelper.getConfusedOriginalSymbolName(symbolName) {
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
        if symbol.nodeKind == .function,
           let symbol: SwiftSourceFunctionSymbol = symbol as? SwiftSourceFunctionSymbol {
            guard !symbol.signature.isEmpty else {
                return
            }
            
            self.symbols[symbol.signature] = symbol
        }
        
        guard !symbol.originalSymbol.isEmpty else {
            return
        }
        
        self.symbols[symbol.originalSymbol] = symbol
    }
    
}
