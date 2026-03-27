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
    nonisolated(unsafe) static let sharedHandler: SourceKittenHandler = SourceKittenHandler()
    
    private var projectPath: String = ""
    private var projectTarget: String = ""
    private var projectModule: Module?
    private var compilerArguments: [String]?
    private var initialized: Bool = false
    
    func isSourceKittenInitialized() -> Bool {
        return self.initialized
    }
    
    func initializeSourceKitten(projectPath: String, projectTarget: String) {
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
            return
        }
        
        let blockedFlags: Set<String> = [
            "-no-serialize-debugging-options",
            "-serialize-debugging-options",
        ]
        
        self.compilerArguments = self.projectModule?.compilerArguments.filter {
            !blockedFlags.contains($0)
        }
        
        self.initialized = true
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
    
    func querySymbolType(by filePath: String, byteOffset: Int) -> SwiftSymbolType {
        guard let typeName = self.getTypeName(filePath: filePath, byteOffset: byteOffset) else {
            return SwiftSymbolUnknownType()
        }
        
        return self.parseTypeString(typeName)
    }
    
    private func getTypeName(filePath: String, byteOffset: Int) -> String? {
        guard let compilerArguments else { return nil }
        let request = Request.cursorInfo(
            file: filePath,
            offset: ByteCount(byteOffset),
            arguments: compilerArguments
        )
        guard let response = try? request.send() else { return nil }
        return response["key.typename"] as? String
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
        guard let cursorInfo = getCursorInfo(filePath: filePath, line: line, column: column) else {
            return nil
        }

        // 提取类型名称
        return cursorInfo["key.typename"] as? String
    }

    /// 获取指定位置的完整 cursor info（用于详细分析）
    /// - Parameters:
    ///   - filePath: 源文件路径
    ///   - line: 行号（从1开始）
    ///   - column: 列号（从1开始）
    /// - Returns: 完整的 cursor info 字典
    func getCursorInfo(filePath: String, line: Int, column: Int) -> [String: Any]? {
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

        return response
    }
    
    // MARK: - 通过 USR 解析模块名
    // Swift USR 格式: s:<mangling>
    //   标准库缩写: s:S<X>... (如 SH=Hashable, SQ=Equatable, SS=String, Si=Int)
    //   普通模块:  s:<length><name>... (如 8TestFile16InternalProtocol...)
    //   ObjC:     c:... / objc(cs)...
    func extractModuleFromUSR(_ usr: String) -> String? {
        if usr.hasPrefix("c:") || usr.hasPrefix("objc(") {
            return "(ObjC)"
        }
        guard usr.hasPrefix("s:") else { return nil }
        let rest = usr.dropFirst(2)
        
        // 标准库缩写: S 后跟大写字母（SH / SQ / SS / Si 等）
        if rest.hasPrefix("S"), let second = rest.dropFirst().first, second.isLetter {
            return "Swift"
        }
        
        // 普通模块: <length><name>
        var digits = ""
        for ch in rest {
            if ch.isNumber { digits.append(ch) } else { break }
        }
        if let len = Int(digits), len > 0 {
            let nameStart = rest.index(rest.startIndex, offsetBy: digits.count)
            if let nameEnd = rest.index(nameStart, offsetBy: len, limitedBy: rest.endIndex) {
                return String(rest[nameStart..<nameEnd])
            }
        }
        return nil
    }
}

// MARK: - SourceKit key.typename 字符串解析
extension SourceKittenHandler {
    
    /// 将 SourceKit 返回的 key.typename 字符串解析为 SwiftSymbolType，
    /// 与 detectTypeSyntax(_:) 对应，但输入来源是字符串而非 AST 节点。
    private func parseTypeString(_ typeName: String) -> SwiftSymbolType {
        let s = typeName.trimmingCharacters(in: .whitespaces)
        guard !s.isEmpty else { return SwiftSymbolUnknownType() }
        
        // Void / 空 tuple
        if s == "Void" || s == "()" {
            return SwiftSymbolSingleType.voidType
        }
        
        // Any / AnyObject
        if s == "Any" || s == "AnyObject" {
            return SwiftSymbolAnyType()
        }
        
        // some T / any T
        if s.hasPrefix("some ") {
            return SwiftSomeAnyType(constraints: parseTypeString(String(s.dropFirst(5))))
        }
        if s.hasPrefix("any ") {
            return SwiftSomeAnyType(constraints: parseTypeString(String(s.dropFirst(4))))
        }
        
        // @escaping / @autoclosure / @Sendable 等 attribute — 对应 AttributedTypeSyntax
        for prefix in ["@escaping ", "@autoclosure ", "@Sendable ", "@noescape "] {
            if s.hasPrefix(prefix) {
                return parseTypeString(String(s.dropFirst(prefix.count)))
            }
        }
        
        // Optional T? / ImplicitlyUnwrapped T! — 对应 OptionalTypeSyntax
        // 先于括号/箭头处理，确保 ((Int)->String)? 能正确剥离外层 ?
        if s.hasSuffix("?") { return parseTypeString(String(s.dropLast())) }
        if s.hasSuffix("!") { return parseTypeString(String(s.dropLast())) }
        
        // 函数类型：顶层含 -> — 对应 FunctionTypeSyntax
        // e.g. "(Int) -> String"  "(Int) throws -> Bool"  "() async -> Void"
        if let arrowRange = typeStringTopLevelArrow(in: s) {
            var paramsPart = String(s[..<arrowRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            let returnPart = String(s[arrowRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            
            // 剥离 throws / async / rethrows 等 effect 修饰词
            for effect in [" async throws", " throws async", " async", " throws", " rethrows"] {
                if paramsPart.hasSuffix(effect) {
                    paramsPart = String(paramsPart.dropLast(effect.count))
                    break
                }
            }
            
            let funcType = SwiftFunctionType()
            funcType.returnType = parseTypeString(returnPart)
            
            if paramsPart.hasPrefix("(") && paramsPart.hasSuffix(")") {
                let inner = String(paramsPart.dropFirst().dropLast())
                for param in typeStringSplitTopLevel(inner, by: ",") {
                    let trimmed = param.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { continue }
                    funcType.elements.append(parseTypeString(typeStringStripParamModifiers(trimmed)))
                }
            }
            return funcType
        }
        
        // Array / Dictionary: [...] — 对应 ArrayTypeSyntax / DictionaryTypeSyntax
        // SourceKit dictionary 格式: [Key : Value]（冒号两边有空格）
        if s.hasPrefix("[") && s.hasSuffix("]") {
            let inner = String(s.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
            let parts = typeStringSplitTopLevel(inner, by: ":")
            if parts.count == 2 {
                return SwiftSymbolDictionaryType(
                    keyType: parseTypeString(parts[0].trimmingCharacters(in: .whitespaces)),
                    valueType: parseTypeString(parts[1].trimmingCharacters(in: .whitespaces))
                )
            }
            return SwiftSymbolArrayType(elementType: parseTypeString(inner))
        }
        
        // Tuple: (...) 顶层含逗号 — 对应 TupleTypeSyntax
        // e.g. "(Int, String)"  "(x: Int, y: String)"
        if s.hasPrefix("(") && s.hasSuffix(")") {
            let inner = String(s.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
            let elements = typeStringSplitTopLevel(inner, by: ",")
            if elements.count >= 2 {
                let tupleType = SwiftSymbolTupleType()
                for elem in elements {
                    let typeStr = typeStringStripTupleLabel(elem.trimmingCharacters(in: .whitespaces))
                    tupleType.elements.append(parseTypeString(typeStr))
                }
                return tupleType
            }
            // 单元素括号，直接 unwrap
            if let only = elements.first {
                let trimmed = only.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { return parseTypeString(trimmed) }
            }
        }
        
        // Protocol Composition: A & B — 对应 CompositionTypeSyntax
        let compParts = typeStringSplitTopLevel(s, by: "&")
        if compParts.count >= 2 {
            let compType = SwiftCompositionType()
            for part in compParts {
                compType.elements.append(parseTypeString(part.trimmingCharacters(in: .whitespaces)))
            }
            return compType
        }
        
        // 其余：命名类型、泛型、模块限定类型 → SingleType
        // e.g. "Int"  "MyClass"  "Set<Int>"  "Result<Int, Error>"  "Swift.Int"
        return SwiftSymbolSingleType(typeName: s)
    }
    
    // MARK: - Private helpers
    
    /// 在顶层（depth == 0）查找第一个 ->，返回其 Range。
    /// 遇到 -> 时优先判断并跳过 >，避免 > 影响括号深度计数。
    private func typeStringTopLevelArrow(in s: String) -> Range<String.Index>? {
        var depth = 0
        var i = s.startIndex
        while i < s.endIndex {
            let ch = s[i]
            let next = s.index(after: i)
            if ch == "-", next < s.endIndex, s[next] == ">" {
                if depth == 0 { return i..<s.index(after: next) }
                i = s.index(after: next)   // 跳过 >，不计入 depth
                continue
            }
            switch ch {
            case "(", "[", "<": depth += 1
            case ")", "]", ">": if depth > 0 { depth -= 1 }
            default: break
            }
            i = s.index(after: i)
        }
        return nil
    }
    
    /// 按分隔符在顶层分割字符串，忽略括号/泛型内的分隔符。
    private func typeStringSplitTopLevel(_ s: String, by sep: Character) -> [String] {
        var result: [String] = []
        var depth = 0
        var current = ""
        var i = s.startIndex
        while i < s.endIndex {
            let ch = s[i]
            let next = s.index(after: i)
            // 跳过 -> 中的 >，避免影响 depth
            if ch == "-", next < s.endIndex, s[next] == ">" {
                current.append(ch)
                current.append(s[next])
                i = s.index(after: next)
                continue
            }
            switch ch {
            case "(", "[", "<": depth += 1
            case ")", "]", ">": if depth > 0 { depth -= 1 }
            default: break
            }
            if ch == sep, depth == 0 {
                result.append(current)
                current = ""
            } else {
                current.append(ch)
            }
            i = s.index(after: i)
        }
        result.append(current)
        return result
    }
    
    /// 剥离 tuple 元素的 label，如 "name: Int" → "Int"。
    /// label 只含 letter/digit/underscore，确保不误剥 "[String : Int]" 中的冒号。
    private func typeStringStripTupleLabel(_ s: String) -> String {
        guard let colonRange = s.range(of: ": ") else { return s }
        let label = String(s[..<colonRange.lowerBound])
        guard label.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) else { return s }
        return String(s[colonRange.upperBound...])
    }
    
    /// 剥离函数参数的修饰词（inout / @escaping 等）及 label，
    /// 最终留下纯类型字符串供 parseTypeString 递归处理。
    private func typeStringStripParamModifiers(_ s: String) -> String {
        var r = s
        for prefix in ["inout ", "@escaping ", "@autoclosure ", "consuming ", "borrowing "] {
            if r.hasPrefix(prefix) {
                r = String(r.dropFirst(prefix.count))
                break
            }
        }
        return typeStringStripTupleLabel(r)
    }
}
