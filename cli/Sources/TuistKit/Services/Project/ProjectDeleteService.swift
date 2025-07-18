import Foundation
import Path
import TuistLoader
import TuistServer
import TuistSupport

protocol ProjectDeleteServicing {
    func run(
        fullHandle: String,
        directory: String?
    ) async throws
}

final class ProjectDeleteService: ProjectDeleteServicing {
    private let deleteProjectService: DeleteProjectServicing
    private let getProjectService: GetProjectServicing
    private let serverEnvironmentService: ServerEnvironmentServicing
    private let configLoader: ConfigLoading

    init(
        deleteProjectService: DeleteProjectServicing = DeleteProjectService(),
        getProjectService: GetProjectServicing = GetProjectService(),
        serverEnvironmentService: ServerEnvironmentServicing = ServerEnvironmentService(),
        configLoader: ConfigLoading = ConfigLoader()
    ) {
        self.deleteProjectService = deleteProjectService
        self.getProjectService = getProjectService
        self.serverEnvironmentService = serverEnvironmentService
        self.configLoader = configLoader
    }

    func run(
        fullHandle: String,
        directory: String?
    ) async throws {
        let directoryPath: AbsolutePath
        if let directory {
            directoryPath = try AbsolutePath(validating: directory, relativeTo: FileHandler.shared.currentPath)
        } else {
            directoryPath = FileHandler.shared.currentPath
        }
        let config = try await configLoader.loadConfig(path: directoryPath)
        let serverURL = try serverEnvironmentService.url(configServerURL: config.url)

        let project = try await getProjectService.getProject(
            fullHandle: fullHandle,
            serverURL: serverURL
        )

        try await deleteProjectService.deleteProject(
            projectId: project.id,
            serverURL: serverURL
        )

        Logger.current.info("Successfully deleted the \(project.fullName) project.")
    }
}
