/*
  Copyright (C) 2015 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  Defines the class for AI that chases a character.
*/

import SpriteKit

class ChaseArtificialIntelligence: ArtificialIntelligence {
    // MARK: Properties

    var enemyAlertRadius: CGFloat
    
    // Bosses and goblins have different attack radii. The default value matches goblins, but should 
    // change if they correspond to a boss.
    var attackRadius: CGFloat
    
    // MARK: Initialization
    
    override init(character: Character) {
        // 500x the collision radius ensures enemies are alerted to the hero no matter where they are.
        enemyAlertRadius = character.collisionRadius * 500
        
        // Doubling the collision radius approximates an enemies arm reach relative to torso size.
        attackRadius =  character.collisionRadius * 2.0
        
        super.init(character: character)
    }
    
    // MARK: Scene Processing Support

    override func updateWithTimeSinceLastUpdate(interval timeInterval: TimeInterval) {
        // The goal of the implementation of this method is to find the closest hero within the
        // enemy alert radius. After finding the closest hero, chase it!
        
        // No need to move / attack the character if the character is dying.
    	if character.isDying {
    		target = nil

            return
    	}

        if let (closestHeroDistance, closestHero) = closestHeroWithinEnemyAlertRadius() {
            target = closestHero

            chaseTargetWithinDistance(closestHeroDistance: closestHeroDistance, timeInterval: timeInterval)
        }
        else {
            target = nil
        }
    }
    
    // MARK: Intelligence Implementation
    
    func closestHeroWithinEnemyAlertRadius() -> (closestHeroDistance: CGFloat, closestHero: HeroCharacter)? {
        let position = character.scene!.convert(character.position, from: character.parent!)

        // Start off with the maximum distance possible away from any of the heroes.
        var closestHeroDistance = CGFloat.greatestFiniteMagnitude
        var closestHero: HeroCharacter?
        
        for hero in character.characterScene.heroes {
            let heroPosition = hero.scene!.convert(hero.position, from: hero.parent!)
            let distance = position.distanceToPoint(point: heroPosition)
            
            if distance < enemyAlertRadius && distance < closestHeroDistance && !hero.isDying {
                let canSee = character.characterScene.canSee(point: heroPosition, from: position)
                
                if !canSee {
                    continue
                }
                
                closestHeroDistance = distance
                closestHero = hero
            }
        }

        if closestHero != nil && closestHeroDistance <= enemyAlertRadius {
            return (closestHeroDistance: closestHeroDistance, closestHero: closestHero!)
        }

        return nil
    }
    
    func chaseTargetWithinDistance(closestHeroDistance: CGFloat, timeInterval: TimeInterval) {
        if let heroPosition = target?.position {
            if closestHeroDistance > attackRadius {
                character.moveTowardsPosition(targetPosition: heroPosition, withTimeInterval: timeInterval)
            }
            else {
                character.faceToPosition(position: heroPosition)
                character.performAttackAction()
            }
        }
    }
}
