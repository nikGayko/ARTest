//
//  LightConfigurator.swift
//  ARTest
//
//  Created by Mikita Haiko on 4/20/21.
//  Copyright © 2021 Mikita Haiko. All rights reserved.
//

import SceneKit

fileprivate enum LightNodes {
    case omni
    
    var title: String {
        switch self {
        case .omni: return "LIGHT"
        }
    }
}

struct LightConfigurator {
}


extension LightConfigurator {
    func configureLight(for categories: GlassesModelsCategory) -> SCNNode {
        let light = SCNLight()
        light.type = .omni
        light.color = UIColor.blue
        light.intensity = 10000
        light.categoryBitMask = categories.rawValue
        
        let lightNode = SCNNode()
        lightNode.position = .init(5, 0, 15)
        lightNode.name = LightNodes.omni.title
        lightNode.light = light
        return lightNode
    }
}
