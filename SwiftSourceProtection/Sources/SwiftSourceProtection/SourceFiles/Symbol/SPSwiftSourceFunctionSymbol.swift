//
//  SPSwiftSourceFunctionSymbol.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/8.
//

import SwiftSyntax

class SPSwiftSourceFunctionSymbol: SPSwiftSourceVariableSymbol {
    var labels: [String] = []
    var confusedLabels: [String] = []
    
    var arguments: [SPSwiftSourceSymbol] = []
    var signature: String
    
    init(sourceFile: File, signature: String, symbolScope: SymbolScope, sourceLocation: SourceLocation) {
        self.signature = signature
        super.init(sourceFile: sourceFile, symbolScope: symbolScope, nodeKind: .function, sourceLocation: sourceLocation)
    }
}
