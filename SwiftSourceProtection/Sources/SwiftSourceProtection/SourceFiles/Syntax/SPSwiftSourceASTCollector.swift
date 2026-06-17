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
    
    init(sourceTree: SourceFileSyntax, sourceFile: File) {
        self.sourceTree = sourceTree
        self.sourceFile = sourceFile
        
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SPSwiftSourceClassSymbol = SPSwiftSourceClassSymbol(sourceFile: self.sourceFile)
        symbol.ASTNode = node
        symbol.originalSymbolName = node.name.text
        
        ConfuseHelper.confuseSymbol(symbol)
        
        SPSwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(symbol)
        SPSwiftSourceScopeManager.sharedManager.pushScope()
        
        return super.visit(node)
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        SPSwiftSourceScopeManager.sharedManager.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: ExtensionDeclSyntax) {
        SPSwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visitPost(_ node: ClassDeclSyntax) {
        SPSwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile)
        symbol.ASTNode = node
        symbol.variableKind = self.variableKind(of: node)
        
        node.bindings.forEach { binding in
            if let idPatternSyntax: IdentifierPatternSyntax = binding.pattern.as(IdentifierPatternSyntax.self) {
                symbol.originalSymbolName = idPatternSyntax.identifier.text
            }
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
        
        ConfuseHelper.confuseSymbol(symbol)
        
        SPSwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(symbol)
        SPSwiftSourceScopeManager.sharedManager.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: VariableDeclSyntax) {
        SPSwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        SPSwiftSourceScopeManager.sharedManager.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: ClosureExprSyntax) {
        SPSwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: ClosureShorthandParameterSyntax) -> SyntaxVisitorContinueKind {
        
        let paramSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile)
        paramSymbol.originalSymbolName = node.name.text
        paramSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName(node.name.text)
        SPSwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(paramSymbol)
        
        return super.visit(node)
    }
    
    override func visit(_ node: ClosureParameterSyntax) -> SyntaxVisitorContinueKind {
        
        let paramSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile)
        paramSymbol.originalSymbolName = node.firstName.text
        paramSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName(node.firstName.text)
        SPSwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(paramSymbol)
        
        return super.visit(node)
    }
    
    override func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
        let paramSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile)
        paramSymbol.ASTNode =  node.firstName
        paramSymbol.originalSymbolName = node.firstName.text
        if let secondName: TokenSyntax = node.secondName {
            paramSymbol.originalSymbolName = secondName.text
            paramSymbol.ASTNode = secondName
            paramSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName(secondName.text)
        }
        paramSymbol.variableKind = .local
        
        SPSwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(paramSymbol)
        return super.visit(node)
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SPSwiftSourceFunctionSymbol = SPSwiftSourceFunctionSymbol(sourceFile: self.sourceFile, funcName: node.name.text)
        
        symbol.ASTNode = node
        symbol.variableKind = self.variableKind(of: node)
        symbol.functionName = node.name.text
        symbol.originalSymbolName = ConfuseHelper.generateFunctionSignature(node)

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
        
        ConfuseHelper.confuseSymbol(symbol)
        
        SPSwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(symbol)
        SPSwiftSourceScopeManager.sharedManager.pushScope()
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: FunctionDeclSyntax) {
        SPSwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        SPSwiftSourceScopeManager.sharedManager.pushScope()
        
        if let idPattern: IdentifierPatternSyntax = node.pattern.as(IdentifierPatternSyntax.self) {
            let varSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile)
            varSymbol.originalSymbolName = idPattern.identifier.text
            varSymbol.variableKind = .local
            varSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName(idPattern.identifier.text)
            
            SPSwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(varSymbol)
        }
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: ForStmtSyntax) {
        SPSwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        SPSwiftSourceScopeManager.sharedManager.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: WhileStmtSyntax) {
        SPSwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind {
        SPSwiftSourceScopeManager.sharedManager.pushScope()
        
        node.conditions.forEach { condition in
            if let optBindCondSyntax: OptionalBindingConditionSyntax = condition.condition.as(OptionalBindingConditionSyntax.self),
               let _ = optBindCondSyntax.initializer,
               let idPattern: IdentifierPatternSyntax = optBindCondSyntax.pattern.as(IdentifierPatternSyntax.self) {
                let varSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile)
                varSymbol.ASTNode = idPattern
                varSymbol.originalSymbolName = idPattern.identifier.text
                varSymbol.variableKind = .local
                varSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName(idPattern.identifier.text)
                
                SPSwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(varSymbol)
            }
        }
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: IfExprSyntax) {
        SPSwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: SwitchExprSyntax) -> SyntaxVisitorContinueKind {
        SPSwiftSourceScopeManager.sharedManager.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: SwitchExprSyntax) {
        SPSwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: SwitchCaseSyntax) -> SyntaxVisitorContinueKind {
        SPSwiftSourceScopeManager.sharedManager.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: SwitchCaseSyntax) {
        SPSwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: SwitchDefaultLabelSyntax) -> SyntaxVisitorContinueKind {
        SPSwiftSourceScopeManager.sharedManager.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: SwitchDefaultLabelSyntax) {
        SPSwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
        node.conditions.forEach { condition in
            if let condition: OptionalBindingConditionSyntax = condition.condition.as(OptionalBindingConditionSyntax.self) {
                if let _ = condition.initializer,
                   let idPattern: IdentifierPatternSyntax = condition.pattern.as(IdentifierPatternSyntax.self) {
                    let paramSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceVariableSymbol(sourceFile: self.sourceFile)
                    paramSymbol.variableKind = .local
                    paramSymbol.ASTNode = idPattern
                    paramSymbol.originalSymbolName = idPattern.identifier.text
                    paramSymbol.confusedSymbolName = ConfuseHelper.confusedSymbolName(idPattern.identifier.text)
                    
                    SPSwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(paramSymbol)
                }
            }
        }
        
        SPSwiftSourceScopeManager.sharedManager.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: GuardStmtSyntax) {
        SPSwiftSourceScopeManager.sharedManager.popScope()
    }
}

extension SPSwiftSourceASTCollector {
    func walk() {
        self.walk(self.sourceTree)
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

extension SPSwiftSourceASTCollector {
    func variableKind(of node: DeclSyntaxProtocol) -> SPSwiftSourceVariableKind {
        var current = node.parent

        while let syntax = current {

            if syntax.is(FunctionDeclSyntax.self) ||
               syntax.is(InitializerDeclSyntax.self) ||
               syntax.is(ClosureExprSyntax.self) {
                return .local
            }

            if syntax.is(StructDeclSyntax.self) ||
               syntax.is(ClassDeclSyntax.self) ||
               syntax.is(EnumDeclSyntax.self) ||
               syntax.is(ActorDeclSyntax.self) {
                return .member
            }

            current = syntax.parent
        }

        return .global
    }
}
