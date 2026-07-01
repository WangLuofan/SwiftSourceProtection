//
//  SPSwiftSourceClassSymbol.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/8.
//

import SwiftSyntax

class SPSwiftSourceClassSymbol: SPSwiftSourceSymbol {
    var children: [SPSwiftSourceSymbol] = []
    
    init(sourceFile: File, symbolScope: SymbolScope, sourceLocation: SourceLocation) {
        super.init(sourceFile: sourceFile, symbolScope: symbolScope, nodeKind: .class, sourceLocation: sourceLocation)
    }
    
    override init(sourceFile: File, symbolScope: SymbolScope, nodeKind: NodeKind, sourceLocation: SourceLocation) {
        super.init(sourceFile: sourceFile, symbolScope: symbolScope, nodeKind: nodeKind, sourceLocation: sourceLocation)
    }
}
