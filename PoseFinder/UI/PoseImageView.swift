/*

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

                    drawLabel(for: joint, in: rendererContext.cgContext)
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
    guard let image = self.image?.cgImage else { return }

    let imageWidth = CGFloat(image.width)
    let imageHeight = CGFloat(image.height)

    let start = CGPoint(
        x: parentJoint.position.x * imageWidth,
        y: parentJoint.position.y * imageHeight
    )
    let end = CGPoint(
        x: childJoint.position.x * imageWidth,
        y: childJoint.position.y * imageHeight
    )

    cgContext.setStrokeColor(segmentColor.cgColor)
    cgContext.setLineWidth(segmentLineWidth)
    cgContext.move(to: start)
    cgContext.addLine(to: end)
    cgContext.strokePath()
}


    private func draw(circle joint: Joint, highlight: Bool = false, in cgContext: CGContext) {
    guard let image = self.image?.cgImage else { return }

    let imageWidth = CGFloat(image.width)
    let imageHeight = CGFloat(image.height)

    let position = CGPoint(
        x: joint.position.x * imageWidth,
        y: joint.position.y * imageHeight
    )

    let color = highlight ? UIColor.red.cgColor : jointColor.cgColor
    cgContext.setFillColor(color)

    let rectangle = CGRect(
        x: position.x - jointRadius,
        y: position.y - jointRadius,
        width: jointRadius * 2,
        height: jointRadius * 2
    )
    cgContext.addEllipse(in: rectangle)
    cgContext.drawPath(using: .fill)
}
    private func drawLabel(for joint: Joint, in cgContext: CGContext) {
        let text = joint.name.rawValue.uppercased()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 30),
            .foregroundColor: UIColor.yellow,
            .backgroundColor: UIColor.black.withAlphaComponent(0.6)
        ]

        let textSize = text.size(withAttributes: attributes)
        let textOrigin = CGPoint(
            x: joint.position.x - textSize.width / 2,
            y: joint.position.y - jointRadius - textSize.height - 2
        )

        text.draw(at: textOrigin, withAttributes: attributes)
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
