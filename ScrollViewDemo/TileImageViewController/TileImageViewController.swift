
import UIKit

class TileImageViewController: UIViewController {

    var imageScrollView: TiledImageScrollView!
    var tiledImagesFileManager: TiledImagesFileManager!

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    func setImages(_ image: UIImage, tiledImagesFileManager: TiledImagesFileManager) {
        self.tiledImagesFileManager = tiledImagesFileManager
        imageScrollView.display(image: image, tiledImagesFileManager: tiledImagesFileManager)
    }

    func configure(tiledImagesFileManager: TiledImagesFileManager) {
        self.tiledImagesFileManager = tiledImagesFileManager
        setupTiledImagesFileManager()
    }

    private func setup() {
        view.backgroundColor = UIColor.white
        setupScrollView()
    }

    private func setupScrollView() {
        imageScrollView = TiledImageScrollView()
        imageScrollView.delegate = self
        imageScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageScrollView)
        imageScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        imageScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 25).isActive = true
        imageScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -25).isActive = true
        imageScrollView.layoutIfNeeded()
    }

    private func setupTiledImagesFileManager() {
        guard let url = TiledImageDemo.demoImageURL else { return }
        tiledImagesFileManager.downloadHighResImageToDisk(url)
        setImages(TiledImageDemo.lowResolutionDemoImage, tiledImagesFileManager: tiledImagesFileManager)
    }

}

extension TileImageViewController: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageScrollView.tilingView
    }

}
