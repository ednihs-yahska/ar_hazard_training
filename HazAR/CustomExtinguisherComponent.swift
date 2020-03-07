//
//  CustomExtinguisherComponent.swift
//  HazAR
//
//  Created by Akshay Shinde on 3/4/20.
//  Copyright © 2020 Akshay_Shinde. All rights reserved.
//

import Foundation
import UIKit
import RealityKit
import Combine

class CustomExtinguisherComponent: Entity, HasModel, HasAnchoring {
    var collisionSubs: [Cancellable] = []
    
    required init() {
        super.init()
        let color = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        self.components[CollisionComponent] = CollisionComponent(
            shapes: [.generateBox(size: [0.05,0.05,0.05])],
            mode: .trigger,
          filter: .sensor
        )
        
        self.components[ModelComponent] = ModelComponent(
            mesh: .generateBox(size: [0.05,0.05,0.05]),
            materials: [SimpleMaterial(
                color: color,
                isMetallic: false)
            ]
        )
    }
    
    convenience init(color: UIColor, position: SIMD3<Float>) {
        self.init()
        self.position = position
    }
}

extension CustomExtinguisherComponent {
    func addCollisions() {
        guard let scene = self.scene else {
            return
        }
        
        collisionSubs.append(scene.subscribe(to: CollisionEvents.Began.self, on: self){ event in
            print("Collision of \(event.entityA) and \(event.entityB)")
        })
    }
}
