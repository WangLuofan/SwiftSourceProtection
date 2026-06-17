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
    
    var originalSymbolName: String?
    
    var confusedSymbolName: String?
    
    init(sourceFile: File, symbolScope: SymbolScope, nodeKind: NodeKind) {
        self.sourceFile = sourceFile
        self.nodeKind = nodeKind
        self.symbolScope = symbolScope
    }
}
