//
//  TrainingStatus.swift
//  HazAR
//
//  Created by Akshay Shinde on 2/29/20.
//  Copyright © 2020 Akshay_Shinde. All rights reserved.
//

import Foundation

enum CandleTrainingStatus: Int, Comparable {
    static func < (lhs: CandleTrainingStatus, rhs: CandleTrainingStatus) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    case prestart = 1
    case setTrainingArea
    case start
    case fireExtinguisherPlaced
    case candlePlaced
    case candleBlownBefore1Min
    case fireStarted
    case fetchedFireExtinguisher
    case fireExtinguishedBefore2Min
    case placeDamaged
    case placeSaved
}
