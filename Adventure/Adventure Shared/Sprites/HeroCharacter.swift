/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines the common class for hero characters
      
*/

import SpriteKit

let kCharacterCollisionRadius: CGFloat = 40.0
let kHeroProjectileSpeed: CGFloat = 480.0
let kHeroProjectileLifetime: TimeInterval = 1.0
let kHeroProjectileFadeOutTime: TimeInterval = 0.6

class HeroCharacter: Character {
    var player: Player!

    init(atPosition position: CGPoint, withTexture texture: SKTexture? = nil, player: Player) {
        self.player = player
        super.init(texture: texture, atPosition: position)

        zRotation = CGFloat(M_PI)
        zPosition = -0.25
        name = "Hero"
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func configurePhysicsBody() {
        // Assign the physics body; unwrap the physics body to configure it.
        physicsBody = SKPhysicsBody(circleOfRadius: kCharacterCollisionRadius)
        physicsBody!.categoryBitMask = ColliderType.Hero.rawValue
        physicsBody!.collisionBitMask = ColliderType.GoblinOrBoss.rawValue | ColliderType.Hero.rawValue | ColliderType.Wall.rawValue | ColliderType.Cave.rawValue
        physicsBody!.contactTestBitMask = ColliderType.GoblinOrBoss.rawValue
    }

    override func collidedWith(other: SKPhysicsBody) {
        if other.categoryBitMask & ColliderType.GoblinOrBoss.rawValue == 0 {
            return
        }

        if let enemy = other.node as? Character {
            if !enemy.dying {
                applyDamage(damage: 5.0)
                requestedAnimation = .GetHit
            }
        }
    }

    override func animationDidComplete(animation: AnimationState) {
        super.animationDidComplete(animation: animation)

        switch animation {
            case .Death:
                let actions = [SKAction.wait(forDuration: 4.0),
                               SKAction.run {
                                self.characterScene.heroWasKilled(hero: self)
                               },
                               SKAction.removeFromParent()]
                run(SKAction.sequence(actions))

            case .Attack:
                fireProjectile()
            case .GetHit: //受到攻击后减血条
                for i in 0...kStartLives {
                    if player.livesLeft>0 && player.livesLeft >= Int(self.health)/(100/kStartLives) {
                        player.livesLeft -= 1
                        self.characterScene.updateHUDAfterHeroDeathForPlayer(player: player)
                    }
                    else {
                        break;
                    }
                }
           default:
                () // Do nothing
        }
    }

// PROJECTILES
    func fireProjectile() {
        let waitAction = SKAction.wait(forDuration: kHeroProjectileFadeOutTime)
        let fadeAction = SKAction.fadeOut(withDuration: kHeroProjectileLifetime - kHeroProjectileFadeOutTime)
        let removeAction = SKAction.removeFromParent()
        let data: NSMutableDictionary = ["kPlayer" : self.player]
        let sequence = [waitAction, fadeAction, removeAction]
        var rot = zRotation
        for i in -2...2 { //循环计算出所有要发射的导弹
            let projectile = self.projectile()!.copy() as! SKSpriteNode
            projectile.position = position

            let emitter = projectileEmitter()!.copy() as! SKEmitterNode
            emitter.targetNode = scene!.childNode(withName: "world")
            projectile.addChild(emitter)

            characterScene.addNode(node: projectile, atWorldLayer: .Character)
            //依zRotation向两侧角度每次加或减0.1
            if i > 0 {
                rot += 0.1
            }
            if i < 0 {
                rot += -0.1
            }
            if i==0 { //0表示正前方
                rot = zRotation
                projectile.run(projectileSoundAction())
            }

            projectile.zRotation = rot
            let x = -sin(rot) * kHeroProjectileSpeed * CGFloat(kHeroProjectileLifetime)
            let y =  cos(rot) * kHeroProjectileSpeed * CGFloat(kHeroProjectileLifetime)
            projectile.run(SKAction.moveBy(x: x, y: y, duration: kHeroProjectileLifetime))

            projectile.run(SKAction.sequence(sequence))

            projectile.userData = data
        }
    }

    func projectile() -> SKSpriteNode? {
        return nil
    }

    func projectileEmitter() -> SKEmitterNode? {
        return nil
    }

    func projectileSoundAction() -> SKAction {
        return sSharedProjectileSoundAction
    }

    class func loadSharedHeroAssets() {
        sSharedProjectileSoundAction = SKAction.playSoundFileNamed("magicmissile.caf", waitForCompletion: false)
    }
}

var sSharedProjectileSoundAction = SKAction()

let kPlayer = "kPlayer"
