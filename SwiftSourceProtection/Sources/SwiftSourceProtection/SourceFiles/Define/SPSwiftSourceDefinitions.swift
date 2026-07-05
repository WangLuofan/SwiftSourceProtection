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

enum SymbolAttribute: String {
    case resultBuilder = "resultBuilder"
}

struct ResultBuilderMethod {
    
    private static let buildMethods: [String] = [
        "buildExpression(_:)",
        "buildBlock(_:)",
        "buildOptional(_:)",
        "buildEither(first:)",
        "buildEither(second:)",
        "buildArray(_:)",
        "buildLimitedAvailability(_:)",
        "buildFinalResult(_:)"
    ]
    
    static func isResultBuilderMethod(_ methodName: String) -> Bool {
        return self.buildMethods.contains(methodName)
    }
}
