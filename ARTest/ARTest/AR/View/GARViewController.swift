//
//  GARViewController.swift
//  ARTest
//
//  Created by Mikita Haiko on 4/16/21.
//  Copyright © 2021 Mikita Haiko. All rights reserved.
//

import AVFoundation
import CoreMotion
import SceneKit
import UIKit
import ARCoreAugmentedFaces


class GARViewController: UIViewController, FaceSceneViewProtocol {
    
    struct Delegate {
        let onError: (Error) -> Void
    }

    let faceContainerNode = SCNNode()
    let scene = SCNScene()
    
    var delegate: Delegate!
    
    // MARK: - Camera / Scene properties
    private var captureDevice: AVCaptureDevice?
    private var captureSession: AVCaptureSession?
    private var videoFieldOfView = Float(0)
    private lazy var cameraImageLayer = CALayer()
    private lazy var sceneView = SCNView()
    private lazy var sceneCamera = SCNCamera()
    private lazy var motionManager = CMMotionManager()
    
    // MARK: - Face properties
    
    private var faceSession: GARAugmentedFaceSession?
    private lazy var faceMeshConverter = FaceMeshGeometryConverter()
    private lazy var faceNode = SCNNode()
    
    // MARK: - Implementation methods
    
    convenience init(delegate: Delegate) {
        self.init()
        self.delegate = delegate
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            setupScene()
            try setupCamera()
            try setupMotion()
            faceSession = try GARAugmentedFaceSession(fieldOfView: videoFieldOfView)
        } catch {
            delegate.onError(error)
        }
    }
}


extension GARViewController {
    
    static var isAvailable: Bool {
        CMMotionManager().isDeviceMotionAvailable && Model.current.isARCoreAvailable
    }
    
    private func setupScene() {
        faceContainerNode.addChildNode(faceNode)
        scene.rootNode.addChildNode(faceContainerNode)
        scene.rootNode.camera = sceneCamera
        
        sceneView.scene = scene
        sceneView.frame = view.bounds
        sceneView.delegate = self
        sceneView.rendersContinuously = true
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.backgroundColor = .clear
        sceneView.layer.transform = CATransform3DMakeScale(-1, 1, 1)
        view.addSubview(sceneView)
    }
    
    private func setupCamera() throws {
        guard
            AVCaptureDevice.authorizationStatus(for: .video) == .authorized,
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        else {
            throw ARError.unknown
        }
        
        let input = try AVCaptureDeviceInput(device: device)
        
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInteractive))
        
        self.captureSession = {
            let session = AVCaptureSession()
            session.sessionPreset = .high
            session.addInput(input)
            session.addOutput(output)
            return session
        }()
        captureDevice = device
        
        videoFieldOfView = captureDevice?.activeFormat.videoFieldOfView ?? 0
        
        cameraImageLayer.contentsGravity = .center
        cameraImageLayer.frame = self.view.bounds
        view.layer.insertSublayer(cameraImageLayer, at: 0)
        
        captureSession?.startRunning()
    }
    
    private func setupMotion() throws {
        guard motionManager.isDeviceMotionAvailable else {
            throw ARError.unknown
        }
        motionManager.deviceMotionUpdateInterval = 0.01
        motionManager.startDeviceMotionUpdates()
    }
}

// MARK: - Camera delegate


extension GARViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let imgBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let deviceMotion = motionManager.deviceMotion
        else {
            return
        }
        
        let frameTime = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        
        // Use the device's gravity vector to determine which direction is up for a face. This is the
        // positive counter-clockwise rotation of the device relative to landscape left orientation.
        let rotation = 2 * .pi - atan2(deviceMotion.gravity.x, deviceMotion.gravity.y) + .pi / 2
        let rotationDegrees = (UInt)(rotation * 180 / .pi) % 360
        
        faceSession?.update(with: imgBuffer, timestamp: frameTime, recognitionRotation: rotationDegrees)
    }
}

// MARK: - Scene Renderer delegate


extension GARViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let frame = faceSession?.currentFrame else {
            return
        }
        
        if let face = frame.face {
            faceNode.geometry = faceMeshConverter.geometryFromFace(face)
            faceNode.geometry?.firstMaterial?.colorBufferWriteMask = []
            faceContainerNode.simdWorldTransform = face.centerTransform
        }
        
        // Set the scene camera's transform to the projection matrix for this frame.
        sceneCamera.projectionTransform = SCNMatrix4.init(
            frame.projectionMatrix(
                forViewportSize: cameraImageLayer.bounds.size,
                presentationOrientation: .portrait,
                mirrored: false,
                zNear: 0.05,
                zFar: 100)
        )
        
        // Update the camera image layer's transform to the display transform for this frame.
        CATransaction.begin()
        CATransaction.setAnimationDuration(0)
        cameraImageLayer.contents = frame.capturedImage as CVPixelBuffer
        cameraImageLayer.setAffineTransform(
            frame.displayTransform(
                forViewportSize: cameraImageLayer.bounds.size,
                presentationOrientation: .portrait,
                mirrored: true)
        )
        CATransaction.commit()
        
        // Only show AR content when a face is detected.
        sceneView.scene?.rootNode.isHidden = frame.face == nil
    }
}

// MARK: - FaceMeshGeometryConverter
/// Converts `GARAugmentedFace` meshes into `SCNGeometry`.
class FaceMeshGeometryConverter {
    
    /// Metal device used for allocating Metal buffers.
    private lazy var metalDevice = MTLCreateSystemDefaultDevice()
    
    /// Array of face meshes used for multiple-buffering.
    private let faceMeshes = [FaceMesh(), FaceMesh()]
    
    /// Index of which face mesh to use. Alternates every frame.
    private var frameCount: Int = 0
    
}

extension FaceMeshGeometryConverter {
    /// Contains all objects needed to hold a face mesh. Used for multi-buffering.
    private class FaceMesh {
        /// Metal buffer containing vertex positions.
        var mtlVertexBuffer: MTLBuffer?
        
        /// Metal buffer containing texture coordinates.
        var mtlTexBuffer: MTLBuffer?
        
        /// Metal buffer containing normal vectors.
        var mtlNormalBuffer: MTLBuffer?
        
        /// Buffer containing triangle indices.
        var indexBuffer: NSMutableData?
        
        /// SceneKit geometry source for vertex positions.
        var vertSource = SCNGeometrySource()
        
        /// SceneKit geometry source for texture coordinates.
        var texSource = SCNGeometrySource()
        
        /// SceneKit geometry source for normal vectors.
        var normSource = SCNGeometrySource()
        
        /// SceneKit element for triangle indices.
        var element = SCNGeometryElement()
        
        /// SceneKit geometry for the face mesh.
        var geometry = SCNGeometry()
    }
    
}

extension FaceMeshGeometryConverter {
    /// Generates a `SCNGeometry` from a face mesh.
    ///
    /// - Parameters:
    ///   - face: The face mesh geometry.
    /// - Returns: The constructed geometry from a face mesh.
    func geometryFromFace(_ face: GARAugmentedFace?) -> SCNGeometry? {
        guard let face = face else { return nil }
        
        frameCount += 1
        let faceMesh = faceMeshes[self.frameCount % self.faceMeshes.count]
        
        #if !targetEnvironment(simulator)
        
        let vertexSize = MemoryLayout.size(ofValue: face.mesh.vertices[0])
        let texSize = MemoryLayout.size(ofValue: face.mesh.textureCoordinates[0])
        let normSize = MemoryLayout.size(ofValue: face.mesh.normals[0])
        let idxSize = MemoryLayout.size(ofValue: face.mesh.triangleIndices[0])
        
        let vertexCount = Int(face.mesh.vertexCount)
        let triangleCount = Int(face.mesh.triangleCount)
        let indexCount = triangleCount * 3
        
        let vertBufSize: size_t = vertexSize * vertexCount
        let texBufSize: size_t = texSize * vertexCount
        let normalBufSize: size_t = normSize * vertexCount
        let idxBufSize: size_t = idxSize * indexCount
        
        var reallocateGeometry = false
        
        // Creates a vertex buffer and sets up a vertex source when the vertex buffer size changes.
        if faceMesh.mtlVertexBuffer?.length != vertBufSize {
            guard
                let vertexBuffer = metalDevice?.makeBuffer(
                    length: vertBufSize,
                    options: .storageModeShared)
            else { return nil }
            faceMesh.mtlVertexBuffer = vertexBuffer
            faceMesh.vertSource = SCNGeometrySource(
                buffer: vertexBuffer,
                vertexFormat: .float3,
                semantic: .vertex,
                vertexCount: vertexCount,
                dataOffset: 0,
                dataStride: vertexSize)
            reallocateGeometry = true
        }
        
        // Creates a texture buffer and sets up a texture source when the texture buffer size changes.
        if faceMesh.mtlTexBuffer?.length != texBufSize {
            guard
                let textureBuffer = metalDevice?.makeBuffer(
                    length: texBufSize,
                    options: .storageModeShared)
            else { return nil }
            faceMesh.mtlTexBuffer = textureBuffer
            faceMesh.texSource = SCNGeometrySource(
                buffer: textureBuffer,
                vertexFormat: .float2,
                semantic: .texcoord,
                vertexCount: vertexCount,
                dataOffset: 0,
                dataStride: texSize)
            reallocateGeometry = true
        }
        
        // Creates a normal buffer and sets up a normal source when the normal buffer size changes.
        if faceMesh.mtlNormalBuffer?.length != normalBufSize {
            guard
                let normalBuffer = metalDevice?.makeBuffer(
                    length: normalBufSize,
                    options: .storageModeShared)
            else { return nil }
            faceMesh.mtlNormalBuffer = normalBuffer
            faceMesh.normSource = SCNGeometrySource(
                buffer: normalBuffer,
                vertexFormat: .float3,
                semantic: .normal,
                vertexCount: vertexCount,
                dataOffset: 0,
                dataStride: normSize)
            reallocateGeometry = true
        }
        
        // Creates an index buffer and sets up an element when the index buffer size changes.
        if faceMesh.indexBuffer?.length != idxBufSize {
            let indexBuffer = NSMutableData(
                bytes: face.mesh.triangleIndices,
                length: idxBufSize)
            faceMesh.indexBuffer = indexBuffer
            faceMesh.element = SCNGeometryElement(
                data: indexBuffer as Data?,
                primitiveType: .triangles,
                primitiveCount: triangleCount,
                bytesPerIndex: idxSize)
            reallocateGeometry = true
        }
        
        // Copy the face mesh data into the appropriate buffers.
        if let vertexBuffer = faceMesh.mtlVertexBuffer,
           let textureBuffer = faceMesh.mtlTexBuffer,
           let normalBuffer = faceMesh.mtlNormalBuffer,
           let indexBuffer = faceMesh.indexBuffer
        {
            memcpy(vertexBuffer.contents(), face.mesh.vertices, vertBufSize)
            memcpy(textureBuffer.contents(), face.mesh.textureCoordinates, texBufSize)
            memcpy(normalBuffer.contents(), face.mesh.normals, normalBufSize)
            memcpy(indexBuffer.mutableBytes, face.mesh.triangleIndices, idxBufSize)
        }
        
        // If any of the sources or element changed, reallocate the geometry.
        if reallocateGeometry {
            let sources = [faceMesh.vertSource, faceMesh.texSource, faceMesh.normSource]
            faceMesh.geometry = SCNGeometry(sources: sources, elements: [faceMesh.element])
        }
        
        #endif
        
        return faceMesh.geometry
    }
    
}

fileprivate extension Model {
    var isARCoreAvailable: Bool {
        switch self {
        case .iPhone4,
             .iPhone4s,
             .iPhone5,
             .iPhone5c,
             .iPhone5s,
             .iPhone6,
             .iPhone6Plus,
             
             .iPad2,
             .iPad3gen,
             .iPad4gen,
             
             .iPadAir,
             .iPadAir2,
             
             .iPadMini,
             .iPadMini2,
             .iPadMini3,
             .iPadMini4:
            return false
            
        default:
            return true
        }
    }
}
