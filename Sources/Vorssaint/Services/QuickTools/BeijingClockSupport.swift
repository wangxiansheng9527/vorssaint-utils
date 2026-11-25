// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import CoreGraphics
import Foundation

/// Pure date/time math, formatting, and top-center capsule geometry for the
/// Beijing Time clock. Kept free of AppKit/SwiftUI so unit tests can exercise
/// every time zone, DST transition, day boundary, and display geometry directly.
enum BeijingClockSupport {
    static let timeZone = TimeZone(identifier: "Asia/Shanghai") ?? TimeZone(secondsFromGMT: 8 * 3600)!

    enum Placement: String, CaseIterable {
        case island
        case menuBar

        static func sanitized(_ raw: String?) -> Placement {
            guard let raw, let value = Placement(rawValue: raw) else { return .island }
            return value
        }
    }

    enum PrefixStyle: String, CaseIterable {
        case beijing
        case bj
        case none

        static func sanitized(_ raw: String?) -> PrefixStyle {
            guard let raw, let value = PrefixStyle(rawValue: raw) else { return .beijing }
            return value
        }
    }

    struct DisplayOptions: Equatable {
        var placement: Placement = .island
        var prefixStyle: PrefixStyle = .beijing
        var use24Hour: Bool = true
        var showSeconds: Bool = false
        var showWeekday: Bool = true
        var showDayOffset: Bool = false
        var showDate: Bool = false

        static func fromDefaults(_ defaults: UserDefaults = .standard) -> DisplayOptions {
            DisplayOptions(
                placement: Placement.sanitized(defaults.string(forKey: DefaultsKey.beijingClockPlacement)),
                prefixStyle: PrefixStyle.sanitized(defaults.string(forKey: DefaultsKey.beijingClockPrefix)),
                use24Hour: defaults.bool(forKey: DefaultsKey.beijingClockUse24Hour),
                showSeconds: defaults.bool(forKey: DefaultsKey.beijingClockShowSeconds),
                showWeekday: defaults.bool(forKey: DefaultsKey.beijingClockShowWeekday),
                showDayOffset: defaults.bool(forKey: DefaultsKey.beijingClockShowDayOffset),
                showDate: defaults.bool(forKey: DefaultsKey.beijingClockShowDate)
            )
        }
    }

    static func menuBarText(now: Date,
                            localTimeZone: TimeZone = .current,
                            language: AppLanguage,
                            options: DisplayOptions) -> String {
        let strings = FeatureStrings.beijingClock(language)
        var parts: [String] = []

        switch options.prefixStyle {
        case .beijing:
            parts.append(strings.prefixBeijing)
        case .bj:
            parts.append(strings.prefixBJ)
        case .none:
            break
        }

        if options.showDate {
            parts.append(formattedShortDate(now: now))
        }

        parts.append(formattedTime(now: now, use24Hour: options.use24Hour, showSeconds: options.showSeconds))

        if options.showWeekday {
            parts.append(formattedWeekday(now: now, language: language))
        }

        if options.showDayOffset,
           let tag = dayOffsetTag(now: now, localTimeZone: localTimeZone, strings: strings) {
            parts.append(tag)
        }

        return parts.joined(separator: " ")
    }

    static func formattedTime(now: Date, use24Hour: Bool, showSeconds: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        switch (use24Hour, showSeconds) {
        case (true, true): formatter.dateFormat = "HH:mm:ss"
        case (true, false): formatter.dateFormat = "HH:mm"
        case (false, true): formatter.dateFormat = "h:mm:ss a"
        case (false, false): formatter.dateFormat = "h:mm a"
        }
        return formatter.string(from: now)
    }

    static func formattedShortDate(now: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: now)
    }

    static func formattedWeekday(now: Date, language: AppLanguage) -> String {
        let formatter = DateFormatter()
        formatter.locale = language.formattingLocale()
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter.string(from: now)
    }

    static func formattedFullDateTime(now: Date,
                                      language: AppLanguage,
                                      use24Hour: Bool = true,
                                      showSeconds: Bool = true) -> String {
        let formatter = DateFormatter()
        formatter.locale = language.formattingLocale()
        formatter.timeZone = timeZone
        let timePart = formattedTime(now: now, use24Hour: use24Hour, showSeconds: showSeconds)
        formatter.setLocalizedDateFormatFromTemplate("yMMMEd")
        let datePart = formatter.string(from: now)
        return "\(datePart) \(timePart)"
    }

    static func copyableFullDateTime(now: Date, use24Hour: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = use24Hour ? "yyyy-MM-dd HH:mm:ss" : "yyyy-MM-dd h:mm:ss a"
        return formatter.string(from: now)
    }

    /// Calendar day difference `(beijingDay - localDay)`. Returns `+1` when
    /// Beijing is already on tomorrow's date relative to `localTimeZone`.
    static func calendarDayOffset(now: Date, localTimeZone: TimeZone = .current) -> Int {
        var beijingCal = Calendar(identifier: .gregorian)
        beijingCal.timeZone = timeZone
        var localCal = Calendar(identifier: .gregorian)
        localCal.timeZone = localTimeZone
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(secondsFromGMT: 0)!

        let bjComponents = beijingCal.dateComponents([.year, .month, .day], from: now)
        let localComponents = localCal.dateComponents([.year, .month, .day], from: now)
        guard let bjDay = utcCal.date(from: bjComponents),
              let localDay = utcCal.date(from: localComponents) else {
            return 0
        }
        return utcCal.dateComponents([.day], from: localDay, to: bjDay).day ?? 0
    }

    static func dayOffsetTag(now: Date,
                             localTimeZone: TimeZone = .current,
                             strings: BeijingClockFeatureStrings) -> String? {
        let diff = calendarDayOffset(now: now, localTimeZone: localTimeZone)
        guard diff != 0 else { return nil }
        switch diff {
        case 1: return strings.tomorrowTag
        case -1: return strings.yesterdayTag
        case let d where d > 1: return String(format: strings.dayOffsetAheadFormat, d)
        default: return String(format: strings.dayOffsetBehindFormat, -diff)
        }
    }

    static func relativeOffsetDescription(now: Date,
                                          localTimeZone: TimeZone = .current,
                                          strings: BeijingClockFeatureStrings) -> String {
        let deltaSeconds = timeZone.secondsFromGMT(for: now) - localTimeZone.secondsFromGMT(for: now)
        if deltaSeconds == 0 {
            return strings.sameTimeAsLocal
        }
        let absMinutes = abs(deltaSeconds) / 60
        let hours = absMinutes / 60
        let minutes = absMinutes % 60
        var chunks: [String] = []
        if hours > 0 {
            let fmt = hours == 1 ? strings.hourUnitSingular : strings.hourUnitPlural
            chunks.append(String(format: fmt, hours))
        }
        if minutes > 0 {
            let fmt = minutes == 1 ? strings.minuteUnitSingular : strings.minuteUnitPlural
            chunks.append(String(format: fmt, minutes))
        }
        let duration = chunks.joined(separator: " ")
        return deltaSeconds > 0
            ? String(format: strings.aheadFormat, duration)
            : String(format: strings.behindFormat, duration)
    }

    static func tooltipText(now: Date,
                            localTimeZone: TimeZone = .current,
                            language: AppLanguage,
                            use24Hour: Bool) -> String {
        let strings = FeatureStrings.beijingClock(language)
        let full = formattedFullDateTime(now: now, language: language, use24Hour: use24Hour, showSeconds: true)
        let header = String(format: strings.tooltipHeaderFormat, full)
        var secondLine = relativeOffsetDescription(now: now, localTimeZone: localTimeZone, strings: strings)
        if let tag = dayOffsetTag(now: now, localTimeZone: localTimeZone, strings: strings) {
            secondLine += " (\(tag))"
        }
        return "\(header)\n\(secondLine)"
    }

    /// Top-center capsule frame matching a simulated Dynamic Island pill inside
    /// the menu bar on non-notched Macs (and sitting cleanly below a physical
    /// camera cutout if one is present).
    static func islandFrame(screenFrame: CGRect,
                            visibleFrame: CGRect,
                            safeAreaTop: CGFloat,
                            menuBarThickness: CGFloat,
                            contentWidth: CGFloat) -> CGRect {
        let visibleBar = screenFrame.maxY - visibleFrame.maxY
        let rawBar = visibleBar >= 20 ? visibleBar : max(24, menuBarThickness)
        let barHeight = rawBar.isFinite ? min(64, max(20, rawBar)) : 24
        let gap = min(2, max(0, ((barHeight - 20) / 2).rounded(.down)))
        let height = max(20, barHeight - gap * 2)
        let width = min(screenFrame.width * 0.7, max(96, contentWidth.rounded(.up)))
        let x = (screenFrame.midX - width / 2).rounded()
        let y: CGFloat
        if safeAreaTop.isFinite, safeAreaTop > 0 {
            y = (screenFrame.maxY - safeAreaTop - height - 2).rounded()
        } else {
            y = (screenFrame.maxY - gap - height).rounded()
        }
        return CGRect(x: x, y: y, width: width, height: height)
    }

    /// Delay until the next whole second (when seconds are shown) or next whole
    /// minute (when seconds are hidden), keeping wakeups to 1/min by default.
    static func nextRefreshInterval(now: Date, showSeconds: Bool) -> TimeInterval {
        let t = now.timeIntervalSince1970
        let period: TimeInterval = showSeconds ? 1.0 : 60.0
        let remainder = t.truncatingRemainder(dividingBy: period)
        let normalized = remainder < 0 ? remainder + period : remainder
        let remaining = period - normalized
        let minimum = showSeconds ? 0.05 : 0.1
        return remaining < minimum ? remaining + period : remaining
    }
}
