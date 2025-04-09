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
        outputStride: Int
    ) -> Pose? {
        var joints = [Joint.Name: Joint]()

        for jointIndex in 0..<Joint.numberOfJoints {
            // Get the most confident cell for this joint
            let (maxRow, maxCol, confidence) = heatmap.maxLocation(for: jointIndex)

            // Create a PoseNet output cell
            let cell = PoseNetOutput.Cell(maxRow, maxCol)

            // Get the refined joint position using offsets
            let jointName = Joint.Name.allCases[jointIndex]
            let position = CGPoint(
                x: CGFloat(maxCol * outputStride) + CGFloat(offsets[jointIndex + Joint.numberOfJoints, maxRow, maxCol]),
                y: CGFloat(maxRow * outputStride) + CGFloat(offsets[jointIndex, maxRow, maxCol])
            )

            let joint = Joint(name: jointName, position: position, confidence: confidence)
            joints[jointName] = joint
        }

        return Pose(joints: joints)
    }
}
