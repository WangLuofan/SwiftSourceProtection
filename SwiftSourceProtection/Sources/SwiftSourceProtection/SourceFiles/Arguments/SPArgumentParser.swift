//
//  SPArgumentParser.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/1.
//

import ArgumentParser

struct SPArgument {
    /// 项目目录
    let project: String
    
    /// scheme名称
    let scheme: String
    
    /// 预览运行
    let dryRun: Bool
    
    /// 源码乱序
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
