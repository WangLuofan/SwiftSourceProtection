//
//  SwiftSourceFunctionInfo.swift
//  SwiftSourceProtection
//
//  Created by WangLuofan on 2025/12/12.
//

class SwiftSourceFunctionInfo: SwiftSourceBaseInfo {
    override var sourceType: SwiftSourceType {
        return .Function
    }
    
    var functionName: String?
    var signature: String?
    var returnType: String?
}
