/*
 PoseNetOutput.swift

 This file defines the PoseNetOutput structure, which stores and processes the output of the PoseNet model.
 It contains heatmaps, offsets, and displacement maps necessary for determining joint positions in human pose estimation.
 The class provides utility methods to extract confidence scores, joint positions, and displacement vectors.
*/

import CoreML
import Vision
import CoreGraphics

/// A structure that holds the PoseNet model's output values.
/// - Tag: PoseNetOutput
struct PoseNetOutput {
    enum Feature: String {
        case heatmap = "heatmap"
        case offsets = "offsets"
        case backwardDisplacementMap = "displacementBwd"
        case forwardDisplacementMap = "displacementFwd"
    }

    struct Cell {
        let yIndex: Int
        let xIndex: Int

        init(_ yIndex: Int, _ xIndex: Int) {
            self.yIndex = yIndex
            self.xIndex = xIndex
        }

        static var zero: Cell {
            return Cell(0, 0)
        }
    }

    let heatmap: MLMultiArray
    let offsets: MLMultiArray
    let backwardDisplacementMap: MLMultiArray
    let forwardDisplacementMap: MLMultiArray
    let modelInputSize: CGSize
    let modelOutputStride: Int

    var height: Int {
        return heatmap.shape[1].intValue
    }

    var width: Int {
        return heatmap.shape[2].intValue
    }

    init(prediction: MLFeatureProvider, modelInputSize: CGSize, modelOutputStride: Int) {
        guard let heatmap = prediction.multiArrayValue(for: .heatmap) else {
            fatalError("Failed to get the heatmap MLMultiArray")
        }
        guard let offsets = prediction.multiArrayValue(for: .offsets) else {
            fatalError("Failed to get the offsets MLMultiArray")
        }
        guard let backwardDisplacementMap = prediction.multiArrayValue(for: .backwardDisplacementMap) else {
            fatalError("Failed to get the backwardDisplacementMap MLMultiArray")
        }
        guard let forwardDisplacementMap = prediction.multiArrayValue(for: .forwardDisplacementMap) else {
            fatalError("Failed to get the forwardDisplacementMap MLMultiArray")
        }

        self.heatmap = heatmap
        self.offsets = offsets
        self.backwardDisplacementMap = backwardDisplacementMap
        self.forwardDisplacementMap = forwardDisplacementMap
        self.modelInputSize = modelInputSize
        self.modelOutputStride = modelOutputStride
    }
}

// MARK: - Utility and accessor methods

extension PoseNetOutput {
    func position(for jointName: Joint.Name, at cell: Cell) -> CGPoint {
        let jointOffset = offset(for: jointName, at: cell)
        var jointPosition = CGPoint(x: cell.xIndex * modelOutputStride, y: cell.yIndex * modelOutputStride)
        jointPosition += jointOffset
        return jointPosition
    }

    func cell(for position: CGPoint) -> Cell? {
        let yIndex = Int((position.y / CGFloat(modelOutputStride)).rounded())
        let xIndex = Int((position.x / CGFloat(modelOutputStride)).rounded())
        guard yIndex >= 0 && yIndex < height && xIndex >= 0 && xIndex < width else {
            return nil
        }
        return Cell(yIndex, xIndex)
    }

    func offset(for jointName: Joint.Name, at cell: Cell) -> CGVector {
        let yOffsetIndex: [Int] = [jointName.index, cell.yIndex, cell.xIndex]
        let xOffsetIndex: [Int] = [jointName.index + Joint.numberOfJoints, cell.yIndex, cell.xIndex]
        let offsetY: Double = offsets[yOffsetIndex].doubleValue
        let offsetX: Double = offsets[xOffsetIndex].doubleValue
        return CGVector(dx: CGFloat(offsetX), dy: CGFloat(offsetY))
    }

    func confidence(for jointName: Joint.Name, at cell: Cell) -> Double {
        let index: [Int] = [jointName.index, cell.yIndex, cell.xIndex]
        return heatmap[index].doubleValue
    }

    func forwardDisplacement(for edgeIndex: Int, at cell: Cell) -> CGVector {
        let yEdgeIndex: [Int] = [edgeIndex, cell.yIndex, cell.xIndex]
        let xEdgeIndex: [Int] = [edgeIndex + Pose.edges.count, cell.yIndex, cell.xIndex]
        let dy = forwardDisplacementMap[yEdgeIndex].doubleValue
        let dx = forwardDisplacementMap[xEdgeIndex].doubleValue
        return CGVector(dx: dx, dy: dy)
    }

    func backwardDisplacement(for edgeIndex: Int, at cell: Cell) -> CGVector {
        let yEdgeIndex: [Int] = [edgeIndex, cell.yIndex, cell.xIndex]
        let xEdgeIndex: [Int] = [edgeIndex + Pose.edges.count, cell.yIndex, cell.xIndex]
        let dy = backwardDisplacementMap[yEdgeIndex].doubleValue
        let dx = backwardDisplacementMap[xEdgeIndex].doubleValue
        return CGVector(dx: dx, dy: dy)
    }
}

// MARK: - MLFeatureProvider extension

extension MLFeatureProvider {
    func multiArrayValue(for feature: PoseNetOutput.Feature) -> MLMultiArray? {
        return featureValue(for: feature.rawValue)?.multiArrayValue
    }
}

// MARK: - MLMultiArray extension

extension MLMultiArray {
    subscript(index: [Int]) -> NSNumber {
        return self[index.map { NSNumber(value: $0) }]
    }
}
