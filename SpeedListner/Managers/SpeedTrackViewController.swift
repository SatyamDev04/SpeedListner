import UIKit

final class SpeedTrackViewController: UIViewController {
    
    @IBOutlet weak var cardBGView:UIView!
    private let scrollView = UIScrollView()
    private let cardView = UIView()

    private let thlLabel = UILabel()
    private let categoryLabel = UILabel()
    private let materialLabel = UILabel()
    private let streakLabel = UILabel()
    private let mrasLabel = UILabel()
    private let mratLabel = UILabel()
    private let pledgeLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "SpeedTrack"
        view.backgroundColor = UIColor(red: 0.32, green: 0.13, blue: 0.47, alpha: 1.0)
        setupUI()
        renderStats()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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

            pledgeLabel.topAnchor.constraint(equalTo: mratLabel.bottomAnchor, constant: 36),
            pledgeLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            pledgeLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            pledgeLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20)
        ])
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
        categoryLabel.text = "Fiction: \(formatTHL(cat.fiction))      Non-Fiction: \(formatTHL(cat.nonFiction))"
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
        pledgeLabel.text = "10,000ℹ️"
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
