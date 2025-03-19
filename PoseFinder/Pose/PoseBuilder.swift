/*
 PoseBuilder.swift
 
 This file defines the PoseBuilder structure, responsible for analyzing PoseNet model outputs.
 It processes predictions to construct single or multiple poses, transforming detected joint positions
 from the model’s coordinate space back to the original image dimensions.
*/

import CoreGraphics

/// Processes PoseNet model outputs to construct pose estimations.
struct PoseBuilder {
    /// The output predictions from the PoseNet model.
    /// These predictions are analyzed to extract joint positions and confidence scores.
    let output: PoseNetOutput

    /// A transformation matrix used to map detected joint positions
    /// from the model's input image space back to the original image size.
    let modelToInputTransformation: CGAffineTransform

    /// Configuration parameters used to fine-tune pose detection algorithms.
    var configuration: PoseBuilderConfiguration

    /// Initializes a PoseBuilder with the given model output, configuration, and input image.
    /// - Parameters:
    ///   - output: The output data from PoseNet.
    ///   - configuration: Parameters controlling pose detection thresholds.
    ///   - inputImage: The original image being processed.
    init(output: PoseNetOutput, configuration: PoseBuilderConfiguration, inputImage: CGImage) {
        self.output = output
        self.configuration = configuration

        // Create a transformation matrix to convert joint positions
        // from the model's input space back to the original input image size.
        modelToInputTransformation = CGAffineTransform(scaleX: inputImage.size.width / output.modelInputSize.width,
                                                       y: inputImage.size.height / output.modelInputSize.height)
    }
}
