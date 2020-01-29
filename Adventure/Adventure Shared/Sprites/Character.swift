/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines the class for a character in Adventure
      
*/

import SpriteKit

enum AnimationState: UInt32 {
    case Idle = 0, Walk, Attack, GetHit, Death
}

enum MoveDirection {
    case Forward, Left, Right, Back
}

enum ColliderType: UInt32 {
    case Hero = 1
    case GoblinOrBoss = 2
    case Projectile = 4
    case Wall = 8
    case Cave = 16
}

class Character: ParallaxSprite {
    var dying = false
    var attacking = false
    var health = 100.0
    var animated = true
    var animationSpeed: CGFloat = 1.0/28.0
    var movementSpeed: CGFloat = 200.0
    var rotationSpeed: CGFloat = 0.06
    var requestedAnimation = AnimationState.Idle
    
    var characterScene: LayeredCharacterScene {
        return self.scene as! LayeredCharacterScene
    }
    
    var shadowBlob = SKSpriteNode()

    func idleAnimationFrames() -> [SKTexture] {
        return []
    }

    func walkAnimationFrames() -> [SKTexture] {
        return []
    }

    func attackAnimationFrames() -> [SKTexture] {
        return []
    }

    func getHitAnimationFrames() -> [SKTexture] {
        return []
    }

    func deathAnimationFrames() -> [SKTexture] {
        return []
    }

    func damageEmitter() -> SKEmitterNode {
        return SKEmitterNode()
    }

    func damageAction() -> SKAction {
        return SKAction()
    }

    init(sprites: [SKSpriteNode], atPosition position: CGPoint, usingOffset offset: CGFloat) {
        super.init(sprites: sprites, usingOffset: offset)

        sharedInitAtPosition(position: position)
    }

    init(texture: SKTexture?, atPosition position: CGPoint) {
        let size = texture != nil ? texture!.size() : CGSize(width: 0, height: 0)
        super.init(texture: texture, color: SKColor.white, size: size)

        sharedInitAtPosition(position: position)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func sharedInitAtPosition(position: CGPoint) {
        let atlas = SKTextureAtlas(named: "Environment")

        shadowBlob = SKSpriteNode(texture: atlas.textureNamed("blobShadow.png"))
        shadowBlob.zPosition = -1.0

        self.position = position

        configurePhysicsBody()
    }

    func reset() {
        health = 100.0
        dying = false
        attacking = false
        animated = true
        requestedAnimation = .Idle
        shadowBlob.alpha = 1.0
    }

// OVERRIDDEN METHODS
    func performAttackAction() {
        if attacking {
            return
        }

        attacking = true
        requestedAnimation = .Attack
    }

    func performDeath() {
        health = 0.0
        dying = true
        requestedAnimation = .Death
    }

    func configurePhysicsBody() {
    }

    func animationDidComplete(animation: AnimationState) {
    }

    func collidedWith(other: SKPhysicsBody) {
    }

// DAMAGE
    func applyDamage( damage: Double, projectile: SKNode? = nil) -> Bool {
        var damage = damage
        if let proj = projectile {
            damage *= Double(proj.alpha)
        }

        health -= damage

        if health > 0.0 {
            let emitter = damageEmitter().copy() as! SKEmitterNode
            characterScene.addNode(node: emitter, atWorldLayer: .AboveCharacter)

            emitter.position = position
            runOneShotEmitter(emitter: emitter, withDuration: 0.15)

            run(damageAction())
            return false
        }

        performDeath()
        return true
    }

// SHADOW BLOB
    override func setScale(_ scale: CGFloat) {
        super.setScale(scale)
        shadowBlob.setScale(scale)
    }

// LOOP UPDATE
    func updateWithTimeSinceLastUpdate(interval: TimeInterval) {
        shadowBlob.position = position

        if !animated {
            return
        }
        resolveRequestedAnimation()
    }

// ANIMATION
    func resolveRequestedAnimation() {
        let (frames, key) = animationFramesAndKeyForState(state: requestedAnimation)

        fireAnimationForState(animationState: requestedAnimation, usingTextures: frames, withKey: key)

        requestedAnimation = dying ? .Death : .Idle
    }

    func animationFramesAndKeyForState(state: AnimationState) -> ([SKTexture], String) {
        //控制当前人物动作动画是否被打断
        var animationState = state
        if (dying) {
            animationState = AnimationState.Death;
        } else if attacking || action(forKey: "anim_attack") != nil {
            if state == AnimationState.GetHit {
                animationState = AnimationState.GetHit;
            } else {
                animationState = AnimationState.Attack;
            }
        } else if action(forKey: "anim_gethit") != nil {
            animationState = AnimationState.GetHit;
        } else {
            animationState = state;
        }
        
        switch animationState {
            case .Walk:
               return (walkAnimationFrames(), "anim_walk")

            case .Attack:
                return (attackAnimationFrames(), "anim_attack")

            case .GetHit:
                return (getHitAnimationFrames(), "anim_gethit")

            case .Death:
                return (deathAnimationFrames(), "anim_death")

            case .Idle:
                return (idleAnimationFrames(), "anim_idle")
        }
    }

    func fireAnimationForState(animationState: AnimationState, usingTextures frames: [SKTexture], withKey key: String) {
        let animAction = action(forKey: key)

        if animAction != nil || frames.count < 1 {
            return
        }

        let animationAction = SKAction.animate(with: frames, timePerFrame: TimeInterval(animationSpeed), resize: true, restore: false)
        let blockAction = SKAction.run {
            self.animationHasCompleted(animationState: animationState)
        }

        run(SKAction.sequence([animationAction, blockAction]), withKey: key)
    }

    func animationHasCompleted(animationState: AnimationState) {
        //死亡动画播放完成后再停止一切动画,否则可能无法复活,因为判断是否死亡采用的参数是AnimationState
        if animationState == AnimationState.Death {
            animated = false
            shadowBlob.run(SKAction.fadeOut(withDuration: 1.5))
        }

        animationDidComplete(animation: animationState)

        if attacking {
            attacking = false
        }
    }

    func fadeIn(duration: TimeInterval) {
        let fadeAction = SKAction.fadeIn(withDuration: duration)

        alpha = 0.0
        run(fadeAction)

        shadowBlob.alpha = 0.0
        shadowBlob.run(fadeAction)
    }

// WORKING WITH SCENES
    func addToScene(scene: LayeredCharacterScene) {
        scene.addNode(node: self, atWorldLayer: .Character)
        scene.addNode(node: shadowBlob, atWorldLayer: .BelowCharacter)
    }

    override func removeFromParent() {
        shadowBlob.removeFromParent()
        super.removeFromParent()
    }

// Movement
    func move(direction: MoveDirection, withTimeInterval timeInterval: TimeInterval) {
        var action: SKAction!

        switch direction {
            case .Forward:
                let x = -sin(zRotation) * movementSpeed * CGFloat(timeInterval)
                let y =  cos(zRotation) * movementSpeed * CGFloat(timeInterval)
                action = SKAction.moveBy(x: x, y: y, duration: timeInterval)

            case .Back:
                let x =  sin(zRotation) * movementSpeed * CGFloat(timeInterval)
                let y = -cos(zRotation) * movementSpeed * CGFloat(timeInterval)
                action = SKAction.moveBy(x: x, y: y, duration: timeInterval)

            case .Left:
                action = SKAction.rotate(byAngle: rotationSpeed, duration:timeInterval)

            case .Right:
                action = SKAction.rotate(byAngle: -rotationSpeed, duration:timeInterval)
        }

        if action != nil {
            requestedAnimation = .Walk
            run(action)
        }
    }

    func faceTo(position: CGPoint) -> CGFloat {
        let angle = adjustAssetOrientation(r: position.radiansToPoint(p: self.position))
        let action = SKAction.rotate(toAngle: angle, duration: 0)
        run(action)
        return angle
    }

    func moveTowards(targetPosition: CGPoint, withTimeInterval timeInterval: TimeInterval) {
        //攻击时不可以移动
        if attacking || action(forKey: "anim_attack") != nil  {
            return
        }
        // Grab an immutable position in case Sprite Kit changes it underneath us.
        let current = position
        let deltaX = targetPosition.x - current.x
        let deltaY = targetPosition.y - current.y
        var deltaT:CGFloat
        //移动速度超过kWorldTileSize了容易越过碰撞体,导致穿墙,高延时导致移动速度过快,所以高延时要降低移动速度,算法待研究
        if timeInterval > 0.033333333 {
            deltaT = movementSpeed/30.0
            //println("deltaT=\(deltaT),timeInterval=\(timeInterval),fps=\(fps),fpsP=\(fpsP)")
        } else {
            deltaT = movementSpeed * CGFloat(timeInterval)
        }

        let angle = adjustAssetOrientation(r: targetPosition.radiansToPoint(p: current))
        let action = SKAction.rotate(toAngle: angle, duration: 0)
        run(action)

        let distRemaining = hypot(deltaX, deltaY)
        if distRemaining < deltaT {
            position = targetPosition
        } else {
            let x = current.x - (deltaT * sin(angle))
            let y = current.y + (deltaT * cos(angle))
            position = CGPoint(x: x, y: y)
        }
        requestedAnimation = .Walk
    }
}
