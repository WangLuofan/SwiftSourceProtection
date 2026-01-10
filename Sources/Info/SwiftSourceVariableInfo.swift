//
//  SwiftSourcePropertyInfo.swift
//  SwiftSourceProtection
//
//  Created by WangLuofan on 2025/12/12.
//

class SwiftSourceVariableInfo: SwiftSourceBaseInfo {
    var type: String?
    
    init() {
        super.init(sourcetype: .Variable)
    }
}
