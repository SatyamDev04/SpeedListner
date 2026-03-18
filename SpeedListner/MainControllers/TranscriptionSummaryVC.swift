//
//  TranscriptionSummaryVC.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 03/07/25.
//


import UIKit

class TranscriptionSummaryVC: UIViewController {

    // MARK: - Properties

    var timeRange: String = ""
    var summaryText: String = ""
    var transcriptionText: String = ""

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Custom handle (pill + chevron)
    private let handleContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .clear
        return v
    }()

//    private let handlePill: UIView = {
//        let v = UIView()
//        v.translatesAutoresizingMaskIntoConstraints = false
//        v.backgroundColor = UIColor(white: 0.88, alpha: 1)
//        v.layer.cornerRadius = 3
//        v.clipsToBounds = true
//        return v
//    }()

    private let handleChevron: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        // Use an SF Symbol; use "chevron.compact.down" or "chevron.down"
        iv.image = UIImage(systemName: "chevron.compact.down")
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .secondaryLabel
        return iv
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()

    private let summaryTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Summary:"
        label.font = .boldSystemFont(ofSize: 16)
        return label
    }()

    private let summaryLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private let transcriptionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Exact Transcription:"
        label.font = .boldSystemFont(ofSize: 16)
        return label
    }()

    private let transcriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        applyData()

        // Optionally enable system grabber if presented as .pageSheet
        if let sheet = sheetPresentationController {
            sheet.prefersGrabberVisible = false // we use our custom handle; set true to use system instead
        }
    }

    // MARK: - Setup

    private func setupViews() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true

        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        // Add handle at top of contentView
        contentView.addSubview(handleContainer)
     //   handleContainer.addSubview(handlePill)
        handleContainer.addSubview(handleChevron)

        // Add labels in the order you wanted
        [timeLabel, transcriptionTitleLabel, transcriptionLabel, summaryTitleLabel, summaryLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        // Make handle tappable (e.g., to dismiss)
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapped(_:)))
        handleContainer.addGestureRecognizer(tap)
        handleContainer.isUserInteractionEnabled = true

        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Content View inside ScrollView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Handle container
            handleContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            handleContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            handleContainer.heightAnchor.constraint(equalToConstant: 24),
            handleContainer.widthAnchor.constraint(equalTo: contentView.widthAnchor),

            // Pill
          //  handlePill.centerXAnchor.constraint(equalTo: handleContainer.centerXAnchor),
           // handlePill.topAnchor.constraint(equalTo: handleContainer.topAnchor, constant: 6),
           // handlePill.widthAnchor.constraint(equalToConstant: 36),
           // handlePill.heightAnchor.constraint(equalToConstant: 6),

            // Chevron (optional small chevron below pill)
            handleChevron.centerXAnchor.constraint(equalTo: handleContainer.centerXAnchor),
   //         handleChevron.topAnchor.constraint(equalTo: handlePill.bottomAnchor, constant: 2),
            handleChevron.widthAnchor.constraint(equalToConstant: 30),
            handleChevron.heightAnchor.constraint(equalToConstant: 50),

            // Time Label (moved below handle)
            timeLabel.topAnchor.constraint(equalTo: handleContainer.bottomAnchor, constant: 8),
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Transcription Title (below Time Label)
            transcriptionTitleLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 20),
            transcriptionTitleLabel.leadingAnchor.constraint(equalTo: timeLabel.leadingAnchor),
            transcriptionTitleLabel.trailingAnchor.constraint(equalTo: timeLabel.trailingAnchor),

            // Transcription Text (below Transcription Title)
            transcriptionLabel.topAnchor.constraint(equalTo: transcriptionTitleLabel.bottomAnchor, constant: 8),
            transcriptionLabel.leadingAnchor.constraint(equalTo: timeLabel.leadingAnchor),
            transcriptionLabel.trailingAnchor.constraint(equalTo: timeLabel.trailingAnchor),

            // Summary Title (below Transcription Text)
            summaryTitleLabel.topAnchor.constraint(equalTo: transcriptionLabel.bottomAnchor, constant: 20),
            summaryTitleLabel.leadingAnchor.constraint(equalTo: timeLabel.leadingAnchor),
            summaryTitleLabel.trailingAnchor.constraint(equalTo: timeLabel.trailingAnchor),

            // Summary Text (below Summary Title)
            summaryLabel.topAnchor.constraint(equalTo: summaryTitleLabel.bottomAnchor, constant: 8),
            summaryLabel.leadingAnchor.constraint(equalTo: timeLabel.leadingAnchor),
            summaryLabel.trailingAnchor.constraint(equalTo: timeLabel.trailingAnchor),
            summaryLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }

    private func applyData() {
        timeLabel.text = timeRange
        summaryLabel.text = summaryText
        transcriptionLabel.text = transcriptionText
    }

    // MARK: - Actions

    @objc private func handleTapped(_ sender: UITapGestureRecognizer) {
        // Common behavior: dismiss the sheet when handle is tapped.
        // Customize: collapse, animate, or notify delegate instead.
        dismiss(animated: true, completion: nil)
    }
}
