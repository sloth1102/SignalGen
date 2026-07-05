<div align="center">

# 〜 SignalGen 〜
### A native SwiftUI audio signal generator for macOS

[![Swift](https://img.shields.io/badge/Swift-5.9-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-000000?style=for-the-badge&logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey?style=for-the-badge&logo=apple&logoColor=white)](https://www.apple.com/macos/)

<img src="https://readme-typing-svg.demolab.com?font=Fira+Code&size=18&pause=1000&color=00FF9C&center=true&vCenter=true&width=500&lines=Generate.+Visualize.+Export.;Sine+%E2%80%A2+Square+%E2%80%A2+Sawtooth+%E2%80%A2+Triangle;Built+with+SwiftUI+%2B+AVFoundation" alt="Typing SVG" />

</div>

---

## 📸 Screenshots

<div align="center">

<img src="https://github.com/user-attachments/assets/a0f827ce-43c4-42d3-a6fb-d8e808b23b24" alt="Sawtooth" width="49%" />
<img src="https://github.com/user-attachments/assets/8d64247c-4ed1-4f40-bcec-bd6aacd755cf" alt="Sine" width="49%" />
<img src="https://github.com/user-attachments/assets/0a95ef02-5034-43c8-a2e4-22f9888b5641" alt="Triangle" width="49%" />
<img src="https://github.com/user-attachments/assets/73ae231d-f366-45c2-928d-c8fa9f32ed8e" alt="Square" width="49%" />

</div>

---

## ⚡ Overview

**SignalGen** is a lightweight, native macOS app for generating and exporting audio signals. Built entirely in SwiftUI, it renders real-time waveform visualizations and lets you export precisely-shaped audio to a wide range of industry-standard formats.

Whether you're testing audio equipment, calibrating hardware, exploring signal processing, or just want to generate a clean tone, SignalGen gives you a fast, native interface to do it.

---

## Waveforms

<div align="center">

| Sine | Square | Sawtooth | Triangle |
|:---:|:---:|:---:|:---:|
| Smooth, pure tone | Harmonic-rich, digital | Bright, buzzy | Soft, mellow |

</div>

Each waveform is rendered live with adjustable **frequency**, **amplitude**, and **phase shift** — visualized on a real-time graph with π-radian labeled axes.

---

## Export Formats

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

## Getting Started

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

Made by [Sloth](https://github.com/sloth1102)

</div>
