/*
 VideoCapture.swift
 
 This file defines the VideoCapture class, which manages frame capturing from the device camera.
 It handles camera setup, frame processing, and communication with a delegate to provide captured images.
 The class also supports toggling between front and back cameras.
*/

import AVFoundation
import CoreVideo
import UIKit
import VideoToolbox

/// Protocol for receiving captured frames.
protocol VideoCaptureDelegate: AnyObject {
    func videoCapture(_ videoCapture: VideoCapture, didCaptureFrame image: CGImage?)
}

/// Manages camera input and provides frames to a delegate.
class VideoCapture: NSObject {
    enum VideoCaptureError: Error {
        case captureSessionIsMissing
        case invalidInput
        case invalidOutput
        case unknown
    }

    /// The delegate receiving captured frames.
    weak var delegate: VideoCaptureDelegate?

    /// Capture session coordinating data flow from camera to output.
    let captureSession = AVCaptureSession()

    /// Capture output providing video frames to the delegate.
    let videoOutput = AVCaptureVideoDataOutput()

    /// Current camera position (front or back).
    private(set) var cameraPostion = AVCaptureDevice.Position.back

    /// Dispatch queue for handling camera setup and frame capture.
    private let sessionQueue = DispatchQueue(label: "com.example.apple-samplecode.estimating-human-pose-with-posenet.sessionqueue")

    /// Toggles between front and back camera.
    public func flipCamera(completion: @escaping (Error?) -> Void) {
        sessionQueue.async {
            do {
                self.cameraPostion = self.cameraPostion == .back ? .front : .back
                self.captureSession.beginConfiguration()
                try self.setCaptureSessionInput()
                try self.setCaptureSessionOutput()
                self.captureSession.commitConfiguration()
                DispatchQueue.main.async { completion(nil) }
            } catch {
                DispatchQueue.main.async { completion(error) }
            }
        }
    }

    /// Asynchronously sets up the capture session.
    public func setUpAVCapture(completion: @escaping (Error?) -> Void) {
        sessionQueue.async {
            do {
                try self.setUpAVCapture()
                DispatchQueue.main.async { completion(nil) }
            } catch {
                DispatchQueue.main.async { completion(error) }
            }
        }
    }

    private func setUpAVCapture() throws {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .vga640x480
        try setCaptureSessionInput()
        try setCaptureSessionOutput()
        captureSession.commitConfiguration()
    }

    private func setCaptureSessionInput() throws {
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPostion) else {
            throw VideoCaptureError.invalidInput
        }
        captureSession.inputs.forEach { captureSession.removeInput($0) }
        guard let videoInput = try? AVCaptureDeviceInput(device: captureDevice), captureSession.canAddInput(videoInput) else {
            throw VideoCaptureError.invalidInput
        }
        captureSession.addInput(videoInput)
    }

    private func setCaptureSessionOutput() throws {
        captureSession.outputs.forEach { captureSession.removeOutput($0) }
        videoOutput.videoSettings = [
            String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        guard captureSession.canAddOutput(videoOutput) else { throw VideoCaptureError.invalidOutput }
        captureSession.addOutput(videoOutput)
        if let connection = videoOutput.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = AVCaptureVideoOrientation(deviceOrientation: UIDevice.current.orientation)
            connection.isVideoMirrored = cameraPostion == .front
            if connection.videoOrientation == .landscapeLeft {
                connection.videoOrientation = .landscapeRight
            } else if connection.videoOrientation == .landscapeRight {
                connection.videoOrientation = .landscapeLeft
            }
        }
    }

    /// Starts capturing frames.
    public func startCapturing(completion completionHandler: (() -> Void)? = nil) {
        sessionQueue.async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
            if let completionHandler = completionHandler {
                DispatchQueue.main.async { completionHandler() }
            }
        }
    }

    /// Stops capturing frames.
    public func stopCapturing(completion completionHandler: (() -> Void)? = nil) {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            if let completionHandler = completionHandler {
                DispatchQueue.main.async { completionHandler() }
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let delegate = delegate, let pixelBuffer = sampleBuffer.imageBuffer else { return }
        guard CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly) == kCVReturnSuccess else { return }
        var image: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &image)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        DispatchQueue.main.sync {
            delegate.videoCapture(self, didCaptureFrame: image)
        }
    }
}
