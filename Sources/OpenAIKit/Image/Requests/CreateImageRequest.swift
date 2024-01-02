import AsyncHTTPClient
import NIOHTTP1
import Foundation

struct CreateImageRequest: Request {
    let method: HTTPMethod = .POST
    let path = "/v1/images/generations"
    let body: Data?
    
    init(
        model: ImageModel,
        responseFormat: ResponseFormat,
        prompt: String,
        n: Int,
        size: ImageSize,
        user: String?
    ) throws {
        
        let quality: String?
        let style: String?
        
        switch model {
        case .dalle2:
            quality = nil
            style = nil
        case .dalle3(let modelQuality, let modelStyle):
            quality = modelQuality.rawValue
            style = modelStyle.rawValue
        }
        
        let body = Body(
            model: model.name,
            quality: quality,
            style: style,
            responseFormat: responseFormat.rawValue,
            prompt: prompt,
            n: n,
            size: size,
            user: user
        )
                
        self.body = try Self.encoder.encode(body)
    }
}

// MARK: - Types

public enum ImageModel {

    case dalle2
    case dalle3(quality: Quality, style: Style)

    public enum Quality: String {
        case standard
        case hd
    }
    
    public enum Style: String {
        case vivid
        case natural
    }
            
    public var name: String {
        switch self {
        case .dalle2:
            return "dall-e-2"
        case .dalle3:
            return "dall-e-3"
        }
    }
    
    public static var `default`: ImageModel { return .dalle3(quality: .standard, style: .natural) }
}

extension CreateImageRequest {
    
    enum ResponseFormat: String {
        case url = "url"
        case data = "b64_json"
    }
    
    struct Body: Encodable {
        let model: String
        let quality: String?
        let style: String?
        let responseFormat: String
        let prompt: String
        let n: Int
        let size: ImageSize
        let user: String?
    }
}
