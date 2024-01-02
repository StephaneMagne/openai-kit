import Foundation

public struct ImageURLResponse: Decodable {
    public let created: Date
    public let data: [ImageURL]
}

public struct ImageDataResponse: Decodable {
    public let created: Date
    public let data: [ImageData]
}
