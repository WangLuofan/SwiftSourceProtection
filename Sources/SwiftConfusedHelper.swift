//
//  SwiftConfusedHelper.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2026/1/17.
//

import SwiftSyntax
import SwiftOperators

class SwiftConfusedHelper {
    nonisolated(unsafe) private static var confusedTable: [String: String] = [String: String]()
    nonisolated(unsafe) private static var reversedTable: [String: String] = [String: String]()
    
    static func confusedSymbol(_ symbol: SwiftSourceSymbol) -> String {
        guard self.shouldConfuseSymbol(symbol) else {
            return symbol.originalSymbol
        }
        
        if let confusedSymbol = symbol.confusedSymbol {
            return confusedSymbol
        }
        
        let confusedSymbolName: String = self.confusedSymbolName(symbol.originalSymbol)
        symbol.confusedSymbol = confusedSymbolName
        
        if symbol.nodeKind == .function,
           let funcSymbol: SwiftSourceFunctionSymbol = symbol as? SwiftSourceFunctionSymbol {
            for (identifier, label) in funcSymbol.labels {
                if identifier == "_" {
                    continue
                }
                
                let confusedLabel: String = self.confusedSymbolName(label.originalSymbol)
                label.confusedSymbol = confusedLabel
            }
        }
        
        return confusedSymbolName
    }
    
    private static func shouldConfuseSymbol(_ symbol: SwiftSourceSymbol) -> Bool {
        if symbol.originalSymbol.isEmpty {
            return false
        }
        
        if symbol.nodeKind == .class ||
            symbol.nodeKind == .enum || symbol.nodeKind == .enumCase ||
            symbol.nodeKind == .protocol || symbol.nodeKind == .struct {
            return true
        }

        if !symbol.isMember {
            return true
        }

        guard let parent: SwiftSourceClassSymbol = symbol.parent as? SwiftSourceClassSymbol else {
            return true
        }

        for child in parent.children {
            if symbol.nodeKind != child.nodeKind {
                continue
            }
            
            if symbol.nodeKind == .function,
               let funcSymbol: SwiftSourceFunctionSymbol = symbol as? SwiftSourceFunctionSymbol,
               let childFuncSymbol: SwiftSourceFunctionSymbol = child as? SwiftSourceFunctionSymbol {
                
                if funcSymbol.signature != childFuncSymbol.signature {
                    continue
                }
                
                if symbol.isOverride, let inheritedTypes = parent.inheritedType {
                    for inheritedType in inheritedTypes {
                        if let ancestorCls = SwiftSourceScopeManager.sharedManager.findSymbol(inheritedType) as? SwiftSourceClassSymbol {
                            for ancestorChild in ancestorCls.children {
                                if ancestorChild.nodeKind != .function {
                                    continue
                                }
                                if let ancestorChild: SwiftSourceFunctionSymbol = ancestorChild as? SwiftSourceFunctionSymbol,
                                   ancestorChild.signature == childFuncSymbol.signature {
                                    return self.shouldConfuseSymbol(ancestorCls)
                                }
                            }
                        }
                    }
                }
                
                return true
            } else {
                if symbol.originalSymbol != child.originalSymbol || symbol.nodeKind != child.nodeKind {
                    continue
                }
                
                if symbol.isOverride, let inheritedTypes = parent.inheritedType {
                    for inheritedType in inheritedTypes {
                        if let ancestorCls = SwiftSourceScopeManager.sharedManager.findSymbol(inheritedType) as? SwiftSourceClassSymbol {
                            for ancestorChild in ancestorCls.children {
                                if ancestorChild.originalSymbol == child.originalSymbol {
                                    return self.shouldConfuseSymbol(ancestorCls)
                                }
                            }
                        }
                    }
                }
                
                return true
            }
        }

        return false
    }
    
    static func confusedSymbolName(_ symbol: String, minLength: Int = 1, maxLength: Int = 31) -> String {
        if let confusedSymbolName: String = self.confusedTable[symbol] {
            return confusedSymbolName
        }
        
        let lowercase: String = "abcdefghijklmnopqrstuvwxyz"
        let uppercase: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let digital: String = "0123456789"
        let underScore: String = "_"
        
        let randomSymbolLength: Int = Int.random(in: minLength...maxLength)
        let firstCharset: [String.Element] = Array(lowercase + uppercase + underScore)
        
        var randomSymbolName = String(firstCharset[Int.random(in: 0..<firstCharset.count)])
        let allCharacters: [String] = [lowercase, uppercase, digital]
        
        for _ in 1..<randomSymbolLength {
            let randomIndex = Int.random(in: 0..<allCharacters.count)
            if randomIndex == 3 {
                randomSymbolName += underScore
                continue
            }
            
            let randomItem = Int.random(in: 0..<allCharacters[randomIndex].count)
            
            let stringArr: [String.Element] = Array(allCharacters[randomIndex])
            randomSymbolName += String(stringArr[randomItem])
        }
        
        if self.reversedTable[randomSymbolName] != nil || randomSymbolName.isSwiftKeyWord {
            return self.confusedSymbolName(symbol)
        }
        
        self.confusedTable[symbol] = randomSymbolName
        self.reversedTable[randomSymbolName] = symbol
        
        return randomSymbolName
    }
}

extension SwiftConfusedHelper {
    static func promoteBuiltInType(left: String, right: String) -> String {
        if left == right {
            return left
        }
        
        let table = [
            "Int8", "Int16", "Int", "Int32", "Int64", "Int128",
            "UInt8", "UInt16", "UInt", "UInt32", "UInt64", "UInt128",
            "Float", "Float32", "Double", "Float64", "Float80"
        ]
        
        if let leftIndex: Int = table.firstIndex(of: left),
           let rightIndex: Int = table.firstIndex(of: right) {
            return leftIndex > rightIndex ? left : right
        }
        
        return left
    }
    
    static func inferMemberAccessExprSyntaxType(_ memberAccessExpr: MemberAccessExprSyntax, forSymbol symbol: SwiftSourceSymbol?) -> String? {
        var baseSymbol = self.lookupSymbolNodeForExpr(memberAccessExpr.base, forSymbol: symbol)
        if baseSymbol?.nodeKind == .variable,
           let symbolName: String = baseSymbol?.symbolType {
            baseSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(symbolName)
        }
        
        if let declName: DeclReferenceExprSyntax = memberAccessExpr.declName.as(DeclReferenceExprSyntax.self),
           let children = baseSymbol?.children {
            for child in children {
                if child.originalSymbol == declName.baseName.text {
                    return child.symbolType
                }
            }
        }
        
        return nil
    }
    
    private static func lookupSymbolNodeForExpr(_ expr: ExprSyntaxProtocol?, forSymbol symbol: SwiftSourceSymbol? = nil,
                                                baseSymbol: SwiftSourceSymbol? = nil) -> SwiftSourceSymbol?
    {
        
        if let baseExpr: DeclReferenceExprSyntax = expr?.as(DeclReferenceExprSyntax.self) {
            if baseExpr.baseName.text == "self" || baseExpr.baseName.text == "Self" {
                var parentSymbol: SwiftSourceSymbol? = symbol?.parent
                while parentSymbol?.nodeKind != .class {
                    parentSymbol = parentSymbol?.parent
                    continue
                }
                
                return parentSymbol
            } else {
                if let baseSymbol: SwiftSourceClassSymbol = baseSymbol as? SwiftSourceClassSymbol {
                    var symbol: SwiftSourceSymbol?
                    for child in baseSymbol.children {
                        if child.originalSymbol == baseExpr.baseName.text {
                            symbol = child
                            break
                        }
                    }
                    
                    if symbol?.nodeKind == .variable,
                       let symbolType: String = symbol?.symbolType {
                        return SwiftSourceScopeManager.sharedManager.findSymbol(symbolType)
                    }
                    
                    return symbol
                } else {
                    let symbol = SwiftSourceScopeManager.sharedManager.findSymbol(baseExpr.baseName.text)
                    
                    if symbol?.nodeKind == .class {
                        
                    }
                    
                    return symbol
                }
            }
        } else if let baseExpr: FunctionCallExprSyntax = expr?.as(FunctionCallExprSyntax.self) {
            if let baseSymbol: SwiftSourceClassSymbol = baseSymbol as? SwiftSourceClassSymbol {
                if let calledExpr: DeclReferenceExprSyntax = baseExpr.calledExpression.as(DeclReferenceExprSyntax.self) {
                    for child in baseSymbol.children {
                        if child.originalSymbol == calledExpr.baseName.text {
                            return child
                        }
                    }
                }
            } else if let calledExpr: MemberAccessExprSyntax = baseExpr.calledExpression.as(MemberAccessExprSyntax.self) {
                let symbol = self.lookupSymbolNodeForExpr(calledExpr, forSymbol: symbol, baseSymbol: baseSymbol)
                if symbol?.nodeKind == .function,
                   let symbol: SwiftSourceFunctionSymbol = symbol as? SwiftSourceFunctionSymbol {
                    return SwiftSourceScopeManager.sharedManager.findSymbol(symbol.returnType)
                }
            }
        } else if let baseExpr: MemberAccessExprSyntax = expr?.as(MemberAccessExprSyntax.self) {
            let baseSymbol = self.lookupSymbolNodeForExpr(baseExpr.base, forSymbol: symbol, baseSymbol: baseSymbol)
            return self.lookupSymbolNodeForExpr(baseExpr.declName, forSymbol: symbol, baseSymbol: baseSymbol)
        }
        
        return nil
    }
    
    static func inferClosureExprSyntaxType(_ closureExpr: ClosureExprSyntax, forSymbol symbol: SwiftSourceSymbol? = nil) -> String? {
        var typeString: String?
        
        if let parameters: ClosureParameterListSyntax = closureExpr.signature?.parameterClause?.as(ClosureParameterClauseSyntax.self)?.parameters.as(ClosureParameterListSyntax.self) {
            if parameters.count == 0 {
                typeString = "()"
            } else {
                typeString = "(\(parameters.trimmedDescription))"
            }
        }
        
        if let returnClause: ReturnClauseSyntax = closureExpr.signature?.returnClause {
            if let identTypeSyntax: IdentifierTypeSyntax = returnClause.type.as(IdentifierTypeSyntax.self) {
                typeString = ((typeString != nil) ? typeString! : "()") + " -> \(identTypeSyntax.name.text)"
            }
        } else {
            if let expr: ExprSyntax = closureExpr.statements.last?.item.as(ExprSyntax.self),
               let stmtType: String = self.inferExprSyntaxType(expr, forSymbol: symbol) {
                typeString = ((typeString != nil) ? typeString! : "()") + " -> \(stmtType)"
            }
        }
        
        return typeString
    }
    
    static func inferExprSyntaxType(_ expr: ExprSyntaxProtocol, forSymbol symbol: SwiftSourceSymbol? = nil) -> String? {
        if let _ = expr.as(IntegerLiteralExprSyntax.self) {
            return "Int"
        } else if let _ = expr.as(StringLiteralExprSyntax.self) {
            return "String"
        } else if let _ = expr.as(FloatLiteralExprSyntax.self) {
            return "Double"
        } else if let _ = expr.as(ArrayExprSyntax.self) {
            return "Array"
        } else if let _ = expr.as(DictionaryExprSyntax.self) {
            return "Dictionary"
        } else if let closureExpr: ClosureExprSyntax = expr.as(ClosureExprSyntax.self) {
            return self.inferClosureExprSyntaxType(closureExpr, forSymbol: symbol)
        } else if let _ = expr.as(BooleanLiteralExprSyntax.self) {
            return "Bool"
        } else if let _ = expr.as(RegexLiteralExprSyntax.self) {
            return "Regex"
        } else if let callExprSyntax: FunctionCallExprSyntax = expr.as(FunctionCallExprSyntax.self) {
            return self.inferExprSyntaxType(callExprSyntax.calledExpression)
        } else if let declRefExpr: DeclReferenceExprSyntax = expr.as(DeclReferenceExprSyntax.self) {
            if declRefExpr.baseName.text == "self" || declRefExpr.baseName.text == "Self" {
                var parentSymbol: SwiftSourceSymbol? = symbol?.parent
                while parentSymbol?.nodeKind != .class {
                    parentSymbol = parentSymbol?.parent
                    continue
                }
                
                return parentSymbol?.originalSymbol
            } else if let symbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(declRefExpr.baseName.text) {
                if symbol.nodeKind == .function {
                    return (symbol as? SwiftSourceFunctionSymbol)?.returnType
                }
                
                return symbol.symbolType
            }
        } else if let macroExpr: MacroExpansionExprSyntax = expr.as(MacroExpansionExprSyntax.self) {
            let macroName = macroExpr.macroName.text
            switch macroName {
            case "file", "fileID", "filePath", "function":
                return "String"
            case "line", "column":
                return "Int"
            default:
                break
            }
        } else if let memberAccessExpr: MemberAccessExprSyntax = expr.as(MemberAccessExprSyntax.self) {
            return self.inferMemberAccessExprSyntaxType(memberAccessExpr, forSymbol: symbol)
        } else if let forceUnwrapExpr: ForceUnwrapExprSyntax = expr.as(ForceUnwrapExprSyntax.self) {
            return self.inferExprSyntaxType(forceUnwrapExpr.expression, forSymbol: symbol)
        } else if let _ = expr.as(TupleExprSyntax.self) {
            
        } else if let _ = expr.as(SubscriptCallExprSyntax.self) {
            
        } else if let _ = expr.as(KeyPathExprSyntax.self) {
            
        } else if let seqExpr = expr.as(SequenceExprSyntax.self) {
            guard let foldExpr = try? OperatorTable.standardOperators.foldSingle(seqExpr) else {
                return nil
            }
            
            return self.inferExprSyntaxType(foldExpr, forSymbol: symbol)
        } else if let infixOperatorExpr = expr.as(InfixOperatorExprSyntax.self) {
            if let oper: BinaryOperatorExprSyntax = infixOperatorExpr.operator.as(BinaryOperatorExprSyntax.self) {
                if oper.isBooleanOperator {
                    return "Bool"
                }
                
                let leftOperand = self.inferExprSyntaxType(infixOperatorExpr.leftOperand, forSymbol: symbol)
                let rightOperand = self.inferExprSyntaxType(infixOperatorExpr.rightOperand, forSymbol: symbol)
                
                if let leftOperand, let rightOperand {
                    return self.promoteBuiltInType(left: leftOperand, right: rightOperand)
                }
                
                return leftOperand ?? rightOperand
            }
        } else if let _ = expr.as(IsExprSyntax.self) {
            return "Bool"
        } else if let prefixOper: PrefixOperatorExprSyntax = expr.as(PrefixOperatorExprSyntax.self) {
            if prefixOper.operator.text == "!" {
                return "Bool"
            }
            
            return self.inferExprSyntaxType(prefixOper.expression, forSymbol: symbol)
        } else if let asExpr: AsExprSyntax = expr.as(AsExprSyntax.self) {
            if let typeAnnon: IdentifierTypeSyntax = asExpr.type.as(IdentifierTypeSyntax.self) {
                return typeAnnon.name.text
            } else if let typeAnnon: OptionalTypeSyntax = asExpr.type.as(OptionalTypeSyntax.self),
                      let idTypeSyntax: IdentifierTypeSyntax = typeAnnon.wrappedType.as(IdentifierTypeSyntax.self) {
                return idTypeSyntax.name.text
            }
        } else if let switchExpr: SwitchExprSyntax = expr.as(SwitchExprSyntax.self) {
            return self.inferExprSyntaxType(switchExpr.subject)
        }
        
        return nil  // 暂时无法推导
    }
    
    // funcName_label1_label2_...
    static func generateFunctionSignature(_ node: SwiftFunctionDeclProtocol) -> String {
        var funcSignature: String = "\(node.name.text)"
        
        node.signature.parameterClause.parameters.forEach { funcSignature.append("_\($0.firstName.text)") }
        
        return funcSignature
    }
}

extension SwiftConfusedHelper {
    static func matchMethodSymbol(_ node: FunctionCallExprSyntax, _ symbol: SwiftSourceSymbol? = nil) -> SwiftSourceFunctionSymbol? {
        let methodSignature: String = self.inferMethodSignature(node)
        
        var baseSymbolName: String?
        var baseSymbol: SwiftSourceSymbol?
        if let declRefSyntax: DeclReferenceExprSyntax = node.calledExpression.as(DeclReferenceExprSyntax.self) {
            baseSymbolName = declRefSyntax.baseName.text
        } else if let memberAccessExpSyntax: MemberAccessExprSyntax = node.calledExpression.as(MemberAccessExprSyntax.self) {
            if let base: DeclReferenceExprSyntax = memberAccessExpSyntax.base?.as(DeclReferenceExprSyntax.self) {
                baseSymbolName = base.baseName.text
            } else {
                baseSymbol = symbol
                baseSymbolName = symbol?.originalSymbol
            }
        }
        
        if let baseSymbolName {
            if baseSymbol == nil {
                baseSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(baseSymbolName)
            }
            
            if let baseSymbol, baseSymbol.isClassNodeKind {
                for child in baseSymbol.children {
                    if child.nodeKind != .function {
                        continue
                    }
                    
                    if let funcSymbol: SwiftSourceFunctionSymbol = child as? SwiftSourceFunctionSymbol,
                       funcSymbol.signature == methodSignature {
                        return funcSymbol
                    }
                }
            }
        } else {
            
        }
        
        return nil
    }
    
    private static func inferMethodSignature(_ node: FunctionCallExprSyntax) -> String {
        var signature: String = ""
        
        if let calledExpression: DeclReferenceExprSyntax = node.calledExpression.as(DeclReferenceExprSyntax.self) {
            if let baseSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(calledExpression.baseName.text) {
                if baseSymbol.isClassNodeKind {
                    signature = "init"
                }
            }
        } else if let calledExpression: MemberAccessExprSyntax = node.calledExpression.as(MemberAccessExprSyntax.self) {
            signature = calledExpression.declName.baseName.text
        }
        
        node.arguments.forEach { labeledExprSyntax in
            if let labelName: String = labeledExprSyntax.label?.text {
                signature += "_\(labelName)"
            }
        }
        
        return signature
    }
    
    static func findNodeParent(_ node: SyntaxProtocol, _ kind: SyntaxKind) -> SyntaxProtocol? {
        var parent = node.parent
        while parent != nil {
            if parent?.kind == kind {
                break
            }
            
            parent = parent?.parent
        }
        
        return parent
    }
}
