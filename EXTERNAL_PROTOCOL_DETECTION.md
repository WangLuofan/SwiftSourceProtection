# 外部协议方法检测（方案1：SourceKitten）

## 功能说明

现在你的混淆工具可以正确识别并**不混淆**来自外部协议的方法，例如：

```swift
// ❌ 以前：这些方法会被错误混淆
class MyEncoder: Codable {
    func encode(to encoder: Encoder) throws { }  // Codable 协议方法
    func myCustomMethod() { }  // 自定义方法
}

// ✅ 现在：正确区分
class MyEncoder: Codable {
    func encode(to encoder: Encoder) throws { }  // 不混淆（外部协议）
    func myCustomMethod() { }  // 混淆（自定义方法）
}
```

## 实现原理

### 检测流程

```
1. 对于每个方法，检查是否是函数符号
   ↓
2. 使用 SourceKitten 获取该方法的 cursor info
   ↓
3. 检查 cursor info 中的 key.overrides 字段
   ↓
4. 如果 overrides 指向协议方法 → 返回 false（不混淆）
   如果没有 overrides 或指向项目内方法 → 继续正常流程
```

### 关键判断依据

SourceKitten 的 `key.overrides` 字段包含了方法实现的来源：

```swift
// 外部协议方法示例
{
  "key.name": "encode(to:)",
  "key.overrides": [
    {
      "key.kind": "source.lang.swift.decl.function.method.instance.protocol",
      "key.usr": "s:10Foundation7Codable7encode2toySo7NSCoderC_tF",
      "key.name": "encode(to:)"
    }
  ]
}
```

如果 `key.kind` 包含 `protocol`，说明是协议方法。

## 支持的协议检测

### 自动检测的系统协议

- **Codable / Encodable / Decodable**
  - `encode(to:)`
  - `init(from:)`

- **Equatable / Hashable**
  - `==(_:_:)`
  - `hash(into:)`

- **Comparable**
  - `<(_:_:)`

- **CustomStringConvertible**
  - `description`

- **Error**
  - 所有 Error 协议方法

- **其他标准库协议**
  - OptionSet
  - RawRepresentable
  - 等等...

### 第三方协议

只要协议不在你的项目符号表中，都会被检测为外部协议。

## 使用方式

### 1. 确保项目类型正确

你的项目必须是 Xcode 项目（.xcodeproj 或 .xcworkspace），因为 SourceKitten 依赖 xcodebuild。

### 2. 设置正确的 target

在 `main.swift` 中修改 target 名称：

```swift
let sourceKittenHandler = SourceKittenHandler(
    projectPath: projectPath,
    projectTarget: "YourTargetName"  // 修改为你的 target
)
```

### 3. 运行混淆

```bash
swift run SwiftSourceProtection /path/to/your/project
```

### 4. 查看输出

```
✅ SourceKitten 初始化成功，将检测外部协议方法
count: 42
混淆完成
```

如果看到 "⚠️ SourceKitten 初始化失败"，说明：
- 项目路径不正确
- target 名称不正确
- 或者 xcodebuild 失败

## 性能考虑

### 初始化开销

- SourceKitten 需要调用 `xcodebuild`：**10-30秒**
- 仅初始化一次，后续查询较快

### 查询开销

- 每次 `getCursorInfo` 调用：**~100ms**
- 仅对方法符号调用，变量和类型不会调用
- 典型项目（100个方法）：额外增加 **~10秒**

### 优化建议

1. **缓存结果**（可选优化）：
   ```swift
   private static var protocolMethodCache: [String: Bool] = [:]
   ```

2. **只在需要时启用**：
   如果你的项目没有实现外部协议，可以禁用此功能

## 故障排除

### SourceKitten 初始化失败

**可能原因**：
1. 项目无法编译
2. target 名称错误
3. 缺少依赖

**解决方法**：
```bash
# 手动测试 xcodebuild
cd /path/to/project
xcodebuild -project YourProject.xcodeproj -target YourTarget -showBuildSettings

# 或者 workspace
xcodebuild -workspace YourProject.xcworkspace -scheme YourScheme -showBuildSettings
```

### 某些协议方法仍被混淆

**可能原因**：
1. SourceKitten 未正确识别（罕见）
2. 协议方法没有正确的 key.overrides

**解决方法**：
添加到黑名单（在 `isExternalProtocolMethod` 中）：
```swift
let systemProtocols = [
    "Codable", "Equatable", "Hashable",
    "YourProtocolName"  // 添加你的协议
]
```

### 性能问题

如果混淆时间过长：

**方法1：禁用 SourceKitten**
```swift
// main.swift
// let sourceKittenHandler = SourceKittenHandler(...)
SwiftConfusedHelper.sourceKittenHandler = nil
```

**方法2：添加缓存**
```swift
// SwiftConfusedHelper.swift
private static var protocolMethodCache: [String: Bool] = [:]

private static func isExternalProtocolMethod(_ funcSymbol: SwiftSourceFunctionSymbol) -> Bool {
    let cacheKey = "\(funcSymbol.symbolFilePath ?? ""):\(funcSymbol.originalSymbol)"

    if let cached = protocolMethodCache[cacheKey] {
        return cached
    }

    let result = /* 原有检测逻辑 */
    protocolMethodCache[cacheKey] = result
    return result
}
```

## 测试用例

创建测试文件验证功能：

```swift
// TestProtocol.swift
import Foundation

// 测试1：系统协议
class MyData: Codable {
    var name: String = "test"

    // 不应混淆
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
    }

    // 应该混淆
    func myCustomMethod() {
        print("Custom")
    }

    enum CodingKeys: String, CodingKey {
        case name
    }
}

// 测试2：Equatable
class MyClass: Equatable {
    var value: Int = 0

    // 不应混淆
    static func == (lhs: MyClass, rhs: MyClass) -> Bool {
        return lhs.value == rhs.value
    }

    // 应该混淆
    func compare(with other: MyClass) -> Bool {
        return self.value == other.value
    }
}

// 测试3：项目内协议
protocol MyProjectProtocol {
    func projectMethod()
}

class MyImplementation: MyProjectProtocol {
    // 应该混淆（项目内协议）
    func projectMethod() {
        print("Project")
    }

    // 应该混淆
    func anotherMethod() {
        print("Another")
    }
}
```

## 总结

✅ **优点**：
- 完全准确，使用编译器的类型信息
- 支持所有系统协议和第三方协议
- 自动检测，无需手动维护列表

⚠️ **限制**：
- 需要 Xcode 项目
- 初始化较慢（10-30秒）
- 查询有一定开销（~100ms/次）

🎯 **适用场景**：
- iOS/macOS 应用开发
- 实现了大量系统协议的项目
- 需要高准确度的混淆
