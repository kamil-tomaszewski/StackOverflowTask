import UIKit

final class UserListTableViewCell: UITableViewCell {
    static let reuseIdentifier = "UserListTableViewCell"

    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let detailsLabel = UILabel()
    private let labelsStackView = UIStackView()
    private let followButton = UIButton(type: .system)

    private var imageTask: Task<Void, Never>?
    private var onFollowTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureLayout()
        configureFollowButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        onFollowTapped = nil
        avatarImageView.image = nil
        nameLabel.text = nil
        detailsLabel.text = nil
        followButton.setTitle("", for: .normal)
    }

    func configure(with row: UserListRow, onFollowTapped: @escaping () -> Void) {
        self.onFollowTapped = onFollowTapped

        avatarImageView.image = UIImage(systemName: "person.crop.circle")
        nameLabel.text = row.user.displayName
        detailsLabel.text = "Reputation: \(row.user.reputation)"

        followButton.setTitle(row.isFollowed ? "Following" : "Follow", for: .normal)

        imageTask?.cancel()
        guard let imageURL = row.user.profileImage else { return }
        imageTask = Task { [weak self] in
            guard let image = await ProfileImageLoader.shared.image(from: imageURL),
                  !Task.isCancelled else { return }
            self?.avatarImageView.image = image
        }
    }

    private func configureLayout() {
        selectionStyle = .none

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.image = UIImage(systemName: "person.crop.circle")
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 22
        avatarImageView.tintColor = .secondaryLabel

        nameLabel.font = .preferredFont(forTextStyle: .body)
        nameLabel.numberOfLines = 1

        detailsLabel.font = .preferredFont(forTextStyle: .caption1)
        detailsLabel.textColor = .secondaryLabel
        detailsLabel.numberOfLines = 2

        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        labelsStackView.axis = .vertical
        labelsStackView.spacing = 2
        labelsStackView.addArrangedSubview(nameLabel)
        labelsStackView.addArrangedSubview(detailsLabel)

        contentView.addSubview(avatarImageView)
        contentView.addSubview(labelsStackView)
        contentView.addSubview(followButton)

        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 44),
            avatarImageView.heightAnchor.constraint(equalToConstant: 44),

            followButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            followButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            labelsStackView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            labelsStackView.trailingAnchor.constraint(lessThanOrEqualTo: followButton.leadingAnchor, constant: -12),
            labelsStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            labelsStackView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 8),
            labelsStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    private func configureFollowButton() {
        followButton.translatesAutoresizingMaskIntoConstraints = false
        followButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        followButton.setContentHuggingPriority(.required, for: .horizontal)
        followButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        followButton.addTarget(self, action: #selector(handleFollowButtonTapped), for: .touchUpInside)
    }

    @objc
    private func handleFollowButtonTapped() {
        onFollowTapped?()
    }
}
