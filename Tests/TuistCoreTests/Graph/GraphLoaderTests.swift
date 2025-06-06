import Foundation
import Mockable
import Path
import TuistSupport
import XcodeGraph
import XcodeMetadata
import XCTest

@testable import TuistCore
@testable import TuistTesting

final class GraphLoaderTests: TuistUnitTestCase {
    private var stubbedFrameworks = [AbsolutePath: PrecompiledMetadata]()
    private var stubbedLibraries = [AbsolutePath: PrecompiledMetadata]()
    private var stubbedXCFrameworks = [AbsolutePath: XCFrameworkMetadata]()
    private var frameworkMetadataProvider: MockFrameworkMetadataProvider!
    private var libraryMetadataProvider: MockLibraryMetadataProvider!
    private var xcframeworkMetadataProvider: MockXCFrameworkMetadataProviding!

    override func setUpWithError() throws {
        frameworkMetadataProvider = makeFrameworkMetadataProvider()
        libraryMetadataProvider = makeLibraryMetadataProvider()
        xcframeworkMetadataProvider = makeXCFrameworkMetadataProvider()
    }

    // MARK: - Load Workspace

    func test_loadWorkspace_unreferencedProjectsAreExcluded() async throws {
        // Given
        let projectA = Project.test(path: "/A", name: "A", targets: [])
        let projectB = Project.test(path: "/B", name: "B", targets: [])
        let workspace = Workspace.test(path: "/", name: "Workspace", projects: ["/A"])
        let subject = makeSubject()

        // When
        let graph = try await subject.loadWorkspace(
            workspace: workspace,
            projects: [
                projectA,
                projectB,
            ]
        )

        // Then
        XCTAssertEqual(graph.workspace, workspace)
        XCTAssertEqual(graph.projects, [
            "/A": projectA,
        ])
        XCTAssertTrue(graph.projects.values.flatMap(\.targets).isEmpty)
        XCTAssertTrue(graph.dependencies.isEmpty)
    }

    func test_loadWorkspace_unlinkedReferencedProjectsAreIncluded() async throws {
        // Given
        let projectA = Project.test(path: "/A", name: "A", targets: [])
        let projectB = Project.test(path: "/B", name: "B", targets: [])
        let workspace = Workspace.test(path: "/", name: "Workspace", projects: ["/A", "/B"])
        let subject = makeSubject()

        // When
        let graph = try await subject.loadWorkspace(
            workspace: workspace,
            projects: [
                projectA,
                projectB,
            ]
        )

        // Then
        XCTAssertEqual(graph.workspace, workspace)
        XCTAssertEqual(graph.projects, [
            "/A": projectA,
            "/B": projectB,
        ])
        XCTAssertTrue(graph.projects.values.flatMap(\.targets).isEmpty)
        XCTAssertTrue(graph.dependencies.isEmpty)
    }

    func test_loadWorkspace_linkedReferencedProjectsAreIncluded() async throws {
        // Given
        let targetA = Target.test(name: "A", dependencies: [.project(target: "B", path: "/B")])
        let targetB = Target.test(name: "B", dependencies: [])
        let projectA = Project.test(path: "/A", name: "A", targets: [targetA])
        let projectB = Project.test(path: "/B", name: "B", targets: [targetB])
        let workspace = Workspace.test(path: "/", name: "Workspace", projects: ["/A"])
        let subject = makeSubject()

        // When
        let graph = try await subject.loadWorkspace(
            workspace: workspace,
            projects: [
                projectA,
                projectB,
            ]
        )

        // Then
        XCTAssertEqual(graph.workspace, workspace.replacing(projects: ["/A", "/B"]))
        XCTAssertEqual(graph.projects, [
            "/A": projectA,
            "/B": projectB,
        ])
        XCTAssertEqual(graph.dependencies, [
            .target(name: "A", path: "/A"): Set([
                .target(name: "B", path: "/B"),
            ]),
        ])
    }

    // MARK: - Load Project

    func test_loadProject_unlinkedProjectsAreExcluded() async throws {
        // Given
        let projectA = Project.test(path: "/A", name: "A", targets: [])
        let projectB = Project.test(path: "/B", name: "B", targets: [])
        let subject = makeSubject()
        let workspace = Workspace.test(path: "/", name: "Workspace", projects: ["/A"])

        // When
        let graph = try await subject.loadWorkspace(
            workspace: workspace,
            projects: [
                projectA,
                projectB,
            ]
        )

        // Then
        XCTAssertEqual(graph.projects, [
            "/A": projectA,
        ])
        XCTAssertTrue(graph.projects.values.flatMap(\.targets).isEmpty)
        XCTAssertTrue(graph.dependencies.isEmpty)
    }

    func test_loadProject_linkedProjectsAreIncluded() async throws {
        // Given
        let targetA = Target.test(name: "A", dependencies: [.project(target: "B", path: "/B")])
        let targetB = Target.test(name: "B", dependencies: [])
        let projectA = Project.test(path: "/A", name: "A", targets: [targetA])
        let projectB = Project.test(path: "/B", name: "B", targets: [targetB])
        let subject = makeSubject()
        let workspace = Workspace.test(path: "/", name: "Workspace", projects: ["/A"])

        // When
        let graph = try await subject.loadWorkspace(
            workspace: workspace,
            projects: [
                projectA,
                projectB,
            ]
        )

        // Then
        XCTAssertEqual(graph.projects, [
            "/A": projectA,
            "/B": projectB,
        ])
        XCTAssertEqual(graph.dependencies, [
            .target(name: "A", path: "/A"): Set([
                .target(name: "B", path: "/B"),
            ]),
        ])
    }

    // MARK: - Frameworks

    func test_loadWorkspace_frameworkDependency() async throws {
        // Given
        let targetA = Target.test(name: "A", dependencies: [.framework(path: "/Frameworks/F1.framework", status: .required)])
        let targetB = Target.test(name: "B", dependencies: [.framework(path: "/Frameworks/F2.framework", status: .required)])
        let projectA = Project.test(path: "/A", name: "A", targets: [targetA])
        let projectB = Project.test(path: "/B", name: "B", targets: [targetB])
        let workspace = Workspace.test(path: "/", name: "Workspace", projects: ["/A", "/B"])

        stubFramework(
            metadata: .init(
                path: "/Frameworks/F1.framework",
                linkage: .dynamic,
                architectures: [.arm64]
            )
        )
        stubFramework(
            metadata: .init(
                path: "/Frameworks/F2.framework",
                linkage: .static,
                architectures: [.x8664]
            )
        )

        let subject = makeSubject()

        // When
        let graph = try await subject.loadWorkspace(
            workspace: workspace,
            projects: [
                projectA,
                projectB,
            ]
        )

        // Then
        XCTAssertEqual(graph.dependencies, [
            .target(name: "A", path: "/A"): Set([
                .framework(
                    path: "/Frameworks/F1.framework",
                    binaryPath: "/Frameworks/F1.framework/F1",
                    dsymPath: nil,
                    bcsymbolmapPaths: [],
                    linking: .dynamic,
                    architectures: [.arm64],
                    status: .required
                ),
            ]),
            .target(name: "B", path: "/B"): Set([
                .framework(
                    path: "/Frameworks/F2.framework",
                    binaryPath: "/Frameworks/F2.framework/F2",
                    dsymPath: nil,
                    bcsymbolmapPaths: [],
                    linking: .static,
                    architectures: [.x8664],
                    status: .required
                ),
            ]),
        ])
    }

    func test_loadWorkspace_frameworkDependencyReferencedMultipleTimes() async throws {
        // Given
        let targetA = Target.test(name: "A", dependencies: [.framework(path: "/Frameworks/F.framework", status: .required)])
        let targetB = Target.test(name: "B", dependencies: [.framework(path: "/Frameworks/F.framework", status: .required)])
        let projectA = Project.test(path: "/A", name: "A", targets: [targetA])
        let projectB = Project.test(path: "/B", name: "B", targets: [targetB])
        let workspace = Workspace.test(path: "/", name: "Workspace", projects: ["/A", "/B"])

        stubFramework(
            metadata: .init(
                path: "/Frameworks/F.framework",
                linkage: .dynamic,
                architectures: [.arm64]
            )
        )

        let subject = makeSubject()

        // When
        let graph = try await subject.loadWorkspace(
            workspace: workspace,
            projects: [
                projectA,
                projectB,
            ]
        )

        // Then
        let frameworkDependency: GraphDependency = .framework(
            path: "/Frameworks/F.framework",
            binaryPath: "/Frameworks/F.framework/F",
            dsymPath: nil,
            bcsymbolmapPaths: [],
            linking: .dynamic,
            architectures: [.arm64],
            status: .required
        )
        XCTAssertEqual(graph.dependencies, [
            .target(name: "A", path: "/A"): Set([
                frameworkDependency,
            ]),
            .target(name: "B", path: "/B"): Set([
                frameworkDependency,
            ]),
        ])
    }

    // MARK: - Libraries

    func test_loadWorkspace_libraryDependency() async throws {
        // Given
        let targetA = Target.test(name: "A", dependencies: [
            .library(path: "/libs/lib1/libL1.dylib", publicHeaders: "/libs/lib1/include", swiftModuleMap: nil),
        ])
        let targetB = Target.test(name: "B", dependencies: [
            .library(
                path: "/libs/lib2/libL2.a",
                publicHeaders: "/libs/lib2/include",
                swiftModuleMap: "/libs/lib2.swiftmodule"
            ),
        ])
        let projectA = Project.test(path: "/A", name: "A", targets: [targetA])
        let projectB = Project.test(path: "/B", name: "B", targets: [targetB])
        let workspace = Workspace.test(path: "/", name: "Workspace", projects: ["/A", "/B"])

        stubLibrary(
            metadata: .init(
                path: "/libs/lib1/libL1.dylib",
                linkage: .dynamic,
                architectures: [.arm64]
            )
        )
        stubLibrary(
            metadata: .init(
                path: "/libs/lib2/libL2.a",
                linkage: .static,
                architectures: [.x8664]
            )
        )

        let subject = makeSubject()

        // When
        let graph = try await subject.loadWorkspace(
            workspace: workspace,
            projects: [
                projectA,
                projectB,
            ]
        )

        // Then
        XCTAssertEqual(graph.dependencies, [
            .target(name: "A", path: "/A"): Set([
                .library(
                    path: "/libs/lib1/libL1.dylib",
                    publicHeaders: "/libs/lib1/include",
                    linking: .dynamic,
                    architectures: [.arm64],
                    swiftModuleMap: nil
                ),
            ]),
            .target(name: "B", path: "/B"): Set([
                .library(
                    path: "/libs/lib2/libL2.a",
                    publicHeaders: "/libs/lib2/include",
                    linking: .static,
                    architectures: [.x8664],
                    swiftModuleMap: "/libs/lib2.swiftmodule"
                ),
            ]),
        ])
    }

    // MARK: - XCFrameworks

    func test_loadWorkspace_xcframeworkDependency() async throws {
        // Given
        let targetA = Target.test(
            name: "A",
            dependencies: [.xcframework(path: "/XCFrameworks/XF1.xcframework", expectedSignature: nil, status: .required)]
        )
        let projectA = Project.test(path: "/A", name: "A", targets: [targetA])
        let workspace = Workspace.test(path: "/", name: "Workspace", projects: ["/A"])

        stubXCFramework(
            metadata: .init(
                path: "/XCFrameworks/XF1.xcframework",
                infoPlist: .test(),
                linking: .dynamic,
                mergeable: false,
                status: .required,
                macroPath: nil
            )
        )

        let subject = makeSubject()

        // When
        let graph = try await subject.loadWorkspace(
            workspace: workspace,
            projects: [
                projectA,
            ]
        )

        // Then
        XCTAssertEqual(graph.dependencies, [
            .target(name: "A", path: "/A"): Set([
                .testXCFramework(
                    path: "/XCFrameworks/XF1.xcframework",
                    infoPlist: .test(),
                    linking: .dynamic,
                    mergeable: false,
                    status: .required,
                    macroPath: nil
                ),
            ]),
        ])
    }

    func test_loadWorkspace_mergeableXCFrameworkDependency() async throws {
        // Given
        let targetA = Target.test(
            name: "A",
            dependencies: [.xcframework(path: "/XCFrameworks/XF1.xcframework", expectedSignature: nil, status: .required)]
        )
        let projectA = Project.test(path: "/A", name: "A", targets: [targetA])
        let workspace = Workspace.test(path: "/", name: "Workspace", projects: ["/A"])

        stubXCFramework(
            metadata: .init(
                path: "/XCFrameworks/XF1.xcframework",
                infoPlist: .test(),
                linking: .dynamic,
                mergeable: true,
                status: .required,
                macroPath: nil
            )
        )

        let subject = makeSubject()

        // When
        let graph = try await subject.loadWorkspace(
            workspace: workspace,
            projects: [
                projectA,
            ]
        )

        // Then
        XCTAssertEqual(graph.dependencies, [
            .target(name: "A", path: "/A"): Set([
                .testXCFramework(
                    path: "/XCFrameworks/XF1.xcframework",
                    infoPlist: .test(),
                    linking: .dynamic,
                    mergeable: true,
                    status: .required,
                    macroPath: nil
                ),
            ]),
        ])
    }

    // MARK: - SDKs

    func test_loadWorkspace_sdkDependency() async throws {
        // Given
        let targetA = Target.test(name: "A", dependencies: [.sdk(name: "libc++.tbd", status: .required)])
        let targetB = Target.test(name: "B", dependencies: [.sdk(name: "SwiftUI.framework", status: .optional)])
        let targetC = Target.test(name: "C", dependencies: [.xctest])
        let projectA = Project.test(path: "/A", name: "A", targets: [targetA, targetB, targetC])
        let workspace = Workspace.test(path: "/", name: "Workspace", projects: ["/A"])
        let subject = makeSubject()

        // When
        let graph = try await subject.loadWorkspace(
            workspace: workspace,
            projects: [
                projectA,
            ]
        )

        // Then
        XCTAssertEqual(graph.dependencies, [
            .target(name: "A", path: "/A"): Set([
                .sdk(
                    name: "libc++.tbd",
                    path: "/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/lib/libc++.tbd",
                    status: .required,
                    source: .system
                ),
            ]),
            .target(name: "B", path: "/A"): Set([
                .sdk(
                    name: "SwiftUI.framework",
                    path: "/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/SwiftUI.framework",
                    status: .optional,
                    source: .system
                ),
            ]),
            .target(name: "C", path: "/A"): Set([
                .sdk(
                    name: "XCTest.framework",
                    path: "/Platforms/iPhoneOS.platform/Developer/Library/Frameworks/XCTest.framework",
                    status: .required,
                    source: .developer
                ),
            ]),
        ])
    }

    // MARK: - Packages

    func test_loadWorkspace_packages() async throws {
        // Given
        let targetA = Target.test(name: "A", dependencies: [
            .package(product: "PackageLibraryA1", type: .runtime),
        ])
        let targetB = Target.test(name: "B", dependencies: [
            .package(product: "PackageLibraryA2", type: .runtime),
        ])
        let targetC = Target.test(name: "C", dependencies: [
            .package(product: "PackageLibraryB", type: .runtime),
        ])
        let projectA = Project.test(path: "/A", name: "A", targets: [targetA], packages: [
            .local(path: "/Packages/PackageLibraryA"),
        ])
        let projectB = Project.test(path: "/B", name: "B", targets: [targetB], packages: [
            .local(path: "/Packages/PackageLibraryA"),
        ])
        let projectC = Project.test(path: "/C", name: "C", targets: [targetC], packages: [
            .remote(url: "https://example.com/package-library-b", requirement: .branch("testing")),
        ])
        let workspace = Workspace.test(path: "/", name: "Workspace", projects: ["/A", "/B", "/C"])

        let subject = makeSubject()

        // When
        let graph = try await subject.loadWorkspace(
            workspace: workspace,
            projects: [
                projectA,
                projectB,
                projectC,
            ]
        )

        // Then

        // Note: the following is a reflection of the current implementation
        // which has a few limitation / bugs when it comes to identifying the same
        // package referenced by multiple projects/
        XCTAssertEqual(graph.packages, [
            "/A": ["/Packages/PackageLibraryA": .local(path: "/Packages/PackageLibraryA")],
            "/B": ["/Packages/PackageLibraryA": .local(path: "/Packages/PackageLibraryA")],
            "/C": ["https://example.com/package-library-b": .remote(
                url: "https://example.com/package-library-b",
                requirement: .branch("testing")
            )],
        ])
        XCTAssertEqual(graph.dependencies, [
            .target(name: "A", path: "/A"): Set([
                .packageProduct(path: "/A", product: "PackageLibraryA1", type: .runtime),
            ]),
            .target(name: "B", path: "/B"): Set([
                .packageProduct(path: "/B", product: "PackageLibraryA2", type: .runtime),
            ]),
            .target(name: "C", path: "/C"): Set([
                .packageProduct(path: "/C", product: "PackageLibraryB", type: .runtime),
            ]),
        ])
    }

    func test_loadWorkspace_package_plugin() async throws {
        // Given
        let targetA = Target.test(name: "A", dependencies: [
            .package(product: "PackagePlugin", type: .plugin),
        ])

        let projectA = Project.test(path: "/A", name: "A", targets: [targetA], packages: [
            .local(path: "/Packages/PackagePlugin"),
        ])

        let workspace = Workspace.test(path: "/", name: "Workspace", projects: ["/A"])

        let subject = makeSubject()

        // When
        let graph = try await subject.loadWorkspace(
            workspace: workspace,
            projects: [
                projectA,
            ]
        )

        // Then
        XCTAssertEqual(graph.packages, [
            "/A": ["/Packages/PackagePlugin": .local(path: "/Packages/PackagePlugin")],
        ])
        XCTAssertEqual(graph.dependencies, [
            .target(name: "A", path: "/A"): Set([
                .packageProduct(path: "/A", product: "PackagePlugin", type: .plugin),
            ]),
        ])
    }

    func test_loadWorkspace_package_embedded() async throws {
        // Given
        let targetA = Target.test(name: "A", dependencies: [
            .package(product: "PackageEmbedded", type: .runtimeEmbedded),
        ])

        let projectA = Project.test(path: "/A", name: "A", targets: [targetA], packages: [
            .local(path: "/Packages/PackageEmbedded"),
        ])

        let workspace = Workspace.test(path: "/", name: "Workspace", projects: ["/A"])

        let subject = makeSubject()

        // When
        let graph = try await subject.loadWorkspace(
            workspace: workspace,
            projects: [
                projectA,
            ]
        )

        // Then
        XCTAssertEqual(graph.packages, [
            "/A": ["/Packages/PackageEmbedded": .local(path: "/Packages/PackageEmbedded")],
        ])
        XCTAssertEqual(graph.dependencies, [
            .target(name: "A", path: "/A"): Set([
                .packageProduct(path: "/A", product: "PackageEmbedded", type: .runtimeEmbedded),
            ]),
        ])
    }

    // MARK: - Error Cases

    func test_loadWorkspace_missingProjectReferenceInWorkspace() async throws {
        // Given
        let projectA = Project.test(path: "/A", name: "A", targets: [])
        let workspace = Workspace.test(path: "/", name: "Workspace", projects: ["/A", "/Missing"])
        let subject = makeSubject()

        // When / Then
        await XCTAssertThrowsSpecific(
            try await subject.loadWorkspace(
                workspace: workspace,
                projects: [
                    projectA,
                ]
            ),
            GraphLoadingError.missingProject("/Missing")
        )
    }

    func test_loadWorkspace_missingProjectReferenceInDependency() async throws {
        // Given
        let targetA = Target.test(name: "A", dependencies: [.project(target: "Missing", path: "/Missing")])
        let projectA = Project.test(path: "/A", name: "A", targets: [targetA])
        let workspace = Workspace.test(path: "/", name: "Workspace", projects: ["/A"])
        let subject = makeSubject()

        // When / Then
        await XCTAssertThrowsSpecific(
            try await subject.loadWorkspace(
                workspace: workspace,
                projects: [
                    projectA,
                ]
            ),
            GraphLoadingError.missingProject("/Missing")
        )
    }

    func test_loadWorkspace_missingTargetReferenceInLocalProject() async throws {
        // Given
        let targetA = Target.test(name: "A", dependencies: [.target(name: "Missing")])
        let projectA = Project.test(path: "/A", name: "A", targets: [targetA])
        let workspace = Workspace.test(path: "/", name: "Workspace", projects: ["/A"])
        let subject = makeSubject()

        // When / Then
        await XCTAssertThrowsSpecific(
            try await subject.loadWorkspace(
                workspace: workspace,
                projects: [
                    projectA,
                ]
            ),
            GraphLoadingError.targetNotFound("Missing", "/A")
        )
    }

    func test_loadWorkspace_missingTargetReferenceInOtherProject() async throws {
        // Given
        let targetA = Target.test(name: "A", dependencies: [.project(target: "Missing", path: "/B")])
        let projectA = Project.test(path: "/A", name: "A", targets: [targetA])
        let projectB = Project.test(path: "/B", name: "B", targets: [])
        let workspace = Workspace.test(path: "/", name: "Workspace", projects: ["/A", "/B"])
        let subject = makeSubject()

        // When / Then
        await XCTAssertThrowsSpecific(
            try await subject.loadWorkspace(
                workspace: workspace,
                projects: [
                    projectA,
                    projectB,
                ]
            ),
            GraphLoadingError.targetNotFound("Missing", "/B")
        )
    }

    // MARK: - Helpers

    private func makeSubject() -> GraphLoader {
        GraphLoader(
            frameworkMetadataProvider: frameworkMetadataProvider,
            libraryMetadataProvider: libraryMetadataProvider,
            xcframeworkMetadataProvider: xcframeworkMetadataProvider,
            systemFrameworkMetadataProvider: SystemFrameworkMetadataProvider()
        )
    }

    private func makeFrameworkMetadataProvider() -> MockFrameworkMetadataProvider {
        let provider = MockFrameworkMetadataProvider()
        provider.loadMetadataStub = { [weak self] path in
            guard let metadata = self?.stubbedFrameworks[path] else {
                throw FrameworkMetadataProviderError.frameworkNotFound(path)
            }
            return FrameworkMetadata(
                path: path,
                binaryPath: path.appending(component: path.basenameWithoutExt),
                dsymPath: nil,
                bcsymbolmapPaths: [],
                linking: metadata.linkage,
                architectures: metadata.architectures,
                status: .required
            )
        }
        return provider
    }

    private func makeLibraryMetadataProvider() -> MockLibraryMetadataProvider {
        let provider = MockLibraryMetadataProvider()
        provider.loadMetadataStub = { [weak self] path, publicHeaders, swiftModuleMap in
            guard let metadata = self?.stubbedLibraries[path] else {
                throw LibraryMetadataProviderError.libraryNotFound(path)
            }
            return LibraryMetadata(
                path: path,
                publicHeaders: publicHeaders,
                swiftModuleMap: swiftModuleMap,
                architectures: metadata.architectures,
                linking: metadata.linkage
            )
        }
        return provider
    }

    private func makeXCFrameworkMetadataProvider() -> MockXCFrameworkMetadataProviding {
        let provider = MockXCFrameworkMetadataProviding()
        given(provider).loadMetadata(at: .any, expectedSignature: .any, status: .any).willProduce { [weak self] path, _, _ in
            guard let metadata = self?.stubbedXCFrameworks[path] else {
                throw XCFrameworkMetadataProviderError.xcframeworkNotFound(path)
            }
            return metadata
        }
        return provider
    }

    private func stubFramework(metadata: PrecompiledMetadata) {
        stubbedFrameworks[metadata.path] = metadata
    }

    private func stubLibrary(metadata: PrecompiledMetadata) {
        stubbedLibraries[metadata.path] = metadata
    }

    private func stubXCFramework(metadata: XCFrameworkMetadata) {
        stubbedXCFrameworks[metadata.path] = metadata
    }

    // MARK: - Helper types

    private struct PrecompiledMetadata {
        var path: AbsolutePath
        var linkage: BinaryLinking
        var architectures: [BinaryArchitecture]
    }
}

extension GraphLoadingError {
    private var isCycleError: Bool {
        switch self {
        case .circularDependency:
            return true
        default:
            return false
        }
    }
}
