//
//  SwiftConfuseHelper.swift
//  SwiftRefactorUtil
//
//  Created by wangluofan on 2025/12/20.
//
import Foundation

class SwiftConfuseHelper {
    static func confusedSymbolName(symbolName: String, sourceInfo: SwiftSourceInfo, minLength: Int = 1, maxLength: Int = 31) -> String? {
        if let confusedName = sourceInfo.identifierMap[symbolName] {
            return confusedName
        }
        
        if minLength <= 0 || maxLength >= 32 {
            return nil
        }
        
        let lowercase: String = "abcdefghijklmnopqrstuvwxyz"
        let uppercase: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let digital: String = "0123456789"
        let underScore: String = "_"
        
        let randomSymbolLength: Int = Int.random(in: minLength...maxLength)
        let firstCharset: [String.Element] = Array(lowercase + uppercase + underScore)
        
        var randomSymbolName = String(firstCharset[Int.random(in: 0..<firstCharset.count)])
        let allCharacters: [String] = [lowercase, uppercase, digital]
        
        for _ in 1..<randomSymbolLength {
            let randomIndex = Int.random(in: 0..<allCharacters.count)
            if randomIndex == 3 {
                randomSymbolName += underScore
                continue
            }
            
            let randomItem = Int.random(in: 0..<allCharacters[randomIndex].count)
            
            let stringArr: [String.Element] = Array(allCharacters[randomIndex])
            randomSymbolName += String(stringArr[randomItem])
        }
        
        sourceInfo.identifierMap[symbolName] = randomSymbolName
        return randomSymbolName
    }
}
