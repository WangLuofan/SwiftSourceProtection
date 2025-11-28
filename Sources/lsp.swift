//
//  lsp.swift
//  SwiftRefactorUtil
//
//  Created by 王落凡 on 2025/11/28.
//

import Foundation

class SourceKitLSPAnalyzer: @unchecked Sendable {
    private let process: Process
    private let inputPipe: Pipe
    private let outputPipe: Pipe
    private let errorPipe: Pipe
    
    private var requestId = 1
    private var responseHandlers: [Int: (Result<[String: Any], Error>) -> Void] = [:]
    private var responseData = Data()
    
    init(lspPath: String = "/usr/bin/sourcekit-lsp") {
        self.process = Process()
        self.inputPipe = Pipe()
        self.outputPipe = Pipe()
        self.errorPipe = Pipe()
        
        setupProcess(lspPath: lspPath)
        setupCommunication()
    }
    
    private func setupProcess(lspPath: String) {
        process.executableURL = URL(fileURLWithPath: lspPath)
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe
    }
    
    private func setupCommunication() {
        // 设置输出处理
        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.count > 0 {
                self?.handleOutput(data)
            }
        }
        
        // 设置错误处理
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.count > 0, let errorString = String(data: data, encoding: .utf8) {
                print("LSP Error: \(errorString)")
            }
        }
    }
    
    func start() throws {
        try process.run()
        print("启动 sourcekit-lsp 进程...")
    }
    
    func stop() {
        process.terminate()
        outputPipe.fileHandleForReading.readabilityHandler = nil
        errorPipe.fileHandleForReading.readabilityHandler = nil
    }
    
    // 发送 LSP 请求
    private func sendRequest(_ method: String, params: [String: Any]) async throws -> [String: Any] {
        let id = requestId
        requestId += 1
        
        let request: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id,
            "method": method,
            "params": params
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            responseHandlers[id] = { [weak self] result in
                continuation.resume(with: result)
            }
            
            do {
                let requestData = try JSONSerialization.data(withJSONObject: request)
                let requestString = String(data: requestData, encoding: .utf8) ?? ""
                let requestWithHeader = "Content-Length: \(requestData.count)\r\n\r\n\(requestString)"
                
                if let requestDataWithHeader = requestWithHeader.data(using: .utf8) {
                    inputPipe.fileHandleForWriting.write(requestDataWithHeader)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // 发送 LSP 通知（不需要响应）
    private func sendNotification(_ method: String, params: [String: Any]) throws {
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
        responseData.append(data)
        
        while let response = parseNextResponse() {
            if let id = response["id"] as? Int,
               let handler = responseHandlers.removeValue(forKey: id) {
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
        guard let responseString = String(data: responseData, encoding: .utf8) else {
            return nil
        }
        
        // 查找 Content-Length 头
        if let range = responseString.range(of: "Content-Length: ") {
            let startIndex = range.upperBound
            if let endIndex = responseString.range(of: "\r\n", range: startIndex..<responseString.endIndex)?.lowerBound,
               let contentLength = Int(responseString[startIndex..<endIndex]) {
                
                // 查找 JSON 开始位置
                if let jsonStart = responseString.range(of: "\r\n\r\n")?.upperBound {
                    let jsonEndIndex = responseString.index(jsonStart, offsetBy: contentLength)
                    
                    if jsonEndIndex <= responseString.endIndex {
                        let jsonString = String(responseString[jsonStart..<jsonEndIndex])
                        
                        // 移除已处理的数据
                        let totalLength = responseString.distance(from: responseString.startIndex, to: jsonEndIndex)
                        if responseData.count >= totalLength {
                            responseData.removeFirst(totalLength)
                        }
                        
                        do {
                            if let json = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8) ?? Data()) as? [String: Any] {
                                return json
                            }
                        } catch {
                            print("JSON 解析错误: \(error)")
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    // 初始化 LSP
    func initialize(workspacePath: String) async throws {
        let params: [String: Any] = [
            "processId": ProcessInfo.processInfo.processIdentifier,
            "rootUri": URL(fileURLWithPath: workspacePath).absoluteString,
            "capabilities": [:],
            "initializationOptions": [:]
        ]
        
        let response = try await sendRequest("initialize", params: params)
        print("初始化完成")
        
        // 发送 initialized 通知（不是方法调用）
        let initializedParams: [String: Any] = [:]
        try sendNotification("initialized", params: initializedParams)
    }
    
    // 打开文档
    func openDocument(filePath: String) async throws {
        let text = try String(contentsOfFile: filePath)
        let params: [String: Any] = [
            "textDocument": [
                "uri": URL(fileURLWithPath: filePath).absoluteString,
                "languageId": "swift",
                "version": 1,
                "text": text
            ]
        ]
        
        try sendNotification("textDocument/didOpen", params: params)
    }
}
