/*
Abstract:
Implementation details of the size property to extend the CGImage class.
*/

import CoreGraphics

extension CGImage {
    var size: CGSize {
        return CGSize(width: width, height: height)
    }
}
