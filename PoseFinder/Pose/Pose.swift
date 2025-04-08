/*
 Pose.swift
 
 This file defines the Pose structure, which represents a detected human pose.
 It consists of individual joints and their relationships (edges) to form a skeletal structure.
 The structure includes utility methods to access joint information and retrieve connections between joints.
*/

import CoreGraphics

/// Represents a detected human pose consisting of joints and edges.
struct Pose {
    /// Defines a parent-child relationship between two joints.
    struct Edge {
        let index: Int
        let parent: Joint.Name
        let child: Joint.Name

        /// Initializes an edge connecting two joints.
        /// - Parameters:
        ///   - parent: The parent joint.
        ///   - child: The child joint.
        ///   - index: The index corresponding to displacement maps.
        init(from parent: Joint.Name, to child: Joint.Name, index: Int) {
            self.index = index
            self.parent = parent
            self.child = child
        }
    }

    /// Defines the skeletal connections between joints.
    /// These edges are used to connect joints when rendering the detected pose.
    static let edges = [
        Edge(from: .nose, to: .leftEye, index: 0),
        Edge(from: .leftEye, to: .leftEar, index: 1),
        Edge(from: .nose, to: .rightEye, index: 2),
        Edge(from: .rightEye, to: .rightEar, index: 3),
        Edge(from: .nose, to: .leftShoulder, index: 4),
        Edge(from: .leftShoulder, to: .leftElbow, index: 5),
        Edge(from: .leftElbow, to: .leftWrist, index: 6),
        Edge(from: .leftShoulder, to: .leftHip, index: 7),
        Edge(from: .leftHip, to: .leftKnee, index: 8),
        Edge(from: .leftKnee, to: .leftAnkle, index: 9),
        Edge(from: .nose, to: .rightShoulder, index: 10),
        Edge(from: .rightShoulder, to: .rightElbow, index: 11),
        Edge(from: .rightElbow, to: .rightWrist, index: 12),
        Edge(from: .rightShoulder, to: .rightHip, index: 13),
        Edge(from: .rightHip, to: .rightKnee, index: 14),
        Edge(from: .rightKnee, to: .rightAnkle, index: 15)
    ]

    /// A dictionary of joints that make up a pose.
    private(set) var joints: [Joint.Name: Joint] = [
        .nose: Joint(name: .nose),
        .leftEye: Joint(name: .leftEye),
        .leftEar: Joint(name: .leftEar),
        .leftShoulder: Joint(name: .leftShoulder),
        .leftElbow: Joint(name: .leftElbow),
        .leftWrist: Joint(name: .leftWrist),
        .leftHip: Joint(name: .leftHip),
        .leftKnee: Joint(name: .leftKnee),
        .leftAnkle: Joint(name: .leftAnkle),
        .rightEye: Joint(name: .rightEye),
        .rightEar: Joint(name: .rightEar),
        .rightShoulder: Joint(name: .rightShoulder),
        .rightElbow: Joint(name: .rightElbow),
        .rightWrist: Joint(name: .rightWrist),
        .rightHip: Joint(name: .rightHip),
        .rightKnee: Joint(name: .rightKnee),
        .rightAnkle: Joint(name: .rightAnkle)
    ]

    /// The confidence score of the pose estimation.
    var confidence: Double = 0.0

    /// Accesses a joint by its name.
    subscript(jointName: Joint.Name) -> Joint {
        get {
            assert(joints[jointName] != nil)
            return joints[jointName]!
        }
        set {
            joints[jointName] = newValue
        }
    }

    /// Retrieves all edges connected to a specified joint.
    /// - Parameter jointName: The name of the joint to find edges for.
    /// - Returns: A list of edges connected to the joint.
    static func edges(for jointName: Joint.Name) -> [Edge] {
        return Pose.edges.filter {
            $0.parent == jointName || $0.child == jointName
        }
    }

    /// Retrieves a specific edge based on parent and child joints.
    /// - Parameters:
    ///   - parentJointName: The parent joint of the edge.
    ///   - childJointName: The child joint of the edge.
    /// - Returns: The corresponding edge if found, otherwise nil.



    


    static func edge(from parentJointName: Joint.Name, to childJointName: Joint.Name) -> Edge? {
        return Pose.edges.first(where: { $0.parent == parentJointName && $0.child == childJointName })
    }

    func movement(for group: [Joint.Name]) -> CGFloat {
    return group.compactMap { joints[$0]?.motionMagnitude() }.reduce(0, +)
}
    // Group joints by body part
    static let leftArm: [Joint.Name] = [.leftShoulder, .leftElbow, .leftWrist]
    static let rightArm: [Joint.Name] = [.rightShoulder, .rightElbow, .rightWrist]
    static let leftLeg: [Joint.Name] = [.leftHip, .leftKnee, .leftAnkle]
    static let rightLeg: [Joint.Name] = [.rightHip, .rightKnee, .rightAnkle]
}
