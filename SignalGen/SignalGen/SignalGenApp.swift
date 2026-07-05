import SwiftUI

@main
struct SignalGenApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .saveItem) { }
            CommandGroup(replacing: .importExport) { }
            CommandGroup(replacing: .printItem) { }
            CommandGroup(replacing: .undoRedo) { }
            CommandGroup(replacing: .pasteboard) { }
            CommandGroup(replacing: .sidebar) { }
            CommandGroup(replacing: .toolbar) { }

            CommandMenu("Misc") {
                Toggle("Show MHz / GHz Units", isOn: $settings.showAdvancedUnits)
                    .keyboardShortcut("u", modifiers: [.command, .shift])

                Divider()

                Toggle("Show Waveform Glow", isOn: $settings.showGlow)
                    .keyboardShortcut("g", modifiers: [.command, .shift])

                Divider()

                Toggle("Show Phase Shift Slider", isOn: $settings.showPhaseShift)
                    .keyboardShortcut("h", modifiers: [.command, .shift])

                Divider()

                Toggle("Show X-Axis in π Radians", isOn: $settings.showPiLabels)
                    .keyboardShortcut("p", modifiers: [.command, .shift])
            }
        }
    }
}
