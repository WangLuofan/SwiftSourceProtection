//
//  SPSwiftSourceASTRewriter.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/8.
//

import Foundation
import SwiftSyntax

class SPSwiftSourceASTRewriter: SyntaxRewriter {
    private var sourceKit: SourceKit
    private var sourceTree: SourceFileSyntax
    private var sourceFile: File
    private var topScope: SPSwiftSourceScope
    private var currentScope: SPSwiftSourceScope
    
    private var currentFunction: DeclSyntaxProtocol?
    private var locationConverter: SourceLocationConverter
    
    init(sourceKit: SourceKit,
         sourceTree: SourceFileSyntax,
         sourceFile: File,
         scope: SPSwiftSourceScope
    ) {
        self.sourceKit = sourceKit
        self.sourceTree = sourceTree
        self.sourceFile = sourceFile
        self.topScope = scope
        self.currentScope = scope
        
        self.locationConverter = SourceLocationConverter(
            fileName: self.sourceFile.path,
            tree: self.sourceTree
        )
        
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        let funcSymbol = self.calledNameToken(node.calledExpression).flatMap { self.functionSymbol(at: $0) }
        
        let visited = super.visit(node)
        
        guard let call = visited.as(FunctionCallExprSyntax.self),
              let funcSymbol else {
            return visited
        }
        
        let newArgs = call.arguments.map { arg -> LabeledExprSyntax in
            guard let label = arg.label,
                  let idx = funcSymbol.labels.firstIndex(of: label.text),
                  idx < funcSymbol.confusedLabels.count else {
                return arg
            }
            
            return arg.with(\.label, .identifier(
                funcSymbol.confusedLabels[idx],
                leadingTrivia: label.leadingTrivia,
                trailingTrivia: label.trailingTrivia))
        }
        
        return ExprSyntax(call.with(\.arguments, LabeledExprListSyntax(newArgs)))
    }
    
    override func visit(_ node: FunctionParameterSyntax) -> FunctionParameterSyntax {
        
        guard let funcSymbol = self.enclosingFunctionSymbol(of: node),
              let index = self.parameterIndex(of: node),
              index < funcSymbol.confusedLabels.count else {
            return super.visit(node)
        }
        
        let confusedLabel = funcSymbol.confusedLabels[index]
        var newNode = node.with(\.firstName, .identifier(
            confusedLabel,
            leadingTrivia: node.firstName.leadingTrivia,
            trailingTrivia: node.firstName.trailingTrivia)
        )
        
        if let secondName = node.secondName {
            newNode = newNode.with(\.secondName, .identifier(
                ConfuseHelper.confusedSymbolName(secondName.text),
                leadingTrivia: secondName.leadingTrivia,
                trailingTrivia: secondName.trailingTrivia)
            )
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: TokenSyntax) -> TokenSyntax {
        guard case .identifier = node.tokenKind,
              !node.text.isSwiftKeyWord else {
            return super.visit(node)
        }
        
        if let labeled = node.parent?.as(LabeledExprSyntax.self), labeled.label?.id == node.id {
            return super.visit(node)
        }
        
        if let _ = node.parent?.as(FunctionParameterSyntax.self) {
            return super.visit(node)
        }
        
        let refLoc = self.locationConverter.location(for: node.positionAfterSkippingLeadingTrivia)
        if let ref = IndexStore.indexStore.getRef(fromFile: self.sourceFile, line: refLoc.line, col: refLoc.column) {
            if let usr: String = ref[sourceKit.keys.usr],
               let symbol: SPSwiftSourceSymbol = IndexStore.indexStore.getSymbol(usr: usr),
               let confusedSymbolName = symbol.confusedSymbolName {
                return super.visit(node.with(\.tokenKind, .identifier(confusedSymbolName)))
            } else {
                return super.visit(node)
            }
        } else if let scopeForNode: SPSwiftSourceScope = IndexStore.indexStore.scope(token: node, inFile: self.sourceFile),
                  let symbol: SPSwiftSourceSymbol = scopeForNode.findSymbolWithSymbolName(node.text),
                  let confusedSymbolName = symbol.confusedSymbolName {
            return super.visit(node.with(\.tokenKind, .identifier(confusedSymbolName)))
        }
        
        return super.visit(node)
    }
}

extension SPSwiftSourceASTRewriter {
    func rewrite() -> String {
        let rewritten = self.visit(self.sourceTree)
        return rewritten.description
    }
    
//    private func confuseNodePattern(_ pattern: PatternSyntax) -> PatternSyntax? {
//        if let idPatternSyntax: IdentifierPatternSyntax = pattern.as(IdentifierPatternSyntax.self) {
//            guard let varSymbol: SPSwiftSourceVariableSymbol = self.currentScope.findSymbolWithSymbolName(idPatternSyntax.identifier.text) as? SPSwiftSourceVariableSymbol,
//                  let confusedSymbolName = varSymbol.confusedSymbolName else {
//                return PatternSyntax(idPatternSyntax)
//            }
//            
//            let newPattern: IdentifierPatternSyntax = idPatternSyntax.with(\.identifier, .identifier(confusedSymbolName)
//                .with(\.leadingTrivia, idPatternSyntax.identifier.leadingTrivia)
//                .with(\.trailingTrivia, idPatternSyntax.identifier.trailingTrivia)
//            )
//            
//            return PatternSyntax(newPattern)
//        } else if let tupPatternSyntax: TuplePatternSyntax = pattern.as(TuplePatternSyntax.self) {
//            let confusedTupPatternSyntaxElems: [TuplePatternElementSyntax] = tupPatternSyntax.elements.compactMap {
//                guard let pattern: PatternSyntax = self.confuseNodePattern($0.pattern) else {
//                    return $0
//                }
//                
//                return $0.with(\.pattern, PatternSyntax(pattern)
//                    .with(\.leadingTrivia, $0.pattern.leadingTrivia)
//                    .with(\.trailingTrivia, $0.pattern.trailingTrivia)
//                )
//            }
//            
//            return PatternSyntax(tupPatternSyntax
//                .with(\.elements, TuplePatternElementListSyntax(confusedTupPatternSyntaxElems)
//                    .with(\.leadingTrivia, tupPatternSyntax.elements.leadingTrivia)
//                    .with(\.trailingTrivia, tupPatternSyntax.elements.trailingTrivia)
//                )
//            )
//        } else if let exprPatternSyntax: ExpressionPatternSyntax = pattern.as(ExpressionPatternSyntax.self) {
//            guard let confusedExprPattern: ExprSyntax = self.confuseExpression(exprPatternSyntax.expression)?.as(ExprSyntax.self) else {
//                return pattern
//            }
//            
//            return PatternSyntax(exprPatternSyntax
//                .with(\.expression, confusedExprPattern
//                    .with(\.leadingTrivia, exprPatternSyntax.leadingTrivia)
//                    .with(\.trailingTrivia, exprPatternSyntax.trailingTrivia)
//                )
//            )
//        } else if let valBindPatternSyntax: ValueBindingPatternSyntax = pattern.as(ValueBindingPatternSyntax.self) {
//            guard let confusedPattern = self.confuseNodePattern(valBindPatternSyntax.pattern) else {
//                return pattern
//            }
//            
//            return PatternSyntax(valBindPatternSyntax
//                .with(\.pattern, confusedPattern
//                    .with(\.leadingTrivia, valBindPatternSyntax.pattern.leadingTrivia)
//                    .with(\.trailingTrivia, valBindPatternSyntax.pattern.trailingTrivia)
//                )
//            )
//        }
//        
//        return pattern
//    }
//    
//    private func confuseExpression(_ expr: some ExprSyntaxProtocol) -> ExprSyntax? {
//        if let patternSyntax: PatternExprSyntax = expr.as(PatternExprSyntax.self) {
//            guard let confusedPattern = self.confuseNodePattern(patternSyntax.pattern) else {
//                return ExprSyntax(expr)
//            }
//            
//            return ExprSyntax(patternSyntax.with(\.pattern, confusedPattern
//                .with(\.leadingTrivia, patternSyntax.pattern.leadingTrivia)
//                .with(\.trailingTrivia, patternSyntax.pattern.trailingTrivia)
//            ))
//        } else if let exprSyntax: FunctionCallExprSyntax = expr.as(FunctionCallExprSyntax.self) {
//            guard let confusedArguments: [LabeledExprSyntax] = exprSyntax.arguments.flatMap({
//                guard let confusedExpr = self.confuseExpression($0.expression) else {
//                    return $0
//                }
//                
//                return $0.with(\.expression, confusedExpr
//                    .with(\.leadingTrivia, $0.expression.leadingTrivia)
//                    .with(\.trailingTrivia, $0.expression.trailingTrivia)
//                )
//            }) as? [LabeledExprSyntax] else {
//                return ExprSyntax(expr)
//            }
//            
//            return ExprSyntax(exprSyntax
//                .with(\.arguments, LabeledExprListSyntax(confusedArguments)
//                    .with(\.leadingTrivia, exprSyntax.arguments.leadingTrivia)
//                    .with(\.trailingTrivia, exprSyntax.arguments.trailingTrivia)
//                )
//            )
//        } else if let seqExprSyntax: SequenceExprSyntax = expr.as(SequenceExprSyntax.self) {
//            let confusedExprList = seqExprSyntax.elements.flatMap {
//                guard let confusedExpr = self.confuseExpression($0) else {
//                    return $0
//                }
//                
//                return confusedExpr.with(\.leadingTrivia, $0.leadingTrivia).with(\.trailingTrivia, $0.trailingTrivia)
//            }
//            
//            return ExprSyntax(seqExprSyntax
//                .with(\.elements, ExprListSyntax(confusedExprList))
//                .with(\.leadingTrivia, seqExprSyntax.elements.leadingTrivia)
//                .with(\.trailingTrivia, seqExprSyntax.elements.trailingTrivia)
//            )
//        } else if let tupExprSyntax: TupleExprSyntax = expr.as(TupleExprSyntax.self) {
//            let confusedExprList = tupExprSyntax.elements.flatMap {
//                guard let confusedExpr = self.confuseExpression($0.expression) else {
//                    return $0
//                }
//                
//                return $0.with(\.expression, confusedExpr
//                    .with(\.leadingTrivia, $0.expression.leadingTrivia)
//                    .with(\.trailingTrivia, $0.expression.trailingTrivia)
//                )
//            }
//            
//            return ExprSyntax(tupExprSyntax
//                .with(\.elements, LabeledExprListSyntax(confusedExprList)
//                    .with(\.leadingTrivia, tupExprSyntax.elements.leadingTrivia)
//                    .with(\.trailingTrivia, tupExprSyntax.elements.trailingTrivia)
//                )
//            )
//        } else if let declRefSyntax: DeclReferenceExprSyntax = expr.as(DeclReferenceExprSyntax.self) {
//            var refSymbol: SPSwiftSourceSymbol?
//            
//            let srcLoc: SourceLocation = self.locationConverter.location(for: declRefSyntax.positionAfterSkippingLeadingTrivia)
//            if let resp: SKResponseDictionary = IndexStore.indexStore.getRef(fromFile: self.sourceFile, line: srcLoc.line, col: srcLoc.column),
//               let usr: String = resp[sourceKit.keys.usr] {
//                refSymbol = IndexStore.indexStore.getSymbol(usr: usr)
//            } else if let symbol: SPSwiftSourceSymbol = self.currentScope.findSymbolInCurrentScope(declRefSyntax.baseName.text) {
//                refSymbol = symbol
//            }
//            
//            if let refSymbol,
//               let confusedSymbolName = refSymbol.confusedSymbolName {
//                return ExprSyntax(declRefSyntax
//                    .with(\.baseName, .identifier(
//                        confusedSymbolName,
//                        leadingTrivia: declRefSyntax.baseName.leadingTrivia,
//                        trailingTrivia: declRefSyntax.baseName.trailingTrivia)
//                    )
//                )
//            }
//        }
//        
//        return ExprSyntax(expr)
//    }
//    
//    private func confuseTypeSyntax(_ typeSyntax: TypeSyntaxProtocol) -> TypeSyntaxProtocol? {
//        if let idTypeSyntax: IdentifierTypeSyntax = typeSyntax.as(IdentifierTypeSyntax.self) {
//            if let typeSymbol: SPSwiftSourceSymbol = self.currentScope.findSymbolWithSymbolName(idTypeSyntax.name.text),
//               let confusedSymbolName = typeSymbol.confusedSymbolName {
//                return idTypeSyntax.with(\.name, .identifier(
//                    confusedSymbolName,
//                    leadingTrivia: idTypeSyntax.name.leadingTrivia,
//                    trailingTrivia: idTypeSyntax.name.trailingTrivia)
//                )
//            }
//        } else if let optTypeSyntax: OptionalTypeSyntax = typeSyntax.as(OptionalTypeSyntax.self),
//                  let confusedWrappedTypeSyntax: TypeSyntax = self.confuseTypeSyntax(optTypeSyntax.wrappedType) as? TypeSyntax {
//            
//            return optTypeSyntax.with(\.wrappedType, confusedWrappedTypeSyntax
//                .with(\.leadingTrivia, optTypeSyntax.wrappedType.leadingTrivia)
//                .with(\.trailingTrivia, optTypeSyntax.wrappedType.trailingTrivia)
//            )
//        } else if let arrTypeSyntax: ArrayTypeSyntax = typeSyntax.as(ArrayTypeSyntax.self),
//                  let confusedElement: TypeSyntax = self.confuseTypeSyntax(arrTypeSyntax.element) as? TypeSyntax {
//            return arrTypeSyntax.with(\.element, confusedElement
//                .with(\.leadingTrivia, arrTypeSyntax.element.leadingTrivia)
//                .with(\.trailingTrivia, arrTypeSyntax.element.trailingTrivia)
//            )
//        } else if let dicTypeSyntax: DictionaryTypeSyntax = typeSyntax.as(DictionaryTypeSyntax.self),
//                  let confusedKeyType: TypeSyntax = self.confuseTypeSyntax(dicTypeSyntax.key) as? TypeSyntax,
//                  let confusedValueType: TypeSyntax = self.confuseTypeSyntax(dicTypeSyntax.value) as? TypeSyntax {
//            return dicTypeSyntax.with(\.key, confusedKeyType
//                .with(\.leadingTrivia, dicTypeSyntax.key.leadingTrivia)
//                .with(\.trailingTrivia, dicTypeSyntax.key.trailingTrivia))
//            .with(\.value, confusedValueType
//                .with(\.leadingTrivia, dicTypeSyntax.value.leadingTrivia)
//                .with(\.trailingTrivia, dicTypeSyntax.value.trailingTrivia)
//            )
//        } else if let tupTypeSyntax: TupleTypeSyntax = typeSyntax.as(TupleTypeSyntax.self) {
//            var confusedTupleElemType: [TupleTypeElementSyntax] = []
//            tupTypeSyntax.elements.forEach {
//                if let confusedType: TypeSyntax = self.confuseTypeSyntax($0.type) as? TypeSyntax {
//                    confusedTupleElemType.append($0.with(\.type, confusedType
//                        .with(\.leadingTrivia, $0.type.leadingTrivia)
//                        .with(\.trailingTrivia, $0.type.trailingTrivia)
//                    ))
//                } else {
//                    confusedTupleElemType.append($0)
//                }
//            }
//            
//            return tupTypeSyntax.with(\.elements, TupleTypeElementListSyntax(confusedTupleElemType)
//                .with(\.leadingTrivia, tupTypeSyntax.elements.leadingTrivia)
//                .with(\.trailingTrivia, tupTypeSyntax.elements.trailingTrivia)
//            )
//        } else if let funcTypeSyntax: FunctionTypeSyntax = typeSyntax.as(FunctionTypeSyntax.self) {
//            var confusedFuncType = funcTypeSyntax
//            if let confusedRetType: TypeSyntax = self.confuseTypeSyntax(funcTypeSyntax.returnClause.type) as? TypeSyntax {
//                confusedFuncType = confusedFuncType.with(\.returnClause, confusedFuncType.returnClause
//                    .with(\.type, confusedRetType
//                        .with(\.leadingTrivia, confusedFuncType.returnClause.type.leadingTrivia)
//                        .with(\.trailingTrivia, confusedFuncType.returnClause.type.trailingTrivia)
//                    )
//                )
//            }
//            
//            var confusedParams: [TupleTypeElementSyntax] = []
//            confusedFuncType.parameters.forEach {
//                if let secondName = $0.secondName {
//                    let confusedSecondName: String = ConfuseHelper.confusedSymbolName(secondName.text)
//                    confusedParams.append($0
//                        .with(\.secondName, .identifier(
//                            confusedSecondName,
//                            leadingTrivia: secondName.leadingTrivia,
//                            trailingTrivia: secondName.trailingTrivia)
//                        )
//                    )
//                } else {
//                    confusedParams.append($0)
//                }
//            }
//            
//            return confusedFuncType.with(\.parameters, TupleTypeElementListSyntax(confusedParams)
//                .with(\.leadingTrivia, confusedFuncType.parameters.leadingTrivia)
//                .with(\.trailingTrivia, confusedFuncType.parameters.trailingTrivia)
//            )
//        } else if let metaTypeSyntax: MetatypeTypeSyntax = typeSyntax.as(MetatypeTypeSyntax.self),
//                  let confusedBaseTypeSyntax: TypeSyntax = self.confuseTypeSyntax(metaTypeSyntax.baseType) as? TypeSyntax {
//            return metaTypeSyntax.with(\.baseType, confusedBaseTypeSyntax
//                .with(\.leadingTrivia, metaTypeSyntax.baseType.leadingTrivia)
//                .with(\.trailingTrivia, metaTypeSyntax.baseType.trailingTrivia)
//            )
//        } else if let someAnyTypeSyntax: SomeOrAnyTypeSyntax = typeSyntax.as(SomeOrAnyTypeSyntax.self),
//                  let confusedConstraintTypeSyntax: TypeSyntax = self.confuseTypeSyntax(someAnyTypeSyntax.constraint) as? TypeSyntax {
//            return someAnyTypeSyntax.with(\.constraint, confusedConstraintTypeSyntax
//                .with(\.leadingTrivia, someAnyTypeSyntax.constraint.leadingTrivia)
//                .with(\.trailingTrivia, someAnyTypeSyntax.constraint.trailingTrivia)
//            )
//        } else if let impUnwrappedOptTypeSyntax: ImplicitlyUnwrappedOptionalTypeSyntax = typeSyntax.as(ImplicitlyUnwrappedOptionalTypeSyntax.self),
//                  let confusedWrappedType: TypeSyntax = self.confuseTypeSyntax(impUnwrappedOptTypeSyntax.wrappedType) as? TypeSyntax {
//            return impUnwrappedOptTypeSyntax.with(\.wrappedType, confusedWrappedType
//                .with(\.leadingTrivia, impUnwrappedOptTypeSyntax.wrappedType.leadingTrivia)
//                .with(\.trailingTrivia, impUnwrappedOptTypeSyntax.wrappedType.trailingTrivia)
//            )
//        } else if let memTypeSyntax: MemberTypeSyntax = typeSyntax.as(MemberTypeSyntax.self) {
//            var confusedMemTypeSyntax = memTypeSyntax
//            if let confusedType: TypeSyntax = self.confuseTypeSyntax(memTypeSyntax.baseType) as? TypeSyntax {
//                confusedMemTypeSyntax = confusedMemTypeSyntax.with(\.baseType, confusedType
//                    .with(\.leadingTrivia, confusedMemTypeSyntax.baseType.leadingTrivia)
//                    .with(\.trailingTrivia, confusedMemTypeSyntax.baseType.trailingTrivia)
//                )
//            }
//            
//            if let varSymbol: SPSwiftSourceSymbol = self.currentScope.findSymbolWithSymbolName(memTypeSyntax.name.text),
//               let confusedSymbolName = varSymbol.confusedSymbolName {
//                confusedMemTypeSyntax = confusedMemTypeSyntax.with(\.name, .identifier(
//                    confusedSymbolName,
//                    leadingTrivia: confusedMemTypeSyntax.name.leadingTrivia,
//                    trailingTrivia: confusedMemTypeSyntax.name.trailingTrivia
//                ))
//            }
//            
//            return confusedMemTypeSyntax
//        } else if let compTypeSyntax: CompositionTypeSyntax = typeSyntax.as(CompositionTypeSyntax.self) {
//            var confusedCompElemType: [CompositionTypeElementSyntax] = []
//            compTypeSyntax.elements.forEach {
//                if let confusedType: TypeSyntax = self.confuseTypeSyntax($0.type) as? TypeSyntax {
//                    confusedCompElemType.append($0.with(\.type, confusedType
//                        .with(\.leadingTrivia, $0.type.leadingTrivia)
//                        .with(\.trailingTrivia, $0.type.trailingTrivia)
//                    ))
//                } else {
//                    confusedCompElemType.append($0)
//                }
//            }
//            
//            return compTypeSyntax.with(\.elements, CompositionTypeElementListSyntax(confusedCompElemType)
//                .with(\.leadingTrivia, compTypeSyntax.elements.leadingTrivia)
//                .with(\.trailingTrivia, compTypeSyntax.elements.trailingTrivia)
//            )
//        } else if let attrTypeSyntax: AttributedTypeSyntax = typeSyntax.as(AttributedTypeSyntax.self),
//                  let confusedBaseType: TypeSyntax = self.confuseTypeSyntax(attrTypeSyntax.baseType) as? TypeSyntax {
//            return attrTypeSyntax.with(\.baseType, confusedBaseType
//                .with(\.leadingTrivia, attrTypeSyntax.baseType.leadingTrivia)
//                .with(\.trailingTrivia, attrTypeSyntax.baseType.trailingTrivia)
//            )
//        }
//        
//        return typeSyntax
//    }
    
    private func nodeParent<T: SyntaxProtocol>(_ node: SyntaxProtocol) -> T? {
        var parent = node.parent
        while parent != nil {
            if let parent: T = parent?.as(T.self) {
                return parent
            }
            
            parent = parent?.parent
        }
        
        return nil
    }
    
    private func getFunctionName(fromCalledExpr calledExpr: ExprSyntax) -> String {
        if let memExpr: MemberAccessExprSyntax = calledExpr.as(MemberAccessExprSyntax.self) {
            return memExpr.declName.baseName.text
        } else if let refExpr: DeclReferenceExprSyntax = calledExpr.as(DeclReferenceExprSyntax.self) {
            return refExpr.baseName.text
        }
        
        return ""
    }
    
    private func parameterIndex(of node: FunctionParameterSyntax) -> Int? {
        guard let list = node.parent?.as(FunctionParameterListSyntax.self) else { return nil }
        for (i, param) in list.enumerated() where param.id == node.id {
            return i
        }
        return nil
    }
    
    private func enclosingFunctionSymbol(of node: FunctionParameterSyntax) -> SPSwiftSourceFunctionSymbol? {
        var parent: Syntax? = node.parent
        while let cur = parent {
            var signature: String?
            if let f = cur.as(FunctionDeclSyntax.self) {
                signature = ConfuseHelper.generateSignature(
                    funcName: f.name.text,
                    parameters: f.signature.parameterClause.parameters
                )
            } else if let i = cur.as(InitializerDeclSyntax.self) {
                signature = ConfuseHelper.generateSignature(
                    funcName: i.initKeyword.text,
                    parameters: i.signature.parameterClause.parameters
                )
            }
            
            if let signature {
                let scope = IndexStore.indexStore.scope(
                    token: node.firstName,
                    inFile:self.sourceFile
                )
                return scope?.findSymbolWithSymbolName(signature) as? SPSwiftSourceFunctionSymbol
            }
            
            parent = cur.parent
        }
        
        return nil
    }
    
    private func calledNameToken(_ expr: ExprSyntax) -> TokenSyntax? {
        if let m = expr.as(MemberAccessExprSyntax.self) { return m.declName.baseName }
        if let d = expr.as(DeclReferenceExprSyntax.self) { return d.baseName }
        return nil
    }
    
    private func functionSymbol(at token: TokenSyntax) -> SPSwiftSourceFunctionSymbol? {
        let loc = self.locationConverter.location(for: token.positionAfterSkippingLeadingTrivia)
        guard let ref = IndexStore.indexStore.getRef(fromFile: self.sourceFile,
                                                     line: loc.line,
                                                     col: loc.column),
              let usr: String = ref[self.sourceKit.keys.usr] else { return nil }
        return IndexStore.indexStore.getSymbol(usr: usr) as? SPSwiftSourceFunctionSymbol
    }
}
