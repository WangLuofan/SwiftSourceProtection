//
//  SPSwiftSourceDefinitions.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/8.
//

enum AccessLevel {
    case `open`
    case `public`
    case `package`
    case `internal`
    case `fileprivate`
    case `private`
}

enum NodeKind {
    case `class`
    case `protocol`
    case `struct`
    case variable
    case function
    case label
    case `enum`
    case enumCase
}

enum SymbolScope {
    case member
    case global
    case local
}
