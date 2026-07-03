//
//  SPSwiftSourceASTCollector.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/8.
//

import SwiftSyntax
import sourcekitd

class SPSwiftSourceASTCollector: SyntaxVisitor {
    private var sourceTree: SourceFileSyntax
    private var sourceFile: File
    private var module: Module
    private var topScope: SPSwiftSourceScope = SPSwiftSourceScope()
    private var extensions: [SPSwiftSourceClassSymbol] = []
    private lazy var currentScope: SPSwiftSourceScope = self.topScope
    
    private var locationConverter: SourceLocationConverter
    private var parentStack: [SPSwiftSourceClassSymbol] = []
    
    init(sourceTree: SourceFileSyntax, sourceFile: File, module: Module) {
        self.sourceTree = sourceTree
        self.sourceFile = sourceFile
        self.module = module
        
        self.locationConverter = SourceLocationConverter(
            fileName: self.sourceFile.path,
            tree: self.sourceTree
        )
        
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visitPost(_ node: SourceFileSyntax) {
        guard !self.extensions.isEmpty else {
            return
        }
        
        self.extensions.forEach {
            if let clsSymbol: SPSwiftSourceClassSymbol = self.topScope.findSymbolWithSymbolName($0.originalSymbolName) as? SPSwiftSourceClassSymbol {
                clsSymbol.children.append(contentsOf: $0.children)
            } else {
                self.topScope.pushSymbol($0)
            }
        }
        self.extensions.removeAll()
    }
    
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SPSwiftSourceClassSymbol = SPSwiftSourceClassSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope, sourceLocation: self.locationConverter.location(for: node.name.positionAfterSkippingLeadingTrivia))
        
        symbol.originalSymbolName = node.name.text
        
        self.parentStack.last?.children.append(symbol)
        self.parentStack.append(symbol)
        
        ConfuseHelper.confuseSymbol(symbol)
        
        self.currentScope.pushSymbol(symbol)
        self.currentScope = self.currentScope.pushScope()
        IndexStore.indexStore.set(nodeID: node.id.indexInTree.toOpaque(), self.currentScope, inFile: self.sourceFile)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: ClassDeclSyntax) {
        if !self.parentStack.isEmpty {
            self.parentStack.removeLast()
        }
        
        self.currentScope = self.currentScope.popScope()
    }
    
    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SPSwiftSourceClassSymbol = SPSwiftSourceClassSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope, nodeKind: .struct, sourceLocation: self.locationConverter.location(for: node.name.positionAfterSkippingLeadingTrivia))
        symbol.originalSymbolName = node.name.text
        
        self.parentStack.last?.children.append(symbol)
        self.parentStack.append(symbol)
        
        ConfuseHelper.confuseSymbol(symbol)
        
        self.currentScope.pushSymbol(symbol)
        self.currentScope = self.currentScope.pushScope()
        IndexStore.indexStore.set(nodeID: node.id.indexInTree.toOpaque(), self.currentScope, inFile: self.sourceFile)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: StructDeclSyntax) {
        if !self.parentStack.isEmpty {
            self.parentStack.removeLast()
        }
        
        self.currentScope = self.currentScope.popScope()
    }
    
    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SPSwiftSourceClassSymbol = SPSwiftSourceClassSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope, nodeKind: .protocol, sourceLocation: self.locationConverter.location(for: node.name.positionAfterSkippingLeadingTrivia))
        symbol.originalSymbolName = node.name.text
        
        self.parentStack.last?.children.append(symbol)
        self.parentStack.append(symbol)
        
        ConfuseHelper.confuseSymbol(symbol)
        
        self.currentScope.pushSymbol(symbol)
        self.currentScope = self.currentScope.pushScope()
        IndexStore.indexStore.set(nodeID: node.id.indexInTree.toOpaque(), self.currentScope, inFile: self.sourceFile)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: ProtocolDeclSyntax) {
        if !self.parentStack.isEmpty {
            self.parentStack.removeLast()
        }
        
        self.currentScope = self.currentScope.popScope()
    }
    
    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SPSwiftSourceClassSymbol = SPSwiftSourceClassSymbol(
            sourceFile: self.sourceFile,
            symbolScope: node.symbolScope,
            nodeKind: .enum,
            sourceLocation: self.locationConverter.location(for: node.name.positionAfterSkippingLeadingTrivia)
        )
        
        symbol.originalSymbolName = node.name.text
        
        self.parentStack.last?.children.append(symbol)
        self.parentStack.append(symbol)
        
        ConfuseHelper.confuseSymbol(symbol)
        
        self.currentScope.pushSymbol(symbol)
        self.currentScope = self.currentScope.pushScope()
        IndexStore.indexStore.set(nodeID: node.id.indexInTree.toOpaque(), self.currentScope, inFile: self.sourceFile)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: EnumDeclSyntax) {
        if !self.parentStack.isEmpty {
            self.parentStack.removeLast()
        }
        
        self.currentScope = self.currentScope.popScope()
    }
    
    override func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
        node.elements.forEach {
            let symbol: SPSwiftSourceEnumCaseSymbol = SPSwiftSourceEnumCaseSymbol(
                sourceFile: self.sourceFile,
                signature: "",
                symbolScope: node.symbolScope,
                sourceLocation: self.locationConverter.location(for: $0.name.positionAfterSkippingLeadingTrivia)
            )
            
            var symbolSignature: String = $0.name.text
            if let paramClause: EnumCaseParameterClauseSyntax = $0.parameterClause {
                symbolSignature += "("
                
                paramClause.parameters.forEach {
                    let label: String = $0.firstName?.text ?? "_"
                    symbol.labels.append(label)
                    symbol.confusedLabels.append(label)
                    
                    symbolSignature += "\(label):"
                }
                
                symbolSignature += ")"
            }
            
            symbol.signature = symbolSignature
            symbol.originalSymbolName = $0.name.text
            ConfuseHelper.confuseSymbol(symbol)
            
            self.currentScope.pushSymbol(symbol)
            
            self.parentStack.last?.children.append(symbol)
        }
        
        return super.visit(node)
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        let clsSymbol: SPSwiftSourceClassSymbol = SPSwiftSourceClassSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope, sourceLocation: self.locationConverter.location(for: node.positionAfterSkippingLeadingTrivia))
        if let extendedType: IdentifierTypeSyntax = node.extendedType.as(IdentifierTypeSyntax.self) {
            clsSymbol.originalSymbolName = extendedType.name.text
        }
        self.extensions.append(clsSymbol)
        self.parentStack.append(clsSymbol)
        
        self.currentScope = self.currentScope.pushScope()
        IndexStore.indexStore.set(nodeID: node.id.indexInTree.toOpaque(), self.currentScope, inFile: self.sourceFile)
        return super.visit(node)
    }
    
    override func visitPost(_ node: ExtensionDeclSyntax) {
        if !self.parentStack.isEmpty {
            self.parentStack.removeLast()
        }
        
        self.currentScope = self.currentScope.popScope()
    }
    
    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        let symbols: [SPSwiftSourceVariableSymbol] = node.bindings.flatMap { binding in
            self.extractPatternNames(binding.pattern).map {
                let symbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope, sourceLocation: self.locationConverter.location(for: binding.pattern.positionAfterSkippingLeadingTrivia))
                symbol.originalSymbolName = $0
                return symbol
            }
        }
        
        node.modifiers.forEach { modifier in
            if let declModifierSyntax: DeclModifierSyntax = modifier.as(DeclModifierSyntax.self) {
                switch declModifierSyntax.name.tokenKind {
                case .keyword(let keyword):
                    switch keyword {
                    case .static:
                        symbols.forEach { $0.isStaticSymbol = true }
                    case .open:
                        symbols.forEach { $0.accessLevel = .open }
                    case .public:
                        symbols.forEach { $0.accessLevel = .public }
                    case .package:
                        symbols.forEach { $0.accessLevel = .package }
                    case .internal:
                        symbols.forEach { $0.accessLevel = .internal }
                    case .fileprivate:
                        symbols.forEach { $0.accessLevel = .fileprivate }
                    case .private:
                        symbols.forEach { $0.accessLevel = .private }
                    default:
                        break
                    }
                default:
                    break
                }
            }
        }
        
        symbols.forEach {
            if $0.symbolScope == .local {
                $0.confusedSymbolName = ConfuseHelper.confusedSymbolName($0.originalSymbolName)
            } else if $0.symbolScope == .member {
                self.parentStack.last?.children.append($0)
            }
            
            self.currentScope.pushSymbol($0)
        }
        
        self.currentScope = self.currentScope.pushScope()
        IndexStore.indexStore.set(nodeID: node.id.indexInTree.toOpaque(), self.currentScope, inFile: self.sourceFile)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: VariableDeclSyntax) {
        self.currentScope = self.currentScope.popScope()
    }
    
    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        self.currentScope = self.currentScope.pushScope()
        IndexStore.indexStore.set(nodeID: node.id.indexInTree.toOpaque(), self.currentScope, inFile: self.sourceFile)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: ClosureExprSyntax) {
        self.currentScope = self.currentScope.popScope()
    }
    
    override func visit(_ node: ClosureShorthandParameterSyntax) -> SyntaxVisitorContinueKind {
        
        let paramSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: .local, sourceLocation: self.locationConverter.location(for: node.name.positionAfterSkippingLeadingTrivia))
        paramSymbol.originalSymbolName = node.name.text
        paramSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName(node.name.text)
        self.currentScope.pushSymbol(paramSymbol)
        
        return super.visit(node)
    }
    
    override func visit(_ node: ClosureParameterSyntax) -> SyntaxVisitorContinueKind {
        
        let paramSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: .local, sourceLocation: self.locationConverter.location(for: node.firstName.positionAfterSkippingLeadingTrivia))
        paramSymbol.originalSymbolName = node.firstName.text
        paramSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName(node.firstName.text)
        self.currentScope.pushSymbol(paramSymbol)
        
        return super.visit(node)
    }
    
    override func visit(_ node: ClosureCaptureSyntax) -> SyntaxVisitorContinueKind {
        if !node.name.text.isSwiftKeyWord {
            let varSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope, sourceLocation: self.locationConverter.location(for: node.name.positionAfterSkippingLeadingTrivia))
            varSymbol.originalSymbolName = node.name.text
            varSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName(node.name.text)
            
            self.currentScope.pushSymbol(varSymbol)
        }
        
        return super.visit(node)
    }
    
    override func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
        let paramSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: .local, sourceLocation: self.locationConverter.location(for: node.firstName.positionAfterSkippingLeadingTrivia))
        paramSymbol.originalSymbolName = node.firstName.text
        if let secondName: TokenSyntax = node.secondName {
            paramSymbol.originalSymbolName = secondName.text
            paramSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName(secondName.text)
            paramSymbol.sourceLocation = self.locationConverter.location(for: secondName.positionAfterSkippingLeadingTrivia)
        }
        
        if let curFunc: FunctionDeclSyntax = node.getParentNode() {
            let signature: String = ConfuseHelper.generateSignature(funcName: curFunc.name.text, parameters: curFunc.signature.parameterClause.parameters)
            if let funcSymbol: SPSwiftSourceFunctionSymbol = self.currentScope.findSymbolWithSymbolName(signature) as? SPSwiftSourceFunctionSymbol {
                funcSymbol.arguments.append(paramSymbol)
                
                funcSymbol.labels.append(node.firstName.text)
                funcSymbol.confusedLabels.append(node.firstName.text)
            }
        } else if let curFunc: InitializerDeclSyntax = node.getParentNode() {
            let signature: String = ConfuseHelper.generateSignature(funcName: curFunc.initKeyword.text, parameters: curFunc.signature.parameterClause.parameters)
            if let funcSymbol: SPSwiftSourceFunctionSymbol = self.currentScope.findSymbolWithSymbolName(signature) as? SPSwiftSourceFunctionSymbol {
                funcSymbol.arguments.append(paramSymbol)
                
                funcSymbol.labels.append(node.firstName.text)
                funcSymbol.confusedLabels.append(node.firstName.text)
            }
        }
        
        self.currentScope.pushSymbol(paramSymbol)
        return super.visit(node)
    }
    
    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SPSwiftSourceFunctionSymbol = SPSwiftSourceFunctionSymbol(
            sourceFile: self.sourceFile,
            signature: ConfuseHelper.generateSignature(
                funcName: node.initKeyword.text,
                parameters: node.signature.parameterClause.parameters
            ),
            symbolScope: node.symbolScope,
            sourceLocation: self.locationConverter.location(for: node.initKeyword.positionAfterSkippingLeadingTrivia)
        )
        symbol.originalSymbolName = node.initKeyword.text
        
        node.modifiers.forEach { modifier in
            if let declModifierSyntax: DeclModifierSyntax = modifier.as(DeclModifierSyntax.self) {
                switch declModifierSyntax.name.tokenKind {
                case .keyword(let keyword):
                    switch keyword {
                    case .static:
                        symbol.isStaticSymbol = true
                    case .open:
                        symbol.accessLevel = .open
                    case .public:
                        symbol.accessLevel = .public
                    case .package:
                        symbol.accessLevel = .package
                    case .internal:
                        symbol.accessLevel = .internal
                    case .fileprivate:
                        symbol.accessLevel = .fileprivate
                    case .private:
                        symbol.accessLevel = .private
                    default:
                        break
                    }
                default:
                    break
                }
            }
        }
        
        if symbol.symbolScope == .local {
            ConfuseHelper.confuseSymbol(symbol)
        } else if symbol.symbolScope == .member {
            self.parentStack.last?.children.append(symbol)
        }
        
        self.currentScope.pushSymbol(symbol)
        self.currentScope = self.currentScope.pushScope()
        
        IndexStore.indexStore.set(nodeID: node.id.indexInTree.toOpaque(), self.currentScope, inFile: self.sourceFile)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: InitializerDeclSyntax) {
        self.currentScope = self.currentScope.popScope()
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SPSwiftSourceFunctionSymbol = SPSwiftSourceFunctionSymbol(
            sourceFile: self.sourceFile,
            signature: ConfuseHelper.generateSignature(
                funcName: node.name.text,
                parameters: node.signature.parameterClause.parameters
            ),
            symbolScope: node.symbolScope,
            sourceLocation: self.locationConverter.location(for: node.name.positionAfterSkippingLeadingTrivia)
        )
        symbol.originalSymbolName = node.name.text
        
        node.modifiers.forEach { modifier in
            if let declModifierSyntax: DeclModifierSyntax = modifier.as(DeclModifierSyntax.self) {
                switch declModifierSyntax.name.tokenKind {
                case .keyword(let keyword):
                    switch keyword {
                    case .static:
                        symbol.isStaticSymbol = true
                    case .open:
                        symbol.accessLevel = .open
                    case .public:
                        symbol.accessLevel = .public
                    case .package:
                        symbol.accessLevel = .package
                    case .internal:
                        symbol.accessLevel = .internal
                    case .fileprivate:
                        symbol.accessLevel = .fileprivate
                    case .private:
                        symbol.accessLevel = .private
                    default:
                        break
                    }
                default:
                    break
                }
            }
        }
        
        ConfuseHelper.confuseSymbol(symbol)
        if symbol.symbolScope == .member || symbol.symbolScope == .global {
            self.parentStack.last?.children.append(symbol)
        }
        
        self.currentScope.pushSymbol(symbol)
        self.currentScope = self.currentScope.pushScope()
        
        IndexStore.indexStore.set(nodeID: node.id.indexInTree.toOpaque(), self.currentScope, inFile: self.sourceFile)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: FunctionDeclSyntax) {
        self.currentScope = self.currentScope.popScope()
    }
    
    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        self.currentScope = self.currentScope.pushScope()
        IndexStore.indexStore.set(nodeID: node.id.indexInTree.toOpaque(), self.currentScope, inFile: self.sourceFile)
        
        let symbols: [String] = self.extractPatternNames(node.pattern)
        symbols.forEach {
            let varSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: .local, sourceLocation: self.locationConverter.location(for: node.pattern.positionAfterSkippingLeadingTrivia))
            varSymbol.originalSymbolName = $0
            varSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName($0)
            
            self.currentScope.pushSymbol(varSymbol)
        }
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: ForStmtSyntax) {
        self.currentScope = self.currentScope.popScope()
    }
    
    override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        self.currentScope = self.currentScope.pushScope()
        IndexStore.indexStore.set(nodeID: node.id.indexInTree.toOpaque(), self.currentScope, inFile: self.sourceFile)
        
        node.conditions.forEach {
            if let optBindCondSyntax: OptionalBindingConditionSyntax = $0.condition.as(OptionalBindingConditionSyntax.self),
               let _ = optBindCondSyntax.initializer {
                let symbols: [String] = self.extractPatternNames(optBindCondSyntax.pattern)
                symbols.forEach {
                    let varSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope, sourceLocation: self.locationConverter.location(for: optBindCondSyntax.pattern.positionAfterSkippingLeadingTrivia))
                    varSymbol.originalSymbolName = $0
                    varSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName($0)
                    
                    self.currentScope.pushSymbol(varSymbol)
               }
            } else if let matchPatternCondSyntax: MatchingPatternConditionSyntax = $0.condition.as(MatchingPatternConditionSyntax.self) {
                let symbols: [String] = self.extractPatternNames(matchPatternCondSyntax.pattern)
                symbols.forEach {
                    let varSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope, sourceLocation: self.locationConverter.location(for: matchPatternCondSyntax.positionAfterSkippingLeadingTrivia))
                    varSymbol.originalSymbolName = $0
                    varSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName($0)
                    
                    self.currentScope.pushSymbol(varSymbol)
                }
            }
        }
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: WhileStmtSyntax) {
        self.currentScope = self.currentScope.popScope()
    }
    
    override func visit(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind {
        self.currentScope = self.currentScope.pushScope()
        IndexStore.indexStore.set(nodeID: node.id.indexInTree.toOpaque(), self.currentScope, inFile: self.sourceFile)
        
        node.conditions.forEach { condition in
            if let optBindCondSyntax: OptionalBindingConditionSyntax = condition.condition.as(OptionalBindingConditionSyntax.self),
               let _ = optBindCondSyntax.initializer {
                let symbols: [String] = self.extractPatternNames(optBindCondSyntax.pattern)
                symbols.forEach {
                    let varSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: .local, sourceLocation: self.locationConverter.location(for: optBindCondSyntax.pattern.positionAfterSkippingLeadingTrivia))
                    varSymbol.originalSymbolName = $0
                    varSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName($0)
                    
                    self.currentScope.pushSymbol(varSymbol)
                }
            }  else if let matchPatternCondSyntax: MatchingPatternConditionSyntax = condition.condition.as(MatchingPatternConditionSyntax.self) {
                let symbols: [String] = self.extractPatternNames(matchPatternCondSyntax.pattern)
                symbols.forEach {
                    let varSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope, sourceLocation: self.locationConverter.location(for: matchPatternCondSyntax.pattern.positionAfterSkippingLeadingTrivia))
                    varSymbol.originalSymbolName = $0
                    varSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName($0)
                    
                    self.currentScope.pushSymbol(varSymbol)
                }
            }
        }
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: IfExprSyntax) {
        self.currentScope = self.currentScope.popScope()
    }
    
    override func visit(_ node: SwitchExprSyntax) -> SyntaxVisitorContinueKind {
        self.currentScope = self.currentScope.pushScope()
        IndexStore.indexStore.set(nodeID: node.id.indexInTree.toOpaque(), self.currentScope, inFile: self.sourceFile)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: SwitchExprSyntax) {
        self.currentScope = self.currentScope.popScope()
    }
    
    override func visit(_ node: SwitchCaseSyntax) -> SyntaxVisitorContinueKind {
        self.currentScope = self.currentScope.pushScope()
        IndexStore.indexStore.set(nodeID: node.id.indexInTree.toOpaque(), self.currentScope, inFile: self.sourceFile)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: SwitchCaseSyntax) {
        self.currentScope = self.currentScope.popScope()
    }
    
    override func visit(_ node: SwitchCaseItemSyntax) -> SyntaxVisitorContinueKind {
        let symbols: [String] = self.extractPatternNames(node.pattern)
        
        symbols.forEach {
            let varSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope, sourceLocation: self.locationConverter.location(for: node.pattern.positionAfterSkippingLeadingTrivia))
            varSymbol.originalSymbolName = $0
            varSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName($0)
            self.currentScope.pushSymbol(varSymbol)
        }
        
        return super.visit(node)
    }
    
    override func visit(_ node: SwitchDefaultLabelSyntax) -> SyntaxVisitorContinueKind {
        self.currentScope = self.currentScope.pushScope()
        IndexStore.indexStore.set(nodeID: node.id.indexInTree.toOpaque(), self.currentScope, inFile: self.sourceFile)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: SwitchDefaultLabelSyntax) {
        self.currentScope = self.currentScope.popScope()
    }
    
    override func visit(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
        node.conditions.forEach { condition in
            if let condition: OptionalBindingConditionSyntax = condition.condition.as(OptionalBindingConditionSyntax.self) {
                if let _ = condition.initializer {
                    let symbols: [String] = self.extractPatternNames(condition.pattern)
                    symbols.forEach {
                        let paramSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: .local, sourceLocation: self.locationConverter.location(for: condition.pattern.positionAfterSkippingLeadingTrivia))
                        paramSymbol.originalSymbolName = $0
                        paramSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName($0)
                        
                        self.currentScope.pushSymbol(paramSymbol)
                    }
                }
            } else if let matchPatternCondSyntax: MatchingPatternConditionSyntax = condition.condition.as(MatchingPatternConditionSyntax.self) {
                let symbols: [String] = self.extractPatternNames(matchPatternCondSyntax.pattern)
                symbols.forEach {
                    let varSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope, sourceLocation: self.locationConverter.location(for: matchPatternCondSyntax.pattern.positionAfterSkippingLeadingTrivia))
                    varSymbol.originalSymbolName = $0
                    varSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName($0)
                    
                    self.currentScope.pushSymbol(varSymbol)
                }
            }
        }
        
        self.currentScope = self.currentScope.pushScope()
        IndexStore.indexStore.set(nodeID: node.id.indexInTree.toOpaque(), self.currentScope, inFile: self.sourceFile)
        
        return super.visit(node)
    }
    
    override func visit(_ node: DoStmtSyntax) -> SyntaxVisitorContinueKind {
        self.currentScope = self.currentScope.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: DoStmtSyntax) {
        self.currentScope = self.currentScope.popScope()
    }
    
    override func visit(_ node: RepeatStmtSyntax) -> SyntaxVisitorContinueKind {
        self.currentScope = self.currentScope.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: RepeatStmtSyntax) {
        self.currentScope = self.currentScope.popScope()
    }
    
    override func visit(_ node: DeinitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        self.currentScope = self.currentScope.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: DeinitializerDeclSyntax) {
        self.currentScope = self.currentScope.popScope()
    }
    
    override func visitPost(_ node: GuardStmtSyntax) {
        self.currentScope = self.currentScope.popScope()
    }
    
    override func visit(_ node: CatchClauseSyntax) -> SyntaxVisitorContinueKind {
        self.currentScope = self.currentScope.pushScope()
        IndexStore.indexStore.set(nodeID: node.id.indexInTree.toOpaque(), self.currentScope, inFile: self.sourceFile)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: CatchClauseSyntax) {
        self.currentScope = self.currentScope.popScope()
    }
    
    override func visit(_ node: CatchItemSyntax) -> SyntaxVisitorContinueKind {
        if let pattern: PatternSyntax = node.pattern {
            let symbols: [String] = self.extractPatternNames(pattern)
            symbols.forEach {
                let varSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope, sourceLocation: self.locationConverter.location(for: pattern.positionAfterSkippingLeadingTrivia))
                varSymbol.originalSymbolName = $0
                varSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName($0)
                
                self.currentScope.pushSymbol(varSymbol)
            }
        }
        
        return super.visit(node)
    }
}

extension SPSwiftSourceASTCollector {
    func walk() -> SPSwiftSourceScope {
        self.walk(self.sourceTree)
        
        IndexStore.indexStore.set(nodeID: self.sourceTree.id.indexInTree.toOpaque(), self.topScope, inFile:
          self.sourceFile)
        return self.topScope
    }
    
    private func extractPatternNames(_ pattern: PatternSyntax) -> [String] {
        if let idPatternSyntax: IdentifierPatternSyntax = pattern.as(IdentifierPatternSyntax.self) {
            return [idPatternSyntax.identifier.text]
        } else if let tupPatternSyntax: TuplePatternSyntax = pattern.as(TuplePatternSyntax.self) {
            return tupPatternSyntax.elements.flatMap { extractPatternNames($0.pattern) }
        } else if let valueBindingPatternSyntax: ValueBindingPatternSyntax = pattern.as(ValueBindingPatternSyntax.self) {
            return extractPatternNames(valueBindingPatternSyntax.pattern)
        } else if let exprPatternSyntax: ExpressionPatternSyntax = pattern.as(ExpressionPatternSyntax.self) {
            return extractPatternNames(fromExpr: exprPatternSyntax.expression)
        }

        return []
    }

    private func extractPatternNames(fromExpr expr: ExprSyntax) -> [String] {
        if let patternExprSyntax: PatternExprSyntax = expr.as(PatternExprSyntax.self) {
            return extractPatternNames(patternExprSyntax.pattern)
        } else if let functionCallExprSyntax: FunctionCallExprSyntax = expr.as(FunctionCallExprSyntax.self) {
            return functionCallExprSyntax.arguments.flatMap { self.extractPatternNames(fromExpr: $0.expression) }
        } else if let tupleExprSyntax: TupleExprSyntax = expr.as(TupleExprSyntax.self) {
            return tupleExprSyntax.elements.flatMap { self.extractPatternNames(fromExpr: $0.expression) }
        } else if let seqExprSyntax: SequenceExprSyntax = expr.as(SequenceExprSyntax.self) {
            return seqExprSyntax.elements.flatMap { self.extractPatternNames(fromExpr: $0) }
        }

        return []
    }
    
    func index(_ sourceKit: SourceKit, _ compilerArguments: SKRequestArray) {
        let req: SKRequestDictionary = SKRequestDictionary(sourcekitd: sourceKit)
        req[sourceKit.keys.request] = sourceKit.requests.indexsource
        req[sourceKit.keys.sourcefile] = self.sourceFile.path
        req[sourceKit.keys.compilerargs] = compilerArguments
        
        do {
            let resp = try sourceKit.sendSync(req)
            IndexStore.indexStore.set(resp: resp, toFile: self.sourceFile)
            
            resp.recurseEntities { (dict: SKResponseDictionary) in
                guard let usr: String = dict[sourceKit.keys.usr] else {
                    return
                }
                
                IndexStore.indexStore.set(resp: dict, toUSR: usr)
                
                let receiver: String? = dict[sourceKit.keys.receiver]
                guard receiver == nil else {
                    return
                }
                
                if let entryKind: SKUID = dict[sourceKit.keys.kind],
                   entryKind.declType() != nil {
                    IndexStore.indexStore.set(usr: usr, toFile: self.sourceFile)
                }
            }
            
            resp.recurseEntities { (dict: SKResponseDictionary) in
                
                guard let entryKind: SKUID = dict[sourceKit.keys.kind],
                      entryKind.declType() != nil || entryKind.refType() != nil else {
                    return
                }
                
                if let line: Int = dict[sourceKit.keys.line],
                   let col: Int = dict[sourceKit.keys.column] {
                    IndexStore.indexStore.set(line: line, col: col, ref: dict, toFile: self.sourceFile)
                }
            }
        } catch let error {
            print(error)
        }
    }
    
    func relate(_ sourceKit: SourceKit) {
        guard let resp: SKResponseDictionary = IndexStore.indexStore.getResponse(forFile: self.sourceFile) else {
            return
        }
        
        resp.recurseEntities { (dict: SKResponseDictionary) in
            
            guard let entryKind: SKUID = dict[sourceKit.keys.kind],
                  entryKind.declType() != nil || entryKind.refType() != nil else {
                return
            }
            
            if let kind: SourceKit.DeclarationType = entryKind.declType() {
                switch kind {
                case .object, .protocol, .enum: do {
                    if let name: String = dict[sourceKit.keys.name],
                       let clsSymbol: SPSwiftSourceClassSymbol = self.topScope.findSymbolInCurrentScope(name) as? SPSwiftSourceClassSymbol {
                        clsSymbol.symbolUSR = dict[sourceKit.keys.usr]
                    }
                }
                    break
                case .property: do {
                    guard let name: String = dict[sourceKit.keys.name] else { break }
                    
                    var varSymbol: SPSwiftSourceVariableSymbol?
                    if let parentName: String = dict.parent[sourceKit.keys.name],
                       let parentSymbol: SPSwiftSourceClassSymbol = self.topScope.findSymbolInCurrentScope(parentName) as? SPSwiftSourceClassSymbol {
                        for child in parentSymbol.children {
                            if child.originalSymbolName == name && child.nodeKind == .variable {
                                varSymbol = child as? SPSwiftSourceVariableSymbol
                                break
                            }
                        }
                    } else {
                        if let line: Int = dict[sourceKit.keys.line],
                           let col: Int = dict[sourceKit.keys.column],
                           let symbols: [SPSwiftSourceSymbol] = IndexStore.indexStore.getSymbol(line: line, col: col, inFile: self.sourceFile) {
                            for symbol in symbols {
                                if symbol.originalSymbolName == name && symbol.nodeKind == .variable {
                                    varSymbol = symbol as? SPSwiftSourceVariableSymbol
                                    break
                                }
                            }
                        }
                    }
                    
                    guard let varSymbol else { break }
                    varSymbol.symbolUSR = dict[sourceKit.keys.usr]
                    
                    if !self.inheritedFromAnyExternal(sourceKit, dict) {
                        varSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName(varSymbol.originalSymbolName)
                    }
                }
                    break
                case .method: do {
                    guard let fullName: String = dict[sourceKit.keys.name],
                          let line: Int = dict[sourceKit.keys.line],
                          let column: Int = dict[sourceKit.keys.column] else {
                        break
                    }
                    
                    var funcSymbol: SPSwiftSourceFunctionSymbol?
                    if let parentName: String = dict.parent[sourceKit.keys.name],
                       let parentSymbol: SPSwiftSourceClassSymbol = self.topScope.findSymbolInCurrentScope(parentName) as?
                        SPSwiftSourceClassSymbol {
                        for child in parentSymbol.children {
                            guard let fSymbol: SPSwiftSourceFunctionSymbol = child as? SPSwiftSourceFunctionSymbol else {
                                continue
                            }
                            
                            if fSymbol.signature == fullName,
                                child.nodeKind == .function,
                                fSymbol.sourceLocation.line == line,
                                fSymbol.sourceLocation.column == column
                            {
                                funcSymbol = fSymbol
                                break
                            }
                        }
                    } else {
                        if let symbols: [SPSwiftSourceSymbol] = IndexStore.indexStore.getSymbol(line: line, col: column, inFile: self.sourceFile) {
                            for symbol in symbols {
                                guard let symbol: SPSwiftSourceFunctionSymbol = symbol as? SPSwiftSourceFunctionSymbol else {
                                    continue
                                }
                                
                                if symbol.signature == fullName && symbol.nodeKind == .function {
                                    funcSymbol = symbol
                                    break
                                }
                            }
                        }
                    }
                    
                    guard let funcSymbol else { break }
                    funcSymbol.symbolUSR = dict[sourceKit.keys.usr]
                    
                    if !self.inheritedFromAnyExternal(sourceKit, dict) {
                        funcSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName(funcSymbol.originalSymbolName)
                        for (index, label) in funcSymbol.labels.enumerated() {
                            let confusedLabel: String = ConfuseHelper.confusedSymbolName(label)
                            funcSymbol.confusedLabels[index] = confusedLabel
                        }
                        
                        for (index, argument) in funcSymbol.arguments.enumerated() {
                            if argument.confusedSymbolName == nil {
                                funcSymbol.arguments[index].confusedSymbolName = funcSymbol.confusedLabels[index]
                            }
                        }
                    }
                }
                    break
                case .enumelement: do {
                    guard let fullName: String = dict[sourceKit.keys.name],
                          let parentName: String = dict.parent[sourceKit.keys.name],
                          let parentSymbol: SPSwiftSourceClassSymbol = self.topScope.findSymbolInCurrentScope(parentName) as?
                            SPSwiftSourceClassSymbol else {
                        break
                    }
                    
                    for child in parentSymbol.children {
                        if child.nodeKind == .enumCase,
                           let enumCaseSymbol: SPSwiftSourceEnumCaseSymbol = child as? SPSwiftSourceEnumCaseSymbol,
                           enumCaseSymbol.signature == fullName {
                            child.symbolUSR = dict[sourceKit.keys.usr]
                            break
                        }
                    }
                }
                    break
                }
            }
        }
    }
    
    private func inheritedFromAnyExternal(_ sourceKit: SourceKit, _ dict: SKResponseDictionary) -> Bool {
        guard let kindID: SKUID = dict[sourceKit.keys.kind] else {
            return false
        }
        
        let type = kindID.declarationType()
        guard type == .property || type == .method,
              let usr: String = dict[sourceKit.keys.usr],
              IndexStore.indexStore.getFile(usr: usr) != nil else {
            return false
        }
        
        var isReference: Bool = false
        dict.recurse(uid: sourceKit.keys.related) { [weak self] dict in
            guard isReference == false,
                  let usr: String = dict[sourceKit.keys.usr] else {
                return
            }
            
            guard let file: File = IndexStore.indexStore.getFile(usr: usr),
                  self?.module.sourceFiles.contains(file) == true else {
                isReference = true
                return
            }
            
            if let relatedDict: SKResponseDictionary = IndexStore.indexStore.getResponse(usr: usr) {
                isReference = (self?.inheritedFromAnyExternal(sourceKit, relatedDict) ?? false)
            }
        }
        
        return isReference
    }
}
