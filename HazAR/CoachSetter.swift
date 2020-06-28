//
//  CoachSetter.swift
//  HazAR
//
//  Created by Akshay Shinde on 6/17/20.
//  Copyright © 2020 Akshay_Shinde. All rights reserved.
//
import ARKit

class CoachSetter: NSObject, ARCoachingOverlayViewDelegate {
    // Example callback for the delegate object
    public func coachingOverlayViewDidDeactivate(
      _ coachingOverlayView: ARCoachingOverlayView
    ) {
      print("Coaching Deactivated")
    }
    
}
