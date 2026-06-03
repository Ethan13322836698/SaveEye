//
//  ConfigWindow.swift
//  SaveEye
//
//  Created by samzong on 6/16/25.
//

import ApplicationServices
import SwiftUI

struct ConfigWindow: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var activityMonitor: ActivityMonitor

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 20) {
                protectionToggleCard

                Divider()
                    .padding(.horizontal, -20)

                breakIntervalCard

                Divider()
                    .padding(.horizontal, -20)

                restDurationCard

                Divider()
                    .padding(.horizontal, -20)

                delayDurationCard

                Divider()
                    .padding(.horizontal, -20)

                autoStartCard
            }
            .padding(20)
            .cornerRadius(12)

            Button(L10n.string("settings.quit_app")) {
                appState.quitApp()
            }
            .buttonStyle(.bordered)
            .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(width: 400)
        .onAppear {
            checkAccessibilityPermission()
            setupWindowStyle()
        }
    }

    // MARK: - 视图组件

    private var protectionToggleCard: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(appState.isRunning ? .green : .red)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(appState.isRunning ? L10n.string("settings.protection.enabled") : L10n.string("settings.protection.disabled"))
                    .font(.body)
                    .fontWeight(.medium)

                Text(appState.isRunning ? appState.timerStatus : " ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(minHeight: 12)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { appState.isRunning },
                set: { isOn in
                    if isOn {
                        startProtection()
                    } else {
                        appState.stopProtection()
                    }
                }
            ))
            .toggleStyle(SwitchToggleStyle(tint: .blue))
            .scaleEffect(1.2)
        }
    }

    private var breakIntervalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.string("settings.break_interval.title"))
                .font(.headline)

            HStack {
                Slider(
                    value: Binding(
                        get: { Double(settings.breakIntervalMinutes) },
                        set: { settings.breakIntervalMinutes = Int($0) }
                    ),
                    in: 5 ... 60,
                    step: 5
                ) {
                    Text(L10n.string("settings.break_interval.title"))
                } minimumValueLabel: {
                    Text("5")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("60")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accentColor(.blue)

                VStack {
                    Text("\(settings.breakIntervalMinutes)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(minWidth: 40)

                    Text(L10n.string("unit.minute.short"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(L10n.string("settings.break_interval.recommendation"))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }

    private var restDurationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.string("settings.rest_duration.title"))
                .font(.headline)

            HStack {
                Slider(
                    value: Binding(
                        get: { Double(settings.restDurationSeconds) },
                        set: { settings.restDurationSeconds = Int($0) }
                    ),
                    in: 10 ... 60,
                    step: 5
                ) {
                    Text(L10n.string("settings.rest_duration.title"))
                } minimumValueLabel: {
                    Text("10")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("60")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accentColor(.blue)

                VStack {
                    Text("\(settings.restDurationSeconds)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(minWidth: 40)

                    Text(L10n.string("unit.second.short"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(L10n.string("settings.rest_duration.recommendation"))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }

    private var delayDurationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.string("settings.delay_duration.title"))
                .font(.headline)

            HStack {
                Slider(
                    value: Binding(
                        get: { Double(settings.delayDurationMinutes) },
                        set: { settings.delayDurationMinutes = Int($0) }
                    ),
                    in: 1 ... 10,
                    step: 1
                ) {
                    Text(L10n.string("settings.delay_duration.title"))
                } minimumValueLabel: {
                    Text("1")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("10")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accentColor(.blue)

                VStack {
                    Text("\(settings.delayDurationMinutes)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(minWidth: 40)

                    Text(L10n.string("unit.minute.short"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(L10n.string("settings.delay_duration.recommendation"))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }

    private var autoStartCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.string("settings.auto_start.title"))
                    .font(.body)
                    .fontWeight(.medium)

                Text(L10n.string("settings.auto_start.description"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $settings.autoStart)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .scaleEffect(1.2)
        }
    }

    private func startProtection() {
        guard AXIsProcessTrusted() else {
            requestAccessibilityPermission()
            return
        }

        appState.startProtection()
    }

    private func checkAccessibilityPermission() {
        if !AXIsProcessTrusted() {}
    }

    private func setupWindowStyle() {
        DispatchQueue.main.async {
            if let window = NSApp.keyWindow ?? NSApp.windows.first(where: { $0.title.contains("SaveEye") }) {
                window.standardWindowButton(.miniaturizeButton)?.isEnabled = false
                window.standardWindowButton(.zoomButton)?.isEnabled = false

                window.styleMask.remove(.resizable)
            }
        }
    }

    private func requestAccessibilityPermission() {
        let alert = NSAlert()
        alert.messageText = L10n.string("permission.accessibility.title")
        alert.informativeText = L10n.string("permission.accessibility.message")
        alert.addButton(withTitle: L10n.string("permission.accessibility.open_settings"))
        alert.addButton(withTitle: L10n.string("permission.accessibility.later"))
        alert.alertStyle = .informational

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

struct ConfigWindow_Previews: PreviewProvider {
    static var previews: some View {
        ConfigWindow()
            .environmentObject(Settings())
            .environmentObject(AppState())
    }
}
