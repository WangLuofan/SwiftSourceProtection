//
//  SwiftSourceBaseInfo.swift
//  SwiftSourceProtection
//
//  Created by WangLuofan on 2025/12/12.
//

enum SwiftSourceType: Int {
    case Unknown
    case Class
    case Function
    case Variable
    case `Protocol`
    case Enum
    case EnumCase
}

class SwiftSourceBaseInfo: SwiftSourceInfoProtocol {
    var sourceType: SwiftSourceType = .Unknown
    
    var parent: SwiftSourceBaseInfo?
    lazy var children: [String: SwiftSourceBaseInfo] = [String: SwiftSourceBaseInfo]()
    
    var filePath: String = ""
    var accessControl: SwiftSourceAccessControl = .Internal
    
    var symbolName: String = ""
    var identifier: String = ""
    
    var isStatic: Bool = false
    var isOverride: Bool = false
    var isClass: Bool = false
    var isFinal: Bool = false
    var isMember: Bool = false
    
    init(sourcetype: SwiftSourceType) {
        self.sourceType = sourcetype
    }
}
