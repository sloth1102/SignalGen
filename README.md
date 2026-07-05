<div align="center">

# 〜 SignalGen 〜

### A native SwiftUI audio signal generator for macOS

[![Swift](https://img.shields.io/badge/Swift-5.9-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-000000?style=for-the-badge&logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey?style=for-the-badge&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](LICENSE)

<img src="https://readme-typing-svg.demolab.com?font=Fira+Code&size=18&pause=1000&color=00FF9C&center=true&vCenter=true&width=500&lines=Generate.+Visualize.+Export.;Sine+%E2%80%A2+Square+%E2%80%A2+Sawtooth+%E2%80%A2+Triangle;Built+with+SwiftUI+%2B+AVFoundation" alt="Typing SVG" />

</div>

---

## ⚡ Overview

**SignalGen** is a lightweight, native macOS app for generating and exporting audio signals. Built entirely in SwiftUI, it renders real-time waveform visualizations and lets you export precisely-shaped audio to a wide range of industry-standard formats.

Whether you're testing audio equipment, calibrating hardware, exploring signal processing, or just want to generate a clean tone, SignalGen gives you a fast, native interface to do it.

---

## 🌊 Waveforms

<div align="center">

| Sine | Square | Sawtooth | Triangle |
|:---:|:---:|:---:|:---:|
| 〰️ | ⏹️ | 📈 | 🔺 |
| Smooth, pure tone | Harmonic-rich, digital | Bright, buzzy | Soft, mellow |

</div>

Each waveform is rendered live with adjustable **frequency**, **amplitude**, and **phase shift** — visualized on a real-time graph with π-radian labeled axes.

---

## 📤 Export Formats

SignalGen supports exporting your generated signal directly to disk via `AVFoundation`, with support for:

<div align="center">

`.wav` &nbsp;•&nbsp; `.aiff` &nbsp;•&nbsp; `.caf` &nbsp;•&nbsp; `.mp3` &nbsp;•&nbsp; `.mp2` &nbsp;•&nbsp; `.m4a` &nbsp;•&nbsp; `.opus` &nbsp;•&nbsp; `.flac` &nbsp;•&nbsp; `.au` &nbsp;•&nbsp; `.ac3`

</div>

Uncompressed, lossless, or compressed — pick the format that fits your workflow.

---

## ✨ Features

- 🎛️ **Live waveform generation** — sine, square, sawtooth, and triangle
- 📊 **Real-time visualization** with π-radian x-axis labeling
- 🔄 **Phase shift control** via an intuitive slider
- 💾 **Multi-format export** across 10 audio file types
- 🖥️ **Native SwiftUI interface** — fast, responsive, and macOS-native
- 📍 **Menu bar integration** for quick access

---

## 🛠️ Tech Stack

<div align="center">

![Swift](https://img.shields.io/badge/-Swift-F05138?style=flat-square&logo=swift&logoColor=white)
![AVFoundation](https://img.shields.io/badge/-AVFoundation-000000?style=flat-square&logo=apple&logoColor=white)
![SwiftUI](https://img.shields.io/badge/-SwiftUI-0066CC?style=flat-square&logo=swift&logoColor=white)

</div>

Built with `SwiftUI` for the interface, and `AVFoundation` for audio buffer generation and file export.

---

## 🚀 Getting Started

```bash
git clone https://github.com/sloth1102/SignalGen.git
cd SignalGen
open SignalGen.xcodeproj
```

Build and run in Xcode — macOS only, no external dependencies required.

---

## 🗺️ Roadmap

- [ ] Custom waveform editor
- [ ] Frequency sweep / chirp mode
- [ ] Multi-channel output
- [ ] Preset save/load

---

<div align="center">

Made with 🎧 by [Parker](https://github.com/sloth1102)

</div>
