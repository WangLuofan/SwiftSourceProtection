//
//  CommandLineParser.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2025/10/28.
//

import Foundation

public class CommandLineParser {
    static func parseCommandLine() -> CommandLineArguments? {
        let args: CommandLineArguments = CommandLineArguments()
        
        if CommandLine.argc != 7 {
            return nil
        }
        
        var argIndex: Int = 0
        for (index, argument) in CommandLine.arguments.enumerated() {
            if index < argIndex {
                continue
            }
            
            if argument == "--workspace" && (index + 1) < CommandLine.argc {
                args.workspace = CommandLine.arguments[index + 1]
                argIndex += 1
            }
        }
        
        return args
    }
}
