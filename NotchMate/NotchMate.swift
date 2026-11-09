import AppKit
import Observation
import ServiceManagement
import SwiftUI

@main
struct NotchMateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var island: IslandController?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        registerForLogin()
        island = IslandController()
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "camera", accessibilityDescription: "NotchMate")
        let menu = NSMenu()
        menu.addItem(withTitle: "Show NotchMate", action: #selector(showIsland), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit NotchMate", action: #selector(quit), keyEquivalent: "q")
        item.menu = menu
        statusItem = item
    }

    private func registerForLogin() {
        guard SMAppService.mainApp.status != .enabled else { return }
        do {
            try SMAppService.mainApp.register()
        } catch {
            NSLog("NotchMate could not register as a login item: %@", error.localizedDescription)
        }
    }

    @objc private func showIsland() { island?.showExpanded() }
    @objc private func quit() { NSApp.terminate(nil) }
}

@MainActor
final class IslandController {
    private let panel: NSPanel
    private let model = IslandModel()

    init() {
        let view = IslandView(model: model)
        panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false
        panel.contentView = NSHostingView(rootView: view)
        positionPanel()
        panel.orderFrontRegardless()
        NotificationCenter.default.addObserver(self, selector: #selector(screenChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    @objc private func screenChanged() { positionPanel() }

    private func positionPanel() {
        guard let screen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) ?? NSScreen.main else { return }
        let size = NSSize(width: 320, height: 180)
        let x = screen.frame.midX - size.width / 2
        let y = screen.frame.maxY - size.height
        panel.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
    }

    func showExpanded() {
        panel.orderFrontRegardless()
        model.isExpanded = true
    }
}

@MainActor
@Observable final class IslandModel {
    var isExpanded = false
    var showNote = false
    var note = ""
    var timerRunning = false
    var secondsRemaining = 15 * 60
    var status = ""
    private var timer: Timer?

    func captureScreenshot() {
        isExpanded = false
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        let path = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop", isDirectory: true)
            .appendingPathComponent("Screenshot \(formatter.string(from: Date())).png").path
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = ["-i", "-s", path]
            do {
                try process.run()
                process.terminationHandler = { [weak self] process in
                    DispatchQueue.main.async {
                        self?.status = process.terminationStatus == 0 ? "Screenshot saved to Desktop" : "Screenshot cancelled"
                        self?.isExpanded = true
                    }
                }
            } catch {
                self.status = "Could not start Screenshot"
                self.isExpanded = true
            }
        }
    }

    func toggleTimer() {
        if timerRunning {
            timer?.invalidate()
            timer = nil
            timerRunning = false
        } else {
            timerRunning = true
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                guard let self else { return }
                if self.secondsRemaining > 0 { self.secondsRemaining -= 1 }
                else { self.timer?.invalidate(); self.timerRunning = false; NSSound.beep() }
            }
        }
    }

    var timerText: String {
        String(format: "%d:%02d", secondsRemaining / 60, secondsRemaining % 60)
    }
}

struct IslandView: View {
    @Bindable var model: IslandModel
    @State private var hovering = false
    @FocusState private var noteFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: model.isExpanded || hovering ? 15 : 12,
                    bottomTrailingRadius: model.isExpanded || hovering ? 15 : 12,
                    topTrailingRadius: 0
                ).fill(Color.black)
                if model.isExpanded || hovering {
                    expandedContent
                        .padding(.horizontal, 10)
                        .padding(.top, 38)
                        .padding(.bottom, 8)
                        .transition(.opacity.combined(with: .scale(scale: 0.94, anchor: .top)))
                } else {
                    EmptyView()
                }
            }
            .frame(width: model.isExpanded || hovering ? 220 : 180, height: model.isExpanded || hovering ? 106 : 34, alignment: .top)
            Spacer(minLength: 0)
        }
        .frame(width: 320, height: 180, alignment: .top)
        .onHover { inside in
            withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) { hovering = inside }
            if !inside && !noteFocused { DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { if !hovering { model.isExpanded = false } } }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.78), value: model.isExpanded)
        .animation(.spring(response: 0.34, dampingFraction: 0.78), value: hovering)
    }

    private var expandedContent: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                actionButton("Screenshot", symbol: "camera", tint: Color(red: 0.43, green: 0.67, blue: 1)) { model.captureScreenshot() }
                actionButton(model.timerRunning ? model.timerText : "Timer", symbol: model.timerRunning ? "pause.fill" : "timer", tint: Color(red: 0.62, green: 0.85, blue: 0.63)) { model.toggleTimer() }
                actionButton("Quick note", symbol: "note.text", tint: Color(red: 1, green: 0.72, blue: 0.42)) { model.showNote.toggle() }
                Button { model.isExpanded = false } label: {
                    Image(systemName: "xmark").font(.system(size: 9, weight: .semibold)).foregroundStyle(.white.opacity(0.55))
                        .frame(width: 24, height: 28)
                }
                .buttonStyle(.plain)
                .help("Close NotchMate")
            }
            if model.showNote {
                TextField("Write a quick note…", text: $model.note)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .frame(height: 24)
                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    .focused($noteFocused)
            } else if !model.status.isEmpty {
                Text(model.status).font(.system(size: 9)).foregroundStyle(.white.opacity(0.55)).lineLimit(1)
            }
        }
    }

    private func actionButton(_ title: String, symbol: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 28)
                .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .help(title)
        .accessibilityLabel(title)
    }
}
