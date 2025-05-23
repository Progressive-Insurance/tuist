import Foundation
import Path
import ProjectAutomation
import TuistSupport
import XcodeGraph

extension ProjectAutomation.Graph {
    static func from(
        graph: XcodeGraph.Graph,
        targetsAndDependencies: [GraphTarget: Set<GraphDependency>]
    ) -> ProjectAutomation.Graph {
        // generate targets projects only
        let projects = targetsAndDependencies
            .map(\.key.project)
            .uniqued()
            .reduce(into: [String: ProjectAutomation.Project]()) {
                $0[$1.path.pathString] = ProjectAutomation.Project.from($1)
            }

        return ProjectAutomation.Graph(name: graph.name, path: graph.path.pathString, projects: projects)
    }

    func export(to filePath: AbsolutePath) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        let jsonData = try encoder.encode(self)
        let jsonString = String(data: jsonData, encoding: .utf8)
        guard let jsonString else {
            throw GraphServiceError.encodingError(GraphFormat.json.rawValue)
        }

        try FileHandler.shared.write(jsonString, path: filePath, atomically: true)
    }
}

extension ProjectAutomation.Project {
    static func from(_ project: XcodeGraph.Project) -> ProjectAutomation.Project {
        let packages = project.packages
            .reduce(into: [ProjectAutomation.Package]()) { $0.append(ProjectAutomation.Package.from($1)) }
        let schemes = project.schemes.reduce(into: [ProjectAutomation.Scheme]()) { $0.append(ProjectAutomation.Scheme.from($1)) }

        var dependenciesCache = [XcodeGraph.TargetDependency: ProjectAutomation.TargetDependency]()
        let targets = project.targets.mapValues { target in
            ProjectAutomation.Target.from(target, dependenciesCache: &dependenciesCache)
        }

        let isExternal = switch project.type {
        case .external:
            true
        case .local:
            false
        }

        return ProjectAutomation.Project(
            name: project.name,
            path: project.path.pathString,
            isExternal: isExternal,
            packages: packages,
            targets: Array(targets.values),
            schemes: schemes
        )
    }
}

extension ProjectAutomation.Package {
    static func from(_ package: XcodeGraph.Package) -> ProjectAutomation.Package {
        switch package {
        case let .remote(url, _):
            return ProjectAutomation.Package(kind: ProjectAutomation.Package.PackageKind.remote, path: url)
        case let .local(path):
            return ProjectAutomation.Package(kind: ProjectAutomation.Package.PackageKind.local, path: path.pathString)
        }
    }
}

extension ProjectAutomation.Target {
    static func from(
        _ target: XcodeGraph.Target,
        dependenciesCache: inout [XcodeGraph.TargetDependency: ProjectAutomation.TargetDependency]
    )
        -> ProjectAutomation.Target
    {
        let dependencies = target.dependencies.map {
            if let foundDependency = dependenciesCache[$0] {
                return foundDependency
            }
            let target = Self.from($0)
            dependenciesCache[$0] = target
            return target
        }
        return ProjectAutomation.Target(
            name: target.name,
            product: target.product.rawValue,
            bundleId: target.bundleId,
            sources: target.sources.map(\.path.pathString),
            resources: target.resources.resources.map(\.path.pathString),
            settings: ProjectAutomation.Settings.from(target.settings),
            dependencies: dependencies
        )
    }

    static func from(_ dependency: XcodeGraph.TargetDependency) -> ProjectAutomation.TargetDependency {
        switch dependency {
        case let .target(name, status, _):
            let linkingStatus: ProjectAutomation.LinkingStatus = status == .optional ? .optional : .required
            return .target(name: name, status: linkingStatus)
        case let .project(target, path, status, _):
            let linkingStatus: ProjectAutomation.LinkingStatus = status == .optional ? .optional : .required
            return .project(target: target, path: path.pathString, status: linkingStatus)
        case let .framework(path, status, _):
            let frameworkStatus: ProjectAutomation.LinkingStatus
            switch status {
            case .optional:
                frameworkStatus = .optional
            case .required:
                frameworkStatus = .required
            case .none:
                frameworkStatus = .none
            }
            return .framework(path: path.pathString, status: frameworkStatus)
        case let .xcframework(path, expectedSignature, status, _):
            let frameworkStatus: ProjectAutomation.LinkingStatus
            switch status {
            case .optional:
                frameworkStatus = .optional
            case .required:
                frameworkStatus = .required
            case .none:
                frameworkStatus = .none
            }
            return .xcframework(path: path.pathString, status: frameworkStatus)
        case let .library(path, publicHeaders, swiftModuleMap, _):
            return .library(
                path: path.pathString,
                publicHeaders: publicHeaders.pathString,
                swiftModuleMap: swiftModuleMap?.pathString
            )
        case let .package(product, type, _):
            switch type {
            case .macro:
                return .packageMacro(product: product)
            case .plugin:
                return .packagePlugin(product: product)
            case .runtime:
                return .package(product: product)
            case .runtimeEmbedded:
                return .package(product: product, embedded: true)
            }
        case let .sdk(name, status, _):
            let projectAutomationStatus: ProjectAutomation.LinkingStatus
            switch status {
            case .optional:
                projectAutomationStatus = .optional
            case .required:
                projectAutomationStatus = .required
            case .none:
                projectAutomationStatus = .none
            }
            return .sdk(name: name, status: projectAutomationStatus)
        case .xctest:
            return .xctest
        }
    }
}

extension ProjectAutomation.Scheme {
    static func from(_ scheme: XcodeGraph.Scheme) -> ProjectAutomation.Scheme {
        var testTargets = [String]()
        if let testAction = scheme.testAction {
            for testTarget in testAction.targets {
                testTargets.append(testTarget.target.name)
            }
        }

        return ProjectAutomation.Scheme(name: scheme.name, testActionTargets: testTargets)
    }
}

extension ProjectAutomation.Settings {
    public static func from(_ settings: XcodeGraph.Settings?) -> ProjectAutomation.Settings {
        ProjectAutomation.Settings(
            configurations: [ProjectAutomation.BuildConfiguration: ProjectAutomation.Configuration?].from(
                settings?.configurations
            )
        )
    }
}

extension [ProjectAutomation.BuildConfiguration: ProjectAutomation.Configuration?] {
    public static func from(
        _ buildConfigurationDictionary: [XcodeGraph.BuildConfiguration: XcodeGraph.Configuration?]?
    ) -> [ProjectAutomation.BuildConfiguration: ProjectAutomation.Configuration?] {
        guard let buildConfigurationDictionary else {
            return [:]
        }

        var dict = [ProjectAutomation.BuildConfiguration: ProjectAutomation.Configuration?]()

        for (buildConfiguration, configuration) in buildConfigurationDictionary {
            let item = ProjectAutomation.BuildConfiguration.from(
                buildConfiguration
            )
            dict[item] = ProjectAutomation.Configuration.from(
                configuration
            )
        }

        return dict
    }
}

extension ProjectAutomation.Configuration {
    static func from(
        _ configuration: XcodeGraph.Configuration?
    ) -> ProjectAutomation.Configuration? {
        guard let configuration else {
            return nil
        }

        return ProjectAutomation.Configuration(
            settings: ProjectAutomation.SettingsDictionary.from(
                configuration.settings
            )
        )
    }
}

extension ProjectAutomation.SettingValue {
    static func from(
        _ value: XcodeGraph.SettingValue
    ) -> ProjectAutomation.SettingValue {
        switch value {
        case let .string(string):
            return ProjectAutomation.SettingValue(string: string)
        case let .array(array):
            return ProjectAutomation.SettingValue(array: array)
        }
    }
}

extension ProjectAutomation.SettingsDictionary {
    static func from(
        _ settings: XcodeGraph.SettingsDictionary
    ) -> ProjectAutomation.SettingsDictionary {
        var dict = ProjectAutomation.SettingsDictionary()
        for (key, value) in settings {
            dict[key] = ProjectAutomation.SettingValue.from(
                value
            )
        }
        return dict
    }
}

extension ProjectAutomation.BuildConfiguration {
    static func from(
        _ buildConfiguration: XcodeGraph.BuildConfiguration
    ) -> ProjectAutomation.BuildConfiguration {
        BuildConfiguration(
            name: buildConfiguration.name,
            variant: ProjectAutomation.BuildConfiguration.Variant.from(
                buildConfiguration.variant
            )
        )
    }
}

extension ProjectAutomation.BuildConfiguration.Variant {
    static func from(
        _ variant: XcodeGraph.BuildConfiguration.Variant
    ) -> ProjectAutomation.BuildConfiguration.Variant {
        ProjectAutomation.BuildConfiguration.Variant(
            variant: variant
        )
    }
}

extension ProjectAutomation.BuildConfiguration.Variant {
    private init(variant: XcodeGraph.BuildConfiguration.Variant) {
        switch variant {
        case .debug:
            self = .debug
        case .release:
            self = .release
        }
    }
}

enum GraphServiceError: FatalError {
    case jsonNotValidForVisualExport
    case encodingError(String)

    var description: String {
        switch self {
        case .jsonNotValidForVisualExport:
            return "json format is not valid for visual export"
        case let .encodingError(format):
            return "failed to encode graph to \(format)"
        }
    }

    var type: ErrorType {
        switch self {
        case .jsonNotValidForVisualExport:
            return .abort
        case .encodingError:
            return .abort
        }
    }
}
