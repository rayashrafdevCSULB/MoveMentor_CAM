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
    /// Called when the PoseNet model generates predictions.
    /// - Parameters:
    ///   - poseNet: The instance of PoseNet performing the inference.
    ///   - predictions: The output containing detected keypoints.
    func poseNet(_ poseNet: PoseNet, didPredict predictions: PoseNetOutput)
}

class PoseNet {
    /// Delegate to receive the PoseNet model's output.
    weak var delegate: PoseNetDelegate?

    /// The fixed input size of the PoseNet model.
    /// PoseNet supports input sizes of 257x257, 353x353, and 513x513 pixels.
    /// Larger sizes get better accuracy but require more computational resources.
    let modelInputSize = CGSize(width: 513, height: 513)

    /// The output stride determines the granularity of the output keypoints.
    /// Strides of 16 or 8 are valid, with smaller strides yielding more detailed results
    /// but increasing computational cost.
    let outputStride = 16

    /// The Core ML model instance used for pose estimation.
    private let poseNetMLModel: MLModel

    /// Initializes the PoseNet model with the default MobileNet variant.
    /// - Throws: An error if the model fails to load.
    init() throws {
        poseNetMLModel = try PoseNetMobileNet075S16FP16(configuration: .init()).model
    }

    /// Performs pose estimation on the given image.
    /// - Parameter image: The input CGImage to process.
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
            self.delegate?.poseNet(self, didPredict: poseNetOutput)
        }
    }
}

}