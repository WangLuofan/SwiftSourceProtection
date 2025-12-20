//
//  SwiftSourcePropertyInfo.swift
//  SwiftRefactorUtil
//
//  Created by WangLuofan on 2025/12/12.
//

class SwiftSourcePropertyInfo: SwiftSourceBaseInfo {
    var type: String = ""
    
    override var sourceType: SwiftSourceType {
        return .Property
    }
}
