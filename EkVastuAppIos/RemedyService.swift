import Foundation
import Combine

@MainActor
class RemedyService {
    private let networkService = NetworkService.shared
    private let baseURL = "https://ekshakti-portal.onrender.com"
    
    func fetchRemedies() -> AnyPublisher<[Remedy], Error> {
        let endpoint = "\(baseURL)/remedies"
        
        return networkService.request(
            url: endpoint,
            method: .GET,
            headers: [:],
            body: nil,
            responseType: [Remedy].self
        )
    }
    
    func fetchRemedyDetails(id: String) -> AnyPublisher<Remedy, Error> {
        let endpoint = "\(baseURL)/remedies/\(id)"
        
        return networkService.request(
            url: endpoint,
            method: .GET,
            headers: [:],
            body: nil,
            responseType: Remedy.self
        )
    }
    
    func fetchRemediesByRoom(roomType: String) -> AnyPublisher<[Remedy], Error> {
        let endpoint = "\(baseURL)/remedies?roomType=\(roomType)"
        
        return networkService.request(
            url: endpoint,
            method: .GET,
            headers: [:],
            body: nil,
            responseType: [Remedy].self
        )
    }
    
    func fetchRemediesByIssue(issueType: String) -> AnyPublisher<[Remedy], Error> {
        let endpoint = "\(baseURL)/remedies?issueType=\(issueType)"
        
        return networkService.request(
            url: endpoint,
            method: .GET,
            headers: [:],
            body: nil,
            responseType: [Remedy].self
        )
    }
}
