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
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
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
        label.textColor = .darkGray
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
        label.textColor = .darkGray
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        applyData()
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.backgroundColor = .white
        
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add all labels to contentView
        [timeLabel, summaryTitleLabel, summaryLabel, transcriptionTitleLabel, transcriptionLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
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
            
            // Time Label
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Summary Title
            summaryTitleLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 20),
            summaryTitleLabel.leadingAnchor.constraint(equalTo: timeLabel.leadingAnchor),
            summaryTitleLabel.trailingAnchor.constraint(equalTo: timeLabel.trailingAnchor),
            
            // Summary Text
            summaryLabel.topAnchor.constraint(equalTo: summaryTitleLabel.bottomAnchor, constant: 8),
            summaryLabel.leadingAnchor.constraint(equalTo: timeLabel.leadingAnchor),
            summaryLabel.trailingAnchor.constraint(equalTo: timeLabel.trailingAnchor),
            
            // Transcription Title
            transcriptionTitleLabel.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: 20),
            transcriptionTitleLabel.leadingAnchor.constraint(equalTo: timeLabel.leadingAnchor),
            transcriptionTitleLabel.trailingAnchor.constraint(equalTo: timeLabel.trailingAnchor),
            
            // Transcription Text
            transcriptionLabel.topAnchor.constraint(equalTo: transcriptionTitleLabel.bottomAnchor, constant: 8),
            transcriptionLabel.leadingAnchor.constraint(equalTo: timeLabel.leadingAnchor),
            transcriptionLabel.trailingAnchor.constraint(equalTo: timeLabel.trailingAnchor),
            transcriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
    
    private func applyData() {
        timeLabel.text = timeRange
        summaryLabel.text = summaryText
        transcriptionLabel.text = transcriptionText
    }
}