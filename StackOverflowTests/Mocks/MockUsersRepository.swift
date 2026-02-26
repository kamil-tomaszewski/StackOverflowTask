import Testing
@testable import StackOverflow

struct MockUsersRepository: UsersRepository {
    enum ResultType {
        case success([StackOverflowUser])
        case failure(Error)
    }

    var result: ResultType

    func fetchUsers(page: Int, pageSize: Int) async throws -> [StackOverflowUser] {
        switch result {
        case .success(let users):
            return users
        case .failure(let error):
            throw error
        }
    }
}
