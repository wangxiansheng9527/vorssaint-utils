// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI

struct FinderContextSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var service = FinderContextMenuService.shared
    @AppStorage(DefaultsKey.finderContextEnabled) private var enabled = true
    @AppStorage(DefaultsKey.finderContextShowNewFile) private var showNewFile = true
    @AppStorage(DefaultsKey.finderContextShowCopyPath) private var showCopyPath = true
    @AppStorage(DefaultsKey.finderContextShowTerminal) private var showTerminal = true
    @AppStorage(DefaultsKey.finderContextShowFavorites) private var showFavorites = true
    @AppStorage(DefaultsKey.finderContextTerminal) private var terminalRaw =
        FinderContextSupport.Terminal.terminal.rawValue
    @State private var templates: [FinderContextSupport.Template] = []
    @State private var favorites: [FinderContextSupport.Favorite] = []
    @State private var loaded = false

    private var strings: FinderContextFeatureStrings { FeatureStrings.finderContext(l10n.language) }

    var body: some View {
        Form {
            Section {
                Toggle(strings.enableLabel, isOn: $enabled)
                    .onChange(of: enabled) { _, _ in service.syncWithPreferences() }
                Text(strings.caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Text(strings.extensionStatusTitle)
                    Spacer()
                    if service.extensionEnabled {
                        Label(strings.extensionOn, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Text(strings.extensionOff)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                    Button(strings.openExtensionSettings) { service.openExtensionSettings() }
                }
            }

            Section(strings.menuItemsTitle) {
                Toggle(strings.newFileToggle, isOn: $showNewFile)
                Toggle(strings.copyPathToggle, isOn: $showCopyPath)
                Toggle(strings.terminalToggle, isOn: $showTerminal)
                Toggle(strings.favoritesToggle, isOn: $showFavorites)
            }

            Section(strings.newFilesTitle) {
                ForEach($templates) { $template in
                    templateRow($template)
                }
                HStack {
                    Button(strings.addTemplate) {
                        templates.append(.init(id: UUID().uuidString, name: "", ext: "",
                                               kind: .empty, value: nil))
                    }
                    Button(strings.resetTemplates) {
                        UserDefaults.standard.removeObject(forKey: DefaultsKey.finderContextTemplates)
                        templates = FinderContextMenuService.templates(strings: strings)
                    }
                }
                Text(strings.templatesCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(strings.favoritesTitle) {
                if favorites.isEmpty {
                    Text(strings.favoritesEmpty).foregroundStyle(.secondary)
                }
                ForEach($favorites) { $favorite in
                    favoriteRow($favorite)
                }
                Button(strings.addFolder) { addFolders() }
                Text(strings.favoritesCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(strings.terminalTitle) {
                Picker(strings.terminalLabel, selection: $terminalRaw) {
                    ForEach(FinderContextSupport.Terminal.allCases) { terminal in
                        Text(terminal.appName).tag(terminal.rawValue)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            if !loaded {
                templates = FinderContextMenuService.templates(strings: strings)
                favorites = FinderContextMenuService.favorites()
                loaded = true
            }
            service.refreshExtensionState()
        }
        .onChange(of: templates) { _, new in save(new, key: DefaultsKey.finderContextTemplates) }
        .onChange(of: favorites) { _, new in save(new, key: DefaultsKey.finderContextFavorites) }
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        guard loaded, let data = FinderContextSupport.encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    // MARK: Rows

    private func templateRow(_ template: Binding<FinderContextSupport.Template>) -> some View {
        HStack(spacing: 8) {
            TextField("", text: template.name, prompt: Text(strings.templateNamePlaceholder))
                .textFieldStyle(.roundedBorder)
                .labelsHidden()
            TextField("", text: Binding(
                get: { template.wrappedValue.ext },
                set: { template.wrappedValue.ext = FinderContextSupport.sanitizedExtension($0) }
            ), prompt: Text(strings.templateExtensionPlaceholder))
                .textFieldStyle(.roundedBorder)
                .labelsHidden()
                .frame(width: 90)
            Button {
                chooseFile(for: template)
            } label: {
                Image(systemName: template.wrappedValue.kind == .file ? "doc.fill" : "doc")
            }
            .buttonStyle(.plain)
            .help(template.wrappedValue.kind == .file
                  ? (template.wrappedValue.value ?? strings.chooseTemplateFile) : strings.chooseTemplateFile)
            reorderButtons(for: template.wrappedValue.id, in: $templates)
        }
    }

    private func favoriteRow(_ favorite: Binding<FinderContextSupport.Favorite>) -> some View {
        HStack(spacing: 8) {
            TextField("", text: favorite.name, prompt: Text(strings.templateNamePlaceholder))
                .textFieldStyle(.roundedBorder)
                .labelsHidden()
                .frame(maxWidth: 180)
            Text(favorite.wrappedValue.path)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 0)
            reorderButtons(for: favorite.wrappedValue.id, in: $favorites)
        }
    }

    private func reorderButtons<Item: Identifiable>(for id: Item.ID, in list: Binding<[Item]>) -> some View {
        HStack(spacing: 4) {
            Button { move(id, by: -1, in: list) } label: { Image(systemName: "chevron.up") }
                .help(strings.moveUp)
            Button { move(id, by: 1, in: list) } label: { Image(systemName: "chevron.down") }
                .help(strings.moveDown)
            Button { list.wrappedValue.removeAll { $0.id == id } } label: { Image(systemName: "minus.circle") }
                .help(strings.remove)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }

    private func move<Item: Identifiable>(_ id: Item.ID, by offset: Int, in list: Binding<[Item]>) {
        guard let index = list.wrappedValue.firstIndex(where: { $0.id == id }) else { return }
        let target = index + offset
        guard list.wrappedValue.indices.contains(target) else { return }
        list.wrappedValue.swapAt(index, target)
    }

    // MARK: Pickers

    private func chooseFile(for template: Binding<FinderContextSupport.Template>) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        template.wrappedValue.kind = .file
        template.wrappedValue.value = url.path
        if template.wrappedValue.ext.isEmpty {
            template.wrappedValue.ext = url.pathExtension
        }
        if template.wrappedValue.name.isEmpty {
            template.wrappedValue.name = url.deletingPathExtension().lastPathComponent
        }
    }

    private func addFolders() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        for url in panel.urls where !favorites.contains(where: { $0.path == url.path }) {
            favorites.append(FinderContextSupport.favorite(forFolder: url))
        }
    }
}
