//
//  SwiftSourceClassInfo.swift
//  SwiftRefactorUtil
//
//  Created by WangLuofan on 2025/12/12.
//

class SwiftSourceClassInfo: SwiftSourceBaseInfo {
    
    var superClasses: [String] = []
    
    override var sourceType: SwiftSourceType {
        return .Class
    }
}
