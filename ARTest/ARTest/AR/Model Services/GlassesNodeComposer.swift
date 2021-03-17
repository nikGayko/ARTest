//
//  GlassesController.swift
//  ARTest
//
//  Created by Mikita Haiko on 4/15/21.
//  Copyright © 2021 Mikita Haiko. All rights reserved.
//

import Foundation
import SceneKit
import SceneKit.ModelIO
import ModelIO

class GlassesNodeComposer {
    
    private static let MODEL_SCALE = 0.0015678
    private static let MODEL_POSITION = SCNVector3(0.0, 0.02, 0.05)
    
    func compose(eyeRimsMesh: MDLMesh, leftBranchMesh: MDLMesh, rightBranchMesh: MDLMesh) throws -> SCNNode {
        
        func configureLightReflection(of mesh: MDLMesh) {
            mesh.submeshes?.forEach({ item in
                guard
                    let submesh = item as? MDLSubmesh,
                    let scatteringFunction = submesh.material?.scatteringFunction as? MDLPhysicallyPlausibleScatteringFunction
                else {
                    return
                }
                
                scatteringFunction.metallic.floatValue = 1.0
                scatteringFunction.roughness.floatValue = 0.0
            })
        }
        
        configureLightReflection(of: eyeRimsMesh)
        configureLightReflection(of: leftBranchMesh)
        configureLightReflection(of: rightBranchMesh)
        
        let glassesNode = SCNNode()
        glassesNode.scale = {
            let scale = Self.MODEL_SCALE
            return .init(scale, scale, scale)
        }()
        glassesNode.position = Self.MODEL_POSITION
        
        let leftBranchNode = composeBranchNode(mesh: leftBranchMesh, type: .leftBranch)
        glassesNode.addChildNode(leftBranchNode)
        
        let rightBranchNode = composeBranchNode(mesh: rightBranchMesh, type: .rightBranch)
        glassesNode.addChildNode(rightBranchNode)
        
        let eyeRimsNode = composeEyeRimsNode(mesh: eyeRimsMesh)
        glassesNode.addChildNode(eyeRimsNode)
        
        return glassesNode
    }
    
    private func composeBranchNode(mesh: MDLMesh, type: GlassesModelType) -> SCNNode {
        
        let branchNode = SCNNode(geometry: .init(mdlMesh: mesh))

        let (deviationMultiplier, xValueOfTargetPoint, categoryBitMask): (Double, Float, GlassesModelsCategory) = {
            let nodeBoundingBox = branchNode.boundingBox
            switch type {
            case .rightBranch: return (1, nodeBoundingBox.min.x + 3, .rightBranch)
            case .leftBranch: return (-1, nodeBoundingBox.max.x - 3, .leftBranch)
            default: fatalError("Unexpected model type passed")
            }
        }()
                
        /// Deviation of 17.5 degrees
        ///
        /// Glasses deviation expresses in Quanternions to rotate around not pivot point, but around explicity specified point.
        /// Runtime calculation of deviation is impossible due to rough aproximation
        /// of face node physics body(mesh presented almost like a box), that's why value hardcoded
        let deviation = SCNQuaternion(0, 0.1521234 * deviationMultiplier, 0, 0.9883615)

        let targetPoint = SCNVector3(xValueOfTargetPoint, 0, 0)
        
        branchNode.rotate(
            by: deviation,
            aroundTarget: targetPoint
        )
        
        branchNode.name = type.sceneNodeTitle
        branchNode.categoryBitMask = categoryBitMask.rawValue
        
        return branchNode
    }
    
    private func composeEyeRimsNode(mesh: MDLMesh) -> SCNNode {
        let containerNode = SCNNode()
        
        // Converting submeshes of lenses into separate mesh.
        mesh.submeshes?
            .filter { item in
                guard let submesh = item as? MDLSubmesh else {
                    return false
                }
                
                if submesh.name.contains("glass") {
                    return true
                }
                if let opacity = submesh.material?.property(with: .opacity)?.floatValue, opacity < 0.8 {
                    return true
                }
                return false
            }
            .forEach({ item in
                guard let index = mesh.submeshes?.index(of: item) else {
                    return
                }
                
                let mesh = MDLMesh(meshBySubdividingMesh: mesh, submeshIndex: Int32(index), subdivisionLevels: 4, allocator: nil)
                let node = SCNNode(geometry: .init(mdlMesh: mesh))
                node.name = GlassesModelType.lenses.sceneNodeTitle
                node.categoryBitMask = GlassesModelsCategory.lenses.rawValue
                
                containerNode.addChildNode(node)                
            })

        let eyeRimsNode = SCNNode(geometry: .init(mdlMesh: mesh))
        eyeRimsNode.name = GlassesModelType.eyeRims.sceneNodeTitle
        eyeRimsNode.categoryBitMask = GlassesModelsCategory.eyeRims.rawValue

        containerNode.addChildNode(eyeRimsNode)
        
        return containerNode
    }
}

fileprivate extension GlassesModelType {
    var sceneNodeTitle: String {
        switch self {
        case .lenses: return "Lenses"
        case .eyeRims: return "Eye Rims"
        case .leftBranch: return "Left branch"
        case .rightBranch: return "Right branch"
        }
    }
}
