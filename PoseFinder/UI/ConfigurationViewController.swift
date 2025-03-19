/*
 ConfigurationViewController.swift
 
 This file defines a modal view that allows users to configure PoseNet algorithm parameters.
 Users can adjust confidence thresholds, search radii, and refinement steps through UI sliders.
 The selected values are passed back to the main application via a delegate pattern.
*/

import UIKit

/// Protocol for handling configuration updates.
protocol ConfigurationViewControllerDelegate: AnyObject {
    func configurationViewController(_ viewController: ConfigurationViewController,
                                     didUpdateConfiguration: PoseBuilderConfiguration)
    func configurationViewController(_ viewController: ConfigurationViewController,
                                     didUpdateAlgorithm: Algorithm)
}

/// View controller for adjusting PoseNet algorithm parameters.
class ConfigurationViewController: UIViewController {
    /// UI components for user-adjustable parameters.
    @IBOutlet var algorithmSegmentedControl: UISegmentedControl!
    @IBOutlet var jointConfidenceThresholdLabel: UILabel!
    @IBOutlet var jointConfidenceThresholdSlider: UISlider!
    @IBOutlet var poseConfidenceThresholdLabel: UILabel!
    @IBOutlet var poseConfidenceThresholdSlider: UISlider!
    @IBOutlet var localJointSearchRadiusLabel: UILabel!
    @IBOutlet var localJointSearchRadiusSlider: UISlider!
    @IBOutlet var matchingJointMinimumDistanceLabel: UILabel!
    @IBOutlet var matchingJointMinimumDistanceSlider: UISlider!
    @IBOutlet var adjacentJointOffsetRefinementStepsLabel: UILabel!
    @IBOutlet var adjacentJointOffsetRefinementStepsSlider: UISlider!

    /// Text descriptions for UI labels.
    let jointConfidenceThresholdText = "Joint confidence threshold"
    let poseConfidenceThresholdText = "Pose confidence threshold"
    let localJointSearchRadiusText = "Local joint search radius"
    let matchingJointMinimumDistanceText = "Matching joint minimum distance"
    let adjacentJointOffsetRefinementStepsText = "Adjacent joint refinement steps"

    weak var delegate: ConfigurationViewControllerDelegate?

    /// Configuration settings for PoseNet.
    var configuration: PoseBuilderConfiguration! {
        didSet {
            delegate?.configurationViewController(self, didUpdateConfiguration: configuration)
            updateUILabels()
        }
    }

    /// Algorithm selection for single or multiple pose detection.
    var algorithm: Algorithm = .multiple {
        didSet {
            delegate?.configurationViewController(self, didUpdateAlgorithm: algorithm)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize UI controls with current configuration values.
        algorithmSegmentedControl.selectedSegmentIndex = algorithm == .single ? 0 : 1
        jointConfidenceThresholdSlider.value = Float(configuration.jointConfidenceThreshold)
        poseConfidenceThresholdSlider.value = Float(configuration.poseConfidenceThreshold)
        localJointSearchRadiusSlider.value = Float(configuration.localSearchRadius)
        matchingJointMinimumDistanceSlider.value = Float(configuration.matchingJointDistance)
        adjacentJointOffsetRefinementStepsSlider.value = Float(configuration.adjacentJointOffsetRefinementSteps)

        updateUILabels()
    }

    /// Closes the configuration modal.
    @IBAction func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    /// Updates the selected algorithm mode (single or multiple poses).
    @IBAction func algorithmValueChanged(_ sender: Any) {
        algorithm = algorithmSegmentedControl.selectedSegmentIndex == 0 ? .single : .multiple
    }

    /// Adjusts joint confidence threshold based on slider value.
    @IBAction func jointConfidenceThresholdValueChanged(_ sender: Any) {
        configuration.jointConfidenceThreshold = Double(jointConfidenceThresholdSlider.value)
    }

    /// Adjusts pose confidence threshold based on slider value.
    @IBAction func poseConfidenceThresholdValueChanged(_ sender: Any) {
        configuration.poseConfidenceThreshold = Double(poseConfidenceThresholdSlider.value)
    }

    /// Adjusts local search radius for joint detection.
    @IBAction func localJointSearchRadiusValueChanged(_ sender: Any) {
        configuration.localSearchRadius = Int(localJointSearchRadiusSlider.value)
    }

    /// Adjusts minimum joint matching distance.
    @IBAction func matchingJointMinimumDistanceValueChanged(_ sender: Any) {
        configuration.matchingJointDistance = Double(matchingJointMinimumDistanceSlider.value)
    }

    /// Adjusts the number of refinement steps for joint offset calculation.
    @IBAction func offsetRefineStepsValueChanged(_ sender: Any) {
        configuration.adjacentJointOffsetRefinementSteps = Int(adjacentJointOffsetRefinementStepsSlider.value)
    }

    /// Updates the UI labels based on current configuration values.
    private func updateUILabels() {
        // Ensure UI components are initialized before updating labels.
        guard jointConfidenceThresholdLabel != nil else { return }

        jointConfidenceThresholdLabel.text = jointConfidenceThresholdText +
            String(format: " (%.1f)", configuration.jointConfidenceThreshold)

        poseConfidenceThresholdLabel.text = poseConfidenceThresholdText +
            String(format: " (%.1f)", configuration.poseConfidenceThreshold)

        matchingJointMinimumDistanceLabel.text = matchingJointMinimumDistanceText +
            String(format: " (%.1f)", configuration.matchingJointDistance)

        localJointSearchRadiusLabel.text = localJointSearchRadiusText +
        " (\(Int(configuration.localSearchRadius)))"

        adjacentJointOffsetRefinementStepsLabel.text = adjacentJointOffsetRefinementStepsText +
        " (\(Int(configuration.adjacentJointOffsetRefinementSteps)))"
    }
}
