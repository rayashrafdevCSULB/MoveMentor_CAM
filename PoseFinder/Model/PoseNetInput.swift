/*
 PoseNetInput.swift
 
 This file defines the PoseNetInput class, which serves as a CoreML feature provider for the PoseNet model.
 It processes input images by resizing and formatting them to meet the model's expected input requirements.
 The class ensures that the image is properly scaled before passing it to PoseNet for inference.
*/

import CoreML
import Vision

/// A CoreML feature provider that prepares images for PoseNet inference.
/// - Tag: PoseNetInput
class PoseNetInput: MLFeatureProvider {
    /// The name of the PoseNet model's expected input feature.
    ///
    /// This corresponds to the input layer name in `PoseNetMobileNet075S16FP16.mlmodel`.
    private static let imageFeatureName = "image"

    /// The original image provided as input to the model.
    var imageFeature: CGImage

    /// The expected size of the image input to the model.
    ///
    /// This class resizes the image accordingly before passing it to the model.
    let imageFeatureSize: CGSize

    /// Defines the available feature names that this provider can supply.
    var featureNames: Set<String> {
        return [PoseNetInput.imageFeatureName]
    }

    /// Initializes a new PoseNetInput with a given image and target size.
    /// - Parameters:
    ///   - image: The input CGImage to be processed.
    ///   - size: The target size to which the image should be resized.
    init(image: CGImage, size: CGSize) {
        imageFeature = image
        imageFeatureSize = size
    }

    /// Provides the MLFeatureValue for a given feature name.
    /// - Parameter featureName: The requested feature name.
    /// - Returns: An MLFeatureValue containing the processed image, or nil if the feature name is incorrect.
    func featureValue(for featureName: String) -> MLFeatureValue? {
        guard featureName == PoseNetInput.imageFeatureName else {
            return nil
        }

        let options: [MLFeatureValue.ImageOption: Any] = [
            .cropAndScale: VNImageCropAndScaleOption.scaleFill.rawValue
        ]

        return try? MLFeatureValue(cgImage: imageFeature,
                                   pixelsWide: Int(imageFeatureSize.width),
                                   pixelsHigh: Int(imageFeatureSize.height),
                                   pixelFormatType: imageFeature.pixelFormatInfo.rawValue,
                                   options: options)
    }
}
