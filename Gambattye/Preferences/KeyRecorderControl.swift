//
//  KeyRecorderControl.swift
//  Gambattye
//
//  Created by Ben10do on 09/04/2017.
//  Copyright © 2017 Ben10do. All rights reserved.
//

import Cocoa
import ShortcutRecorder

class KeyRecorderControl: SRRecorderControl {
    
    // TODO: See if we can mitigate this mess
    
    var name: String = "" {
        didSet {
            objectValue = UserDefaults.standard.dictionary(forKey: name + "ButtonKey")
        }
    }
    
    override var toolTip: String? {
        get {
            return nil
        }
        set {
            super.toolTip = nil
        }
    }
    
    override func accessibilityLabel() -> String! {
        let ret = super.accessibilityLabel()
        Swift.print(ret ?? "nil")
        return ret
    }
    
    override func view(_ view: NSView, stringForToolTip tag: NSToolTipTag, point: NSPoint, userData data: UnsafeMutableRawPointer?) -> String {
        let returnValue = super.view(view, stringForToolTip: tag, point: point, userData: data)
        if returnValue == SRLoc("Use old shortcut") {
            return "Use previous key"
        } else {
            return returnValue
        }
    }
    
    override func flagsChanged(with event: NSEvent) {
        let modifierFlags = event.modifierFlags.intersection(SRCocoaModifierFlagsMask)
        if isRecording && !modifierFlags.isEmpty { // Ignore the Fn key
            if areModifierFlagsValid(event.modifierFlags, forKeyCode: event.keyCode) {
                let newObjectValue: [AnyHashable: Any] = [SRShortcutKeyCode: event.keyCode,
                                                          SRShortcutModifierFlagsKey: modifierFlags.rawValue,
                                                          SRShortcutCharacters: 0,
                                                          SRShortcutCharactersIgnoringModifiers: 0]
                
                endRecording(withObjectValue: newObjectValue)
            }
        }
    }
    
    override func clearAndEndRecording() {
        // All controls should be assigned, so don't let this happen
    }
    
    override func clearButtonRect() -> NSRect {
        return NSRect(x: NSMaxX(bounds) - 4.0 - 1.0,
                      y: NSMinY(bounds),
                      width: 0.0,
                      height: 25.0)
    }
    
}
