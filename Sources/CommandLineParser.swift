//
//  CommandLineParser.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2025/10/28.
//

import Foundation

public class CommandLineParser {
    static func parseCommandLine() -> (String?, String?)? {
        
        if CommandLine.argc != 3 {
            return nil
        }
        
        return (CommandLine.arguments[1], CommandLine.arguments[2])
    }
}
