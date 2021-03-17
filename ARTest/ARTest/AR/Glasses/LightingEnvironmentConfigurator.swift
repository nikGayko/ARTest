//
//  SceneConfigurator.swift
//  ARTest
//
//  Created by Mikita Haiko on 28.09.21.
//  Copyright © 2021 Mikita Haiko. All rights reserved.
//

import Foundation
import SceneKit

struct LightingEnvironmentConfigurator {
    func configureLightingEnvironment(_ scene: SCNScene, intensity: CGFloat) {
        scene.lightingEnvironment.contents = UIImage(named: "lightingEnvironment")
        scene.lightingEnvironment.intensity = intensity
    }
}
