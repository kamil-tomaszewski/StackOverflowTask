import UIKit

final class UserListViewController: UIViewController {
    private let viewModel: UserListViewModel
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private var dataSourceAdapter: UserListDataSourceAdapter?

    init(viewModel: UserListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported. Use init(viewModel:) instead.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "StackOverflow Users"
        view.backgroundColor = .systemBackground

        configureTableView()
        configureDataSource()
        bindViewModel()
        loadUsers()
    }

    private func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.estimatedRowHeight = 60
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureDataSource() {
        dataSourceAdapter = UserListDataSourceAdapter(
            tableView: tableView,
            onToggleFollow: { [weak self] userID in
                self?.viewModel.toggleFollow(userID: userID)
            }
        )
    }

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] state in
            self?.render(state)
        }
    }

    private func loadUsers() {
        Task { [weak self] in
            await self?.viewModel.loadUsers()
        }
    }

    private func render(_ state: UserListViewModel.ViewState) {
        switch state {
        case .idle:
            break
        case .loading:
            refreshControl.endRefreshing()
            loadingIndicator.startAnimating()
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingIndicator)
        case let .loaded(rows, withAnimation):
            refreshControl.endRefreshing()
            loadingIndicator.stopAnimating()
            navigationItem.rightBarButtonItem = nil
            dataSourceAdapter?.apply(rows: rows, animatingDifferences: withAnimation)
        case .error(let message):
            refreshControl.endRefreshing()
            loadingIndicator.stopAnimating()
            navigationItem.rightBarButtonItem = nil
            showErrorAlert(message: message)
        }
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.loadUsers()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc
    private func didPullToRefresh() {
        loadUsers()
    }
}
