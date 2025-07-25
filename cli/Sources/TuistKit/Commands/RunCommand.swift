import ArgumentParser
import Foundation
import TSCUtility
import TuistSupport

enum Runnable: ExpressibleByArgument, Equatable {
    init?(argument: String) {
        let specifierComponents = argument.components(separatedBy: "@")
        if argument.starts(with: "http://") || argument.starts(with: "https://"),
           let previewLink = URL(string: argument)
        {
            self = .url(previewLink)
        } else if specifierComponents.count == 2 {
            self = .specifier(displayName: specifierComponents[0], specifier: specifierComponents[1])
        } else {
            self = .scheme(argument)
        }
    }

    case url(Foundation.URL)
    case scheme(String)
    case specifier(displayName: String, specifier: String)
}

public struct RunCommand: AsyncParsableCommand {
    public init() {}

    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "run",
            abstract: "Runs a scheme or target in the project",
            discussion: """
            Given a runnable scheme or target the run command builds & runs it.
            All arguments after the scheme or target are forwarded to the application.
            """
            // TODO: There is a bug in swift-argument-parser dependency (https://github.com/apple/swift-argument-parser/issues/169)
            // add this documentation when this is true
            //
            // For example: calling `tuist run --device iPhone 12 MyScheme Arg1 --arg2 --arg3`
            // Will result in running the application on an iPhone 12 simulator while 'Arg1', '--arg2', and '--arg3' are forwarded
            // to the application.
        )
    }

    @Argument(
        help: "Runnable project scheme, a preview URL, or app name with a specifier such as App@latest or App@feature-branch.",
        envKey: .runScheme
    )
    var runnable: Runnable

    @Flag(
        help: "Force the generation of the project before running.",
        envKey: .runGenerate
    )
    var generate: Bool = false

    @Flag(
        help: "When passed, it cleans the project before running.",
        envKey: .runClean
    )
    var clean: Bool = false

    @Option(
        name: .shortAndLong,
        help: "The path to the directory that contains the project with the target or scheme to be run.",
        completion: .directory
    )
    var path: String?

    @Option(
        name: [.long, .customShort("C")],
        help: "The configuration to be used when building the scheme."
    )
    var configuration: String?

    @Option(help: "The simulator or physical device name to run the target, scheme, or preview on.")
    var device: String?

    @Option(
        name: .shortAndLong,
        help: "The OS version of the simulator.",
        envKey: .runOS
    )
    var os: String?

    @Flag(
        name: .long,
        help: "When passed, append arch=x86_64 to the 'destination' to run simulator in a Rosetta mode."
    )
    var rosetta: Bool = false

    @Argument(
        parsing: .captureForPassthrough,
        help: "The arguments to pass to the runnable target during execution.",
        envKey: .runArguments
    )
    var arguments: [String] = []

    public func run() async throws {
        try await RunCommandService().run(
            path: path,
            runnable: runnable,
            generate: generate,
            clean: clean,
            configuration: configuration,
            device: device,
            osVersion: os,
            rosetta: rosetta,
            arguments: arguments
        )
    }
}
