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
        
        if !self.parentStack.isEmpty {
            self.parentStack.last?.children.append(symbol)
        }
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
        let symbol: SPSwiftSourceClassSymbol = SPSwiftSourceClassSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope)
        symbol.originalSymbolName = node.name.text
        
        if !self.parentStack.isEmpty {
            self.parentStack.last?.children.append(symbol)
        }
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
        let symbol: SPSwiftSourceClassSymbol = SPSwiftSourceClassSymbol(sourceFile: self.sourceFile, symbolScope: node.symbolScope)
        symbol.originalSymbolName = node.name.text
        
        if !self.parentStack.isEmpty {
            self.parentStack.last?.children.append(symbol)
        }
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
    
    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SPSwiftSourceFunctionSymbol = SPSwiftSourceFunctionSymbol(sourceFile: self.sourceFile, funcName: node.initKeyword.text, symbolScope: node.symbolScope)
        
        symbol.originalSymbolName = ConfuseHelper.generateSignature(funcName: node.initKeyword.text, parameters: node.signature.parameterClause.parameters)
        
        if !self.parentStack.isEmpty {
            self.parentStack.last?.children.append(symbol)
        }
        
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
                if !self.parentStack.isEmpty {
                    self.parentStack.last?.children.append($0)
                }
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
            if !self.parentStack.isEmpty {
                self.parentStack.last?.children.append(symbol)
            }
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
        
        if let idPattern: IdentifierPatternSyntax = node.pattern.as(IdentifierPatternSyntax.self) {
            let varSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: .local)
            varSymbol.originalSymbolName = idPattern.identifier.text
            varSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName(idPattern.identifier.text)
            
            self.currentScope.pushSymbol(varSymbol)
        }
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: ForStmtSyntax) {
        self.currentScope = self.currentScope.popScope(false)
    }
    
    override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        self.currentScope = self.currentScope.pushScope(true)
        return super.visit(node)
    }
    
    override func visitPost(_ node: WhileStmtSyntax) {
        self.currentScope = self.currentScope.popScope(false)
    }
    
    override func visit(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind {
        self.currentScope = self.currentScope.pushScope(true)
        
        node.conditions.forEach { condition in
            if let optBindCondSyntax: OptionalBindingConditionSyntax = condition.condition.as(OptionalBindingConditionSyntax.self),
               let _ = optBindCondSyntax.initializer,
               let idPattern: IdentifierPatternSyntax = optBindCondSyntax.pattern.as(IdentifierPatternSyntax.self) {
                let varSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: .local)
                varSymbol.originalSymbolName = idPattern.identifier.text
                varSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName(idPattern.identifier.text)
                
                self.currentScope.pushSymbol(varSymbol)
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
                if let _ = condition.initializer,
                   let idPattern: IdentifierPatternSyntax = condition.pattern.as(IdentifierPatternSyntax.self) {
                    let paramSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile, symbolScope: .local)
                    paramSymbol.originalSymbolName = idPattern.identifier.text
                    paramSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName(idPattern.identifier.text)
                    
                    self.currentScope.pushSymbol(paramSymbol)
                }
            }
        }
        
        self.currentScope = self.currentScope.pushScope(true)
        return super.visit(node)
    }
    
    override func visitPost(_ node: GuardStmtSyntax) {
        self.currentScope = self.currentScope.popScope(false)
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
        }
        
        return []
    }
    
    func index(_ sourceKit: SourceKit, _ compilerArguments: SKRequestArray) {
//        let req: SKRequestDictionary = SKRequestDictionary(sourcekitd: sourceKit)
//        req[sourceKit.keys.request] = sourceKit.requests.indexsource
//        req[sourceKit.keys.sourcefile] = self.sourceFile.path
//        req[sourceKit.keys.compilerargs] = compilerArguments
//        
//        guard let response = try? sourceKit.sendSync(req) else {
//            return
//        }
        
    }
}
