// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "GenIR",
	platforms: [
		.macOS(.v12)
	],
	dependencies: [
		// Dependencies declare other packages that this package depends on.
		// .package(url: /* package url */, from: "1.0.0"),
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.3"),
		.package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
		.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
		.package(path: "PBXProjParser"),
		.package(path: "GenIRLogging"),
		.package(path: "GenIRExtensions")
	],
	targets: [
		// Targets are the basic building blocks of a package. A target can define a module or a test suite.
		// Targets can depend on other targets in this package, and on products in packages this package depends on.
		.executableTarget(
			name: "gen-ir",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				.product(name: "Logging", package: "swift-log"),
				.product(name: "PBXProjParser", package: "PBXProjParser"),
				.product(name: "GenIRLogging", package: "GenIRLogging"),
				.product(name: "GenIRExtensions", package: "GenIRExtensions")
			],
			path: "Sources/GenIR"
		),
		.testTarget(
			name: "GenIRTests",
			dependencies: ["gen-ir", "GenIRLogging"],
			path: "Tests/GenIRTests"
		)
	]
)
