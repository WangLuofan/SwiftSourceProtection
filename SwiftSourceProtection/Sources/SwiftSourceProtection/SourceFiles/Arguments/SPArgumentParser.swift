//
//  SPArgumentParser.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/1.
//

import ArgumentParser

struct SPArgument {
    let project: String
    
    let scheme: String
    
    let dryRun: Bool
    
    let shuffle: Bool
}

struct SPArgumentParser: ParsableCommand {
    
    static let configuration: CommandConfiguration = CommandConfiguration(
        commandName: "SwiftSourceProtection",
        abstract: "Protect and obfuscate Swift source code"
    )
    
    @Argument(help: "Specify the project file(.xcodeproj / .xcworkspace")
    var project: String
    
    @Argument(help: "Specify the scheme in the project")
    var scheme: String
    
    @Flag(name: [.short, .long], help: "Perform a trial run without making any changes.")
    var dryRun: Bool = false
    
    @Flag(name:[.short, .long], help: "Randomize the order of source codes.")
    var shuffle: Bool = false
    
    func run() throws {
        let argument: SPArgument = SPArgument(
            project: self.project,
            scheme: self.scheme,
            dryRun: self.dryRun,
            shuffle: self.shuffle
        )
        
        let ssp: SPSourceProtection = SPSourceProtection(argument: argument)
        ssp.run()
    }
}
