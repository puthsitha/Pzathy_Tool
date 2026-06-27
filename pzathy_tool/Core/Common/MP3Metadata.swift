//
//  MP3Metadata.swift
//  pzathy_tool
//
//  Embeds ID3v2.3 metadata (title, artist, year, cover art) into MP3 bytes so a
//  shared .mp3 carries its own song info. Pure-Swift; no third-party dependencies.
//

import Foundation

enum MP3Metadata {

    /// Writes a copy of `mp3Data` with a fresh ID3v2.3 tag prepended and returns the
    /// temporary file URL. Any ID3v2 tag already at the start of `mp3Data` is stripped
    /// first so we never double-tag a file.
    static func taggedFile(
        mp3Data: Data,
        title: String,
        artist: String,
        year: String?,
        coverJPEG: Data?,
        fileName: String
    ) throws -> URL {
        let audio = stripLeadingID3(from: mp3Data)
        var output = buildTag(title: title, artist: artist, year: year, coverJPEG: coverJPEG)
        output.append(audio)

        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("share", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
        try output.write(to: url)
        return url
    }

    // MARK: - Tag building

    private static func buildTag(title: String, artist: String, year: String?, coverJPEG: Data?) -> Data {
        var frames = Data()
        frames.append(textFrame(id: "TIT2", text: title))   // title
        frames.append(textFrame(id: "TPE1", text: artist))  // artist
        if let year, !year.isEmpty {
            frames.append(textFrame(id: "TYER", text: year)) // year
        }
        if let coverJPEG, !coverJPEG.isEmpty {
            frames.append(pictureFrame(jpeg: coverJPEG))     // thumbnail / cover art
        }

        var tag = Data()
        tag.append(contentsOf: [0x49, 0x44, 0x33]) // "ID3"
        tag.append(contentsOf: [0x03, 0x00])       // version 2.3.0
        tag.append(0x00)                            // flags
        tag.append(contentsOf: synchsafe(UInt32(frames.count)))
        tag.append(frames)
        return tag
    }

    /// Text frame using UTF-16-with-BOM encoding so titles/artists in any script survive.
    private static func textFrame(id: String, text: String) -> Data {
        var content = Data([0x01])                          // encoding: UTF-16 w/ BOM
        content.append(contentsOf: [0xFF, 0xFE])            // little-endian BOM
        content.append(text.data(using: .utf16LittleEndian) ?? Data())
        content.append(contentsOf: [0x00, 0x00])           // UTF-16 terminator
        return frame(id: id, content: content)
    }

    /// APIC frame holding the cover art as a front-cover JPEG.
    private static func pictureFrame(jpeg: Data) -> Data {
        var content = Data([0x00])                          // description encoding: Latin-1
        content.append("image/jpeg".data(using: .isoLatin1) ?? Data())
        content.append(0x00)                                // MIME terminator
        content.append(0x03)                                // picture type: cover (front)
        content.append(0x00)                                // empty description + terminator
        content.append(jpeg)
        return frame(id: "APIC", content: content)
    }

    private static func frame(id: String, content: Data) -> Data {
        var f = Data()
        f.append(id.data(using: .isoLatin1) ?? Data())
        f.append(contentsOf: bigEndian(UInt32(content.count))) // v2.3 frame size: plain 32-bit
        f.append(contentsOf: [0x00, 0x00])                     // flags
        f.append(content)
        return f
    }

    // MARK: - Helpers

    private static func bigEndian(_ value: UInt32) -> [UInt8] {
        [UInt8((value >> 24) & 0xFF), UInt8((value >> 16) & 0xFF),
         UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF)]
    }

    /// 28-bit synchsafe integer (7 usable bits per byte) used by the tag-header size field.
    private static func synchsafe(_ value: UInt32) -> [UInt8] {
        [UInt8((value >> 21) & 0x7F), UInt8((value >> 14) & 0x7F),
         UInt8((value >> 7) & 0x7F), UInt8(value & 0x7F)]
    }

    /// Removes an ID3v2 tag at the start of `data`, if one is present.
    private static func stripLeadingID3(from data: Data) -> Data {
        let start = data.startIndex
        guard data.count > 10,
              data[start] == 0x49, data[start + 1] == 0x44, data[start + 2] == 0x33
        else { return data }

        // Header size (bytes 6...9) is a synchsafe integer; full tag = 10 + size.
        let size = (UInt32(data[start + 6]) << 21) | (UInt32(data[start + 7]) << 14)
                 | (UInt32(data[start + 8]) << 7) | UInt32(data[start + 9])
        let tagLength = 10 + Int(size)
        guard tagLength < data.count else { return data }
        return data.subdata(in: data.index(start, offsetBy: tagLength)..<data.endIndex)
    }
}
