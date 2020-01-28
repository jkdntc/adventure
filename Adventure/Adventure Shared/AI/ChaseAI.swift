/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines the class for AI that chases a character
      
*/

import SpriteKit

let kEnemyAlertRadius = kCharacterCollisionRadius * 500

class ChaseAI: ArtificialIntelligence {
	var chaseRadius: CGFloat = kCharacterCollisionRadius * 2.0
	var maxAlertRadius: CGFloat = kEnemyAlertRadius * 2.0

	// Initialization
    override init(character: Character, target: Character?) {
        super.init(character: character, target: target)
    }

    override func updateWithTimeSinceLastUpdate(interval: TimeInterval) {
    	if character.dying {
    		target = nil
    		return
    	}

		let position = character.position

        var closestHeroDistance = CGFloat.greatestFiniteMagnitude

		for hero in character.characterScene.heroes {
            let distance = position.distanceTo(p: hero.position)

			if distance < kEnemyAlertRadius && distance < closestHeroDistance && !hero.dying {
				closestHeroDistance = distance
				target = hero
			}
		}

        if let heroPosition = target?.position {
            if closestHeroDistance > maxAlertRadius {
                target = nil
            } else if closestHeroDistance > chaseRadius {
                character.moveTowards(targetPosition: heroPosition, withTimeInterval: interval)
            } else if closestHeroDistance < chaseRadius {
                character.faceTo(position: heroPosition)
                character.performAttackAction()
            }
        }
    }
}
