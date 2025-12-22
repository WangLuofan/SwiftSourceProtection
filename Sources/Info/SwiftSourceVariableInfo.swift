//
//  SwiftSourcePropertyInfo.swift
//  SwiftSourceProtection
//
//  Created by WangLuofan on 2025/12/12.
//

class SwiftSourceVariableInfo: SwiftSourceBaseInfo {
    var type: String?
    var isLocalVariable: Bool
    
    override var sourceType: SwiftSourceType {
        return .Property
    }
    
    init(_ isLocalVariable: Bool) {
        self.isLocalVariable = isLocalVariable
    }
}
