/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation details of a view that visualizes the detected poses.
*/

import UIKit

@IBDesignable
class PoseImageView: UIImageView {

    /// A data structure used to describe a visual connection between two joints.
    struct JointSegment {
        let jointA: Joint.Name
        let jointB: Joint.Name
    }

    /// An array of joint-pairs that define the lines of a pose's wireframe drawing.
    static let jointSegments = [
        // The connected joints that are on the left side of the body.
        JointSegment(jointA: .leftHip, jointB: .leftShoulder),
        JointSegment(jointA: .leftShoulder, jointB: .leftElbow),
        JointSegment(jointA: .leftElbow, jointB: .leftWrist),
        JointSegment(jointA: .leftHip, jointB: .leftKnee),
        JointSegment(jointA: .leftKnee, jointB: .leftAnkle),
        // The connected joints that are on the right side of the body.
        JointSegment(jointA: .rightHip, jointB: .rightShoulder),
        JointSegment(jointA: .rightShoulder, jointB: .rightElbow),
        JointSegment(jointA: .rightElbow, jointB: .rightWrist),
        JointSegment(jointA: .rightHip, jointB: .rightKnee),
        JointSegment(jointA: .rightKnee, jointB: .rightAnkle),
        // The connected joints that cross over the body.
        JointSegment(jointA: .leftShoulder, jointB: .rightShoulder),
        JointSegment(jointA: .leftHip, jointB: .rightHip)
    ]

    /// The width of the line connecting two joints.
    @IBInspectable var segmentLineWidth: CGFloat = 2
    /// The color of the line connecting two joints.
    @IBInspectable var segmentColor: UIColor = UIColor.systemTeal
    /// The radius of the circles drawn for each joint.
    @IBInspectable var jointRadius: CGFloat = 4
    /// The color of the circles drawn for each joint.
    @IBInspectable var jointColor: UIColor = UIColor.systemPink

    /// The body part to highlight (e.g., "Left Arm", "Right Leg")
    var highlightedBodyPart: String?

    // MARK: - Rendering methods

    /// Returns an image showing the detected poses.
    ///
    /// - parameters:
    ///     - poses: An array of detected poses.
    ///     - frame: The image used to detect the poses and used as the background for the returned image.
    func show(poses: [Pose], on frame: CGImage) {
        let dstImageSize = CGSize(width: frame.width, height: frame.height)
        let dstImageFormat = UIGraphicsImageRendererFormat()

        dstImageFormat.scale = 1
        let renderer = UIGraphicsImageRenderer(size: dstImageSize,
                                               format: dstImageFormat)

        let dstImage = renderer.image { rendererContext in
            // Draw the current frame as the background for the new image.
            draw(image: frame, in: rendererContext.cgContext)

            for pose in poses {
                // Draw the segment lines.
                for segment in PoseImageView.jointSegments {
                    let jointA = pose[segment.jointA]
                    let jointB = pose[segment.jointB]

                    guard jointA.isValid, jointB.isValid else {
                        continue
                    }

                    drawLine(from: jointA,
                             to: jointB,
                             in: rendererContext.cgContext)
                }

                // Draw the joints as circles above the segment lines.
                for joint in pose.joints.values.filter({ $0.isValid }) {
                    draw(circle: joint,
                         highlight: isJointInHighlightedPart(joint.name),
                         in: rendererContext.cgContext)
                }
            }
        }

        image = dstImage
    }

    /// Vertically flips and draws the given image.
    func draw(image: CGImage, in cgContext: CGContext) {
        cgContext.saveGState()
        cgContext.scaleBy(x: 1.0, y: -1.0)
        let drawingRect = CGRect(x: 0, y: -image.height, width: image.width, height: image.height)
        cgContext.draw(image, in: drawingRect)
        cgContext.restoreGState()
    }

    /// Draws a line between two joints.
    func drawLine(from parentJoint: Joint,
                  to childJoint: Joint,
                  in cgContext: CGContext) {
        cgContext.setStrokeColor(segmentColor.cgColor)
        cgContext.setLineWidth(segmentLineWidth)

        cgContext.move(to: parentJoint.position)
        cgContext.addLine(to: childJoint.position)
        cgContext.strokePath()
    }

    /// Draws a circle in the location of the given joint, with optional highlighting.
    private func draw(circle joint: Joint,
                      highlight: Bool = false,
                      in cgContext: CGContext) {
        let color = highlight ? UIColor.red.cgColor : jointColor.cgColor
        cgContext.setFillColor(color)

        let rectangle = CGRect(x: joint.position.x - jointRadius,
                               y: joint.position.y - jointRadius,
                               width: jointRadius * 2,
                               height: jointRadius * 2)
        cgContext.addEllipse(in: rectangle)
        cgContext.drawPath(using: .fill)
    }

    /// Returns true if the joint is in the currently highlighted body part.
    private func isJointInHighlightedPart(_ jointName: Joint.Name) -> Bool {
        guard let part = highlightedBodyPart else { return false }

        switch part {
        case "Left Arm":
            return Pose.leftArm.contains(jointName)
        case "Right Arm":
            return Pose.rightArm.contains(jointName)
        case "Left Leg":
            return Pose.leftLeg.contains(jointName)
        case "Right Leg":
            return Pose.rightLeg.contains(jointName)
        default:
            return false
        }
    }
}