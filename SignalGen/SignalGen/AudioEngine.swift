import AVFoundation
import Combine

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
        
        if format.isCompressed {
            try exportCompressed(samples: samples, sampleRate: exportSampleRate, format: format, to: url)
        } else {
            try exportPCM(samples: samples, sampleRate: exportSampleRate, format: format, to: url)
        }
    }
    
    private func exportPCM(samples: [Float], sampleRate: Double, format: ExportFormat, to url: URL) throws {
        let settings: [String: Any]
        
        switch format {
        case .flac:
            settings = [
                AVFormatIDKey:             kAudioFormatFLAC,
                AVSampleRateKey:           sampleRate,
                AVNumberOfChannelsKey:     1,
                AVLinearPCMBitDepthKey:    24,
                AVLinearPCMIsFloatKey:     false,
                AVLinearPCMIsBigEndianKey: false
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
        
        guard let avFormat = AVAudioFormat(settings: settings) else {
            throw NSError(domain: "AudioEngine", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Could not create audio format"])
        }
        
        let file = try AVAudioFile(forWriting: url, settings: settings)
        let bufferSize = 4096
        var offset = 0
        
        while offset < samples.count {
            let count = min(bufferSize, samples.count - offset)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: avFormat, frameCapacity: AVAudioFrameCount(count)) else { break }
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
                chunk.withUnsafeMutableBytes { raw in
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
}
