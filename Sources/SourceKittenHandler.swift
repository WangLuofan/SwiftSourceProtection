//
//  SourceKittenHandler.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2026/3/4.
//

import SourceKittenFramework

class SourceKittenHandler {
    private var projectPath: String
    private var projectTarget: String
    private var projectModule: Module?
    private var compilerArguments: [String]?
    
    init?(projectPath: String, projectTarget: String) {
        self.projectPath = projectPath
        self.projectTarget = projectTarget

        if projectPath.hasSuffix("xcworkspace") {
            self.projectModule = Module.init(xcodeBuildArguments: [
                "-workspace", projectPath,
                "-scheme", projectTarget
            ], name: projectTarget)
        } else if projectPath.hasSuffix("xcodeproj") {
            self.projectModule = Module.init(xcodeBuildArguments: [
                "-project", projectPath,
                "-target", projectTarget
            ], name: projectTarget)
        }

        guard self.projectModule != nil else {
            return nil
        }
        
        self.compilerArguments = self.projectModule?.compilerArguments
    }
}
