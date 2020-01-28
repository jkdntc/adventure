/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines the layered character scene class
      
*/


import SpriteKit

/// The location of a sprite encoded as a 32-bit integer on disk.
struct SpriteLocation {
    var fullLocation: UInt32

    var bossLocation: UInt8 {
      return UInt8(fullLocation & 0x000000FF) 
    }

    var wall: UInt8 { 
      return UInt8((fullLocation & 0x0000FF00) >> 8) 
    }

    var goblinCaveLocation: UInt8 { 
      return UInt8((fullLocation & 0x00FF0000) >> 16)
    }

    var heroSpawnLocation: UInt8 {
        return UInt8((fullLocation & 0xFF000000) >> 24)
    }
}

/// The location of a tree encoded as a 32-bit integer on disk.
struct TreeLocation {
    var fullLocation: UInt32

    var bigTreeLocation: UInt8 {
        return UInt8((fullLocation & 0x0000FF00) >> 8)
    }

    var smallTreeLocation: UInt8 {
        return UInt8((fullLocation & 0x00FF0000) >> 16)
    }
}

enum WorldLayer: Int {
    case Ground = 0, BelowCharacter, Character, AboveCharacter, Top
}

let kStartLives = 20 //TODO 3条命修改成x条命测试用
let kWorldLayerCount = 5
let kMinTimeInterval = (1.0 / 60.0)
let kMinHeroToEdgeDistance: CGFloat = 256.0                // minimum distance between hero and edge of camera before moving camera

class LayeredCharacterScene: SKScene {
    var world = SKNode()
    var layers = [SKNode]()

    var heroes = [HeroCharacter]()

    var defaultSpawnPoint = CGPoint.zero
    var worldMovedForUpdate = false

    var defaultPlayer = Player()

    // HUD
    var hudAvatar: SKSpriteNode!
    var hudLabel: SKLabelNode!
    var hudScore: SKLabelNode!
    var hudLifeHearts = [SKSpriteNode]()

    var lastUpdateTimeInterval = TimeInterval(0)

    override init(size: CGSize) {
        super.init(size: size)

        world.name = "world"
        for i in 0..<kWorldLayerCount {
            let layer = SKNode()
            layer.zPosition = CGFloat(i - kWorldLayerCount)
            world.addChild(layer)
            layers.append(layer)
        }

        addChild(world)
        
        buildHUD()
        updateHUDForPlayer(player: defaultPlayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func addNode(node: SKNode, atWorldLayer layer: WorldLayer) {
        let layerNode = layers[layer.rawValue]

        layerNode.addChild(node)
    }

// HEROES
    func addHeroForPlayer(player: Player) -> HeroCharacter {
        if let hero = player.hero {
          if !hero.dying {
            hero.removeFromParent()
          }
        }

        let spawnPos = defaultSpawnPoint

        var hero: HeroCharacter
        switch player.charClass! {
            case .Warrior:
                hero = Warrior(atPosition: spawnPos, withPlayer: player)

            case .Archer:
                hero = Archer(atPosition: spawnPos, withPlayer: player)
        }

        let emitter = sSharedSpawnEmitter.copy() as! SKEmitterNode
        emitter.position = spawnPos
        addNode(node: emitter, atWorldLayer: .AboveCharacter)
        runOneShotEmitter(emitter: emitter, withDuration: 0.15)

        hero.fadeIn(duration: 2.0)
        hero.addToScene(scene: self)
        heroes.append(hero)

        player.hero = hero

        return hero
    }

    func heroWasKilled(hero: HeroCharacter) {
        let player = hero.player
    
        // Remove this hero from our list of heroes
        for (idx, obj) in heroes.enumerated() {
            if obj === hero {
                heroes.remove(at: idx)
                break
            }
        }
        
        #if os(iOS)
        // Disable touch movement, otherwise new hero will try to move to previously-touched location.
        player.moveRequested = false
        #endif

        let hero = addHeroForPlayer(player: player!)
        
        centerWorldOnCharacter(character: hero)
        //复活后将血条长满
        player!.livesLeft=kStartLives
        for heart in hudLifeHearts {
            heart.run(SKAction.fadeAlpha(to: 1.0, duration: 3.0))
        }
    }

// HUD and Scores
    func buildHUD() {
        let iconName = "iconWarrior_blue"
        let color = SKColor.green
        let fontName = "Copperplate"
        let hudX: CGFloat = 30
        let hudY: CGFloat = self.frame.size.height - 30
        let _: CGFloat = self.frame.size.width
    
        let hud = SKNode()
        
        // Add the avatar
        hudAvatar = SKSpriteNode(imageNamed: iconName)
        hudAvatar.setScale(0.5)
        hudAvatar.alpha = 0.5
        hudAvatar.position = CGPoint(x: hudX, y: self.frame.size.height - hudAvatar.size.height * 0.5 - 8)
        hud.addChild(hudAvatar)
    
        // Add the label
        hudLabel = SKLabelNode(fontNamed: fontName)
        hudLabel.text = "ME"
        hudLabel.fontColor = color
        hudLabel.fontSize = 16
        hudLabel.horizontalAlignmentMode = .left
        hudLabel.position = CGPoint(x: hudX + (hudAvatar.size.width * 1.0), y: hudY + 10 )
        hud.addChild(hudLabel)
        
        // Add the score.
        hudScore = SKLabelNode(fontNamed: fontName)
        hudScore.text = "SCORE: 0"
        hudScore.fontColor = color
        hudScore.fontSize = 16
        hudScore.horizontalAlignmentMode = .left
        hudScore.position = CGPoint(x: hudX + (hudAvatar.size.width * 1.0), y: hudY - 40 )
        hud.addChild(hudScore)
    
        // Add the life hearts.
        for j in 0..<kStartLives {
            let heart = SKSpriteNode(imageNamed: "lives.png")
            heart.setScale(0.4)
            let x = hudX + (hudAvatar.size.width * 1.0) + 18 + ((heart.size.width + 5) * CGFloat(j))
            let y = hudY - 10
            heart.position = CGPoint(x: x, y: y)
            hudLifeHearts.append(heart)
            hud.addChild(heart)
        }

        addChild(hud)
    }

    func updateHUDForPlayer(player: Player) {
        hudScore.text = "SCORE: \(player.score)"
    }

    func updateHUDAfterHeroDeathForPlayer(player: Player) {
        // Fade out the relevant heart - one-based livesLeft has already been decremented.
        let heartNumber = player.livesLeft
        
        let heart = hudLifeHearts[heartNumber]
        heart.run(SKAction.fadeAlpha(to: 0.0, duration: 3.0))
    }

    func addToScore(amount: Int, afterEnemyKillWithProjectile projectile: SKNode) {
        if let player = projectile.userData?[kPlayer] as? Player {
            player.score += amount
            updateHUDForPlayer(player: player)
        }
    }


// LOOP UPDATE
    override func update(_ currentTime: TimeInterval) {
        var timeSinceLast = currentTime - lastUpdateTimeInterval
        lastUpdateTimeInterval = currentTime

        if timeSinceLast > 1 {
            timeSinceLast = kMinTimeInterval
            worldMovedForUpdate = true
        }

        updateWithTimeSinceLastUpdate(timeSinceLast: timeSinceLast)

        if defaultPlayer.hero == nil {
            return
        }

        let hero = defaultPlayer.hero!
        
        if hero.dying {
            return
        }
        
        if defaultPlayer.moveForward {
            hero.move(direction: .Forward, withTimeInterval: timeSinceLast)
        } else if defaultPlayer.moveBack {
            hero.move(direction: .Back, withTimeInterval: timeSinceLast)
        }

        if defaultPlayer.moveLeft {
            hero.move(direction: .Left, withTimeInterval: timeSinceLast)
        } else if defaultPlayer.moveRight {
            hero.move(direction: .Right, withTimeInterval: timeSinceLast)
        }

        if defaultPlayer.fireAction {
            hero.performAttackAction()
        }

        #if os(iOS)
        if defaultPlayer.targetLocation != CGPointZero {
            if defaultPlayer.fireAction {
                hero.faceTo(defaultPlayer.targetLocation)
            }
            
            if defaultPlayer.moveRequested {
                if defaultPlayer.targetLocation != hero.position {
                    hero.moveTowards(defaultPlayer.targetLocation,
                                     withTimeInterval: timeSinceLast)
                } else {
                    defaultPlayer.moveRequested = false
                }
            }
        }

        #endif
    }

    func updateWithTimeSinceLastUpdate(timeSinceLast: TimeInterval) {
      // Overridden by subclasses
    }

    override func didSimulatePhysics() {
        if let defaultHero = defaultPlayer.hero {
            let heroPosition = defaultHero.position
            var worldPos = world.position

            let yCoordinate = worldPos.y + heroPosition.y
            if yCoordinate < kMinHeroToEdgeDistance {
                worldPos.y = worldPos.y - yCoordinate + kMinHeroToEdgeDistance
                worldMovedForUpdate = true
            } else if yCoordinate > (frame.size.height - kMinHeroToEdgeDistance) {
                worldPos.y = worldPos.y + (frame.size.height - yCoordinate) - kMinHeroToEdgeDistance
                worldMovedForUpdate = true
            }

            let xCoordinate = worldPos.x + heroPosition.x
            if xCoordinate < kMinHeroToEdgeDistance {
                worldPos.x = worldPos.x - xCoordinate + kMinHeroToEdgeDistance
                worldMovedForUpdate = true
            } else if xCoordinate > (frame.size.width - kMinHeroToEdgeDistance) {
                worldPos.x = worldPos.x + (frame.size.width - xCoordinate) - kMinHeroToEdgeDistance
                worldMovedForUpdate = true
            }

            world.position = worldPos

            updateAfterSimulatingPhysics()

            worldMovedForUpdate = false
        }
    }

    func updateAfterSimulatingPhysics() { }

// ASSET LOADING
    class func loadSceneAssetsWithCompletionHandler(completionHandler: @escaping () -> Void) {
        DispatchQueue.global(qos: .background).async {

            // Background Thread
            self.loadSceneAssets()
            DispatchQueue.main.async {
                // Run UI Updates
               
                completionHandler()
            }
        }
//
//        let queue = dispatch_get_main_queue()
//
//        let backgroundQueue = DispatchQueue.global(CLong(DispatchQueue.GlobalQueuePriority.high), 0)
//        backgroundQueue.async() {
//            self.loadSceneAssets()
//
//            dispatch_async(queue, completionHandler)
//        }
    }

    class func loadSceneAssets() {

    }

// MAPPING
    func centerWorldOnPosition(position: CGPoint) {
        world.position = CGPoint(x: -position.x + frame.midX,
                                 y: -position.y + frame.midY)
        worldMovedForUpdate = true
    }
    
    func centerWorldOnCharacter(character: Character) {
        centerWorldOnPosition(position: character.position)
    }
    
    func canSee(point: CGPoint, from vantagePoint: CGPoint) -> Bool {
        return false
    }
}
