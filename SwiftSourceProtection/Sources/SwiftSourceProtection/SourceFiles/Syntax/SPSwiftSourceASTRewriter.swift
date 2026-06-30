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
    
    override func visit(_ node: FunctionTypeSyntax) -> TypeSyntax {
        var newNode = node
        
        var confusedParams: [TupleTypeElementSyntax] = []
        node.parameters.forEach {
            if let secondName = $0.secondName {
                var confusedParam = $0.with(\.secondName, .identifier(
                    ConfuseHelper.confusedSymbolName(secondName.text),
                    leadingTrivia: secondName.leadingTrivia,
                    trailingTrivia: secondName.trailingTrivia)
                )
                
                confusedParam = confusedParam.with(\.type, self.confuseType($0.type))
                confusedParams.append(confusedParam)
            } else {
                confusedParams.append($0)
            }
        }
        
        newNode = newNode.with(\.parameters, TupleTypeElementListSyntax(confusedParams)
            .with(\.leadingTrivia, newNode.parameters.leadingTrivia)
            .with(\.trailingTrivia, newNode.parameters.trailingTrivia)
        )
        
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
        if let refs = IndexStore.indexStore.getRef(fromFile: self.sourceFile, line: refLoc.line, col: refLoc.column),
           let ref = self.matchRef(refs, to: node) {
            if let usr: String = ref[sourceKit.keys.usr],
               let symbol: SPSwiftSourceSymbol = IndexStore.indexStore.getSymbol(usr: usr),
               let confusedSymbolName = symbol.confusedSymbolName {
                return super.visit(node.with(\.tokenKind, .identifier(confusedSymbolName)))
            }
            
            return super.visit(node)
        }
        
        guard !self.skipScopeResolution(node) else {
            return super.visit(node)
        }
        
        if let scopeForNode: SPSwiftSourceScope = IndexStore.indexStore.scope(token: node, inFile: self.sourceFile),
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
    
    private func matchRef(_ refs: [SKResponseDictionary], to token: TokenSyntax) -> SKResponseDictionary? {
        return refs.first { ref in
            let name = (ref[sourceKit.keys.name] as String?) ?? ""
            let base = name.components(separatedBy: "(").first ?? name
            
            return base == token.text
        }
    }
   
    private func confuseType(_ type: TypeSyntax) -> TypeSyntax {
        if let idTypeSyntax: IdentifierTypeSyntax = type.as(IdentifierTypeSyntax.self) {
            let location = self.locationConverter.location(for: idTypeSyntax.name.positionAfterSkippingLeadingTrivia)
            if let refs = IndexStore.indexStore.getRef(fromFile: self.sourceFile, line: location.line, col: location.column),
               let matchedRef = self.matchRef(refs, to: idTypeSyntax.name) {
                if let usr: String = matchedRef[sourceKit.keys.usr],
                   let symbol: SPSwiftSourceSymbol = IndexStore.indexStore.getSymbol(usr: usr),
                   let confusedSymbolName = symbol.confusedSymbolName {
                    return TypeSyntax(idTypeSyntax.with(\.name, .identifier(
                        confusedSymbolName,
                        leadingTrivia: idTypeSyntax.leadingTrivia,
                        trailingTrivia: idTypeSyntax.trailingTrivia)
                    ))
                }
                
                return type
            }
        } else if let tupTypeSyntax: TupleTypeSyntax = type.as(TupleTypeSyntax.self) {
            let confusedType: [TupleTypeElementSyntax] = tupTypeSyntax.elements.map { $0.with(\.type, self.confuseType($0.type)).with(\.leadingTrivia, $0.type.leadingTrivia).with(\.trailingTrivia, $0.type.trailingTrivia) }
            return TypeSyntax(tupTypeSyntax.with(\.elements, TupleTypeElementListSyntax(confusedType).with(\.leadingTrivia, tupTypeSyntax.elements.leadingTrivia).with(\.trailingTrivia, tupTypeSyntax.elements.trailingTrivia)))
        }
        
        return type
    }
    
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
        guard let refs = IndexStore
            .indexStore.getRef(
                fromFile: self.sourceFile,
                line: loc.line,
                col: loc.column
            ) else { return nil }
        
        for ref in refs {
            if let usr: String = ref[self.sourceKit.keys.usr],
               let symbol: SPSwiftSourceFunctionSymbol = IndexStore.indexStore.getSymbol(usr: usr) as? SPSwiftSourceFunctionSymbol {
                return symbol
            }
        }
        
        return nil
    }
    
    private func skipScopeResolution(_ node: TokenSyntax) -> Bool {
          guard let parent = node.parent else { return false }

          if let d = parent.as(DeclReferenceExprSyntax.self),
             let ma = d.parent?.as(MemberAccessExprSyntax.self), ma.declName.id == d.id {
              return true
          }
        
          if let le = parent.as(LabeledExprSyntax.self), le.label?.id == node.id {
              return true
          }
        
          if let te = parent.as(TupleTypeElementSyntax.self),
             te.firstName?.id == node.id || te.secondName?.id == node.id {
              return true
          }
          return false
      }
}
