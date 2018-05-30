
import UIKit

class DemoViewController: UIViewController {

    var imageScrollView: ImageScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()

        imageScrollView = ImageScrollView(frame: view.bounds)
        self.view = imageScrollView
        imageScrollView.displayTiledImage()
        view.backgroundColor = UIColor.white
    }
}

class ImageScrollView: UIScrollView {
    var zoomView: UIImageView?
    var tilingView: TilingView?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.delegate = self // TODO: Consider placing this in VC
    }

    func displayTiledImage() {//in url: URL, size imageSize: CGSize) {
        zoomView?.removeFromSuperview()
        zoomView = nil
        tilingView = nil

//        zoomView = UIImageView(frame: CGRect(origin: CGPoint.zero, size: imageSize))
//        let image = placeholderImage(for: url)
//        zoomView?.image = image
//        addSubview(zoomView!)

        let image = #imageLiteral(resourceName: "yosemite")
        tilingView = TilingView(image: image, frame: CGRect(origin: .zero, size: image.size))
        addSubview(tilingView!)

        configureFor(tilingView!.bounds.size)
    }

    private func configureFor(_ size: CGSize) {
        contentSize = size
        setMaxMinZoomScaleForCurrentBounds()
        zoomScale = self.minimumZoomScale
        zoomView?.isUserInteractionEnabled = true
    }

    private func setMaxMinZoomScaleForCurrentBounds() {
        let boundsSize = bounds.size
        let imageSize = tilingView?.bounds.size ?? CGSize.zero

        let xScale =  boundsSize.width  / imageSize.width
        let yScale = boundsSize.height / imageSize.height
        let minScale = min(xScale, yScale)

        var maxScale: CGFloat = 1.0

        if minScale < 0.1 {
            maxScale = 0.3
        }

        if minScale >= 0.1 && minScale < 0.5 {
            maxScale = 0.7
        }

        if minScale >= 0.5 {
            maxScale = max(1.0, minScale)
        }

        self.maximumZoomScale = 2//maxScale
        self.minimumZoomScale = 0.5//minScale
    }

    private func placeholderImage(for url: URL) -> UIImage? {
        let name = url.deletingPathExtension().lastPathComponent
        let imageName = "\(name)_Placeholder.jpg"
        let url = url.appendingPathComponent(imageName)
        return UIImage(contentsOfFile: url.path)
    }

    private func centerImageView() {
        let boundsSize = bounds.size
        var frameToCenter = tilingView?.frame ?? CGRect.zero

        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.width) / 2
        } else {
            frameToCenter.origin.x = 0
        }

        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.height) / 2
        } else {
            frameToCenter.origin.y = 0
        }

        tilingView?.frame = frameToCenter
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        centerImageView()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

extension ImageScrollView: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return tilingView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageView()
    }

}

class TileManager {

    private lazy var documentsDirectory: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }()

    private let fileManager = FileManager.default
    private let image: UIImage

    init(image: UIImage) {
        self.image = image
        clearImageCache()
    }

    private func clearImageCache() {
        guard let paths = try? fileManager.contentsOfDirectory(atPath: documentsDirectory.path) else { return }
        for path in paths {
            if path.contains("TiledImages") {
                try? fileManager.removeItem(atPath: pathByAppending(pathComponent: path).path)
            }
        }
    }

    func tileFor(size: CGSize, scale: CGFloat, rect: CGRect, row: Int, col: Int) -> UIImage? {
        let prefix = Int(scale * 1000)
        let pathComponent = "TiledImages-\(prefix)-\(row)-\(col)"
        let filePath = pathByAppending(pathComponent: pathComponent)
        if !fileManager.fileExists(atPath: filePath.path) {
            let prefix = "\(prefix)"
            guard let cgImage = image.cgImage else { return nil }
            saveTiles(ofSize: size, forRect: rect, toDirectory: "TiledImages", usingPrefix: prefix, image: cgImage)
        }
        
        return UIImage(contentsOfFile: filePath.path)
    }

    private func pathByAppending(pathComponent: String) -> URL {
        return documentsDirectory.appendingPathComponent(pathComponent)
    }

    private func saveTiles(ofSize tileSize: CGSize, forRect rect: CGRect, toDirectory directoryPath: String, usingPrefix prefix: String, image: CGImage) {

        let cgImage = image
        // TODO: Deal with remainder

        let firstCol = Int(floor(rect.minX / tileSize.width))
        let lastCol = Int(floor((rect.maxX - 1) / tileSize.width))
        let firstRow = Int(floor(rect.minY / tileSize.height))
        let lastRow = Int(floor((rect.maxY - 1) / tileSize.height))

        for row in firstRow...lastRow {
            for col in firstCol...lastCol {
                let tileImageRect = CGRect(x: tileSize.width * CGFloat(col), y: tileSize.height * CGFloat(row), width: tileSize.width, height: tileSize.height)
                guard let tileImage = cgImage.cropping(to: tileImageRect),
                    let imageData = UIImagePNGRepresentation(UIImage(cgImage: tileImage)) else { continue }
                let pathComponent = "TiledImages-\(prefix)-\(row)-\(col)"
                let fileManagerPath = pathByAppending(pathComponent: pathComponent)
                try? imageData.write(to: fileManagerPath)
            }
        }
    }

}

class TilingView: UIView {

    private let tileManager: TileManager
    private var tileBounds: CGRect?

    override static var layerClass: AnyClass {
        return CATiledLayer.self
    }

    override var contentScaleFactor: CGFloat {
        didSet {
            super.contentScaleFactor = 1
        }
    }

    required init(image: UIImage, frame: CGRect) {
        // TODO: Optimize for small images
        self.tileManager = TileManager(image: image)
        super.init(frame: frame)

        (self.layer as! CATiledLayer).levelsOfDetail = 4
        (self.layer as! CATiledLayer).levelsOfDetailBias = 2
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        self.tileBounds = bounds
    }

    override func draw(_ rect: CGRect) {
        guard let currentContext = UIGraphicsGetCurrentContext(),
            let tileBounds = tileBounds, tileBounds != CGRect.zero
            else { return }

        let scaleX: CGFloat = currentContext.ctm.a
        let scaleY: CGFloat = currentContext.ctm.d
        var tileSize = CGSize(width: 256, height: 256)
        tileSize.width /= scaleX
        tileSize.height /= -scaleY

        let firstCol = Int(floor(rect.minX / tileSize.width))
        let lastCol = Int(floor((rect.maxX - 1) / tileSize.width))
        let firstRow = Int(floor(rect.minY / tileSize.height))
        let lastRow = Int(floor((rect.maxY - 1) / tileSize.height))

        for row in firstRow...lastRow {
            for col in firstCol...lastCol {
                guard let tile = tileManager.tileFor(size: tileSize, scale: scaleX, rect: rect, row: row, col: col) else { return }

                var tileRect = CGRect(x: tileSize.width * CGFloat(col), y: tileSize.height * CGFloat(row), width: tileSize.width, height: tileSize.height)
                tileRect = tileBounds.intersection(tileRect)
                tile.draw(in: tileRect)

                if true {
                    scaleX == 4 ? UIColor.red.set() : UIColor.white.set()
                    currentContext.setLineWidth(6.0 / scaleX)
                    currentContext.stroke(tileRect)
                }
            }
        }
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

