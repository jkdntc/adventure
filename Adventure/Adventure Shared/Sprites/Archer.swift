/*
  Copyright (C) 2015 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  Defines the class for the archer hero character.
*/

import SpriteKit

final class Archer: HeroCharacter, SharedAssetProvider {
    // MARK: Initializers

    convenience init(atPosition: CGPoint, withPlayer: Player) {
        let atlas = SKTextureAtlas(named: "Archer_Idle")
        let texture = atlas.textureNamed("archer_idle_0001.png")

        self.init(atPosition: atPosition, withTexture: texture, player: withPlayer)
  	}

    // MARK: Asset Pre-loading

    class func loadSharedAssets() {
        idleAnimationFrames = loadFramesFromAtlasWithName(atlasName: "Archer_Idle")
        walkAnimationFrames = loadFramesFromAtlasWithName(atlasName: "Archer_Walk")
        attackAnimationFrames = loadFramesFromAtlasWithName(atlasName: "Archer_Attack")
        getHitAnimationFrames = loadFramesFromAtlasWithName(atlasName: "Archer_GetHit")
        deathAnimationFrames = loadFramesFromAtlasWithName(atlasName: "Archer_Death")
        
        let archerProjectile = SKSpriteNode(color: SKColor.white, size: CGSize(width: 2.0, height: 24.0))
        archerProjectile.name = "Projectile"
        
        // Assign the physics body; unwrap the physics body to configure it.
        archerProjectile.physicsBody = SKPhysicsBody(circleOfRadius: HeroCharacter.Constants.projectileCollisionRadius)
        archerProjectile.physicsBody!.categoryBitMask = ColliderType.Projectile.rawValue
        archerProjectile.physicsBody!.collisionBitMask = ColliderType.Wall.rawValue
        archerProjectile.physicsBody!.contactTestBitMask = archerProjectile.physicsBody!.collisionBitMask
        
        projectile = archerProjectile

        projectileEmitter = SKEmitterNode(fileNamed: "ArcherProjectile")!

        let actions = [
            SKAction.colorize(with: SKColor.white, colorBlendFactor: 10.0, duration: 0.0),
            SKAction.wait(forDuration: 0.75),
            SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.25)
        ]

        damageAction = SKAction.sequence(actions)
    }
}
