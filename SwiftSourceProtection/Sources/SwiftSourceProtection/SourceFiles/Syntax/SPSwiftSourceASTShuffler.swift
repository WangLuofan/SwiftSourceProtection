//
//  SPSwiftSourceASTShuffler.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/7/3.
//

import SwiftSyntax

class SPSwiftSourceASTShuffler: SyntaxRewriter {
    private var sourceTree: SourceFileSyntax
    private var sourceFile: File
    
    init(sourceTree: SourceFileSyntax, sourceFile: File) {
        self.sourceTree = sourceTree
        self.sourceFile = sourceFile
        
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
        var newNode = node
        
        var importDecls: [CodeBlockItemSyntax] = []
        var nonImportDecls: [CodeBlockItemSyntax] = []
        
        node.statements.forEach {
            if let _: ImportDeclSyntax = $0.item.as(ImportDeclSyntax.self) {
                importDecls.append($0)
            } else {
                nonImportDecls.append($0)
            }
        }
        
        importDecls.shuffle()
        nonImportDecls.shuffle()
        
        newNode = newNode.with(\.statements, CodeBlockItemListSyntax(importDecls + nonImportDecls))
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        var newNode = node
        
        var memberBlockItems: [MemberBlockItemSyntax] = []
        node.memberBlock.members.forEach {
            memberBlockItems.append($0)
        }
        memberBlockItems.shuffle()
        
        newNode = newNode.with(\.memberBlock, newNode.memberBlock.with(\.members, MemberBlockItemListSyntax(memberBlockItems)))
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        var newNode = node
        
        let memberBlockItems: [MemberBlockItemSyntax] = self.shuffleMemberBlock(node.memberBlock.members)
        newNode = newNode.with(\.memberBlock, newNode.memberBlock.with(\.members, MemberBlockItemListSyntax(memberBlockItems)))
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
        var newNode = node
        
        let memberBlockItems: [MemberBlockItemSyntax] = self.shuffleMemberBlock(node.memberBlock.members)
        newNode = newNode.with(\.memberBlock, newNode.memberBlock.with(\.members, MemberBlockItemListSyntax(memberBlockItems)))
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        var newNode = node
        
        let memberBlockItems: [MemberBlockItemSyntax] = self.shuffleMemberBlock(node.memberBlock.members)
        newNode = newNode.with(\.memberBlock, newNode.memberBlock.with(\.members, MemberBlockItemListSyntax(memberBlockItems)))
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        var newNode = node
        
        let memberBlockItems: [MemberBlockItemSyntax] = self.shuffleMemberBlock(node.memberBlock.members)
        newNode = newNode.with(\.memberBlock, newNode.memberBlock.with(\.members, MemberBlockItemListSyntax(memberBlockItems)))
        
        return super.visit(newNode)
    }
}

extension SPSwiftSourceASTShuffler {
    func shuffle() -> SourceFileSyntax {
        let rewritedSyntax: SourceFileSyntax = self.visit(self.sourceTree)
        return rewritedSyntax
    }
    
    private func shuffleMemberBlock(_ members: MemberBlockItemListSyntax) -> [MemberBlockItemSyntax] {
        var memberBlockItems: [MemberBlockItemSyntax] = []
        members.forEach {
            memberBlockItems.append($0)
        }
        memberBlockItems.shuffle()
        
        return memberBlockItems
    }
}
