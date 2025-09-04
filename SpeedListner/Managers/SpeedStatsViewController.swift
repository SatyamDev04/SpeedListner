//
//  SpeedStatsViewController.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 28/08/25.
//


import UIKit

final class SpeedStatsViewController: UIViewController {
    private let segmented = UISegmentedControl(items: ["Daily", "Monthly"])
    private let allTimeLabel = UILabel()
    private let chart = BarChartView()
    private let infoLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Listening Speed"
        view.backgroundColor = .systemBackground

        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(segChanged), for: .valueChanged)

        allTimeLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        allTimeLabel.textColor = .label

        chart.translatesAutoresizingMaskIntoConstraints = false
        segmented.translatesAutoresizingMaskIntoConstraints = false
        allTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false

        infoLabel.font = .systemFont(ofSize: 12)
        infoLabel.textColor = .secondaryLabel
        infoLabel.numberOfLines = 0
        infoLabel.text = "Time-weighted average speed."

        view.addSubview(segmented)
        view.addSubview(allTimeLabel)
        view.addSubview(chart)
        view.addSubview(infoLabel)

        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            segmented.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            allTimeLabel.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 12),
            allTimeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            chart.topAnchor.constraint(equalTo: allTimeLabel.bottomAnchor, constant: 16),
            chart.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            chart.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            chart.heightAnchor.constraint(equalToConstant: 220),

            infoLabel.topAnchor.constraint(equalTo: chart.bottomAnchor, constant: 8),
            infoLabel.leadingAnchor.constraint(equalTo: chart.leadingAnchor),
            infoLabel.trailingAnchor.constraint(equalTo: chart.trailingAnchor)
        ])

        reloadAll()
    }

    @objc private func segChanged() { reloadChart() }

    private func reloadAll() {
        // All-time label
        let userID = PlayerManager.shared.currentUserID
        if let avg = SpeedAnalyticsManager.shared.averageAllTime(userID: userID) {
            allTimeLabel.text = String(format: "All-Time Avg: %.2fx", avg)
        } else {
            allTimeLabel.text = "All-Time Avg: —"
        }
        reloadChart()
    }

    private func reloadChart() {
        let userID = PlayerManager.shared.currentUserID
        let dfDay = DateFormatter(); dfDay.dateFormat = "MM/dd"
        let dfMonth = DateFormatter(); dfMonth.dateFormat = "MMM"

        switch segmented.selectedSegmentIndex {
        case 0: // Daily (last 30 days)
            let series = SpeedAnalyticsManager.shared.dailySeries(userID: userID, days: 30)
            chart.bars = series.map { tup in
                let label = dfDay.string(from: tup.date)
                let v = CGFloat(tup.avg ?? 0)
                let isToday = Calendar.current.isDateInToday(tup.date)
                return .init(value: v, label: label, highlight: isToday)
            }
            chart.valueFormatter = { String(format: "%.1fx", $0) }

        default: // Monthly (last 12 months)
            let series = SpeedAnalyticsManager.shared.monthlySeries(userID: userID, months: 12)
            chart.bars = series.map { tup in
                let label = dfMonth.string(from: tup.monthStart)
                let v = CGFloat(tup.avg ?? 0)
                let isCurrentMonth = Calendar.current.isDate(tup.monthStart, equalTo: Date(), toGranularity: .month)
                return .init(value: v, label: label, highlight: isCurrentMonth)
            }
            chart.valueFormatter = { String(format: "%.2fx", $0) }
        }
    }
}