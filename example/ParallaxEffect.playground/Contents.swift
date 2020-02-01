//: A SpriteKit based Playground

import PlaygroundSupport
import SpriteKit

class GameScene: SKScene {
    var parallax = SKSpriteNode()
    
    override func didMove(to view: SKView) {
        let movF = SKAction.move(by: CGVector(dx: -frame.width,dy:0), duration: TimeInterval(frame.width/200))
        let resetF = SKAction.move(by: CGVector(dx:frame.width,dy:0), duration: 0)
        let repF = SKAction.repeatForever(SKAction.sequence([movF,resetF]))
        var i:CGFloat = 0
        while i<2 {
            parallax = SKSpriteNode(imageNamed: "")
            parallax.position = CGPoint(x:frame.width * i, y: frame.midY)
            parallax.size.width = frame.width
            parallax.size.height = frame.height
            parallax.zPosition = -1
            parallax.run(repF)
            addChild(parallax)
            i+=1
        }
    }
    
}

// Load the SKScene from 'GameScene.sks'
let sceneView = SKView(frame: CGRect(x:0 , y:0, width: 640, height: 480))
if let scene = GameScene(fileNamed: "GameScene") {
    // Set the scale mode to scale to fit the window
    scene.scaleMode = .aspectFill
    
    // Present the scene
    sceneView.presentScene(scene)
}

PlaygroundSupport.PlaygroundPage.current.liveView = sceneView
