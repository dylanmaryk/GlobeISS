//
//  InterfaceController.swift
//  GlobeISS WatchKit Extension
//
//  Created by Dylan Maryk on 02/05/2020.
//  Copyright © 2020 Dylan Maryk. All rights reserved.
//

import WatchKit

class InterfaceController: WKInterfaceController, WKCrownDelegate {
    
    @IBOutlet private weak var sceneView: WKInterfaceSCNScene!
    
    private lazy var globeNode = self.createGlobeNode()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        let scene = SCNScene()
        scene.rootNode.addChildNode(self.globeNode)
        sceneView.scene = scene
        
        self.crownSequencer.delegate = self
        self.crownSequencer.focus()
    }
    
    @IBAction func panGesture(_ sender: Any) {
        let gestureRecognizer = sender as! WKPanGestureRecognizer
        let translation = gestureRecognizer.translationInObject()
        let x = translation.x
        let y = -translation.y
        let anglePan = sqrt(pow(x, 2) + pow(y, 2)) * .pi / 180
        let rotationVector = SCNVector4(-y, x, 0, anglePan)
        self.globeNode.rotation = rotationVector
        
        if gestureRecognizer.state == .ended {
            let currentPivot = self.globeNode.pivot
            let currentPosition = self.globeNode.position
            let changePivot = SCNMatrix4Invert(SCNMatrix4MakeRotation(self.globeNode.rotation.w,
                                                                      self.globeNode.rotation.x,
                                                                      self.globeNode.rotation.y,
                                                                      self.globeNode.rotation.z))
            self.globeNode.pivot = SCNMatrix4Mult(changePivot, currentPivot)
            self.globeNode.transform = SCNMatrix4Identity
            self.globeNode.position = currentPosition
        }
    }
    
    func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
        self.globeNode.runAction(.moveBy(x: 0, y: 0, z: CGFloat(rotationalDelta), duration: 0))
    }
    
    private func createGlobeNode() -> SCNNode {
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "snapshot-2020-05-1")
        
        let sphere = SCNSphere(radius: 1)
        sphere.firstMaterial = material
        
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = SCNVector3(0, 0, 0)
        
        return sphereNode
    }
    
}
