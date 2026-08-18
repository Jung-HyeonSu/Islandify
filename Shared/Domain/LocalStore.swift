import Foundation

public enum IslandifyDataModel {
    public static let currentVersion = 1
}

public enum LocalStoreError: Error, Equatable {
    case invalidKey
    case invalidSchemaVersion(Int)
    case encodingFailed
    case decodingFailed
}

public protocol LocalStore {
    func save<Value: Encodable>(_ value: Value, forKey key: String, schemaVersion: Int) throws
    func load<Value: Decodable>(_ type: Value.Type, forKey key: String) throws -> Value?
    func removeValue(forKey key: String) throws
}

private struct EncodedEnvelope<Value: Encodable>: Encodable {
    let schemaVersion: Int
    let value: Value
}

private struct DecodedEnvelope<Value: Decodable>: Decodable {
    let schemaVersion: Int
    let value: Value
}

/// A small device-local JSON store with an explicit schema envelope.
/// The app can replace the migration closure in a later schema version without
/// changing callers or storing process-local state.
public final class JSONLocalStore: LocalStore {
    public let directoryURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(directoryURL: URL, fileManager: FileManager = .default) {
        self.directoryURL = directoryURL
        self.fileManager = fileManager

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func save<Value: Encodable>(_ value: Value, forKey key: String, schemaVersion: Int = IslandifyDataModel.currentVersion) throws {
        guard Self.isValidKey(key), schemaVersion > 0 else {
            throw LocalStoreError.invalidKey
        }

        do {
            let envelope = EncodedEnvelope(schemaVersion: schemaVersion, value: value)
            let data = try encoder.encode(envelope)
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            try data.write(to: fileURL(forKey: key), options: Data.WritingOptions.atomic)
        } catch let error as LocalStoreError {
            throw error
        } catch {
            throw LocalStoreError.encodingFailed
        }
    }

    public func load<Value: Decodable>(_ type: Value.Type, forKey key: String) throws -> Value? {
        guard Self.isValidKey(key) else {
            throw LocalStoreError.invalidKey
        }

        let url = fileURL(forKey: key)
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let envelope = try decoder.decode(DecodedEnvelope<Value>.self, from: data)
            guard envelope.schemaVersion <= IslandifyDataModel.currentVersion else {
                throw LocalStoreError.invalidSchemaVersion(envelope.schemaVersion)
            }
            return envelope.value
        } catch let error as LocalStoreError {
            throw error
        } catch {
            throw LocalStoreError.decodingFailed
        }
    }

    public func removeValue(forKey key: String) throws {
        guard Self.isValidKey(key) else {
            throw LocalStoreError.invalidKey
        }

        let url = fileURL(forKey: key)
        guard fileManager.fileExists(atPath: url.path) else {
            return
        }
        try fileManager.removeItem(at: url)
    }

    private func fileURL(forKey key: String) -> URL {
        directoryURL.appendingPathComponent("\(key).json", isDirectory: false)
    }

    private static func isValidKey(_ key: String) -> Bool {
        !key.isEmpty && key.rangeOfCharacter(from: CharacterSet(charactersIn: "/\\")) == nil
    }
}
