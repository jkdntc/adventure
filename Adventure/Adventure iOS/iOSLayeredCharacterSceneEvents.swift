/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines iOS-specific extensions for the layered character scene
      
*/

import SpriteKit

extension LayeredCharacterScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    //override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        if heroes.count < 1 || touches.count <= 0 {
            return
        }

        if defaultPlayer.movementTouch != nil {
            return
        }

        let touch = touches.first!

        defaultPlayer.targetLocation = touch.location(in: defaultPlayer.hero!.parent!)

        var wantsAttack = false
        let nodes = self.nodes(at: touch.location(in: self))

        let targetCategoryBitmask = ColliderType.GoblinOrBoss.rawValue | ColliderType.Cave.rawValue

        for node in nodes as [SKNode] {
            // There are multiple values for ColliderType. Need to check if we want to attack.
            if let body = node.physicsBody {
                if body.categoryBitMask & targetCategoryBitmask > 0 {
                    wantsAttack = true
                }
            }
        }

        defaultPlayer.fireAction = wantsAttack
        defaultPlayer.moveRequested = !wantsAttack
        defaultPlayer.movementTouch = touch
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if heroes.count < 1 || touches.count <= 0 {
            return
        }

        if let touch: UITouch = defaultPlayer.movementTouch {
            if touches.contains(touch) {
                defaultPlayer.targetLocation = touch.location(in: defaultPlayer.hero!.parent!)

                if !defaultPlayer.fireAction {
                    defaultPlayer.moveRequested = true
                }
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if heroes.count < 1 || touches.count <= 0 {
            return
        }
        
        if let touch = defaultPlayer.movementTouch {
            if touches.contains(touch) {
                defaultPlayer.movementTouch = nil
                defaultPlayer.fireAction = false
            }
        }
    }
}
