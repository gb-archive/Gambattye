//
//  TouchBarController.swift
//  Gambattye
//
//  Created by Ben Hetherington on 29/06/2017.
//  Copyright © 2017 Ben Hetherington. Licenced under the GPL v2 (see LICENCE).
//

import Cocoa

@available(macOS 10.12.2, *)
class TouchBarController: NSObject {
    
    @IBOutlet var touchBar: NSTouchBar?
    @IBOutlet var descriptionText: NSTextField?
    @IBOutlet var swapText: NSTextField?
    var buttons = [NSButton?]()
    
    @IBOutlet var button0: NSButton?
    @IBOutlet var button1: NSButton?
    @IBOutlet var button2: NSButton?
    @IBOutlet var button3: NSButton?
    @IBOutlet var button4: NSButton?
    @IBOutlet var button5: NSButton?
    @IBOutlet var button6: NSButton?
    @IBOutlet var button7: NSButton?
    @IBOutlet var button8: NSButton?
    @IBOutlet var button9: NSButton?
    
    var romURL: URL? {
        didSet {
            setUpDisplay()
        }
    }
    var console: Emulator.Console = .GBC {
        didSet {
            setUpDisplay()
        }
    }
    private(set) var shouldSave = false
    
    var saveState: ((Int) -> Void)?
    var loadState: ((Int) -> Void)?

    private weak var placeholderImage: NSImage?
    private let gbPlaceholderImage = #imageLiteral(resourceName: "No State (GB).png")
    private let gbcPlaceholderImage = #imageLiteral(resourceName: "No State (GBC).png")

    private var observers = [NSObjectProtocol]()

    override init() {
        super.init()
        NSNib(nibNamed: NSNib.Name("Touch Bar"), bundle: nil)?.instantiate(withOwner: self, topLevelObjects: nil)
        buttons = [button0, button1, button2, button3, button4, button5, button6, button7, button8, button9]
        setUpDisplay()
        
        observers += NotificationCenter.default.addObserver(forName: .OptionPressed, object: nil, queue: nil) { [weak self] _ in
            self?.shouldSave = true
            self?.setUpDisplay()
        }
        
        observers += NotificationCenter.default.addObserver(forName: .OptionReleased, object: nil, queue: nil) { [weak self] _ in
            self?.shouldSave = false
            self?.setUpDisplay()
        }
        
        observers += NotificationCenter.default.addObserver(forName: .SaveState, object: nil, queue: nil) { [weak self] _ in
            self?.setUpDisplay()
        }
    }
    
    func setUpDisplay() {
        placeholderImage = console == .GB ? gbPlaceholderImage : gbcPlaceholderImage
        let pathPrefix = romURL?.deletingPathExtension().path
        
        for button in buttons {
            if let pathPrefix = pathPrefix, let image = StateImage(fromState: URL(fileURLWithPath: pathPrefix + "_\(button!.tag).gqs"))?.toNSImage() {
                button?.image = image
                button?.isEnabled = true
            } else {
                button?.image = placeholderImage
                button?.isEnabled = false
            }
        }
        
        if shouldSave {
            descriptionText?.stringValue = NSLocalizedString("Save State:", comment: "Touch Bar Title")
            swapText?.stringValue = NSLocalizedString("Release ⌥ to load.", comment: "Touch Bar Subtitle")
            setAllAction(#selector(saveState(_:)))
            setAllEnabled(true)
        } else {
            descriptionText?.stringValue = NSLocalizedString("Restore State:", comment: "Touch Bar Title")
            swapText?.stringValue = NSLocalizedString("Hold ⌥ to save.", comment: "Touch Bar Subtitle")
            setAllAction(#selector(loadState(_:)))
        }
    }
    
    func setAllEnabled(_ enabled: Bool) {
        for button in buttons {
            button?.isEnabled = enabled
        }
    }
    
    func setAllAction(_ action: Selector?) {
        for button in buttons {
            button?.action = action
        }
    }
    
    @IBAction func saveState(_ sender: NSButton) {
        NotificationCenter.default.post(name: .SaveState, object: self, userInfo: ["id": sender.tag])
    }
    
    @IBAction func loadState(_ sender: NSButton) {
        NotificationCenter.default.post(name: .LoadState, object: self, userInfo: ["id": sender.tag])
    }
    
    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
}
