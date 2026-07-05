# SwiftSourceProtection 实现原理

本文档说明 `SwiftSourceProtection` 当前代码的核心实现思路。项目的目标是在尽量保持 Swift 语义和 Xcode 工程可编译的前提下，对源码符号做混淆，并可选对源码声明顺序做乱序处理。

## 整体流程

命令入口在 `main.swift`，实际由 `SPArgumentParser` 解析参数后创建 `SPSourceProtection` 执行。

命令参数包括：

- `project`：`.xcodeproj` 或 `.xcworkspace` 路径。
- `scheme`：需要处理的 Xcode scheme。
- `--dry-run` / `-d`：当前实现中为写回源文件，否则打印到标准输出。
- `--shuffle` / `-s`：是否对源码声明顺序做随机乱序。

主流程在 `SPSourceProtection.run()` 中分为四个阶段：

1. 通过 `xcodebuild clean build` 获取真实 Swift 编译命令。
2. 使用 SwiftSyntax 解析源码并收集本地符号、作用域和声明信息。
3. 使用 SourceKit 索引结果补全 USR、引用关系和跨文件符号关联。
4. 使用 SwiftSyntax 重写源码，把引用到的符号替换成混淆名，并可选执行源码乱序。

处理结束后，`ConfuseHelper.dumpConfusedTable` 会在项目目录输出 `confused.json`，记录原始符号到混淆符号的映射。

## 工程与编译参数获取

`SPSchemeInfoProvider` 负责从 Xcode 工程中提取模块信息。

它会执行：

```text
xcodebuild -scheme <scheme> -project/-workspace <project> -sdk iphonesimulator clean build
```

然后从构建输出中提取包含 `swiftc` 和 `-module-name` 的命令行。这样做的原因是 SwiftSyntax 只能解析语法，但 SourceKit 索引需要尽量接近真实编译环境的参数，包括：

- Swift 源文件列表。
- 模块名。
- SDK、target、import path 等编译参数。
- 条件编译宏。

如果构建命令中使用 `@...SwiftFileList`，实现会读取该文件列表并把源码路径补回 `-c` 参数后面。

为了让 SourceKit 索引更稳定，代码会过滤部分构建期参数，例如：

- `-output-file-map`
- `-parseable-output`
- `-incremental`
- `-serialize-diagnostics`
- `-emit-dependencies`

同时会把 `-O` 改为 `-Onone`，并补充 `DEBUG` 宏。

最终每个 target 会被表示为一个 `Module`：

```swift
struct Module {
    let name: String
    let sourceFiles: Set<File>
    let compilerArguments: [String]
}
```

## 符号模型

项目内部使用一组符号对象描述 Swift 源码实体：

- `SPSwiftSourceSymbol`：基础符号，保存文件、作用域、源码位置、原始名、混淆名和 USR。
- `SPSwiftSourceClassSymbol`：类型符号，用于 class、struct、enum、protocol，并保存子符号。
- `SPSwiftSourceFunctionSymbol`：函数/初始化器/enum case 符号，保存签名、参数 label 和混淆后的 label。
- `SPSwiftSourceVariableSymbol`：变量/属性/参数符号，保存访问级别、是否 static 等信息。
- `SPSwiftSourceEnumCaseSymbol`：enum case 符号，继承函数符号模型，因为 enum case 也可能带有关联值 label。

作用域由 `SPSwiftSourceScope` 表示。AST 收集阶段进入 class、struct、function、closure、if、switch、catch 等语法节点时会创建子作用域，离开节点时回到父作用域。

`IndexStore` 是全局索引缓存，保存几类映射：

- USR 到符号。
- USR 到文件。
- 源码位置到符号。
- 源码位置到 SourceKit 引用结果。
- SwiftSyntax node id 到当前作用域。
- 文件到 SourceKit 索引响应。

`SymbolIndexRelator` 进一步保存 token id 到符号的映射，最终重写阶段只依赖这个映射决定某个 token 是否需要替换。

## AST 收集阶段

`SPSwiftSourceASTCollector` 继承 `SyntaxVisitor`，负责遍历 SwiftSyntax AST。

它主要完成这些工作：

- 收集类型声明：`ClassDeclSyntax`、`StructDeclSyntax`、`ProtocolDeclSyntax`、`EnumDeclSyntax`。
- 收集成员属性、全局变量、局部变量、闭包参数、函数参数。
- 收集函数、初始化器、enum case。
- 建立父子符号关系。
- 建立语法节点到作用域的映射。
- 根据局部语法信息先生成一部分混淆名。

函数签名使用 `ConfuseHelper.generateSignature` 生成，格式类似：

```text
functionName(label1:label2:)
```

这样可以区分同名重载函数。

### extension 合并

extension 会先作为临时类型符号保存到 `extensions` 中。源码文件遍历完成后，`visitPost(SourceFileSyntax)` 会把 extension 中收集到的 children 合并回原类型符号。

当前实现也会把 extension 上识别到的 `Codable` / `CodingKey` 标记合并回原类型。

## SourceKit 索引与关联阶段

SwiftSyntax 可以可靠拿到语法结构，但无法完整判断“这个引用到底指向哪个声明”。所以项目使用 SourceKit 做语义索引。

`SPSwiftSourceASTCollector.index` 会发送 `source.request.indexsource` 请求，并把 SourceKit 返回的实体递归保存到 `IndexStore`：

- declaration / reference 的 USR。
- 源码位置。
- related 信息。
- 所属文件。

`SPSwiftSourceASTCollector.relate` 会再遍历 SourceKit 响应，把 SourceKit 的语义信息回填到前面 SwiftSyntax 收集到的符号上：

- 给类型、属性、方法、enum case 绑定 USR。
- 根据访问级别、作用域和外部继承关系决定是否生成混淆名。
- 给函数参数 label 生成混淆 label。
- 识别继承自外部库的成员，避免破坏 override、协议实现、系统框架入口。

外部继承判断在 `inheritedFromAnyExternal` 中完成。它检查当前 SourceKit 实体的 `related` 链，如果 related 符号来自当前 module 之外的文件，则认为该符号受外部约束，不应混淆。

## 预重写关联阶段

`SPSwiftSourceASTPreRewriter` 是正式重写前的关联器。

它会再次遍历 AST，对每个 identifier token：

1. 先根据 token 的源码位置查 SourceKit reference。
2. 如果 SourceKit reference 能匹配 token 文本，则通过 USR 找到目标符号。
3. 如果 SourceKit 没有给出引用，则退回到当前 SwiftSyntax 作用域中按名字查找。
4. 找到符号后，写入 `SymbolIndexRelator`，建立 token id 到符号的关系。

这个阶段的目的是把“文本替换”变成“符号替换”：最终重写不是看某个字符串叫 `name` 就替换，而是看这个 token 是否已经被关联到一个确定符号。

## 混淆名生成策略

`ConfuseHelper` 管理混淆表。

生成规则：

- 如果符号是 Swift 关键字或保留名，直接返回原名。
- 如果原名已经生成过混淆名，复用已有结果。
- 随机生成 1 到 31 位标识符。
- 首字符从字母或 `_` 中选择。
- 后续字符从字母和数字中选择。
- 避免和已有混淆名冲突。
- 避免生成 Swift 关键字。

混淆策略由 `shouldConfuseSymbol` 控制：

- class / struct / enum / protocol / enum case 默认可混淆。
- global、local、private function 可混淆。
- global、local、static、private variable 可混淆。
- 其他符号需要 SourceKit 进一步判断后再决定。

函数和 enum case 除了混淆自身名字，还会为参数 label 生成对应的 `confusedLabels`。调用点重写时会用这个映射同步改参数标签。

## 正式源码重写

`SPSwiftSourceASTRewriter` 继承 `SyntaxRewriter`，负责生成最终源码。

### token 重写

最基础的重写发生在 `visit(TokenSyntax)`：

```swift
token id -> SymbolIndexRelator -> symbol.confusedSymbolName
```

如果当前 token 能找到符号且符号有混淆名，就把 token 改成混淆后的 identifier。

### 函数声明参数标签

函数声明本身需要单独处理参数 label：

```swift
func testFunc(num1: Int, num2: Int)
```

如果函数符号的 label 被混淆，`visit(FunctionDeclSyntax)` 会把声明处的 `firstName` 同步替换为 `confusedLabels`。

### 函数调用参数标签

调用点由 `visit(FunctionCallExprSyntax)` 处理。

它会根据被调用表达式找到对应函数符号，然后把调用参数 label 按 `labels -> confusedLabels` 映射替换。

初始化器调用比较特殊：调用表达式关联到类型符号时，会在类型 children 中寻找 `originalSymbolName == "init"` 且参数 label 匹配的初始化器符号。

多尾随闭包的 label 也会按同一套规则同步重写。

### enum case 关联值标签

`visit(EnumCaseDeclSyntax)` 会处理 enum case 关联值参数的 label。enum case 本身在 SourceKit 关联阶段决定是否混淆，关联值 label 也需要和调用点保持一致。

### #selector 宏

`visit(MacroExpansionExprSyntax)` 对 `#selector(...)` 做特殊处理。

例如：

```swift
#selector(handleTap(sender:))
```

这里的 `sender` 不是普通函数调用参数，而是 `DeclNameArgumentSyntax`。如果 `handleTap(sender:)` 的 Swift 方法 label 被混淆，`#selector` 内部的 label 也要同步修改，否则编译器无法解析到正确方法。

如果方法带有显式 `@objc(handleTapWithSender:)`，Objective-C runtime 暴露名由 `@objc(...)` 决定，Swift 方法名和 label 可以混淆，但 `#selector` 中的 Swift 引用仍必须同步重写。

## 特殊语义保护

Swift 混淆不能只看“这个名字能不能改”，还要看编译器、协议、运行时和外部系统是否依赖这个名字。

当前项目中已经包含几类保护。

### Swift 关键字与基础类型

`String.isSwiftKeyWord` 中维护了一批不能作为混淆目标处理的关键字、上下文关键字、基础类型和常见框架类型。

这些名字不会被混淆，也不会被随机生成器生成出来。

### 外部继承和协议约束

SourceKit 的 `related` 信息用于识别 override、协议实现、系统框架入口等外部约束。如果符号的 related 链指向当前 module 之外的文件，则认为该符号不能混淆。

这种保护用于避免破坏类似：

```swift
override func viewDidLoad()
func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
```

这类外部 API 约定入口。

### Codable / CodingKey

`SPSwiftSourceClassSymbol.isInheritedFromCodableOrCodingKey` 用来标记直接遵守 `Codable` 或 `CodingKey` 的类型。

当前实现的核心策略是：

- `Codable` / `CodingKey` 类型的属性不在 SourceKit relate 阶段生成混淆名。
- `CodingKey` enum case 不在 SourceKit relate 阶段生成混淆名。
- extension 上的 `Codable` / `CodingKey` 标记会合并回原类型。

这主要是为了保护 `Codable` 自动合成依赖的存储属性名，以及 `enum CodingKeys: CodingKey` 的 case 名。

### resultBuilder

`@resultBuilder` 类型中的 builder hook 方法名不能随意混淆。Swift 编译器会按固定名称识别这些方法，例如：

- `buildExpression(_:)`
- `buildBlock(_:)`
- `buildOptional(_:)`
- `buildEither(first:)`
- `buildEither(second:)`
- `buildArray(_:)`
- `buildLimitedAvailability(_:)`
- `buildFinalResult(_:)`

当前实现通过 `SymbolAttribute.resultBuilder` 和 `ResultBuilderMethod` 识别 result builder 类型中的这些方法，并在 SourceKit relate 阶段跳过对应方法的混淆。

### Objective-C 暴露与 Selector

Swift 与 Objective-C runtime 交互时，名字可能被字符串或 selector 依赖。

当前实现重点处理 Swift 语法中的 `#selector(...)`，保证 selector 内部的 Swift 方法 label 和混淆后的声明保持一致。

对于显式 `@objc(name:)`，Objective-C 暴露名由属性参数决定，通常不应修改 `@objc(...)` 内部名称。对于没有显式 selector 的 `@objc`、`@IBAction`、`@objcMembers` 场景，需要继续依赖 SourceKit 外部约束判断或额外保守策略。

## 源码乱序

`SPSwiftSourceASTShuffler` 是可选阶段，由 `--shuffle` 控制。

它会随机打乱：

- 文件顶层声明顺序，但 import 仍放在非 import 之前。
- class / struct / protocol / enum / extension 的成员顺序。

乱序只调整声明列表，不改函数体内部语句顺序。

需要注意，Swift 中部分声明顺序可能有隐式影响，例如同文件 private 访问、条件编译、宏展开、属性包装器组合等。当前 shuffler 是语法级乱序，没有做更深的依赖分析。

## 当前实现边界

当前实现已经覆盖了大量常见 Swift 语法，但仍有一些需要谨慎的边界：

- `Codable` 识别当前主要匹配直接的 `Codable` / `CodingKey`，如果写成 `Swift.Codable`、`Encodable`、`Decodable` 或类型别名，可能需要扩展判断。
- `inheritedFromAnyExternal` 当前依赖 SourceKit 的 related 信息，索引质量会影响保护效果。
- `#selector` 已有专项处理，但字符串形式的 `Selector("...")`、KVC `forKey:`、通知名、storyboard action 等字符串语义仍需要独立保护。
- `@objcMembers` 下没有显式 selector 的成员，如果被 ObjC runtime 外部使用，保守策略应该避免混淆或同步改写外部资源。
- result builder hook 当前按固定签名白名单处理，后续如果支持 Swift 新版本 hook，需要同步补充 `ResultBuilderMethod`。
- 源码乱序不做语义依赖分析，适合在可编译验证后使用。

## 文件职责速览

- `main.swift`：程序入口。
- `SPArgumentParser.swift`：命令行参数定义。
- `SPSourceProtection.swift`：主流程编排。
- `SPSchemeInfoProvider.swift`：调用 xcodebuild 并解析模块、源码文件和编译参数。
- `SourceKit.swift` / `DLHandle.swift`：sourcekitd 动态加载与请求封装。
- `SPSwiftSourceASTCollector.swift`：SwiftSyntax 符号收集、作用域建立、SourceKit 关联。
- `SPSwiftSourceASTPreRewriter.swift`：把源码 token 关联到符号。
- `SPSwiftSourceASTRewriter.swift`：正式 AST 重写。
- `SPSwiftSourceASTShuffler.swift`：源码声明乱序。
- `ConfuseHelper.swift`：混淆名生成、混淆表管理、签名生成。
- `IndexStore.swift`：索引数据缓存。
- `SymbolIndexRelator.swift`：token id 到符号的映射。
- `SPSwiftSourceScope.swift`：作用域树和符号查找。
- `SPSwiftSourceSymbol.swift` 及其子类：符号模型。
- `SPSwiftSourceDefinitions.swift`：基础枚举、属性和 result builder 方法白名单。
