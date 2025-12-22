//
//  SwiftASTSyntaxRewriter.swift
//  SwiftSourceProtection
//
//  Created by WangLuofan on 2025/12/12.
//
import Foundation
import SwiftSyntax
import SwiftParser
import SwiftSyntaxBuilder

class SwiftASTSyntaxRewriter: SyntaxRewriter {
    private let sourceInfo: SwiftSourceInfo
    private let projectPath: String
    
    init(sourceInfo: SwiftSourceInfo, projectPath: String) {
        self.sourceInfo = sourceInfo
        self.projectPath = projectPath
        
        super.init(viewMode: .sourceAccurate)
    }
    
    //    override func visit(_ node: ImportDeclSyntax) -> DeclSyntax {
    //
    //        var importList: ImportPathComponentListSyntax = ImportPathComponentListSyntax()
    //        node.path.forEach { path in
    //            guard let confusedSymbolName = SwiftConfuseHelper
    //                .confusedSymbolName(symbolName: path.name.text, sourceInfo: self.sourceInfo) else {
    //                return
    //            }
    //
    //            let newPath = path.with(\.name, TokenSyntax(stringLiteral: confusedSymbolName))
    //            importList.append(newPath)
    //        }
    //
    //        let newNode = node.with(\.path, importList)
    //
    //        return super.visit(newNode)
    //    }
    
    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        
        let updatedBindings: [PatternBindingSyntax] = node.bindings.map { bindings in
            guard let identifierPattern = bindings.pattern.as(IdentifierPatternSyntax.self),
                  let name = SwiftConfuseHelper.confusedSymbolName(symbolName: identifierPattern.identifier.text, sourceInfo: self.sourceInfo) else {
                return bindings
            }
            
            let newPattern = PatternSyntax(stringLiteral: name).with(\.leadingTrivia, identifierPattern.leadingTrivia).with(\.trailingTrivia, identifierPattern.trailingTrivia)
            return bindings.with(\.leadingTrivia, bindings.leadingTrivia).with(\.pattern, newPattern).with(\.trailingTrivia, bindings.trailingTrivia)
        }
        
        let newNode = node.with(\.leadingTrivia, node.leadingTrivia).with(\.bindings, PatternBindingListSyntax(updatedBindings)).with(\.trailingTrivia, node.trailingTrivia)
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        let symbolName: String = node.name.text
        guard let confusedName: String = SwiftConfuseHelper.confusedSymbolName(symbolName: symbolName, sourceInfo: self.sourceInfo) else {
            return super.visit(node)
        }
        
        var newNode = node.with(\.name, TokenSyntax(stringLiteral: confusedName).with(\.leadingTrivia, node.name.leadingTrivia).with(\.trailingTrivia, node.name.trailingTrivia))
        
        var confusedInheritedList: InheritedTypeListSyntax = InheritedTypeListSyntax()
        if let inheritedList = node.inheritanceClause {
            let inheritedCount = inheritedList.inheritedTypes.count
            for (inheritedIndex, inheritedType) in inheritedList.inheritedTypes.enumerated() {
                let superClassName = inheritedType.type.trimmedDescription
                guard let confusedSymbolName = SwiftConfuseHelper.confusedSymbolName(symbolName: superClassName, sourceInfo: self.sourceInfo) else {
                    confusedInheritedList.append(inheritedType)
                    continue
                }
                
                var confusedInheritedType: InheritedTypeSyntax = InheritedTypeSyntax(type: TypeSyntax(stringLiteral: confusedSymbolName).with(\.leadingTrivia, inheritedType.type.leadingTrivia).with(\.trailingTrivia, inheritedType.type.trailingTrivia)).with(\.leadingTrivia, inheritedType.leadingTrivia).with(\.trailingTrivia, inheritedType.trailingTrivia)
                if inheritedIndex != inheritedCount - 1 {
                    confusedInheritedType = confusedInheritedType.with(\.trailingComma, .commaToken())
                }
                
                confusedInheritedList.append(confusedInheritedType)
            }
            
            newNode = newNode.with(\.inheritanceClause, InheritanceClauseSyntax(leadingTrivia: node.inheritanceClause?.leadingTrivia, inheritedTypes: confusedInheritedList, trailingTrivia: node.inheritanceClause?.trailingTrivia))
        }
        
        newNode = newNode.with(\.leadingTrivia, node.leadingTrivia).with(\.trailingTrivia, node.trailingTrivia)
        return super.visit(newNode)
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        guard let extendedType = node.extendedType.as(IdentifierTypeSyntax.self), let confusedName: String = SwiftConfuseHelper.confusedSymbolName(symbolName: extendedType.name.text, sourceInfo: self.sourceInfo) else {
            return super.visit(node)
        }
        
        let newExtendedType = IdentifierTypeSyntax(
            name: TokenSyntax.identifier(confusedName),
            genericArgumentClause: extendedType.genericArgumentClause
        ).with(\.leadingTrivia, extendedType.leadingTrivia).with(\.trailingTrivia, extendedType.trailingTrivia)
        
        let newNode = node.with(\.extendedType, TypeSyntax(newExtendedType)).with(\.leadingTrivia, node.leadingTrivia).with(\.trailingTrivia, node.trailingTrivia)
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        guard let confusedFuncName: String = SwiftConfuseHelper.confusedSymbolName(symbolName: node.name.text,
                                                                                   sourceInfo: self.sourceInfo) else {
            return super.visit(node)
        }
        
        let newNode = node.with(\.name, TokenSyntax(stringLiteral: confusedFuncName)).with(\.leadingTrivia, node.leadingTrivia).with(\.trailingTrivia, node.trailingTrivia)
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionParameterSyntax) -> FunctionParameterSyntax {
        var parentNode = node.parent
        while parentNode != nil && parentNode?.as(FunctionDeclSyntax.self) == nil {
            parentNode = parentNode?.parent
        }
        
        var newNode = node
        
        let firstName = node.firstName.text
        if firstName.compare("_") != .orderedSame, let confusedFirstName: String = SwiftConfuseHelper.confusedSymbolName(symbolName: firstName, sourceInfo: self.sourceInfo) {
            newNode = newNode.with(\.firstName, TokenSyntax(stringLiteral: confusedFirstName).with(\.leadingTrivia, node.firstName.leadingTrivia).with(\.trailingTrivia, node.firstName.trailingTrivia))
        }
        
        if let secondName = newNode.secondName?.text, secondName.compare("_") != .orderedSame, let confusedSecondName: String = SwiftConfuseHelper.confusedSymbolName(symbolName: secondName, sourceInfo: self.sourceInfo) {
            var tokenSyntax = TokenSyntax(stringLiteral: confusedSecondName)
            if let leadingTrivia = node.secondName?.leadingTrivia {
                tokenSyntax = tokenSyntax.with(\.leadingTrivia, leadingTrivia)
            }
            if let trailingTrivia = node.secondName?.trailingTrivia {
                tokenSyntax = tokenSyntax.with(\.trailingTrivia, trailingTrivia)
            }
            
            newNode = newNode.with(\.secondName, tokenSyntax)
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: DeclReferenceExprSyntax) -> ExprSyntax {
        var newNode = node
        let baseName = newNode.baseName
        
        if let confusedBaseName: String = SwiftConfuseHelper.confusedSymbolName(symbolName: baseName.text, sourceInfo: self.sourceInfo) {
            newNode = newNode.with(\.baseName, TokenSyntax(stringLiteral: confusedBaseName).with(\.leadingTrivia, baseName.leadingTrivia).with(\.trailingTrivia, baseName.trailingTrivia))
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        var newNode = node

        var exprList: LabeledExprListSyntax = LabeledExprListSyntax()
        newNode.arguments.forEach { exprSyntax in
            var confusedExpr: LabeledExprSyntax = exprSyntax
            if let label = confusedExpr.label, let confusedLabelText = SwiftConfuseHelper.confusedSymbolName(symbolName: label.text, sourceInfo: self.sourceInfo) {
                confusedExpr = confusedExpr.with(\.label, TokenSyntax(stringLiteral: confusedLabelText)).with(\.leadingTrivia, confusedExpr.leadingTrivia).with(\.trailingTrivia, confusedExpr.trailingTrivia)
            }
            
            exprList.append(confusedExpr)
        }
        
        newNode = newNode.with(\.arguments, exprList)
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
        let symbolName: String = node.name.text
        guard let confusedName: String = SwiftConfuseHelper.confusedSymbolName(symbolName: symbolName, sourceInfo: self.sourceInfo) else {
            return super.visit(node)
        }
        
        var newNode = node.with(\.name, TokenSyntax(stringLiteral: confusedName).with(\.leadingTrivia, node.name.leadingTrivia).with(\.trailingTrivia, node.name.trailingTrivia))
        
        var confusedInheritedList: InheritedTypeListSyntax = InheritedTypeListSyntax()
        if let inheritedList = node.inheritanceClause {
            let inheritedCount = inheritedList.inheritedTypes.count
            for (inheritedIndex, inheritedType) in inheritedList.inheritedTypes.enumerated() {
                let superClassName = inheritedType.type.description
                guard let confusedSymbolName = SwiftConfuseHelper.confusedSymbolName(symbolName: superClassName, sourceInfo: self.sourceInfo) else {
                    confusedInheritedList.append(inheritedType)
                    continue
                }
                
                var confusedInheritedType: InheritedTypeSyntax = InheritedTypeSyntax(type: TypeSyntax(stringLiteral: confusedSymbolName).with(\.leadingTrivia, inheritedType.type.leadingTrivia).with(\.trailingTrivia, inheritedType.type.trailingTrivia)).with(\.leadingTrivia, inheritedType.leadingTrivia).with(\.trailingTrivia, inheritedType.trailingTrivia)
                if inheritedIndex != inheritedCount - 1 {
                    confusedInheritedType = confusedInheritedType.with(\.trailingComma, .commaToken())
                }
                
                confusedInheritedList.append(confusedInheritedType)
            }
            
            newNode = newNode.with(\.inheritanceClause, InheritanceClauseSyntax(leadingTrivia: node.inheritanceClause?.leadingTrivia, inheritedTypes: confusedInheritedList, trailingTrivia: node.inheritanceClause?.trailingTrivia))
        }
        
        newNode = newNode.with(\.leadingTrivia, node.leadingTrivia).with(\.trailingTrivia, node.trailingTrivia)
        return super.visit(newNode)
    }
    
    override func visit(_ node: ClosureCaptureSyntax) -> ClosureCaptureSyntax {
        let originName = node.name.text
        guard originName != "self", let confusedName = SwiftConfuseHelper.confusedSymbolName(symbolName: originName, sourceInfo: self.sourceInfo) else {
            return super.visit(node)
        }

        let newNode = node.with(\.leadingTrivia, node.leadingTrivia).with(\.name, TokenSyntax(stringLiteral: confusedName).with(\.leadingTrivia, node.name.leadingTrivia).with(\.trailingTrivia, node.name.trailingTrivia)).with(\.trailingTrivia, node.trailingTrivia)
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
        var newNode = node
        
        if let identifierPatternSyntax = node.pattern.as(IdentifierPatternSyntax.self), let confusedIdentifier = SwiftConfuseHelper.confusedSymbolName(symbolName: identifierPatternSyntax.identifier.text, sourceInfo: self.sourceInfo) {
            let pattern = identifierPatternSyntax.with(\.identifier, TokenSyntax(stringLiteral: confusedIdentifier).with(\.leadingTrivia, identifierPatternSyntax.identifier.leadingTrivia).with(\.trailingTrivia, identifierPatternSyntax.identifier.trailingTrivia))
            
            newNode = node.with(\.pattern, PatternSyntax(pattern).with(\.leadingTrivia, identifierPatternSyntax.leadingTrivia).with(\.trailingTrivia, identifierPatternSyntax.trailingTrivia)).with(\.leadingTrivia, node.leadingTrivia).with(\.trailingTrivia, node.trailingTrivia)
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: IfExprSyntax) -> ExprSyntax {
        let newNode = node
        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionTypeSyntax) -> TypeSyntax {
        var newNode = node
        
        let confusedParameters = node.parameters.map { parameter in
            var firstNameToken = parameter.firstName
            if firstNameToken != nil, let confusedFirstName: String = SwiftConfuseHelper.confusedSymbolName(symbolName: firstNameToken!.text, sourceInfo: self.sourceInfo) {
                firstNameToken = TokenSyntax(stringLiteral: confusedFirstName).with(\.leadingTrivia, firstNameToken!.leadingTrivia).with(\.trailingTrivia, firstNameToken!.trailingTrivia)
            }
            
            var secondNameToken = parameter.secondName
            if secondNameToken != nil, let confusedSecondName: String = SwiftConfuseHelper.confusedSymbolName(symbolName: secondNameToken!.text, sourceInfo: self.sourceInfo) {
                secondNameToken = TokenSyntax(stringLiteral: confusedSecondName).with(\.leadingTrivia, secondNameToken!.leadingTrivia).with(\.trailingTrivia, secondNameToken!.trailingTrivia)
            }
            
            return parameter.with(\.firstName, firstNameToken).with(\.secondName, secondNameToken).with(\.leadingTrivia, parameter.leadingTrivia).with(\.trailingTrivia, parameter.trailingTrivia)
        }
        
        newNode = node.with(\.parameters, TupleTypeElementListSyntax(confusedParameters)).with(\.leadingTrivia, node.leadingTrivia).with(\.trailingTrivia, node.trailingTrivia)
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        var newNode = node
        
        guard let confusedName = SwiftConfuseHelper.confusedSymbolName(symbolName: node.name.text, sourceInfo: self.sourceInfo) else {
            return super.visit(node)
        }
        
        newNode = newNode.with(\.name, TokenSyntax(stringLiteral: confusedName).with(\.leadingTrivia, node.name.leadingTrivia).with(\.trailingTrivia, node.name.trailingTrivia)).with(\.leadingTrivia, node.leadingTrivia).with(\.trailingTrivia, node.trailingTrivia)
        return super.visit(newNode)
    }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        var newNode = node
        
        guard let confusedName = SwiftConfuseHelper.confusedSymbolName(symbolName: node.name.text, sourceInfo: self.sourceInfo) else {
            return super.visit(node)
        }
        
        newNode = newNode.with(\.name, TokenSyntax(stringLiteral: confusedName).with(\.leadingTrivia, node.name.leadingTrivia).with(\.trailingTrivia, node.name.trailingTrivia)).with(\.leadingTrivia, node.leadingTrivia).with(\.trailingTrivia, node.trailingTrivia)
        return super.visit(newNode)
    }
    
    override func visit(_ node: EnumCaseDeclSyntax) -> DeclSyntax {
        var newNode = node
        
        let confusedElements = node.elements.map { enumCaseElement in
            guard let confusedName = SwiftConfuseHelper.confusedSymbolName(symbolName: enumCaseElement.name.text, sourceInfo: self.sourceInfo) else {
                return enumCaseElement
            }
            
            return enumCaseElement.with(\.name, TokenSyntax(stringLiteral: confusedName).with(\.leadingTrivia, enumCaseElement.leadingTrivia).with(\.trailingTrivia, enumCaseElement.trailingTrivia))
        }
        
        newNode = node.with(\.elements, EnumCaseElementListSyntax(confusedElements).with(\.leadingTrivia, node.elements.leadingTrivia).with(\.trailingTrivia, node.elements.trailingTrivia)).with(\.leadingTrivia, node.leadingTrivia).with(\.trailingTrivia, node.trailingTrivia)
        return super.visit(newNode)
    }
    
    override func visit(_ node: ClosureSignatureSyntax) -> ClosureSignatureSyntax {
        switch node.parameterClause {
        case .parameterClause(let paramClause):
            // 处理完整参数列表，如 { (a: Int, b: String) in ... }
            let newParams = paramClause.parameters.map { param -> ClosureParameterSyntax in
                var modifiedParam = param
                
                // 处理参数标签（外部参数名）
                if let secondName = param.secondName,
                   let confusedName = SwiftConfuseHelper.confusedSymbolName(
                       symbolName: secondName.text,
                       sourceInfo: self.sourceInfo
                   ) {
                    // 保持原有的格式信息
                    modifiedParam = modifiedParam.with(
                        \.secondName,
                        secondName.with(\.tokenKind, .identifier(confusedName))
                    )
                }
                
                // 处理参数名称（内部参数名），跳过下划线 _
                if param.firstName.text != "_",
                   let confusedName = SwiftConfuseHelper.confusedSymbolName(
                       symbolName: param.firstName.text,
                       sourceInfo: self.sourceInfo
                   ) {
                    modifiedParam = modifiedParam.with(
                        \.firstName,
                        param.firstName.with(\.tokenKind, .identifier(confusedName))
                    )
                }
                
                return modifiedParam
            }
            
            // 创建新的参数列表
            let newParamList = ClosureParameterListSyntax(newParams)
            
            // 创建新的参数子句
            let newParamClause = paramClause.with(\.parameters, newParamList)
            
            // 更新节点
            let modifiedNode = node.with(\.parameterClause, .parameterClause(newParamClause))
            return super.visit(modifiedNode)
            
        case .simpleInput(let paramList):
            // 处理简写参数，如 { a, b in ... }
            let newParams = paramList.map { param -> ClosureShorthandParameterSyntax in
                guard let confusedName = SwiftConfuseHelper.confusedSymbolName(
                    symbolName: param.name.text,
                    sourceInfo: self.sourceInfo
                ) else {
                    return param
                }
                
                return param.with(
                    \.name,
                    param.name.with(\.tokenKind, .identifier(confusedName))
                )
            }
            
            let newParamList = ClosureShorthandParameterListSyntax(newParams)
            let modifiedNode = node.with(\.parameterClause, .simpleInput(newParamList))
            return super.visit(modifiedNode)
            
        case .none:
            // 没有参数的闭包，直接返回
            return super.visit(node)
        }
    }
}

extension SwiftASTSyntaxRewriter {
    //    private func findFunctionSourceInfo(_ node: SyntaxProtocol?, _ confused: Bool = false) -> SwiftSourceFunctionInfo? {
    //        guard let funcDeclNode: FunctionDeclSyntax = node?.as(FunctionDeclSyntax.self),
    //                let funcName: String = confused ? self.sourceInfo.confusedMap[funcDeclNode.name.text] : funcDeclNode.name.text else {
    //            return nil
    //        }
    //
    //        var parentNode = funcDeclNode.parent
    //        while (parentNode != nil && (parentNode?.as(ClassDeclSyntax.self)) == nil) {
    //            parentNode = parentNode?.parent
    //        }
    //
    //        let funcSignature: String? = funcDeclNode.signature.trimmedDescription
    //
    //        var funcSourceInfo: SwiftSourceFunctionInfo?
    //        if let clsNode = parentNode?.as(ClassDeclSyntax.self), let oriClsName = self.sourceInfo.confusedMap[clsNode.name.text], let clsInfo = self.sourceInfo.sourceInfoList[oriClsName] {
    //            for child in clsInfo.children {
    //                guard child.sourceType == .Function, let funcInfo = child as? SwiftSourceFunctionInfo else {
    //                    continue
    //                }
    //
    //                if funcInfo.name == funcName && funcInfo.signature == funcSignature {
    //                    funcSourceInfo = funcInfo
    //                    break
    //                }
    //            }
    //        }
    //
    //        if funcSourceInfo == nil {
    //            funcSourceInfo = self.sourceInfo.sourceInfoList[funcName] as? SwiftSourceFunctionInfo
    //        }
    //
    //        return funcSourceInfo
    //    }
    //
    //    private func isSymbolInProjectPath(sourceInfo: SwiftSourceBaseInfo) -> Bool {
    //        return sourceInfo.filePath.hasPrefix(self.projectPath)
    //    }
    //
    //    private func isSymbolShouldBeConfused(sourceInfo: SwiftSourceBaseInfo) -> Bool {
    //        if sourceInfo.isFinal || sourceInfo.isStatic {
    //            return true
    //        }
    //
    //        guard let clsInfo: SwiftSourceClassInfo = sourceInfo.parent as? SwiftSourceClassInfo, clsInfo.superClasses.count > 0 else {
    //            return true
    //        }
    //
    //        var shouldConfuse: Bool = false
    //        for supercls in clsInfo.superClasses {
    //            if let superClsInfo: SwiftSourceClassInfo = self.sourceInfo.sourceInfoList[supercls] as? SwiftSourceClassInfo {
    //                for child in superClsInfo.children {
    //                    if SwiftConfuseHelper.isEqualSourceInfo(sourceInfo, child) {
    //                        shouldConfuse = isSymbolShouldBeConfused(sourceInfo: superClsInfo) || shouldConfuse
    //                        break
    //                    }
    //                }
    //            }
    //        }
    //
    //        return shouldConfuse
    //        return true
    //    }
}

//class SwiftASTSyntaxRewriter: SyntaxRewriter {
//
//    private let sourceInfo: SwiftSourceInfo
//
//    init(sourceInfo: SwiftSourceInfo) {
//        self.sourceInfo = sourceInfo
//        super.init(viewMode: .sourceAccurate)
//    }
//
//    private let swiftKeywords: Set<String> = [
//        "self", "super", "in", "let", "var", "func", "if", "else", "for", "while",
//        "return", "break", "continue", "nil", "true", "false", "guard", "switch"
//    ]
//
//    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
//        var newNode = self.addCommentForDeclSyntax(node, startTriviaString: "// class_start-", endTriviaString: "// class_end-")
//        newNode.name = TokenSyntax(stringLiteral: "cla_\(node.name.text)_cla")
//        return super.visit(newNode)
//    }
//
//    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
//        var newNode = self.addCommentForDeclSyntax(node, startTriviaString: "// class_start-", endTriviaString: "// class_end-")
//
//        if let extendedType = node.extendedType.as(IdentifierTypeSyntax.self) {
//            let newExtendedType = IdentifierTypeSyntax(
//                name: TokenSyntax.identifier("cla_\(extendedType.name.text)_cla"),
//                genericArgumentClause: extendedType.genericArgumentClause
//            )
//
//            newNode = newNode.with(\.extendedType, TypeSyntax(newExtendedType))
//        }
//
//        return super.visit(newNode)
//    }
//
//    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
//        var newNode = self.addCommentForDeclSyntax(node, startTriviaString: "// class_start-", endTriviaString: "// class_end-")
//        newNode.name = TokenSyntax(stringLiteral: "cla_\(node.name.text)_cla")
//        return super.visit(newNode)
//    }
//
//    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
//        var newNode = self.addCommentForDeclSyntax(node, startTriviaString: "// class_start-", endTriviaString: "// class_end-")
//        newNode.name = TokenSyntax(stringLiteral: "cla_\(node.name.text)_cla")
//        return super.visit(newNode)
//    }
//
//    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
//
//        let updatedBindings: [PatternBindingSyntax] = node.bindings.map { bindings in
//            guard let identifierPattern = bindings.pattern.as(IdentifierPatternSyntax.self) else {
//                return bindings
//            }
//
//            let isMemberType: Bool = SwiftRefactorHelper.isMemberVariable(node)
//            let name = isMemberType ? "pro_\(identifierPattern.identifier.text)_pro" : "par_\(identifierPattern.identifier.text)_par"
//
//            let newPattern = PatternSyntax(stringLiteral: name)
//            return bindings.with(\.leadingTrivia, identifierPattern.leadingTrivia).with(\.pattern, newPattern).with(\.trailingTrivia, identifierPattern.trailingTrivia)
//        }
//
//        var newNode = node.with(\.leadingTrivia, node.leadingTrivia).with(\.bindings, PatternBindingListSyntax(updatedBindings)).with(\.trailingTrivia, node.trailingTrivia)
//
//        if SwiftRefactorHelper.isMemberVariable(node) {
//            newNode = self.addCommentForDeclSyntax(newNode, startTriviaString: "// attribute_start-", endTriviaString: "// attribute_end-")
//        }
//
//        return super.visit(newNode)
//    }
//
//    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
//        var newNode = self.addCommentForDeclSyntax(node, startTriviaString: "// func_start-", endTriviaString: "// func_end-")
//        newNode.name = TokenSyntax(stringLiteral: "fun_\(node.name.text)_fun")
//        return super.visit(newNode)
//    }
//
//    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
//        var funcName: String = ""
//        var expr: ExprSyntax?
//
//        if let exp = node.calledExpression.as(DeclReferenceExprSyntax.self) {
//            funcName = "func_\(exp.baseName.text)_func"
//            let newToken = TokenSyntax.identifier(funcName).with(\.leadingTrivia, exp.leadingTrivia).with(\.trailingTrivia, exp.trailingTrivia)
//            expr = ExprSyntax(exp.with(\.baseName, newToken))
//        }  else if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self) {
//            funcName = "func_\(memberAccess.declName.baseName.text)_func"
//            let newDeclName = memberAccess.declName.with(\.baseName, TokenSyntax.identifier(funcName))
//            expr = ExprSyntax(memberAccess.with(\.leadingTrivia, memberAccess.leadingTrivia).with(\.declName, newDeclName)).with(\.trailingTrivia, memberAccess.trailingTrivia)
//        }
//
//        if let expr {
//            let newNode = node.with(\.leadingTrivia, node.leadingTrivia).with(\.calledExpression, expr).with(\.trailingTrivia, node.trailingTrivia)
//            return super.visit(newNode)
//        }
//
//        return super.visit(node)
//    }
//
//    override func visit(_ node: ClosureCaptureSyntax) -> ClosureCaptureSyntax {
//        let originName = node.name.text
//        if originName.compare("self") == .orderedSame {
//            return super.visit(node)
//        }
//
//        let newName = "par_\(originName)_par"
//
//        let newNode = node.with(\.leadingTrivia, node.leadingTrivia).with(\.name, TokenSyntax(stringLiteral: newName)).with(\.trailingTrivia, node.trailingTrivia)
//        return super.visit(newNode)
//    }
//
//    override func visit(_ node: ClosureSignatureSyntax) -> ClosureSignatureSyntax {
//        var modifiedNode = node
//
//        // 检查 parameterClause 的类型
//        switch modifiedNode.parameterClause {
//        case .simpleInput(let paramList):
//            // 简写参数列表，如: text, name in
//            let newParams = paramList.map { param -> ClosureShorthandParameterSyntax in
//                let originName = param.name.text
//                let newName = "par_\(originName)_par"
//                return param.with(\.leadingTrivia, param.leadingTrivia).with(\.name, TokenSyntax(stringLiteral: newName)).with(\.trailingTrivia, param.trailingTrivia)
//            }
//
//            modifiedNode = modifiedNode.with(\.leadingTrivia, modifiedNode.leadingTrivia).with(\.parameterClause, .simpleInput(ClosureShorthandParameterListSyntax(newParams))).with(\.trailingTrivia, modifiedNode.trailingTrivia)
//
//        case .parameterClause(let paramClause):
//            // 完整参数列表，如: (text: String, name: String) in
//            let newParams = paramClause.parameters.map { param -> ClosureParameterSyntax in
//                var modifiedParam = param
//
//                // 处理内部参数名 (secondName)
//                if let secondName = param.secondName {
//                    let originName = secondName.text
//                    let newName = "par_\(originName)_par"
//                    modifiedParam = modifiedParam.with(\.leadingTrivia, modifiedParam.leadingTrivia).with(\.secondName, TokenSyntax(stringLiteral: newName)).with(\.trailingTrivia, modifiedNode.trailingTrivia)
//                }
//                // 如果没有 secondName，使用 firstName（但跳过下划线）
//                else if param.firstName.text != "_" {
//                    let originName = param.firstName.text
//                    let newName = "par_\(originName)_par"
//                    modifiedParam = modifiedParam.with(\.leadingTrivia, modifiedParam.leadingTrivia).with(\.firstName, TokenSyntax(stringLiteral: newName)).with(\.trailingTrivia, modifiedParam.trailingTrivia)
//                }
//
//                return modifiedParam
//            }
//
//            let newParamClause = paramClause.with(\.parameters, ClosureParameterListSyntax(newParams))
//            modifiedNode = modifiedNode.with(\.leadingTrivia, modifiedNode.leadingTrivia).with(\.parameterClause, .parameterClause(newParamClause)).with(\.trailingTrivia, modifiedNode.trailingTrivia)
//
//        default:
//            break
//        }
//
//        return super.visit(modifiedNode)
//    }
//
//    // 重命名函数类型中的参数
//    override func visit(_ node: FunctionTypeSyntax) -> TypeSyntax {
//        // 修改参数
//        let newParameters = node.parameters.map { param -> TupleTypeElementSyntax in
//            var modifiedParam = param
//
//            // 处理内部参数名 (secondName)
//            if let secondName = param.secondName {
//                let originName = secondName.text
//                let newName = "par_\(originName)_par"
//                modifiedParam = modifiedParam.with(\.leadingTrivia, modifiedParam.leadingTrivia).with(\.secondName, TokenSyntax(stringLiteral: newName)).with(\.trailingTrivia, modifiedParam.trailingTrivia)
//            }
//            // 处理外部参数名 (firstName)，跳过下划线
//            else if let firstName = param.firstName,
//                    firstName.text != "_" {
//                let originName = firstName.text
//                let newName = "par_\(originName)_par"
//                modifiedParam = modifiedParam.with(\.leadingTrivia, modifiedParam.leadingTrivia).with(\.firstName, TokenSyntax(stringLiteral: newName)).with(\.trailingTrivia, modifiedParam.trailingTrivia)
//            }
//
//            return modifiedParam
//        }
//
//        // 创建修改后的节点
//        let modifiedNode = node.with(\.leadingTrivia, node.leadingTrivia).with(\.parameters, TupleTypeElementListSyntax(newParameters)).with(\.trailingTrivia, node.trailingTrivia)
//
//        // 重要：调用 super.visit 来继续处理子节点
//        return super.visit(modifiedNode)
//    }
//
//    override func visit(_ node: FunctionParameterSyntax) -> FunctionParameterSyntax {
//        var newNode = node
//
//        let newFirstNameText = node.firstName.text.compare("_") == .orderedSame ? node.firstName.text : "par_\(node.firstName.text)_par"
//
//        let newFirstNameToken = TokenSyntax.identifier(newFirstNameText).with(\.leadingTrivia, node.firstName.leadingTrivia).with(\.trailingTrivia, node.firstName.trailingTrivia)
//
//        newNode = newNode.with(\.firstName, newFirstNameToken)
//
//        if let originalSecondName = node.secondName {
//            let newSecondNameText = "par_\(originalSecondName.text)_par"
//            let newSecondNameToken = TokenSyntax.identifier(newSecondNameText)
//                .with(\.leadingTrivia, originalSecondName.leadingTrivia)
//                .with(\.trailingTrivia, originalSecondName.trailingTrivia)
//            newNode = newNode.with(\.secondName, newSecondNameToken)
//        }
//
//        newNode = newNode
//            .with(\.leadingTrivia, node.leadingTrivia)
//            .with(\.trailingTrivia, node.trailingTrivia)
//
//        return super.visit(newNode)
//    }
//}
//
//extension SwiftASTSyntaxRewriter {
//    private func addCommentForDeclSyntax<T: DeclSyntaxProtocol>(_ node: T, startTriviaString: String, endTriviaString: String) -> T {
//
//        let startTrivia = TriviaPiece.lineComment(startTriviaString)
//        let endTrivia = TriviaPiece.lineComment(endTriviaString)
//
//        var leadingTrivia = Trivia(pieces: [.newlines(1), startTrivia])
//        node.leadingTrivia.pieces.forEach { piece in
//            leadingTrivia = leadingTrivia.appending(piece)
//        }
//
//        let trailingTrivia = node.trailingTrivia + Trivia(pieces: [.newlines(1), endTrivia, .newlines(1)])
//
//        let newNode = node.with(\.leadingTrivia, leadingTrivia).with(\.trailingTrivia, trailingTrivia)
//        return newNode
//    }
//
//    private func renameForDeclSyntax<T: DeclSyntaxProtocol>(_ node: T, prefix: String) -> T {
//        return node
//    }
//}
