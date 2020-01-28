/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines the class for the archer hero character
      
*/

import SpriteKit

let kArcherAttackFrames = 10
let kArcherGetHitFrames = 18
let kArcherDeathFrames = 42
let kArcherProjectileSpeed = 8.0

var sSharedArcherProjectile = SKSpriteNode()
var sSharedArcherProjectileEmitter = SKEmitterNode()
var sSharedArcherIdleAnimationFrames = [SKTexture]()
var sSharedArcherWalkAnimationFrames = [SKTexture]()
var sSharedArcherAttackAnimationFrames = [SKTexture]()
var sSharedArcherGetHitAnimationFrames = [SKTexture]()
var sSharedArcherDeathAnimationFrames = [SKTexture]()
var sSharedArcherDamageAction = SKAction()

var kLoadSharedArcherAssetsOnceToken = 0

class Archer: HeroCharacter {

	  // Initialization.
    convenience init(atPosition: CGPoint, withPlayer: Player) {
        let atlas = SKTextureAtlas(named: "Archer_Idle")
        let texture = atlas.textureNamed("archer_idle_0001.png")

        self.init(atPosition: atPosition, withTexture: texture, player: withPlayer)
  	}

    // Shared Assets.
    class func loadSharedAssets() {
        //dispatch_once(&kLoadSharedArcherAssetsOnceToken) {
        sSharedArcherProjectile = SKSpriteNode(color: SKColor.white, size: CGSize(width: 2.0, height: 24.0))
            sSharedArcherProjectile.name = "Projectile"
            
            // Assign the physics body; unwrap the physics body to configure it.
            sSharedArcherProjectile.physicsBody = SKPhysicsBody(circleOfRadius: kProjectileCollisionRadius)
            sSharedArcherProjectile.physicsBody!.categoryBitMask = ColliderType.Projectile.rawValue
            sSharedArcherProjectile.physicsBody!.collisionBitMask = ColliderType.Wall.rawValue
            sSharedArcherProjectile.physicsBody!.contactTestBitMask = sSharedArcherProjectile.physicsBody!.collisionBitMask

        sSharedArcherProjectileEmitter = SKEmitterNode.emitterNodeWithName(name: "ArcherProjectile")

        sSharedArcherIdleAnimationFrames = loadFramesFromAtlasWithName(atlasName: "Archer_Idle", baseFileName: "archer_idle_", numberOfFrames: kDefaultNumberOfIdleFrames)
        sSharedArcherWalkAnimationFrames = loadFramesFromAtlasWithName(atlasName: "Archer_Walk", baseFileName: "archer_walk_", numberOfFrames: kDefaultNumberOfWalkFrames)
        sSharedArcherAttackAnimationFrames = loadFramesFromAtlasWithName(atlasName: "Archer_Attack", baseFileName: "archer_attack_", numberOfFrames: kArcherAttackFrames)
        sSharedArcherGetHitAnimationFrames = loadFramesFromAtlasWithName(atlasName: "Archer_GetHit", baseFileName: "archer_getHit_", numberOfFrames: kArcherGetHitFrames)
        sSharedArcherDeathAnimationFrames = loadFramesFromAtlasWithName(atlasName: "Archer_Death", baseFileName: "archer_death_", numberOfFrames: kArcherDeathFrames)

            let actions = [
                SKAction.colorize(with: SKColor.white, colorBlendFactor: 10.0, duration: 0.0),
                SKAction.wait(forDuration: 0.75),
                SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.25)
            ]

            sSharedArcherDamageAction = SKAction.sequence(actions)
        //}
    }

    override func projectile() -> SKSpriteNode {
        return sSharedArcherProjectile
    }

    override func projectileEmitter() -> SKEmitterNode {
        return sSharedArcherProjectileEmitter
    }

    override func idleAnimationFrames() -> [SKTexture] {
        return sSharedArcherIdleAnimationFrames
    }

    override func walkAnimationFrames() -> [SKTexture] {
        return sSharedArcherWalkAnimationFrames
    }

    override func attackAnimationFrames() -> [SKTexture] {
        return sSharedArcherAttackAnimationFrames
    }

    override func getHitAnimationFrames() -> [SKTexture] {
        return sSharedArcherGetHitAnimationFrames
    }

    override func deathAnimationFrames() -> [SKTexture] {
        return sSharedArcherDeathAnimationFrames
    }

    override func damageAction() -> SKAction {
        return sSharedArcherDamageAction
    }
}
