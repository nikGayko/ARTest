//
//  GlassesModelType.swift
//  ARTest
//
//  Created by Nikita Gayko on 13.04.22.
//  Copyright © 2022 Mikita Haiko. All rights reserved.
//

import Foundation

enum GlassesModelType {
    case lenses
    case eyeRims
    case leftBranch
    case rightBranch
}

struct GlassesModelsCategory: OptionSet {
    let rawValue: Int
    
    static let lenses = Self(rawValue: 1 << 0)
    static let eyeRims = Self(rawValue: 1 << 1)
    static let leftBranch = Self(rawValue: 1 << 2)
    static let rightBranch = Self(rawValue: 1 << 3)
}
