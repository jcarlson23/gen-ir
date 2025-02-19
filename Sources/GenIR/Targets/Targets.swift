//
//  Target.swift
//
//
//  Created by Thomas Hedderwick on 05/04/2023.
//

import Foundation
import PBXProjParser

/// Represents a collection of `Target`s
struct Targets {
	/// The underlying storage of `Target`s
	private(set) var targets: Set<Target> = []

	/// The project targets where parsed from
	private let project: ProjectParser

	init(for project: ProjectParser) {
		self.project = project

		project.targets.forEach { insert(native: $0) }
		project.packages.forEach { insert(package: $0) }
	}

	/// The sum of all commands for all stored targets
	var totalCommandCount: Int {
		targets
			.map { $0.commands.count }
			.reduce(0, +)
	}

	/// Inserts the given native target into the container if it's not already present
	/// - Parameter target: the element to insert
	/// - Returns: `(true, target)` if `target` wasn't in the container. `(false, existingElement)` if `target` is in the container.
	@discardableResult
	mutating func insert(native target: PBXNativeTarget) -> (inserted: Bool, memberAfterInsert: Element) {
		let newTarget = Target(
				name: target.name,
				backingTarget: .native(target),
				project: project
			)

		return targets.insert(newTarget)
	}

	/// Inserts the given package into the container if it's not already present
	/// - Parameter package: the element to insert
	/// - Returns: `(true, target)` if `target` wasn't in the container. `(false, existingElement)` if `target` is in the container.
	@discardableResult
	mutating func insert(package target: XCSwiftPackageProductDependency) -> (inserted: Bool, memberAfterInsert: Element) {
		// TODO: when we can handle SPM transitive deps, should we look up the name here? Can we even do that?
		let newTarget = Target(
				name: target.productName,
				backingTarget: .packageDependency(target),
				project: project
			)

		return targets.insert(newTarget)
	}

	/// Inserts the given target into the container if it's not already present
	/// - Parameter target: the element to insert
	/// - Returns: `(true, target)` if `target` wasn't in the container. `(false, existingElement)` if `target` is in the container.
	@discardableResult
	mutating func insert(target: Target) -> (inserted: Bool, memberAfterInsert: Element) {
		targets.insert(target)
	}

	// TODO: maybe specialize a product vs name lookup for those sweet sweet milliseconds
	func target(for key: String) -> Target? {
		if let result = targets.filter({ $0.name == key }).first {
			return result
		}

		if let result = targets.filter({ $0.productName == key }).first {
			return result
		}

		if let result = targets.filter({ $0.path == key }).first {
			return result
		}

		return nil
	}

	// TODO: once we stabilize Targets, this should return a Set<Target> not [String]
	func calculateDependencies(for target: Target) -> [String] {
		// TODO: eventually we'd like to move some of the project dependencies calculations here
		let dependencies = project.dependencies(for: target.name)

		if dependencies.count == 0, let productName = target.productName {
			// HACK: once we stabilize Targets to not use one of two potential names, this can be removed...
			return project.dependencies(for: productName)
		}

		return dependencies
	}
}

extension Targets: Collection {
	typealias CollectionType = Set<Target>
	typealias Index = CollectionType.Index
	typealias Element = CollectionType.Element

	var startIndex: Index { targets.startIndex }
	var endIndex: Index { targets.endIndex }

// TODO: Add subscripting support for looking up targets by name or product
	subscript(index: Index) -> CollectionType.Element {
		targets[index]
	}

	func index(after index: Index) -> Index {
		targets.index(after: index)
	}

	func makeIterator() -> CollectionType.Iterator {
		targets.makeIterator()
	}
}