import Foundation
import Testing
@testable import StackOverflow

// MARK: - Test Doubles
private enum DummyError: Error, LocalizedError {
    case somethingWentWrong

    var errorDescription: String? { "somethingWentWrong" }
}

private func makeUser(id: Int, name: String = "User", reputation: Int = 1, image: URL? = nil) -> StackOverflowUser {
    StackOverflowUser(userId: id, displayName: name + "\(id)", reputation: reputation, location: nil, profileImage: image)
}

private func freshUserDefaults(suiteName: String = UUID().uuidString) -> UserDefaults {
    // Use an ephemeral suite so tests don't leak to each other
    let ud = UserDefaults(suiteName: suiteName)!
    ud.removePersistentDomain(forName: suiteName)
    return ud
}

// MARK: - Tests

@Suite("UserListViewModel")
struct UserListViewModelTests {

    @Test("initial state is idle and callback is invoked on state changes")
    @MainActor
    func initialStateAndCallback() async throws {
        let repo = MockUsersRepository(result: .success([]))
        let storage = freshUserDefaults()
        let vm = UserListViewModel(repository: repo, storage: storage)

        // initial state
        #expect({ if case .idle = vm.state { true } else { false } }())

        var observedStates: [UserListViewModel.ViewState] = []
        vm.onStateChanged = { observedStates.append($0) }

        await vm.loadUsers(page: 1, pageSize: 2)

        // We expect at least .loading then .loaded([], true)
        #expect(observedStates.count == 2)
        #expect({ if case .loading = observedStates.first { true } else { false } }())
        #expect({ if case .loaded(let rows, let animated) = observedStates.last { rows.isEmpty && animated } else { false } }())
    }

    @Test("loadUsers publishes loaded state with rows")
    @MainActor
    func loadUsersSuccess() async throws {
        let users = [makeUser(id: 1, reputation: 10), makeUser(id: 2, reputation: 20)]
        let repo = MockUsersRepository(result: .success(users))
        let storage = freshUserDefaults()
        let vm = UserListViewModel(repository: repo, storage: storage)

        var lastState: UserListViewModel.ViewState?
        vm.onStateChanged = { lastState = $0 }

        await vm.loadUsers(page: 1, pageSize: 30)

        guard case .loaded(let rows, let animated)? = lastState else {
            Issue.record("Expected loaded state")
            return
        }
        #expect(animated)
        #expect(rows.count == 2)
        #expect(rows[0].user.userId == 1 && rows[0].isFollowed == false)
        #expect(rows[1].user.userId == 2 && rows[1].isFollowed == false)
    }

    @Test("loadUsers failure publishes error state")
    @MainActor
    func loadUsersFailure() async throws {
        let repo = MockUsersRepository(result: .failure(DummyError.somethingWentWrong))
        let storage = freshUserDefaults()
        let vm = UserListViewModel(repository: repo, storage: storage)

        var lastState: UserListViewModel.ViewState?
        vm.onStateChanged = { lastState = $0 }

        await vm.loadUsers()

        guard case .error(let message)? = lastState else {
            Issue.record("Expected error state")
            return
        }
        #expect(message == DummyError.somethingWentWrong.localizedDescription)
    }

    @Test("toggleFollow toggles and persists, then publishes loaded without animation")
    @MainActor
    func toggleFollowPersistsAndUpdates() async throws {
        let users = [makeUser(id: 1), makeUser(id: 2)]
        let repo = MockUsersRepository(result: .success(users))
        let storage = freshUserDefaults()
        let vm = UserListViewModel(repository: repo, storage: storage)

        var observed: [UserListViewModel.ViewState] = []
        vm.onStateChanged = { observed.append($0) }

        await vm.loadUsers()
        // Now toggle follow for user 1
        vm.toggleFollow(userID: 1)

        // Last state should be loaded with animation false
        guard case .loaded(let rows, let animated) = observed.last! else {
            Issue.record("Expected loaded state after toggle")
            return
        }
        #expect(animated == false)
        #expect(rows.count == 2)
        #expect(rows.first { $0.user.userId == 1 }?.isFollowed == true)
        #expect(rows.first { $0.user.userId == 2 }?.isFollowed == false)

        // Verify persistence
        let saved = Set(storage.array(forKey: "followed_user_ids") as? [Int] ?? [])
        #expect(saved.contains(1))

        // Toggle again to unfollow
        vm.toggleFollow(userID: 1)
        let savedAfter = Set(storage.array(forKey: "followed_user_ids") as? [Int] ?? [])
        #expect(savedAfter.contains(1) == false)
    }
}
