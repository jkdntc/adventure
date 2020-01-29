/*
  Copyright (C) 2015 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  Defines the class for goblin enemies.
*/

import SpriteKit

final class Goblin: EnemyCharacter, SharedAssetProvider {
    // MARK: Types
    
    struct Constants {
        static let minimumSize: CGFloat = 0.5
        static let sizeVariance: CGFloat = 0.35
    }
    
    // MARK: Properties
    
    weak var cave: Cave?
    
    // MARK: Initializers

    convenience init(atPosition position: CGPoint) {
        let atlas = SKTextureAtlas(named: "Goblin_Idle")
		let atlasTexture = atlas.textureNamed("goblin_idle_0001.png")

        self.init(texture: atlasTexture, atPosition: position)

		movementSpeed *= unitRandom()

		self.setScale(Constants.minimumSize + (unitRandom() * Constants.sizeVariance))
		name = "Enemy"

		intelligence = ChaseArtificialIntelligence(character: self)
	}

    // MARK: Setup
    
    override func configurePhysicsBody() {
        // Assign the physics body; unwrap the physics body to configure it.
        physicsBody = SKPhysicsBody(circleOfRadius: collisionRadius)
        physicsBody!.categoryBitMask = ColliderType.GoblinOrBoss.rawValue
        physicsBody!.collisionBitMask = ColliderType.all
        physicsBody!.contactTestBitMask = ColliderType.Projectile.rawValue
    }

    // MARK: Scene Processing Support
    
    override func animationDidComplete(animation animationState: AnimationState) {
        super.animationDidComplete(animation: animationState)

        if animationState == AnimationState.Death {
            removeAllActions()

            let actions = [
                SKAction.wait(forDuration: 0.75),
                SKAction.fadeOut(withDuration: 1.0),
                SKAction.run {
                    self.removeFromParent()
                    self.cave?.recycle(goblin: self)
                }
            ]

            let actionSequence = SKAction.sequence(actions)
            run(actionSequence)
        }
    }

    override func collidedWith(other otherBody: SKPhysicsBody) {
        if isDying  {
            return
        }

        if otherBody.categoryBitMask & ColliderType.Projectile.rawValue == ColliderType.Projectile.rawValue {
            // Apply random damage of either 100% or 50%
            requestedAnimation = .GetHit
            var damage = 100.0
            if arc4random_uniform(2) == 0 {
                damage = 50.0
            }

            let killed = applyDamage(damage: damage, projectile: otherBody.node)
            if killed {
                characterScene.addToScore(amount: 10, afterEnemyKillWithProjectile: otherBody.node!)
            }
        }
    }

    override func performDeath() {
        removeAllActions()

        let splort = Goblin.deathSplort.copy() as! SKSpriteNode
        splort.zPosition = -1.0
        splort.zRotation = unitRandom() * CGFloat(Double.pi)
        splort.position = position
        splort.alpha = 0.5
        characterScene.addNode(node: splort, atWorldLayer: .Ground)
        splort.run(SKAction.fadeOut(withDuration: 10.0))

        super.performDeath()

        physicsBody?.collisionBitMask = 0
        physicsBody?.contactTestBitMask = 0
        physicsBody?.categoryBitMask = 0
        physicsBody = nil
    }

    override func reset() {
        super.reset()

        alpha = 1
        removeAllChildren()
        configurePhysicsBody()
    }

    // MARK: Asset Pre-loading

    class func loadSharedAssets() {
        let atlas = SKTextureAtlas(named: "Environment")

        idleAnimationFrames = loadFramesFromAtlasWithName(atlasName: "Goblin_Idle")
        walkAnimationFrames = loadFramesFromAtlasWithName(atlasName: "Goblin_Walk")
        attackAnimationFrames = loadFramesFromAtlasWithName(atlasName: "Goblin_Attack")
        getHitAnimationFrames = loadFramesFromAtlasWithName(atlasName: "Goblin_GetHit")
        deathAnimationFrames = loadFramesFromAtlasWithName(atlasName: "Goblin_Death")
        damageEmitter = SKEmitterNode(fileNamed: "Damage")!
        deathSplort = SKSpriteNode(texture: atlas.textureNamed("minionSplort.png"))

        let actions = [
            SKAction.colorize(with: SKColor.white, colorBlendFactor: 1.0, duration: 0.0),
            SKAction.wait(forDuration: 0.75),
            SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.1)
        ]

        damageAction = SKAction.sequence(actions)
    }
}
