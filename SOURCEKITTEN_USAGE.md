# SourceKitten 集成使用指南

## 功能说明

`SourceKittenHandler` 提供了两种方式获取类型信息：

### 1. 获取整个文件的类型信息映射表

```swift
if let handler = SourceKittenHandler(projectPath: projectPath, projectTarget: "YourTarget") {
    // 获取文件中所有符号的类型信息
    if let typeMap = handler.getTypeInfo(for: "/path/to/file.swift") {
        for (location, typeInfo) in typeMap {
            print("行 \(location.line), 列 \(location.column): \(typeInfo.typeName)")
        }
    }
}
```

### 2. 获取特定位置的类型信息

```swift
if let handler = SourceKittenHandler(projectPath: projectPath, projectTarget: "YourTarget") {
    // 获取第53行第18列的类型
    if let typeName = handler.getTypeAtLocation(filePath: sourceFile, line: 53, column: 18) {
        print("该位置的类型是: \(typeName)")
    }
}
```

## 集成到混淆流程

### 建议的流程

```
1. 初始化 SourceKittenHandler
   ↓
2. 解析 AST（SwiftSyntax）
   ↓
3. 遍历 AST 节点
   ↓
4. 遇到需要类型推导的表达式时：
   - 优先查询项目符号表（SwiftSourceScopeManager）
   - 如果找不到，使用 SourceKitten 查询
   ↓
5. 进行混淆重写
```

### 示例：增强类型推导

```swift
// 在 SwiftConfusedHelper.swift 中添加
static var sourceKittenHandler: SourceKittenHandler?

static func inferExprSyntaxType(_ expr: ExprSyntaxProtocol, forSymbol symbol: SwiftSourceSymbol? = nil) -> String? {
    // 1. 先用现有的推导逻辑
    if let type = inferExprSyntaxTypeInternal(expr, forSymbol: symbol) {
        return type
    }

    // 2. 回退到 SourceKitten
    if let handler = sourceKittenHandler,
       let sourceFile = symbol?.sourceFile,
       let position = expr.positionAfterSkippingLeadingTrivia {
        // 将 AbsolutePosition 转换为行列号
        let converter = SourceLocationConverter(fileName: sourceFile, tree: ...)
        let location = converter.location(for: position)

        if let typeName = handler.getTypeAtLocation(
            filePath: sourceFile,
            line: location.line,
            column: location.column
        ) {
            return typeName
        }
    }

    return nil
}
```

## 性能考虑

1. **初始化开销**：SourceKitten 需要调用 `xcodebuild`，初始化较慢（10-30秒）
2. **查询性能**：每次 cursor info 查询需要与 SourceKit 通信（~100ms）
3. **优化建议**：
   - 只对无法推导的情况使用 SourceKitten
   - 缓存查询结果
   - 批量查询文件类型信息

## 限制

1. **需要项目能编译**：SourceKitten 依赖 Xcode 项目配置
2. **仅支持 .xcodeproj 和 .xcworkspace**：不支持纯 SPM 项目
3. **需要 macOS 12.0+**

## 替代方案

如果项目不是 Xcode 项目，可以使用：
- `swiftc -print-ast`：更轻量，但需要解析输出
- 保守策略：无法推导时保持原样，要求用户添加类型注解
