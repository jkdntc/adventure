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
    var scene: AdventureScene!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        let scene = GameScene.newGameScene()
//
//        // Present the scene
        let skView = self.view as! SKView
        skView.presentScene(scene)
//
        skView.ignoresSiblingOrder = false
//
//        skView.showsFPS = true
//        skView.showsNodeCount = true
        
        AdventureScene.loadSceneAssetsWithCompletionHandler {
            self.scene = AdventureScene(size: CGSize(width: 1024, height: 768))
            self.scene.scaleMode = SKSceneScaleMode.aspectFit

            skView.presentScene(self.scene)

//            self.loadingProgressIndicator.stopAnimation(self)
//            self.loadingProgressIndicator.hidden = true
//
//            self.archerButton.alphaValue = 1.0
//            self.warriorButton.alphaValue = 1.0
            self.scene.startLevel(charClass: CharacterClass.Archer)
            let image = SKSpriteNode(imageNamed: "archer_attack_0003.png")

            // Add the image to the scene.
            self.scene.addChild(image)
        }

        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsDrawCount = true
        //scene.startLevel(charClass: CharacterClass.Archer)
    }

}

