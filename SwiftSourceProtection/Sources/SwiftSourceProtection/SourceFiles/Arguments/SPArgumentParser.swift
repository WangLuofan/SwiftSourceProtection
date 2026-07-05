//
//  SPArgumentParser.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/1.
//

import ArgumentParser

protocol SPArgumentProtocol {
    /// 项目目录
    var project: String { get }
    
    /// scheme名称
    var scheme: String { get }
    
    /// 预览运行
    var dryRun: Bool { get }
}

struct SPObfuseArgument: SPArgumentProtocol {
    
    let project: String
    
    let scheme: String
    
    let dryRun: Bool
    
    /// 源码乱序
    let shuffle: Bool
}

struct SPDeObfuseArgument: SPArgumentProtocol {
    let project: String
    
    let scheme: String
    
    let dryRun: Bool
    
    /// 混淆映射表
    let confusedMap: String
}

struct CommonOptions: ParsableArguments {
    @Argument(help: "Specify the project file(.xcodeproj / .xcworkspace")
    var project: String
    
    @Argument(help: "Specify the scheme in the project")
    var scheme: String
    
    @Flag(name: [.short, .long], help: "Perform a trial run without making any changes.")
    var dryRun: Bool = false
}

struct SPObfuseParser: ParsableCommand {
    static let configuration: CommandConfiguration = CommandConfiguration(
        commandName: "obfuse",
        abstract: "Obfuse Swift Source Project"
    )
    
    @OptionGroup
    var options: CommonOptions

    @Flag(name:[.short, .long], help: "Randomize the order of source codes.")
    var shuffle: Bool = false
    
    func run() throws {
        let argument: SPObfuseArgument = SPObfuseArgument(
            project: self.options.project,
            scheme: self.options.scheme,
            dryRun: self.options.dryRun,
            shuffle: self.shuffle
        )
        
        let ssp: SPSourceProtection = SPSourceProtection(obfuse: true, argument: argument)
        ssp.run()
    }
}

struct SPDeobfuseParser: ParsableCommand {
    static let configuration: CommandConfiguration = CommandConfiguration(
        commandName: "deobfuse",
        abstract: "Deobfuse obfused Swift Source Project"
    )
    
    @OptionGroup
    var options: CommonOptions

    @Argument(help: "Specify Obfused Map File")
    var map: String
    
    func run() throws {
        let argument: SPDeObfuseArgument = SPDeObfuseArgument(
            project: self.options.project,
            scheme: self.options.scheme,
            dryRun: self.options.dryRun,
            confusedMap: self.map
        )
        
        let ssp: SPSourceProtection = SPSourceProtection(obfuse: false, argument: argument)
        ssp.run()
    }
}

struct SPArgumentParser: ParsableCommand {
    
    static let configuration: CommandConfiguration = CommandConfiguration(
        commandName: "SwiftSourceProtection",
        abstract: "Protect and obfuscate/deobfusecate Swift source code",
        subcommands: [
            SPObfuseParser.self,
            SPDeobfuseParser.self
        ]
    )
    
}
