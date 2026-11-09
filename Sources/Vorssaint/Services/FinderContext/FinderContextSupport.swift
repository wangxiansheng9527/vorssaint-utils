// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// The decisions behind the Finder right-click menu, kept free of views and
/// services so they can be tested: which files can be created, how a path is
/// written out, and where a new or moved file may land.
enum FinderContextSupport {
    // MARK: New file templates

    struct Template: Codable, Equatable, Identifiable {
        enum Kind: String, Codable {
            /// A zero-byte file.
            case empty
            /// A file holding `value` as UTF-8 text.
            case text
            /// A copy of a file shipped inside the app (`value` is its name).
            case bundled
            /// A copy of a file the user chose (`value` is its path).
            case file
        }

        var id: String
        var name: String
        /// Extension without the dot.
        var ext: String
        var kind: Kind
        var value: String?
    }

    /// Names for the built-in templates, in the user's language.
    struct DefaultNames {
        var text = "Text"
        var markdown = "Markdown"
        var richText = "Rich Text"
        var word = "Word"
        var excel = "Excel"
        var powerPoint = "PowerPoint"
        var wpsWriter = "WPS Writer"
        var wpsSheet = "WPS Spreadsheet"
        var wpsPresentation = "WPS Presentation"
    }

    static let bundledFolder = "FinderTemplates"

    static func defaultTemplates(_ names: DefaultNames = DefaultNames()) -> [Template] {
        let rtf = "{\\rtf1\\ansi\\ansicpg1252\\cocoartf2761\n{\\fonttbl\\f0\\fswiss\\fcharset0 Helvetica;}\n"
            + "\\f0\\fs24 \\cf0 }\n"
        return [
            Template(id: "txt", name: names.text, ext: "txt", kind: .empty, value: nil),
            Template(id: "md", name: names.markdown, ext: "md", kind: .empty, value: nil),
            Template(id: "rtf", name: names.richText, ext: "rtf", kind: .text, value: rtf),
            Template(id: "docx", name: names.word, ext: "docx", kind: .bundled, value: "Blank.docx"),
            Template(id: "xlsx", name: names.excel, ext: "xlsx", kind: .bundled, value: "Blank.xlsx"),
            Template(id: "pptx", name: names.powerPoint, ext: "pptx", kind: .bundled, value: "Blank.pptx"),
            // WPS keeps its own formats under these extensions but opens the
            // Office formats whatever the extension says, so these start from
            // the same blank documents. Swap in a file of your own to change that.
            Template(id: "wps", name: names.wpsWriter, ext: "wps", kind: .bundled, value: "Blank.docx"),
            Template(id: "et", name: names.wpsSheet, ext: "et", kind: .bundled, value: "Blank.xlsx"),
            Template(id: "dps", name: names.wpsPresentation, ext: "dps", kind: .bundled, value: "Blank.pptx"),
        ]
    }

    static func decodeTemplates(_ data: Data?) -> [Template]? {
        guard let data else { return nil }
        return try? JSONDecoder().decode([Template].self, from: data)
    }

    static func encode<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }

    /// A file extension typed by a person: no dot, no spaces, no slashes.
    static func sanitizedExtension(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .drop(while: { $0 == "." })
        return String(trimmed.filter { !$0.isWhitespace && $0 != "/" && $0 != ":" })
    }

    // MARK: Favorites

    struct Favorite: Codable, Equatable, Identifiable {
        var id: String
        var name: String
        var path: String
    }

    static func decodeFavorites(_ data: Data?) -> [Favorite] {
        guard let data else { return [] }
        return (try? JSONDecoder().decode([Favorite].self, from: data)) ?? []
    }

    static func favorite(forFolder url: URL) -> Favorite {
        Favorite(id: UUID().uuidString, name: url.lastPathComponent, path: url.path)
    }

    // MARK: Terminal

    enum Terminal: String, CaseIterable, Identifiable {
        case terminal, iTerm, warp, ghostty

        var id: String { rawValue }

        /// The name `open -a` finds the app by.
        var appName: String {
            switch self {
            case .terminal: return "Terminal"
            case .iTerm: return "iTerm"
            case .warp: return "Warp"
            case .ghostty: return "Ghostty"
            }
        }

        static func sanitized(_ raw: String?) -> Terminal {
            raw.flatMap(Terminal.init(rawValue:)) ?? .terminal
        }
    }

    /// The folder a terminal should open in for a menu opened on a folder's
    /// background (`directory`) or on selected items.
    static func terminalDirectory(directory: String?, paths: [String],
                                  isDirectory: (String) -> Bool = { path in
        var flag: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &flag) && flag.boolValue
    }) -> String? {
        if let first = paths.first {
            return isDirectory(first) ? first : (first as NSString).deletingLastPathComponent
        }
        return directory
    }

    // MARK: Paths

    enum PathStyle: String {
        case full, name, home, quoted
    }

    static func pathText(_ paths: [String], style: PathStyle, home: String = NSHomeDirectory()) -> String {
        paths.map { path -> String in
            switch style {
            case .full:
                return path
            case .name:
                return (path as NSString).lastPathComponent
            case .home:
                if path == home { return "~" }
                return path.hasPrefix(home + "/") ? "~" + path.dropFirst(home.count) : path
            case .quoted:
                return "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
            }
        }.joined(separator: "\n")
    }

    // MARK: Names

    /// `name.ext`, then `name 2.ext`, `name 3.ext`… until nothing is there.
    static func uniqueURL(in folder: URL, baseName: String, ext: String,
                          exists: (URL) -> Bool = { FileManager.default.fileExists(atPath: $0.path) }) -> URL {
        func candidate(_ index: Int) -> URL {
            let stem = index == 1 ? baseName : "\(baseName) \(index)"
            return ext.isEmpty ? folder.appendingPathComponent(stem)
                : folder.appendingPathComponent(stem).appendingPathExtension(ext)
        }
        var index = 1
        while exists(candidate(index)) { index += 1 }
        return candidate(index)
    }

    /// Where `source` lands inside `folder`, keeping Finder's habit of numbering
    /// a name that is taken instead of overwriting it.
    static func destination(for source: URL, in folder: URL,
                            exists: (URL) -> Bool = { FileManager.default.fileExists(atPath: $0.path) }) -> URL {
        uniqueURL(in: folder, baseName: source.deletingPathExtension().lastPathComponent,
                  ext: source.pathExtension, exists: exists)
    }

    // MARK: Creating files

    enum CreationError: Error, Equatable {
        case notAFolder
        case templateMissing
        case writeFailed
    }

    /// Creates a file from `template` in `folder` and returns it.
    static func createFile(from template: Template, in folder: URL, baseName: String,
                           bundle: Bundle = .main) throws -> URL {
        var flag: ObjCBool = false
        guard FileManager.default.fileExists(atPath: folder.path, isDirectory: &flag), flag.boolValue else {
            throw CreationError.notAFolder
        }
        let destination = uniqueURL(in: folder, baseName: baseName, ext: template.ext)
        switch template.kind {
        case .empty:
            guard FileManager.default.createFile(atPath: destination.path, contents: Data()) else {
                throw CreationError.writeFailed
            }
        case .text:
            do { try Data((template.value ?? "").utf8).write(to: destination, options: .withoutOverwriting) }
            catch { throw CreationError.writeFailed }
        case .bundled:
            guard let name = template.value,
                  let source = bundle.url(forResource: (name as NSString).deletingPathExtension,
                                          withExtension: (name as NSString).pathExtension,
                                          subdirectory: bundledFolder) else {
                throw CreationError.templateMissing
            }
            do { try FileManager.default.copyItem(at: source, to: destination) }
            catch { throw CreationError.writeFailed }
        case .file:
            guard let path = template.value, FileManager.default.fileExists(atPath: path) else {
                throw CreationError.templateMissing
            }
            do { try FileManager.default.copyItem(at: URL(fileURLWithPath: path), to: destination) }
            catch { throw CreationError.writeFailed }
        }
        return destination
    }

    // MARK: Moving and copying

    struct TransferResult: Equatable {
        var moved: [URL] = []
        var failed: [String] = []
    }

    /// Moves or copies `sources` into `folder`. An item already inside `folder`
    /// is skipped when moving, and a folder is never put inside itself.
    static func transfer(_ sources: [URL], to folder: URL, move: Bool) -> TransferResult {
        var result = TransferResult()
        let manager = FileManager.default
        for source in sources {
            let parent = source.deletingLastPathComponent().standardizedFileURL.path
            if move && parent == folder.standardizedFileURL.path { continue }
            if folder.standardizedFileURL.path == source.standardizedFileURL.path
                || folder.standardizedFileURL.path.hasPrefix(source.standardizedFileURL.path + "/") {
                result.failed.append(source.lastPathComponent)
                continue
            }
            let target = destination(for: source, in: folder)
            do {
                if move { try manager.moveItem(at: source, to: target) }
                else { try manager.copyItem(at: source, to: target) }
                result.moved.append(target)
            } catch {
                result.failed.append(source.lastPathComponent)
            }
        }
        return result
    }
}
