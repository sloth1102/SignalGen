import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ExportView: View {
    @ObservedObject var audio: AudioEngine
    var waveColor: Color
    @Environment(\.dismiss) private var dismiss

    @State private var duration: String = "5"
    @State private var selectedFormat: AudioEngine.ExportFormat = .wav
    @State private var isExporting = false
    @State private var exportError: String? = nil
    @State private var exportSuccess = false

    // Layout: show formats in rows of up to 5
    private let columns = [
        GridItem(.adaptive(minimum: 60), spacing: 8)
    ]

    private var durationSeconds: Double {
        Double(duration) ?? 0
    }

    private var fileSizeBytes: Int {
        guard durationSeconds > 0 else { return 0 }
        return audio.estimatedFileSizeBytes(duration: durationSeconds, format: selectedFormat)
    }

    private var fileSizeString: String {
        let bytes = fileSizeBytes
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024.0)
        } else if bytes < 1024 * 1024 * 1024 {
            return String(format: "%.2f MB", Double(bytes) / (1024.0 * 1024.0))
        } else {
            return String(format: "%.2f GB", Double(bytes) / (1024.0 * 1024.0 * 1024.0))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Title row with X button
            ZStack {
                Text("EXPORT WAVEFORM")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(6)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(8)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Format picker — centered, wrapping grid
            VStack(spacing: 10) {
                Text("FILE FORMAT")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
                    .tracking(4)
                    .frame(maxWidth: .infinity, alignment: .center)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(AudioEngine.ExportFormat.allCases, id: \.self) { fmt in
                        Button(action: { selectedFormat = fmt }) {
                            Text(fmt.label)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(selectedFormat == fmt ? .black : .white.opacity(0.5))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedFormat == fmt ? waveColor : Color.white.opacity(0.07))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity)

                // Note for compressed formats
                if selectedFormat.isCompressed {
                    Text("Compressed format — estimated size is approximate")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.orange.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }

            // Duration input
            VStack(spacing: 8) {
                Text("DURATION")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
                    .tracking(4)

                HStack(spacing: 0) {
                    TextField("seconds", text: $duration)
                        .font(.system(size: 18, weight: .light, design: .monospaced))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .onChange(of: duration) {
                            var result = ""
                            var hasDot = false
                            for char in duration {
                                if char.isNumber {
                                    result.append(char)
                                } else if char == "." && !hasDot {
                                    result.append(char)
                                    hasDot = true
                                }
                            }
                            if result != duration { duration = result }
                        }

                    Text("sec")
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

            // File size preview
            HStack {
                Text("ESTIMATED SIZE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
                    .tracking(4)
                Spacer()
                Text(durationSeconds > 0 ? fileSizeString : "—")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(waveColor)
            }
            .padding(.horizontal, 4)

            // Info row
            HStack {
                Text("44100 Hz · 32-bit float · mono")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.25))
                Spacer()
                Text("\(audio.waveform.rawValue) · \(String(format: "%.1f", audio.frequency)) Hz · \(String(format: "%.2f", audio.amplitude)) dFS")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.25))
            }
            .padding(.horizontal, 4)

            // Error / success feedback
            if let err = exportError {
                Text("⚠ \(err)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.red.opacity(0.8))
            }
            if exportSuccess {
                Text("✓ Exported successfully")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.green.opacity(0.8))
            }

            // Export button
            Button(action: runExport) {
                HStack(spacing: 8) {
                    if isExporting {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                    }
                    Text(isExporting ? "EXPORTING..." : "EXPORT")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .tracking(3)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(durationSeconds > 0 ? waveColor : Color.white.opacity(0.2))
                )
            }
            .buttonStyle(.plain)
            .disabled(durationSeconds <= 0 || isExporting)
        }
        .padding(24)
        .background(Color.black)
        .frame(width: 420)
    }

    private func runExport() {
        guard durationSeconds > 0 else { return }
        exportError = nil
        exportSuccess = false

        let panel = NSSavePanel()
        panel.title = "Export Waveform"
        panel.nameFieldStringValue = "\(audio.waveform.rawValue.lowercased())_\(Int(audio.frequency))hz.\(selectedFormat.fileExtension)"
        panel.canCreateDirectories = true

        // Set allowed content types where we know them
        switch selectedFormat {
        case .wav:
            panel.allowedContentTypes = [UTType.wav]
        case .aiff:
            panel.allowedContentTypes = [UTType.aiff]
        case .m4a:
            panel.allowedContentTypes = [UTType.mpeg4Audio]
        case .mp3:
            if let t = UTType("public.mp3") { panel.allowedContentTypes = [t] }
        case .flac:
            if let t = UTType("org.xiph.flac") { panel.allowedContentTypes = [t] }
        case .opus:
            if let t = UTType("org.xiph.opus") { panel.allowedContentTypes = [t] }
        default:
            panel.allowedContentTypes = []
        }

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return }

        let finalURL: URL
        if url.pathExtension.lowercased() != selectedFormat.fileExtension {
            finalURL = url.deletingPathExtension().appendingPathExtension(selectedFormat.fileExtension)
        } else {
            finalURL = url
        }

        isExporting = true

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try audio.exportAudio(duration: durationSeconds, format: selectedFormat, to: finalURL)
                DispatchQueue.main.async {
                    isExporting = false
                    exportSuccess = true
                }
            } catch {
                DispatchQueue.main.async {
                    isExporting = false
                    exportError = error.localizedDescription
                }
            }
        }
    }
}
