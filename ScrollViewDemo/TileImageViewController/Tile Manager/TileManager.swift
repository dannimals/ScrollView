
import UIKit

class TileManager {

    private let image: UIImage
    private var fileManager: TiledImagesFileManager
    private let imageID = "demo-image"

    var imageFrame: CGRect {
        return CGRect(origin: .zero, size: image.size)
    }

    init(image: UIImage, tiledImagesFileManager: TiledImagesFileManager) {
        self.image = image
        self.fileManager = tiledImagesFileManager
    }

    private func pathNameFor(prefix: String, row: Int, col: Int) -> String {
        return "\(prefix)-\(row)-\(col)"
    }

    func clearImageCache() {
        fileManager.clearImageCache()
    }

    func tileFor(size: CGSize, scale: CGFloat, rect: CGRect, row: Int, col: Int) -> UIImage? {
        let prefix = "\(imageID)_\(String(Int(scale * 1000)))"
        let pathComponent = pathNameFor(prefix: prefix, row: row, col: col)
        guard let filePath = fileManager.urlPathByAppending(pathComponent: pathComponent) else { return nil }

        if !fileManager.fileExists(atPath: filePath.path) {
            var optimalImage = image.cgImage
            if scale * 1000 >= 4000 {
                optimalImage = fileManager.highResImage ?? image.cgImage
            }
            guard let cgImage = optimalImage else { return nil }
            let mappedRect = mappedRectForImage(cgImage, rect: rect)
            saveTile(forImage: cgImage, ofSize: size, forRect: mappedRect, usingPrefix: prefix, forRow: row, forCol: col)
        }

        return UIImage(contentsOfFile: filePath.path)
    }

    private func mappedRectForImage(_ mappedImage: CGImage, rect: CGRect) -> CGRect {
        let scaleX = CGFloat(mappedImage.width) / image.size.width
        let scaleY = CGFloat(mappedImage.height) / image.size.height

        let mappedX = rect.minX * scaleX
        let mappedY = rect.minY * scaleY
        let mappedWidth = rect.width * scaleX
        let mappedHeight = rect.height * scaleY

        return CGRect(x: mappedX, y: mappedY, width: mappedWidth, height: mappedHeight)
    }

    private func saveTile(forImage image: CGImage, ofSize tileSize: CGSize, forRect rect: CGRect, usingPrefix prefix: String, forRow row: Int, forCol col: Int) {
        let pathComponent = pathNameFor(prefix: prefix, row: row, col: col)
        guard let tileImage = image.cropping(to: rect),
            let imageData = UIImagePNGRepresentation(UIImage(cgImage: tileImage)),
            let pathURL = fileManager.urlPathByAppending(pathComponent: pathComponent) else { return }
        fileManager.store(imageData: imageData, toPathURL: pathURL)
    }

}
