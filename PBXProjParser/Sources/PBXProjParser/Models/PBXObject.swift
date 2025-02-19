//
//  File.swift
//
//
//  Created by Thomas Hedderwick on 31/01/2023.
//

import Foundation

/// Base class for all PBX objects
public class PBXObject: Decodable {
	/// Objects class name
	public let isa: ObjectType
	// / The 'UUID-like' reference key found at the start of an object declaration
	public var reference: String!

	public enum ObjectType: String, Decodable, CaseIterable {
	case buildFile                     = "PBXBuildFile"
	case appleScriptBuildPhase         = "PBXAppleScriptBuildPhase"
	case copyFilesBuildPhase           = "PBXCopyFilesBuildPhase"
	case frameworksBuildPhase          = "PBXFrameworksBuildPhase"
	case headersBuildPhase             = "PBXHeadersBuildPhase"
	case resourcesBuildPhase           = "PBXResourcesBuildPhase"
	case shellScriptBuildPhase         = "PBXShellScriptBuildPhase"
	case sourcesBuildPhase             = "PBXSourcesBuildPhase"
	case containerItemProxy            = "PBXContainerItemProxy"
	case fileReference                 = "PBXFileReference"
	case group                         = "PBXGroup"
	case variantGroup                  = "PBXVariantGroup"
	case aggregateTarget               = "PBXAggregateTarget"
	case legacyTarget                  = "PBXLegacyTarget"
	case nativeTarget                  = "PBXNativeTarget"
	case project                       = "PBXProject"
	case targetDependency              = "PBXTargetDependency"
	case buildConfiguration            = "XCBuildConfiguration"
	case configurationList             = "XCConfigurationList"
	case swiftPackageProductDependency = "XCSwiftPackageProductDependency"
	case remoteSwiftPackageReference   = "XCRemoteSwiftPackageReference"
	case referenceProxy                = "PBXReferenceProxy"
	case versionGroup                  = "XCVersionGroup"
	case buildRule                     = "PBXBuildRule"
	case rezBuildPhase                 = "PBXRezBuildPhase"

	// swiftlint:disable cyclomatic_complexity
	public func getType() -> PBXObject.Type {
		switch self {
		case .buildFile:											return PBXBuildFile.self
		case .appleScriptBuildPhase:					return PBXAppleScriptBuildPhase.self
		case .copyFilesBuildPhase:						return PBXCopyFilesBuildPhase.self
		case .frameworksBuildPhase:						return PBXFrameworksBuildPhase.self
		case .headersBuildPhase:							return PBXHeadersBuildPhase.self
		case .resourcesBuildPhase:						return PBXResourcesBuildPhase.self
		case .shellScriptBuildPhase:					return PBXShellScriptBuildPhase.self
		case .sourcesBuildPhase:							return PBXSourcesBuildPhase.self
		case .containerItemProxy:							return PBXContainerItemProxy.self
		case .fileReference:									return PBXFileReference.self
		case .group:													return PBXGroup.self
		case .variantGroup:										return PBXVariantGroup.self
		case .aggregateTarget:								return PBXAggregateTarget.self
		case .legacyTarget:										return PBXLegacyTarget.self
		case .nativeTarget:										return PBXNativeTarget.self
		case .project:												return PBXProject.self
		case .targetDependency:								return PBXTargetDependency.self
		case .buildConfiguration:							return XCBuildConfiguration.self
		case .configurationList:							return XCConfigurationList.self
		case .swiftPackageProductDependency:	return XCSwiftPackageProductDependency.self
		case .remoteSwiftPackageReference:		return XCRemoteSwiftPackageReference.self
		case .referenceProxy:									return PBXReferenceProxy.self
		case .versionGroup:										return XCVersionGroup.self
		case .buildRule:											return PBXBuildRule.self
		case .rezBuildPhase:									return PBXRezBuildPhase.self
		}
		// swiftlint:enable cyclomatic_complexity
	}
}

}

/// Single case enum that decodes and holds a reference to an underlying `PBXObject` subclass
enum Object: Decodable {
	/// The wrapped object
	case object(PBXObject)

	private enum CodingKeys: String, CodingKey {
		case isa
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let isa = try container.decode(PBXObject.ObjectType.self, forKey: .isa)
		let singleContainer = try decoder.singleValueContainer()

		self = .object(try singleContainer.decode(isa.getType()))
	}

	func unwrap() -> PBXObject {
		if case .object(let object) = self {
			return object
		}

		fatalError(
			"""
			Failed to unwrap the underlying PBXObject, this should only happen if someone adds a case to `Object` and \
			didn't handle it.
			"""
		)
	}
}
