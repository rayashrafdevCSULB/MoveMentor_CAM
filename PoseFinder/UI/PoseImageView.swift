/*
 PoseImageView.swift
 
 This file defines PoseImageView, a custom UIImageView subclass responsible for visualizing detected poses.
 It draws joints as circles and connects them with lines to form a skeletal representation of the detected body pose.
 The rendering methods overlay the pose information onto the given image frame.
*/

import UIKit

@IBDesignable
class PoseImageView: UIImageView {
    /// Defines a visual connection between two joints.
    struct JointSegment {
        let jointA: Joint.Name
        let jointB: Joint.Name
    }

    /// Defines joint connections for skeletal visualization.
    static let jointSegments = [
        // Left-side body connections.
        JointSegment(jointA: .leftHip, jointB: .leftShoulder),
        JointSegment(jointA: .leftShoulder, jointB: .leftElbow),
        JointSegment(jointA: .leftElbow, jointB: .leftWrist),
        JointSegment(jointA: .leftHip, jointB: .leftKnee),
        JointSegment(jointA: .leftKnee, jointB: .leftAnkle),
        // Right-side body connections.
        JointSegment(jointA: .rightHip, jointB: .rightShoulder),
        JointSegment(jointA: .rightShoulder, jointB: .rightElbow),
        JointSegment(jointA: .rightElbow, jointB: .rightWrist),
        JointSegment(jointA: .rightHip, jointB: .rightKnee),
        JointSegment(jointA: .rightKnee, jointB: .rightAnkle),
        // Cross-body connections.
        JointSegment(jointA: .leftShoulder, jointB: .rightShoulder),
        JointSegment(jointA: .leftHip, jointB: .rightHip)
    ]

    /// Line width for joint connections.
    @IBInspectable var segmentLineWidth: CGFloat = 2
    /// Color for joint connection lines.
    @IBInspectable var segmentColor: UIColor = UIColor.systemTeal
    /// Radius of joint circles.
    @IBInspectable var jointRadius: CGFloat = 4
    /// Color for joint circles.
    @IBInspectable var jointColor: UIColor = UIColor.systemPink

    // MARK: - Rendering methods

    /// Generates an image overlay showing detected poses.
    /// - Parameters:
    ///   - poses: Array of detected poses.
    ///   - frame: The image frame onto which poses are drawn.
    func show(poses: [Pose], on frame: CGImage) {
        let dstImageSize = CGSize(width: frame.width, height: frame.height)
        let dstImageFormat = UIGraphicsImageRendererFormat()
        dstImageFormat.scale = 1
        
        let renderer = UIGraphicsImageRenderer(size: dstImageSize, format: dstImageFormat)
        let dstImage = renderer.image { rendererContext in
            draw(image: frame, in: rendererContext.cgContext)
            
            for pose in poses {
                // Draw skeletal segments.
                for segment in PoseImageView.jointSegments {
                    let jointA = pose[segment.jointA]
                    let jointB = pose[segment.jointB]
                    guard jointA.isValid, jointB.isValid else { continue }
                    drawLine(from: jointA, to: jointB, in: rendererContext.cgContext)
                }
                
                // Draw joint circles.
                for joint in pose.joints.values.filter({ $0.isValid }) {
                    draw(circle: joint, in: rendererContext.cgContext)
                }
            }
        }
        image = dstImage
    }

    /// Flips and draws the given image onto the rendering context.
    /// - Parameters:
    ///   - image: The image to draw.
    ///   - cgContext: The rendering context.
    func draw(image: CGImage, in cgContext: CGContext) {
        cgContext.saveGState()
        cgContext.scaleBy(x: 1.0, y: -1.0)
        let drawingRect = CGRect(x: 0, y: -image.height, width: image.width, height: image.height)
        cgContext.draw(image, in: drawingRect)
        cgContext.restoreGState()
    }

    /// Draws a line between two joints.
    /// - Parameters:
    ///   - parentJoint: The starting joint.
    ///   - childJoint: The ending joint.
    ///   - cgContext: The rendering context.
    func drawLine(from parentJoint: Joint, to childJoint: Joint, in cgContext: CGContext) {
        cgContext.setStrokeColor(segmentColor.cgColor)
        cgContext.setLineWidth(segmentLineWidth)
        cgContext.move(to: parentJoint.position)
        cgContext.addLine(to: childJoint.position)
        cgContext.strokePath()
    }

    /// Draws a circular representation of a joint.
    /// - Parameters:
    ///   - joint: The joint to visualize.
    ///   - cgContext: The rendering context.
    private func draw(circle joint: Joint, in cgContext: CGContext) {
        cgContext.setFillColor(jointColor.cgColor)
        let rectangle = CGRect(x: joint.position.x - jointRadius, y: joint.position.y - jointRadius,
                               width: jointRadius * 2, height: jointRadius * 2)
        cgContext.addEllipse(in: rectangle)
        cgContext.drawPath(using: .fill)
    }
}
