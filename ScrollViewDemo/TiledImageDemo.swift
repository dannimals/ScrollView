
import UIKit

struct TiledImageDemo {

    static func dataCacheDirectoryURL(forUserWithID id: String) -> URL? {
        return TiledImageDemo.dataCacheDirectoryBaseURL?.appendingPathComponent(id)
    }
    static let demoImageURL = URL(string: "https://frameio-assets-production.s3-accelerate.amazonaws.com/image/c8f99f0f-7475-4499-b068-d1b3a267f27e/image_high.jpg?x-amz-meta-project_id=1338b3bb-8471-4380-9a04-fe3e27a9ac29&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIHKSS2IP3JTIPKYQ%2F20181124%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20181124T182608Z&X-Amz-Expires=172800&X-Amz-SignedHeaders=host&X-Amz-Signature=a3d6d6a1171c8ad70eb2a8bd07cd80a70026e4b96033e98535f78d244747c97c")
    static let lowResolutionDemoImage = #imageLiteral(resourceName: "galaxy-smaller")

    private static let cachesDirectoryURL: URL? = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    private static let dataCacheDirectoryName: String = "com.TiledImageDemo.DataCache"
    private static let dataCacheDirectoryBaseURL: URL? = cachesDirectoryURL?.appendingPathComponent(dataCacheDirectoryName)

}
