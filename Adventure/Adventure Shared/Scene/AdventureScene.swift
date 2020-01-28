/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        The primary scene class for Adventure
      
*/

import SpriteKit

// Set this to true to cheat and end up next to the level boss
let cheat = true

enum CharacterClass {
  case Warrior
  case Archer
}

class AdventureScene: LayeredCharacterScene, SKPhysicsContactDelegate {
    var levelMap = createDataMap(mapName: "map_level.png").assumingMemoryBound(to: SpriteLocation.self)
    var treeMap = createDataMap(mapName: "map_trees.png").assumingMemoryBound(to: TreeLocation.self)
    var parallaxSprites = [ParallaxSprite]()
    var trees = [Tree]()
    var particleSystems = [SKEmitterNode]()
    var goblinCaves = [Cave]()
    var levelBoss: Boss?
    
    override init(size: CGSize) {
        super.init(size: size)

        buildWorld()

        centerWorldOnPosition(position: defaultSpawnPoint)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

// WORLD BUILDING

    func buildWorld() {
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self

        addBackgroundTiles()
        addSpawnPoints()
        //addTrees()
        addCollisionWalls()
    }

    func addBackgroundTiles() {
        for tileNode in sBackgroundTiles {
            addNode(node: tileNode, atWorldLayer: .Ground)
        }
    }

    func addSpawnPoints() {
        for y in 0..<kLevelMapSize {
            for x in 0..<kLevelMapSize {
                let location = CGPoint(x: x, y: y)
                let spot = queryLevelMap(point: location)

                let worldPoint = convertLevelMapPointToWorldPoint(location: location)

                if spot.bossLocation <= 200 {
                    levelBoss = Boss(atPosition:worldPoint)
                    levelBoss!.addToScene(scene: self)
                } else if spot.goblinCaveLocation >= 200 {
                    let cave = Cave(atPosition: worldPoint)
                    goblinCaves.append(cave)
                    parallaxSprites.append(cave)
                    cave.addToScene(scene: self)
                } else if spot.heroSpawnLocation >= 200 {
                    defaultSpawnPoint = worldPoint
                }
            }
        }
    }

    func addTrees() {
        for y in 0..<kLevelMapSize {
            for x in 0..<kLevelMapSize {
                let location = CGPoint(x: x, y: y)
                let spot = queryTreeMap(point: location)
                let treePos = convertLevelMapPointToWorldPoint(location: location)
                var treeLayer = WorldLayer.Top

                var tree: Tree
                if spot.smallTreeLocation >= 200 {
                    treeLayer = .AboveCharacter
                    tree = sSharedSmallTree.copy() as! Tree
                } else if spot.bigTreeLocation >= 200 {
                    tree = sSharedBigTree.copy() as! Tree

                    var emitter: SKEmitterNode
                    if arc4random_uniform(2) == 1 {
                        emitter = sSharedLeafEmitterA.copy() as! SKEmitterNode
                    } else {
                        emitter = sSharedLeafEmitterB.copy() as! SKEmitterNode
                    }

                    emitter.position = treePos
                    emitter.isPaused = true
                    addNode(node: emitter, atWorldLayer: .AboveCharacter)
                    particleSystems.append(emitter)
                } else {
                    continue
                }

                tree.position = treePos
                tree.zRotation = unitRandom()
                addNode(node: tree, atWorldLayer: .Top)
                parallaxSprites.append(tree)
                trees.append(tree)
            }
        }

        free(treeMap)
    }

    func addCollisionWalls() {
        var filled = [UInt8](unsafeUninitializedCapacity: kLevelMapSize * kLevelMapSize)
        { buffer, initializedCount in
//            for x in 1..<5 {
//                buffer[x] = UInt8(x)
//            }
//            buffer[0] = 10
            initializedCount = kLevelMapSize * kLevelMapSize
        }

        var numVolumes = 0, numBlocks = 0

        for y in 0..<kLevelMapSize {
            for x in 0..<kLevelMapSize {
                let location = CGPoint(x: x, y: y)
                let spot = queryLevelMap(point: location)

                let worldPoint = convertLevelMapPointToWorldPoint(location: location)

                if spot.wall < 200 {
                    continue // no wall
                }

                var horizontalDistanceFromLeft = x
                var nextSpot = spot
                while (horizontalDistanceFromLeft < kLevelMapSize && nextSpot.wall >= 200 &&
                       filled[(y * kLevelMapSize) + horizontalDistanceFromLeft] < 1) {
                    horizontalDistanceFromLeft += 1
                        nextSpot = queryLevelMap(point: CGPoint(x: horizontalDistanceFromLeft, y: y))
                }

                let wallWidth = horizontalDistanceFromLeft - x
                var verticalDistanceFromTop = y

                if wallWidth > 8 {
                    nextSpot = spot
                    while verticalDistanceFromTop < kLevelMapSize && nextSpot.wall >= 200 {
                        verticalDistanceFromTop += 1
                        nextSpot = queryLevelMap(point: CGPoint(x: x + (wallWidth / 2), y: verticalDistanceFromTop))
                    }

                    var wallHeight = verticalDistanceFromTop - y
                    for j in y..<verticalDistanceFromTop {
                        for i in x..<horizontalDistanceFromLeft {
                            filled[(j * kLevelMapSize) + i] = 255
                            numBlocks += 1
                        }
                    }

                    addCollisionWallAtWorldPoint(worldPoint: worldPoint, width: CGFloat(kLevelMapDivisor * wallWidth), height: CGFloat(kLevelMapDivisor * wallHeight))
                    numVolumes += 1
                }
            }
        }

        for x in 0..<kLevelMapSize {
            for y in 0..<kLevelMapSize {
                let location = CGPoint(x: x, y: y)
                let spot = queryLevelMap(point: location)

                let worldPoint = convertLevelMapPointToWorldPoint(location: location)

                if spot.wall < 200 || filled[(y * kLevelMapSize) + x] > 0 {
                    continue
                }

                var verticalDistanceFromTop = y
                var nextSpot = spot
                while verticalDistanceFromTop < kLevelMapSize && nextSpot.wall >= 200 && filled[(verticalDistanceFromTop * kLevelMapSize) + x] < 1 {
                    verticalDistanceFromTop += 1
                    nextSpot = queryLevelMap(point: CGPoint(x: x, y: verticalDistanceFromTop))
                }

                let wallHeight = verticalDistanceFromTop - y
                var horizontalDistanceFromLeft = x

                if wallHeight > 8 {
                    nextSpot = spot
                    while horizontalDistanceFromLeft < kLevelMapSize && nextSpot.wall >= 200 {
                        horizontalDistanceFromLeft += 1
                        nextSpot = queryLevelMap(point: CGPoint(x: horizontalDistanceFromLeft, y: y + (wallHeight / 2)))
                    }

                    let wallLength = horizontalDistanceFromLeft - x
                    for j in y..<verticalDistanceFromTop {
                        for i in x..<horizontalDistanceFromLeft {
                            filled[(j * kLevelMapSize) + i] = 255
                            numBlocks += 1
                        }
                    }
                    addCollisionWallAtWorldPoint(worldPoint: worldPoint, width: CGFloat(kLevelMapDivisor * wallLength), height: CGFloat(kLevelMapDivisor * wallHeight))
                    numVolumes += 1
                }
            }
        }
    }

    func addCollisionWallAtWorldPoint(worldPoint: CGPoint, width: CGFloat, height: CGFloat) {
        let size = CGSize(width: width, height: height)
        let wallNode = SKNode()
        wallNode.position = CGPoint(x: worldPoint.x + size.width * 0.5, y: worldPoint.y - size.height * 0.5)
        
        // Assign the physics body; unwrap the physics body to configure it.
        wallNode.physicsBody = SKPhysicsBody(rectangleOf: size)
        wallNode.physicsBody!.isDynamic = false
        wallNode.physicsBody!.categoryBitMask = ColliderType.Wall.rawValue
        wallNode.physicsBody!.collisionBitMask = 0

        addNode(node: wallNode, atWorldLayer: .Ground)
    }

    // MAPPING
    func queryLevelMap(point: CGPoint) -> SpriteLocation {
        let index = (Int(point.y) * kLevelMapSize) + Int(point.x)
        return levelMap[index]
    }

    func queryTreeMap(point: CGPoint) -> TreeLocation {
        let index = (Int(point.y) * kLevelMapSize) + Int(point.x)
        return treeMap[index]
    }

    func convertLevelMapPointToWorldPoint(location: CGPoint) -> CGPoint {
        // Given a level map pixel point, convert up to a world point.
        // This determines which "tile" the point falls in and centers within that tile.
        let x =   (Int(location.x) * kLevelMapDivisor) - (kWorldCenter + (kWorldTileSize/2))
        let y = -((Int(location.y) * kLevelMapDivisor) - (kWorldCenter + (kWorldTileSize/2)))

        return CGPoint(x: x, y: y)
    }

    func convertWorldPointToLevelMapPoint(location: CGPoint) -> CGPoint {
        let x = (Int(location.x) + kWorldCenter) / kLevelMapDivisor
        let y = (kWorldSize - (Int(location.y) + kWorldCenter)) / kLevelMapDivisor
        return CGPoint(x: x, y: y)
    }

    override func canSee(point: CGPoint, from vantagePoint: CGPoint) -> Bool {
        let a = convertWorldPointToLevelMapPoint(location: point)
        let b = convertWorldPointToLevelMapPoint(location: vantagePoint)

        let deltaX = b.x - a.x
        let deltaY = b.y - a.y
        let dist = a.distanceTo(p: b)
        let inc = 1.0 / dist
        var p = CGPoint.zero
        for i in stride(from: 0.0, to: inc, by: inc) {
        //for var i: CGFloat = 0.0; i < inc; i += inc {
            p.x = a.x + i * deltaX
            p.y = a.y + i * deltaY

            let location = queryLevelMap(point: p)
            if (location.wall > 200) {
                return false
            }
        }
        return true
    }
    
// HEROES
    override func heroWasKilled(hero: HeroCharacter) {
        for cave in goblinCaves {
            cave.stopGoblinsFromTargettingHero(target: hero)
        }
        
        super.heroWasKilled(hero: hero)
    }
    
// LEVEL START
    func startLevel(charClass: CharacterClass) {
        defaultPlayer.charClass = charClass
        addHeroForPlayer(player: defaultPlayer)

        if cheat {
            var bossPosition = levelBoss!.position
            bossPosition.x += 128
            bossPosition.y += 512
            defaultPlayer.hero!.position = bossPosition
        }
    }

// LOOP UPDATE
    override func updateWithTimeSinceLastUpdate(timeSinceLast: TimeInterval) {
        for hero in heroes {
            hero.updateWithTimeSinceLastUpdate(interval: timeSinceLast)
        }

        levelBoss?.updateWithTimeSinceLastUpdate(interval: timeSinceLast)

        for cave in goblinCaves {
            cave.updateWithTimeSinceLastUpdate(interval: timeSinceLast)
        }
    }

    override func updateAfterSimulatingPhysics() {
        let position = defaultPlayer.hero!.position

        for tree in trees {
            if tree.position.distanceTo(p: position) < 1024 {
                tree.updateAlphaWithScene(scene: self)
            }
        }

        if !worldMovedForUpdate {
            return
        }

        for emitter in particleSystems {
            let emitterIsVisible = (emitter.position.distanceTo(p: position) < 1024)
            if !emitterIsVisible && !emitter.isPaused {
                emitter.isPaused = true
            } else if emitterIsVisible && emitter.isPaused {
                emitter.isPaused = false
            }
        }

        for sprite in parallaxSprites {
            if sprite.position.distanceTo(p: position) < 1024 {
                sprite.updateOffset()
            }
        }
    }

// PHYSICS DELEGATE
    func didBeginContact(contact: SKPhysicsContact) {
        if let character = contact.bodyA.node as? Character {
            character.collidedWith(other: contact.bodyB)
        }

        if let character = contact.bodyB.node as? Character {
            character.collidedWith(other: contact.bodyA)
        }

        let rawProjectileType = ColliderType.Projectile.rawValue
        // 导弹打到墙则爆炸消失,其他则穿透
        if (contact.bodyA.categoryBitMask & rawProjectileType == rawProjectileType || contact.bodyB.categoryBitMask & rawProjectileType == rawProjectileType) && (contact.bodyA.categoryBitMask & ColliderType.Wall.rawValue == ColliderType.Wall.rawValue || contact.bodyB.categoryBitMask & ColliderType.Wall.rawValue == ColliderType.Wall.rawValue) {
            if let projectile = (contact.bodyA.categoryBitMask & rawProjectileType) == rawProjectileType ? contact.bodyA.node : contact.bodyB.node {
                projectile.run(SKAction.removeFromParent())

                let emitter = sSharedProjectileSparkEmitter.copy() as! SKEmitterNode
                addNode(node: emitter, atWorldLayer: .AboveCharacter)
                emitter.position = projectile.position

                runOneShotEmitter(emitter: emitter, withDuration: 0.15)
            }
        }
    }


// PRELOADING
    override class func loadSceneAssets() {
        AdventureScene.loadBackgroundTiles()

        Goblin.loadSharedAssets()
        Warrior.loadSharedAssets()
        Archer.loadSharedAssets()
        Cave.loadSharedAssets()
        HeroCharacter.loadSharedHeroAssets()
        Boss.loadSharedAssets()

        sSharedLeafEmitterA = .emitterNodeWithName(name: "Leaves_01")
        sSharedLeafEmitterB = .emitterNodeWithName(name: "Leaves_02")
        sSharedProjectileSparkEmitter = .emitterNodeWithName(name: "ProjectileSplat")
        sSharedSpawnEmitter = .emitterNodeWithName(name: "Spawn")
        
        // Load Trees
        let atlas = SKTextureAtlas(named: "Environment")
        var sprites = [
            SKSpriteNode(texture: atlas.textureNamed("small_tree_base.png")),
            SKSpriteNode(texture: atlas.textureNamed("small_tree_middle.png")),
            SKSpriteNode(texture: atlas.textureNamed("small_tree_top.png"))
        ]
        sSharedSmallTree = Tree(sprites:sprites, usingOffset:25.0)

        sprites = [
            SKSpriteNode(texture: atlas.textureNamed("big_tree_base.png")),
            SKSpriteNode(texture: atlas.textureNamed("big_tree_middle.png")),
            SKSpriteNode(texture: atlas.textureNamed("big_tree_top.png"))
        ]
        sSharedBigTree = Tree(sprites:sprites, usingOffset:150.0)
        sSharedBigTree.fadeAlpha = true
    }

    class func loadBackgroundTiles() {
        let tileAtlas = SKTextureAtlas(named: "Tiles")

        for y in 0..<kWorldTileDivisor {
            for x in 0..<kWorldTileDivisor {
                let tileNumber = (y * kWorldTileDivisor) + x
                let tileNode = SKSpriteNode(texture: tileAtlas.textureNamed("tile\(tileNumber).png"))

                let xPosition = CGFloat((x * kWorldTileSize) - kWorldCenter)
                let yPosition = CGFloat((kWorldSize - (y * kWorldTileSize)) - kWorldCenter)

                let position = CGPoint(x: xPosition, y: yPosition)

                tileNode.position = position
                tileNode.zPosition = -1.0
                tileNode.blendMode = .replace
                sBackgroundTiles.append(tileNode)
            }
        }
    }

}


var sBackgroundTiles = [SKSpriteNode]()
var sSharedSmallTree = Tree(sprites: [SKSpriteNode](), usingOffset: 0.0)
var sSharedBigTree = Tree(sprites: [SKSpriteNode](), usingOffset: 0.0)
var sSharedLeafEmitterA = SKEmitterNode()
var sSharedLeafEmitterB = SKEmitterNode()
var sSharedProjectileSparkEmitter = SKEmitterNode()
var sSharedSpawnEmitter = SKEmitterNode()

let kWorldTileDivisor = 32
let kWorldSize = 4096
let kWorldTileSize = kWorldSize / kWorldTileDivisor
let kWorldCenter = kWorldSize / 2
let kLevelMapSize = 256
let kLevelMapDivisor = (kWorldSize / kLevelMapSize)
