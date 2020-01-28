/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines the class for the cave
      
*/

import SpriteKit

var kLoadSharedCaveAssetsOnceToken = 0

class Cave: EnemyCharacter {
    var smokeEmitter: SKEmitterNode?
    var timeUntilNextGenerate: CGFloat = 5000.0
    var activeGoblins = [Goblin]()
    var inactiveGoblins = [Goblin]()

    init(atPosition position: CGPoint) {
        let sprites = [sSharedCaveBase.copy() as! SKSpriteNode, sSharedCaveTop.copy() as! SKSpriteNode]
        super.init(sprites: sprites, atPosition:position, usingOffset: 50.0)

        timeUntilNextGenerate = 5.0 + 5.0 * unitRandom()

        for _ in 0..<caveCapacity {
            let goblin = Goblin(atPosition: position)
            goblin.cave = self
            inactiveGoblins.append(goblin)
        }

        movementSpeed = 0.0
        name = "GoblinCave"

        // make it AWARE!
        intelligence = SpawnAI(character: self, target: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configurePhysicsBody() {
        // Assign the physics body; unwrap the physics body to configure it.
        physicsBody = SKPhysicsBody(circleOfRadius: 90)
        physicsBody!.isDynamic = false
        physicsBody!.categoryBitMask = ColliderType.Cave.rawValue
        physicsBody!.collisionBitMask = ColliderType.Projectile.rawValue | ColliderType.Hero.rawValue
        physicsBody!.contactTestBitMask = ColliderType.Projectile.rawValue
        
        animated = false
        zPosition = -0.85
    }

    override func reset() {
        super.reset()

        animated = false
    }

    class func loadSharedAssets() {
        //dispatch_once(&kLoadSharedCaveAssetsOnceToken) {
            let atlas = SKTextureAtlas(named: "Environment")

            let fire: SKEmitterNode = SKEmitterNode.emitterNodeWithName(name: "CaveFire")
            fire.zPosition = 1
            let smoke: SKEmitterNode = SKEmitterNode.emitterNodeWithName(name: "CaveFireSmoke")

            let torch = SKNode()
            torch.addChild(fire)
            torch.addChild(smoke)

            sSharedCaveBase = SKSpriteNode(texture: atlas.textureNamed("cave_base.png"))

            torch.position = CGPoint(x: 83, y: 83)
            sSharedCaveBase.addChild(torch)

            let torchB = torch.copy() as! SKNode
            torch.position = CGPoint(x: -83, y: 83)
            sSharedCaveBase.addChild(torchB)

            sSharedCaveTop = SKSpriteNode(texture: atlas.textureNamed("cave_top.png"))

            sSharedCaveDamageEmitter = SKEmitterNode.emitterNodeWithName(name: "CaveDamage")
            sSharedCaveDeathEmitter = SKEmitterNode.emitterNodeWithName(name: "CaveDeathSmoke")

            sSharedCaveDeathSplort = SKSpriteNode(texture: atlas.textureNamed("cave_destroyed.png"))

            sSharedCaveDamageAction = SKAction.sequence([
                SKAction.colorize(with: SKColor.red, colorBlendFactor: 1.0, duration: 0.0),
                SKAction.wait(forDuration: 0.25),
                    SKAction.colorize(withColorBlendFactor: 0.0, duration:0.1)])
        //}
    }

    override func collidedWith(other: SKPhysicsBody) {
        if health > 0.0 {
            if (other.categoryBitMask & ColliderType.Projectile.rawValue) == ColliderType.Projectile.rawValue {
                let damage = 10.0
                applyCaveDamage(damage: damage, projectile: other.node!)
            }
        }
    }

    func applyCaveDamage(damage: Double, projectile: SKNode) {
        let killed = super.applyDamage(damage: damage)
        if killed {
            // give the player some points
        }

        // show damage
        updateSmokeForHealth()

        // show damage on parallax stacks
        for node in children as [SKNode] {
            node.run(sSharedCaveDamageAction)
        }
    }

    func updateSmokeForHealth() {
        if health > 75.0 || smokeEmitter != nil {
            return
        }

        let emitter: SKEmitterNode = sSharedCaveDeathEmitter.copy() as! SKEmitterNode
        emitter.position = position
        emitter.zPosition = -0.8
        smokeEmitter = emitter
        characterScene.addNode(node: emitter, atWorldLayer: .AboveCharacter)
    }

    override func performDeath() {
        super.performDeath()

        let splort = sSharedCaveDeathSplort.copy() as! SKSpriteNode
        splort.zPosition = -1.0
        splort.zRotation = virtualZRotation
        splort.position = position
        splort.alpha = 0.1
        splort.run(SKAction.fadeAlpha(to: 1.0, duration: 0.5))

        characterScene.addNode(node: splort, atWorldLayer: .BelowCharacter)

        run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.0, duration: 0.5),
            SKAction.removeFromParent()
        ]))
        if let smoke = smokeEmitter {
            smoke.run(SKAction.sequence([
                SKAction.wait(forDuration: 2.0),
                SKAction.run {
                    smoke.particleBirthRate = 2.0
                },
                SKAction.wait(forDuration: 2.0),
                SKAction.run {
                    smoke.particleBirthRate = 0.0
                },
                SKAction.wait(forDuration: 10.0),
                SKAction.fadeAlpha(to: 0.0, duration: 0.5),
                SKAction.removeFromParent()
            ]))
        }
    }

// LOOP UPDATE
    override func updateWithTimeSinceLastUpdate(interval: TimeInterval) {
        super.updateWithTimeSinceLastUpdate(interval: interval) // this triggers the update in the SpawnAI

        for goblin in activeGoblins {
            goblin.updateWithTimeSinceLastUpdate(interval: interval)
        }
    }

// GOBLIN TARGETING
    func stopGoblinsFromTargettingHero(target: Character) {
        for goblin in activeGoblins {
            goblin.intelligence.clearTarget(target: target)
        }
    }

// SPAWNING SUPPORT
    func generate() {
        if sSharedGoblinCap > 0 && sSharedGoblinAllocation >= sSharedGoblinCap {
            return
        }

        if inactiveGoblins.count > 0 {
            let goblin = inactiveGoblins.removeLast()

            let offset = caveCollisionRadius * 0.75
            let rot = adjustAssetOrientation(r: virtualZRotation)
            goblin.position = position.pointByAdding(point: CGPoint(x: cos(rot)*offset, y: sin(rot)*offset))

            goblin.addToScene(scene: characterScene)

            goblin.zPosition = -1.0

            goblin.fadeIn(duration: 0.5)

            activeGoblins.append(goblin)

            sSharedGoblinAllocation += 1
        }
    }

    func recycle(goblin: Goblin) {
        goblin.reset()
        if let index = activeGoblins.firstIndex(of: goblin) {
            activeGoblins.remove(at: index)
        }
        inactiveGoblins.append(goblin)
        sSharedGoblinAllocation -= 1
    }
}

let caveCollisionRadius: CGFloat = 90.0
let caveCapacity = 50
let sSharedGoblinCap = 32
var sSharedGoblinAllocation = 0
var sSharedCaveBase = SKSpriteNode()
var sSharedCaveTop = SKSpriteNode()
var sSharedCaveDeathSplort = SKSpriteNode()
var sSharedCaveDamageEmitter = SKEmitterNode()
var sSharedCaveDeathEmitter = SKEmitterNode()
var sSharedCaveDamageAction = SKAction()
