import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

  @IBOutlet var sceneView: ARSCNView!
  var applyGrayscale = false

  override func viewDidLoad() {
    super.viewDidLoad()
    sceneView.delegate = self
    sceneView.session.delegate = self
    sceneView.scene.rootNode.isHidden = true
    sceneView.insetsLayoutMarginsFromSafeArea = false

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
    sceneView.addGestureRecognizer(tapGesture)
  }

  func session(_ session: ARSession, didUpdate frame: ARFrame) {
    if !applyGrayscale {
      return
    }

    // https://stackoverflow.com/a/50037055/61811
    // Convert to black and white
    guard let currentBackgroundFrameImage = sceneView.session.currentFrame?.capturedImage,
          let pixelBufferAddressOfPlane = CVPixelBufferGetBaseAddressOfPlane(currentBackgroundFrameImage, 1) else { return }

    let x: size_t = CVPixelBufferGetWidthOfPlane(currentBackgroundFrameImage, 1)
    let y: size_t = CVPixelBufferGetHeightOfPlane(currentBackgroundFrameImage, 1)
    memset(pixelBufferAddressOfPlane, 128, Int(x * y) * 2)
   }

  @objc func onTap(_ recognizer: UITapGestureRecognizer) {
    applyGrayscale = !applyGrayscale
    sceneView.scene.rootNode.isHidden = !applyGrayscale
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    let configuration = ARWorldTrackingConfiguration()
    configuration.detectionImages = ARReferenceImage.referenceImages(inGroupNamed: "AR", bundle: nil)
    configuration.maximumNumberOfTrackedImages = 2
    sceneView.session.run(configuration)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    sceneView.session.pause()
  }

  func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    guard let imageAnchor = anchor as? ARImageAnchor else { return }

    let material = SCNMaterial()
    switch imageAnchor.referenceImage.name {
    case "amazon-book":
      material.diffuse.contents = UIImage(named: "consume")
    case "apple-tv-screen":
      material.diffuse.contents = UIImage(named: "watch-tv")
    default:
      fatalError("Unknown reference image")
      break
    }

    let size = imageAnchor.referenceImage.physicalSize
    let plane = SCNPlane(width: size.width, height: size.height)
    let planeNode = SCNNode(geometry: plane)
    plane.materials = [material]
    planeNode.simdOrientation = simd_quatf(angle: -.pi/2, axis: [1,0,0])
    node.addChildNode(planeNode)
  }
}
