
import UIKit

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

    required init(tileManager: TileManager) {
        self.tileManager = tileManager

        super.init(frame: tileManager.imageFrame)
        backgroundColor = .yellow

        configureTiledLayer()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        self.tileBounds = bounds
    }

    func configureTiledLayer() {
        guard let tiledLayer = layer as? CATiledLayer else { return }
        tiledLayer.levelsOfDetail = 7
        tiledLayer.levelsOfDetailBias = 3
        tiledLayer.tileSize = tileSize
    }

    func clearImageCache() {
        tileManager.clearImageCache()
    }

    override func draw(_ rect: CGRect) {
        guard let currentContext = UIGraphicsGetCurrentContext(),
            let tileBounds = tileBounds, tileBounds != CGRect.zero else { return }

        let scale: CGFloat = currentContext.ctm.a
        var tileSize = self.tileSize
        tileSize.width /= scale
        tileSize.height /= scale

        let firstCol = Int(floor(rect.minX / tileSize.width))
        let lastCol = Int(floor((rect.maxX - 1) / tileSize.width))
        let firstRow = Int(floor(rect.minY / tileSize.height))
        let lastRow = Int(floor((rect.maxY - 1) / tileSize.height))

        guard lastRow >= firstRow && lastCol >= firstCol else { return }

        for row in firstRow...lastRow {
            for col in firstCol...lastCol {
                guard let tile = tileManager.tileFor(size: tileSize, scale: scale, rect: rect, row: row, col: col) else { return }

                var tileRect = CGRect(x: tileSize.width * CGFloat(col), y: tileSize.height * CGFloat(row), width: tileSize.width, height: tileSize.height)
                tileRect = tileBounds.intersection(tileRect)
                tile.draw(in: tileRect)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
