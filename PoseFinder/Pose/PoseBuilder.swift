/*
 PoseBuilder.swift
 
 This file defines the PoseBuilder structure, responsible for analyzing PoseNet model outputs.
 It processes predictions to construct single or multiple poses, transforming detected joint positions
 from the model’s coordinate space back to the original image dimensions.
*/

iimport Foundation
import CoreGraphics
import CoreML

final class PoseBuilder {

    func estimatePose(
        from heatmap: MLMultiArray,
        offsets: MLMultiArray,
        displacementsFwd: MLMultiArray,
        displacementsBwd: MLMultiArray,
        outputStride: Int
    ) -> Pose? {
        
        // Decode pose (only one for now) using built-in logic or simplified from multi-pose
        // This is a placeholder. Your original multiple-pose logic likely called into PoseBuilder+Single
        guard let pose = decodeSinglePose(
            from: heatmap,
            offsets: offsets,
            outputStride: outputStride
        ) else {
            return nil
        }

        return pose
    }

    // MARK: - Pose Decoding (adapted from PoseBuilder+Single.swift)
    private func decodeSinglePose(
        from heatmap: MLMultiArray,
        offsets: MLMultiArray,
        outputStride: Int
    ) -> Pose? {
        var joints: [Joint.Name: Joint] = [:]

        for jointName in Joint.Name.allCases {
            let jointIndex = jointName.index
            let (maxRow, maxCol, maxConfidence) = heatmap.maxLocation(for: jointIndex)

            let offsetX = offsets[offset: 0, row: maxRow, col: maxCol, channelStride: 2]
            let offsetY = offsets[offset: 1, row: maxRow, col: maxCol, channelStride: 2]

            let x = CGFloat(maxCol * outputStride) + CGFloat(offsetX)
            let y = CGFloat(maxRow * outputStride) + CGFloat(offsetY)

            let position = CGPoint(x: x, y: y)
            joints[jointName] = Joint(name: jointName, position: position, confidence: maxConfidence)
        }

        return Pose(joints: joints)
    }
}
