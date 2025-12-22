//
//  SourceKitLSP.swift
//  SwiftSourceProtection
//
//  Created by WangLuofan on 2025/11/29.
//

@preconcurrency import Foundation

// 定义符号来源枚举
enum SymbolSource: String, CustomStringConvertible {
    case systemFramework = "系统库"
    case thirdPartyLibrary = "第三方库"
    case userCode = "自定义代码"
    case unknown = "未知"
    
    var description: String {
        return self.rawValue
    }
}

// 符号信息结构体
struct SymbolInfo {
    let name: String
    let filePath: String?
    let source: SymbolSource
    let symbolType: String // 新增：符号类型
}

class SourceKitLSPAnalyzer: @unchecked Sendable {
    
    public static let shared: SourceKitLSPAnalyzer = SourceKitLSPAnalyzer()
    
    private lazy var process: Process = Process()
    private lazy var inputPipe: Pipe = Pipe()
    private lazy var outputPipe: Pipe = Pipe()
    private lazy var errorPipe: Pipe = Pipe()
    
    private lazy var lock: NSLock = NSLock()
    
    private var requestID = 1
    private lazy var responseData = Data()
    private lazy var responseHandlers: [Int: (Result<[String: Any], Error>) -> Void] = [:]
    
    private init() {
        let lspPath: String = "/usr/bin/sourcekit-lsp"
        
        self.setUpProcess(lspPath: lspPath)
        self.setUpCommunication()
    }
    
    private func setUpProcess(lspPath: String) {
        self.process.executableURL = .init(fileURLWithPath: lspPath)
        self.process.standardInput = self.inputPipe
        self.process.standardOutput = self.outputPipe
        self.process.standardError = self.errorPipe
    }
    
    private func setUpCommunication() {
        self.outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            
            let data = handle.availableData
            if data.count > 0 {
                self?.handleOutput(data)
            }
        }
        
        self.errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.count > 0, let errorString = String(data: data, encoding: .utf8) {
                print("LSP Error: \(errorString)")
            }
        }
    }
    
    func start() {
        if let _ = try? self.process.run() {
            print("启动 sourcekit-lsp 进程...")
            return
        }
        
        print("sourcekit-lsp 进程启动失败...")
    }
    
    func stop() {
        // 首先终止进程
        self.process.terminate()
        
        // 等待进程完全终止
        self.process.waitUntilExit()
        
        // 然后安全地清理管道
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 在主线程上安全地设置 handler 为 nil
            self.outputPipe.fileHandleForReading.readabilityHandler = nil
            self.errorPipe.fileHandleForReading.readabilityHandler = nil
            
            // 关闭所有管道
            try? self.inputPipe.fileHandleForWriting.close()
            try? self.outputPipe.fileHandleForReading.close()
            try? self.errorPipe.fileHandleForReading.close()
        }
    }
}

extension SourceKitLSPAnalyzer {
    private func sendRequest(_ method: String, params: [String: Any]?, completion: ((Result<[String: Any], Error>) -> Void)?) {
        guard let params else {
            completion?(.failure(NSError(domain: "LSPError", code: -1, userInfo: [NSLocalizedDescriptionKey: "实例已释放"])))
            return
        }
        
        if self.lock.try() {
            defer { self.lock.unlock() }
            
            let id = self.requestID
            self.requestID += 1
            
            self.responseHandlers[id] = { result in
                completion?(result)
            }
            
            let request: [String: Any] = [
                "jsonrpc": "2.0",
                "id": id,
                "method": method,
                "params": params
            ]
            
            do {
                let requestData = try JSONSerialization.data(withJSONObject: request)
                let requestString = String(data: requestData, encoding: .utf8) ?? ""
                let requestWithHeader = "Content-Length: \(requestData.count)\r\n\r\n\(requestString)"
                
                // 3. 写入管道发送请求
                if let requestDataWithHeader = requestWithHeader.data(using: .utf8) {
                    // 写入操作建议放到后台队列（避免阻塞 handlerQueue）
                    DispatchQueue.global(qos: .utility).async {
                        self.inputPipe.fileHandleForWriting.write(requestDataWithHeader)
                    }
                }
            } catch {
                // 构造请求失败：立即触发回调
                completion?(.failure(error))
                // 清理当前请求的回调（避免内存泄漏）
                self.responseHandlers.removeValue(forKey: id)
            }
        }
    }
    
    // 发送 LSP 通知（不需要响应）
    private func sendNotification(_ method: String, params: [String: Any]) {
        let request: [String: Any] = [
            "jsonrpc": "2.0",
            "method": method,
            "params": params
        ]
        
        do {
            let requestData = try JSONSerialization.data(withJSONObject: request)
            let requestString = String(data: requestData, encoding: .utf8) ?? ""
            let requestWithHeader = "Content-Length: \(requestData.count)\r\n\r\n\(requestString)"
            
            if let requestDataWithHeader = requestWithHeader.data(using: .utf8) {
                inputPipe.fileHandleForWriting.write(requestDataWithHeader)
            }
        } catch {
            print("发送通知失败: \(error)")
        }
    }
    
    // 处理 LSP 响应
    private func handleOutput(_ data: Data) {
        self.lock.lock()
        defer { self.lock.unlock() }
        
        responseData.append(data)
        
        while let response = self.parseNextResponse() {
            if let id = response["id"] as? Int,
               let handler = self.responseHandlers.removeValue(forKey: id) {
                if let result = response["result"] {
                    handler(.success(["result": result]))
                } else if let error = response["error"] {
                    handler(.failure(NSError(domain: "LSP", code: -1, userInfo: ["error": error])))
                }
            } else if response["method"] != nil {
                // 处理服务器发来的通知，忽略
                continue
            }
        }
    }
    
    private func parseNextResponse() -> [String: Any]? {
        // 直接在字节级别处理，避免字符串编码问题
        let headerPattern = "Content-Length: ".data(using: .utf8)!
        
        guard let headerRange = responseData.range(of: headerPattern) else {
            return nil
        }
        
        var index = headerRange.upperBound
        var contentLength = 0
        
        // 读取 Content-Length 值
        while index < responseData.endIndex {
            let byte = responseData[index]
            if byte == 13 { // \r
                break
            }
            if byte >= 48 && byte <= 57 { // 数字 0-9
                contentLength = contentLength * 10 + Int(byte - 48)
            }
            index += 1
        }
        
        // 跳过 \r\n\r\n
        while index + 3 < responseData.endIndex {
            if responseData[index] == 13 &&     // \r
               responseData[index+1] == 10 &&   // \n
               responseData[index+2] == 13 &&   // \r
               responseData[index+3] == 10 {    // \n
                index += 4
                break
            }
            index += 1
        }
        
        // 检查是否有完整的 JSON 数据
        guard index + contentLength <= responseData.endIndex else {
            return nil
        }
        
        let jsonData = responseData.subdata(in: index..<index + contentLength)
        
        do {
            if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                // 移除整个响应（从头部开始到 JSON 结束）
                let totalLength = index + contentLength - headerRange.lowerBound
                responseData.removeSubrange(0..<totalLength)
                return json
            }
        } catch {
            print("JSON 解析错误: \(error)")
            // 即使解析失败，也要移除这个响应
            let totalLength = index + contentLength - headerRange.lowerBound
            responseData.removeSubrange(0..<totalLength)
        }
        
        return nil
    }
    
    // 初始化 LSP
    func initialize(workspacePath: String, semaphore: DispatchSemaphore) {
        let params: [String: Any] = [
            "processId": ProcessInfo.processInfo.processIdentifier,
            "rootUri": URL(fileURLWithPath: workspacePath).absoluteString,
            "capabilities": [:],
            "initializationOptions": [:]
        ]
        
        sendRequest("initialize", params: params) { [weak self] result in
            print("初始化完成")
            
            // 发送 initialized 通知（不是方法调用）
            let initializedParams: [String: Any] = [:]
            self?.sendNotification("initialized", params: initializedParams)
            
            semaphore.signal()
        }
    }
    
    // 打开文档
    func openDocument(filePath: String) {
        if let text = try? String(contentsOfFile: filePath) {
            let params: [String: Any] = [
                "textDocument": [
                    "uri": URL(fileURLWithPath: filePath).absoluteString,
                    "languageId": "swift",
                    "version": 1,
                    "text": text
                ]
            ]
            
            sendNotification("textDocument/didOpen", params: params)
        }
    }
    
    // 获取符号定义
    func getSymbolDefinition(filePath: String, line: Int, character: Int, symbolName: String, symbolType: String){
        let params: [String: Any] = [
            "textDocument": [
                "uri": URL(fileURLWithPath: filePath).absoluteString
            ],
            "position": [
                "line": line,
                "character": character
            ]
        ]
        
        sendRequest("textDocument/definition", params: params) { response in
//            var definitionFilePath: String?
//            var source: SymbolSource = .unknown
//            
//            if let result = response["result"] as? [[String: Any]],
//               let firstLocation = result.first,
//               let uri = firstLocation["uri"] as? String,
//               let url = URL(string: uri) {
//                
//                definitionFilePath = url.path
//                source = determineSource(filePath: definitionFilePath, currentFile: filePath)
//            } else {
//                // 如果没有找到定义，使用已知的系统函数列表
//                if isKnownSystemFunction(symbolName) {
//                    source = .systemFramework
//                } else if isKnownSystemProperty(symbolName) {
//                    source = .systemFramework
//                } else {
//                    // 尝试在项目目录中查找定义
//                    if let projectPath = findProjectPath(for: filePath),
//                       let foundPath = await findSymbolDefinitionInProject(symbolName, projectPath: projectPath) {
//                        definitionFilePath = foundPath
//                        source = determineSource(filePath: foundPath, currentFile: filePath)
//                    }
//                }
//            }
            
//            return SymbolInfo(name: symbolName, filePath: definitionFilePath, source: source, symbolType: symbolType)
        }
    }
}
