/*
 PopOverPresentationManager.swift
 
 This file implements the PopOverPresentationManager and PopOverPresentationController classes.
 These classes are responsible for presenting the ConfigurationViewController as a pop-over modal.
 The pop-over is displayed at the bottom of the screen, occupying a configurable portion of the height.
*/

import UIKit

// MARK: - PopOverPresentationManager

/// Manages the transition for presenting a view controller as a pop-over modal.
class PopOverPresentationManager: NSObject, UIViewControllerTransitioningDelegate {
    var presentedViewController: UIViewController
    var presentingViewController: UIViewController

    /// Initializes the presentation manager with the presenting and presented view controllers.
    /// - Parameters:
    ///   - presentingViewController: The view controller initiating the presentation.
    ///   - presentedViewController: The view controller being presented.
    init(presenting presentingViewController: UIViewController,
         presented presentedViewController: UIViewController) {
        self.presentingViewController = presentingViewController
        self.presentedViewController = presentedViewController
    }

    /// Returns a custom presentation controller to manage the pop-over appearance.
    /// - Parameters:
    ///   - presented: The view controller being presented.
    ///   - presenting: The view controller initiating the presentation.
    ///   - source: The source view controller triggering the presentation.
    /// - Returns: A custom UIPresentationController instance for managing the pop-over.
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        return PopOverPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

// MARK: - PopOverPresentationController

/// Custom presentation controller for managing the pop-over modal's frame and layout.
class PopOverPresentationController: UIPresentationController {
    /// Defines the height ratio of the pop-over relative to the screen height.
    private let popOverHeightRatio: CGFloat = 0.6

    /// Computes the frame for the presented view within the container view.
    override var frameOfPresentedViewInContainerView: CGRect {
        let viewHeight = containerView!.bounds.height * popOverHeightRatio
        let origin = CGPoint(x: 0, y: containerView!.bounds.height - viewHeight)
        let size = CGSize(width: containerView!.bounds.width, height: viewHeight)
        return CGRect(origin: origin, size: size)
    }
}
