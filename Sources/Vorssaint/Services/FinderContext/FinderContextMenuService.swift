// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Foundation

/// Runs the Finder right-click menu. The menu itself is drawn by a Finder
/// extension inside the app bundle; this service tells that extension what to
/// show and does the work when an entry is clicked, because the extension is
/// sandboxed and cannot create or move the user's files.
final class FinderContextMenuService: ObservableObject {
    static let shared = FinderContextMenuService()

    static let extensionFileName = "VorssaintFinderMenu.appex"

    /// Whether macOS has the Finder extension switched on. Read with pluginkit,
    /// so it is refreshed on demand rather than guessed.
    @Published private(set) var extensionEnabled = false

    private let host = Bundle.main.bundleIdentifier ?? "com.vorssaint.utils"
    private var observing = false
    private var pushWork: DispatchWorkItem?
    private let toolQueue = DispatchQueue(label: "Vorssaint.FinderContext.pluginkit", qos: .utility)

    private var extensionID: String { FinderContextWire.extensionBundleID(host: host) }

    private init() {}

    private var extensionURL: URL {
        Bundle.main.bundleURL.appendingPathComponent("Contents/PlugIns/\(Self.extensionFileName)")
    }

    // MARK: Lifecycle

    func syncWithPreferences() {
        let enabled = AppFeature.finderContextMenu.isAvailable
            && UserDefaults.standard.bool(forKey: DefaultsKey.finderContextEnabled)
        if enabled {
            startObserving()
            switchExtension(on: true)
        } else {
            stopObserving()
            switchExtension(on: false)
        }
        pushConfig()
    }

    private func startObserving() {
        guard !observing else { return }
        observing = true
        let center = DistributedNotificationCenter.default()
        center.addObserver(self, selector: #selector(actionArrived(_:)),
                           name: FinderContextWire.actionNotification(host: host), object: nil,
                           suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(helloArrived(_:)),
                           name: FinderContextWire.helloNotification(host: host), object: nil,
                           suspensionBehavior: .deliverImmediately)
        NotificationCenter.default.addObserver(self, selector: #selector(preferencesChanged),
                                               name: UserDefaults.didChangeNotification, object: nil)
    }

    private func stopObserving() {
        guard observing else { return }
        observing = false
        DistributedNotificationCenter.default().removeObserver(self)
        NotificationCenter.default.removeObserver(self, name: UserDefaults.didChangeNotification, object: nil)
    }

    @objc private func helloArrived(_ note: Notification) {
        DispatchQueue.main.async { self.pushConfig() }
    }

    /// Preferences change often and for unrelated reasons; settle before
    /// telling the extension.
    @objc private func preferencesChanged() {
        pushWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.pushConfig() }
        pushWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    // MARK: Extension registration

    /// Registers the extension and turns it on or off for the user, so there is
    /// normally nothing to switch on by hand in System Settings.
    private func switchExtension(on: Bool) {
        let path = extensionURL.path
        let id = extensionID
        guard FileManager.default.fileExists(atPath: path) else { return }
        toolQueue.async { [weak self] in
            if on { Self.runPluginkit(["-a", path]) }
            Self.runPluginkit(["-e", on ? "use" : "ignore", "-i", id])
            self?.refreshExtensionState()
        }
    }

    func refreshExtensionState() {
        let id = extensionID
        toolQueue.async { [weak self] in
            let output = Self.runPluginkit(["-m", "-A", "-i", id]) ?? ""
            // pluginkit prefixes the line with "+" when the user has it on.
            let enabled = output.split(separator: "\n").contains { $0.hasPrefix("+") && $0.contains(id) }
            DispatchQueue.main.async { self?.extensionEnabled = enabled }
        }
    }

    func openExtensionSettings() {
        let urls = ["x-apple.systempreferences:com.apple.ExtensionsPreferences?extensionPointIdentifier=com.apple.FinderSync",
                    "x-apple.systempreferences:com.apple.LoginItems-Settings.extension"]
        for text in urls {
            if let url = URL(string: text), NSWorkspace.shared.open(url) { return }
        }
    }

    @discardableResult
    private static func runPluginkit(_ arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do { try process.run() } catch { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(data: data, encoding: .utf8)
    }

    // MARK: Preferences

    private var strings: FinderContextFeatureStrings { FeatureStrings.finderContext(L10n.shared.language) }

    static func templates(strings: FinderContextFeatureStrings) -> [FinderContextSupport.Template] {
        FinderContextSupport.decodeTemplates(UserDefaults.standard.data(forKey: DefaultsKey.finderContextTemplates))
            ?? FinderContextSupport.defaultTemplates(defaultNames(strings))
    }

    static func defaultNames(_ s: FinderContextFeatureStrings) -> FinderContextSupport.DefaultNames {
        FinderContextSupport.DefaultNames(text: s.templateText, markdown: s.templateMarkdown,
                                          richText: s.templateRichText, word: s.templateWord,
                                          excel: s.templateExcel, powerPoint: s.templatePowerPoint,
                                          wpsWriter: s.templateWPSWriter, wpsSheet: s.templateWPSSheet,
                                          wpsPresentation: s.templateWPSPresentation)
    }

    static func favorites() -> [FinderContextSupport.Favorite] {
        FinderContextSupport.decodeFavorites(UserDefaults.standard.data(forKey: DefaultsKey.finderContextFavorites))
    }

    // MARK: Pushing the menu

    func menuConfig() -> FinderContextWire.MenuConfig {
        let defaults = UserDefaults.standard
        let enabled = AppFeature.finderContextMenu.isAvailable
            && defaults.bool(forKey: DefaultsKey.finderContextEnabled)
        guard enabled else { return .off }
        let s = strings
        var config = FinderContextWire.MenuConfig()
        config.enabled = true
        config.showNewFile = defaults.bool(forKey: DefaultsKey.finderContextShowNewFile)
        config.showCopyPath = defaults.bool(forKey: DefaultsKey.finderContextShowCopyPath)
        config.showTerminal = defaults.bool(forKey: DefaultsKey.finderContextShowTerminal)
        config.showFavorites = defaults.bool(forKey: DefaultsKey.finderContextShowFavorites)
        config.labels = .init(newFile: s.menuNewFile, copyPath: s.menuCopyPath,
                              copyCurrentPath: s.menuCopyCurrentPath, fullPath: s.menuFullPath,
                              fileName: s.menuFileName, homePath: s.menuHomePath,
                              quotedPath: s.menuQuotedPath, openTerminal: s.menuOpenTerminal,
                              favorites: s.menuFavorites, openFolder: s.menuOpenFolder,
                              moveHere: s.menuMoveHere, copyHere: s.menuCopyHere)
        config.newFiles = Self.templates(strings: s).map {
            .init(id: $0.id, title: "\($0.name) (.\($0.ext))", path: nil)
        }
        config.favorites = Self.favorites().map { .init(id: $0.id, title: $0.name, path: $0.path) }
        return config
    }

    private var lastPushed: String?

    func pushConfig() {
        guard let text = FinderContextWire.encode(menuConfig()) else { return }
        guard text != lastPushed else { return }
        lastPushed = text
        DistributedNotificationCenter.default().postNotificationName(
            FinderContextWire.configNotification(host: host), object: text,
            userInfo: nil, deliverImmediately: true)
    }

    // MARK: Actions

    @objc private func actionArrived(_ note: Notification) {
        guard let action = FinderContextWire.decode(FinderContextWire.Action.self, from: note.object as? String)
        else { return }
        DispatchQueue.main.async { self.perform(action) }
    }

    func perform(_ action: FinderContextWire.Action) {
        guard menuConfig().enabled else { return }
        let s = strings
        switch action.kind {
        case .newFile:
            guard let directory = action.directory,
                  let template = Self.templates(strings: s).first(where: { $0.id == action.argument }) else { return }
            do {
                let url = try FinderContextSupport.createFile(from: template,
                                                              in: URL(fileURLWithPath: directory),
                                                              baseName: s.untitledName)
                NSWorkspace.shared.activateFileViewerSelecting([url])
            } catch {
                QuickToolHUD.show(icon: "exclamationmark.triangle", message: s.createFailed)
            }
        case .copyPath:
            let style = FinderContextSupport.PathStyle(rawValue: action.argument ?? "") ?? .full
            let text = FinderContextSupport.pathText(action.paths, style: style)
            guard !text.isEmpty else { return }
            GeneralPasteboardAccess.shared.async({
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            }, then: { _ in
                QuickToolHUD.show(icon: "doc.on.doc", message: s.pathCopied)
            })
        case .openTerminal:
            guard let directory = FinderContextSupport.terminalDirectory(directory: action.directory,
                                                                         paths: action.paths) else { return }
            openTerminal(at: directory, failure: s.terminalFailed)
        case .openFolder:
            guard let directory = action.directory else { return }
            NSWorkspace.shared.open(URL(fileURLWithPath: directory))
        case .moveTo, .copyTo:
            guard let destination = action.argument, !action.paths.isEmpty else { return }
            let sources = action.paths.map { URL(fileURLWithPath: $0) }
            let move = action.kind == .moveTo
            DispatchQueue.global(qos: .userInitiated).async {
                let result = FinderContextSupport.transfer(sources, to: URL(fileURLWithPath: destination),
                                                           move: move)
                DispatchQueue.main.async {
                    if !result.failed.isEmpty {
                        QuickToolHUD.show(icon: "exclamationmark.triangle", message: s.transferFailed)
                    } else if !result.moved.isEmpty {
                        NSWorkspace.shared.activateFileViewerSelecting(result.moved)
                    }
                }
            }
        }
    }

    private func openTerminal(at directory: String, failure: String) {
        let terminal = FinderContextSupport.Terminal.sanitized(
            UserDefaults.standard.string(forKey: DefaultsKey.finderContextTerminal))
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", terminal.appName, directory]
        process.standardError = Pipe()
        process.terminationHandler = { finished in
            if finished.terminationStatus != 0 {
                DispatchQueue.main.async { QuickToolHUD.show(icon: "exclamationmark.triangle", message: failure) }
            }
        }
        do { try process.run() } catch {
            QuickToolHUD.show(icon: "exclamationmark.triangle", message: failure)
        }
    }
}
