//
//  SPSwiftSourceFunctionSymbol.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/8.
//

class SPSwiftSourceFunctionSymbol: SPSwiftSourceVariableSymbol {
    var labels: [String] = []
    
    init(sourceFile: File) {
        super.init(sourceFile: sourceFile, nodeKind: .function)
    }
}
