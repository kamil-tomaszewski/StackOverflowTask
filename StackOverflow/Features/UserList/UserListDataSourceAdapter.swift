import UIKit

private enum UserListSection: nonisolated Hashable, Sendable {
    case main
}

actor ProfileImageLoader {
    static let shared = ProfileImageLoader()
    private let cache = NSCache<NSURL, UIImage>()

    func image(from url: URL) async -> UIImage? {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let image = UIImage(data: data) else {
                return nil
            }

            cache.setObject(image, forKey: url as NSURL)
            return image
        } catch {
            return nil
        }
    }
}

@MainActor
final class UserListDataSourceAdapter {
    private weak var tableView: UITableView!
    private let onToggleFollow: (Int) -> Void
    private lazy var dataSource: UITableViewDiffableDataSource<UserListSection, UserListRow> = {
        UITableViewDiffableDataSource<UserListSection, UserListRow>(tableView: tableView) {
            tableView, indexPath, row in
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: UserListTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? UserListTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(with: row) {
                self.onToggleFollow(row.user.userId)
            }
            return cell
        }
    }()

    init(tableView: UITableView, onToggleFollow: @escaping (Int) -> Void) {
        self.tableView = tableView
        self.onToggleFollow = onToggleFollow
        tableView.register(UserListTableViewCell.self, forCellReuseIdentifier: UserListTableViewCell.reuseIdentifier)
    }

    func apply(rows: [UserListRow], animatingDifferences: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<UserListSection, UserListRow>()
        snapshot.appendSections([.main])
        snapshot.appendItems(rows, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
}
