//
//  SwiftSourceFunctionInfo.swift
//  SwiftSourceProtection
//
//  Created by WangLuofan on 2025/12/12.
//

class SwiftSourceFunctionInfo: SwiftSourceBaseInfo {
    
    var signature: String?
    var returnType: String?
    
    init() {
        super.init(sourcetype: .Function)
    }
}
