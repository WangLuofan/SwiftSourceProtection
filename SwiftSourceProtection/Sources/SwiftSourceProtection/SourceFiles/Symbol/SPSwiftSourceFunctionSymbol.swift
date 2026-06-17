//
//  SPSwiftSourceFunctionSymbol.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/8.
//

class SPSwiftSourceFunctionSymbol: SPSwiftSourceVariableSymbol {
    var labels: [String] = []
    var confusedLabels: [String] = []
    
    var functionName: String
    var confusedFunctionName: String?
    
    init(sourceFile: File, funcName: String, symbolScope: SymbolScope) {
        self.functionName = funcName
        super.init(sourceFile: sourceFile, symbolScope: symbolScope, nodeKind: .function)
    }
}
