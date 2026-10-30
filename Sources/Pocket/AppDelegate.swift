import AppKit
import Carbon.HIToolbox
import SwiftUI

extension Notification.Name {
    static let pocketDidShow = Notification.Name("pocketDidShow")
}

/// Borderless panel that behaves like a popover but can blend into its content.
final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }

    override func resignKey() {
        super.resignKey()
        orderOut(nil)
    }

    override func cancelOperation(_ sender: Any?) {
        orderOut(nil)
        NSApp.hide(nil)
    }
}

@main
struct PocketApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static let panelSize = NSSize(width: 400, height: 600)

    private let store = ClipStore()
    private var statusItem: NSStatusItem?
    private var panel: FloatingPanel?
    private var hotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        store.start()
        buildStatusItem()
        buildPanel()
        hotKey = HotKey(keyCode: kVK_ANSI_V, modifiers: cmdKey | controlKey) { [weak self] in self?.toggle() }
        if hotKey == nil { NSLog("Pocket: could not register the ⌃⌘V hotkey") }
        if ProcessInfo.processInfo.environment["POCKET_SHOW_ON_LAUNCH"] != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.show() }
        }
    }

    // MARK: Status item

    private func buildStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            let image = NSImage(systemSymbolName: "tray.full.fill", accessibilityDescription: "Pocket")
            image?.isTemplate = true
            button.image = image
            button.target = self
            button.action = #selector(statusClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem = item
    }

    @objc private func statusClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu()
        } else {
            toggle()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "Open Pocket   ⌃⌘V", action: #selector(openFromMenu), keyEquivalent: "").target = self
        let login = menu.addItem(withTitle: "Launch at Login", action: #selector(toggleLogin), keyEquivalent: "")
        login.target = self
        login.state = LaunchAtLogin.isEnabled ? .on : .off
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Pocket", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func openFromMenu() { show() }
    @objc private func toggleLogin() { LaunchAtLogin.toggle() }

    // MARK: Panel

    private func buildPanel() {
        let root = PopoverView(store: store, close: { [weak self] in self?.dismiss() })
            .preferredColorScheme(.dark)
        let host = NSHostingView(rootView: root)
        host.frame = NSRect(origin: .zero, size: Self.panelSize)

        let panel = FloatingPanel(
            contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false
        )
        panel.contentView = host
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.panel = panel
    }

    private func toggle() {
        if panel?.isVisible == true { dismiss() } else { show() }
    }

    private func show() {
        guard let panel, let button = statusItem?.button, let window = button.window else { return }
        let buttonFrame = window.convertToScreen(button.convert(button.bounds, to: nil))
        let screen = window.screen ?? NSScreen.main
        let visible = screen?.visibleFrame ?? .zero

        var x = buttonFrame.midX - Self.panelSize.width / 2
        x = min(max(x, visible.minX + 8), visible.maxX - Self.panelSize.width - 8)
        let y = buttonFrame.minY - Self.panelSize.height - 6
        panel.setFrame(NSRect(origin: NSPoint(x: x, y: y), size: Self.panelSize), display: true)

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        NotificationCenter.default.post(name: .pocketDidShow, object: nil)
    }

    private func dismiss() {
        panel?.orderOut(nil)
        NSApp.hide(nil)
    }
}
