import Foundation
import Combine

final class VastuService: ObservableObject {
    static let shared = VastuService()
    private let network = NetworkService.shared
    private let roomService = RoomService.shared
    private var cancellables = Set<AnyCancellable>()
    private init() {}

    // GET /room/questions/{ROOM_ID}
    func getRoomQuestions(roomId: String, completion: @escaping (Result<RoomQuestionsResponse, NetworkError>) -> Void) {
        let url = APIConfig.ekshaktiBaseURL + "/room/questions/\(roomId)"
        network.request(url: url, method: .GET, headers: ["Content-Type": "application/json"], body: nil, responseType: RoomQuestionsResponse.self)
            .sink { comp in
                switch comp {
                case .finished: break
                case .failure(let err):
                    if let nerr = err as? NetworkError { completion(.failure(nerr)) } else { completion(.failure(.networkError(err))) }
                }
            } receiveValue: { resp in
                completion(.success(resp))
            }
            .store(in: &cancellables)
    }

    // POST /room/{ROOM_ID}/questions
    func submitRoomAnswers(roomId: String, answers: [RoomAnswerItem], completion: @escaping (Result<SubmitRoomAnswersResponse, NetworkError>) -> Void) {
        let url = APIConfig.ekshaktiBaseURL + "/room/\(roomId)/questions"
        let payload = SubmitRoomAnswersRequest(answers: answers)
        guard let body = try? JSONEncoder().encode(payload) else { completion(.failure(.invalidRequest)); return }
        network.request(url: url, method: .POST, headers: ["Content-Type": "application/json"], body: body, responseType: SubmitRoomAnswersResponse.self)
            .sink { comp in
                switch comp {
                case .finished: break
                case .failure(let err):
                    if let nerr = err as? NetworkError { completion(.failure(nerr)) } else { completion(.failure(.networkError(err))) }
                }
            } receiveValue: { resp in
                completion(.success(resp))
            }
            .store(in: &cancellables)
    }

    // GET /room/{ROOM_ID}/vastuscore
    func getRoomVastuScore(roomId: String, completion: @escaping (Result<RoomVastuScoreResponse, NetworkError>) -> Void) {
        let url = APIConfig.ekshaktiBaseURL + "/room/\(roomId)/vastuscore"
        network.request(url: url, method: .GET, headers: ["Content-Type": "application/json"], body: nil, responseType: RoomVastuScoreResponse.self)
            .sink { comp in
                switch comp {
                case .finished: break
                case .failure(let err):
                    if let nerr = err as? NetworkError { completion(.failure(nerr)) } else { completion(.failure(.networkError(err))) }
                }
            } receiveValue: { resp in
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