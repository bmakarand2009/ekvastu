import Foundation
import Combine

@MainActor
final class VastuService: ObservableObject {
    static let shared = VastuService()
    private let network = NetworkService.shared
    private let roomService = RoomService.shared
    private var cancellables = Set<AnyCancellable>()
    private init() {}
    
    // MARK: - Debug helpers
    private func maskToken(_ token: String) -> String {
        let trimmed = token.replacingOccurrences(of: "Bearer ", with: "")
        guard trimmed.count > 16 else { return "***" }
        let start = trimmed.prefix(8)
        let end = trimmed.suffix(8)
        return "Bearer \(start)...\(end)"
    }
    
    private func prettyJSON<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(value), let str = String(data: data, encoding: .utf8) {
            return str
        }
        return String(describing: value)
    }

    // GET /room/questions/{ROOM_ID}
    func getRoomQuestions(roomId: String, completion: @escaping (Result<RoomQuestionsResponse, NetworkError>) -> Void) {
        let url = APIConfig.ekshaktiBaseURL + "/room/questions/\(roomId)"
        
        // Debug: log request
        let authHeader = TokenManager.shared.getAuthorizationHeader() ?? ""
        print("🧭 VastuService.getRoomQuestions -> REQUEST")
        print("  URL: \(url)")
        print("  Method: GET")
        print("  Headers: Content-Type: application/json, Authorization: \(maskToken(authHeader))")
        
        network.request(url: url, method: .GET, headers: ["Content-Type": "application/json"], body: nil, responseType: RoomQuestionsResponse.self)
            .sink { comp in
                switch comp {
                case .finished: break
                case .failure(let err):
                    print("🧭 VastuService.getRoomQuestions -> ERROR: \(err.localizedDescription)")
                    if let nerr = err as? NetworkError { completion(.failure(nerr)) } else { completion(.failure(.networkError(err))) }
                }
            } receiveValue: { resp in
                print("🧭 VastuService.getRoomQuestions -> RESPONSE: \(resp)")
                print("  success: \(resp.success), count: \(resp.count)")
                completion(.success(resp))
            }
            .store(in: &cancellables)
    }

    // POST /room/{ROOM_ID}/questions
    func submitRoomAnswers(roomId: String, answers: [RoomAnswerItem], completion: @escaping (Result<SubmitRoomAnswersResponse, NetworkError>) -> Void) {
        let url = APIConfig.ekshaktiBaseURL + "/room/\(roomId)/questions"
        let payload = SubmitRoomAnswersRequest(answers: answers)
        guard let body = try? JSONEncoder().encode(payload) else { completion(.failure(.invalidRequest)); return }
        
        // Debug: log request
        let authHeader = TokenManager.shared.getAuthorizationHeader() ?? ""
        print("🧭 VastuService.submitRoomAnswers -> REQUEST")
        print("  URL: \(url)")
        print("  Method: POST")
        print("  Headers: Content-Type: application/json, Authorization: \(maskToken(authHeader))")
        print("  Body: \n\(prettyJSON(payload))")
        
        network.request(url: url, method: .POST, headers: ["Content-Type": "application/json"], body: body, responseType: SubmitRoomAnswersResponse.self)
            .sink { comp in
                switch comp {
                case .finished: break
                case .failure(let err):
                    print("🧭 VastuService.submitRoomAnswers -> ERROR: \(err.localizedDescription)")
                    if let nerr = err as? NetworkError { completion(.failure(nerr)) } else { completion(.failure(.networkError(err))) }
                }
            } receiveValue: { resp in
                print("🧭 VastuService.submitRoomAnswers -> RESPONSE: \(resp)")
                completion(.success(resp))
            }
            .store(in: &cancellables)
    }

    // GET /room/{ROOM_ID}/vastuscore
    func getRoomVastuScore(roomId: String, completion: @escaping (Result<RoomVastuScoreResponse, NetworkError>) -> Void) {
        let url = APIConfig.ekshaktiBaseURL + "/room/\(roomId)/vastuscore"
        
        // Debug: log request
        let authHeader = TokenManager.shared.getAuthorizationHeader() ?? ""
        print("🧭 VastuService.getRoomVastuScore -> REQUEST")
        print("  URL: \(url)")
        print("  Method: GET")
        print("  Headers: Content-Type: application/json, Authorization: \(maskToken(authHeader))")
        
        network.request(url: url, method: .GET, headers: ["Content-Type": "application/json"], body: nil, responseType: RoomVastuScoreResponse.self)
            .sink { comp in
                switch comp {
                case .finished: break
                case .failure(let err):
                    print("🧭 VastuService.getRoomVastuScore -> ERROR: \(err.localizedDescription)")
                    if let nerr = err as? NetworkError { completion(.failure(nerr)) } else { completion(.failure(.networkError(err))) }
                }
            } receiveValue: { resp in
                print("🧭 VastuService.getRoomVastuScore -> RESPONSE: \(resp)")
                print("  success: \(resp.success)")
                print("  data.room_id: \(resp.data.room_id)")
                print("  data.score/max: \(resp.data.score)/\(resp.data.maxScore) (\(resp.data.displayPercentage)%)")
                print("  data.room_name: \(resp.data.room_name ?? "nil")")
                print("  data.analysis: \(resp.data.analysis ?? "nil")")
                print("  data.calculated_at: \(resp.data.calculated_at ?? "nil")")
                if let msg = resp.message { print("  message: \(msg)") }
                completion(.success(resp))
            }
            .store(in: &cancellables)
    }
    
    // Get room details including property ID
    func getRoomDetails(roomId: String, completion: @escaping (Result<RoomData, NetworkError>) -> Void) {
        print("🔍 Getting room details for room ID: \(roomId)")
        roomService.getRoom(id: roomId) { result in
            switch result {
            case .success(let response):
                if let roomData = response.data {
                    print("✅ Got room details for room ID: \(roomId), property ID: \(roomData.propertyId)")
                    completion(.success(roomData))
                } else {
                    print("❌ Room data not found for room ID: \(roomId)")
                    completion(.failure(.noData))
                }
            case .failure(let error):
                print("❌ Failed to get room details: \(error)")
                completion(.failure(error))
            }
        }
    }
}