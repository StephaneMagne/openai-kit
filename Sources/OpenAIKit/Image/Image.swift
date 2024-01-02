import Foundation

public struct ImageURL: Decodable {
    public let url: String
}

public struct ImageData: Decodable {
    public let b64Json: Data
}

public enum ImageSize: String, Codable {
    case twoFiftySix = "256x256"
    case fiveTwelve = "512x512"
    case tenTwentyFour = "1024x1024"
    case seventeenNinetyTwoPortrait = "1024x1792"
    case seventeenNinetyTwoLandscape = "1792x1024"
}
