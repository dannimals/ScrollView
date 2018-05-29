
import UIKit

class DemoViewController: UIViewController {

    var imageScrollView: ImageScrollView!

    override func loadView() {
        super.loadView()

        imageScrollView = ImageScrollView(frame: view.bounds)
        self.view = imageScrollView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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

    func displayTiledImage(in url: URL, size imageSize: CGSize) {
        zoomView?.removeFromSuperview()
        zoomView = nil
        tilingView = nil

        zoomView = UIImageView(frame: CGRect(origin: CGPoint.zero, size: imageSize))
        let image = placeholderImage(for: url)
        zoomView?.image = image
        addSubview(zoomView!)

        tilingView = TilingView(image: UIImage(), frame: CGRect.zero)
        zoomView?.addSubview(tilingView!)

        configureFor(imageSize)
    }

    private func configureFor(_ size: CGSize) {
        contentSize = size
        setMaxMinZoomScaleForCurrentBounds()
        zoomScale = self.minimumZoomScale
        zoomView?.isUserInteractionEnabled = true
    }

    private func setMaxMinZoomScaleForCurrentBounds() {
        let boundsSize = bounds.size
        let imageSize = zoomView?.bounds.size ?? CGSize.zero

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

        self.maximumZoomScale = maxScale
        self.minimumZoomScale = minScale
    }

    private func placeholderImage(for url: URL) -> UIImage? {
        let name = url.deletingPathExtension().lastPathComponent
        let imageName = "\(name)_Placeholder.jpg"
        let url = url.appendingPathComponent(imageName)
        return UIImage(contentsOfFile: url.path)
    }

    private func centerImageView() {
        let boundsSize = bounds.size
        var frameToCenter = zoomView?.frame ?? CGRect.zero

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

        zoomView?.frame = frameToCenter
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        centerImageView()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

extension ImageScrollView: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomView
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

    private let image: UIImage

    init(image: UIImage) {
        self.image = image
    }

    func saveTiles(ofSize tileSize: CGSize, forRect rect: CGRect, toDirectory directoryPath: String, usingPrefix prefix: String) {
        guard let cgImage = image.cgImage else { return }

        let firstCol = Int(floor(rect.minX / tileSize.width))
        let lastCol = Int(floor((rect.maxX - 1) / tileSize.width))
        let firstRow = Int(floor(rect.minY / tileSize.height))
        let lastRow = Int(floor((rect.maxY - 1) / tileSize.height))

        for row in firstRow...lastRow {
            for col in firstCol...lastCol {
                let tileImageRect = CGRect(x: tileSize.width * CGFloat(row), y: tileSize.height * CGFloat(col), width: tileSize.width, height: tileSize.height)
                guard let tileImage = cgImage.cropping(to: tileImageRect),
                    let imageData = UIImagePNGRepresentation(UIImage(cgImage: tileImage)) else { continue }
                let imagePathComponent = String(format: "%@/%@%d_%d.png", directoryPath, prefix, row, col)
                let fileManagerPath = documentsDirectory.appendingPathComponent(imagePathComponent)
                try? imageData.write(to: fileManagerPath)
            }
        }
    }

    func tileFor(scale: CGFloat, row: Int, col: Int) -> UIImage? {
        return nil
    }

}

class TilingView: UIView {

    private let tileManager: TileManager

    override static var layerClass: AnyClass {
        return CATiledLayer.self
    }

    override var contentScaleFactor: CGFloat {
        didSet {
            super.contentScaleFactor = 1
        }
    }

    private var tiledLayer: CATiledLayer {
        return self.layer as! CATiledLayer
    }

    required init(image: UIImage, frame: CGRect) {
        self.tileManager = TileManager(image: image)
        super.init(frame: frame)

        tiledLayer.levelsOfDetail = 4
    }

    override func draw(_ rect: CGRect) {
        guard let currentContext = UIGraphicsGetCurrentContext(), let tiledLayer = self.layer as? CATiledLayer
            else { return }

        let scaleX: CGFloat = currentContext.ctm.a
        let scaleY: CGFloat = currentContext.ctm.d
        var tileSize = tiledLayer.tileSize
        tileSize.width /= scaleX
        tileSize.height /= -scaleY

        let firstCol = Int(floor(rect.minX / tileSize.width))
        let lastCol = Int(floor((rect.maxX - 1) / tileSize.width))
        let firstRow = Int(floor(rect.minY / tileSize.height))
        let lastRow = Int(floor((rect.maxY - 1) / tileSize.height))

        for row in firstRow...lastRow {
            for col in firstCol...lastCol {
                guard let tile = tileManager.tileFor(scale: scaleX, row: row, col: col) else { return }
                var tileRect = CGRect(x: tileSize.width * CGFloat(col), y: tileSize.height * CGFloat(row), width: tileSize.width, height: tileSize.height)
                tileRect = self.bounds.intersection(tileRect)
                tile.draw(in: tileRect)

                if true {
                    UIColor.white.set()
                    currentContext.setLineWidth(6.0 / scaleX)
                    currentContext.stroke(tileRect)
                }
            }
        }
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

