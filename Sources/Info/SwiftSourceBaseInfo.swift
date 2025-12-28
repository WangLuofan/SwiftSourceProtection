//
//  SwiftSourceBaseInfo.swift
//  SwiftSourceProtection
//
//  Created by WangLuofan on 2025/12/12.
//

enum SwiftSourceType {
    case Unknown
    case Class
    case Function
    case Property
    case `Protocol`
    case Enum
}

class SwiftSourceBaseInfo {
    var sourceType: SwiftSourceType {
        return .Unknown
    }
    
    var parent: SwiftSourceBaseInfo?
    var children: [String: SwiftSourceBaseInfo] = [String: SwiftSourceBaseInfo]()
    
    var filePath: String = ""
    var accessControl: SwiftSourceAccessControl = .Internal
    
    var symbolName: String = ""
    var identifier: String = ""
    
    var isStatic: Bool = false
    var isOverride: Bool = false
    var isClass: Bool = false
    var isFinal: Bool = false
    var isMember: Bool = false
}
