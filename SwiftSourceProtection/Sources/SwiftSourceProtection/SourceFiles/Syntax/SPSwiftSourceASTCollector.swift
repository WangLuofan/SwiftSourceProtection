//
//  SPSwiftSourceASTCollector.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/8.
//

import SwiftSyntax

class SPSwiftSourceASTCollector: SyntaxVisitor {
    private var sourceTree: SourceFileSyntax
    private var sourceFile: File
    private var topScope: SPSwiftSourceScope = SPSwiftSourceScope()
    private lazy var currentScope: SPSwiftSourceScope = self.topScope
    
    private var parentStack: [SPSwiftSourceClassSymbol] = []
    
    init(sourceTree: SourceFileSyntax, sourceFile: File) {
        self.sourceTree = sourceTree
        self.sourceFile = sourceFile
        
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SPSwiftSourceClassSymbol = SPSwiftSourceClassSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope)
        symbol.originalSymbolName = node.name.text
        
        self.parentStack.last?.children.append(symbol)
        self.parentStack.append(symbol)
        
        ConfuseHelper.confuseSymbol(symbol)
        
        self.currentScope.pushSymbol(symbol)
        self.currentScope = self.currentScope.pushScope(true)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: ClassDeclSyntax) {
        if !self.parentStack.isEmpty {
            self.parentStack.removeLast()
        }
        
        self.currentScope = self.currentScope.popScope(false)
    }
    
    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SPSwiftSourceClassSymbol = SPSwiftSourceClassSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope, nodeKind: .struct)
        symbol.originalSymbolName = node.name.text
        
        self.parentStack.last?.children.append(symbol)
        self.parentStack.append(symbol)
        
        ConfuseHelper.confuseSymbol(symbol)
        
        self.currentScope.pushSymbol(symbol)
        self.currentScope = self.currentScope.pushScope(true)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: StructDeclSyntax) {
        if !self.parentStack.isEmpty {
            self.parentStack.removeLast()
        }
        
        self.currentScope = self.currentScope.popScope(false)
    }
    
    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SPSwiftSourceClassSymbol = SPSwiftSourceClassSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope, nodeKind: .protocol)
        symbol.originalSymbolName = node.name.text
        
        self.parentStack.last?.children.append(symbol)
        self.parentStack.append(symbol)
        
        ConfuseHelper.confuseSymbol(symbol)
        
        self.currentScope.pushSymbol(symbol)
        self.currentScope = self.currentScope.pushScope(true)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: ProtocolDeclSyntax) {
        if !self.parentStack.isEmpty {
            self.parentStack.removeLast()
        }
        
        self.currentScope = self.currentScope.popScope(false)
    }
    
    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SPSwiftSourceClassSymbol = SPSwiftSourceClassSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope, nodeKind: .enum)
        symbol.originalSymbolName = node.name.text
        
        self.parentStack.last?.children.append(symbol)
        self.parentStack.append(symbol)
        
        ConfuseHelper.confuseSymbol(symbol)
        
        self.currentScope.pushSymbol(symbol)
        self.currentScope = self.currentScope.pushScope(true)
        return super.visit(node)
    }
    
    override func visitPost(_ node: EnumDeclSyntax) {
        if !self.parentStack.isEmpty {
            self.parentStack.removeLast()
        }
        
        self.currentScope = self.currentScope.popScope(false)
    }
    
    override func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
        node.elements.forEach {
            let symbol: SPSwiftSourceEnumCaseSymbol = SPSwiftSourceEnumCaseSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope)
            
            symbol.originalSymbolName = $0.name.text
            symbol.confusedSymbolName = ConfuseHelper.confusedSymbolName($0.name.text)

            if let paramClause: EnumCaseParameterClauseSyntax = $0.parameterClause {
                paramClause.parameters.forEach {
                    if let idTypeSyntax: IdentifierTypeSyntax = $0.type.as(IdentifierTypeSyntax.self) {
                        symbol.relatedType.append(idTypeSyntax.name.text)
                    }
                }
            }
            
            self.currentScope.pushSymbol(symbol)
            
            self.parentStack.last?.children.append(symbol)
        }
        
        return super.visit(node)
    }
    
    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SPSwiftSourceFunctionSymbol = SPSwiftSourceFunctionSymbol(sourceFile: self.sourceFile, funcName: node.initKeyword.text, symbolScope: node.symbolScope)
        
        symbol.originalSymbolName = ConfuseHelper.generateSignature(funcName: node.initKeyword.text, parameters: node.signature.parameterClause.parameters)
        
        self.parentStack.last?.children.append(symbol)
        
        self.currentScope.pushSymbol(symbol)
        self.currentScope = self.currentScope.pushScope(true)
        return super.visit(node)
    }
    
    override func visitPost(_ node: InitializerDeclSyntax) {
        self.currentScope = self.currentScope.popScope(false)
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        self.currentScope = self.currentScope.pushScope(true)
        return super.visit(node)
    }
    
    override func visitPost(_ node: ExtensionDeclSyntax) {
        self.currentScope = self.currentScope.popScope(false)
    }
    
    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        let symbols: [SPSwiftSourceVariableSymbol] = node.bindings.flatMap {
            self.extractPatternNames($0.pattern).map {
                let symbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope)
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
        
        self.currentScope = self.currentScope.pushScope(true)
        return super.visit(node)
    }
    
    override func visitPost(_ node: VariableDeclSyntax) {
        self.currentScope = self.currentScope.popScope(false)
    }
    
    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        self.currentScope = self.currentScope.pushScope(true)
        return super.visit(node)
    }
    
    override func visitPost(_ node: ClosureExprSyntax) {
        self.currentScope = self.currentScope.popScope(false)
    }
    
    override func visit(_ node: ClosureShorthandParameterSyntax) -> SyntaxVisitorContinueKind {
        
        let paramSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: .local)
        paramSymbol.originalSymbolName = node.name.text
        paramSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName(node.name.text)
        self.currentScope.pushSymbol(paramSymbol)
        
        return super.visit(node)
    }
    
    override func visit(_ node: ClosureParameterSyntax) -> SyntaxVisitorContinueKind {
        
        let paramSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: .local)
        paramSymbol.originalSymbolName = node.firstName.text
        paramSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName(node.firstName.text)
        self.currentScope.pushSymbol(paramSymbol)
        
        return super.visit(node)
    }
    
    override func visit(_ node: ClosureCaptureSyntax) -> SyntaxVisitorContinueKind {
        if !node.name.text.isSwiftKeyWord {
            let varSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope)
            varSymbol.originalSymbolName = node.name.text
            varSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName(node.name.text)
            
            self.currentScope.pushSymbol(varSymbol)
        }
        
        return super.visit(node)
    }
    
    override func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
        let paramSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: .local)
        paramSymbol.originalSymbolName = node.firstName.text
        if let secondName: TokenSyntax = node.secondName {
            paramSymbol.originalSymbolName = secondName.text
            paramSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName(secondName.text)
        }
        
        self.currentScope.pushSymbol(paramSymbol)
        return super.visit(node)
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SPSwiftSourceFunctionSymbol = SPSwiftSourceFunctionSymbol(sourceFile: self.sourceFile, funcName: node.name.text, symbolScope: node.symbolScope)
        symbol.originalSymbolName = ConfuseHelper.generateSignature(funcName: node.name.text, parameters: node.signature.parameterClause.parameters)

        node.signature.parameterClause.parameters.forEach { parameter in
            symbol.labels.append(parameter.firstName.text)
        }
        
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
        self.currentScope = self.currentScope.pushScope(true)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: FunctionDeclSyntax) {
        self.currentScope = self.currentScope.popScope(false)
    }
    
    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        self.currentScope = self.currentScope.pushScope(true)
        
        let symbols: [String] = self.extractPatternNames(node.pattern)
        symbols.forEach {
            let varSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: .local)
            varSymbol.originalSymbolName = $0
            varSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName($0)
            
            self.currentScope.pushSymbol(varSymbol)
        }
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: ForStmtSyntax) {
        self.currentScope = self.currentScope.popScope(false)
    }
    
    override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        self.currentScope = self.currentScope.pushScope(true)
        
        node.conditions.forEach {
            if let optBindCondSyntax: OptionalBindingConditionSyntax = $0.condition.as(OptionalBindingConditionSyntax.self),
               let _ = optBindCondSyntax.initializer {
                let symbols: [String] = self.extractPatternNames(optBindCondSyntax.pattern)
                symbols.forEach {
                    let varSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope)
                    varSymbol.originalSymbolName = $0
                    varSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName($0)
                    
                    self.currentScope.pushSymbol(varSymbol)
               }
            } else if let matchPatternCondSyntax: MatchingPatternConditionSyntax = $0.condition.as(MatchingPatternConditionSyntax.self) {
                let symbols: [String] = self.extractPatternNames(matchPatternCondSyntax.pattern)
                symbols.forEach {
                    let varSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope)
                    varSymbol.originalSymbolName = $0
                    varSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName($0)
                    
                    self.currentScope.pushSymbol(varSymbol)
                }
            }
        }
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: WhileStmtSyntax) {
        self.currentScope = self.currentScope.popScope(false)
    }
    
    override func visit(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind {
        self.currentScope = self.currentScope.pushScope(true)
        
        node.conditions.forEach { condition in
            if let optBindCondSyntax: OptionalBindingConditionSyntax = condition.condition.as(OptionalBindingConditionSyntax.self),
               let _ = optBindCondSyntax.initializer {
                let symbols: [String] = self.extractPatternNames(optBindCondSyntax.pattern)
                symbols.forEach {
                    let varSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: .local)
                    varSymbol.originalSymbolName = $0
                    varSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName($0)
                    
                    self.currentScope.pushSymbol(varSymbol)
                }
            }  else if let matchPatternCondSyntax: MatchingPatternConditionSyntax = condition.condition.as(MatchingPatternConditionSyntax.self) {
                let symbols: [String] = self.extractPatternNames(matchPatternCondSyntax.pattern)
                symbols.forEach {
                    let varSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope)
                    varSymbol.originalSymbolName = $0
                    varSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName($0)
                    
                    self.currentScope.pushSymbol(varSymbol)
                }
            }
        }
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: IfExprSyntax) {
        self.currentScope = self.currentScope.popScope(false)
    }
    
    override func visit(_ node: SwitchExprSyntax) -> SyntaxVisitorContinueKind {
        self.currentScope = self.currentScope.pushScope(true)
        return super.visit(node)
    }
    
    override func visitPost(_ node: SwitchExprSyntax) {
        self.currentScope = self.currentScope.popScope(false)
    }
    
    override func visit(_ node: SwitchCaseSyntax) -> SyntaxVisitorContinueKind {
        self.currentScope = self.currentScope.pushScope(true)
        return super.visit(node)
    }
    
    override func visitPost(_ node: SwitchCaseSyntax) {
        self.currentScope = self.currentScope.popScope(false)
    }
    
    override func visit(_ node: SwitchCaseItemSyntax) -> SyntaxVisitorContinueKind {
        let symbols: [String] = self.extractPatternNames(node.pattern)
        symbols.forEach {
            let varSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope)
            varSymbol.originalSymbolName = $0
            varSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName($0)
            self.currentScope.pushSymbol(varSymbol)
        }
        return super.visit(node)
    }
    
    override func visit(_ node: SwitchDefaultLabelSyntax) -> SyntaxVisitorContinueKind {
        self.currentScope = self.currentScope.pushScope(true)
        return super.visit(node)
    }
    
    override func visitPost(_ node: SwitchDefaultLabelSyntax) {
        self.currentScope = self.currentScope.popScope(false)
    }
    
    override func visit(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
        node.conditions.forEach { condition in
            if let condition: OptionalBindingConditionSyntax = condition.condition.as(OptionalBindingConditionSyntax.self) {
                if let _ = condition.initializer {
                    let symbols: [String] = self.extractPatternNames(condition.pattern)
                    symbols.forEach {
                        let paramSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: .local)
                        paramSymbol.originalSymbolName = $0
                        paramSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName($0)
                        
                        self.currentScope.pushSymbol(paramSymbol)
                    }
                }
            } else if let matchPatternCondSyntax: MatchingPatternConditionSyntax = condition.condition.as(MatchingPatternConditionSyntax.self) {
                let symbols: [String] = self.extractPatternNames(matchPatternCondSyntax.pattern)
                symbols.forEach {
                    let varSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope)
                    varSymbol.originalSymbolName = $0
                    varSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName($0)
                    
                    self.currentScope.pushSymbol(varSymbol)
                }
            }
        }
        
        self.currentScope = self.currentScope.pushScope(true)
        return super.visit(node)
    }
    
    override func visitPost(_ node: GuardStmtSyntax) {
        self.currentScope = self.currentScope.popScope(false)
    }
    
    override func visit(_ node: CatchClauseSyntax) -> SyntaxVisitorContinueKind {
        self.currentScope = self.currentScope.pushScope(true)
        return super.visit(node)
    }
    
    override func visitPost(_ node: CatchClauseSyntax) {
        self.currentScope = self.currentScope.popScope(false)
    }
    
    override func visit(_ node: CatchItemSyntax) -> SyntaxVisitorContinueKind {
        if let pattern: PatternSyntax = node.pattern {
            let symbols: [String] = self.extractPatternNames(pattern)
            symbols.forEach {
                let varSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope)
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

        // MemberAccessExpr（`.second`）、字面量等没有绑定，忽略
        return []
    }
    
    func index(_ sourceKit: SourceKit, _ compilerArguments: SKRequestArray, _ scope: SPSwiftSourceScope) {
        let req: SKRequestDictionary = SKRequestDictionary(sourcekitd: sourceKit)
        req[sourceKit.keys.request] = sourceKit.requests.indexsource
        req[sourceKit.keys.sourcefile] = self.sourceFile.path
        req[sourceKit.keys.compilerargs] = compilerArguments
        
        do {
            let resp = try sourceKit.sendSync(req)
            resp.recurseEntities { dict in
                
            }
        } catch let error {
            print(error)
        }
    }
}
