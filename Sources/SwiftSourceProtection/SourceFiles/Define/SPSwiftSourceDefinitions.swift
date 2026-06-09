//
//  SPSwiftSourceDefinitions.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/8.
//

enum SPSwiftSourceAccessLevel {
    case `open`
    case `public`
    case `package`
    case `internal`
    case `fileprivate`
    case `private`
}

enum SPSwiftSourceNodeKind {
    case `class`
    case `protocol`
    case `struct`
    case variable
    case function
    case label
    case `enum`
    case enumCase
}

enum SPSwiftSourceVariableKind {
    case member
    case global
    case local
}
