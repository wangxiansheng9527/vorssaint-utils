// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI

/// Borderless, non-activating top-center Dynamic Island capsule panel for the
/// Beijing Time clock, modeled after NotchPanel so it stays pinned at the top
/// center of the menu bar across Spaces without taking focus.
final class BeijingClockIslandPanel: NSPanel {
    static let capsuleCollectionBehavior: NSWindow.CollectionBehavior = [
        .canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle
    ]
    static let capsuleLevel = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    @objc func _hasActiveAppearanceIgnoringKeyFocus() -> Bool { true }

    override func accessibilitySubrole() -> NSAccessibility.Subrole? { .unknown }

    init(frame: CGRect) {
        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        appearance = NSAppearance(named: .darkAqua)
        hasShadow = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        animationBehavior = .none
        level = Self.capsuleLevel
        collectionBehavior = Self.capsuleCollectionBehavior
    }
}

/// Hosts the SwiftUI black capsule and routes left/right clicks without
/// stealing focus from the frontmost app.
final class BeijingClockIslandContentView: NSView {
    private static let textFont = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
    private static let horizontalPadding: CGFloat = 12

    var onLeftClick: ((NSView) -> Void)?
    var onRightClick: ((NSView) -> Void)?

    private let model = BeijingClockCapsuleModel()
    private let hostingView: NSHostingView<BeijingClockCapsuleContent>

    override init(frame frameRect: NSRect) {
        hostingView = NSHostingView(rootView: BeijingClockCapsuleContent(model: model))
        super.init(frame: frameRect)
        wantsLayer = true
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(text: String, tooltip: String) {
        if model.text != text {
            model.text = text
        }
        if toolTip != tooltip {
            toolTip = tooltip
        }
    }

    static func measuredWidth(for text: String) -> CGFloat {
        let measured = (text as NSString).size(withAttributes: [.font: textFont]).width
        return ceil(measured) + horizontalPadding * 2
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseUp(with event: NSEvent) {
        guard bounds.contains(convert(event.locationInWindow, from: nil)) else { return }
        onLeftClick?(self)
    }

    override func rightMouseUp(with event: NSEvent) {
        guard bounds.contains(convert(event.locationInWindow, from: nil)) else { return }
        onRightClick?(self)
    }
}

private final class BeijingClockCapsuleModel: ObservableObject {
    @Published var text: String = ""
}

private struct BeijingClockCapsuleContent: View {
    @ObservedObject var model: BeijingClockCapsuleModel

    var body: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(Color.black)
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5)
                }
            Text(model.text)
                .font(.system(size: 12, weight: .medium).monospacedDigit())
                .foregroundStyle(.white)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.text)
    }
}
