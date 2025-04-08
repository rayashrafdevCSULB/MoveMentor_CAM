/*
 ViewController.swift

 This file implements the main view controller responsible for coordinating the user interface,
 handling the video feed, and processing PoseNet model predictions.
 It manages camera input, runs pose detection, and updates the UI with detected poses.
*/

import AVFoundation
import UIKit
import VideoToolbox

class ViewController: UIViewController {
    @IBOutlet private var previewImageView: PoseImageView!

    private let videoCapture = VideoCapture()
    private var poseNet: PoseNet!
    private var currentFrame: CGImage?
    private var algorithm: Algorithm = .multiple
    private var poseBuilderConfiguration = PoseBuilderConfiguration()
    private var popOverPresentationManager: PopOverPresentationManager?

    private var movementLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        UIApplication.shared.isIdleTimerDisabled = true

        do {
            poseNet = try PoseNet()
        } catch {
            fatalError("Failed to load model. \(error.localizedDescription)")
        }

        poseNet.delegate = self
        setupAndBeginCapturingVideoFrames()

        // Setup label
        movementLabel = UILabel()
        movementLabel.frame = CGRect(x: 20, y: 60, width: 300, height: 40)
        movementLabel.textColor = .white
        movementLabel.font = UIFont.boldSystemFont(ofSize: 18)
        movementLabel.text = ""
        view.addSubview(movementLabel)
    }

    private func setupAndBeginCapturingVideoFrames() {
        videoCapture.setUpAVCapture { error in
            if let error = error {
                print("Failed to setup camera with error \(error)")
                return
            }
            self.videoCapture.delegate = self
            self.videoCapture.startCapturing()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        videoCapture.stopCapturing {
            super.viewWillDisappear(animated)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        setupAndBeginCapturingVideoFrames()
    }
}

// MARK: - Navigation

extension ViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let uiNavigationController = segue.destination as? UINavigationController,
              let configurationViewController = uiNavigationController.viewControllers.first as? ConfigurationViewController else {
            return
        }

        configurationViewController.configuration = poseBuilderConfiguration
        configurationViewController.algorithm = algorithm
        configurationViewController.delegate = self

        popOverPresentationManager = PopOverPresentationManager(presenting: self, presented: uiNavigationController)
        segue.destination.modalPresentationStyle = .custom
        segue.destination.transitioningDelegate = popOverPresentationManager
    }
}

// MARK: - ConfigurationViewControllerDelegate

extension ViewController: ConfigurationViewControllerDelegate {
    func configurationViewController(_ viewController: ConfigurationViewController, didUpdateConfiguration configuration: PoseBuilderConfiguration) {
        poseBuilderConfiguration = configuration
    }

    func configurationViewController(_ viewController: ConfigurationViewController, didUpdateAlgorithm algorithm: Algorithm) {
        self.algorithm = algorithm
    }
}

// MARK: - VideoCaptureDelegate

extension ViewController: VideoCaptureDelegate {
    func videoCapture(_ videoCapture: VideoCapture, didCaptureFrame capturedImage: CGImage?) {
        guard currentFrame == nil else { return }
        guard let image = capturedImage else {
            fatalError("Captured image is null")
        }

        currentFrame = image
        poseNet.predict(image)
    }
}

// MARK: - PoseNetDelegate

extension ViewController: PoseNetDelegate {
    func poseNet(_ poseNet: PoseNet, didPredict predictions: PoseNetOutput) {
        defer { self.currentFrame = nil }

        guard let currentFrame = currentFrame else {
            return
        }

        let poseBuilder = PoseBuilder(output: predictions,
                                      configuration: poseBuilderConfiguration,
                                      inputImage: currentFrame)

        let poses = algorithm == .single
            ? [poseBuilder.pose]
            : poseBuilder.poses

        if let pose = poses.first {
            // Ensure at least some joints are visible (valid)
            let visibleJoints = pose.joints.values.filter { $0.isValid }
            guard !visibleJoints.isEmpty else {
                movementLabel.text = ""
                previewImageView.highlightedBodyPart = nil
                return
            }

            // Motion check
            let motions: [(String, CGFloat)] = [
                ("Left Arm", pose.movement(for: Pose.leftArm)),
                ("Right Arm", pose.movement(for: Pose.rightArm)),
                ("Left Leg", pose.movement(for: Pose.leftLeg)),
                ("Right Leg", pose.movement(for: Pose.rightLeg))
            ]

            // Only keep body parts with a decent number of visible joints
            let bodyPartsWithValidJoints = motions.filter { part in
                let jointGroup = Pose.jointGroup(for: part.0)
                let visibleCount = jointGroup.filter { pose[$0].isValid }.count
                return visibleCount >= 2
            }

            guard let mostMoved = bodyPartsWithValidJoints.max(by: { $0.1 < $1.1 }), mostMoved.1 > 5 else {
                movementLabel.text = ""
                previewImageView.highlightedBodyPart = nil
                return
            }

            movementLabel.text = "\(mostMoved.0) is moving"
            previewImageView.highlightedBodyPart = mostMoved.0
        }

        previewImageView.show(poses: poses, on: currentFrame)
    }
}