//
//  GameViewController.swift
//  GeometryFighter
//
//  Created by Stefan Boblic on 09.02.2023.
//

import UIKit
import SceneKit

class GameViewController: UIViewController {
    
    private var scnView: SCNView!
    private var scnScene: SCNScene!
    private var cameraNode: SCNNode!
    private var geometry: SCNGeometry!
    private var spawnTime: TimeInterval = 0
    private var game = GameHelper.sharedInstance
    private var splashNodes: [String: SCNNode] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupScene()
        setupCamera()
        setupHUD()
        setupSplash()
        setupSounds()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func setupView() {
        scnView = self.view as? SCNView
        scnView.showsStatistics = true
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = true
        
        scnView.delegate = self
        scnView.isPlaying = true
    }
    
    private func setupScene() {
        scnScene = SCNScene()
        scnView.scene = scnScene
        scnScene.background.contents = "GeometryFighter.scnassets/Textures/Background_Diffuse.jpg"
    }
    
    private func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 5, z: 10)
        scnScene.rootNode.addChildNode(cameraNode)
    }
    
    private func spawnShape() {
        switch ShapeType.random() {
        case .box:
            geometry = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.0)
        case .sphere:
            geometry = SCNSphere(radius: 0.5)
        case .pyramid:
            geometry = SCNPyramid(width: 1.0, height: 1.0, length: 1.0)
        case .torus:
            geometry = SCNTorus(ringRadius: 0.5, pipeRadius: 0.25)
        case .capsule:
            geometry = SCNCapsule(capRadius: 0.3, height: 2.5)
        case .cylinder:
            geometry = SCNCylinder(radius: 0.3, height: 2.5)
        case .cone:
            geometry = SCNCone(topRadius: 0, bottomRadius: 0.5, height: 1.0)
        case .tube:
            geometry = SCNTube(innerRadius: 0.25, outerRadius: 0.5, height: 1.0)
        }
        
        let color = UIColor.random()
        geometry.materials.first?.diffuse.contents = color
        let geometryNode = SCNNode(geometry: geometry)
        geometryNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        let trailEmitter = createTrail(color: color, geometry: geometry)
        geometryNode.addParticleSystem(trailEmitter)
        
        let randomX = Float.random(min: -2, max: 2)
        let randomY = Float.random(min: 10, max: 18)
        
        let force = SCNVector3(x: randomX, y: randomY, z: 0)
        let position = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
        
        geometryNode.physicsBody?.applyForce(force, at: position, asImpulse: true)
        
        scnScene.rootNode.addChildNode(geometryNode)
        
        if color == UIColor.black {
            geometryNode.name = "BAD"
            game.playSound(scnScene.rootNode, name: "SpawnBad")
        } else {
            geometryNode.name = "GOOD"
            game.playSound(scnScene.rootNode, name: "SpawnGood")
        }
    }
    
    private func cleanScene() {
        scnScene.rootNode.childNodes
            .filter { $0.presentation.position.y < -2 }
            .forEach { $0.removeFromParentNode() }
    }
    
    private func createTrail(color: UIColor, geometry: SCNGeometry) -> SCNParticleSystem {
        let trail = SCNParticleSystem(named: "Trail.scnp", inDirectory: nil)!
        trail.particleColor = color
        trail.emitterShape = geometry
        return trail
    }
    
    private func setupHUD() {
        game.hudNode.position = SCNVector3(x: 0, y: 10, z: 0)
        scnScene.rootNode.addChildNode(game.hudNode)
    }
    
    private func createExplosion(geometry: SCNGeometry, position: SCNVector3, rotation: SCNVector4) {
        let explosion = SCNParticleSystem(named: "Explode.scnp", inDirectory: nil)!
        
        explosion.emitterShape = geometry
        explosion.birthLocation = .surface
        
        let rotationMatrix = SCNMatrix4MakeRotation(rotation.w, rotation.x, rotation.y, rotation.z)
        let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
        let transformMatrix = SCNMatrix4Mult(rotationMatrix, translationMatrix)
        
        scnScene.addParticleSystem(explosion, transform: transformMatrix)
    }
    
    private func createSplash(name: String, imageFileName: String) -> SCNNode {
        let plane = SCNPlane(width: 5, height: 5)
        let splashNode = SCNNode(geometry: plane)
        splashNode.position = SCNVector3(x: 0, y: 5, z: 0)
        splashNode.name = name
        splashNode.geometry?.materials.first?.diffuse.contents = imageFileName
        scnScene.rootNode.addChildNode(splashNode)
        return splashNode
    }
    
    private func showSplash(splashName: String) {
        for (name,node) in splashNodes {
            if name == splashName {
                node.isHidden = false
            } else {
                node.isHidden = true
            }
        }
    }
    
    private func setupSplash() {
        splashNodes["TapToPlay"] = createSplash(name: "TAPTOPLAY",
                                                imageFileName: "GeometryFighter.scnassets/Textures/TapToPlay_Diffuse.png")
        splashNodes["GameOver"] = createSplash(name: "GAMEOVER",
                                               imageFileName: "GeometryFighter.scnassets/Textures/GameOver_Diffuse.png")
        showSplash(splashName: "TapToPlay")
    }
    
    private func setupSounds() {
        game.loadSound("ExplodeGood",
                       fileNamed: "GeometryFighter.scnassets/Sounds/ExplodeGood.wav")
        game.loadSound("SpawnGood",
                       fileNamed: "GeometryFighter.scnassets/Sounds/SpawnGood.wav")
        game.loadSound("ExplodeBad",
                       fileNamed: "GeometryFighter.scnassets/Sounds/ExplodeBad.wav")
        game.loadSound("SpawnBad",
                       fileNamed: "GeometryFighter.scnassets/Sounds/SpawnBad.wav")
        game.loadSound("GameOver",
                       fileNamed: "GeometryFighter.scnassets/Sounds/GameOver.wav")
    }
    
    private func handleGoodCollision() {
        game.score += 1
        game.playSound(scnScene.rootNode, name: "ExplodeGood")
    }
    
    private func handleBadCollision() {
        game.lives -= 1
        game.playSound(scnScene.rootNode, name: "ExplodeBad")
        game.shakeNode(cameraNode)
        
        if game.lives <= 0 {
            game.saveState()
            showSplash(splashName: "GameOver")
            game.playSound(scnScene.rootNode, name: "GameOver")
            game.state = .GameOver
            scnScene.rootNode.runAction(SCNAction.waitForDurationThenRunBlock(5) { (node:SCNNode!) -> Void in
                self.showSplash(splashName: "TapToPlay")
                self.game.state = .TapToPlay
            })
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if game.state == .GameOver {
            return
        }
        
        if game.state == .TapToPlay {
            game.reset()
            game.state = .Playing
            showSplash(splashName: "")
            return
        }
        
        let touch = touches.first!
        let location = touch.location(in: scnView)
        let hitResults = scnView.hitTest(location)
        
        guard let result = hitResults.first else { return }
        
        if result.node.name == "HUD" ||
            result.node.name == "GAMEOVER" ||
            result.node.name == "TAPTOPLAY" {
            return
        } else if result.node.name == "GOOD" {
            handleGoodCollision()
        } else if result.node.name == "BAD" {
            handleBadCollision()
        }
        
        createExplosion(geometry: result.node.geometry!,
                        position: result.node.presentation.position,
                        rotation: result.node.presentation.rotation)
        
        result.node.removeFromParentNode()
    }
}

extension GameViewController: SCNSceneRendererDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if game.state == .Playing {
            if time > spawnTime {
                spawnShape()
                spawnTime = time + TimeInterval(Float.random(min: 0.2, max: 1.5))
            }
            cleanScene()
        }
        game.updateHUD()
    }
}
