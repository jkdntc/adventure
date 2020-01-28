/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines basic graphics utilities used throughout Adventure
      
*/

import SpriteKit

func createCGImageFromFile(path: String) -> CGImage! {
#if os(iOS)
    if let image = UIImage(contentsOfFile: path) {
        return image.CGImage
    } else {
        return nil
    }
#else
    let nsimage = NSImage(contentsOfFile: path)
    //let destRect = NSZeroRect
    
    return nsimage!.cgImage(forProposedRect: nil, context: nil, hints: nil)  //.takeUnretainedValue()
#endif
}

func getCGImageNamed(name: String) -> CGImage! {
#if os(iOS)
    let actualName = name.lastPathComponent
    if let image = UIImage(named: actualName) {
        return image.CGImage
    } else {
        return nil
    }
#else
    var path: String
    
    if name.hasPrefix("/") {
        path = name
    } else {
        let directory = NSString(string: name).deletingLastPathComponent
        var newName = NSString(string: name).lastPathComponent
        let fileExtension = NSString(string: newName).pathExtension
        newName = NSString(string: newName).deletingPathExtension
        path = Bundle.main.path(forResource: newName, ofType: fileExtension, inDirectory: directory)!
    }
    return createCGImageFromFile(path: path)
#endif
}

extension SKEmitterNode {
    class func emitterNodeWithName(name: String) -> SKEmitterNode {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Bundle.main.path(forResource: name, ofType: "sks")!) as! SKEmitterNode
    }
}

func unitRandom() -> CGFloat {
    let quotient = Double(arc4random()) / Double(UInt32.max)

    return CGFloat(quotient)
}

func createARGBBitmapContext(inImage: CGImage) -> CGContext {
    var bitmapByteCount = 0
    var bitmapBytesPerRow = 0

    let pixelsWide = inImage.width
    let pixelsHigh = inImage.height

    bitmapBytesPerRow = Int(pixelsWide) * 4
    bitmapByteCount = bitmapBytesPerRow * Int(pixelsHigh)

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapData = malloc(bitmapByteCount)
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)

    let context = CGContext(data: bitmapData, width: pixelsWide, height: pixelsHigh, bitsPerComponent: Int(CUnsignedLong(8)), bytesPerRow: bitmapBytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!

    return context
}

func createDataMap(mapName: String) -> UnsafeMutableRawPointer  {
    let inImage = getCGImageNamed(name: mapName)
    let cgContext = createARGBBitmapContext(inImage: inImage!)

    let width = inImage!.width
    let height = inImage!.height

    var rect = CGRect.zero
    rect.size.width = CGFloat(width)
    rect.size.height = CGFloat(height)

    cgContext.draw(inImage!, in: rect, byTiling: false)

    return cgContext.data!
}

// The assets are all facing Y down, so offset by half pi to get into X right facing
func adjustAssetOrientation(r: CGFloat) -> CGFloat {
    return r + (CGFloat(M_PI) * 0.5)
}

extension CGPoint : Equatable {
    func distanceTo(p : CGPoint) -> CGFloat {
        return hypot(self.x - p.x, self.y - p.y)
    }

    func radiansToPoint(p: CGPoint) -> CGFloat {
        let deltaX = p.x - self.x
        let deltaY = p.y - self.y

        return atan2(deltaY, deltaX)
    }

    func pointByAdding(point: CGPoint) -> CGPoint {
        return CGPoint(x: self.x + point.x, y: self.y + point.y)
    }
}

func runOneShotEmitter(emitter: SKEmitterNode, withDuration duration: CGFloat) {
    let waitAction = SKAction.wait(forDuration: TimeInterval(duration))
    let birthRateSet = SKAction.run { emitter.particleBirthRate = 0.0 }
    let waitAction2 = SKAction.wait(forDuration: TimeInterval(emitter.particleLifetime + emitter.particleLifetimeRange))
    let removeAction = SKAction.removeFromParent()

    let sequence = [ waitAction, birthRateSet, waitAction2, removeAction]
    emitter.run(SKAction.sequence(sequence))
}
