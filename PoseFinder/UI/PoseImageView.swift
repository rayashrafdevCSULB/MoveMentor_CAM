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
                let leftShoulder = pose[.leftShoulder]
                let leftElbow = pose[.leftElbow]
                let leftWrist = pose[.leftWrist]

                let rightShoulder = pose[.rightShoulder]
                let rightElbow = pose[.rightElbow]
                let rightWrist = pose[.rightWrist]

                var curledArmSegments: Set<JointSegment> = []

                // LEFT ARM
                if leftShoulder.isValid && leftElbow.isValid && leftWrist.isValid {
                    let leftAngle = angleBetween(
                        jointA: leftShoulder.position,
                        jointB: leftElbow.position,
                        jointC: leftWrist.position
                    )

                    if leftAngle < 90 {
                        curledArmSegments.insert(JointSegment(jointA: .leftShoulder, jointB: .leftElbow))
                        curledArmSegments.insert(JointSegment(jointA: .leftElbow, jointB: .leftWrist))
                    }
                }

                // RIGHT ARM
                if rightShoulder.isValid && rightElbow.isValid && rightWrist.isValid {
                    let rightAngle = angleBetween(
                        jointA: rightShoulder.position,
                        jointB: rightElbow.position,
                        jointC: rightWrist.position
                    )

                    if rightAngle < 90 {
                        curledArmSegments.insert(JointSegment(jointA: .rightShoulder, jointB: .rightElbow))
                        curledArmSegments.insert(JointSegment(jointA: .rightElbow, jointB: .rightWrist))
                    }
                }

                // Draw the res of the edges
                for segment in PoseImageView.jointSegments {
                    let jointA = pose[segment.jointA]
                    let jointB = pose[segment.jointB]

                    guard jointA.isValid, jointB.isValid else { continue }

                    let isCurled = curledArmSegments.contains(segment) // ✅ Check for highlighted segments
                    drawLine(from: jointA, to: jointB, in: rendererContext.cgContext, highlight: isCurled)
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

    func drawLine(from parentJoint: Joint, to childJoint: Joint, in cgContext: CGContext, highlight: Bool = false) {
        guard let image = self.image?.cgImage else { return }

        let imageWidth = CGFloat(image.width)
        let imageHeight = CGFloat(image.height)

        let start = CGPoint(x: parentJoint.position.x * imageWidth, y: parentJoint.position.y * imageHeight)
        let end = CGPoint(x: childJoint.position.x * imageWidth, y: childJoint.position.y * imageHeight)

        cgContext.setStrokeColor((highlight ? UIColor.red : segmentColor).cgColor)
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
    guard let image = self.image?.cgImage else { return }

    let imageWidth = CGFloat(image.width)
    let imageHeight = CGFloat(image.height)

    // Convert normalized joint position to pixel coordinates
    let x = joint.position.x * imageWidth
    let y = joint.position.y * imageHeight

    let text = joint.name.rawValue.uppercased()
    let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 30),
        .foregroundColor: UIColor.yellow,
        .backgroundColor: UIColor.black.withAlphaComponent(0.6)
    ]

    let textSize = text.size(withAttributes: attributes)
    let textOrigin = CGPoint(
        x: x - textSize.width / 2,
        y: y - jointRadius - textSize.height - 4
    )

    text.draw(at: textOrigin, withAttributes: attributes)

    // Optional debug dot
    let debugRect = CGRect(x: x - 2, y: y - 2, width: 4, height: 4)
    cgContext.setFillColor(UIColor.red.cgColor)
    cgContext.fill(debugRect)
}
    //MARK: Compute Elbow Angle (Remove)
    private func angleBetween(jointA: CGPoint, jointB: CGPoint, jointC: CGPoint) -> CGFloat {
    // Angle at jointB between A and C
    let ab = CGVector(dx: jointA.x - jointB.x, dy: jointA.y - jointB.y)
    let cb = CGVector(dx: jointC.x - jointB.x, dy: jointC.y - jointB.y)

    let dot = ab.dx * cb.dx + ab.dy * cb.dy
    let magAB = sqrt(ab.dx * ab.dx + ab.dy * ab.dy)
    let magCB = sqrt(cb.dx * cb.dx + cb.dy * cb.dy)

    guard magAB > 0 && magCB > 0 else { return 0 }

    let cosineAngle = dot / (magAB * magCB)
    return acos(cosineAngle) * 180 / .pi  // Convert to degrees
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
