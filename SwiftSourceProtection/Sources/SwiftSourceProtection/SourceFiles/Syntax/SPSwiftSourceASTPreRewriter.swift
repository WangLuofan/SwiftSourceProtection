//
//  SPSwiftSourceASTPreRewriter.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/30.
//
import SwiftSyntax
import sourcekitd

class SPSwiftSourceASTPreRewriter: SyntaxVisitor {
    private var fileScope: SPSwiftSourceScope
    private var sourceFile: File
    private var sourceKit: SourceKit
    private var sourceTree: SourceFileSyntax
    private var locationConverter: SourceLocationConverter
    
    init(fileScope: SPSwiftSourceScope, sourceFile: File, sourceKit: SourceKit, sourceTree: SourceFileSyntax) {
        self.fileScope = fileScope
        self.sourceFile = sourceFile
        self.sourceKit = sourceKit
        self.sourceTree = sourceTree
        
        self.locationConverter = SourceLocationConverter(
            fileName: self.sourceFile.path,
            tree: self.sourceTree
        )
        
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        self.relateCallExpression(node.calledExpression)
        return super.visit(node)
    }
    
    override func visit(_ node: TokenSyntax) -> SyntaxVisitorContinueKind {
        
        guard case .identifier = node.tokenKind,
              !node.text.isSwiftKeyWord else {
            return super.visit(node)
        }

        let refLoc = self.locationConverter.location(for: node.positionAfterSkippingLeadingTrivia)
        if let refs = IndexStore.indexStore.getRef(fromFile: self.sourceFile, line: refLoc.line, col: refLoc.column),
           let ref = self.matchRef(refs, to: node) {
            if let usr: String = ref[sourceKit.keys.usr],
               let symbol: SPSwiftSourceSymbol = IndexStore.indexStore.getSymbol(usr: usr) {
                SymbolIndexRelator.shared.set(symbol: symbol, index: node.id.indexInTree.toOpaque(), forFile: self.sourceFile)
            }
        } else if let scopeForNode: SPSwiftSourceScope = IndexStore.indexStore.scope(token: node, inFile: self.sourceFile),
           let symbol: SPSwiftSourceSymbol = scopeForNode.findSymbolWithSymbolName(node.text) {
            if let memAccExpr: MemberAccessExprSyntax = node.getParentNode(),
               memAccExpr.declName.baseName == node {
                /// memAcc.decl不处理，由后续流程处理
                return super.visit(node)
            } else if let _: TupleTypeSyntax = node.getParentNode() {
                /// tuple标签不处理
                return super.visit(node)
            } else if let tupExpr: TupleExprSyntax = node.getParentNode() {
                for elem in tupExpr.elements {
                    if elem.label == node {
                        return super.visit(node)
                    }
                }
            }
                
            SymbolIndexRelator.shared.set(symbol: symbol, index: node.id.indexInTree.toOpaque(), forFile: self.sourceFile)
        }
        
        return super.visit(node)
    }
}

extension SPSwiftSourceASTPreRewriter {
    func process() {
        self.walk(self.sourceTree)
    }
    
    private func matchRef(_ refs: [SKResponseDictionary], to token: TokenSyntax) -> SKResponseDictionary? {
        return refs.first { ref in
            let name = (ref[sourceKit.keys.name] as String?) ?? ""
            let base = name.components(separatedBy: "(").first ?? name
            
            return base == token.text
        }
    }
    
    private func relateCallExpression(_ calledExpression: ExprSyntaxProtocol) {
        if let declRefExprSyntax: DeclReferenceExprSyntax = calledExpression.as(DeclReferenceExprSyntax.self) {
            let refLoc = self.locationConverter.location(for: declRefExprSyntax.baseName.positionAfterSkippingLeadingTrivia)
            if let refs = IndexStore.indexStore.getRef(fromFile: self.sourceFile, line: refLoc.line, col: refLoc.column),
               let ref = self.matchRef(refs, to: declRefExprSyntax.baseName),
               let usr: String = ref[sourceKit.keys.usr],
               let symbol: SPSwiftSourceSymbol = IndexStore.indexStore.getSymbol(usr: usr) {
                
                SymbolIndexRelator.shared.set(symbol: symbol, index: declRefExprSyntax.baseName.id.indexInTree.toOpaque(), forFile: self.sourceFile)
            }
        } else if let memAccExprSyntax: MemberAccessExprSyntax = calledExpression.as(MemberAccessExprSyntax.self) {
            self.relateCallExpression(memAccExprSyntax.declName)
        }
    }
}
