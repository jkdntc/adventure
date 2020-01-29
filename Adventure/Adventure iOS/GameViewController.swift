//
//  GameViewController.swift
//  Adventure iOS
//
//  Created by 姜坤 on 2020/1/28.
//  Copyright © 2020 姜坤. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    var scene: AdventureScene!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Present the scene
        let skView = self.view as! SKView
        
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
        
        skView.presentScene(scene)
        
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
