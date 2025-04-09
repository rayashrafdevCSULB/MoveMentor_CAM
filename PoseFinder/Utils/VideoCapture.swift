/*
 VideoCapture.swift
 
 This file defines the VideoCapture class, which manages frame capturing from the device camera.
 It handles camera setup, frame processing, and communication with a delegate to provide captured images.
 The class also supports toggling between front and back cameras.
*/

import AVFoundation
import UIKit

// MARK: - Delegate Protocol

protocol VideoCaptureDelegate: AnyObject {
    func videoCapture(_ videoCapture: VideoCapture, didCapturePixelBuffer pixelBuffer: CVPixelBuffer?)
}

// MARK: - Camera Manager

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

// MARK: - Frame Output

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        delegate?.videoCapture(self, didCapturePixelBuffer: pixelBuffer)
    }
}

