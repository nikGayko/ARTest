//
//  ARFaceContentController.swift
//  ARTest
//
//  Created by Mikita Haiko on 4/15/21.
//  Copyright © 2021 Mikita Haiko. All rights reserved.
//

import Foundation
import SceneKit

protocol FaceSceneViewProtocol {
    var scene: SCNScene { get }
    var faceContainerNode: SCNNode { get }
}

struct ARContentController {
    
    private var glassesNode: SCNNode?
    
    private let arFaceViewController: FaceSceneViewProtocol
    private let modelLoader: ModelLoader
    private let glassesNodeComposer: GlassesNodeComposer
    private let lightConfigurator: LightConfigurator
    private let lightingEnvironmentConfigurator: LightingEnvironmentConfigurator
    
    init(
        arFaceViewController: FaceSceneViewProtocol,
        modelLoader: ModelLoader,
        glassesNodeComposer: GlassesNodeComposer,
        lightConfigurator: LightConfigurator,
        lightingEnvironmentConfigurator: LightingEnvironmentConfigurator
    ) {
        self.arFaceViewController = arFaceViewController
        self.modelLoader = modelLoader
        self.glassesNodeComposer = glassesNodeComposer
        self.lightConfigurator = lightConfigurator
        self.lightingEnvironmentConfigurator = lightingEnvironmentConfigurator
    }
}

extension ARContentController {
    
    mutating func removeGlasses() {
        glassesNode?.removeFromParentNode()
    }
    
    mutating func updateModel(withModelsAtURL folderURL: URL, modelName: String) throws {
        let meshes = try ModelLoader().loadModelAssets(fromFolder: folderURL, named: modelName)
        let node = try glassesNodeComposer.compose(
            eyeRimsMesh: meshes.eyeRimsMesh,
            leftBranchMesh: meshes.leftBranchMesh,
            rightBranchMesh: meshes.rightBranchMesh
        )
        removeGlasses()
        glassesNode = node
        arFaceViewController.faceContainerNode.addChildNode(node)
    }
}

extension ARContentController {
    func configureLight() {
        let lightNode = lightConfigurator.configureLight(for: .lenses)  // Used for blue-light filtering effect
        arFaceViewController.faceContainerNode.addChildNode(lightNode)
    }
}

extension ARContentController {
    func configureLightingEnvironment(intensity: CGFloat) {
        lightingEnvironmentConfigurator.configureLightingEnvironment(arFaceViewController.scene, intensity: intensity)
    }
}
