
import UIKit

class NonTileImageViewController: UIViewController {

    let imageScrollView = UIScrollView()
    let imageView = UIImageView()
    let doubleTapGestureRecognizer = UITapGestureRecognizer()
    var tiledImagesFileManager: TiledImagesFileManager!

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    private func setup() {
        view.backgroundColor = UIColor.white
        setupDoubleTapGestureRecognizer()
        setupScrollView()
        setupImageView()
    }

    private func setupDoubleTapGestureRecognizer() {
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        doubleTapGestureRecognizer.addTarget(self, action: #selector(didDoubleTap))
        imageScrollView.addGestureRecognizer(doubleTapGestureRecognizer)
    }

    private func setupScrollView() {
        imageScrollView.delegate = self
        imageScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageScrollView)
        imageScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        imageScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 25).isActive = true
        imageScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -25).isActive = true
        imageScrollView.layoutIfNeeded()
    }

    private func setupImageView() {
        imageView.image = #imageLiteral(resourceName: "galaxy")
        imageView.contentMode = .scaleAspectFit
        imageScrollView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.leadingAnchor.constraint(equalTo: imageScrollView.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: imageScrollView.trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: imageScrollView.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: imageScrollView.bottomAnchor).isActive = true
        imageView.layoutIfNeeded()
    }

    @objc private func didDoubleTap(_ gestureRecognizer: UIGestureRecognizer) {
        let location = gestureRecognizer.location(in: imageScrollView)
        let zoomRect = CGRect(origin: location, size: .zero)
        imageScrollView.maximumZoomScale = 1
        imageScrollView.zoom(to: zoomRect, animated: true)
        imageScrollView.maximumZoomScale = 2
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        updateMinZoomScaleForSize(view.bounds.size)
        centerImageView()
    }

    private func updateMinZoomScaleForSize(_ size: CGSize) {
        let widthScale = size.width / imageView.bounds.width
        let heightScale = size.height / imageView.bounds.height
        let minScale = min(widthScale, heightScale)

        imageScrollView.minimumZoomScale = minScale
        imageScrollView.zoomScale = minScale
    }

    private func centerImageView() {
        let boundsSize = view.bounds.size
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

}

extension NonTileImageViewController: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

}
