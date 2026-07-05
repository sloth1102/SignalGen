import SwiftUI

struct WaveformView: View {
    var samples: [Float]
    var color: Color = .green
    var frequency: Double = 440.0
    var amplitude: Double = 0.5
    var windowSeconds: Double = 0.02
    var waveform: Waveform = .sine
    var showGlow: Bool = false
    var showPiLabels: Bool = false

    /// Downsample `samples` to at most `targetCount` points using
    /// min/max envelope so visual peaks are never lost.
    private func downsample(_ input: [Float], to targetCount: Int) -> [Float] {
        guard input.count > targetCount, targetCount > 1 else { return input }
        var out = [Float]()
        out.reserveCapacity(targetCount)
        let ratio = Double(input.count) / Double(targetCount)
        for i in 0..<targetCount {
            let start = Int(Double(i) * ratio)
            let end   = min(Int(Double(i + 1) * ratio), input.count)
            guard start < end else { continue }
            let slice = input[start..<end]
            // Keep the extreme (max absolute value) to preserve wave shape
            let minVal = slice.min()!
            let maxVal = slice.max()!
            // Alternate min/max to avoid collapsing peaks to zero
            out.append(abs(minVal) >= abs(maxVal) ? minVal : maxVal)
        }
        return out
    }

    private func buildWavePath(plotW: Double, plotH: Double, padLeft: Double, padTop: Double, midY: Double) -> Path {
        var path = Path()
        guard samples.count > 1 else { return path }

        // Limit to 2 samples per pixel to avoid sub-pixel rendering artifacts
        let maxSamples = max(64, Int(plotW) * 2)
        let display = downsample(samples, to: maxSamples)

        let step = plotW / Double(max(display.count - 1, 1))

        func yPos(_ sample: Float) -> Double {
            midY - Double(sample) * (plotH / 2) * 0.85
        }

        path.move(to: CGPoint(x: padLeft, y: yPos(display[0])))

        let jumpThreshold = Float(amplitude) * 1.2

        for i in 1..<display.count {
            let x     = padLeft + Double(i) * step
            let y     = yPos(display[i])
            let prevY = yPos(display[i - 1])
            let prevX = padLeft + Double(i - 1) * step

            if waveform.hasVerticalTransitions && abs(display[i] - display[i - 1]) > jumpThreshold {
                path.addLine(to: CGPoint(x: prevX, y: prevY))
                let midX = (prevX + x) / 2.0
                path.addLine(to: CGPoint(x: midX, y: prevY))
                path.addLine(to: CGPoint(x: midX, y: y))
                path.addLine(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            let padLeft: Double = 44
            let padBottom: Double = 28
            let padTop: Double = 8
            let padRight: Double = 8

            let plotW = width - padLeft - padRight
            let plotH = height - padBottom - padTop
            let midY = padTop + plotH / 2

            let wavePath = buildWavePath(
                plotW: plotW,
                plotH: plotH,
                padLeft: padLeft,
                padTop: padTop,
                midY: midY
            )

            ZStack(alignment: .topLeading) {

                // Grid
                Path { path in
                    path.move(to: CGPoint(x: padLeft, y: midY))
                    path.addLine(to: CGPoint(x: padLeft + plotW, y: midY))
                    path.move(to: CGPoint(x: padLeft, y: padTop + plotH * 0.25))
                    path.addLine(to: CGPoint(x: padLeft + plotW, y: padTop + plotH * 0.25))
                    path.move(to: CGPoint(x: padLeft, y: padTop + plotH * 0.75))
                    path.addLine(to: CGPoint(x: padLeft + plotW, y: padTop + plotH * 0.75))
                    for i in 0...4 {
                        let x = padLeft + plotW * Double(i) / 4.0
                        path.move(to: CGPoint(x: x, y: padTop))
                        path.addLine(to: CGPoint(x: x, y: padTop + plotH))
                    }
                }
                .stroke(Color.white.opacity(0.08), lineWidth: 1)

                // Axes
                Path { path in
                    path.move(to: CGPoint(x: padLeft, y: padTop))
                    path.addLine(to: CGPoint(x: padLeft, y: padTop + plotH))
                    path.move(to: CGPoint(x: padLeft, y: padTop + plotH))
                    path.addLine(to: CGPoint(x: padLeft + plotW, y: padTop + plotH))
                }
                .stroke(Color.white.opacity(0.25), lineWidth: 1)

                if showGlow {
                    wavePath
                        .stroke(color.opacity(0.4), lineWidth: 6)
                        .blur(radius: 4)
                }

                wavePath
                    .stroke(color, lineWidth: 2)

                let ampStr     = String(format: "%.2f", amplitude)
                let halfAmpStr = String(format: "%.2f", amplitude / 2)

                Text("+\(ampStr)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(width: padLeft - 4, alignment: .trailing)
                    .position(x: (padLeft - 4) / 2, y: padTop + plotH * 0.075)

                Text("+\(halfAmpStr)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(width: padLeft - 4, alignment: .trailing)
                    .position(x: (padLeft - 4) / 2, y: padTop + plotH * 0.25)

                Text("0")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(width: padLeft - 4, alignment: .trailing)
                    .position(x: (padLeft - 4) / 2, y: midY)

                Text("-\(halfAmpStr)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(width: padLeft - 4, alignment: .trailing)
                    .position(x: (padLeft - 4) / 2, y: padTop + plotH * 0.75)

                Text("-\(ampStr)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(width: padLeft - 4, alignment: .trailing)
                    .position(x: (padLeft - 4) / 2, y: padTop + plotH * 0.925)

                let xLabels = (0..<5).map { i -> (Double, String) in
                    let frac = Double(i) / 4.0
                    let xPos = padLeft + plotW * frac
                    let label: String
                    if showPiLabels {
                        let piMultiple = frac * frequency * windowSeconds * 2.0
                        if i == 0 {
                            label = "0"
                        } else if piMultiple.truncatingRemainder(dividingBy: 1) == 0 {
                            label = String(format: "%.0f\u{03C0}", piMultiple)
                        } else {
                            label = String(format: "%.1f\u{03C0}", piMultiple)
                        }
                    } else {
                        let ms = windowSeconds * frac * 1000.0
                        label = ms < 1.0
                            ? String(format: "%.2fms", ms)
                            : String(format: "%.1fms", ms)
                    }
                    return (xPos, label)
                }
                ForEach(xLabels.indices, id: \.self) { i in
                    Text(xLabels[i].1)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(width: 44, alignment: .center)
                        .position(x: xLabels[i].0, y: padTop + plotH + padBottom * 0.6)
                }
            }
        }
    }
}
