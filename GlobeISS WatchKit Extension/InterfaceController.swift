//
//  InterfaceController.swift
//  GlobeISS WatchKit Extension
//
//  Created by Dylan Maryk on 02/05/2020.
//  Copyright © 2020 Dylan Maryk. All rights reserved.
//

import Combine
import WatchKit

class InterfaceController: WKInterfaceController, WKCrownDelegate {
    
    @IBOutlet private weak var sceneView: WKInterfaceSCNScene!
    
    private var timerCancellable: AnyCancellable?
    private var issPositionSessionCancellable: AnyCancellable?
    
    private lazy var scene: SCNScene = {
        let scene = SCNScene()
        scene.rootNode.addChildNode(self.globeNode)
        scene.rootNode.addChildNode(self.issNode)
        return scene
    }()
    
    private lazy var globeNode = self.createGlobeNode()
    private lazy var issNode = self.createIssNode()
    
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return URLSession(configuration: config)
    }()
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        self.createTimer()
        self.retrieveIssPosition()
        
        self.sceneView.scene = self.scene
        
        self.crownSequencer.delegate = self
        self.crownSequencer.focus()
    }
    
    @IBAction func panGesture(_ sender: Any) {
        let rootNode = self.scene.rootNode
        
        let gestureRecognizer = sender as! WKPanGestureRecognizer
        let translation = gestureRecognizer.translationInObject()
        let x = translation.x
        let y = -translation.y
        let anglePan = sqrt(pow(x, 2) + pow(y, 2)) * .pi / 180
        let rotationVector = SCNVector4(-y, x, 0, anglePan)
        rootNode.rotation = rotationVector
        
        if gestureRecognizer.state == .ended {
            let currentPivot = rootNode.pivot
            let currentPosition = rootNode.position
            let changePivot = SCNMatrix4Invert(SCNMatrix4MakeRotation(rootNode.rotation.w,
                                                                      rootNode.rotation.x,
                                                                      rootNode.rotation.y,
                                                                      rootNode.rotation.z))
            rootNode.pivot = SCNMatrix4Mult(changePivot, currentPivot)
            rootNode.transform = SCNMatrix4Identity
            rootNode.position = currentPosition
        }
    }
    
    func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
        self.scene.rootNode.runAction(.moveBy(x: 0, y: 0, z: CGFloat(rotationalDelta), duration: 0))
    }
    
    private func createTimer() {
        self.timerCancellable = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [unowned self] _ in
                self.retrieveIssPosition()
        }
    }
    
    private func retrieveIssPosition() {
        self.issPositionSessionCancellable?.cancel()
        self.issPositionSessionCancellable = self.session
            .dataTaskPublisher(for: URL(string: "http://api.open-notify.org/iss-now.json")!)
            .map { $0.data }
            .decode(type: PositionResponse.self, decoder: self.decoder)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [unowned self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.presentAlert(withTitle: "Could not retrieve ISS positon",
                                      message: error.localizedDescription,
                                      preferredStyle: .alert,
                                      actions: [WKAlertAction(title: "OK", style: .default, handler: {})])
                }
                }, receiveValue: { [unowned self] positionResponse in
                    guard let lat = Float(positionResponse.issPosition.latitude),
                        let lng = Float(positionResponse.issPosition.longitude) else {
                            assertionFailure("Invalid coordinates")
                            return
                    }
                    
                    let latRadians = lat * .pi / 180
                    let lngRadians = lng * .pi / 180
                    self.issNode.position = SCNVector3(0.25 * cos(latRadians) * cos(lngRadians),
                                                       0.25 * cos(latRadians) * sin(lngRadians),
                                                       0.25 * sin(latRadians))
            })
    }
    
    private func createGlobeNode() -> SCNNode {
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "snapshot-2020-05-1")
        
        let sphere = SCNSphere(radius: 0.2)
        sphere.firstMaterial = material
        
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = SCNVector3(0, 0, 0)
        sphereNode.eulerAngles = SCNVector3Make(.pi / 2, 0, .pi / 2)
        
        return sphereNode
    }
    
    private func createIssNode() -> SCNNode {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.purple
        
        let sphere = SCNSphere(radius: 0.02)
        sphere.firstMaterial = material
        
        return SCNNode(geometry: sphere)
    }
    
}
