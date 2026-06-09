//
//  SPSwiftSourceVariableSymbol.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/8.
//

class SPSwiftSourceVariableSymbol: SPSwiftSourceSymbol {
    var accessLevel: SPSwiftSourceAccessLevel = .internal
    
    var variableKind: SPSwiftSourceVariableKind = .global
    
    var isStaticSymbol: Bool = false
    
    var type: String?
    
    override init(sourceFile: File, nodeKind: SPSwiftSourceNodeKind = .variable) {
        super.init(sourceFile: sourceFile, nodeKind: nodeKind)
    }
}
