
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

        self.delegate = self
    }

    func displayTiledImage(in url: URL, size imageSize: CGSize) {
        zoomView?.removeFromSuperview()
        zoomView = nil
        tilingView = nil

        zoomView = UIImageView(frame: CGRect(origin: CGPoint.zero, size: imageSize))
        let image = placeholderImage(for: url)
        zoomView?.image = image
        addSubview(zoomView!)

        tilingView = TilingView(url: url, size: imageSize)
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

class TilingView: UIView {

    let imageName: String
    let url: URL

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

    required init(url: URL, size: CGSize) {
        self.url = url
        self.imageName = url.deletingPathExtension().lastPathComponent

        super.init(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
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
                guard let tile = tileFor(scale: scaleX, row: row, col: col) else { return }
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

    func tileFor(scale: CGFloat, row: Int, col: Int) -> UIImage? {
        let scale = scale < 1.0 ? Int(1 / CGFloat(Int(1 / scale)) * 1000) : Int(scale * 1000)
        let tileName = "\(self.imageName)_\(scale)_\(col)_\(row).png"
        let path = url.appendingPathComponent(tileName).path
        let image = UIImage(contentsOfFile: path)

        return image
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

