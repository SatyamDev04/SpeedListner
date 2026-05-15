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
    private let pledgeInfoButton = UIButton(type: .system)
    private let pledgeRow = UIStackView()
    private var tipView: EasyTipView?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "SpeedTrack"
        view.backgroundColor = UIColor(red: 0.32, green: 0.13, blue: 0.47, alpha: 1.0)
        tabBarController?.delegate = self
        setupTopBar()
        setupUI()
        renderStats()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.tintColor = .white
        showSpeedTrackTopBadge()
        renderStats()
    }

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 18
        cardView.clipsToBounds = true

        [thlLabel, categoryLabel, materialLabel, streakLabel, mrasLabel, mratLabel, pledgeLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.numberOfLines = 0
            $0.textColor = .black
            cardView.addSubview($0)
        }

        thlLabel.font = .systemFont(ofSize: 40, weight: .bold)
        thlLabel.textAlignment = .center
        categoryLabel.font = .systemFont(ofSize: 16, weight: .bold)
        categoryLabel.textAlignment = .center
        materialLabel.font = .systemFont(ofSize: 16, weight: .bold)
        materialLabel.textAlignment = .center
        streakLabel.font = .systemFont(ofSize: 17, weight: .bold)
        mrasLabel.font = .systemFont(ofSize: 17, weight: .bold)
        mratLabel.font = .systemFont(ofSize: 17, weight: .bold)
        pledgeLabel.font = .systemFont(ofSize: 18, weight: .bold)
        pledgeInfoButton.setTitle("ℹ️", for: .normal)
        pledgeInfoButton.titleLabel?.font = .systemFont(ofSize: 28, weight: .regular)
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
                .font: UIFont.systemFont(ofSize: 16, weight: .bold),
                .foregroundColor: UIColor.black
            ]
        )

        let valueAttributed = NSAttributedString(
            string: valueText,
            attributes: [
                .font: UIFont.systemFont(ofSize: 40, weight: .bold),
                .foregroundColor: UIColor.black
            ]
        )

        attributedString.append(valueAttributed)
        thlLabel.attributedText = attributedString
        let primary = SpeedTrackCategoryManager.shared.primaryLabel()
        let secondary = SpeedTrackCategoryManager.shared.secondaryLabel()
        categoryLabel.text = "\(primary): \(formatTHL(cat.fiction))      \(secondary): \(formatTHL(cat.nonFiction))"
        materialLabel.text = "Material Hours Covered: \(formatTHL(covered))"

        let speedDailyPrefix = NSMutableAttributedString(
            string: "SpeedDaily",
            attributes: [
                .font: UIFont.systemFont(ofSize: 17, weight: .bold),
                .foregroundColor: UIColor.black
            ]
        )

        let iconAttachment = NSTextAttachment()
        iconAttachment.image = UIImage(named: "speeddaily")
        iconAttachment.bounds = CGRect(x: 0, y: -2, width: 18, height: 18)
        speedDailyPrefix.append(NSAttributedString(attachment: iconAttachment))
        speedDailyPrefix.append(NSAttributedString(
            string: ":\nCurrent Streak: \(currentStreak) Days\nLongest Streak: \(longestStreak) Days",
            attributes: [
                .font: UIFont.systemFont(ofSize: 17, weight: .bold),
                .foregroundColor: UIColor.black
            ]
        ))
        streakLabel.attributedText = speedDailyPrefix

        mrasLabel.text = String(format: "3 Month Rolling Average Speed (3MRAS):\nFirst 3 Months: %@x\nMost Recent 3 Months: %@x",
                                firstMras != nil ? String(format: "%.2f", firstMras!) : "Pending",
                                currentMras != nil ? String(format: "%.2f", currentMras!) : "0.00")

        mratLabel.text = "3 Month Rolling Average Time (3MRAT):\n\(formatDuration(mratSeconds))/Day"
        pledgeLabel.text = "10,000"
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%d:%02d:%02d", h, m, s)
    }

    private func formatTHL(_ hours: Double) -> String {
        let wholeHours = max(0, Int(hours.rounded(.down)))
        return "\(wholeHours) THL"
    }
}
