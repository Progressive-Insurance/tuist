import Foundation
import Path
import XCTest
@testable import TuistSupport
@testable import TuistTesting

final class FileHandlerErrorTests: XCTestCase {
    func test_description() {
        XCTAssertEqual(
            FileHandlerError.invalidTextEncoding(try AbsolutePath(validating: "/path")).description,
            "The file at /path is not a utf8 text file"
        )
        XCTAssertEqual(
            FileHandlerError.writingError(try AbsolutePath(validating: "/path")).description,
            "Couldn't write to the file /path"
        )
    }
}

final class FileHandlerTests: TuistUnitTestCase {
    struct TestDecodable: Decodable {}

    private var subject: FileHandler!
    private let fileManager = FileManager.default

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        subject = FileHandler()
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_replace() throws {
        // Given
        let temporaryPath = try temporaryPath()
        let tempFile = temporaryPath.appending(component: "Temporary")
        let destFile = temporaryPath.appending(component: "Destination")
        try "content".write(to: URL(fileURLWithPath: tempFile.pathString), atomically: true, encoding: .utf8)

        // When
        try subject.replace(destFile, with: tempFile)

        // Then
        let content = try String(contentsOf: URL(fileURLWithPath: destFile.pathString))
        XCTAssertEqual(content, "content")
    }

    func test_decode() throws {
        let testPlistPath = fixturePath(path: try RelativePath(validating: "Test.plist"))
        let xcframeworkInfoPlist: TestPlist = try subject.readPlistFile(testPlistPath)
        XCTAssertNotNil(xcframeworkInfoPlist)
    }

    func test_replace_cleans_up_temp() throws {
        // FIX: This test runs fine locally but it fails on CI.
        // // Given
        // let temporaryPath = try self.temporaryPath()
        // let from = temporaryPath.appending(component: "from")
        // try FileHandler.shared.touch(from)
        // let to = temporaryPath.appending(component: "to")

        // let count = try countItemsInRootTempDirectory(appropriateFor: to.asURL)

        // // When
        // try subject.replace(to, with: from)

        // // Then
        // XCTAssertEqual(count, try countItemsInRootTempDirectory(appropriateFor: to.asURL))
    }

    func test_base64MD5() throws {
        // Given
        let testZippedFrameworkPath = fixturePath(path: try RelativePath(validating: "uUI.xcframework.zip"))

        // When
        let result = try subject.urlSafeBase64MD5(path: testZippedFrameworkPath)

        // Then
        XCTAssertEqual(result, "X0vsGS0PGIT9z0l1s3Bn3A==")
    }

    func test_readPlistFile_throwsAnError_when_invalidPlist() throws {
        // Given
        let temporaryDirectory = try temporaryPath()
        let plistPath = temporaryDirectory.appending(component: "file.plist")
        try FileHandler.shared.touch(plistPath)

        // When/Then
        var _error: Error? = nil
        do {
            let _: TestDecodable = try subject.readPlistFile<TestDecodable>(plistPath)
        } catch {
            _error = error
        }
        XCTAssertEqual(
            _error as? FileHandlerError,
            FileHandlerError.propertyListDecodeError(plistPath, description: "The given data was not a valid property list.")
        )
    }

    // MARK: - Private

    private func countItemsInRootTempDirectory(appropriateFor url: URL) throws -> Int {
        let tempPath = try AbsolutePath(validating: try fileManager.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: url,
            create: true
        ).path)
        let rootTempPath = tempPath.parentDirectory
        try fileManager.removeItem(at: URL(fileURLWithPath: tempPath.pathString))
        let content = try fileManager.contentsOfDirectory(atPath: rootTempPath.pathString)
        return content.count
    }
}

private struct TestPlist: Decodable {
    enum CodingKeys: CodingKey {
        case platforms
    }

    struct Platform: Decodable {
        enum CodingKeys: CodingKey {
            case name
            case supportedLanguages
        }

        let name: String
        let supportedLanguages: [String]
    }

    let platforms: [Platform]
}
