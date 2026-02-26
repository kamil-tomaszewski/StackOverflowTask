import Foundation

struct StackOverflowUsersResponse: Decodable, Sendable {
    let items: [StackOverflowUser]
}

struct StackOverflowUser: Decodable, nonisolated Hashable, Sendable {
    let userId: Int
    let displayName: String
    let reputation: Int
    let location: String?
    let profileImage: URL?
}

protocol UsersRepository {
    func fetchUsers(page: Int, pageSize: Int) async throws -> [StackOverflowUser]
}

enum UsersRepositoryError: LocalizedError {
    case invalidURL
    case badStatusCode(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Failed to create users endpoint URL."
        case .badStatusCode(let statusCode):
            return "Request failed with status code \(statusCode)."
        }
    }
}

final class NetworkUsersRepository: UsersRepository {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchUsers(page: Int = 1, pageSize: Int = 30) async throws -> [StackOverflowUser] {
        guard var components = URLComponents(string: "https://api.stackexchange.com/2.3/users") else {
            throw UsersRepositoryError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "pagesize", value: "\(pageSize)"),
            URLQueryItem(name: "order", value: "desc"),
            URLQueryItem(name: "sort", value: "reputation"),
            URLQueryItem(name: "site", value: "stackoverflow")
        ]

        guard let url = components.url else {
            throw UsersRepositoryError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw UsersRepositoryError.badStatusCode(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(StackOverflowUsersResponse.self, from: data).items
    }
}
