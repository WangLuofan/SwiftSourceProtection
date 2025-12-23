//
//  SwiftSourceConfusedTable.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2025/12/23.
//

class SwiftSourceConfusedTable: @unchecked Sendable {
    static let shared: SwiftSourceConfusedTable = SwiftSourceConfusedTable()
    
    lazy var confusedTable: [String: String] = [String: String]()
}
