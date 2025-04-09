/*
 PoseBuilder.swift

 This file implements logic for estimating a human pose from PoseNet output.
*/

import CoreGraphics
import CoreML

class PoseBuilder {

    /// Estimates a single pose from the provided model output.
    func estimatePose(
        from heatmap: MLMultiArray,
        offsets: MLMultiArray,
        displacementsFwd: MLMultiArray,
        displacementsBwd: MLMultiArray,
        outputStride: Int,
        modelInputSize: CGSize
) -> Pose? {
    var joints = [Joint.Name: Joint]()

    for jointIndex in 0..<Joint.numberOfJoints {
        let (maxRow, maxCol, confidence) = heatmap.maxLocation(for: jointIndex)
        let cell = PoseNetOutput.Cell(maxRow, maxCol)

        let offsetX = CGFloat(offsets[jointIndex + Joint.numberOfJoints, maxRow, maxCol])
        let offsetY = CGFloat(offsets[jointIndex, maxRow, maxCol])

        let x = CGFloat(maxCol * outputStride) + offsetX
        let y = CGFloat(maxRow * outputStride) + offsetY

        // Normalize to [0, 1] for PoseImageView scaling
        let normalizedX = x / modelInputSize.width
        let normalizedY = y / modelInputSize.height

        let position = CGPoint(x: normalizedX, y: normalizedY)
        let jointName = Joint.Name.allCases[jointIndex]
        let joint = Joint(name: jointName, position: position, confidence: confidence)

        joints[jointName] = joint
    }

    return Pose(joints: joints)
}

}
