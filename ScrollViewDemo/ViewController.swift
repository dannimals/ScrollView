
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

    var tiledLayer: CATiledLayer {
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

        let scale = currentContext.ctm.a
        var tileSize = tiledLayer.tileSize
        tileSize.width /= scale
        tileSize.height /= scale

        let firstCol = floor(rect.minX / tileSize.width)
        let lastCol = floor((rect.maxX - 1) / tileSize.width)
        let firstRow = floor(rect.minY / tileSize.height)
        let lastRow = floor((rect.maxY - 1) / tileSize.height)

        for row in Int(firstRow)...Int(lastRow) {
            for col in Int(firstCol)...Int(lastCol) {
                let tile = tileForScale(scale, row: row, col: col)
                var tileRect = CGRect(x: tileSize.width * CGFloat(col), y: tileSize.height * CGFloat(row), width: tileSize.width, height: tileSize.height)
                tileRect = self.bounds.intersection(tileRect)
                tile.draw(in: tileRect)
            }
        }
    }

    //TODO: What...
    func tileForScale(_ scale: CGFloat, row: Int, col: Int) -> UIImage {
        return UIImage()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

