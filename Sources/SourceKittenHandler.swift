//
//  SourceKittenHandler.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2026/3/4.
//

import SourceKittenFramework
import Foundation

/// 位置信息（行号和列号）
struct SourceLocation: Hashable {
    let line: Int
    let column: Int
}

/// 类型信息
struct TypeInfo {
    let typeName: String
    let usr: String?  // Unified Symbol Resolution
}

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

    /// 获取指定文件中所有符号的类型信息
    /// - Parameter filePath: Swift 源文件路径
    /// - Returns: 位置到类型的映射表
    func getTypeInfo(for filePath: String) -> [SourceLocation: TypeInfo]? {
        guard let file = File(path: filePath) else {
            return nil
        }

        var typeMap: [SourceLocation: TypeInfo] = [:]

        // 使用 SourceKitten 的 Structure API 获取文件结构
        guard let structure = try? Structure(file: file) else {
            return nil
        }

        // 遍历结构，提取类型信息
        extractTypes(from: structure.dictionary, in: file, into: &typeMap)

        return typeMap
    }

    /// 递归提取结构中的类型信息
    private func extractTypes(from dict: [String: Any], in file: File, into typeMap: inout [SourceLocation: TypeInfo]) {
        // 提取当前节点的类型信息
        if let offset = dict["key.offset"] as? Int64,
           let _ = dict["key.length"] as? Int64,
           let typeName = dict["key.typename"] as? String {

            // 将字节偏移转换为行列号
            if let location = file.stringView.lineAndCharacter(forByteOffset: ByteCount(offset)) {
                let sourceLocation = SourceLocation(line: location.line, column: location.character)
                let usr = dict["key.usr"] as? String
                typeMap[sourceLocation] = TypeInfo(typeName: typeName, usr: usr)
            }
        }

        // 递归处理子结构
        if let substructures = dict["key.substructure"] as? [[String: Any]] {
            for substructure in substructures {
                extractTypes(from: substructure, in: file, into: &typeMap)
            }
        }
    }

    /// 获取指定位置的类型信息（使用 cursor info）
    /// - Parameters:
    ///   - filePath: 源文件路径
    ///   - line: 行号（从1开始）
    ///   - column: 列号（从1开始）
    /// - Returns: 类型名称，如果无法推导则返回 nil
    func getTypeAtLocation(filePath: String, line: Int, column: Int) -> String? {
        guard let file = File(path: filePath) else {
            return nil
        }

        guard let compilerArguments = self.compilerArguments else {
            return nil
        }

        // 找到对应行
        guard line > 0 && line <= file.lines.count else {
            return nil
        }

        let targetLine = file.lines[line - 1]

        // 计算字节偏移：行起始位置 + 列偏移
        let byteOffset = targetLine.byteRange.location + ByteCount(column - 1)

        // 使用 cursor info 获取该位置的详细信息
        let request = Request.cursorInfo(file: filePath, offset: byteOffset, arguments: compilerArguments)

        guard let response = try? request.send() else {
            return nil
        }
        
        // 提取类型名称
        return response["key.typename"] as? String
    }
}
