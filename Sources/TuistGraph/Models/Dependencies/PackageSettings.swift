import Foundation
import TSCUtility

/// Contains the description of custom SPM settings
public struct PackageSettings: Equatable, Codable {
    /// The custom `Product` types to be used for SPM targets.
    public let productTypes: [String: Product]

    /// Custom destinations to be used for SPM products.
    public let productDestinations: [String: Destinations]

    // The base settings to be used for targets generated from SwiftPackageManager
    public let baseSettings: Settings

    /// The custom `Settings` to be applied to SPM targets
    public let targetSettings: [String: SettingsDictionary]

    /// The custom project options for each project generated from a swift package
    public let projectOptions: [String: TuistGraph.Project.Options]

    /// Swift tools version of the parsed `Package.swift`
    public let swiftToolsVersion: Version

    /// When true, it tries to mimic SPM's linking style
    public let spmLinkingStyle: Bool

    /// Initializes a new `PackageSettings` instance.
    /// - Parameters:
    ///    - productTypes: The custom `Product` types to be used for SPM targets.
    ///    - baseSettings: The base settings to be used for targets generated from SwiftPackageManager
    ///    - targetSettings: The custom `SettingsDictionary` to be applied to denoted targets
    ///    - projectOptions: The custom project options for each project generated from a swift package
    public init(
        productTypes: [String: Product],
        productDestinations: [String: Destinations],
        baseSettings: Settings,
        targetSettings: [String: SettingsDictionary],
        projectOptions: [String: TuistGraph.Project.Options] = [:],
        swiftToolsVersion: Version,
        spmLinkingStyle: Bool
    ) {
        self.productTypes = productTypes
        self.productDestinations = productDestinations
        self.baseSettings = baseSettings
        self.targetSettings = targetSettings
        self.projectOptions = projectOptions
        self.swiftToolsVersion = swiftToolsVersion
        self.spmLinkingStyle = spmLinkingStyle
    }
}
