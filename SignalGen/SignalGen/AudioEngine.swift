import AVFoundation
import AudioToolbox
import Combine
import lame

enum Waveform: String, CaseIterable {
    case sine     = "Sine"
    case square   = "Square"
    case sawtooth = "Sawtooth"
    case triangle = "Triangle"

    var hasVerticalTransitions: Bool {
        switch self {
        case .square, .sawtooth: return true
        case .sine, .triangle:   return false
        }
    }
}

class AudioEngine: ObservableObject {
    private var engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    
    @Published var isPlaying = false
    @Published var frequency: Double = 440.0  { didSet { updateDisplayBuffer() } }
    @Published var amplitude: Double = 0.5    { didSet { updateDisplayBuffer() } }
    @Published var waveform: Waveform = .sine { didSet { updateDisplayBuffer() } }
    @Published var phaseShift: Double = 0.0   { didSet { updateDisplayBuffer() } }
    
    @Published var waveformBuffer: [Float] = Array(repeating: 0, count: 256)
    
    private var phase: Double = 0.0
    private let sampleRate: Double = 44100.0
    
    let displayWindowSeconds: Double = 0.02
    
    init() {
        updateDisplayBuffer()
    }
    
    func start() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        
        sourceNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let phaseIncrement = (2.0 * Double.pi * self.frequency) / self.sampleRate
            
            for frame in 0..<Int(frameCount) {
                let sample = Float(self.amplitude * self.generateSample(phase: self.phase))
                self.phase += phaseIncrement
                if self.phase >= 2.0 * Double.pi { self.phase -= 2.0 * Double.pi }
                
                for buffer in ablPointer {
                    let buf = buffer.mData?.assumingMemoryBound(to: Float.self)
                    buf?[frame] = sample
                }
            }
            
            return noErr
        }
        
        engine.attach(sourceNode!)
        engine.connect(sourceNode!, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 1.0
        
        do {
            try engine.start()
            isPlaying = true
        } catch {
            print("AudioEngine failed to start: \(error)")
        }
    }
    
    func stop() {
        engine.stop()
        if let node = sourceNode {
            engine.detach(node)
        }
        sourceNode = nil
        phase = 0
        isPlaying = false
        updateDisplayBuffer()
    }
    
    private func updateDisplayBuffer() {
        let cyclesInWindow = frequency * displayWindowSeconds
        let pointsPerCycle = 64
        let displayCount = max(256, Int(cyclesInWindow * Double(pointsPerCycle)))
        let twoPi = 2.0 * Double.pi
        
        var display: [Float] = []
        display.reserveCapacity(displayCount)
        
        for i in 0..<displayCount {
            let t = Double(i) / Double(displayCount)
            let cyclePos = (t * cyclesInWindow).truncatingRemainder(dividingBy: 1.0)
            let p = cyclePos * twoPi
            display.append(Float(amplitude * generateSample(phase: p)))
        }
        
        waveformBuffer = display
    }
    
    func generateSample(phase: Double) -> Double {
        let p = phase + phaseShift
        switch waveform {
        case .sine:
            return sin(p)
        case .square:
            return p.truncatingRemainder(dividingBy: 2.0 * Double.pi) < Double.pi ? 1.0 : -1.0
        case .sawtooth:
            let normalized = p.truncatingRemainder(dividingBy: 2.0 * Double.pi)
            return (normalized / Double.pi) - 1.0
        case .triangle:
            let normalized = p.truncatingRemainder(dividingBy: 2.0 * Double.pi)
            return 1.0 - (2.0 / Double.pi) * abs(normalized - Double.pi)
        }
    }
    
    // MARK: - Export
    
    enum ExportFormat: String, CaseIterable {
        case wav   = "WAV"
        case aiff  = "AIFF"
        case caf   = "CAF"
        case mp3   = "MP3"
        case mp2   = "MP2"
        case m4a   = "M4A"
        case opus  = "Opus"
        case flac  = "FLAC"
        case au    = "AU"
        case ac3   = "AC3"
        
        var fileExtension: String {
            switch self {
            case .wav:   return "wav"
            case .aiff:  return "aiff"
            case .caf:   return "caf"
            case .mp3:   return "mp3"
            case .mp2:   return "mp2"
            case .m4a:   return "m4a"
            case .opus:  return "opus"
            case .flac:  return "flac"
            case .au:    return "au"
            case .ac3:   return "ac3"
            }
        }
        
        var isCompressed: Bool {
            switch self {
            case .wav, .aiff, .caf, .au, .flac: return false
            case .mp3, .mp2, .m4a, .opus, .ac3: return true
            }
        }
        
        var avFileType: AVFileType {
            switch self {
            case .wav:   return .wav
            case .aiff:  return .aiff
            case .caf:   return .caf
            case .mp3:   return .mp3
            case .mp2:   return AVFileType(rawValue: "public.mp2")
            case .m4a:   return .m4a
            case .opus:  return AVFileType(rawValue: "org.xiph.opus")
            case .flac:  return AVFileType(rawValue: "org.xiph.flac")
            case .au:    return AVFileType(rawValue: "public.au-audio")
            case .ac3:   return .ac3
            }
        }
        
        var compressedFormatID: AudioFormatID? {
            switch self {
            case .mp3:  return kAudioFormatMPEGLayer3
            case .mp2:  return kAudioFormatMPEGLayer2
            case .m4a:  return kAudioFormatMPEG4AAC
            case .opus: return kAudioFormatOpus
            case .ac3:  return kAudioFormatAC3
            default:    return nil
            }
        }
        
        var bytesPerSecond: Int {
            switch self {
            case .wav, .aiff, .caf, .au: return 44100 * 4
            case .flac:  return 44100 * 2
            case .m4a:   return 256_000 / 8
            case .mp3:   return 192_000 / 8
            case .mp2:   return 192_000 / 8
            case .opus:  return 128_000 / 8
            case .ac3:   return 192_000 / 8
            }
        }
        
        var label: String { rawValue }

        /// Formats macOS has no built-in encoder for and that we haven't
        /// wired up a third-party encoder for. MP3 is handled by a bundled
        /// LAME encoder (see exportMP3).
        var requiresThirdPartyEncoder: Bool {
            switch self {
            case .mp2, .opus, .ac3: return true
            default: return false
            }
        }
    }
    
    func estimatedFileSizeBytes(duration: Double, format: ExportFormat) -> Int {
        return 100 + Int(duration * Double(format.bytesPerSecond))
    }
    
    func exportAudio(duration: Double, format: ExportFormat, to url: URL) throws {
        let exportSampleRate: Double = 44100.0
        let totalFrames = Int(duration * exportSampleRate)
        
        var samples = [Float](repeating: 0, count: totalFrames)
        var exportPhase: Double = 0.0
        let phaseIncrement = (2.0 * Double.pi * frequency) / exportSampleRate
        for i in 0..<totalFrames {
            samples[i] = Float(amplitude * generateSample(phase: exportPhase))
            exportPhase += phaseIncrement
            if exportPhase >= 2.0 * Double.pi { exportPhase -= 2.0 * Double.pi }
        }
        
        if format == .mp3 {
            try exportMP3(samples: samples, sampleRate: exportSampleRate, to: url)
        } else if format.isCompressed {
            try exportCompressed(samples: samples, sampleRate: exportSampleRate, format: format, to: url)
        } else {
            try exportPCM(samples: samples, sampleRate: exportSampleRate, format: format, to: url)
        }
    }

    /// Encodes to MP3 using the bundled LAME encoder (added via SPM — see
    /// project setup notes). AVFoundation has no MP3 encoder on macOS at
    /// all, so this doesn't go through AVAssetWriter/AVAudioFile like the
    /// other formats.
    private func exportMP3(samples: [Float], sampleRate: Double, to url: URL) throws {
        guard let gfp = lame_init() else {
            throw NSError(domain: "AudioEngine", code: 10,
                          userInfo: [NSLocalizedDescriptionKey: "Could not initialize the MP3 encoder"])
        }
        defer { lame_close(gfp) }

        lame_set_in_samplerate(gfp, Int32(sampleRate))
        lame_set_num_channels(gfp, 1)
        lame_set_brate(gfp, 192)   // CBR 192 kbps — matches the size estimate shown in Export
        lame_set_quality(gfp, 2)   // 0 = best/slowest, 9 = worst/fastest; 2 is effectively best quality at a sane speed

        guard lame_init_params(gfp) >= 0 else {
            throw NSError(domain: "AudioEngine", code: 11,
                          userInfo: [NSLocalizedDescriptionKey: "Could not configure the MP3 encoder"])
        }

        FileManager.default.createFile(atPath: url.path, contents: nil)
        guard let handle = FileHandle(forWritingAtPath: url.path) else {
            throw NSError(domain: "AudioEngine", code: 12,
                          userInfo: [NSLocalizedDescriptionKey: "Could not open output file for MP3 export"])
        }
        defer { try? handle.close() }

        let chunkFrames = 8192
        // LAME's documented worst-case output buffer size for a given input chunk.
        let outBufSize = Int(1.25 * Double(chunkFrames)) + 7200
        var outBuffer = [UInt8](repeating: 0, count: outBufSize)

        var offset = 0
        while offset < samples.count {
            let count = min(chunkFrames, samples.count - offset)
            let written: Int32 = samples.withUnsafeBufferPointer { pcm -> Int32 in
                let chunkPtr = pcm.baseAddress!.advanced(by: offset)
                return outBuffer.withUnsafeMutableBufferPointer { out in
                    // Mono: LAME wants a left-channel pointer; we pass the
                    // same pointer as "right" since some builds still read it.
                    lame_encode_buffer_ieee_float(gfp, chunkPtr, chunkPtr, Int32(count), out.baseAddress, Int32(outBufSize))
                }
            }
            guard written >= 0 else {
                throw NSError(domain: "AudioEngine", code: 13,
                              userInfo: [NSLocalizedDescriptionKey: "MP3 encoding failed (code \(written))"])
            }
            if written > 0 {
                handle.write(Data(bytes: outBuffer, count: Int(written)))
            }
            offset += count
        }

        let flushed = outBuffer.withUnsafeMutableBufferPointer { out in
            lame_encode_flush(gfp, out.baseAddress, Int32(outBufSize))
        }
        guard flushed >= 0 else {
            throw NSError(domain: "AudioEngine", code: 14,
                          userInfo: [NSLocalizedDescriptionKey: "MP3 flush failed (code \(flushed))"])
        }
        if flushed > 0 {
            handle.write(Data(bytes: outBuffer, count: Int(flushed)))
        }
    }
    
    private func exportPCM(samples: [Float], sampleRate: Double, format: ExportFormat, to url: URL) throws {
        let settings: [String: Any]
        
        switch format {
        case .flac:
            // FLAC's file-level settings describe a *compressed* format —
            // no linear-PCM keys belong here. Mixing them in (as before)
            // produced an AVAudioFormat that couldn't back a PCM write
            // buffer, which is what crashed a few lines down.
            settings = [
                AVFormatIDKey:            kAudioFormatFLAC,
                AVSampleRateKey:          sampleRate,
                AVNumberOfChannelsKey:    1,
                AVEncoderBitDepthHintKey: 24
            ]
        default:
            settings = [
                AVFormatIDKey:               kAudioFormatLinearPCM,
                AVSampleRateKey:             sampleRate,
                AVNumberOfChannelsKey:       1,
                AVLinearPCMBitDepthKey:      32,
                AVLinearPCMIsFloatKey:       true,
                AVLinearPCMIsBigEndianKey:   false,
                AVLinearPCMIsNonInterleaved: false
            ]
        }
        
        // Validate up front so a bad settings dict surfaces as a normal,
        // catchable Swift error instead of failing deeper inside AVFoundation.
        guard AVAudioFormat(settings: settings) != nil else {
            throw NSError(domain: "AudioEngine", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Could not create a valid \(format.rawValue) format"])
        }

        // Buffers we hand to AVAudioFile must always be plain float32 PCM —
        // that's the "processing format" AVAudioFile expects, and it
        // converts internally into whatever `settings` describes (PCM at
        // another depth, or losslessly into FLAC). Previously this buffer
        // was built from the *file's* target format, which is only
        // correct by coincidence for the plain-PCM formats.
        guard let bufferFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                                sampleRate: sampleRate,
                                                channels: 1,
                                                interleaved: false) else {
            throw NSError(domain: "AudioEngine", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Could not create PCM buffer format"])
        }

        let file = try AVAudioFile(forWriting: url, settings: settings)
        let bufferSize = 4096
        var offset = 0
        
        while offset < samples.count {
            let count = min(bufferSize, samples.count - offset)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: bufferFormat, frameCapacity: AVAudioFrameCount(count)) else { break }
            buffer.frameLength = AVAudioFrameCount(count)
            let ch = buffer.floatChannelData![0]
            for i in 0..<count { ch[i] = samples[offset + i] }
            try file.write(from: buffer)
            offset += count
        }
    }
    
    private func exportCompressed(samples: [Float], sampleRate: Double, format: ExportFormat, to url: URL) throws {
        guard let formatID = format.compressedFormatID else {
            throw NSError(domain: "AudioEngine", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "No compressed format ID for \(format.rawValue)"])
        }

        // AVAssetWriterInput(mediaType:outputSettings:) raises an
        // Objective-C exception — not a Swift error — if you hand it a
        // formatID macOS has no encoder for. Swift's do/catch cannot catch
        // that, so the app terminates. mp3/mp2/ac3 (and opus on most
        // systems) have no registered encoder component on macOS: Apple
        // ships decoders for them but never shipped encoders. Check first
        // and fail with an ordinary, catchable error instead of crashing.
        guard hasEncoderComponent(for: formatID) else {
            throw NSError(domain: "AudioEngine", code: 6, userInfo: [
                NSLocalizedDescriptionKey:
                    "macOS has no built-in \(format.rawValue) encoder — Apple only ships a decoder for this format, so AVFoundation can't write it. Try M4A, WAV, AIFF, CAF, AU, or FLAC instead."
            ])
        }

        let outputSettings: [String: Any] = [
            AVFormatIDKey:         formatID,
            AVSampleRateKey:       sampleRate,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey:   192_000
        ]
        
        let sourceSettings: [String: Any] = [
            AVFormatIDKey:               kAudioFormatLinearPCM,
            AVSampleRateKey:             sampleRate,
            AVNumberOfChannelsKey:       1,
            AVLinearPCMBitDepthKey:      32,
            AVLinearPCMIsFloatKey:       true,
            AVLinearPCMIsBigEndianKey:   false,
            AVLinearPCMIsNonInterleaved: false
        ]
        
        guard let sourceFormat = AVAudioFormat(settings: sourceSettings),
              let outputFormat = AVAudioFormat(settings: outputSettings) else {
            throw NSError(domain: "AudioEngine", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "Could not create format for \(format.rawValue)"])
        }
        
        let writer = try AVAssetWriter(outputURL: url, fileType: format.avFileType)
        let input  = AVAssetWriterInput(mediaType: .audio, outputSettings: outputSettings)
        
        guard writer.canAdd(input) else {
            throw NSError(domain: "AudioEngine", code: 4,
                          userInfo: [NSLocalizedDescriptionKey: "AVAssetWriter cannot add input for \(format.rawValue)"])
        }
        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        let bufferSize = 4096
        var offset = 0
        var pts = CMTime.zero
        
        let sema = DispatchSemaphore(value: 0)
        
        input.requestMediaDataWhenReady(on: DispatchQueue(label: "audioExport")) {
            while input.isReadyForMoreMediaData && offset < samples.count {
                let count = min(bufferSize, samples.count - offset)
                
                var blockBuffer: CMBlockBuffer?
                var sampleBuffer: CMSampleBuffer?
                let dataSize = count * MemoryLayout<Float>.size
                
                var chunk = Array(samples[offset..<(offset + count)])
                _ = chunk.withUnsafeMutableBytes { raw in
                    CMBlockBufferCreateWithMemoryBlock(
                        allocator: nil,
                        memoryBlock: raw.baseAddress,
                        blockLength: dataSize,
                        blockAllocator: kCFAllocatorNull,
                        customBlockSource: nil,
                        offsetToData: 0,
                        dataLength: dataSize,
                        flags: 0,
                        blockBufferOut: &blockBuffer
                    )
                }
                
                var formatDesc: CMAudioFormatDescription?
                var asbd = sourceFormat.streamDescription.pointee
                CMAudioFormatDescriptionCreate(allocator: nil, asbd: &asbd, layoutSize: 0, layout: nil, magicCookieSize: 0, magicCookie: nil, extensions: nil, formatDescriptionOut: &formatDesc)
                
                let timing = CMSampleTimingInfo(duration: CMTimeMake(value: 1, timescale: Int32(sampleRate)),
                                                presentationTimeStamp: pts,
                                                decodeTimeStamp: .invalid)
                var timingCopy = timing
                CMSampleBufferCreate(allocator: nil, dataBuffer: blockBuffer, dataReady: true, makeDataReadyCallback: nil, refcon: nil, formatDescription: formatDesc, sampleCount: count, sampleTimingEntryCount: 1, sampleTimingArray: &timingCopy, sampleSizeEntryCount: 0, sampleSizeArray: nil, sampleBufferOut: &sampleBuffer)
                
                if let sb = sampleBuffer {
                    input.append(sb)
                }
                
                pts = CMTimeAdd(pts, CMTimeMake(value: Int64(count), timescale: Int32(sampleRate)))
                offset += count
            }
            
            if offset >= samples.count {
                input.markAsFinished()
                writer.finishWriting { sema.signal() }
            }
        }
        
        sema.wait()
        
        if writer.status == .failed {
            throw writer.error ?? NSError(domain: "AudioEngine", code: 5,
                                          userInfo: [NSLocalizedDescriptionKey: "Export failed for \(format.rawValue)"])
        }
    }

    /// Asks CoreAudio's component registry directly (no AVFoundation, no
    /// exceptions possible) whether an encoder exists for `formatID` on
    /// this machine. If Apple ever adds one, this starts returning true
    /// automatically — nothing here needs to change.
    private func hasEncoderComponent(for formatID: AudioFormatID) -> Bool {
        var description = AudioComponentDescription(
            componentType: kAudioEncoderComponentType,
            componentSubType: formatID,
            componentManufacturer: 0,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        return AudioComponentFindNext(nil, &description) != nil
    }
}
