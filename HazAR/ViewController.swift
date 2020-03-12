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
    
    @IBOutlet weak var crosshair: UIImageView!
    
    @IBOutlet weak var distanceLabel: UILabel!
    
    @IBOutlet weak var timerLabel: UILabel!
    
    @IBAction func resetTraining(_ sender: Any) {
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        arView.scene.removeAnchor(self.floor)
        arView.scene.removeAnchor(self.airAnchor)
        arView.scene.removeAnchor(self.camera)
        stopTimer()
        distanceLabel.isHidden = true
        timeTillFire = 30
        timerLabel.text = ""
        timerLabel.isHidden = false
        crosshair.image = nil
        arView.scene.addAnchor(camera)
        if let fire_ex = camera.findEntity(named: "fire_ex_body"){
            camera.removeChild(fire_ex)
        }
        
        //arView.scene.anchors.append(wall)
        changeAppStatusTo(.prestart)
    }
    
    var timer = Timer()
    
    let configuration = ARWorldTrackingConfiguration()
    var floor = AnchorEntity()
    var isPinching = false
    let camera = AnchorEntity(.camera)
    var wall = AnchorEntity(plane: .vertical, classification: .wall, minimumBounds: [0,0])
    
    var trainingStatus = CandleTrainingStatus.prestart
    var candleNode = Entity()
    var airAnchor = AnchorEntity()
    var fireExtinguisher = Entity()
    var trainingEntity = Entity()
    var timeTillFire = 30
    
    @objc func updateTimer() {
        if timeTillFire <= 1 {
            timer.invalidate()
        }
        timeTillFire -= 1     //This will decrement(count down)the seconds.
        timerLabel.text = "00:\(timeTillFire)" //This will update the label.
    }
    
    func stopTimer(){
        timerLabel.isHidden = true
        timer.invalidate()
    }
    
    func runTimer() {
        timeTillFire = 30
        timerLabel.isHidden = false
         timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(ViewController.updateTimer)), userInfo: nil, repeats: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timerLabel.layer.masksToBounds = true;
        timerLabel.layer.cornerRadius = 8.0;
        
        instructionsLabel.layer.masksToBounds = true;
        instructionsLabel.layer.cornerRadius = 8.0;
        
        distanceLabel.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.5)
        distanceLabel.isHidden = true
        
        timerLabel.isHidden = false
        
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
        let pinch_gesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(recognizer:)))
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeUp(recognizer:)))
        
        swipeGesture.direction = .up
        //tap_gesture.numberOfTouchesRequired = 2
        arView.addGestureRecognizer(tap_gesture)
        arView.addGestureRecognizer(pinch_gesture)
        arView.addGestureRecognizer(swipeGesture)
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
        let candlePosition = self.candleNode.position(relativeTo: nil)
        let cameraPosition = self.camera.position(relativeTo: nil)
        let distanceBetweenCameraAndCandle = candlePosition - cameraPosition;
        let scalarDistanceBetweenCameraAndCandle = length(distanceBetweenCameraAndCandle)
        if self.trainingStatus >= .fireStarted {
            distanceLabel.text = "\(scalarDistanceBetweenCameraAndCandle.roundTo(places: 2)) m"
            distanceLabel.isHidden = false
            if scalarDistanceBetweenCameraAndCandle < 0.5 {
                distanceLabel.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.5)
                distanceLabel.text = "Too close"
            } else {
                distanceLabel.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.5)
            }
        }
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        if trainingStatus == .setTrainingArea{
            print("Anchor added <<<<<")
        }
    }
    
    /// - Tag: UpdateFacialExpression
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        if trainingStatus == .candlePlaced {
            anchors.compactMap { $0 as? ARFaceAnchor }.forEach {
                print("Puff \(String(describing: $0.blendShapes[.cheekPuff]))")
                print("Funnel \(String(describing: $0.blendShapes[.mouthFunnel]))")
                let candlePosition = self.candleNode.position(relativeTo: nil)
                let cameraPosition = self.camera.position(relativeTo: nil)
                let distanceBetweenCameraAndCandle = candlePosition - cameraPosition;
                let scalarDistanceBetweenCameraAndCandle = length(distanceBetweenCameraAndCandle)
                print("Distance Camera and Candle \(scalarDistanceBetweenCameraAndCandle)")
                let isCheekPuff = ($0.blendShapes[.cheekPuff] ?? 0) as Double > 0.20 && ($0.blendShapes[.mouthFunnel] ?? 0) as Double > 0.20 ? true : false
                print("Is cheekpuff \(isCheekPuff)")
                if(isCheekPuff && scalarDistanceBetweenCameraAndCandle < 0.5) {
                    if let candle = trainingEntity.findEntity(named: "candle"){
                        print("Candle blown")
                        candle.scale = [0,0,0]
                        changeAppStatusTo(.candleBlownBefore1Min)
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
            break
        case .start:
            airAnchor = AnchorEntity(world: camera.transformMatrix(relativeTo: nil))
            airAnchor.position.z -= 0.5
            //airAnchor.position.y -= 0.5
            arView.scene.addAnchor(airAnchor)
            
            print("Loading Fire Extinguisher")
            if let fire_ex_body = try? Entity.load(named: "fireext_body") {
                print("FireExt loaded")
                fire_ex_body.name = "fire_ex_body"
                //camera.addChild(fire_ex_body)
                fireExtinguisher = fire_ex_body
                airAnchor.addChild(fire_ex_body)
                fire_ex_body.position.y-=0.5
                changeAppStatusTo(.fireExtinguisherPlaced)
            }else {
                fatalError("Error: Unable to load model.")
            }
            break
        case .setTrainingArea:
            changeAppStatusTo(.start)
            break
        case .fireStarted:
            stopTimer()
            let fireExtinguisherPosition = self.fireExtinguisher.position(relativeTo: nil)
            let cameraPosition = self.camera.position(relativeTo: nil)
            let distanceBetweenCameraAndFireExtinguisher = fireExtinguisherPosition - cameraPosition;
            let scalarDistanceBetweenCameraAndFireExtinguisher = length(distanceBetweenCameraAndFireExtinguisher)
            print("Distance betw Camera and FireExt \(scalarDistanceBetweenCameraAndFireExtinguisher)")
            if scalarDistanceBetweenCameraAndFireExtinguisher < 0.7 {
                //airAnchor.removeChild(fireExtinguisher)
                camera.addChild(fireExtinguisher)
                fireExtinguisher.position.z -= 0.5
                fireExtinguisher.position.y -= 0.3
                changeAppStatusTo(.fetchedFireExtinguisher)
                print("Fetched \(fireExtinguisher.position(relativeTo: camera))")
            }
            break
        case .fetchedFireExtinguisher:
            trainingStatus = .fetchedFireExtinguisher
            print("Fetched \(fireExtinguisher.position(relativeTo: camera))")
            break
        default:
            print()
        }
    }
    
    @objc
    func handlePinch(recognizer: UIPinchGestureRecognizer){
        print("Scale \(recognizer.scale) Velocity \(recognizer.velocity)")
        
        if !self.isPinching{
            self.isPinching = true
            print("Raycasting")
            let hits = arView.hitTest(arView.center, query: .any, mask: .all)
            hits.forEach {
                self.candleNode.removeChild($0.entity)
            }
            DispatchQueue.main.asyncAfter(deadline: .now()+1){
                self.isPinching = false
            }
        }
        
        if candleNode.findEntity(named: "fire_tracker") == nil {
            changeAppStatusTo(.placeSaved)
        }
    }
    
    @objc
    func handleSwipeUp(recognizer: UISwipeGestureRecognizer){
        print("Swiped \(recognizer.direction)")
    }
    
    
    func changeAppStatusTo(_ to: CandleTrainingStatus) {
        switch to {
        case .prestart:
            trainingStatus = .prestart
            instructionsLabel.text = "Find a flat table as space for training. Tap on screen to continue"
        case .setTrainingArea:
            trainingStatus = .setTrainingArea
            instructionsLabel.text = "Move your phone untill you see a blue area. Then tap the screen again."
            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            self.floor = AnchorEntity(plane: .horizontal, classification: .table, minimumBounds: [0, 0])
            floor.name = "training_area"
            let plane = MeshResource.generatePlane(width: 0.5, depth: 0.5) // size in metres
            let material = SimpleMaterial(color: UIColor(red: 0, green: 0, blue: 1, alpha: 0.3), isMetallic: false)
            trainingEntity = ModelEntity(mesh: plane, materials: [material])
            trainingEntity.name = "training_plane"
            arView.scene.addAnchor(floor)
            floor.addChild(trainingEntity)
        case .start:
            trainingStatus = .start
            instructionsLabel.text = "Touch the back of your phone to fire extinguisher and tap on the screen"
        case .fireExtinguisherPlaced:
            trainingStatus = .fireExtinguisherPlaced
            instructionsLabel.text = "Starting Training... Go back to training area."
            DispatchQueue.main.asyncAfter(deadline: .now()+3){
                if self.trainingStatus == .fireExtinguisherPlaced {
                    self.addCandle()
                    self.changeAppStatusTo(.candlePlaced)
                }
            }
        case .candlePlaced:
            trainingStatus = .candlePlaced
            runTimer()
            print("Run timer Called")
            if let trainginPlane = self.floor.findEntity(named: "training_plane") {
                trainginPlane.components[ModelComponent] = ModelComponent(
                    mesh: MeshResource.generatePlane(width: 0.1, depth: 0.1),
                    materials: [SimpleMaterial(
                        color: UIColor(red: 0, green: 0, blue: 1, alpha: 0.0),
                        isMetallic: false)
                    ]
                )
            }
            
            instructionsLabel.text = "An open flame is placed in the scene. It can be dangerous. Blow it out"
        case .candleBlownBefore1Min:
            stopTimer()
            trainingStatus = .candleBlownBefore1Min
            instructionsLabel.text = "You have averted potential hazardous scenario"
        case .fireStarted:
            stopTimer()
            DispatchQueue.main.asyncAfter(deadline: .now() + 30){
                if self.trainingStatus == .fireStarted {
                    self.changeAppStatusTo(.placeDamaged)
                    print("Place Damaged")
                }
            }
            runTimer()
            trainingStatus = .fireStarted
            instructionsLabel.text = "There is fire in your room. Go to your fire entinguisher and tap the screen"
        case .fetchedFireExtinguisher:
            crosshair.image = UIImage(systemName: "plus")
            trainingStatus = .fetchedFireExtinguisher
            instructionsLabel.text = "Aim at the base of the fire and squeeze the handle by pinching on screen"
        case .placeDamaged:
            trainingStatus = .placeDamaged
            instructionsLabel.text = "You failed to protect your belongings"
        case .fireExtinguishedBefore2Min:
            trainingStatus = .fireExtinguishedBefore2Min
            instructionsLabel.text = "Congratulations, you saved your room from fire"
        case .placeSaved:
            stopTimer()
            trainingStatus = .placeSaved
            instructionsLabel.text = "You have averted potential hazardous scenario"
        default:
            instructionsLabel.text = ""
        }
    }
    func addCandle() {
        print("Loading Candle....")
        if let candle = try? Entity.load(named: "short_candle") {
            if self.trainingStatus != .prestart {
                self.candleNode = candle
                print("Candle added at \(candle.position)")
                candle.name = "candle"
                print("Candle Animations \(candle.availableAnimations)")
                candle.availableAnimations.forEach{
                    candle.playAnimation($0.repeat(duration: .infinity), transitionDuration: 0, startsPaused: false)
                }
                candle.playAnimation(named: "transform")
                trainingEntity.addChild(candle)
                DispatchQueue.main.asyncAfter(deadline: .now() + 30) { //change thi soon
                    if self.trainingStatus == .candlePlaced {
                        print("Burning Started")
                        
                        let box = MeshResource.generateBox(size: 0.05) // size in metres
                        let material = SimpleMaterial(color: .green, isMetallic: true)
                        let boxEntity = ModelEntity(mesh: box, materials: [material])
                        boxEntity.name =  "fire_tracker"
                        boxEntity.collision = CollisionComponent(
                            shapes: [.generateBox(size: [0.05,0.05,0.05])],
                            mode: .trigger,
                          filter: .sensor
                        )
                        /*let boxEntity = CustomExtinguisherComponent(color: UIColor(red: 1,
                                                                                   green: 0,
                                                                                   blue: 0, alpha: 0),
                                                                    position:[0,0,0])//ModelEntity(mesh: box, materials: [material])*/
                        if let flame = try? Entity.load(named: "fire") {
                            flame.availableAnimations.forEach {
                                print($0.name ?? "No Name for animation in fire")
                                flame.playAnimation($0.repeat(duration: .infinity), transitionDuration: 0, startsPaused: false)
                            }
                            boxEntity.addChild(flame)
                        }
                        
                        let boxEntity5 = boxEntity.clone(recursive: true)
                        boxEntity5.position.x += 0.1
                        
                        let boxEntity2 = boxEntity.clone(recursive: true)
                        boxEntity2.position.x -= 0.1
                        boxEntity2.transform.rotation = simd_quatf(angle: .pi, axis: [0, 1, 0])
                        
                        let boxEntity3 = boxEntity.clone(recursive: true)
                        boxEntity3.position.z += 0.1
                        boxEntity3.position.x = 0
                        boxEntity3.transform.rotation = simd_quatf(angle: .pi/2, axis: [0, 1, 0])
                        
                        let boxEntity4 = boxEntity.clone(recursive: true)
                        boxEntity4.position.z -= 0.1
                        boxEntity4.position.x = 0
                        boxEntity4.transform.rotation = simd_quatf(angle: .pi/2, axis: [0, -1, 0])
                        
                        
                        if self.trainingStatus != .candleBlownBefore1Min {
                            self.changeAppStatusTo(.fireStarted)
                            candle.addChild(boxEntity)
                            candle.addChild(boxEntity2)
                            candle.addChild(boxEntity3)
                            candle.addChild(boxEntity4)
                        }
                        candle.addChild(boxEntity)
                    }
                }
            }
            //wall.addChild(candle.clone(recursive: true))
        } else {
            fatalError("Error: Unable to load model.")
        }
    }
}

extension Float {
    func roundTo(places:Int) -> Float {
        let divisor = Float(pow(Float(10.0), Float(places)))
        return (self * divisor).rounded() / divisor
    }
}
