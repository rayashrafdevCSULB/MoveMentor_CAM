/*
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
}
