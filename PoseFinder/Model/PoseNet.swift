/*
 PoseNet.swift
 
 This file contains the implementation of a facade for interacting with the PoseNet model.
 The class handles input preprocessing, model inference, and delegates the output results.
 PoseNet is a deep learning model used for real-time human pose estimation.
 It predicts keypoints of the human body from an image using CoreML and Vision.
*/


import CoreML
import Vision
import CoreGraphics

/// Protocol for PoseNet delegate to handle predictions.
protocol PoseNetDelegate: AnyObject {
    func poseNet(_ poseNet: PoseNet, didPredict predictions: PoseNetOutput)
}

class PoseNet {
    weak var delegate: PoseNetDelegate?

    let modelInputSize = CGSize(width: 513, height: 513)
    let outputStride = 16
    private let poseNetMLModel: MLModel

    init() throws {
        poseNetMLModel = try PoseNetMobileNet075S16FP16(configuration: .init()).model
    }

    func predict(_ image: CGImage) {
        DispatchQueue.global(qos: .userInitiated).async {
            let input = PoseNetInput(image: image, size: self.modelInputSize)

            guard let prediction = try? self.poseNetMLModel.prediction(from: input) else {
                return
            }

            let output = PoseNetOutput(
                prediction: prediction,
                modelInputSize: self.modelInputSize,
                modelOutputStride: self.outputStride
            )

            DispatchQueue.main.async {
                self.delegate?.poseNet(self, didPredict: output) // ✅ fixed: use correct variable
            }
        }
    }
}
