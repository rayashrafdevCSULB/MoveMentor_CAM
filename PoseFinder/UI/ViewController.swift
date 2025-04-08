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
    /// View used to visualize detected poses.
    @IBOutlet private var previewImageView: PoseImageView!

    private let videoCapture = VideoCapture()
    private var poseNet: PoseNet!

    /// The current frame being analyzed by PoseNet.
    private var currentFrame: CGImage?

    /// Algorithm used for extracting poses (single or multiple person detection).
    private var algorithm: Algorithm = .multiple

    /// Configuration settings for the pose builder.
    private var poseBuilderConfiguration = PoseBuilderConfiguration()

    private var popOverPresentationManager: PopOverPresentationManager?

    /// Label used to display which body part is moving
    private var movementLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Prevent screen from locking while the app is running.
        UIApplication.shared.isIdleTimerDisabled = true

        do {
            poseNet = try PoseNet()
        } catch {
            fatalError("Failed to load model. \(error.localizedDescription)")
        }

        poseNet.delegate = self
        setupAndBeginCapturingVideoFrames()

        // Setup movement label
        movementLabel = UILabel()
        movementLabel.frame = CGRect(x: 20, y: 60, width: 300, height: 40)
        movementLabel.textColor = .white
        movementLabel.font = UIFont.boldSystemFont(ofSize: 18)
        movementLabel.text = ""
        view.addSubview(movementLabel)
    }

    /// Sets up the camera and starts capturing video frames.
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
        // Reinitialize the camera when the device orientation changes.
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
        guard currentFrame == nil else {
            return
        }
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
        defer {
            self.currentFrame = nil
        }

        guard let currentFrame = currentFrame else {
            return
        }

        let poseBuilder = PoseBuilder(output: predictions,
                                      configuration: poseBuilderConfiguration,
                                      inputImage: currentFrame)

        let poses = algorithm == .single
            ? [poseBuilder.pose]
            : poseBuilder.poses

        // 🟢 Motion detection logic
        if let pose = poses.first {
            let motions: [(String, CGFloat)] = [
                ("Left Arm", pose.movement(for: Pose.leftArm)),
                ("Right Arm", pose.movement(for: Pose.rightArm)),
                ("Left Leg", pose.movement(for: Pose.leftLeg)),
                ("Right Leg", pose.movement(for: Pose.rightLeg))
            ]

            if let mostMoved = motions.max(by: { $0.1 < $1.1 }), mostMoved.1 > 10 {
                movementLabel.text = "\(mostMoved.0) is moving"
                previewImageView.highlightedBodyPart = mostMoved.0
            } else {
                movementLabel.text = ""
                previewImageView.highlightedBodyPart = nil
            }
        }

        previewImageView.show(poses: poses, on: currentFrame)
    }
}