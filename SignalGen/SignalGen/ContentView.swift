import SwiftUI
import AppKit

enum FrequencyUnit: String, CaseIterable {
    case hz   = "Hz"
    case khz  = "kHz"
    case mhz  = "MHz"
    case ghz  = "GHz"
    case rads = "rad/s"

    func toHz(_ value: Double) -> Double {
        switch self {
        case .hz:   return value
        case .khz:  return value * 1_000
        case .mhz:  return value * 1_000_000
        case .ghz:  return value * 1_000_000_000
        case .rads: return value / (2.0 * Double.pi)
        }
    }

    func fromHz(_ hz: Double) -> Double {
        switch self {
        case .hz:   return hz
        case .khz:  return hz / 1_000
        case .mhz:  return hz / 1_000_000
        case .ghz:  return hz / 1_000_000_000
        case .rads: return hz * 2.0 * Double.pi
        }
    }

    var placeholder: String {
        switch self {
        case .hz:   return "20 – 20000"
        case .khz:  return "0.02 – 20"
        case .mhz:  return "0.00002 – 0.02"
        case .ghz:  return "0.00000002 – 0.00002"
        case .rads: return "125.66 – 125663.7"
        }
    }

    var decimals: Int {
        switch self {
        case .hz:   return 1
        case .khz:  return 4
        case .mhz:  return 7
        case .ghz:  return 11
        case .rads: return 3
        }
    }

    var audioMaxInUnit: Double { fromHz(20000) }
    var isAdvanced: Bool { self == .mhz || self == .ghz }
}

struct ContentView: View {
    @StateObject private var audio = AudioEngine()
    @EnvironmentObject private var settings: AppSettings

    @State private var freqText: String = "440.0"
    @State private var ampText: String = "0.50"
    @State private var selectedUnit: FrequencyUnit = .hz
    @State private var showExport = false

    var effectiveUnit: FrequencyUnit {
        if !settings.showAdvancedUnits && selectedUnit.isAdvanced { return .hz }
        return selectedUnit
    }

    var visibleUnits: [FrequencyUnit] {
        FrequencyUnit.allCases.filter { !$0.isAdvanced || settings.showAdvancedUnits }
    }

    var waveColor: Color {
        switch audio.waveform {
        case .sine:     return .cyan
        case .square:   return .green
        case .sawtooth: return .orange
        case .triangle: return .purple
        }
    }

    var phaseShiftDegrees: String {
        let deg = audio.phaseShift * 180.0 / Double.pi
        return String(format: "%.0f°", deg)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {

                Color.clear
                    .frame(width: 0, height: 0)
                    .onAppear {
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 100_000_000)
                            NSApp.keyWindow?.makeFirstResponder(nil)
                        }
                    }

                Text("SIGNAL GENERATOR")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(6)

                // Waveform Display
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )

                    WaveformView(
                        samples: audio.waveformBuffer,
                        color: waveColor,
                        frequency: audio.frequency,
                        amplitude: audio.amplitude,
                        windowSeconds: audio.displayWindowSeconds,
                        waveform: audio.waveform,
                        showGlow: settings.showGlow,
                        showPiLabels: settings.showPiLabels
                    )
                    .padding(12)
                }
                .frame(height: 180)
                .padding(.horizontal)

                // Frequency unit picker
                VStack(spacing: 8) {
                    Text("FREQUENCY UNIT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.3))
                        .tracking(4)

                    HStack(spacing: 8) {
                        ForEach(visibleUnits, id: \.self) { unit in
                            Button(action: {
                                commitFrequency()
                                selectedUnit = unit
                                freqText = formatFreq(unit.fromHz(audio.frequency), decimals: unit.decimals)
                            }) {
                                Text(unit.rawValue)
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundColor(effectiveUnit == unit ? .black : .white.opacity(0.4))
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(effectiveUnit == unit ? waveColor : Color.white.opacity(0.07))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if effectiveUnit != .hz && effectiveUnit != .rads {
                        Text("Audio max: \(formatFreq(effectiveUnit.audioMaxInUnit, decimals: effectiveUnit.decimals)) \(effectiveUnit.rawValue) — values above clamp to 20kHz")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.orange.opacity(0.6))
                    }
                }

                // Frequency + Amplitude textboxes
                HStack(spacing: 16) {

                    VStack(spacing: 6) {
                        Text("FREQUENCY")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.3))
                            .tracking(4)

                        HStack(spacing: 0) {
                            TextField(effectiveUnit.placeholder, text: $freqText)
                                .font(.system(size: 18, weight: .light, design: .monospaced))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(.plain)
                                .frame(maxWidth: .infinity)
                                .onSubmit { commitFrequency() }
                                .onChange(of: freqText) {
                                    let sanitized = sanitizeNumeric(freqText)
                                    if sanitized != freqText {
                                        freqText = sanitized
                                        return
                                    }
                                    if let val = Double(freqText), val > 0 {
                                        let hz = effectiveUnit.toHz(val)
                                        let clamped = min(max(hz, 20), 20000)
                                        if audio.frequency != clamped {
                                            audio.frequency = clamped
                                        }
                                    }
                                }

                            Text(effectiveUnit.rawValue)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white.opacity(0.3))
                                .padding(.trailing, 10)
                        }
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(waveColor.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }

                    VStack(spacing: 6) {
                        Text("AMPLITUDE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.3))
                            .tracking(4)

                        HStack(spacing: 0) {
                            TextField("0.0–1.0", text: $ampText)
                                .font(.system(size: 18, weight: .light, design: .monospaced))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(.plain)
                                .frame(maxWidth: .infinity)
                                .onSubmit { commitAmplitude() }
                                .onChange(of: ampText) {
                                    let sanitized = sanitizeNumeric(ampText)
                                    if sanitized != ampText {
                                        ampText = sanitized
                                        return
                                    }
                                    if let val = Double(ampText) {
                                        let clamped = min(max(val, 0), 1.0)
                                        if audio.amplitude != clamped {
                                            audio.amplitude = clamped
                                        }
                                    }
                                }

                            Text("dFS")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white.opacity(0.3))
                                .padding(.trailing, 10)
                        }
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(waveColor.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal)

                // Waveform Picker
                VStack(spacing: 10) {
                    Text("WAVEFORM")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.3))
                        .tracking(4)

                    HStack(spacing: 10) {
                        ForEach(Waveform.allCases, id: \.self) { wave in
                            Button(action: { audio.waveform = wave }) {
                                Text(wave.rawValue)
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundColor(audio.waveform == wave ? .black : .white.opacity(0.5))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(audio.waveform == wave ? waveColor : Color.white.opacity(0.07))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Phase Shift Slider
                if settings.showPhaseShift {
                    VStack(spacing: 8) {
                        HStack {
                            Text("PHASE SHIFT")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.3))
                                .tracking(4)
                            Spacer()
                            Text(phaseShiftDegrees)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(waveColor)
                            Button(action: { audio.phaseShift = 0.0 }) {
                                Text("RESET")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.3))
                                    .padding(.vertical, 3)
                                    .padding(.horizontal, 7)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.white.opacity(0.07))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)

                        Slider(value: $audio.phaseShift, in: 0...(2.0 * Double.pi))
                            .accentColor(waveColor)
                            .padding(.horizontal)
                    }
                }

                // Play / Stop + Export row
                HStack(spacing: 12) {
                    Button(action: {
                        if audio.isPlaying { audio.stop() } else { audio.start() }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: audio.isPlaying ? "stop.fill" : "play.fill")
                            Text(audio.isPlaying ? "STOP" : "PLAY")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .tracking(3)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(audio.isPlaying ? Color.red : waveColor)
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: { showExport = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.down")
                            Text("EXPORT")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .tracking(3)
                        }
                        .foregroundColor(waveColor)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(waveColor.opacity(0.4), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 30)
        }
        .frame(minWidth: 460, minHeight: 620)
        .sheet(isPresented: $showExport) {
            ExportView(audio: audio, waveColor: waveColor)
        }
        .onChange(of: settings.showAdvancedUnits) {
            if !settings.showAdvancedUnits && selectedUnit.isAdvanced {
                selectedUnit = .hz
                freqText = formatFreq(FrequencyUnit.hz.fromHz(audio.frequency), decimals: FrequencyUnit.hz.decimals)
            }
        }
    }

    private func sanitizeNumeric(_ input: String) -> String {
        var result = ""
        var hasDot = false
        for char in input {
            if char.isNumber {
                result.append(char)
            } else if char == "." && !hasDot {
                result.append(char)
                hasDot = true
            }
        }
        return result
    }

    private func formatFreq(_ value: Double, decimals: Int) -> String {
        String(format: "%.\(decimals)f", value)
    }

    private func commitFrequency() {
        guard let val = Double(freqText), val > 0 else { return }
        let hz = effectiveUnit.toHz(val)
        let clamped = min(max(hz, 20), 20000)
        audio.frequency = clamped
        freqText = formatFreq(effectiveUnit.fromHz(clamped), decimals: effectiveUnit.decimals)
    }

    private func commitAmplitude() {
        guard let val = Double(ampText), val >= 0 else { return }
        let clamped = min(val, 1.0)
        audio.amplitude = clamped
        ampText = formatFreq(clamped, decimals: 2)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings())
}
