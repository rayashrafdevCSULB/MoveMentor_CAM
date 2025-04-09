/*
 PoseNetOutput.swift
 
 This file defines the PoseNetOutput structure, which stores and processes the output of the PoseNet model.
 It contains heatmaps, offsets, and displacement maps necessary for determining joint positions in human pose estimation.
 The class provides utility methods to extract confidence scores, joint positions, and displacement vectors.
*/

import CoreML
import Vision

/// A structure that holds the PoseNet model's output values.
/// - Tag: PoseNetOutput
struct PoseNetOutput {
    /// Enum representing the different feature outputs of PoseNet.
    enum Feature: String {
        case heatmap = "heatmap"
        case offsets = "offsets"
        case backwardDisplacementMap = "displacementBwd"
        case forwardDisplacementMap = "displacementFwd"
    }

    /// Represents a grid cell coordinate in the PoseNet output.
    struct Cell {
        let yIndex: Int
        let xIndex: Int

        init(_ yIndex: Int, _ xIndex: Int) {
            self.yIndex = yIndex
            self.xIndex = xIndex
        }

        /// A zero-value cell reference.
        static var zero: Cell {
            return Cell(0, 0)
        }
    }

    /// Heatmap containing confidence scores for detected joints.
    let heatmap: MLMultiArray
    /// Offset values that refine joint positions within the output grid.
    let offsets: MLMultiArray
    /// Displacement map for tracking joint relationships backward (parent to child).
    let backwardDisplacementMap: MLMultiArray
    /// Displacement map for tracking joint relationships forward (child to parent).
    let forwardDisplacementMap: MLMultiArray
    /// The input image size used by the PoseNet model.
    let modelInputSize: CGSize
    /// The output stride defining the resolution of the PoseNet output grid.
    let modelOutputStride: Int

    /// Returns the height of the heatmap grid.
    var height: Int {
        return heatmap.shape[1].intValue
    }

    /// Returns the width of the heatmap grid.
    var width: Int {
        return heatmap.shape[2].intValue
    }

    /// Initializes PoseNetOutput with extracted prediction values.
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
    /// Computes the precise joint position based on the model’s output.
    func position(for jointName: Joint.Name, at cell: Cell) -> CGPoint {
        let jointOffset = offset(for: jointName, at: cell)
        var jointPosition = CGPoint(x: cell.xIndex * modelOutputStride, y: cell.yIndex * modelOutputStride)
        jointPosition += jointOffset
        return jointPosition
    }

    /// Maps a CGPoint position to the closest grid cell.
    func cell(for position: CGPoint) -> Cell? {
        let yIndex = Int((position.y / CGFloat(modelOutputStride)).rounded())
        let xIndex = Int((position.x / CGFloat(modelOutputStride)).rounded())
        guard yIndex >= 0 && yIndex < height && xIndex >= 0 && xIndex < width else {
            return nil
        }
        return Cell(yIndex, xIndex)
    }

    /// Retrieves the offset for a joint at a specific grid cell.
    func offset(for jointName: Joint.Name, at cell: Cell) -> CGVector {
        let yOffsetIndex: [Int] = [jointName.index, cell.yIndex, cell.xIndex]
        let xOffsetIndex: [Int] = [jointName.index + Joint.numberOfJoints, cell.yIndex, cell.xIndex]
        let offsetY: Double = offsets[yOffsetIndex].doubleValue
        let offsetX: Double = offsets[xOffsetIndex].doubleValue
        return CGVector(dx: CGFloat(offsetX), dy: CGFloat(offsetY))
    }

    /// Returns the confidence score for a joint at a specified cell.
    func confidence(for jointName: Joint.Name, at cell: Cell) -> Double {
        let multiArrayIndex: [Int] = [jointName.rawValue, cell.yIndex, cell.xIndex]
        return heatmap[multiArrayIndex].doubleValue
    }

    /// Retrieves the forward displacement vector for an edge at a specific grid cell.
    func forwardDisplacement(for edgeIndex: Int, at cell: Cell) -> CGVector {
        let yEdgeIndex = [edgeIndex, cell.yIndex, cell.xIndex]
        let xEdgeIndex = [edgeIndex + Pose.edges.count, cell.yIndex, cell.xIndex]
        let displacementY = forwardDisplacementMap[yEdgeIndex].doubleValue
        let displacementX = forwardDisplacementMap[xEdgeIndex].doubleValue
        return CGVector(dx: displacementX, dy: displacementY)
    }

    /// Retrieves the backward displacement vector for an edge at a specific grid cell.
    func backwardDisplacement(for edgeIndex: Int, at cell: Cell) -> CGVector {
        let yEdgeIndex = [edgeIndex, cell.yIndex, cell.xIndex]
        let xEdgeIndex = [edgeIndex + Pose.edges.count, cell.yIndex, cell.xIndex]
        let displacementY = backwardDisplacementMap[yEdgeIndex].doubleValue
        let displacementX = backwardDisplacementMap[xEdgeIndex].doubleValue
        return CGVector(dx: displacementX, dy: displacementY)
    }
}

// MARK: - MLFeatureProvider extension
extension MLFeatureProvider {
    /// Retrieves an MLMultiArray value for a given feature.
    func multiArrayValue(for feature: PoseNetOutput.Feature) -> MLMultiArray? {
        return featureValue(for: feature.rawValue)?.multiArrayValue
    }
}

// MARK: - MLMultiArray extension
extension MLMultiArray {
    /// Provides subscript access to elements using an integer array.
    subscript(index: [Int]) -> NSNumber {
        return self[index.map { NSNumber(value: $0) } ]
    }
}
