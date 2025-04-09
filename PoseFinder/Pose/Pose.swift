/*
 Pose.swift
 
 This file defines the Pose structure, which represents a detected human pose.
 It consists of individual joints and their relationships (edges) to form a skeletal structure.
 The structure includes utility methods to access joint information and retrieve connections between joints.
*/

import CoreGraphics

struct Pose {
    let joints: [Joint.Name: Joint]

    subscript(_ jointName: Joint.Name) -> Joint {
        return joints[jointName] ?? Joint(
            name: jointName,
            position: CGPoint(x: 0, y: 0),
            confidence: 0
        )
    }

    // Group joints by body part for easy access (used by PoseImageView)
    static let leftArm: [Joint.Name] = [.leftShoulder, .leftElbow, .leftWrist]
    static let rightArm: [Joint.Name] = [.rightShoulder, .rightElbow, .rightWrist]
    static let leftLeg: [Joint.Name] = [.leftHip, .leftKnee, .leftAnkle]
    static let rightLeg: [Joint.Name] = [.rightHip, .rightKnee, .rightAnkle]

    static func jointGroup(for name: String) -> [Joint.Name] {
        switch name {
        case "Left Arm": return Pose.leftArm
        case "Right Arm": return Pose.rightArm
        case "Left Leg": return Pose.leftLeg
        case "Right Leg": return Pose.rightLeg
        default: return []
        }
    }

    // Optional: export joint data as matrix [x, y, confidence]
    func toMatrix() -> [[Float]] {
        return joints.values.map {
            [Float($0.position.x), Float($0.position.y), $0.confidence]
        }
    }
}
