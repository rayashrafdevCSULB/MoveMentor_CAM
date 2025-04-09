/*
 ViewController.swift

 This file implements the main view controller responsible for coordinating the user interface,
 handling the video feed, and processing PoseNet model predictions.
 It manages camera input, runs pose detection, and updates the UI with detected poses.
*/

import AVFoundation
import UIKit

protocol VideoCaptureDelegate: AnyObject {
    func videoCapture(_ videoCapture: VideoCapture, didCapturePixelBuffer pixelBuffer: CVPixelBuffer?)
}

class VideoCapture: NSObject {
    weak var delegate: VideoCaptureDelegate?

    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "videoQueue")

    func setUp(sessionPreset: AVCaptureSession.Preset, completion: @escaping (Bool) -> Void) {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = sessionPreset

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input) else {
            completion(false)
            return
        }

        captureSession.addInput(input)

        if captureSession.canAddOutput(videoOutput) {
            videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
            captureSession.addOutput(videoOutput)
        } else {
            completion(false)
            return
        }

        captureSession.commitConfiguration()
        completion(true)
    }

    func start() {
        captureSession.startRunning()
    }

    func stop() {
        captureSession.stopRunning()
    }
}

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        delegate?.videoCapture(self, didCapturePixelBuffer: pixelBuffer)
    }
}
