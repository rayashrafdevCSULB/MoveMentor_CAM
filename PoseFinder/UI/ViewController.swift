/*
 ViewController.swift

 This file implements the main view controller responsible for coordinating the user interface,
 handling the video feed, and processing PoseNet model predictions.
 It manages camera input, runs pose detection, and updates the UI with detected poses.
*/

import UIKit
import AVFoundation

class ViewController: UIViewController {

    // UI to draw pose
    var poseImageView: PoseImageView!

    // CoreML Model & Logic
    let poseNet = PoseNet()
    let poseBuilder = PoseBuilder()

    // Camera Feed
    let videoCapture = VideoCapture()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCamera()
        setupPoseImageView()
    }

    private func setupCamera() {
        videoCapture.delegate = self
        videoCapture.setUp(sessionPreset: .high) { success in
            if success {
                self.videoCapture.start()
            }
        }
    }

    private func setupPoseImageView() {
        poseImageView = PoseImageView()
        poseImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(poseImageView)

        NSLayoutConstraint.activate([
            poseImageView.topAnchor.constraint(equalTo: view.topAnchor),
            poseImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            poseImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            poseImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

extension ViewController: VideoCaptureDelegate {
    func videoCapture(_ videoCapture: VideoCapture, didCapturePixelBuffer pixelBuffer: CVPixelBuffer?) {
        guard let pixelBuffer = pixelBuffer else { return }

        poseNet.predict(pixelBuffer: pixelBuffer) { result in
            guard let result = result else { return }

            let pose = self.poseBuilder.estimatePose(
                from: result.heatmap,
                offsets: result.offsets,
                displacementsFwd: result.displacementsFwd,
                displacementsBwd: result.displacementsBwd,
                outputStride: result.modelOutputStride
            )

            if let pose = pose,
               let cgImage = pixelBuffer.toCGImage() {
                DispatchQueue.main.async {
                    self.poseImageView.show(pose: pose, on: cgImage)
                }
            }
        }
    }
}
