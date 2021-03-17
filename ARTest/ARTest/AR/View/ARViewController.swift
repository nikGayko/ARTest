//
//  ARViewController.swift
//  ARTest
//
//  Created by Mikita Haiko on 2/16/21.
//  Copyright © 2021 Mikita Haiko. All rights reserved.
//

import UIKit
import ARKit
import SceneKit


class ARViewController: UIViewController, FaceSceneViewProtocol {
    
    struct Delegate {
        let onError: (Error) -> Void
    }
    
    let faceContainerNode = SCNNode()
    
    var scene: SCNScene { sceneView.scene }
    
    private var faceMeshNode: SCNNode?
    
    private var sceneView: ARSCNView!
    
    private var delegate: Delegate!
    
    convenience init(delegate: Delegate) {
        self.init()
        self.delegate = delegate
    }
    
    override func loadView() {
        sceneView = .init()
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.backgroundColor = .clear
        
        self.view = sceneView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        startTracking()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }
}


extension ARViewController {
    static var isAvailable: Bool { ARFaceTrackingConfiguration.isSupported }
    
    private func startTracking() {
        resetTracking()
    }
    
    private func resetTracking() {
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = false
        
        sceneView.session.run(
            configuration,
            options: [.resetTracking, .removeExistingAnchors]
        )
    }
}


extension ARViewController: ARSCNViewDelegate {    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let sceneView = renderer as? ARSCNView, anchor is ARFaceAnchor else {
            return
        }
        
        let faceGeometry: ARSCNFaceGeometry = {
            let faceGeometry = ARSCNFaceGeometry(device: sceneView.device!, fillMesh: true)!
            faceGeometry.firstMaterial!.colorBufferWriteMask = []
            return faceGeometry
        }()
        
        let faceMeshNode = SCNNode(geometry: faceGeometry)
        faceMeshNode.renderingOrder = -1
        faceMeshNode.name = "Face"
        
        self.faceMeshNode = faceMeshNode
        
        faceContainerNode.addChildNode(faceMeshNode)
        node.addChildNode(faceContainerNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceGeometry = faceMeshNode?.geometry as? ARSCNFaceGeometry,
              let faceAnchor = anchor as? ARFaceAnchor
        else {
            return
        }
        
        faceGeometry.update(from: faceAnchor.geometry)
    }
}


extension ARViewController: ARSessionDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {
        let error = ARError(error: error)
        delegate?.onError(error)
    }
}
