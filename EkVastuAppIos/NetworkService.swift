import Foundation
import Combine

// MARK: - API Configuration
struct APIConfig {
    //for prod
    static let baseURL = "https://api.wajooba.xyz"
    
    //static let baseURL = "https://api.wajooba.xyz"
    static let ekshaktiBaseURL = "https://ekshakti-portal.onrender.com"
    
    static let tenantName = "m300"
    static let tidDebug = "b5YA470P7r"
    static let tidRelease = "e2EAVLLGzK"
    //for production
    //static let tenantName = "ekshakti"
    static let timeout: TimeInterval = 30.0
}

// MARK: - API Endpoints
enum APIEndpoint {
    // Authentication
    case signin
    case signup
    case googleLogin
    case tenantPing
    
    // Profile Management
    case checkProfile
    case createProfile
    case updateProfile
    
    // Property Management
    case getAllProperties
    case createProperty
    case getProperty(String)
    case updateProperty(String)
    case deleteProperty(String)
    
    // Room Management
    case createRoom(String) // propertyId
    case getRoomsInProperty(String) // propertyId
    case getRoom(String) // roomId
    case updateRoom(String) // roomId
    
    // Photo Management
    case addPhotoWithURL(String) // roomId
    case getPhotosInRoom(String) // roomId
    case deletePhoto(String) // photoId
    
    var path: String {
        switch self {
        case .signin:
            return "/public/user/signin"
        case .signup:
            return "/smobile/rest/signup"
        case .googleLogin:
            return "/smobile/rest/glogin"
        case .tenantPing:
            return "/smobile/tenant/public/ping?name=\(APIConfig.tenantName)"
            
        // Profile Management
        case .checkProfile, .createProfile, .updateProfile:
            return "/profile"
            
        // Property Management
        case .getAllProperties, .createProperty:
            return "/properties"
        case .getProperty(let id), .updateProperty(let id), .deleteProperty(let id):
            return "/properties/\(id)"
            
        // Room Management
        case .createRoom(let propertyId), .getRoomsInProperty(let propertyId):
            return "/properties/\(propertyId)/rooms"
        case .getRoom(let roomId), .updateRoom(let roomId):
            return "/rooms/\(roomId)"
            
        // Photo Management
        case .addPhotoWithURL(let roomId):
            return "/rooms/\(roomId)/photos/url"
        case .getPhotosInRoom(let roomId):
            return "/rooms/\(roomId)/photos"
        case .deletePhoto(let photoId):
            return "/photos/\(photoId)"
        }
    }
    
    var url: URL {
        switch self {
        case .tenantPing, .signup, .googleLogin:
            // Use wajooba API for tenant ping, signup, and google login
            return URL(string: APIConfig.baseURL + path)!
        case .signin:
            // Use wajooba API for signin
            return URL(string: APIConfig.baseURL + path)!
        default:
            // Use ekshakti API for profile, property, room, and photo management
            return URL(string: APIConfig.ekshaktiBaseURL + path)!
        }
    }
}

// MARK: - HTTP Methods
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

// MARK: - Network Error Types
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidRequest
    case noData
    case decodingError(Error)
    case serverError(Int, String?)
    case networkError(Error)
    case timeout
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidRequest:
            return "Invalid request data"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown error")"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .timeout:
            return "Request timeout"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}

// MARK: - Network Service
@MainActor
class NetworkService: ObservableObject {
    static let shared = NetworkService()
    
    private let session = URLSession.shared
    private let tokenManager = TokenManager.shared
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.timeout
        config.timeoutIntervalForResource = APIConfig.timeout
    }
    
    // MARK: - Tenant ID Helper
    func getCurrentTenantId() -> String {
        // If the base URL is api.wajooba.xyz, use tidDebug, otherwise use tidRelease
        if APIConfig.baseURL.contains("api.wajooba.xyz") {
            return APIConfig.tidDebug
        } else {
            return APIConfig.tidRelease
        }
    }
    
    // MARK: - Print cURL Command
    func printCurlCommand(for request: URLRequest) {
        guard let url = request.url else { return }
        
        var components = ["curl -v"]
        
        // Add HTTP method if not GET
        if let method = request.httpMethod, method != "GET" {
            components.append("-X \(method)")
        }
        
        // Add headers
        request.allHTTPHeaderFields?.forEach { key, value in
            let escapedValue = value.replacingOccurrences(of: "\"", with: "\\\"")
            components.append("-H \"\(key): \(escapedValue)\"")
        }
        
        // Add request body if present
        if let httpBody = request.httpBody, let bodyString = String(data: httpBody, encoding: .utf8) {
            let escapedBody = bodyString.replacingOccurrences(of: "\"", with: "\\\"")
            components.append("-d \"\(escapedBody)\"")
        }
        
        // Add URL
        components.append("\"\(url.absoluteString)\"")
        
        // Join all components and print
        let curlCommand = components.joined(separator: " ")
        print("📋 cURL command:\n\(curlCommand)")
    }
    
    
    // MARK: - Generic Request Method
    func request<T: Codable>(
        endpoint: APIEndpoint,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        headers: [String: String]? = nil
    ) -> AnyPublisher<T, NetworkError> {
        
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Set default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("https://marksampletest.me.com:9001", forHTTPHeaderField: "Origin")
        request.setValue("https://marksampletest.me.com:9001/", forHTTPHeaderField: "Referer")
        request.setValue("empty", forHTTPHeaderField: "Sec-Fetch-Dest")
        request.setValue("cors", forHTTPHeaderField: "Sec-Fetch-Mode")
        request.setValue("cross-site", forHTTPHeaderField: "Sec-Fetch-Site")
        request.setValue("1", forHTTPHeaderField: "Sec-GPC")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        // Add authentication header if available
        if let authHeader = tokenManager.getAuthorizationHeader() {
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        }
        
        // Add custom headers if provided
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        print("🌐 Making \(method.rawValue) request to: \(endpoint.url)")
        if let bodyData = body, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📤 Request body: \(bodyString)")
        }
        
        // Print curl command for debugging
        printCurlCommand(for: request)
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.networkError(URLError(.badServerResponse))
                }
                
                print("📥 Response status: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 Response data: \(responseString)")
                    // Detect invalid/expired JWTs and force re-auth
                    let lower = responseString.lowercased()
                    if httpResponse.statusCode >= 400 && (
                        lower.contains("signature verification failed") ||
                        lower.contains("not enough or too many segments") ||
                        (lower.contains("jwt") && lower.contains("signature") && lower.contains("failed"))
                    ) {
                        DispatchQueue.main.async {
                            TokenManager.shared.clearTokens()
                        }
                        throw NetworkError.unauthorized
                    }
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw NetworkError.unauthorized
                case 400...499:
                    let errorMessage = String(data: data, encoding: .utf8)
                    throw NetworkError.serverError(httpResponse.statusCode, errorMessage)
                case 500...599:
                    let errorMessage = String(data: data, encoding: .utf8)
                    throw NetworkError.serverError(httpResponse.statusCode, errorMessage)
                default:
                    let errorMessage = String(data: data, encoding: .utf8)
                    throw NetworkError.serverError(httpResponse.statusCode, errorMessage)
                }
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                if error is DecodingError {
                    return NetworkError.decodingError(error)
                } else if let networkError = error as? NetworkError {
                    return networkError
                } else {
                    return NetworkError.networkError(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Convenience Methods
    func get<T: Codable>(
        endpoint: APIEndpoint,
        headers: [String: String]? = nil
    ) -> AnyPublisher<T, NetworkError> {
        return request(endpoint: endpoint, method: .GET, headers: headers)
    }
    
    func post<T: Codable>(
        endpoint: APIEndpoint,
        body: Data,
        headers: [String: String]? = nil
    ) -> AnyPublisher<T, NetworkError> {
        return request(endpoint: endpoint, method: .POST, body: body, headers: headers)
    }
    
    // Direct URL request method
    func request<T: Codable>(
        url: String,
        method: HTTPMethod = .GET,
        headers: [String: String]? = nil,
        body: Data? = nil,
        responseType: T.Type
    ) -> AnyPublisher<T, Error> {
        guard let url = URL(string: url) else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Set default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication header if available
        if let authHeader = tokenManager.getAuthorizationHeader() {
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        }
        
        // Add custom headers if provided
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        print("🌐 Making \(method.rawValue) request to: \(url)")
        if let bodyData = body, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📤 Request body: \(bodyString)")
        }
        
        // Print curl command for debugging
        printCurlCommand(for: request)
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.networkError(URLError(.badServerResponse))
                }
                
                print("📥 Response status: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 Response data: \(responseString)")
                    // Detect invalid/expired JWTs and force re-auth
                    let lower = responseString.lowercased()
                    if httpResponse.statusCode >= 400 && (
                        lower.contains("signature verification failed") ||
                        lower.contains("not enough or too many segments") ||
                        (lower.contains("jwt") && lower.contains("signature") && lower.contains("failed"))
                    ) {
                        DispatchQueue.main.async {
                            TokenManager.shared.clearTokens()
                        }
                        throw NetworkError.unauthorized
                    }
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw NetworkError.unauthorized
                case 400...499:
                    let errorMessage = String(data: data, encoding: .utf8)
                    throw NetworkError.serverError(httpResponse.statusCode, errorMessage)
                case 500...599:
                    let errorMessage = String(data: data, encoding: .utf8)
                    throw NetworkError.serverError(httpResponse.statusCode, errorMessage)
                default:
                    let errorMessage = String(data: data, encoding: .utf8)
                    throw NetworkError.serverError(httpResponse.statusCode, errorMessage)
                }
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                if error is DecodingError {
                    return NetworkError.decodingError(error)
                } else if let networkError = error as? NetworkError {
                    return networkError
                } else {
                    return NetworkError.networkError(error)
                }
            }
            .eraseToAnyPublisher()
    }
}
