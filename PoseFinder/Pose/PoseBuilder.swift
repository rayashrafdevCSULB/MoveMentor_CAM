/*
 PoseBuilder.swift
 
 This file defines the PoseBuilder structure, responsible for analyzing PoseNet model outputs.
 It processes predictions to construct single or multiple poses, transforming detected joint positions
 from the model’s coordinate space back to the original image dimensions.
*/

import Foundation
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
        return decodeSinglePose(from: heatmap, offsets: offsets, outputStride: outputStride)
    }

    private func decodeSinglePose(
        from heatmap: MLMultiArray,
        offsets: MLMultiArray,
        outputStride: Int
    ) -> Pose? {
        var joints: [Joint.Name: Joint] = [:]

        for jointName in Joint.Name.allCases {
            let jointIndex = jointName.index
            let (row, col, confidence) = heatmap.maxLocation(for: jointIndex)

            let offsetX = offsets[offset: 0, row: row, col: col, channelStride: 2]
            let offsetY = offsets[offset: 1, row: row, col: col, channelStride: 2]

            let x = CGFloat(col * outputStride) + CGFloat(offsetX)
            let y = CGFloat(row * outputStride) + CGFloat(offsetY)

            let position = CGPoint(x: x, y: y)
            joints[jointName] = Joint(name: jointName, position: position, confidence: confidence)
        }

        return Pose(joints: joints)
    }
}
