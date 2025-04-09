/*
 Joint.swift
 
 This file defines the Joint class, which represents a single body joint detected by PoseNet.
 Each joint has a name, position, confidence score, and validity flag.
 The class also includes a mapping from output grid coordinates to the original image space.
*/

import CoreGraphics

struct Joint {
    enum Name: String, CaseIterable {
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

    let name: Name
    let position: CGPoint
    let confidence: Float

    var isValid: Bool {
        return confidence > 0.1
    }
}

// MARK: - Helper for PoseBuilder: Convert Joint.Name to Index
extension Joint.Name {
    var index: Int {
        switch self {
        case .nose: return 0
        case .leftEye: return 1
        case .rightEye: return 2
        case .leftEar: return 3
        case .rightEar: return 4
        case .leftShoulder: return 5
        case .rightShoulder: return 6
        case .leftElbow: return 7
        case .rightElbow: return 8
        case .leftWrist: return 9
        case .rightWrist: return 10
        case .leftHip: return 11
        case .rightHip: return 12
        case .leftKnee: return 13
        case .rightKnee: return 14
        case .leftAnkle: return 15
        case .rightAnkle: return 16
        }
    }
}
extension Joint {
    static var numberOfJoints: Int {
        return Joint.Name.allCases.count
    }
}
