//
//  Document.swift
//  Gambattye
//
//  Created by Ben10do on 28/01/2017.
//  Copyright © 2017 Ben10do. All rights reserved.
//

import Cocoa

class Document: NSDocument {
    
    var romData = Data()
    let emulator = GB()
    var timer = DispatchSource.makeTimerSource()
    let inputGetter = InputGetter()
    let audioEngine: AudioEngine?
    var internalSoundEnabled = true
    let emulationStateAccessQueue = DispatchQueue(label: "com.ben10do.Gambattye.EmulationStateAccess")
    
    var videoBuffer = [UInt32](repeating: 0xF8F8F8, count: 160 * 144)
    var dataProvider: CGDataProvider?
    
    @IBOutlet var gbWindow: NSWindow? {
        didSet {
            gbWindow?.makeFirstResponder(inputGetter)
        }
    }
    @IBOutlet var display: GBView?

    override init() {
        // Add your subclass-specific initialization here.
        do {
            try audioEngine = AudioEngine()
        } catch {
            Swift.print("Failed to initialise audio engine: \(error.localizedDescription)")
            audioEngine = nil
            internalSoundEnabled = false
        }
        
        super.init()
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }

    override var windowNibName: String? {
        // Returns the nib file name of the document
        return "Document"
    }

    override func data(ofType typeName: String) throws -> Data {
        return romData
    }
    
    func beginEmulation() {
        emulator.setInputGetter(inputGetter)
        soundEnabled = true
        
        let startTime = DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + 100000000)
        let frameRate = 262144.0 / 4389.0
        timer.scheduleRepeating(deadline: startTime, interval: 1 / (frameRate * 4.0))
        
        dataProvider = CGDataProvider.init(data: Data(bytesNoCopy: &videoBuffer, count: 4 * videoBuffer.count, deallocator: .none) as CFData)!
        
        
        let dispatchHandler = DispatchWorkItem() { [weak self] in
            self?.emulate()
        }
        
        timer.setEventHandler(handler: dispatchHandler)
        
        if #available(OSX 10.12, *) {
            timer.activate()
        } else {
            // Fallback on earlier versions
            timer.resume()
        }
    }
    
    func emulate() {
        var samples = 35112 / 4
        var audioBuffer = [UInt32](repeating: 0, count: samples + 2064)
        
        var result = 0
        emulationStateAccessQueue.sync {
            result = emulator.run(withVideoBuffer: &videoBuffer, pitch: 160, audioBuffer: &audioBuffer, samples: &samples)
            
            if internalSoundEnabled, let audioEngine = audioEngine {
                audioBuffer.removeLast(audioBuffer.count - samples)
                audioEngine.pushData(newData: audioBuffer)
            }
        }
            
        if result != -1, let dataProvider = dataProvider {
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue).union([.byteOrder32Little])
            let image = CGImage(width: 160, height: 144, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 4 * 160, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo, provider: dataProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
            
            DispatchQueue.main.async { [weak self] in
                if let display = self?.display {
                    display.image = image
                }
            }
        }
    }
    
    func saveSaveData() {
        emulator.saveSaveData()
    }
    
    override func read(from url: URL, ofType typeName: String) throws {
        try romData = Data(contentsOf: url) // Just in case someone tries to save the ROM
        try emulator.load(from: url, flags: [])
        beginEmulation()
    }
    
    @IBAction func reset(_: Any?) {
        emulationStateAccessQueue.sync {
            emulator.reset()
            audioEngine?.restartAudio()
        }
    }
    
    dynamic var soundEnabled: Bool {
        get {
            return internalSoundEnabled && canEnableSound
        }
        set {
            if canEnableSound {
                if newValue {
                    do {
                        try audioEngine?.startAudio()
                        internalSoundEnabled = newValue
                    } catch {
                        NSAlert(error: error).runModal()
                        internalSoundEnabled = false
                    }
                } else {
                    audioEngine?.stopAudio()
                    internalSoundEnabled = newValue
                }
            }
        }
    }
    
    dynamic var canEnableSound: Bool {
        get {
            return audioEngine != nil
        }
    }
    
    override var displayName: String! {
        get {
            // If possible, use the title in the ROM header
            return emulator.isLoaded ? emulator.romTitle : super.displayName
        }
        set {
            super.displayName = newValue
        }
    }
    
    deinit {
        audioEngine?.stopAudio()
        timer.cancel()
    }

}

