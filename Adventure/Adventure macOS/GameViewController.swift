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

class GameViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let scene = GameScene.newGameScene()
//
//        // Present the scene
//        let skView = self.view as! SKView
//        skView.presentScene(scene)
//
//        skView.ignoresSiblingOrder = true
//
//        skView.showsFPS = true
//        skView.showsNodeCount = true
        
        AdventureScene.loadSceneAssetsWithCompletionHandler {
            self.scene = AdventureScene(size: CGSize(width: 1024, height: 768))
            self.scene.scaleMode = SKSceneScaleMode.AspectFit

            self.skView.presentScene(self.scene)

            self.loadingProgressIndicator.stopAnimation(self)
            self.loadingProgressIndicator.hidden = true

            self.archerButton.alphaValue = 1.0
            self.warriorButton.alphaValue = 1.0
        }

        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsDrawCount = true
    }

}

