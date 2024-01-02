import AsyncHTTPClient
import NIO
import NIOHTTP1
import NIOFoundationCompat
import Foundation

struct NIORequestHandler: RequestHandler {
    let httpClient: HTTPClient
    let configuration: Configuration
    let decoder: JSONDecoder
    
    init(
        httpClient: HTTPClient,
        configuration: Configuration,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.httpClient = httpClient
        self.configuration = configuration
        self.decoder = decoder
    }
    
    func perform<T: Decodable>(request: Request) async throws -> T {
        var headers = configuration.headers
        
        headers.add(contentsOf: request.headers)
        
        let url = try generateURL(for: request)
        
        let body: HTTPClient.Body? = {
            guard let data = request.body else { return nil }
            return .data(data)
        }()
        
        let response = try await httpClient.execute(
            request: HTTPClient.Request(
                url: url,
                method: request.method,
                headers: headers,
                body: body
            )
        ).get()
        
        
        guard var byteBuffer = response.body else {
            throw RequestHandlerError.responseBodyMissing
        }
        
        var data = Data()
        let bytes = byteBuffer.readBytes(length: byteBuffer.readableBytes)
        bytes.flatMap { data.append(contentsOf: $0) }

        decoder.keyDecodingStrategy = request.keyDecodingStrategy
        decoder.dateDecodingStrategy = request.dateDecodingStrategy

        // Debug
        if AnyDecodableHelper.environmentVariable != nil {
            print("==================================================================")
            print("Parsing response for path: \(request.path)")
            print("------------------------------------------------------------------")
            do {
                let anyDecodable = try decoder.decode(AnyDecodableDictionary.self, from: data)
                AnyDecodableHelper.printKeys(for: anyDecodable)
            } catch {
                print("failed to debug decode -> \(error)")
            }
            print("==================================================================\n")
        }

        // Data
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw try decoder.decode(APIErrorResponse.self, from: data)
        }
    }
    
    func stream<T: Decodable>(request: Request) async throws -> AsyncThrowingStream<T, Error> {
        
        let url = try generateURL(for: request)
        
        var httpClientRequest = HTTPClientRequest(url: url)
        
        httpClientRequest.headers.add(contentsOf: configuration.headers)
        httpClientRequest.headers.add(contentsOf: request.headers)
        
        httpClientRequest.method = request.method

        if let body = request.body {
            httpClientRequest.body = .bytes(body)
        }
        
        decoder.keyDecodingStrategy = request.keyDecodingStrategy
        decoder.dateDecodingStrategy = request.dateDecodingStrategy
        
        let response = try await httpClient.execute(httpClientRequest, timeout: .seconds(25))
        
        return AsyncThrowingStream<T, Error> { continuation in
            Task(priority: .userInitiated) {
                do {
                    for try await buffer in response.body {
                        String(buffer: buffer)
                            .components(separatedBy: "data: ")
                            .filter { $0 != "data: " }
                            .compactMap {
                                guard let data = $0.data(using: .utf8) else { return nil }
                                return try? decoder.decode(T.self, from: data)
                            }
                            .forEach { value in
                                continuation.yield(value)
                            }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

}
