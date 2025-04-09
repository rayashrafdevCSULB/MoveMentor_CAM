/*
CGImage+Extension.swift
Abstract:
Implementation details of the size property to extend the CGImage class.
*/


import CoreGraphics
import UIKit
import CoreVideo

extension CVPixelBuffer {
    func toCGImage() -> CGImage? {
        let ciImage = CIImage(cvPixelBuffer: self)
        let context = CIContext()
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
}

extension CGImage {
    var size: CGSize {
        return CGSize(width: width, height: height)
    }
    func rotated(by radians: CGFloat) -> CGImage? {
        let originalSize = CGSize(width: self.width, height: self.height)
        let rotatedViewBox = UIView(frame: CGRect(origin: .zero, size: originalSize))
        let t = CGAffineTransform(rotationAngle: radians)
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size

        let renderer = UIGraphicsImageRenderer(size: rotatedSize)
        let image = renderer.image { context in
            let ctx = context.cgContext
            ctx.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            ctx.rotate(by: radians)
            ctx.translateBy(x: -CGFloat(self.width) / 2, y: -CGFloat(self.height) / 2)
            ctx.draw(self, in: CGRect(origin: .zero, size: originalSize))
        }
        return image.cgImage
}
}
