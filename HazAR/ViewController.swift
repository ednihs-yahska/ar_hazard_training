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
    
    @IBOutlet var arView: ARView!
    let configuration = ARWorldTrackingConfiguration()
    let wall = AnchorEntity(plane: .vertical, classification: .wall, minimumBounds: [0,0])
    let floor = AnchorEntity(plane: .horizontal, classification: .any, minimumBounds: [0, 0])
    let camera = AnchorEntity(.camera)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard ARWorldTrackingConfiguration.supportsUserFaceTracking else {
            fatalError("This sample code requires iOS 13, and an iOS device with a front TrueDepth camera.")
        }
        
        arView.session.delegate = self
        arView.debugOptions.insert(.showAnchorGeometry)
        //arView.debugOptions.insert(.showAnchorOrigins)
        arView.debugOptions.insert(.showFeaturePoints)
        //arView.debugOptions.insert(.showStatistics)
        arView.debugOptions.insert(.showWorldOrigin)
        // Load the "Box" scene from the "Experience" Reality File
        //let boxAnchor = try! Experience.loadBox()
        
        arView.automaticallyConfigureSession = false
        configuration.userFaceTrackingEnabled = true
        configuration.planeDetection = [.horizontal, .vertical]
        
        
         print("Loading Candle....")
         if let candle = try? Entity.load(named: "short_candle") {
            print("Candle added at \(candle.position)")
            candle.name = "candle"
            candle.playAnimation(named: "transform")
            floor.addChild(candle)
            
            //wall.addChild(candle.clone(recursive: true))
         } else {
            fatalError("Error: Unable to load model.")
         }
        
        let tap_gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        //tap_gesture.numberOfTouchesRequired = 2
        arView.addGestureRecognizer(tap_gesture)
        
         // Add the box anchor to the scene
         //arView.scene.anchors.append(boxAnchor)
            print("Attacching floor....")
        arView.scene.addAnchor(camera)
         arView.scene.anchors.append(floor)
        arView.scene.anchors.append(wall)
       
    }
    
    /// - Tag: RunConfiguration
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        arView.session.run(configuration)
        print("Ran configuration")
        
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        print()
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
//        anchors.forEach {
//            print("\nAnchor added \($0.description)\n")
//        }
    }
    
    /// - Tag: UpdateFacialExpression
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        anchors.compactMap { $0 as? ARFaceAnchor }.forEach {
            let isCheekPuff = ($0.blendShapes[.cheekPuff] ?? 0) as Double > 0.9 ? true : false
            if(isCheekPuff) {
                //print("\n Cheeks puffing \n")
                if let candle = floor.findEntity(named: "candle"){
                    candle.scale = [0,0,0]
                    
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
        print("Double Tap recognized")
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
        }else {
            fatalError("Error: Unable to load model.")
        }
        
        
        
    }
}
