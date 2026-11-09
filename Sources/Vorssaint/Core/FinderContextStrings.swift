// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct FinderContextFeatureStrings {
    let pageTitle: String
    let hubTitle: String
    let hubDescription: String
    let enableLabel: String
    let caption: String
    let extensionStatusTitle: String
    let extensionOn: String
    let extensionOff: String
    let openExtensionSettings: String
    let menuItemsTitle: String
    let newFileToggle: String
    let copyPathToggle: String
    let terminalToggle: String
    let favoritesToggle: String
    let newFilesTitle: String
    let templateNamePlaceholder: String
    let templateExtensionPlaceholder: String
    let addTemplate: String
    let chooseTemplateFile: String
    let resetTemplates: String
    let remove: String
    let moveUp: String
    let moveDown: String
    let templatesCaption: String
    let favoritesTitle: String
    let addFolder: String
    let favoritesEmpty: String
    let favoritesCaption: String
    let terminalTitle: String
    let terminalLabel: String
    // Entries of the Finder menu itself.
    let menuNewFile: String
    let menuCopyPath: String
    let menuCopyCurrentPath: String
    let menuFullPath: String
    let menuFileName: String
    let menuHomePath: String
    let menuQuotedPath: String
    let menuOpenTerminal: String
    let menuFavorites: String
    let menuOpenFolder: String
    let menuMoveHere: String
    let menuCopyHere: String
    // Results.
    let untitledName: String
    let pathCopied: String
    let createFailed: String
    let transferFailed: String
    let terminalFailed: String
    // Names of the built-in templates.
    let templateText: String
    let templateMarkdown: String
    let templateRichText: String
    let templateWord: String
    let templateExcel: String
    let templatePowerPoint: String
    let templateWPSWriter: String
    let templateWPSSheet: String
    let templateWPSPresentation: String
}

extension FeatureStrings {
    static func finderContext(_ language: AppLanguage) -> FinderContextFeatureStrings {
        switch language {
        case .zhHans: return .zhHans
        case .zhTW, .zhHK: return .zhTW
        // Other languages show the English text until someone translates it.
        case .enUS, .ptBR, .tr, .ru, .es, .sk, .de, .fr, .it, .ja, .ko, .uk: return .enUS
        }
    }
}

extension FinderContextFeatureStrings {
    static let enUS = FinderContextFeatureStrings(
        pageTitle: "Finder right-click menu",
        hubTitle: "Finder right-click menu",
        hubDescription: "Add new file, copy path, open in Terminal and favorite folders to Finder’s right-click menu.",
        enableLabel: "Add Vorssaint to Finder’s right-click menu",
        caption: "Finder’s own entries stay exactly as they are. Ours are added at the end of the menu.",
        extensionStatusTitle: "Finder extension",
        extensionOn: "Enabled",
        extensionOff: "Not enabled yet. Turn on the Finder extension in System Settings.",
        openExtensionSettings: "Open Extension Settings",
        menuItemsTitle: "Menu entries",
        newFileToggle: "New file",
        copyPathToggle: "Copy path",
        terminalToggle: "Open in terminal",
        favoritesToggle: "Favorite folders",
        newFilesTitle: "New file templates",
        templateNamePlaceholder: "Name",
        templateExtensionPlaceholder: "Extension",
        addTemplate: "Add template",
        chooseTemplateFile: "Choose template file…",
        resetTemplates: "Restore default templates",
        remove: "Remove",
        moveUp: "Move up",
        moveDown: "Move down",
        templatesCaption: "A template made from a file copies that file every time. Without one, a blank file with the extension is created.",
        favoritesTitle: "Favorite folders",
        addFolder: "Add folder…",
        favoritesEmpty: "No favorite folders yet.",
        favoritesCaption: "Open a favorite from the background of a folder, or move or copy the selected files into it.",
        terminalTitle: "Terminal",
        terminalLabel: "Open with",
        menuNewFile: "New File",
        menuCopyPath: "Copy Path",
        menuCopyCurrentPath: "Copy Current Path",
        menuFullPath: "Full path",
        menuFileName: "File name",
        menuHomePath: "Path starting with ~",
        menuQuotedPath: "Path in quotes (for Terminal)",
        menuOpenTerminal: "Open in Terminal",
        menuFavorites: "Favorite Folders",
        menuOpenFolder: "Open",
        menuMoveHere: "Move Selection Here",
        menuCopyHere: "Copy Selection Here",
        untitledName: "Untitled",
        pathCopied: "Path copied",
        createFailed: "Could not create the file here",
        transferFailed: "Some items could not be moved or copied",
        terminalFailed: "Could not open the terminal app",
        templateText: "Text",
        templateMarkdown: "Markdown",
        templateRichText: "Rich Text",
        templateWord: "Word",
        templateExcel: "Excel",
        templatePowerPoint: "PowerPoint",
        templateWPSWriter: "WPS Writer",
        templateWPSSheet: "WPS Spreadsheet",
        templateWPSPresentation: "WPS Presentation"
    )

    static let zhHans = FinderContextFeatureStrings(
        pageTitle: "Finder 右键菜单",
        hubTitle: "Finder 右键菜单",
        hubDescription: "在 Finder 右键菜单中加入新建文件、拷贝路径、在终端打开和常用目录。",
        enableLabel: "在 Finder 右键菜单中加入 Vorssaint",
        caption: "Finder 原有的菜单项保持不变，我们的菜单项会加在菜单末尾。",
        extensionStatusTitle: "Finder 扩展",
        extensionOn: "已启用",
        extensionOff: "尚未启用。请在系统设置中打开 Finder 扩展。",
        openExtensionSettings: "打开扩展设置",
        menuItemsTitle: "菜单项",
        newFileToggle: "新建文件",
        copyPathToggle: "拷贝路径",
        terminalToggle: "在终端打开",
        favoritesToggle: "常用目录",
        newFilesTitle: "新建文件模板",
        templateNamePlaceholder: "名称",
        templateExtensionPlaceholder: "扩展名",
        addTemplate: "添加模板",
        chooseTemplateFile: "选择模板文件…",
        resetTemplates: "恢复默认模板",
        remove: "删除",
        moveUp: "上移",
        moveDown: "下移",
        templatesCaption: "由文件生成的模板每次都会复制该文件；否则会按扩展名创建一个空白文件。",
        favoritesTitle: "常用目录",
        addFolder: "添加目录…",
        favoritesEmpty: "还没有常用目录。",
        favoritesCaption: "可在文件夹空白处直接打开常用目录，也可把选中的文件移动或拷贝到其中。",
        terminalTitle: "终端",
        terminalLabel: "使用",
        menuNewFile: "新建文件",
        menuCopyPath: "拷贝路径",
        menuCopyCurrentPath: "拷贝当前路径",
        menuFullPath: "完整路径",
        menuFileName: "文件名",
        menuHomePath: "以 ~ 开头的路径",
        menuQuotedPath: "带引号的路径（用于终端）",
        menuOpenTerminal: "在终端打开",
        menuFavorites: "常用目录",
        menuOpenFolder: "打开",
        menuMoveHere: "移动选中项到这里",
        menuCopyHere: "拷贝选中项到这里",
        untitledName: "未命名",
        pathCopied: "路径已拷贝",
        createFailed: "无法在此处创建文件",
        transferFailed: "部分项目无法移动或拷贝",
        terminalFailed: "无法打开终端应用",
        templateText: "文本",
        templateMarkdown: "Markdown",
        templateRichText: "富文本",
        templateWord: "Word 文档",
        templateExcel: "Excel 表格",
        templatePowerPoint: "PowerPoint 演示",
        templateWPSWriter: "WPS 文字",
        templateWPSSheet: "WPS 表格",
        templateWPSPresentation: "WPS 演示"
    )

    static let zhTW = FinderContextFeatureStrings(
        pageTitle: "Finder 右鍵選單",
        hubTitle: "Finder 右鍵選單",
        hubDescription: "在 Finder 右鍵選單中加入新增檔案、拷貝路徑、在終端機打開和常用目錄。",
        enableLabel: "在 Finder 右鍵選單中加入 Vorssaint",
        caption: "Finder 原有的選單項目保持不變，我們的項目會加在選單末尾。",
        extensionStatusTitle: "Finder 延伸功能",
        extensionOn: "已啟用",
        extensionOff: "尚未啟用。請在系統設定中開啟 Finder 延伸功能。",
        openExtensionSettings: "打開延伸功能設定",
        menuItemsTitle: "選單項目",
        newFileToggle: "新增檔案",
        copyPathToggle: "拷貝路徑",
        terminalToggle: "在終端機打開",
        favoritesToggle: "常用目錄",
        newFilesTitle: "新增檔案範本",
        templateNamePlaceholder: "名稱",
        templateExtensionPlaceholder: "副檔名",
        addTemplate: "加入範本",
        chooseTemplateFile: "選擇範本檔案…",
        resetTemplates: "還原預設範本",
        remove: "移除",
        moveUp: "上移",
        moveDown: "下移",
        templatesCaption: "由檔案產生的範本每次都會拷貝該檔案；否則會依副檔名建立空白檔案。",
        favoritesTitle: "常用目錄",
        addFolder: "加入目錄…",
        favoritesEmpty: "還沒有常用目錄。",
        favoritesCaption: "可在資料夾空白處直接打開常用目錄，也可把選取的檔案移動或拷貝到其中。",
        terminalTitle: "終端機",
        terminalLabel: "使用",
        menuNewFile: "新增檔案",
        menuCopyPath: "拷貝路徑",
        menuCopyCurrentPath: "拷貝目前路徑",
        menuFullPath: "完整路徑",
        menuFileName: "檔案名稱",
        menuHomePath: "以 ~ 開頭的路徑",
        menuQuotedPath: "帶引號的路徑（用於終端機）",
        menuOpenTerminal: "在終端機打開",
        menuFavorites: "常用目錄",
        menuOpenFolder: "打開",
        menuMoveHere: "移動所選項目到這裡",
        menuCopyHere: "拷貝所選項目到這裡",
        untitledName: "未命名",
        pathCopied: "路徑已拷貝",
        createFailed: "無法在此處建立檔案",
        transferFailed: "部分項目無法移動或拷貝",
        terminalFailed: "無法打開終端機應用程式",
        templateText: "文字",
        templateMarkdown: "Markdown",
        templateRichText: "富文字",
        templateWord: "Word 文件",
        templateExcel: "Excel 試算表",
        templatePowerPoint: "PowerPoint 簡報",
        templateWPSWriter: "WPS 文字",
        templateWPSSheet: "WPS 表格",
        templateWPSPresentation: "WPS 演示"
    )
}
