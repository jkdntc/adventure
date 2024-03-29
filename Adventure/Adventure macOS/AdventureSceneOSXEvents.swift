/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Defines OS X-specific extensions to the layered character scene.
*/

import SpriteKit

extension AdventureScene {
    // MARK: Types
    
    // Represents different types of user input that result in actions.
    private enum KeyEventFlag {
        case MoveForward
        case MoveLeft
        case MoveRight
        case MoveBackward
        case Fire

        // The mapping from key events to their player actions. //TODO UnicodeScalar
        private static let keyMapping: [UnicodeScalar: KeyEventFlag] = [
            "w":                    .MoveForward,
            //UnicodeScalar(0xF700):  .MoveForward,
            "s":                    .MoveBackward,
            //UnicodeScalar(0xF701):  .MoveBackward,
            "d":                    .MoveRight,
            //UnicodeScalar(0xF703):  .MoveRight,
            "a":                    .MoveLeft,
            //UnicodeScalar(0xF702):  .MoveLeft,
            " ":                    .Fire
        ]
        
        // MARK: Initializers
        
        init?(unicodeScalar: UnicodeScalar) {
            if let event = KeyEventFlag.keyMapping[unicodeScalar] {
                self = event
            }
            else {
                return nil
            }
        }
    }
    
    // MARK: Event Handling
    
    override func keyDown(with event: NSEvent) {
        handleKeyEvent(event: event, keyDown: true)
    }
    
    override func keyUp(with event: NSEvent) {
        handleKeyEvent(event: event, keyDown: false)
    }
    
    // MARK: Convenience
    
    private func handleKeyEvent(event: NSEvent, keyDown: Bool) {
        if event.modifierFlags.rawValue & NSEvent.ModifierFlags.numericPad.rawValue == NSEvent.ModifierFlags.numericPad.rawValue
        {
            if let charactersIgnoringModifiers = event.charactersIgnoringModifiers {
                applyEventsFromEventString(eventString: charactersIgnoringModifiers, keyDown: keyDown)
            }
        }
        
        if let characters = event.characters {
            applyEventsFromEventString(eventString: characters, keyDown: keyDown)
        }
    }
    
    func applyEventsFromEventString(eventString: String, keyDown: Bool) {
        for key in eventString.unicodeScalars {
            if let flag = KeyEventFlag(unicodeScalar: key) {
                switch flag {
                    case .MoveForward: defaultPlayer.moveForward = keyDown
                    case .MoveBackward: defaultPlayer.moveBackward = keyDown
                    case .MoveLeft: defaultPlayer.moveLeft = keyDown
                    case .MoveRight: defaultPlayer.moveRight = keyDown
                    case .Fire: defaultPlayer.fireAction = keyDown
                }
            }
        }
    }
}
