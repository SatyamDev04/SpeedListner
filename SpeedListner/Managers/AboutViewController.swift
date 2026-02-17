import UIKit

final class AboutViewController: UIViewController {

    private let logoImageView = UIImageView()
    private let versionLabel = UILabel()
    private let founderLabel = UILabel()
    private let backButton = UIButton(type: .system)
    private let headerView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // MARK: Header
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        // 🔹 System back icon
        let backImage = UIImage(systemName: "chevron.left")
        backButton.setImage(backImage, for: .normal)
        backButton.tintColor = .label
        backButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false

        headerView.addSubview(backButton)

        // MARK: Logo
        logoImageView.image = UIImage(named: "1024")
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false

        // MARK: Version
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        versionLabel.text = "Version \(version)"
        versionLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        versionLabel.textAlignment = .center

        // MARK: Founder
        founderLabel.text = "Founder: Chris Jameson"
        founderLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        founderLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [
            logoImageView,
            versionLabel,
            founderLabel
        ])
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        // MARK: Constraints
        NSLayoutConstraint.activate([
            
            // Header
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10), // 🔥 10px niche
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 44),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            // Logo
            logoImageView.heightAnchor.constraint(equalToConstant: 120),
            logoImageView.widthAnchor.constraint(equalToConstant: 120),

            // Stack
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
