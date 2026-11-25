// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct BeijingClockFeatureStrings {
    let pageTitle: String
    let hubTitle: String
    let hubDescription: String
    let enableLabel: String
    let caption: String
    let previewTitle: String
    let localDiffPrefix: String
    let placementLabel: String
    let placementIsland: String
    let placementMenuBar: String
    let prefixLabel: String
    let prefixBeijing: String
    let prefixBJ: String
    let prefixNone: String
    let use24HourLabel: String
    let showSecondsLabel: String
    let showWeekdayLabel: String
    let showDayOffsetLabel: String
    let showDateLabel: String
    let tomorrowTag: String
    let yesterdayTag: String
    let dayOffsetAheadFormat: String
    let dayOffsetBehindFormat: String
    let aheadFormat: String
    let behindFormat: String
    let sameTimeAsLocal: String
    let hourUnitSingular: String
    let hourUnitPlural: String
    let minuteUnitSingular: String
    let minuteUnitPlural: String
    let copyTimeFormat: String
    let copyFullFormat: String
    let copiedHUDFormat: String
    let openSettings: String
    let tooltipHeaderFormat: String
}

extension FeatureStrings {
    static func beijingClock(_ language: AppLanguage) -> BeijingClockFeatureStrings {
        switch language {
        case .zhHans: return .zhHans
        case .zhTW, .zhHK: return .zhTW
        case .enUS, .ptBR, .tr, .ru, .es, .sk, .de, .fr, .it, .ja, .ko, .uk: return .enUS
        }
    }
}

extension BeijingClockFeatureStrings {
    static let enUS = BeijingClockFeatureStrings(
        pageTitle: "Beijing Time",
        hubTitle: "Beijing Time",
        hubDescription: "Keep Beijing Time (UTC+8) visible at the top center or in the menu bar regardless of your Mac’s system time zone.",
        enableLabel: "Show Beijing Time",
        caption: "Useful when your Mac uses another time zone (such as US time) and you want China Standard Time always at a glance.",
        previewTitle: "Preview",
        localDiffPrefix: "vs. Mac time",
        placementLabel: "Position",
        placementIsland: "Top center (Island)",
        placementMenuBar: "Menu bar right",
        prefixLabel: "Label",
        prefixBeijing: "北京",
        prefixBJ: "BJ",
        prefixNone: "None",
        use24HourLabel: "Use 24-hour clock",
        showSecondsLabel: "Show seconds",
        showWeekdayLabel: "Show weekday",
        showDayOffsetLabel: "Show day difference (+1d / -1d)",
        showDateLabel: "Show date",
        tomorrowTag: "+1d",
        yesterdayTag: "-1d",
        dayOffsetAheadFormat: "+%dd",
        dayOffsetBehindFormat: "-%dd",
        aheadFormat: "%@ ahead of Mac time",
        behindFormat: "%@ behind Mac time",
        sameTimeAsLocal: "Same as Mac time",
        hourUnitSingular: "%d hr",
        hourUnitPlural: "%d hrs",
        minuteUnitSingular: "%d min",
        minuteUnitPlural: "%d mins",
        copyTimeFormat: "Copy Time (%@)",
        copyFullFormat: "Copy Date & Time (%@)",
        copiedHUDFormat: "Copied %@",
        openSettings: "Beijing Time Settings…",
        tooltipHeaderFormat: "Beijing Time (UTC+8): %@"
    )

    static let zhHans = BeijingClockFeatureStrings(
        pageTitle: "常驻北京时间",
        hubTitle: "常驻北京时间",
        hubDescription: "无论 Mac 当前使用哪个系统时区，都在顶部正中灵动岛位置或菜单栏常驻显示北京时间 (UTC+8)。",
        enableLabel: "常驻显示北京时间",
        caption: "适合把 Mac 设为美国等其他时区时，在屏幕顶部随时一眼查看北京时间和星期。",
        previewTitle: "当前效果预览",
        localDiffPrefix: "与本机时差",
        placementLabel: "显示位置",
        placementIsland: "灵动岛位置（顶部正中）",
        placementMenuBar: "菜单栏右侧",
        prefixLabel: "前缀标签",
        prefixBeijing: "北京",
        prefixBJ: "BJ",
        prefixNone: "无前缀",
        use24HourLabel: "使用 24 小时制",
        showSecondsLabel: "显示秒数",
        showWeekdayLabel: "显示周几",
        showDayOffsetLabel: "与本机日期不同时显示跨天提示",
        showDateLabel: "显示日期",
        tomorrowTag: "明天",
        yesterdayTag: "昨天",
        dayOffsetAheadFormat: "+%d天",
        dayOffsetBehindFormat: "-%d天",
        aheadFormat: "比当前系统时间快 %@",
        behindFormat: "比当前系统时间慢 %@",
        sameTimeAsLocal: "与当前系统时间一致",
        hourUnitSingular: "%d 小时",
        hourUnitPlural: "%d 小时",
        minuteUnitSingular: "%d 分钟",
        minuteUnitPlural: "%d 分钟",
        copyTimeFormat: "复制北京时间 (%@)",
        copyFullFormat: "复制完整日期时间 (%@)",
        copiedHUDFormat: "已复制 %@",
        openSettings: "北京时间设置…",
        tooltipHeaderFormat: "北京时间 (UTC+8)：%@"
    )

    static let zhTW = BeijingClockFeatureStrings(
        pageTitle: "常駐北京時間",
        hubTitle: "常駐北京時間",
        hubDescription: "無論 Mac 目前使用哪個系統時區，都在螢幕頂部正中動態島位置或選單列常駐顯示北京時間 (UTC+8)。",
        enableLabel: "常駐顯示北京時間",
        caption: "適合將 Mac 設為美國等其他時區時，隨時一眼查看北京時間與星期。",
        previewTitle: "目前效果預覽",
        localDiffPrefix: "與本機時差",
        placementLabel: "顯示位置",
        placementIsland: "動態島位置（頂部正中）",
        placementMenuBar: "選單列右側",
        prefixLabel: "前綴標籤",
        prefixBeijing: "北京",
        prefixBJ: "BJ",
        prefixNone: "無前綴",
        use24HourLabel: "使用 24 小時制",
        showSecondsLabel: "顯示秒數",
        showWeekdayLabel: "顯示星期幾",
        showDayOffsetLabel: "與本機日期不同時顯示跨日提示",
        showDateLabel: "顯示日期",
        tomorrowTag: "明天",
        yesterdayTag: "昨天",
        dayOffsetAheadFormat: "+%d天",
        dayOffsetBehindFormat: "-%d天",
        aheadFormat: "比目前系統時間快 %@",
        behindFormat: "比目前系統時間慢 %@",
        sameTimeAsLocal: "與目前系統時間一致",
        hourUnitSingular: "%d 小時",
        hourUnitPlural: "%d 小時",
        minuteUnitSingular: "%d 分鐘",
        minuteUnitPlural: "%d 分鐘",
        copyTimeFormat: "複製北京時間 (%@)",
        copyFullFormat: "複製完整日期時間 (%@)",
        copiedHUDFormat: "已複製 %@",
        openSettings: "北京時間設定…",
        tooltipHeaderFormat: "北京時間 (UTC+8)：%@"
    )
}
