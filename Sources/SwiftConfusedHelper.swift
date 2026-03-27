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
            for label in funcSymbol.labels {
                let confusedLabel: String = self.confusedSymbolName(label.originalSymbol)
                label.confusedSymbol = confusedLabel
            }
        }
        
        return confusedSymbolName
    }
    
    private static func shouldConfuseSymbol(_ symbol: SwiftSourceSymbol) -> Bool {
        if symbol.originalSymbol.isEmpty || symbol.originalSymbol.isSwiftKeyWord {
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

        for child in parent.members {
            if symbol.nodeKind != child.nodeKind {
                continue
            }
            
            if symbol.nodeKind == .function,
               let funcSymbol: SwiftSourceFunctionSymbol = symbol as? SwiftSourceFunctionSymbol,
               let childFuncSymbol: SwiftSourceFunctionSymbol = child as? SwiftSourceFunctionSymbol {

                if funcSymbol.signature != childFuncSymbol.signature {
                    continue
                }

                if symbol.isOverride, !parent.inheritedType.isEmpty {
                    for inheritedType in parent.inheritedType {
                        if let ancestorCls = SwiftSourceScopeManager.sharedManager.findSymbol(inheritedType) as? SwiftSourceClassSymbol {
                            for ancestorChild in ancestorCls.members {
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
                } else {
                    for inheritedType in parent.inheritedType {
                        if let ancestorCls: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(inheritedType) as? SwiftSourceClassSymbol {
                            if ancestorCls.nodeKind != .protocol {
                                continue
                            }
                            
                            for ancestorChild in ancestorCls.members {
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
                
                if symbol.isOverride {
                    for inheritedType in parent.inheritedType {
                        if let ancestorCls = SwiftSourceScopeManager.sharedManager.findSymbol(inheritedType) as? SwiftSourceClassSymbol {
                            for ancestorChild in ancestorCls.members {
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
        if symbol.isSwiftKeyWord {
            return symbol
        }
        
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
    
    static func getConfusedOriginalSymbolName(_ symbolName: String) -> String {
        guard let originalSymbolName: String = self.reversedTable[symbolName] else {
            return symbolName
        }
        
        return originalSymbolName
    }
}

extension SwiftConfusedHelper {
    static func detectTypeSyntax(_ type: TypeSyntax) -> SwiftSymbolType {
        if let type = type.as(IdentifierTypeSyntax.self) {
            return SwiftSymbolSingleType(typeName: type.name.text)
        } else if let funcType = type.as(FunctionTypeSyntax.self) {
            let symbolFuncType: SwiftFunctionType = SwiftFunctionType()
            symbolFuncType.returnType = self.detectTypeSyntax(funcType.returnClause.type)
            funcType.parameters.forEach { tupleTypeElemSyntax in
                symbolFuncType.elements.append(self.detectTypeSyntax(tupleTypeElemSyntax.type))
            }
            
            return symbolFuncType
        } else if let tupleType = type.as(TupleTypeSyntax.self) {
            let symbolTupleType: SwiftSymbolTupleType = SwiftSymbolTupleType()
            tupleType.elements.forEach { tupleTypeElemSyntax in
                symbolTupleType.elements.append(self.detectTypeSyntax(tupleTypeElemSyntax.type))
            }
            
            return symbolTupleType
        } else if let optType = type.as(OptionalTypeSyntax.self) {
            return self.detectTypeSyntax(optType.wrappedType)
        } else if let arrType = type.as(ArrayTypeSyntax.self) {
            return SwiftSymbolArrayType(elementType: self.detectTypeSyntax(arrType.element))
        } else if let dictType = type.as(DictionaryTypeSyntax.self) {
            return SwiftSymbolDictionaryType(keyType: self.detectTypeSyntax(dictType.key), valueType: self.detectTypeSyntax(dictType.value))
        } else if let compType = type.as(CompositionTypeSyntax.self) {
            let symbolCompType: SwiftCompositionType = SwiftCompositionType()
            compType.elements.forEach { compTypeElemSyntax in
                symbolCompType.elements.append(self.detectTypeSyntax(compTypeElemSyntax.type))
            }
            
            return symbolCompType
        } else if let someAnyType = type.as(SomeOrAnyTypeSyntax.self) {
            return SwiftSomeAnyType(constraints: self.detectTypeSyntax(someAnyType.constraint))
        } else if let metaType = type.as(MetatypeTypeSyntax.self) {
            return self.detectTypeSyntax(metaType.baseType)
        } else if let attrType = type.as(AttributedTypeSyntax.self) {
            return self.detectTypeSyntax(attrType.baseType)
        }

        return SwiftSymbolUnknownType()
    }
    
    static func inferMemberAccessExprSyntaxType(_ memberAccessExpr: MemberAccessExprSyntax) -> SwiftSymbolType? {
        return nil
    }
     
    static func inferClosureExprSyntaxType(_ closureExpr: ClosureExprSyntax) -> SwiftSymbolType {
        let funcType: SwiftFunctionType = SwiftFunctionType()
        if let returnClause: ReturnClauseSyntax = closureExpr.signature?.returnClause {
            funcType.returnType = SwiftConfusedHelper.detectTypeSyntax(returnClause.type)
        }
        
        if let paramClauseSyntax: ClosureParameterClauseSyntax = closureExpr.signature?.parameterClause?.as(ClosureParameterClauseSyntax.self) {
            paramClauseSyntax.parameters.forEach { closureParamSyntax in
                if let paramType = closureParamSyntax.type {
                    funcType.elements.append(SwiftConfusedHelper.detectTypeSyntax(paramType))
                }
            }
        }
        
        return funcType
    }
    
    static func inferExprSyntaxType(_ expr: ExprSyntaxProtocol) -> SwiftSymbolType {
        if let _ = expr.as(IntegerLiteralExprSyntax.self) {
            return SwiftSymbolSingleType(typeName: "Int")
        } else if let _ = expr.as(StringLiteralExprSyntax.self) {
            return SwiftSymbolSingleType(typeName: "String")
        } else if let _ = expr.as(FloatLiteralExprSyntax.self) {
            return SwiftSymbolSingleType(typeName: "Double")
        } else if let expr: ArrayExprSyntax = expr.as(ArrayExprSyntax.self) {
            let arrType: SwiftSymbolArrayType = SwiftSymbolArrayType()
            if let firstElem = expr.elements.first?.expression as? ExprSyntaxProtocol {
                arrType.elementType = self.inferExprSyntaxType(firstElem)
            }
            return arrType
        } else if let expr: DictionaryExprSyntax = expr.as(DictionaryExprSyntax.self) {
            let dictType: SwiftSymbolDictionaryType = SwiftSymbolDictionaryType()
            
            if let content: DictionaryElementListSyntax = expr.content.as(DictionaryElementListSyntax.self),
               let firstElemSyntax: DictionaryElementSyntax = content.first {
                dictType.keyType = self.inferExprSyntaxType(firstElemSyntax.key)
                dictType.valueType = self.inferExprSyntaxType(firstElemSyntax.value)
            }
            
            return dictType
        } else if let closureExpr: ClosureExprSyntax = expr.as(ClosureExprSyntax.self) {
            return self.inferClosureExprSyntaxType(closureExpr)
        } else if let _ = expr.as(BooleanLiteralExprSyntax.self) {
            return SwiftSymbolSingleType(typeName: "Bool")
        } else if let _ = expr.as(RegexLiteralExprSyntax.self) {
            return SwiftSymbolSingleType(typeName: "Regex")
        } else if let callExprSyntax: FunctionCallExprSyntax = expr.as(FunctionCallExprSyntax.self) {
            return self.inferExprSyntaxType(callExprSyntax.calledExpression)
        } else if let declRefExpr: DeclReferenceExprSyntax = expr.as(DeclReferenceExprSyntax.self) {
            if declRefExpr.baseName.text == "self" || declRefExpr.baseName.text == "Self" {
                if let clsDecl: ClassDeclSyntax = SwiftConfusedHelper.findNodeParent(expr, .classDecl)?.as(ClassDeclSyntax.self),
                   let clsSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(clsDecl.name.text) as? SwiftSourceClassSymbol {
                    return clsSymbol.symbolType
                } else if let clsDecl: ExtensionDeclSyntax = SwiftConfusedHelper.findNodeParent(expr, .extensionDecl)?.as(ExtensionDeclSyntax.self),
                          let clsSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(clsDecl.name.text) as? SwiftSourceClassSymbol {
                    return clsSymbol.symbolType
                } else if let clsDecl: StructDeclSyntax = SwiftConfusedHelper.findNodeParent(expr, .structDecl)?.as(StructDeclSyntax.self),
                          let clsSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(clsDecl.name.text) as? SwiftSourceClassSymbol {
                    return clsSymbol.symbolType
                } else if let clsDecl: ProtocolDeclSyntax = SwiftConfusedHelper.findNodeParent(expr, .protocolDecl)?.as(ProtocolDeclSyntax.self),
                          let clsSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(clsDecl.name.text) as? SwiftSourceClassSymbol {
                    return clsSymbol.symbolType
                } else if let clsDecl: EnumDeclSyntax = SwiftConfusedHelper.findNodeParent(expr, .enumDecl)?.as(EnumDeclSyntax.self),
                          let clsSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(clsDecl.name.text) as? SwiftSourceClassSymbol {
                    return clsSymbol.symbolType
                }
            } else if let symbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(declRefExpr.baseName.text) {
                if symbol.nodeKind == .function {
                    return (symbol as? SwiftSourceFunctionSymbol)?.returnType ?? SwiftSymbolSingleType.voidType
                }
                
                return symbol.symbolType
            }
        } else if let macroExpr: MacroExpansionExprSyntax = expr.as(MacroExpansionExprSyntax.self) {
            let macroName = macroExpr.macroName.text
            switch macroName {
            case "file", "fileID", "filePath", "function":
                return SwiftSymbolSingleType(typeName: "String")
            case "line", "column":
                return SwiftSymbolSingleType(typeName: "Int")
            default:
                break
            }
        } else if let memberAccessExpr: MemberAccessExprSyntax = expr.as(MemberAccessExprSyntax.self) {
            if let type = self.inferMemberAccessExprSyntaxType(memberAccessExpr) {
                return type
            }
        } else if let forceUnwrapExpr: ForceUnwrapExprSyntax = expr.as(ForceUnwrapExprSyntax.self) {
            return self.inferExprSyntaxType(forceUnwrapExpr.expression)
        } else if let _ = expr.as(TupleExprSyntax.self) {
            
        } else if let _ = expr.as(SubscriptCallExprSyntax.self) {
            
        } else if let _ = expr.as(KeyPathExprSyntax.self) {
            
        } else if let seqExpr = expr.as(SequenceExprSyntax.self) {
            guard let foldExpr = try? OperatorTable.standardOperators.foldSingle(seqExpr) else {
                return SwiftSymbolAnyType()
            }
            
            return self.inferExprSyntaxType(foldExpr)
        } else if let infixOperatorExpr = expr.as(InfixOperatorExprSyntax.self) {
            if let oper: BinaryOperatorExprSyntax = infixOperatorExpr.operator.as(BinaryOperatorExprSyntax.self) {
                if oper.isBooleanOperator {
                    return SwiftSymbolSingleType(typeName: "Bool")
                }
                
                let leftOperand = self.inferExprSyntaxType(infixOperatorExpr.leftOperand)
                let rightOperand = self.inferExprSyntaxType(infixOperatorExpr.rightOperand)
                
                if let leftOperand = leftOperand as? SwiftSymbolSingleType, let rightOperand = rightOperand as? SwiftSymbolSingleType {
                    return SwiftSymbolSingleType.promoteBuiltInType(left: leftOperand, right: rightOperand)
                }
                
                return leftOperand
            }
        } else if let optChainingExprSyntax: OptionalChainingExprSyntax = expr.as(OptionalChainingExprSyntax.self) {
            return self.inferExprSyntaxType(optChainingExprSyntax.expression)
        } else if let _ = expr.as(IsExprSyntax.self) {
            return SwiftSymbolSingleType(typeName: "Bool")
        } else if let prefixOper: PrefixOperatorExprSyntax = expr.as(PrefixOperatorExprSyntax.self) {
            if prefixOper.operator.text == "!" {
                return SwiftSymbolSingleType(typeName: "Bool")
            }
            
            return self.inferExprSyntaxType(prefixOper.expression)
        } else if let asExpr: AsExprSyntax = expr.as(AsExprSyntax.self) {
            return SwiftConfusedHelper.detectTypeSyntax(asExpr.type)
        } else if let switchExpr: SwitchExprSyntax = expr.as(SwitchExprSyntax.self) {
            return self.inferExprSyntaxType(switchExpr.subject)
        } else if let _: SuperExprSyntax = expr.as(SuperExprSyntax.self) {
            if let clsDecl: ClassDeclSyntax = Self.findNodeParent(expr, .classDecl)?.as(ClassDeclSyntax.self) {
                return SwiftSymbolSingleType(typeName: clsDecl.name.text)
            } else if let structDecl: StructDeclSyntax = Self.findNodeParent(expr, .structDecl)?.as(StructDeclSyntax.self) {
                return SwiftSymbolSingleType(typeName: structDecl.name.text)
            } else if let enumDecl: EnumDeclSyntax = Self.findNodeParent(expr, .enumDecl)?.as(EnumDeclSyntax.self) {
                return SwiftSymbolSingleType(typeName: enumDecl.name.text)
            } else if let protoDecl: ProtocolDeclSyntax = Self.findNodeParent(expr, .protocolDecl)?.as(ProtocolDeclSyntax.self) {
                return SwiftSymbolSingleType(typeName: protoDecl.name.text)
            }
        }
        
        return SwiftSymbolUnknownType()  // 未知类型
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
            
            if baseSymbol?.isClassNodeKind == true,
               let baseSymbol: SwiftSourceClassSymbol = baseSymbol as? SwiftSourceClassSymbol {
                for child in baseSymbol.members {
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
    
    private static func findFuncSymbol(with signature: String, inSymbol parentSymbol: SwiftSourceClassSymbol?) -> SwiftSourceSymbol? {
        var symbol: SwiftSourceSymbol?
        
        if let parentSymbol {
            for child in parentSymbol.members {
                if child.nodeKind != .function {
                    continue
                }
                
                if (child as? SwiftSourceFunctionSymbol)?.signature == signature {
                    symbol = child
                    break
                }
            }
            
            if symbol == nil {
                for inheritedType in parentSymbol.inheritedType {
                    if let parentSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(inheritedType) as? SwiftSourceClassSymbol {
                        symbol = self.findFuncSymbol(with: signature, inSymbol: parentSymbol)
                        if symbol != nil {
                            break
                        }
                    }
                }
            }
        }
        
        return symbol
    }
    
    static func findChildSymbol(_ clsSymbol: SwiftSourceClassSymbol?, _ symbolName: String, _ nodeKind: SwiftNodeKind? = nil) -> SwiftSourceSymbol? {
        guard let clsSymbol else {
            return nil
        }
        
        var symbol: SwiftSourceSymbol?
        for child in clsSymbol.members {
            if child.originalSymbol == symbolName {
                if nodeKind == nil {
                    symbol = child
                } else if let nodeKind, nodeKind == child.nodeKind {
                    symbol = child
                }
                
                break
            }
        }
        
        if symbol == nil {
            for inheritedType in clsSymbol.inheritedType {
                if let parentSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(inheritedType) as? SwiftSourceClassSymbol {
                    symbol = self.findChildSymbol(parentSymbol, symbolName)
                    if symbol != nil {
                        break
                    }
                }
            }
        }
        
        return symbol
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
