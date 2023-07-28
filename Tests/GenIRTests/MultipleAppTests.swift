import XCTest
@testable import gen_ir
import PBXProjParser

final class MultipleAppTests: XCTestCase {
	static private var testPath: URL = {
		TestContext.testAssetPath
			.appendingPathComponent("MultipleApp")
			.appendingPathComponent("MultipleApp.xcodeproj")
	}()

	func testExpectedTargetLookup() async throws {
		let context = try TestContext()
		let result = try context.build(test: Self.testPath, scheme: "MultipleApp")

		let project: ProjectParser = try await ProjectParser(path: Self.testPath, logLevel: .debug)
		var targets = Targets(for: project)

		let logContents = try String(contentsOf: context.buildLog).components(separatedBy: .newlines)
		let log = XcodeLogParser(log: logContents)
		try log.parse(&targets)

		let app = try XCTUnwrap(targets.target(for: "MultipleApp"))
		let copy = try XCTUnwrap(targets.target(for: "MultipleApp Copy"))

		XCTAssertEqual(app.commands.count, 3)
		XCTAssertEqual(copy.commands.count, 3)
	}
}
