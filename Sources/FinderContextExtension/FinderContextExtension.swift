// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Cocoa
import FinderSync

/// Adds Vorssaint's entries to the end of Finder's right-click menu. Finder's
/// own entries are never touched. The extension holds no logic of its own: it
/// shows the menu the app last sent and reports clicks back to the app.
final class FinderContextExtension: FIFinderSync {
    private static let cacheKey = "menuConfig"

    private let host: String
    private var config: FinderContextWire.MenuConfig
    /// Actions of the menu on screen, indexed by menu item tag.
    private var pending: [FinderContextWire.Action] = []

    override init() {
        host = Bundle.main.object(forInfoDictionaryKey: FinderContextWire.hostBundleIDInfoKey) as? String
            ?? "com.vorssaint.utils"
        config = FinderContextWire.decode(FinderContextWire.MenuConfig.self,
                                          from: UserDefaults.standard.string(forKey: Self.cacheKey))
            ?? .off
        super.init()

        // Finder only asks for a menu inside watched folders; watching the
        // root covers every folder and volume.
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]

        let center = DistributedNotificationCenter.default()
        center.addObserver(self, selector: #selector(configArrived(_:)),
                           name: FinderContextWire.configNotification(host: host), object: nil,
                           suspensionBehavior: .deliverImmediately)
        // The app may have started first; ask it to say its menu again.
        center.postNotificationName(FinderContextWire.helloNotification(host: host), object: nil,
                                    userInfo: nil, deliverImmediately: true)
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
    }

    @objc private func configArrived(_ note: Notification) {
        guard let text = note.object as? String,
              let new = FinderContextWire.decode(FinderContextWire.MenuConfig.self, from: text) else { return }
        config = new
        UserDefaults.standard.set(text, forKey: Self.cacheKey)
    }

    // MARK: Menu

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard config.enabled else { return nil }
        let controller = FIFinderSyncController.default()
        pending = []
        let menu = NSMenu(title: "")

        switch menuKind {
        case .contextualMenuForContainer:
            guard let folder = controller.targetedURL()?.path else { return nil }
            addContainerItems(to: menu, folder: folder)
        case .contextualMenuForItems:
            let selected = controller.selectedItemURLs() ?? []
            guard !selected.isEmpty else { return nil }
            addItemItems(to: menu, selected: selected.map(\.path))
        default:
            return nil
        }
        return menu.items.isEmpty ? nil : menu
    }

    private func addContainerItems(to menu: NSMenu, folder: String) {
        let l = config.labels
        if config.showNewFile, !config.newFiles.isEmpty {
            let sub = NSMenu(title: l.newFile)
            for entry in config.newFiles {
                sub.addItem(item(entry.title,
                                 .init(kind: .newFile, argument: entry.id, directory: folder)))
            }
            menu.addItem(submenu(l.newFile, symbol: "doc.badge.plus", sub))
        }
        if config.showCopyPath {
            menu.addItem(item(l.copyCurrentPath, symbol: "doc.on.doc",
                              .init(kind: .copyPath, argument: "full", directory: folder, paths: [folder])))
        }
        if config.showTerminal {
            menu.addItem(item(l.openTerminal, symbol: "terminal",
                              .init(kind: .openTerminal, directory: folder)))
        }
        if config.showFavorites, !config.favorites.isEmpty {
            let sub = NSMenu(title: l.favorites)
            for fav in config.favorites {
                guard let path = fav.path else { continue }
                sub.addItem(item(fav.title, symbol: "folder",
                                 .init(kind: .openFolder, directory: path)))
            }
            menu.addItem(submenu(l.favorites, symbol: "star", sub))
        }
    }

    private func addItemItems(to menu: NSMenu, selected: [String]) {
        let l = config.labels
        if config.showCopyPath {
            let sub = NSMenu(title: l.copyPath)
            for (title, style) in [(l.fullPath, "full"), (l.fileName, "name"),
                                   (l.homePath, "home"), (l.quotedPath, "quoted")] {
                sub.addItem(item(title, .init(kind: .copyPath, argument: style, paths: selected)))
            }
            menu.addItem(submenu(l.copyPath, symbol: "doc.on.doc", sub))
        }
        if config.showTerminal {
            menu.addItem(item(l.openTerminal, symbol: "terminal",
                              .init(kind: .openTerminal, paths: selected)))
        }
        if config.showFavorites, !config.favorites.isEmpty {
            let sub = NSMenu(title: l.favorites)
            for fav in config.favorites {
                guard let path = fav.path else { continue }
                let folder = NSMenu(title: fav.title)
                folder.addItem(item(l.openFolder, .init(kind: .openFolder, directory: path)))
                folder.addItem(.separator())
                folder.addItem(item(l.moveHere, .init(kind: .moveTo, argument: path, paths: selected)))
                folder.addItem(item(l.copyHere, .init(kind: .copyTo, argument: path, paths: selected)))
                sub.addItem(submenu(fav.title, symbol: "folder", folder))
            }
            menu.addItem(submenu(l.favorites, symbol: "star", sub))
        }
    }

    private func item(_ title: String, symbol: String? = nil,
                      _ action: FinderContextWire.Action) -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: #selector(clicked(_:)), keyEquivalent: "")
        menuItem.target = self
        menuItem.tag = pending.count
        pending.append(action)
        if let symbol { menuItem.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) }
        return menuItem
    }

    private func submenu(_ title: String, symbol: String, _ sub: NSMenu) -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        menuItem.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        menuItem.submenu = sub
        return menuItem
    }

    @objc private func clicked(_ sender: NSMenuItem) {
        guard pending.indices.contains(sender.tag),
              let text = FinderContextWire.encode(pending[sender.tag]) else { return }
        DistributedNotificationCenter.default().postNotificationName(
            FinderContextWire.actionNotification(host: host), object: text,
            userInfo: nil, deliverImmediately: true)
    }
}
