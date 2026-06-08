//
//  SPArgumentParser.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/1.
//

import ArgumentParser

struct SPArgumentParser: ParsableCommand {
    
    static let configuration: CommandConfiguration = CommandConfiguration(
        commandName: "SwiftSourceProtection",
        abstract: "Protect and obfuscate Swift source code"
    )
    
    @Argument(help: "Specify the project file(.xcodeproj / .xcworkspace")
    var project: String
    
    @Argument(help: "Specify the scheme in the project")
    var scheme: String
    
    func run() throws {
        let ssp: SPSourceProtection = SPSourceProtection(project: self.project, scheme: self.scheme)
        ssp.run()
    }
}
