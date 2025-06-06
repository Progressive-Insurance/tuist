import FileSystem
import Foundation
import XcodeGraph
import XCTest

@testable import TuistLoader
@testable import TuistSupport
@testable import TuistTesting

final class ManifestLoaderTests: TuistTestCase {
    private var subject: ManifestLoader!
    private var fileSystem: FileSysteming!

    override func setUp() {
        super.setUp()
        fileSystem = FileSystem()
        subject = ManifestLoader()
    }

    override func tearDown() {
        fileSystem = nil
        subject = nil
        super.tearDown()
    }

    func test_loadConfig() async throws {
        // Given
        let temporaryPath = try temporaryPath()
        let content = """
        import ProjectDescription
        let config = Config()
        """

        let manifestPath = temporaryPath.appending(component: Manifest.config.fileName(temporaryPath))
        try content.write(
            to: manifestPath.url,
            atomically: true,
            encoding: .utf8
        )

        // When
        _ = try await subject.loadConfig(at: temporaryPath)
    }

    func test_loadPlugin() async throws {
        // Given
        let temporaryPath = try temporaryPath()
        let content = """
        import ProjectDescription
        let plugin = Plugin(name: "TestPlugin")
        """

        let manifestPath = temporaryPath.appending(component: Manifest.plugin.fileName(temporaryPath))
        try content.write(to: manifestPath.url, atomically: true, encoding: .utf8)

        // When
        _ = try await subject.loadPlugin(at: temporaryPath)
    }

    func test_loadProject() async throws {
        // Given
        let temporaryPath = try temporaryPath()
        let content = """
        import ProjectDescription
        let project = Project(name: "tuist")
        """

        let manifestPath = temporaryPath.appending(component: Manifest.project.fileName(temporaryPath))
        try content.write(
            to: manifestPath.url,
            atomically: true,
            encoding: .utf8
        )

        // When
        let got = try await subject.loadProject(at: temporaryPath, disableSandbox: false)

        // Then
        XCTAssertEqual(got.name, "tuist")
    }

    func test_loadPackage() async throws {
        // Given
        let temporaryPath = try temporaryPath()
        let content = """
        // swift-tools-version: 5.9
        import PackageDescription

        #if TUIST
        import ProjectDescription

        let packageSettings = PackageSettings(
            platforms: [.iOS, .watchOS]
        )

        #endif

        let package = Package(
            name: "tuist",
            products: [
                .executable(name: "tuist", targets: ["tuist"]),
            ],
            dependencies: [],
            targets: [
                .target(
                    name: "tuist",
                    dependencies: []
                ),
            ]
        )

        """

        let manifestPath = temporaryPath.appending(
            component: Manifest.package.fileName(temporaryPath)
        )
        try FileHandler.shared.createFolder(temporaryPath.appending(component: Constants.tuistDirectoryName))
        try content.write(
            to: manifestPath.url,
            atomically: true,
            encoding: .utf8
        )

        // When
        let got = try await subject.loadPackage(at: manifestPath.parentDirectory)

        // Then
        XCTAssertBetterEqual(
            got,
            .test(
                name: "tuist",
                products: [
                    PackageInfo.Product(name: "tuist", type: .executable, targets: ["tuist"]),
                ],
                targets: [
                    PackageInfo.Target(
                        name: "tuist",
                        path: nil,
                        url: nil,
                        sources: nil,
                        resources: [],
                        exclude: [],
                        dependencies: [],
                        publicHeadersPath: nil,
                        type: .regular,
                        settings: [],
                        checksum: nil,
                        packageAccess: true
                    ),
                ]
            )
        )
    }

    func test_loadPackageSettings() async throws {
        // Given
        let temporaryPath = try temporaryPath()
        let content = """
        // swift-tools-version: 5.9
        import PackageDescription

        #if TUIST
        import ProjectDescription

        let packageSettings = PackageSettings(
            targetSettings: ["TargetA": ["OTHER_LDFLAGS": "-ObjC"]]
        )

        #endif

        let package = Package(
            name: "PackageName",
            dependencies: [
                .package(url: "https://github.com/Alamofire/Alamofire", exact: "5.8.0"),
            ]
        )

        """

        let manifestPath = temporaryPath.appending(
            component: Manifest.package.fileName(temporaryPath)
        )
        try FileHandler.shared.createFolder(temporaryPath.appending(component: Constants.tuistDirectoryName))
        try content.write(
            to: manifestPath.url,
            atomically: true,
            encoding: .utf8
        )

        // When
        let got = try await subject.loadPackageSettings(at: temporaryPath, disableSandbox: false)

        // Then
        XCTAssertEqual(
            got,
            .init(
                targetSettings: [
                    "TargetA": .settings(base: [
                        "OTHER_LDFLAGS": "-ObjC",
                    ]),
                ]
            )
        )
    }

    func test_loadPackageSettings_without_package_settings() async throws {
        // Given
        let temporaryPath = try temporaryPath()
        let content = """
        // swift-tools-version: 5.9
        import PackageDescription

        let package = Package(
            name: "PackageName",
            dependencies: []
        )

        """

        let manifestPath = temporaryPath.appending(
            component: Manifest.package.fileName(temporaryPath)
        )
        try FileHandler.shared.createFolder(temporaryPath.appending(component: Constants.tuistDirectoryName))
        try content.write(
            to: manifestPath.url,
            atomically: true,
            encoding: .utf8
        )

        // When
        let got = try await subject.loadPackageSettings(at: temporaryPath, disableSandbox: false)

        // Then
        XCTAssertEqual(
            got,
            .init()
        )
    }

    func test_loadWorkspace() async throws {
        // Given
        let temporaryPath = try temporaryPath()
        let content = """
        import ProjectDescription
        let workspace = Workspace(name: "tuist", projects: [])
        """

        let manifestPath = temporaryPath.appending(component: Manifest.workspace.fileName(temporaryPath))
        try content.write(
            to: manifestPath.url,
            atomically: true,
            encoding: .utf8
        )

        // When
        let got = try await subject.loadWorkspace(at: temporaryPath, disableSandbox: false)

        // Then
        XCTAssertEqual(got.name, "tuist")
    }

    func test_loadTemplate() async throws {
        // Given
        let temporaryPath = try temporaryPath().appending(component: "folder")
        try fileHandler.createFolder(temporaryPath)
        let content = """
        import ProjectDescription

        let template = Template(
            description: "Template description",
            items: []
        )
        """

        let manifestPath = temporaryPath.appending(component: "folder.swift")
        try content.write(
            to: manifestPath.url,
            atomically: true,
            encoding: .utf8
        )

        // When
        let got = try await subject.loadTemplate(at: temporaryPath)

        // Then
        XCTAssertEqual(got.description, "Template description")
    }

    func test_load_invalidFormat() async throws {
        // Given
        let temporaryPath = try temporaryPath()
        let content = """
        import ABC
        let project
        """

        let manifestPath = temporaryPath.appending(component: Manifest.project.fileName(temporaryPath))
        try content.write(
            to: manifestPath.url,
            atomically: true,
            encoding: .utf8
        )

        // When / Then
        var _error: Error?
        do {
            _ = try await subject.loadProject(at: temporaryPath, disableSandbox: false)
        } catch {
            _error = error
        }
        XCTAssertNotNil(_error)
    }

    func test_load_missingManifest() async throws {
        let temporaryPath = try temporaryPath()
        await XCTAssertThrowsSpecific(
            { try await self.subject.loadProject(at: temporaryPath, disableSandbox: false) },
            ManifestLoaderError.manifestNotFound(.project, temporaryPath)
        )
    }

    func test_manifestsAt() async throws {
        // Given
        let fileHandler = FileHandler()
        let temporaryPath = try temporaryPath()
        try fileHandler.touch(temporaryPath.appending(component: "Project.swift"))
        try fileHandler.touch(temporaryPath.appending(component: "Workspace.swift"))
        try fileHandler.touch(temporaryPath.appending(component: "Config.swift"))

        // When
        let got = try await subject.manifests(at: temporaryPath)

        // Then
        XCTAssertTrue(got.contains(.project))
        XCTAssertTrue(got.contains(.workspace))
        XCTAssertTrue(got.contains(.config))
    }

    func test_manifestLoadError() async throws {
        // Given
        let fileHandler = FileHandler()
        let temporaryPath = try temporaryPath()
        let configPath = temporaryPath.appending(component: "Config.swift")
        try fileHandler.touch(configPath)
        let data = try fileHandler.readFile(configPath)

        // When
        await XCTAssertThrowsSpecific(
            { try await self.subject.loadConfig(at: temporaryPath) },
            ManifestLoaderError.manifestLoadingFailed(
                path: temporaryPath.appending(component: "Config.swift"),
                data: data,
                context: """
                The encoded data for the manifest is corrupted.
                The given data was not valid JSON.
                """
            )
        )
    }

    func test_validate_projectExists() async throws {
        // Given
        let path = try temporaryPath().appending(component: "App")
        try fileHandler.touch(
            path.appending(component: "Project.swift")
        )

        // When / Then
        try await subject.validateHasRootManifest(at: path)
    }

    func test_validate_workspaceExists() async throws {
        // Given
        let path = try temporaryPath().appending(component: "App")
        try fileHandler.touch(
            path.appending(component: "Workspace.swift")
        )

        // When / Then
        try await subject.validateHasRootManifest(at: path)
    }

    func test_validate_packageExists() async throws {
        // Given
        let path = try temporaryPath().appending(component: "App")
        try fileHandler.touch(
            path.appending(component: "Package.swift")
        )

        // When / Then
        try await subject.validateHasRootManifest(at: path)
    }

    func test_validate_manifestDoesNotExist() async throws {
        // Given
        let path = try temporaryPath().appending(component: "App")

        // When / Then
        await XCTAssertThrowsSpecific(
            try await subject.validateHasRootManifest(at: path),
            ManifestLoaderError.manifestNotFound(path)
        )
    }

    func test_hasRootManifest_projectExists() async throws {
        // Given
        let path = try temporaryPath().appending(component: "App")
        try await fileSystem.makeDirectory(at: path)
        try await fileSystem.touch(
            path.appending(component: "Project.swift")
        )

        // When
        let got = try await subject.hasRootManifest(at: path)

        // Then
        XCTAssertTrue(got)
    }

    func test_hasRootManifest_workspaceExists() async throws {
        // Given
        let path = try temporaryPath().appending(component: "App")
        try fileHandler.touch(
            path.appending(component: "Workspace.swift")
        )

        // When
        let got = try await subject.hasRootManifest(at: path)

        // Then
        XCTAssertTrue(got)
    }

    func test_hasRootManifest_packageExists() async throws {
        // Given
        let path = try temporaryPath().appending(component: "App")
        try fileHandler.touch(
            path.appending(component: "Package.swift")
        )

        // When
        let got = try await subject.hasRootManifest(at: path)

        // Then
        XCTAssertTrue(got)
    }

    func test_hasRootManifest_manifestDoesNotExist() async throws {
        // Given
        let path = try temporaryPath().appending(component: "App")

        // When
        let got = try await subject.hasRootManifest(at: path)

        // Then
        XCTAssertFalse(got)
    }
}
