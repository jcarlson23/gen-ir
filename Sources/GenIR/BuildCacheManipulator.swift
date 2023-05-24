import Foundation

struct BuildCacheManipulator {
	/// Path to the build cache
	private let buildCachePath: URL

	/// Build settings used as part of the build
	private let buildSettings: [String: String]

	/// Should we run the SKIP_INSTALL hack?
	private let shouldDeploySkipInstallHack: Bool

	/// Path to the Archive Build Products inside the Build Cache
	private let archiveBuildProductsPath: URL

	/// Path to the built products inside the xcarchive
	private let buildProductsPath: URL

	enum Error: Swift.Error {
		case directoryNotFound(String)
		case tooManyDirectories(String)
	}

	init(buildCachePath: URL, buildSettings: [String: String], archive: URL) throws {
		self.buildCachePath = buildCachePath
		self.buildSettings = buildSettings
		buildProductsPath = archive
		shouldDeploySkipInstallHack = buildSettings["SKIP_INSTALL"] == "NO"

		guard FileManager.default.directoryExists(at: buildCachePath) else {
			throw Error.directoryNotFound("Build cache path doesn't exist at expected path: \(buildCachePath)")
		}

		let intermediatesPath = buildCachePath
			.appendingPathComponent("Intermediates.noindex")
			.appendingPathComponent("ArchiveIntermediates")

		var intermediateFolders: [URL]

		do {
			intermediateFolders = try FileManager.default.directories(at: intermediatesPath, recursive: false)
		} catch {
			throw Error.directoryNotFound("No directories found at \(intermediatesPath), expected exactly one. Ensure you did an archive build.")
		}

		guard intermediateFolders.count == 1 else {
			logger.debug("intermediateFolders: \(intermediateFolders))")
			throw Error.tooManyDirectories("Expected exactly one target folder at path: \(intermediatesPath), but found: \(intermediateFolders)")
		}

		let intermediatesBuildPath = intermediatesPath
				.appendingPathComponent(intermediateFolders.first!.lastPathComponent)
				.appendingPathComponent("BuildProductsPath")

		guard let archivePath = Self.findConfigurationDirectory(intermediatesBuildPath) else {
			throw Error.directoryNotFound("Couldn't find archive build directory (expected at: \(intermediatesBuildPath))")
		}

		archiveBuildProductsPath = archivePath
	}

	func manipulate() throws {
		try skipInstallHack()
	}

	private func skipInstallHack() throws {
		/* This is a hack. Turn away now.

			When archiving frameworks with the SKIP_INSTALL=NO setting, frameworks will be evicted (see below) from the build cache.
			This means when we rerun commands to generate IR, the frameworks no longer exist on disk, and we fail with linker errors.

			This is how the build cache is (roughly) laid out:

			* Build/Intermediates.noindex/ArchiveIntermediates/<TARGET>/BuildProductsPath/Debug-iphoneos
				* this contains a set of symlinks to elsewhere in the build cache. These links remain in place, but the items they point to are removed
			* Build/Products/Debug-iphoneos
				* this contains the build products cache

			The idea here is simple, attempt to update the symlinks so they point to valid framework product.
		*/
		if !shouldDeploySkipInstallHack { return }

		let symlinksToUpdate = FileManager.default.filteredContents(of: archiveBuildProductsPath) {
			$0.lastPathComponent.hasSuffix("framework")
		}
		.reduce(into: [String: URL]()) { $0[$1.lastPathComponent] = $1 }

		let existingFrameworks = FileManager.default.filteredContents(of: buildProductsPath) {
			$0.lastPathComponent.hasSuffix("framework")
		}
		.reduce(into: [String: URL]()) { $0[$1.lastPathComponent] = $1 }

		logger.debug("symlinks to update: \(symlinksToUpdate)")
		logger.debug("existing frameworks: \(existingFrameworks)")

		try symlinksToUpdate.forEach { name, path in
			guard let buildProductPath = existingFrameworks[name] else {
				logger.error("Couldn't lookup \(name) in existing frameworks: \(existingFrameworks)")
				return
			}

			// Update the symlink
			try FileManager.default.removeItem(at: path)
			try FileManager.default.createSymbolicLink(at: path, withDestinationURL: buildProductPath)
		}
	}

	///  Tries to find the xcode build configuration directory path inside the given path
	/// - Parameter path: the path to search
	/// - Returns:
	private static func findConfigurationDirectory(_ path: URL) -> URL? {
		let folders = (try? FileManager.default.directories(at: path, recursive: false)) ?? []

		guard folders.count != 0 else {
			return nil
		}

		if folders.count == 1 {
			return folders.first
		}

		// Uh oh, there shouldn't be more than one folder here - was a clean performed?
		logger.warning(
			"Expected one folder at path: \(path), but got \(folders.count): \(folders). Attempting to select a Debug or Veracode configuration folder"
		)

		let tokens = ["debug", "veracode"]
		var filtered = [URL]()

		for folder in folders {
			for token in tokens where folder.lastPathComponent.lowercased().contains(token) {
				filtered.append(folder)
			}
		}

		if filtered.count > 1 {
			logger.error(
				"""
				Found more than one possible folders matching 'debug' or 'veracode' configurations: \(filtered). Please ensure you build from a clean state.
				"""
			)
			return nil
		}

		return filtered.first
	}
}
