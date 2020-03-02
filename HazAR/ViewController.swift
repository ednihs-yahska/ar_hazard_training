//
//  ViewController.swift
//  HazAR
//
//  Created by Akshay Shinde on 2/23/20.
//  Copyright © 2020 Akshay_Shinde. All rights reserved.
//

import UIKit
import RealityKit
import ARKit

class ViewController: UIViewController, ARSessionDelegate {
    
   
    @IBOutlet weak var arView: ARView!
    
    @IBOutlet weak var instructionsLabel: UILabel!
    
    let configuration = ARWorldTrackingConfiguration()
    
    let camera = AnchorEntity(.camera)
    var wall = AnchorEntity(plane: .vertical, classification: .wall, minimumBounds: [0,0])
    
    var trainingStatus = CandleTrainingStatus.prestart
    var candleNode = Entity()
    var trainingEntity = Entity()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard ARWorldTrackingConfiguration.supportsUserFaceTracking else {
            fatalError("This sample code requires iOS 13, and an iOS device with a front TrueDepth camera.")
        }
        
        arView.session.delegate = self
        
        // Load the "Box" scene from the "Experience" Reality File
        //let boxAnchor = try! Experience.loadBox()
        
        arView.automaticallyConfigureSession = false
        configuration.userFaceTrackingEnabled = true
        configuration.planeDetection = [.horizontal, .vertical]
        
        arView.renderOptions.insert(.disableMotionBlur)
        //arView.debugOptions.insert(.showAnchorGeometry)
        //arView.debugOptions.insert(.showAnchorOrigins)
//        let directionalLight = DirectionalLight()
//        directionalLight.look(at: [0, -1, 0], from: [0, 1, 0], relativeTo: nil)
//        let airAnchor = AnchorEntity(world: camera.transformMatrix(relativeTo: nil))
//        airAnchor.addChild(directionalLight)
//        arView.scene.addAnchor(airAnchor)
//
        let tap_gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        //tap_gesture.numberOfTouchesRequired = 2
        arView.addGestureRecognizer(tap_gesture)

         // Add the box anchor to the scene
         //arView.scene.anchors.append(boxAnchor)
        print("Attacching floor....")
        arView.scene.addAnchor(camera)
        //arView.scene.anchors.append(floor)
        arView.scene.anchors.append(wall)
        changeAppStatusTo(.prestart)
        
        
        
       
    }
    
    /// - Tag: RunConfiguration
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        arView.session.run(configuration)
        print("Ran configuration")
        
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        if trainingStatus == .setTrainingArea{
            print("Anchor added <<<<<")
        }
        
//        anchors.forEach {
//            print("\nAnchor added \($0.description)\n")
//        }
//        anchors.forEach {
//            let tempAnchor = AnchorEntity(anchor: $0)
//            arView.scene.anchors.append(tempAnchor)
//
//            let plane = MeshResource.generatePlane(width: 1, depth: 1) // size in metres
//            let material = SimpleMaterial(color: .green, isMetallic: true)
//            let planeEntity = ModelEntity(mesh: plane, materials: [material])
//            planeEntity.setTransformMatrix($0.transform, relativeTo: nil)
//            tempAnchor.addChild(planeEntity)
//
//        }
    }
    
    /// - Tag: UpdateFacialExpression
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        anchors.compactMap { $0 as? ARFaceAnchor }.forEach {
            //print("Puff \(String(describing: $0.blendShapes[.cheekPuff]))")
            //print("Funnel \(String(describing: $0.blendShapes[.mouthFunnel]))")
            
            let candlePosition = self.candleNode.position(relativeTo: nil)
            let cameraPosition = self.camera.position(relativeTo: nil)
            let distanceBetweenCameraAndCandle = candlePosition - cameraPosition;
            let scalarDistanceBetweenCameraAndCandle = length(distanceBetweenCameraAndCandle)
            
            let isCheekPuff = ($0.blendShapes[.cheekPuff] ?? 0) as Double > 0.25 && ($0.blendShapes[.mouthFunnel] ?? 0) as Double > 0.25 ? true : false
            if(isCheekPuff && trainingStatus == .candlePlaced && scalarDistanceBetweenCameraAndCandle < 0.25) {
                let candlePosition = self.candleNode.position(relativeTo: nil)
                let cameraPosition = self.camera.position(relativeTo: nil)
                let distanceBetweenCameraAndCandle = candlePosition - cameraPosition;
                print(distanceBetweenCameraAndCandle)
                
                if trainingStatus == .start {
                    self.trainingStatus = .candleBlownBefore1Min
                    if let candle = trainingEntity.findEntity(named: "candle"){
                        candle.scale = [0,0,0]
                    }
                    //floor.removeChild(candle)
                }
            }
        }
        
        //print(camera.transform)
    }
    
    // MARK: - User interaction and messages
    /// - Tag: HandleTap
    @objc
    func handleTap(recognizer: UITapGestureRecognizer) {
        print("Tap \(trainingStatus)")
        switch trainingStatus {
            case .prestart:
                print("Tap prestarting")
                changeAppStatusTo(.setTrainingArea)
            case .start:
                let airAnchor = AnchorEntity(world: camera.transformMatrix(relativeTo: nil))
                airAnchor.position.z -= 0.5
                //airAnchor.position.y -= 0.5
                arView.scene.addAnchor(airAnchor)
                
                print("Loading Fire Extinguisher")
                if let fire_ex_body = try? Entity.load(named: "fireext_body") {
                    print("FireExt loaded")
                    fire_ex_body.name = "fire_ex_body"
                    //camera.addChild(fire_ex_body)
                    airAnchor.addChild(fire_ex_body)
                    changeAppStatusTo(.fireExtinguisherPlaced)
                }else {
                    fatalError("Error: Unable to load model.")
                }
            default:
                print()
        }
    }
    
    func changeAppStatusTo(_ to: CandleTrainingStatus) {
        switch to {
        case .prestart:
            trainingStatus = .prestart
            instructionsLabel.text = "Find a flat table as space for training. Tap on screen to continue"
        case .setTrainingArea:
            trainingStatus = .setTrainingArea
            instructionsLabel.text = "Move your phone untill you see a blue area"
            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            let floor = AnchorEntity(plane: .horizontal, classification: .table, minimumBounds: [0, 0])
            let plane = MeshResource.generatePlane(width: 0.5, depth: 0.5) // size in metres
            let material = SimpleMaterial(color: UIColor(red: 0, green: 0, blue: 1, alpha: 0.3), isMetallic: false)
            trainingEntity = ModelEntity(mesh: plane, materials: [material])
            arView.scene.addAnchor(floor)
            floor.addChild(trainingEntity)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                
                self.changeAppStatusTo(.start)
            })
        case .start:
            trainingStatus = .start
            instructionsLabel.text = "Touch the back of your phone to fire extinguisher and tap on the screen"
        case .fireExtinguisherPlaced:
            trainingStatus = .fireExtinguisherPlaced
            instructionsLabel.text = "Move your phone around to randomly place a candle in your room"
            addCandle()
        case .candlePlaced:
            trainingStatus = .candlePlaced
            instructionsLabel.text = "An open flame is placed in the scene. It can be dangerous. Blow it out"
        case .candleBlownBefore1Min:
            trainingStatus = .candleBlownBefore1Min
            instructionsLabel.text = "You have averted potential hazardous scenario"
        case .fireStarted:
            trainingStatus = .fireStarted
            instructionsLabel.text = "There is fire in your room. Use your fire entinguisher"
        case .placeDamaged:
            trainingStatus = .placeDamaged
            instructionsLabel.text = "You failed to protect your belongings"
        case .fireExtinguishedBefore2Min:
            trainingStatus = .fireExtinguishedBefore2Min
            instructionsLabel.text = "Congratulations, you saved your room from fire"
        default:
            instructionsLabel.text = ""
        }
    }
    func addCandle() {
        print("Loading Candle....")
        if let candle = try? Entity.load(named: "short_candle") {
           self.candleNode = candle
           print("Candle added at \(candle.position)")
           candle.name = "candle"
           candle.playAnimation(named: "transform")
           trainingEntity.addChild(candle)
           changeAppStatusTo(.candlePlaced)
           DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
               print("Burning Started")
               
               let box = MeshResource.generateBox(size: 0.05) // size in metres
               let material = SimpleMaterial(color: .green, isMetallic: true)
               let boxEntity = ModelEntity(mesh: box, materials: [material])
               boxEntity.position.x += 0.1
               
               let boxEntity2 = boxEntity.clone(recursive: true)
               boxEntity2.position.x -= 0.1
               
               let boxEntity3 = boxEntity.clone(recursive: true)
               boxEntity3.position.z += 0.1
               
               let boxEntity4 = boxEntity.clone(recursive: true)
               boxEntity4.position.z -= 0.1
               
               
               if self.trainingStatus != .candleBlownBefore1Min {
                self.changeAppStatusTo(.fireStarted)
                candle.addChild(boxEntity)
                candle.addChild(boxEntity2)
                candle.addChild(boxEntity3)
                candle.addChild(boxEntity4)
               }
               candle.addChild(boxEntity)
               DispatchQueue.main.asyncAfter(deadline: .now() + 60){
                   if self.trainingStatus != .fireExtinguishedBefore2Min {
                       print("Place Damaged")
                   }
               }
           }
           
           //wall.addChild(candle.clone(recursive: true))
        } else {
           fatalError("Error: Unable to load model.")
        }
    }
}
