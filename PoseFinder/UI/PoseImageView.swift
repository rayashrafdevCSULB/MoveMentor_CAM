/*
 See the LICENSE.txt file for this sample’s licensing information.

 Abstract:
 Implementation details of a view that visualizes the detected poses.
*/

import UIKit

@IBDesignable
class PoseImageView: UIImageView {

    struct JointSegment {
        let jointA: Joint.Name
        let jointB: Joint.Name
    }

    static let jointSegments = [
        // Left side
        JointSegment(jointA: .leftHip, jointB: .leftShoulder),
        JointSegment(jointA: .leftShoulder, jointB: .leftElbow),
        JointSegment(jointA: .leftElbow, jointB: .leftWrist),
        JointSegment(jointA: .leftHip, jointB: .leftKnee),
        JointSegment(jointA: .leftKnee, jointB: .leftAnkle),
        // Right side
        JointSegment(jointA: .rightHip, jointB: .rightShoulder),
        JointSegment(jointA: .rightShoulder, jointB: .rightElbow),
        JointSegment(jointA: .rightElbow, jointB: .rightWrist),
        JointSegment(jointA: .rightHip, jointB: .rightKnee),
        JointSegment(jointA: .rightKnee, jointB: .rightAnkle),
        // Across the body
        JointSegment(jointA: .leftShoulder, jointB: .rightShoulder),
        JointSegment(jointA: .leftHip, jointB: .rightHip)
    ]

    @IBInspectable var segmentLineWidth: CGFloat = 2
    @IBInspectable var segmentColor: UIColor = UIColor.systemTeal
    @IBInspectable var jointRadius: CGFloat = 4
    @IBInspectable var jointColor: UIColor = UIColor.systemPink

    var highlightedBodyPart: String?

    // MARK: - Main rendering method

    func show(poses: [Pose], on frame: CGImage) {
        let dstImageSize = CGSize(width: frame.width, height: frame.height)
        let dstImageFormat = UIGraphicsImageRendererFormat()
        dstImageFormat.scale = 1

        let renderer = UIGraphicsImageRenderer(size: dstImageSize, format: dstImageFormat)

        let dstImage = renderer.image { rendererContext in
            draw(image: frame, in: rendererContext.cgContext)

            for pose in poses {
                // Draw connections
                for segment in PoseImageView.jointSegments {
                    let jointA = pose[segment.jointA]
                    let jointB = pose[segment.jointB]

                    guard jointA.isValid, jointB.isValid else { continue }
                    drawLine(from: jointA, to: jointB, in: rendererContext.cgContext)
                }

                // Draw individual joints
                for joint in pose.joints.values.filter({ $0.isValid }) {
                    draw(circle: joint,
                         highlight: isJointInHighlightedPart(joint.name),
                         in: rendererContext.cgContext)
                }
            }
        }

        image = dstImage
    }

    // MARK: - Drawing Helpers

    func draw(image: CGImage, in cgContext: CGContext) {
        cgContext.saveGState()
        cgContext.scaleBy(x: 1.0, y: -1.0)
        let drawingRect = CGRect(x: 0, y: -image.height, width: image.width, height: image.height)
        cgContext.draw(image, in: drawingRect)
        cgContext.restoreGState()
    }

    func drawLine(from parentJoint: Joint, to childJoint: Joint, in cgContext: CGContext) {
        cgContext.setStrokeColor(segmentColor.cgColor)
        cgContext.setLineWidth(segmentLineWidth)
        cgContext.move(to: parentJoint.position)
        cgContext.addLine(to: childJoint.position)
        cgContext.strokePath()
    }

    private func draw(circle joint: Joint, highlight: Bool = false, in cgContext: CGContext) {
        let color = highlight ? UIColor.red.cgColor : jointColor.cgColor
        cgContext.setFillColor(color)

        let rectangle = CGRect(x: joint.position.x - jointRadius,
                               y: joint.position.y - jointRadius,
                               width: jointRadius * 2,
                               height: jointRadius * 2)
        cgContext.addEllipse(in: rectangle)
        cgContext.drawPath(using: .fill)
    }

    private func isJointInHighlightedPart(_ jointName: Joint.Name) -> Bool {
        guard let part = highlightedBodyPart else { return false }

        switch part {
        case "Left Arm": return Pose.leftArm.contains(jointName)
        case "Right Arm": return Pose.rightArm.contains(jointName)
        case "Left Leg": return Pose.leftLeg.contains(jointName)
        case "Right Leg": return Pose.rightLeg.contains(jointName)
        default: return false
        }
    }
}
