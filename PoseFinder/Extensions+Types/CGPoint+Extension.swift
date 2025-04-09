/*
Abstract:
The implementation details of some mathematical operations that extend the CGPoint structure.
*/

import CoreGraphics
import CoreML

// MARK: - MLMultiArray Extension

extension MLMultiArray {
    /// Finds the (row, col) of the highest confidence value for a given joint index.
    func maxLocation(for jointIndex: Int) -> (row: Int, col: Int, confidence: Float) {
        let height = self.shape[1].intValue
        let width = self.shape[2].intValue

        var maxConfidence: Float = 0
        var maxRow = 0
        var maxCol = 0

        for row in 0..<height {
            for col in 0..<width {
                let index = jointIndex * height * width + row * width + col
                let confidence = self[index].floatValue
                if confidence > maxConfidence {
                    maxConfidence = confidence
                    maxRow = row
                    maxCol = col
                }
            }
        }

        return (maxRow, maxCol, maxConfidence)
    }

    /// Simplified offset accessor for PoseBuilder
    subscript(_ offset: Int, _ row: Int, _ col: Int) -> Float {
        let width = self.shape[2].intValue
        let height = self.shape[1].intValue
        let index = offset * height * width + row * width + col
        return self[index].floatValue
    }
}

// MARK: - CGPoint Math Utilities

extension CGPoint {
    init(_ cell: PoseNetOutput.Cell) {
        self.init(x: CGFloat(cell.xIndex), y: CGFloat(cell.yIndex))
    }

    func squaredDistance(to other: CGPoint) -> CGFloat {
        let dx = other.x - x
        let dy = other.y - y
        return dx * dx + dy * dy
    }

    func distance(to other: CGPoint) -> Double {
        return Double(squaredDistance(to: other).squareRoot())
    }

    static func + (_ lhs: CGPoint, _ rhs: CGVector) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
    }

    static func += (lhs: inout CGPoint, _ rhs: CGVector) {
        lhs.x += rhs.dx
        lhs.y += rhs.dy
    }

    static func * (_ lhs: CGPoint, _ scale: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x * scale, y: lhs.y * scale)
    }

    static func * (_ lhs: CGPoint, _ rhs: CGSize) -> CGPoint {
        return CGPoint(x: lhs.x * rhs.width, y: lhs.y * rhs.height)
    }
}
