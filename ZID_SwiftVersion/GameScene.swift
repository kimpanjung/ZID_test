//
//  GameScene.swift
//  ZID_SwiftVersion
//
//  Created by Kim Pan Jung on 2015. 4. 8..
//  Copyright (c) 2015년 Kim Pan Jung. All rights reserved.
//

import SceneKit
import SpriteKit
import CoreMotion
import UIKit

struct PhysicsCategory {
    static let None: Int              = 0
    static let player: Int            = 0b1      // 1
    static let zombie: Int               = 0b10     // 2
    static let Obstacle: Int          = 0b100    // 4
}

func degreesToRadians(degrees: Float) -> Float {
    return (degrees * Float(M_PI)) / 180.0
}

class GameScene: SCNScene, SCNSceneRendererDelegate, SCNPhysicsContactDelegate {

    // GameScene : property //
    var sceneView: SCNView!
    
    var camera: SCNNode!
    var cameraHandle: SCNNode!
    var cameraOrthographicScale = 0.5
    var cameraOffsetFromPlayer = SCNVector3(x: 0.25, y: 1.25, z: 0.55)
    
    var playerNode: SCNNode!
    let playerScene = SCNScene(named: "car.dae")
    var playerChildNode: SCNNode!
    
    let zombieScene = SCNScene(named: "frog.dae")
    
    var motionManager : CMMotionManager?
    
    //add a tap gesture recogizer
    
    // GameScene : method //
    init(view: SCNView) {
        sceneView = view
        super.init()
        // (Schedule) level init
        initLevel()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func initLevel(){
        setupLightAndFloor()
        setupCamera()
        setupPlayer()
    }
    
    func setupPlayer(){
        playerNode = SCNNode()
        playerNode.name = "player"
        playerNode.position = SCNVector3Zero
        
        let playerMat = SCNMaterial()
        playerMat.diffuse.contents = UIImage(named: "model_texture.tga")
        playerMat.locksAmbientWithDiffuse = false
        
        playerChildNode = playerScene!.rootNode.childNodeWithName("player", recursively: false)!
        playerChildNode.geometry!.firstMaterial = playerMat
        playerChildNode.position = SCNVector3(x: 0.0, y: 0.0, z: 0.05)
        
        playerNode.addChildNode(playerChildNode)
        
        // player physicsbody
        let playerPhysicsBodyShape = SCNPhysicsShape(geometry: SCNBox(width: 0.08, height: 0.08, length: 0.08, chamferRadius: 0.0), options: nil)
        
        playerChildNode.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.Kinematic, shape: playerPhysicsBodyShape)
        playerChildNode.physicsBody!.categoryBitMask = PhysicsCategory.player
        playerChildNode.physicsBody!.collisionBitMask = PhysicsCategory.zombie
        
        rootNode.addChildNode(playerNode)
        
    }
    
    func setupCamera() {
//        camera = SCNNode()
//        camera.name = "Camera"
//        camera.position = cameraOffsetFromPlayer
//        camera.camera = SCNCamera()
//        camera.camera!.usesOrthographicProjection = true
//        camera.camera!.orthographicScale = cameraOrthographicScale
//        camera.camera!.zNear = 0.05
//        camera.camera!.zFar = 300.0
//        playerNode.addChildNode(camera)
//        
//        camera.constraints = [SCNLookAtConstraint(target: playerNode)]
        
         //create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 15, z: 10)
        cameraNode.eulerAngles = SCNVector3Make(degreesToRadians(90), 0, 0)
        rootNode.addChildNode(cameraNode)
        
        let cameraRollNode = SCNNode()
        cameraRollNode.addChildNode(cameraNode)
        
        let cameraPitchNode = SCNNode()
        cameraPitchNode.addChildNode(cameraRollNode)
        
        let cameraYawNode = SCNNode()
        cameraYawNode.addChildNode(cameraPitchNode)
        
        rootNode.addChildNode(cameraYawNode)
        
        motionManager = CMMotionManager()
        motionManager?.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager?.startDeviceMotionUpdatesUsingReferenceFrame(
            CMAttitudeReferenceFrameXArbitraryZVertical,
            toQueue: NSOperationQueue.mainQueue(),
            withHandler: { (motion: CMDeviceMotion!, error: NSError!) -> Void in
                
                let currentAttitude = motion.attitude
                let roll = Float(currentAttitude.roll)
                let pitch = Float(currentAttitude.pitch)
                let yaw = Float(currentAttitude.yaw)
                
                cameraRollNode.eulerAngles = SCNVector3Make(roll, 0.0, 0.0)
                cameraPitchNode.eulerAngles = SCNVector3Make(0.0, 0.0, pitch)
                cameraYawNode.eulerAngles = SCNVector3Make(0.0, yaw, 0.0)
                
        })
    }
    
    func setupLightAndFloor(){
        // create floor
        let floor = SCNFloor()
        floor.reflectivity = 0.1
        
        let floorNode = SCNNode(geometry: floor)
        floorNode.geometry?.firstMaterial?.diffuse.contents = "desertTexture.jpg"
        floorNode.geometry?.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(0.5, 0.5, 1);
        floorNode.geometry?.firstMaterial?.locksAmbientWithDiffuse = false
        //floorNode.position = SCNVector3Zero
        
        floorNode.geometry!.firstMaterial?.diffuse.wrapS = SCNWrapMode.Repeat
        floorNode.geometry!.firstMaterial?.diffuse.wrapT = SCNWrapMode.Repeat
        floorNode.geometry!.firstMaterial?.diffuse.mipFilter = SCNFilterMode.Linear
        
        let staticBody = SCNPhysicsBody(type: SCNPhysicsBodyType.Static, shape: nil)
        floorNode.physicsBody = staticBody
        
        rootNode.addChildNode(floorNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = UIColor.darkGrayColor()
        rootNode.addChildNode(ambientLightNode)
        
        let spotLightNode = SCNNode()
        spotLightNode.light = SCNLight()
        spotLightNode.light?.type = SCNLightTypeSpot
        spotLightNode.position = SCNVector3Make(0, 80, 30)
        spotLightNode.rotation = SCNVector4Make(1, 0, 0,  Float(-M_PI)/2.8)
        spotLightNode.light?.spotInnerAngle = 0
        spotLightNode.light?.shadowColor = SKColor(red: 1, green: 1, blue: 1, alpha: 1);
        spotLightNode.light?.zFar = 500;
        spotLightNode.light?.zNear = 50;
        rootNode.addChildNode(spotLightNode)
    }
    
    
    func spawnZombieAtPosition(position: SCNVector3) {
        
        // Create a material using the model_texture.tga image
        let zombieMaterial = SCNMaterial()
        zombieMaterial.diffuse.contents = UIImage(named: "zombie_D.jpg")
        zombieMaterial.locksAmbientWithDiffuse = false
        
        // Create a clone of the Car node of the carScene - you need a clone because you need to add many cars
        let zombieNode = zombieScene!.rootNode.childNodeWithName("zombie", recursively: false)!.clone() as SCNNode
        
        zombieNode.name = "zombie"
        
        zombieNode.position = position
        
        // Set the material
        zombieNode.geometry!.firstMaterial = zombieMaterial
        
        // Create a physicsbody for collision detection
        let zombiePhysicsbodyShape = SCNPhysicsShape(geometry: SCNBox(width: 0.30, height: 0.20, length: 0.16, chamferRadius: 0.0), options: nil)
        
        zombieNode.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.Kinematic, shape: zombiePhysicsbodyShape)
        zombieNode.physicsBody!.categoryBitMask = PhysicsCategory.zombie
        zombieNode.physicsBody!.collisionBitMask = PhysicsCategory.player
        
        rootNode.addChildNode(zombieNode)
        
        // Move the Zombie
//        let moveDirection: Float = position.x > 0.0 ? -1.0 : 1.0
//        let moveDistance = levelData.gameLevelWidth()
//        let moveAction = SCNAction.moveBy(SCNVector3(x: moveDistance * moveDirection, y: 0.0, z: 0.0), duration: 10.0)
//        let removeAction = SCNAction.runBlock { node -> Void in
//            node.removeFromParentNode()
//        }
//        carNode.runAction(SCNAction.sequence([moveAction, removeAction]))
//        
//        // Rotate the car to move it in the right direction
//        if moveDirection > 0.0 {
//            carNode.rotation = SCNVector4(x: 0.0, y: 1.0, z: 0.0, w: 3.1415)
//        }
    }
    

    

}
