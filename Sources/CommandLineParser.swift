//
//  CommandLineParser.swift
//  SwiftRefactorUtil
//
//  Created by 王落凡 on 2025/10/28.
//

import Foundation

public class CommandLineParser {
    static func parseCommandLine() -> String? {
        if CommandLine.argc != 2 {
            return nil
        }
        
        return CommandLine.arguments.last
    }
}
