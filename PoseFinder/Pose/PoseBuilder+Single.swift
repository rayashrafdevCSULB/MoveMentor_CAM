/*
 PoseBuilder+Single.swift
 
 This file defines an extension of PoseBuilder that implements a single-person pose estimation algorithm.
 The algorithm analyzes the PoseNet model output to determine the most likely joint positions for one individual.
 It selects the highest-confidence joint positions from the heatmap and maps them back onto the original image.
*/

import CoreGraphics

extension PoseBuilder {
    /// Constructs a single pose using the PoseNet model output.
    /// - Returns: A `Pose` object containing detected joints and their confidence scores.
    var pose: Pose {
        var pose = Pose()

        // Locate the most confident position for each joint.
        pose.joints.values.forEach { joint in
            configure(joint: joint)
        }

        // Compute the overall confidence of the pose.
        pose.confidence = pose.joints.values
            .map { $0.confidence }.reduce(0, +) / Double(Joint.numberOfJoints)

        // Transform joint positions back to the original image space.
        pose.joints.values.forEach { joint in
            joint.position = joint.position.applying(modelToInputTransformation)
        }

        return pose
    }

    /// Updates a joint's properties using the highest-confidence cell in the heatmap.
    /// - Parameter joint: The joint to configure.
    private func configure(joint: Joint) {
        var bestCell = PoseNetOutput.Cell(0, 0)
        var bestConfidence = 0.0

        // Scan the heatmap to find the cell with the highest confidence.
        for yIndex in 0..<output.height {
            for xIndex in 0..<output.width {
                let currentCell = PoseNetOutput.Cell(yIndex, xIndex)
                let currentConfidence = output.confidence(for: joint.name, at: currentCell)

                // Store the highest-confidence cell.
                if currentConfidence > bestConfidence {
                    bestConfidence = currentConfidence
                    bestCell = currentCell
                }
            }
        }

        // Update joint properties.
        joint.cell = bestCell
        joint.position = output.position(for: joint.name, at: joint.cell)
        joint.confidence = bestConfidence
        joint.isValid = joint.confidence >= configuration.jointConfidenceThreshold
    }
}
