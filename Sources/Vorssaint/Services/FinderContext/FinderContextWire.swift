// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// What the app and its Finder extension say to each other. Compiled into both
/// targets, so it stays Foundation-only.
///
/// The extension is sandboxed and can neither read the app's preferences nor
/// write files for the user. The app therefore pushes the whole menu (already
/// localized) to the extension, and the extension hands every click back to the
/// app, which does the work. Both directions travel as a JSON string in the
/// `object` of a distributed notification: unlike `userInfo`, a string object
/// is delivered to and from sandboxed processes.
enum FinderContextWire {
    /// Info.plist key naming the app that owns the extension, so the Developer
    /// and official builds each talk only to their own extension.
    static let hostBundleIDInfoKey = "VorssaintHostBundleID"

    static func configNotification(host: String) -> Notification.Name {
        Notification.Name("\(host).finderContext.config")
    }

    static func actionNotification(host: String) -> Notification.Name {
        Notification.Name("\(host).finderContext.action")
    }

    /// Posted by the extension when it starts, asking the app to push the menu.
    static func helloNotification(host: String) -> Notification.Name {
        Notification.Name("\(host).finderContext.hello")
    }

    static func extensionBundleID(host: String) -> String { "\(host).FinderMenu" }

    struct Entry: Codable, Equatable {
        /// Template id for a new file, favorite id for a folder.
        var id: String
        var title: String
        /// Folder path for a favorite; unused for templates.
        var path: String?
    }

    struct Labels: Codable, Equatable {
        var newFile = ""
        var copyPath = ""
        var copyCurrentPath = ""
        var fullPath = ""
        var fileName = ""
        var homePath = ""
        var quotedPath = ""
        var openTerminal = ""
        var favorites = ""
        var openFolder = ""
        var moveHere = ""
        var copyHere = ""
    }

    struct MenuConfig: Codable, Equatable {
        var enabled = false
        var showNewFile = true
        var showCopyPath = true
        var showTerminal = true
        var showFavorites = true
        var labels = Labels()
        var newFiles: [Entry] = []
        var favorites: [Entry] = []

        static let off = MenuConfig()
    }

    enum Kind: String, Codable {
        case newFile, copyPath, openTerminal, openFolder, moveTo, copyTo
    }

    struct Action: Codable, Equatable {
        var kind: Kind
        /// Template id, path style or destination folder, depending on `kind`.
        var argument: String?
        /// The folder the menu was opened in (new file, terminal, open).
        var directory: String?
        /// Selected items, when the menu was opened on some.
        var paths: [String] = []
    }

    static func encode<T: Encodable>(_ value: T) -> String? {
        guard let data = try? JSONEncoder().encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func decode<T: Decodable>(_ type: T.Type, from text: String?) -> T? {
        guard let data = text?.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
