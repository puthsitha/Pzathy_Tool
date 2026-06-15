//
//  FileStorage.swift
//  pzathy_tool
//
//  Small helpers for on-disk locations and Codable JSON persistence.
//

import Foundation

enum FileStorage {
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Folder where downloaded audio files live.
    static var audioDirectory: URL {
        let dir = documentsDirectory.appendingPathComponent("Audio", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func loadJSON<T: Decodable>(_ type: T.Type, named name: String) -> T? {
        let url = documentsDirectory.appendingPathComponent(name)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    static func saveJSON<T: Encodable>(_ value: T, named name: String) {
        let url = documentsDirectory.appendingPathComponent(name)
        if let data = try? JSONEncoder().encode(value) {
            try? data.write(to: url, options: .atomic)
        }
    }
}
