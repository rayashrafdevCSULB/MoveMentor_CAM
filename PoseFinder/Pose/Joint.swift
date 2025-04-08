/*
 Joint.swift
 
 This file defines the Joint class, which represents a single body joint detected by PoseNet.
 Each joint has a name, position, confidence score, and validity flag.
 The class also includes a mapping from output grid coordinates to the original image space.
*/

import CoreGraphics

/// Represents a detected body joint in PoseNet.
class Joint {
    /// Enum representing all possible body joints PoseNet can detect.
    enum Name: Int, CaseIterable {
        case nose
        case leftEye
        case rightEye
        case leftEar
        case rightEar
        case leftShoulder
        case rightShoulder
        case leftElbow
        case rightElbow
        case leftWrist
        case rightWrist
        case leftHip
        case rightHip
        case leftKnee
        case rightKnee
        case leftAnkle
        case rightAnkle
    }

    /// The total number of joints defined in the model.
    static var numberOfJoints: Int {
        return Name.allCases.count
    }
    

    /// The unique identifier for the joint.
    let name: Name

    /// The position of the joint in image space.
    /// Initially relative to the model’s input size and later mapped to the original image.
    var position: CGPoint
    

    /// The joint’s location in the PoseNet model’s output grid.
    var cell: PoseNetOutput.Cell

    /// Confidence score indicating the model’s certainty of joint detection.
    var confidence: Double

    /// Indicates whether the joint meets the confidence threshold.
    var isValid: Bool

    var previousPosition: CGPoint?
    
    func motionMagnitude() -> CGFloat {
        guard let prev = previousPosition else { return 0 }
        return hypot(position.x - prev.x, position.y - prev.y)
}    /// Initializes a new joint with the provided properties.
    /// - Parameters:
    ///   - name: The joint’s name.
    ///   - cell: The corresponding cell location in the output grid.
    ///   - position: The joint’s position in image space.
    ///   - confidence: The confidence score of the detection.
    ///   - isValid: Whether the joint is valid based on confidence thresholds.
    init(name: Name,
         cell: PoseNetOutput.Cell = .zero,
         position: CGPoint = .zero,
         confidence: Double = 0,
         isValid: Bool = false) {
        self.name = name
        self.cell = cell
        self.position = position
        self.confidence = confidence
        self.isValid = isValid
    }
}
