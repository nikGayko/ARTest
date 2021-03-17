//
//  GlassesModelLoader.swift
//  ARTest
//
//  Created by Nikita Gayko on 13.04.22.
//  Copyright © 2022 Mikita Haiko. All rights reserved.
//

import Foundation
import ModelIO

class ModelLoader {
    
    struct GlassesMeshes {
        let eyeRimsMesh: MDLMesh
        let leftBranchMesh: MDLMesh
        let rightBranchMesh: MDLMesh
    }
    
    func loadModelAssets(fromFolder folderURL: URL, named modelName: String) throws -> GlassesMeshes {
        
        let eyeRimsFileName = modelName + ".obj"
        let leftBranchFileName = modelName + "-left-branch.obj"
        let rightBranchFileName = modelName + "-right-branch.obj"
        
        let eyeRimsURL = folderURL.appendingPathComponent(eyeRimsFileName)
        let leftBranchURL = folderURL.appendingPathComponent(leftBranchFileName)
        let rightBranchURL = folderURL.appendingPathComponent(rightBranchFileName)

        guard
            let eyeRimsMesh = MDLAsset(url: eyeRimsURL).object(at: 0) as? MDLMesh,
            let leftBranchMesh = MDLAsset(url: leftBranchURL).object(at: 0) as? MDLMesh,
            let rightBranchMesh = MDLAsset(url: rightBranchURL).object(at: 0) as? MDLMesh
        else {
            throw ARError.unknown
        }

        return .init(eyeRimsMesh: eyeRimsMesh, leftBranchMesh: leftBranchMesh, rightBranchMesh: rightBranchMesh)
    }
}

