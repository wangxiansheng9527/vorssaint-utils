// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import CoreGraphics
import Foundation

enum BeijingClockTests {
    static func run(_ suite: TestSuite) {
        let beijingTZ = BeijingClockSupport.timeZone
        let laTZ = TimeZone(identifier: "America/Los_Angeles")!
        let nyTZ = TimeZone(identifier: "America/New_York")!

        var bjCal = Calendar(identifier: .gregorian)
        bjCal.timeZone = beijingTZ

        // 2026-11-25 (Wednesday) 10:05:30 CST (UTC+8) = 2026-11-24 18:05:30 PST (UTC-8)
        let morningBeijing = bjCal.date(from: DateComponents(
            year: 2026, month: 11, day: 25, hour: 10, minute: 5, second: 30
        ))!
        suite.expect(BeijingClockSupport.calendarDayOffset(now: morningBeijing, localTimeZone: laTZ) == 1,
                     "10:05 in Beijing is the next calendar day compared to Los Angeles")
        suite.expect(BeijingClockSupport.calendarDayOffset(now: morningBeijing, localTimeZone: beijingTZ) == 0,
                     "same time zone has zero day offset")

        let defaultOptions = BeijingClockSupport.DisplayOptions()
        suite.expect(defaultOptions.placement == .island
                     && defaultOptions.showWeekday
                     && !defaultOptions.showDayOffset,
                     "defaults show top-center island placement with weekday and without tomorrow tag")
        suite.expect(BeijingClockSupport.menuBarText(
            now: morningBeijing, localTimeZone: laTZ, language: .zhHans, options: defaultOptions
        ) == "北京 10:05 周三",
                     "default Chinese clock shows prefix, 24h time, and Beijing weekday without tomorrow tag")
        suite.expect(BeijingClockSupport.menuBarText(
            now: morningBeijing, localTimeZone: laTZ, language: .enUS, options: defaultOptions
        ) == "北京 10:05 Wed",
                     "default English clock shows Beijing weekday")

        let bjOptions = BeijingClockSupport.DisplayOptions(
            placement: .menuBar,
            prefixStyle: .bj,
            use24Hour: false,
            showSeconds: true,
            showWeekday: false,
            showDayOffset: true,
            showDate: true
        )
        suite.expect(BeijingClockSupport.menuBarText(
            now: morningBeijing, localTimeZone: laTZ, language: .enUS, options: bjOptions
        ) == "BJ 11/25 10:05:30 AM +1d",
                     "custom options render BJ prefix, date, 12h seconds, and optional day offset")

        let noneOptions = BeijingClockSupport.DisplayOptions(
            placement: .menuBar,
            prefixStyle: .none,
            use24Hour: true,
            showSeconds: false,
            showWeekday: false,
            showDayOffset: true,
            showDate: false
        )
        // 2026-11-25 23:45:00 CST = 2026-11-25 10:45:00 EST (same calendar day)
        let nightBeijing = bjCal.date(from: DateComponents(
            year: 2026, month: 11, day: 25, hour: 23, minute: 45, second: 0
        ))!
        suite.expect(BeijingClockSupport.calendarDayOffset(now: nightBeijing, localTimeZone: nyTZ) == 0
                     && BeijingClockSupport.menuBarText(
                        now: nightBeijing, localTimeZone: nyTZ, language: .zhHans, options: noneOptions
                     ) == "23:45",
                     "same calendar day omits day offset tag and bare mode shows only time")

        suite.expect(BeijingClockSupport.PrefixStyle.sanitized("invalid") == .beijing
                     && BeijingClockSupport.PrefixStyle.sanitized("bj") == .bj
                     && BeijingClockSupport.PrefixStyle.sanitized("none") == .none,
                     "prefix style sanitization falls back to beijing")
        suite.expect(BeijingClockSupport.Placement.sanitized("invalid") == .island
                     && BeijingClockSupport.Placement.sanitized("menuBar") == .menuBar,
                     "placement sanitization falls back to top-center island")

        // Non-notched 1440x900 display with 24pt menu bar -> 20pt tall capsule centered at x=720, y=878
        let nonNotchedFrame = BeijingClockSupport.islandFrame(
            screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 876),
            safeAreaTop: 0,
            menuBarThickness: 24,
            contentWidth: 120
        )
        suite.expect(nonNotchedFrame == CGRect(x: 660, y: 878, width: 120, height: 20),
                     "non-notched display centers the 20pt capsule inside the 24pt menu bar")

        // Notched display fallback places capsule cleanly below the camera housing
        let notchedFrame = BeijingClockSupport.islandFrame(
            screenFrame: CGRect(x: 0, y: 0, width: 1512, height: 982),
            visibleFrame: CGRect(x: 0, y: 0, width: 1512, height: 944),
            safeAreaTop: 32,
            menuBarThickness: 38,
            contentWidth: 120
        )
        suite.expect(notchedFrame.midX == 756 && notchedFrame.maxY <= 982 - 32,
                     "notched display keeps the capsule centered below the physical cutout")

        let zhStrings = FeatureStrings.beijingClock(.zhHans)
        suite.expect(BeijingClockSupport.relativeOffsetDescription(
            now: morningBeijing, localTimeZone: laTZ, strings: zhStrings
        ) == "比当前系统时间快 16 小时",
                     "winter PST offset is 16 hours behind Beijing")

        // Summer DST check: 2026-07-15 10:00 CST vs PDT (UTC-7, 15 hours behind)
        let summerBeijing = bjCal.date(from: DateComponents(
            year: 2026, month: 7, day: 15, hour: 10, minute: 0, second: 0
        ))!
        suite.expect(BeijingClockSupport.relativeOffsetDescription(
            now: summerBeijing, localTimeZone: laTZ, strings: zhStrings
        ) == "比当前系统时间快 15 小时",
                     "summer PDT offset automatically adjusts to 15 hours")
        suite.expect(BeijingClockSupport.relativeOffsetDescription(
            now: summerBeijing, localTimeZone: beijingTZ, strings: zhStrings
        ) == "与当前系统时间一致",
                     "same timezone reports matching local time")

        // Refresh interval aligns cleanly to minute and second boundaries
        let exactMinute = Date(timeIntervalSince1970: 1_800_000_000) // divisible by 60
        suite.expect(abs(BeijingClockSupport.nextRefreshInterval(now: exactMinute, showSeconds: false) - 60.0) < 0.01,
                     "minute-aligned refresh waits a full minute when already on boundary")
        let midMinute = Date(timeIntervalSince1970: 1_800_000_015.25)
        suite.expect(abs(BeijingClockSupport.nextRefreshInterval(now: midMinute, showSeconds: false) - 44.75) < 0.01,
                     "minute-mode wakes at the next whole minute")
        suite.expect(abs(BeijingClockSupport.nextRefreshInterval(now: midMinute, showSeconds: true) - 0.75) < 0.01,
                     "second-mode wakes at the next whole second")

        // Feature catalog, permissions, backup, and localization integration
        suite.expect(AppFeature.beijingClock.group == .tools
                     && AppFeature.beijingClock.permissions.isEmpty
                     && AppFeature.beijingClock.enabledKeys == [DefaultsKey.beijingClockEnabled]
                     && AppFeature.beijingClock.settingsDestination
                        == FeatureSettingsDestination(.quickTools, sectionAnchor: .beijingClock)
                     && FeaturePreset.essential.features.contains(.beijingClock),
                     "beijingClock is registered as a zero-permission Essential tool")

        let backupKeys = SettingsBackupSupport.exportKeys()
        for key in [DefaultsKey.beijingClockEnabled, DefaultsKey.beijingClockPlacement,
                    DefaultsKey.beijingClockPrefix, DefaultsKey.beijingClockUse24Hour,
                    DefaultsKey.beijingClockShowSeconds, DefaultsKey.beijingClockShowWeekday,
                    DefaultsKey.beijingClockShowDayOffset, DefaultsKey.beijingClockShowDate,
                    AppFeature.beijingClock.availabilityKey] {
            suite.expect(backupKeys.contains(key), "settings backup exports \(key)")
        }

        for language in AppLanguage.allCases {
            let s = FeatureStrings.beijingClock(language)
            suite.expect(!s.pageTitle.isEmpty && !s.enableLabel.isEmpty
                         && !s.placementIsland.isEmpty && !s.showWeekdayLabel.isEmpty,
                         "Beijing clock strings exist for \(language.rawValue)")
        }
    }
}
