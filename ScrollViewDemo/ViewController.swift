
import UIKit

class DemoViewController: UIViewController {

    var imageScrollView: ImageScrollView!

    override func loadView() {
        super.loadView()

        imageScrollView = ImageScrollView(frame: view.bounds)
        self.view = imageScrollView
        imageScrollView.delegate = self
        imageScrollView.maximumZoomScale = 5
        imageScrollView.minimumZoomScale = 0.5
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white

    }
}

extension DemoViewController: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageScrollView.imageView
    }
}

class ImageScrollView: UIScrollView {
    let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "maincoon")
        var imageViewFrame = imageView.frame
        imageViewFrame.size.width = frame.width
        imageViewFrame.size.height = frame.height
        imageView.frame = imageViewFrame
        addSubview(imageView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let boundsSize = bounds.size
        var frameToCenter = imageView.frame

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

        imageView.frame = frameToCenter
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
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

