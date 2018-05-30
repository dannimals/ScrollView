
import UIKit

extension UIImage {

    func resizeImage(toSize size: CGSize) -> UIImage? {
        guard let cgImage = cgImage else { return nil }

        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.interpolationQuality = .high
        let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height)

        context.concatenate(flipVertical)
        context.draw(cgImage, in: rect)

        guard let newCGImage = context.makeImage() else { return nil }
        let newImage = UIImage(cgImage: newCGImage)
        UIGraphicsEndImageContext()

        return newImage
    }
}
