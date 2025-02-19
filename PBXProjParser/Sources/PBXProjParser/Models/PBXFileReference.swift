//
//  PBXFileReference.swift
//
//
//  Created by Thomas Hedderwick on 31/01/2023.
//

import Foundation

public class PBXFileReference: PBXObject {
	#if FULL_PBX_PARSING
	public let fileEncoding: String?
	public let explicitFileType: String?
	public let includeInIndex: String?
	public let lastKnownFileType: String?
	public let name: String?
	public let sourceTree: String
	#endif
	public let path: String

	private enum CodingKeys: String, CodingKey {
		#if FULL_PBX_PARSING
		case fileEncoding
		case explicitFileType
		case includeInIndex
		case lastKnownFileType
		case name
		case sourceTree
		#endif
		case path
	}

	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		#if FULL_PBX_PARSING
		fileEncoding = try container.decodeIfPresent(String.self, forKey: .fileEncoding)
		explicitFileType = try container.decodeIfPresent(String.self, forKey: .explicitFileType)
		includeInIndex = try container.decodeIfPresent(String.self, forKey: .includeInIndex)
		lastKnownFileType = try container.decodeIfPresent(String.self, forKey: .lastKnownFileType)
		name = try container.decodeIfPresent(String.self, forKey: .name)
		sourceTree = try container.decode(String.self, forKey: .sourceTree)
		#endif
		path = try container.decode(String.self, forKey: .path)

		try super.init(from: decoder)
	}
}

public class PBXReferenceProxy: PBXObject {}
