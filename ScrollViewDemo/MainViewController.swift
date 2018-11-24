
import UIKit

class MainViewController: UIViewController {

    let tileImageButton = UIButton()
    let imageButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    func setup() {
        setupButtons()
        view.backgroundColor = .white
    }

    func setupButtons() {
        tileImageButton.setTitle("Tile Image", for: .normal)
        tileImageButton.setTitleColor(.purple, for: .normal)
        view.addSubview(tileImageButton)
        tileImageButton.translatesAutoresizingMaskIntoConstraints = false
        tileImageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        tileImageButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        tileImageButton.addTarget(self, action: #selector(tileImageTapped), for: .touchUpInside)

        imageButton.setTitle("Non-tile Image", for: .normal)
        imageButton.setTitleColor(.purple, for: .normal)
        view.addSubview(imageButton)
        imageButton.translatesAutoresizingMaskIntoConstraints = false
        imageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        imageButton.topAnchor.constraint(equalTo: tileImageButton.bottomAnchor, constant: 25).isActive = true
        imageButton.addTarget(self, action: #selector(imageButtonTapped), for: .touchUpInside)
    }

    @objc
    func tileImageTapped() {
        let tiledImagesFileManager = TiledImagesFileManager()
        let tiledImageViewController = TileImageViewController()
        _ = tiledImageViewController.view
        tiledImageViewController.configure(tiledImagesFileManager: tiledImagesFileManager)
        navigationController?.pushViewController(tiledImageViewController, animated: true)
    }

    @objc
    func imageButtonTapped() {
        let nonTileImageViewController = NonTileImageViewController()
        _ = nonTileImageViewController.view
        navigationController?.pushViewController(nonTileImageViewController, animated: true)
    }

}
