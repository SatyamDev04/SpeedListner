import UIKit
import EasyTipView

final class SpeedTrackViewController: UIViewController, UITabBarControllerDelegate {
    
    @IBOutlet weak var cardBGView:UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    private let scrollView = UIScrollView()
    private let cardView = UIView()
    private let thlLabel = UILabel()
    private let categoryLabel = UILabel()
    private let materialLabel = UILabel()
    private let streakLabel = UILabel()
    private let mrasLabel = UILabel()
    private let mratLabel = UILabel()
    private let pledgeLabel = UILabel()
    private let pledgeInfoButton = UIButton()
    private let pledgeRow = UIStackView()
    private var tipView: EasyTipView?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "SpeedTrack"
        tabBarController?.delegate = self
        setupTopBar()
        setupUI()
        applyAppearance()
        renderStats()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.tintColor = .white
        showSpeedTrackTopBadge()
        applyAppearance()
        renderStats()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            applyAppearance()
            renderStats()
        }
    }

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.layer.cornerRadius = 18
        cardView.clipsToBounds = true

        [thlLabel, categoryLabel, materialLabel, streakLabel, mrasLabel, mratLabel, pledgeLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.numberOfLines = 0
            $0.textColor = .label
            cardView.addSubview($0)
        }

        thlLabel.font = .systemFont(ofSize: 40, weight: .semibold)
        thlLabel.textAlignment = .center
        categoryLabel.font = .systemFont(ofSize: 16, weight: .regular)
        categoryLabel.textAlignment = .center
        materialLabel.font = .systemFont(ofSize: 16, weight: .regular)
        materialLabel.textAlignment = .center
        streakLabel.font = .systemFont(ofSize: 17, weight: .regular)
        mrasLabel.font = .systemFont(ofSize: 17, weight: .regular)
        mratLabel.font = .systemFont(ofSize: 17, weight: .regular)
        pledgeLabel.font = .systemFont(ofSize: 18, weight: .regular)
        let infoImage = UIImage(named: "ep_info-filled 2")?.withRenderingMode(.alwaysTemplate)
        pledgeInfoButton.setImage(infoImage, for: .normal)
        pledgeInfoButton.imageView?.contentMode = .scaleAspectFit
        pledgeInfoButton.contentHorizontalAlignment = .fill
        pledgeInfoButton.contentVerticalAlignment = .fill
        pledgeInfoButton.widthAnchor.constraint(equalToConstant: 20).isActive = true
        pledgeInfoButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        pledgeInfoButton.addTarget(self, action: #selector(showPledgeInfo), for: .touchUpInside)
        pledgeInfoButton.setContentHuggingPriority(.required, for: .horizontal)
        pledgeInfoButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        pledgeRow.translatesAutoresizingMaskIntoConstraints = false
        pledgeRow.axis = .horizontal
        pledgeRow.alignment = .center
        pledgeRow.spacing = 4
        pledgeRow.addArrangedSubview(pledgeLabel)
        pledgeRow.addArrangedSubview(pledgeInfoButton)
        cardView.addSubview(pledgeRow)

        cardBGView.addSubview(cardView)
        

        NSLayoutConstraint.activate([
        

            cardView.leadingAnchor.constraint(equalTo: cardBGView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: cardBGView.trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: cardBGView.topAnchor, constant: 14),
            cardView.bottomAnchor.constraint(equalTo: cardBGView.bottomAnchor, constant: -16),
            cardView.widthAnchor.constraint(equalTo: cardBGView.widthAnchor, constant: -32),

            thlLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 26),
            thlLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            thlLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            categoryLabel.topAnchor.constraint(equalTo: thlLabel.bottomAnchor, constant: 12),
            categoryLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            categoryLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            materialLabel.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 6),
            materialLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            materialLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            streakLabel.topAnchor.constraint(equalTo: materialLabel.bottomAnchor, constant: 30),
            streakLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            streakLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),

            mrasLabel.topAnchor.constraint(equalTo: streakLabel.bottomAnchor, constant: 30),
            mrasLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            mrasLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),

            mratLabel.topAnchor.constraint(equalTo: mrasLabel.bottomAnchor, constant: 30),
            mratLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            mratLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),

            pledgeRow.topAnchor.constraint(equalTo: mratLabel.bottomAnchor, constant: 36),
            pledgeRow.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            pledgeRow.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20)
        ])
    }

    private func applyAppearance() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark

        view.backgroundColor = isDarkMode
            ? UIColor(red: 0.055, green: 0.035, blue: 0.075, alpha: 1)
            : UIColor(red: 0.32, green: 0.13, blue: 0.47, alpha: 1)
        cardBGView.backgroundColor = isDarkMode
            ? UIColor(red: 0.055, green: 0.035, blue: 0.075, alpha: 1)
            : .clear
        cardView.backgroundColor = isDarkMode
            ? UIColor(red: 0.12, green: 0.085, blue: 0.15, alpha: 1)
            : .white

        [thlLabel, categoryLabel, materialLabel, streakLabel, mrasLabel, mratLabel, pledgeLabel].forEach {
            $0.textColor = .label
        }

        pledgeInfoButton.tintColor = .secondaryLabel
    }

    private func setupTopBar() {
        titleLabel?.text = "SpeedTrack"
        backButton?.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        backButton?.isHidden = false
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func showPledgeInfo() {
        if tipView != nil {
            tipView?.dismiss()
            tipView = nil
            return
        }
        var preferences = EasyTipView.Preferences()
        preferences.drawing.font = UIFont(name: "Futura-Medium", size: 13)!
        preferences.drawing.foregroundColor = .white
        preferences.drawing.backgroundColor = #colorLiteral(red: 0.3098039216, green: 0, blue: 0.3921568627, alpha: 1)
        preferences.drawing.arrowPosition = .bottom

        let message = """
        The 10,000 Hour Rule: Consistent, Deliberate Practice Compounds. Spend 10,000 Focused Hours On A Skill And You Will Be A Master! Pledge: I Commit To Showing Up Consistently, Training My Mind Through Focused Listening, And Building My Knowledge One Hour At A Time. Every Session Counts. Every Hour Compounds. 10,000 Hours To Excellence
        """
        tipView = EasyTipView(text: message, preferences: preferences)
        tipView?.show(forView: pledgeInfoButton, withinSuperview: view)
    }

    @IBAction func backButtonTapped(_ sender: UIButton) {
        backTapped()
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        navigationController?.popToRootViewController(animated: false)
        return true
    }

    private func renderStats() {
        let uid = UserDetail.shared.getUserId()
        let thl = SpeedAnalyticsManager.shared.totalHoursListened(userID: uid)
        let covered = SpeedAnalyticsManager.shared.materialHoursCovered(userID: uid)
        let cat = SpeedAnalyticsManager.shared.categoryHours(userID: uid)
        let currentStreak = SpeedAnalyticsManager.shared.currentStreak(userID: uid)
        let longestStreak = SpeedAnalyticsManager.shared.longestStreak(userID: uid)
        let firstMras = SpeedAnalyticsManager.shared.first3MonthRollingAverage(userID: uid)
        let currentMras = SpeedAnalyticsManager.shared.current3MonthRollingAverage(userID: uid)
        let mratSeconds = SpeedAnalyticsManager.shared.current3MonthRollingAverageTimePerDay(userID: uid)

        let titleText = "Total Hours Listened (THL):\n"
        let valueText = formatTHL(thl)

        let attributedString = NSMutableAttributedString(
            string: titleText,
            attributes: [
                .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
        )

        let valueAttributed = NSAttributedString(
            string: valueText,
            attributes: [
                .font: UIFont.systemFont(ofSize: 40, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
        )

        attributedString.append(valueAttributed)
        thlLabel.attributedText = attributedString
        let primary = SpeedTrackCategoryManager.shared.primaryLabel()
        let secondary = SpeedTrackCategoryManager.shared.secondaryLabel()
        let tertiary = SpeedTrackCategoryManager.shared.tertiaryLabel()
        let quaternary = SpeedTrackCategoryManager.shared.quaternaryLabel()
        let categoryValues = reconciledWholeCategoryHours(
            totalHours: thl,
            categoryHours: [cat.fiction, cat.nonFiction, cat.misc1, cat.misc2]
        )
        categoryLabel.text = """
        \(primary): \(categoryValues[0])      \(secondary): \(categoryValues[1])
        \(tertiary): \(categoryValues[2])      \(quaternary): \(categoryValues[3])
        """
        materialLabel.text = "Material Hours Covered: \(formatTHL(covered))"

        let speedDailyPrefix = NSMutableAttributedString(
            string: "SpeedDaily ",
            attributes: [
                .font: UIFont.systemFont(ofSize: 17, weight: .regular),
                .foregroundColor: UIColor.label
            ]
        )

        let iconAttachment = NSTextAttachment()
        iconAttachment.image = UIImage(named: "speeddaily")
        iconAttachment.bounds = CGRect(x: 0, y: -2, width: 18, height: 18)
        speedDailyPrefix.append(NSAttributedString(attachment: iconAttachment))
        speedDailyPrefix.append(NSAttributedString(
            string: " :\nCurrent Streak: \(currentStreak) Days\nLongest Streak: \(longestStreak) Days",
            attributes: [
                .font: UIFont.systemFont(ofSize: 17, weight: .regular),
                .foregroundColor: UIColor.label
            ]
        ))
        streakLabel.attributedText = speedDailyPrefix

        let mrasText = String(format: "3 Month Rolling Average Speed (3MRAS):\nFirst 3 Months: %@x\nMost Recent 3 Months: %@x",
                              firstMras != nil ? String(format: "%.2f", firstMras!) : "Pending",
                              currentMras != nil ? String(format: "%.2f", currentMras!) : "0.00")
        let mratText = "3 Month Rolling Average Time (3MRAT):\n\(formatDuration(mratSeconds))/Day"

        mrasLabel.attributedText = NSAttributedString(
            string: mrasText,
            attributes: [
                .font: UIFont.systemFont(ofSize: 17, weight: .regular),
                .foregroundColor: UIColor.label
            ]
        )
        mratLabel.attributedText = NSAttributedString(
            string: mratText,
            attributes: [
                .font: UIFont.systemFont(ofSize: 17, weight: .regular),
                .foregroundColor: UIColor.label
            ]
        )
        pledgeLabel.text = "10,000"
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h == 0 {
            return String(format: "%d:%02d", m, s)
        }
        return String(format: "%d:%02d:%02d", h, m, s)
    }

    private func reconciledWholeCategoryHours(
        totalHours: Double,
        categoryHours: [Double]
    ) -> [Int] {
        let target = max(0, Int(totalHours.rounded(.down)))
        var values = categoryHours.map { max(0, Int($0.rounded(.down))) }
        let difference = target - values.reduce(0, +)

        if difference > 0 {
            values[2] += difference
        } else if difference < 0 {
            var overflow = -difference
            for index in [2, 3, 1, 0] where overflow > 0 {
                let reduction = min(values[index], overflow)
                values[index] -= reduction
                overflow -= reduction
            }
        }
        return values
    }

    private func formatTHL(_ hours: Double) -> String {
        let wholeHours = max(0, Int(hours.rounded(.down)))
        return "\(wholeHours)"
    }
}
