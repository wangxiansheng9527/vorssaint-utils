// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// The Finder right-click menu: the templates it offers, how paths are written,
/// where files land, and what the app and its sandboxed extension send each other.
enum FinderContextMenuTests {
    static func run(_ suite: TestSuite) {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("vorssaint-finder-context-\(UUID().uuidString)")
        let manager = FileManager.default
        try? manager.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? manager.removeItem(at: root) }

        // Templates
        let templates = FinderContextSupport.defaultTemplates()
        suite.expect(templates.map(\.ext) == ["txt", "md", "rtf", "docx", "xlsx", "pptx", "wps", "et", "dps"],
                     "the default templates cover text, Markdown, Office and WPS formats")
        suite.expect(Set(templates.map(\.id)).count == templates.count, "template ids are unique")
        suite.expect(FinderContextSupport.decodeTemplates(FinderContextSupport.encode(templates)) == templates,
                     "templates survive being saved and read back")
        suite.expect(FinderContextSupport.decodeTemplates(nil) == nil
                && FinderContextSupport.decodeTemplates(Data("nope".utf8)) == nil,
                     "a missing or broken saved template list falls back to the defaults")
        suite.expect(FinderContextSupport.sanitizedExtension(" .Md ") == "Md"
                && FinderContextSupport.sanitizedExtension("a/b c") == "abc"
                && FinderContextSupport.sanitizedExtension("") == "",
                     "typed extensions lose dots, spaces and slashes")

        // Names
        let a = FinderContextSupport.uniqueURL(in: root, baseName: "Untitled", ext: "txt")
        suite.expect(a.lastPathComponent == "Untitled.txt", "the first new file keeps the plain name")
        manager.createFile(atPath: a.path, contents: nil)
        let b = FinderContextSupport.uniqueURL(in: root, baseName: "Untitled", ext: "txt")
        suite.expect(b.lastPathComponent == "Untitled 2.txt", "a taken name gets a number, not an overwrite")
        suite.expect(FinderContextSupport.uniqueURL(in: root, baseName: "Folder", ext: "")
            .lastPathComponent == "Folder", "a name without extension has no stray dot")

        // Creating files
        let empty = FinderContextSupport.Template(id: "t", name: "T", ext: "txt", kind: .empty, value: nil)
        let created = try? FinderContextSupport.createFile(from: empty, in: root, baseName: "Note")
        suite.expect(created?.lastPathComponent == "Note.txt"
                && (try? Data(contentsOf: created!))?.isEmpty == true,
                     "an empty template creates a zero-byte file")
        let text = FinderContextSupport.Template(id: "r", name: "R", ext: "rtf", kind: .text, value: "{\\rtf1}")
        let rtf = try? FinderContextSupport.createFile(from: text, in: root, baseName: "Note")
        suite.expect(rtf.flatMap { try? String(contentsOf: $0, encoding: .utf8) } == "{\\rtf1}",
                     "a text template writes its text")
        let source = root.appendingPathComponent("source.dat")
        try? Data("copy me".utf8).write(to: source)
        let fromFile = FinderContextSupport.Template(id: "f", name: "F", ext: "dat", kind: .file, value: source.path)
        let copied = try? FinderContextSupport.createFile(from: fromFile, in: root, baseName: "Copy")
        suite.expect(copied.flatMap { try? String(contentsOf: $0, encoding: .utf8) } == "copy me",
                     "a file template copies the chosen file")
        let missing = FinderContextSupport.Template(id: "m", name: "M", ext: "dat", kind: .file, value: "/nonexistent/x")
        suite.expect((try? FinderContextSupport.createFile(from: missing, in: root, baseName: "X")) == nil,
                     "a template whose file is gone creates nothing")
        suite.expect((try? FinderContextSupport.createFile(from: empty, in: root.appendingPathComponent("nope"),
                                                           baseName: "X")) == nil,
                     "no file is created in a folder that does not exist")
        let bundled = FinderContextSupport.Template(id: "b", name: "B", ext: "docx", kind: .bundled, value: "Blank.docx")
        suite.expect((try? FinderContextSupport.createFile(from: bundled, in: root, baseName: "X",
                                                           bundle: Bundle(for: BundleToken.self))) == nil,
                     "a bundled template missing from the app fails instead of writing an empty file")
        for template in templates where template.kind == .bundled {
            let path = "Resources/\(FinderContextSupport.bundledFolder)/\(template.value ?? "")"
            suite.expect(manager.fileExists(atPath: path), "\(template.id) has its blank document in the repo")
        }

        // Paths
        let home = "/Users/someone"
        suite.expect(FinderContextSupport.pathText(["/a/b.txt", "/c"], style: .full, home: home) == "/a/b.txt\n/c",
                     "several paths are copied one per line")
        suite.expect(FinderContextSupport.pathText(["/a/b.txt"], style: .name, home: home) == "b.txt",
                     "the name style keeps only the file name")
        suite.expect(FinderContextSupport.pathText([home + "/Desktop/x", home, "/Users/someone2/x"],
                                                   style: .home, home: home) == "~/Desktop/x\n~\n/Users/someone2/x",
                     "the home style abbreviates only the user's own folder")
        suite.expect(FinderContextSupport.pathText(["/tmp/it's here"], style: .quoted, home: home)
                     == "'/tmp/it'\\''s here'", "the quoted style is safe to paste into a shell")

        // Terminal
        suite.expect(FinderContextSupport.terminalDirectory(directory: "/bg", paths: [], isDirectory: { _ in true })
                     == "/bg", "the terminal opens in the folder the menu was opened in")
        suite.expect(FinderContextSupport.terminalDirectory(directory: nil, paths: ["/a/file.txt"],
                                                            isDirectory: { _ in false }) == "/a",
                     "a selected file opens its parent folder")
        suite.expect(FinderContextSupport.terminalDirectory(directory: nil, paths: ["/a/dir"],
                                                            isDirectory: { _ in true }) == "/a/dir",
                     "a selected folder opens itself")
        suite.expect(FinderContextSupport.Terminal.sanitized("bogus") == .terminal
                && FinderContextSupport.Terminal.sanitized(nil) == .terminal
                && FinderContextSupport.Terminal.sanitized("warp") == .warp,
                     "an unknown terminal choice falls back to Terminal")

        // Move and copy
        let destination = root.appendingPathComponent("dest")
        try? manager.createDirectory(at: destination, withIntermediateDirectories: true)
        let item = root.appendingPathComponent("item.txt")
        try? Data("1".utf8).write(to: item)
        try? Data("old".utf8).write(to: destination.appendingPathComponent("item.txt"))
        let copyResult = FinderContextSupport.transfer([item], to: destination, move: false)
        suite.expect(copyResult.failed.isEmpty && manager.fileExists(atPath: item.path)
                && manager.fileExists(atPath: destination.appendingPathComponent("item 2.txt").path),
                     "copying keeps the original and never overwrites a file with the same name")
        suite.expect((try? String(contentsOf: destination.appendingPathComponent("item.txt"), encoding: .utf8))
                     == "old", "the file already there is untouched")
        let moveResult = FinderContextSupport.transfer([item], to: destination, move: true)
        suite.expect(moveResult.failed.isEmpty && !manager.fileExists(atPath: item.path)
                && manager.fileExists(atPath: destination.appendingPathComponent("item 3.txt").path),
                     "moving removes the original")
        let inside = destination.appendingPathComponent("item 3.txt")
        suite.expect(FinderContextSupport.transfer([inside], to: destination, move: true).moved.isEmpty
                && manager.fileExists(atPath: inside.path),
                     "moving an item into the folder it is already in does nothing")
        let nested = destination.appendingPathComponent("inner")
        try? manager.createDirectory(at: nested, withIntermediateDirectories: true)
        suite.expect(FinderContextSupport.transfer([destination], to: nested, move: true).failed == ["dest"]
                && manager.fileExists(atPath: nested.path),
                     "a folder is never moved into itself")

        // Favorites and wire format
        let favorites = [FinderContextSupport.favorite(forFolder: URL(fileURLWithPath: "/Users/x/Projects"))]
        suite.expect(favorites[0].name == "Projects"
                && FinderContextSupport.decodeFavorites(FinderContextSupport.encode(favorites)) == favorites
                && FinderContextSupport.decodeFavorites(nil).isEmpty,
                     "favorites are named after their folder and survive being saved")
        var config = FinderContextWire.MenuConfig()
        config.enabled = true
        config.labels.newFile = "新建文件"
        config.newFiles = [.init(id: "txt", title: "Text (.txt)", path: nil)]
        config.favorites = [.init(id: "1", title: "Projects", path: "/Users/x/Projects")]
        suite.expect(FinderContextWire.decode(FinderContextWire.MenuConfig.self,
                                              from: FinderContextWire.encode(config)) == config,
                     "the menu sent to the extension arrives unchanged, non-ASCII text included")
        let action = FinderContextWire.Action(kind: .moveTo, argument: "/dest", directory: nil, paths: ["/a b/c"])
        suite.expect(FinderContextWire.decode(FinderContextWire.Action.self,
                                              from: FinderContextWire.encode(action)) == action,
                     "a click reaches the app unchanged")
        suite.expect(FinderContextWire.decode(FinderContextWire.Action.self, from: "{}") == nil
                && FinderContextWire.decode(FinderContextWire.MenuConfig.self, from: nil) == nil,
                     "malformed messages are ignored")
        suite.expect(FinderContextWire.configNotification(host: "a.b") != FinderContextWire.configNotification(host: "a.c")
                && FinderContextWire.extensionBundleID(host: "a.b") == "a.b.FinderMenu",
                     "each build talks only to its own extension")

        // The extension is compiled apart from the app, so it can use nothing but the wire file.
        let extensionSource = (try? String(contentsOfFile: "Sources/FinderContextExtension/FinderContextExtension.swift",
                                           encoding: .utf8)) ?? ""
        suite.expect(!extensionSource.isEmpty && !extensionSource.contains("FinderContextSupport")
                && !extensionSource.contains("AppFeature"),
                     "the Finder extension depends only on the shared wire format")
        suite.expect(AppFeature.finderContextMenu.group == .clipboardFiles
                && AppFeature.finderContextMenu.permissions == [.filesAndFolders]
                && AppFeature.finderContextMenu.onboardingPermissions.isEmpty
                && FeaturePreset.essential.features.contains(.finderContextMenu),
                     "the right-click menu is a Finder feature, installed from the first run, with no broad permission")
        for language in AppLanguage.allCases {
            let strings = FeatureStrings.finderContext(language)
            let labels = [strings.menuNewFile, strings.menuCopyPath, strings.menuCopyCurrentPath,
                          strings.menuFullPath, strings.menuFileName, strings.menuHomePath,
                          strings.menuQuotedPath, strings.menuOpenTerminal, strings.menuFavorites,
                          strings.menuOpenFolder, strings.menuMoveHere, strings.menuCopyHere,
                          strings.untitledName, strings.templateWord, strings.templateWPSWriter]
            suite.expect(labels.allSatisfy { !$0.isEmpty }, "the Finder menu is fully labeled in \(language.rawValue)")
        }
        suite.expect(FeatureStrings.finderContext(.zhHans).menuNewFile == "新建文件",
                     "Simplified Chinese is complete")
    }

    private final class BundleToken {}
}
