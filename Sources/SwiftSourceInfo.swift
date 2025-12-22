//
//  SwiftSourceInfo.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2025/12/20.
//
import Foundation

class SwiftSourceInfo: @unchecked Sendable {
    
    private lazy var sourceStack: [SwiftSourceBaseInfo] = [SwiftSourceBaseInfo]()
    
    lazy var sourceInfoList: [String: SwiftSourceBaseInfo] = [String: SwiftSourceBaseInfo]()
    
    lazy var identifierMap: [String: String] = [String: String]()
    lazy var confusedMap: [String: String] = [String: String]()
    
    init() {
        
    }
    
    func appendSourceInfo(_ sourceInfo: SwiftSourceBaseInfo) {
        
        if self.sourceStack.isEmpty {
            self.sourceInfoList[sourceInfo.name] = sourceInfo
        } else {
            if sourceInfo.sourceType == .Class, let classInfo: SwiftSourceClassInfo = sourceInfo as? SwiftSourceClassInfo {
                classInfo.parent = self.sourceStack.last
                self.sourceStack.last?.children.append(classInfo)
            } else if sourceInfo.sourceType == .Function, let functionInfo: SwiftSourceFunctionInfo = sourceInfo as? SwiftSourceFunctionInfo {
                functionInfo.parent = self.sourceStack.last
                self.sourceStack.last?.children.append(functionInfo)
            } else if sourceInfo.sourceType == .Property, let variableInfo: SwiftSourceVariableInfo = sourceInfo as? SwiftSourceVariableInfo {
                variableInfo.parent = self.sourceStack.last
                self.sourceStack.last?.children.append(variableInfo)
            }
        }
        
        self.sourceStack.append(sourceInfo)
    }
    
    func popSourceInfo() {
        if self.sourceStack.isEmpty {
            return
        }
        
        self.sourceStack.removeLast()
    }
}
