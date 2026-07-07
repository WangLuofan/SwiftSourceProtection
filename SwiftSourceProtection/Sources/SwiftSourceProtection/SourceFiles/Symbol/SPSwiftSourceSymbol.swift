//
//  SPSwiftSourceSymbol.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/8.
//

import Foundation
import SwiftSyntax

class SPSwiftSourceSymbol {
    var sourceFile: File
    
    var nodeKind: NodeKind
    
    var symbolScope: SymbolScope
    
    var sourceLocation: SourceLocation
    
    var originalSymbolName: String = ""
    
    var confusedSymbolName: String?
    
    var parent: SPSwiftSourceSymbol?
    
    var symbolUSR: String? {
        didSet {
            if let symbolUSR {
                IndexStore.indexStore.set(usr: symbolUSR, forSymbol: self)
            }
        }
    }
    
    init(sourceFile: File, symbolScope: SymbolScope, nodeKind: NodeKind, sourceLocation: SourceLocation) {
        self.sourceFile = sourceFile
        self.nodeKind = nodeKind
        self.symbolScope = symbolScope
        self.sourceLocation = sourceLocation
        
        IndexStore.indexStore.setSourceLocation(forSymbol: self)
    }
}
