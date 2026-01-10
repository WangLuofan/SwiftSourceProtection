//
//  SwiftSourceInfoProtocol.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2026/1/9.
//

enum SwiftSourceAccessControl {
    case Open
    case Public
    case Internal
    case Package
    case FilePrivate
    case Private
}

protocol SwiftSourceInfoProtocol {
    var sourceType: SwiftSourceType { get set }
    
    var parent: SwiftSourceBaseInfo? { get set }
    
    var filePath: String { get set }
    var accessControl: SwiftSourceAccessControl { get set }
    
    var symbolName: String { get set }
    var identifier: String { get set }
    
    var isStatic: Bool { get set }
    var isOverride: Bool { get set }
    var isClass: Bool { get set }
    var isFinal: Bool { get set }
    var isMember: Bool { get set }
}
