//
//  GameViewController.swift
//  Adventure macOS
//
//  Created by 姜坤 on 2020/1/28.
//  Copyright © 2020 姜坤. All rights reserved.
//

import Cocoa
import SpriteKit
import GameplayKit

class AdventureWindow: NSWindow {}

class GameViewController: NSViewController,NSWindowDelegate {
        // MARK: Properties

    var scene: AdventureScene!
    
    @IBOutlet weak var coverView: NSView!
    
    @IBOutlet weak var skView: SKView!
    
    @IBOutlet weak var loadingProgressIndicator: NSProgressIndicator!
    
    @IBOutlet weak var gameLogo: NSImageView!
    
    @IBOutlet weak var archerButton: NSButton!
    
    @IBOutlet weak var warriorButton: NSButton!
    
    var adventureWindow: NSWindow {
        let windows = NSApplication.shared.windows
        
        for window in windows {
            if window is AdventureWindow {
                return window
            }
        }
        
        fatalError("There should always be an Adventure window.")
    }
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear() {
        loadingProgressIndicator.startAnimation(self)

        AdventureScene.loadSceneAssetsWithCompletionHandler { loadedScene in
            let adventureWindow = self.adventureWindow
            
            adventureWindow.delegate = self
            self.scene = loadedScene
            
            let windowRect = adventureWindow.contentRect(forFrameRect: adventureWindow.frame)
            self.scene.size = windowRect.size
            
            self.scene.finishedMovingToView = {
                // Remove the cover view so the user can see the scene.
                self.coverView.removeFromSuperview()
                
                // Stop the loading indicator once the scene is completely loaded.
                self.loadingProgressIndicator.stopAnimation(self)
                self.loadingProgressIndicator.isHidden = true
                
                // Show the character selection buttons so the user can start playing.
                self.archerButton.alphaValue = 1.0
                self.warriorButton.alphaValue = 1.0
            }
            
            self.skView.presentScene(self.scene)
        }

        #if DEBUG
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsDrawCount = true
        #endif
    }
    // MARK: NSWindowDelegate
    
    func windowWillResize(sender: NSWindow, toSize frameSize: NSSize) -> NSSize {
        scene.isPaused = true
        return frameSize
    }
    
    private func windowDidResize(notification: NSNotification) {
        let window = notification.object as! NSWindow
        let windowSize = window.contentRect(forFrameRect: window.frame)
        
        scene.size = CGSize(width: windowSize.width, height: windowSize.height)
        view.frame.size = CGSize(width: windowSize.width, height: windowSize.height)
        
        scene.isPaused = false
    }
    
    // MARK: IBActions

    @IBAction func chooseArcher(_: AnyObject) {
        scene.startLevel(heroType: .Archer)
        gameLogo.isHidden = true

        archerButton.alphaValue = 0.0
        warriorButton.alphaValue = 0.0
    }

    @IBAction func chooseWarrior(_: AnyObject) {
        scene.startLevel(heroType: .Warrior)
        gameLogo.isHidden = true

        archerButton.alphaValue = 0.0
        warriorButton.alphaValue = 0.0
    }
}

