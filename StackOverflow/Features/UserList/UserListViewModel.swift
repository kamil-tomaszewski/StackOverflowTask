import Foundation

struct UserListRow: nonisolated Hashable, Sendable {
    let user: StackOverflowUser
    let isFollowed: Bool
}

@MainActor
final class UserListViewModel {
    enum ViewState: Sendable {
        case idle
        case loading
        case loaded([UserListRow], Bool)
        case error(String)
    }

    private let repository: UsersRepository
    private let storage: UserDefaults
    private let followedUserIDsKey = "followed_user_ids"
    private var users: [StackOverflowUser] = []
    private var followedUserIDs: Set<Int>
    private(set) var state: ViewState = .idle {
        didSet { onStateChanged?(state) }
    }

    var onStateChanged: ((ViewState) -> Void)?

    init(repository: UsersRepository, storage: UserDefaults = .standard) {
        self.repository = repository
        self.storage = storage
        self.followedUserIDs = Set(storage.array(forKey: followedUserIDsKey) as? [Int] ?? [])
    }

    func loadUsers(page: Int = 1, pageSize: Int = 30) async {
        state = .loading
        do {
            users = try await repository.fetchUsers(page: page, pageSize: pageSize)
            publishLoadedState()
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func toggleFollow(userID: Int) {
        if followedUserIDs.contains(userID) {
            followedUserIDs.remove(userID)
        } else {
            followedUserIDs.insert(userID)
        }
        persistFollowedIDs()
        publishLoadedState(isUpdating: true)
    }

    private func persistFollowedIDs() {
        storage.set(Array(followedUserIDs), forKey: followedUserIDsKey)
    }

    private func publishLoadedState(isUpdating: Bool = false) {
        let rows = users.map { user in
            UserListRow(user: user, isFollowed: followedUserIDs.contains(user.userId))
        }
        state = .loaded(rows, !isUpdating)
    }
}
