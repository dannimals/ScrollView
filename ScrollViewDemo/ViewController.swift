
import UIKit

class DemoViewController: UIViewController {

    var imageScrollView: ImageScrollView!

    override func loadView() {
        super.loadView()

        imageScrollView = ImageScrollView(frame: view.bounds)
        imageScrollView.delegate = self
        self.view = imageScrollView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white
        let lowResolutionImage = #imageLiteral(resourceName: "galaxy-smallest")
        imageScrollView.display(image: lowResolutionImage)
    }
}

extension DemoViewController: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageScrollView.tilingView
    }

}

class ImageScrollView: UIScrollView {
    var tilingView: TilingView?
    var scaledImage: UIImage?

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    func display(image: UIImage) {
        self.tilingView = TilingView(image: image, frame: CGRect(origin: .zero, size: image.size))
        guard let tilingView = self.tilingView else { return }
        addSubview(tilingView)
        setMaxMinZoomScaleForCurrentBounds()
    }

    private func setup() {
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
    }

    private func setMaxMinZoomScaleForCurrentBounds() {
        guard let tilingView = tilingView else { return }
        maximumZoomScale = 2
        minimumZoomScale = 0.125
        if tilingView.bounds.size.width > bounds.width {
            let scale = bounds.width / tilingView.bounds.size.width
            minimumZoomScale = min(minimumZoomScale, scale)
            zoomScale = scale
        }
    }

    func centerImageView() {
        guard let tilingView = self.tilingView else { return }

        let boundsSize = bounds.size
        var frameToCenter = tilingView.frame

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

        tilingView.frame = frameToCenter
    }

    override func layoutSubviews() {
        super.layoutSubviews()

//        if zoomScale * 1000 <= 1000 {
//            let lowResolutionImage = #imageLiteral(resourceName: "galaxy-smallest")
//            display(image: lowResolutionImage)
//        } else if zoomScale * 1000 <= 2000 && zoomScale * 1000 > 1000 {
//            let medResolutionImage = #imageLiteral(resourceName: "galaxy-smaller")
//            display(image: medResolutionImage)
//        } else {
//            let highResolutionImage = #imageLiteral(resourceName: "galaxy")
//            display(image: highResolutionImage)
//        }
        centerImageView()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

class TileManager {

    private lazy var documentsDirectory: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }()

    private let fileManager = FileManager.default
    private let image: UIImage
    private let midResImage: UIImage?
    private let highResImage: UIImage?

    init(image: UIImage, midResImage: UIImage?, highResImage: UIImage?) {
        self.image = image
        let sizeToResize = image.size
        self.midResImage = midResImage?.resizeImage(toSize: sizeToResize)
        self.highResImage = highResImage?.resizeImage(toSize: sizeToResize)
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
            var optimalImage: UIImage?
            if scale * 1000 <= 1000 {
                optimalImage = self.image
            } else if scale * 1000 <= 2000 && scale * 1000 > 1000 {
                optimalImage = self.midResImage
            } else {
                optimalImage = self.highResImage
            }
            guard let cgImage = optimalImage?.cgImage else { return nil }
            saveTile(ofSize: size, forRect: rect, withScale: scale, usingPrefix: prefix, forImage: cgImage, forRow: row, forCol: col)
//            saveTiles(ofSize: size, forRect: rect, toDirectory: "TiledImages", usingPrefix: prefix, image: cgImage)
        }
        
        return UIImage(contentsOfFile: filePath.path)
    }

    private func pathByAppending(pathComponent: String) -> URL {
        return documentsDirectory.appendingPathComponent(pathComponent)
    }

    private func saveTile(ofSize tileSize: CGSize, forRect rect: CGRect, withScale scale: CGFloat, usingPrefix prefix: String, forImage image: CGImage, forRow row: Int, forCol col: Int) {
        guard let tileImage = image.cropping(to: rect),
            let imageData = UIImagePNGRepresentation(UIImage(cgImage: tileImage)) else { return }

        let pathComponent = "TiledImages-\(prefix)-\(row)-\(col)"
        let fileManagerPath = pathByAppending(pathComponent: pathComponent)
        try? imageData.write(to: fileManagerPath)
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
    private let tileSize = CGSize(width: 500, height: 500)

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
        self.tileManager = TileManager(image: image, midResImage: #imageLiteral(resourceName: "galaxy-smaller"), highResImage: #imageLiteral(resourceName: "galaxy"))
        super.init(frame: frame)

        (self.layer as! CATiledLayer).levelsOfDetail = 7
        (self.layer as! CATiledLayer).levelsOfDetailBias = 3
        (self.layer as! CATiledLayer).tileSize = tileSize
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        self.tileBounds = bounds
    }

    override func draw(_ rect: CGRect) {
        guard let currentContext = UIGraphicsGetCurrentContext(),
            let tileBounds = tileBounds, tileBounds != CGRect.zero
            else { return }

        let scale: CGFloat = currentContext.ctm.a
        var tileSize = self.tileSize
        tileSize.width /= scale
        tileSize.height /= scale

        let firstCol = Int(floor(rect.minX / tileSize.width))
        let lastCol = Int(floor((rect.maxX - 1) / tileSize.width))
        let firstRow = Int(floor(rect.minY / tileSize.height))
        let lastRow = Int(floor((rect.maxY - 1) / tileSize.height))

        for row in firstRow...lastRow {
            for col in firstCol...lastCol {
                guard let tile = tileManager.tileFor(size: tileSize, scale: scale, rect: rect, row: row, col: col) else { return }

                var tileRect = CGRect(x: tileSize.width * CGFloat(col), y: tileSize.height * CGFloat(row), width: tileSize.width, height: tileSize.height)
                tileRect = tileBounds.intersection(tileRect)
                tile.draw(in: tileRect)

                if true {
                    scale == 4 ? UIColor.red.set() : UIColor.white.set()
                    currentContext.setLineWidth(6.0 / scale)
                    currentContext.stroke(tileRect)
                }
            }
        }
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
