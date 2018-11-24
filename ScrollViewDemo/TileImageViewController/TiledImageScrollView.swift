
import UIKit

class TiledImageScrollView: UIScrollView {

    var tilingView: TilingView?
    var drawingContainerView: UIView? { return tilingView }

    let doubleTapGestureRecognizer = UITapGestureRecognizer()

    lazy var previousZoomScale: CGFloat = {
        return self.zoomScaleToFit
    }()
    override var zoomScale: CGFloat {
        willSet { previousZoomScale = zoomScale }
    }

    var zoomScaleToFit: CGFloat {
        return min(bounds.size.width / (image?.size.width ?? 1), bounds.size.height / (image?.size.height ?? 1))
    }

    private var image: UIImage?

    private func setup() {
        setupScrollView()
        setupDoubleTapGestureRecognizer()
    }

    private func setupDoubleTapGestureRecognizer() {
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        doubleTapGestureRecognizer.addTarget(self, action: #selector(didDoubleTap))
        addGestureRecognizer(doubleTapGestureRecognizer)
    }

    private func setupScrollView() {
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        centerImageView()
    }

    func display(image: UIImage, tiledImagesFileManager: TiledImagesFileManager) {
        tiledImagesFileManager.clearImageCache()
        self.image = image
        if let tilingView = tilingView {
            tilingView.removeFromSuperview()
            self.tilingView = nil
        }
        let tileManager = TileManager(image: image, tiledImagesFileManager: tiledImagesFileManager)
        self.tilingView = TilingView(tileManager: tileManager)
        guard let tilingView = self.tilingView else { return }
        addSubview(tilingView)
        setMaxMinZoomScaleForCurrentBounds()
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
        if tilingView.bounds.width < bounds.width && tilingView.bounds.height < bounds.height {
            minimumZoomScale = zoomScaleToFit
            maximumZoomScale = zoomScaleToFit
            zoomScale = zoomScaleToFit
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

    @objc private func didDoubleTap(_ gestureRecognizer: UIGestureRecognizer) {
        guard let tilingView = tilingView else { return }
        let location = gestureRecognizer.location(in: tilingView)
        let zoomPoint = (superview ?? self).convert(location, to: self)
        let zoomRect = CGRect(origin: zoomPoint, size: .zero)
        maximumZoomScale = 1
        zoom(to: zoomRect, animated: true)
        maximumZoomScale = 2
    }

}
