//
//  ChaptersViewController.swift
//  SpeedListner
//
//Created by Satyam Dwivedi on 16/06/23.
import UIKit
import AVFoundation
import MediaPlayer
import DeckTransition

struct Chapterr:Equatable {
    
    var title:String
    var start:Int
    var duration:Int
    var index:Int
    
}



class ChaptersViewController: UITableViewController {
    var chapters: [Chapter]!

    var currentChapter: Chapter!
    var didSelectChapter: ((_ selectedChapter: Chapter) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        guard !chapters.isEmpty else {
                showToast("Please add a book to the library if already added then play")
                return
            }
        self.tableView.tableFooterView = UIView()
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 60))
        let arrowImageView = UIImageView()
        if let chevronImage = UIImage(systemName: "chevron.compact.down") {
            arrowImageView.image = chevronImage
            arrowImageView.tintColor = .systemGray
        }
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(arrowImageView)
        NSLayoutConstraint.activate([
            arrowImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            arrowImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            arrowImageView.heightAnchor.constraint(equalToConstant: 36),
            arrowImageView.widthAnchor.constraint(equalToConstant: 36)
        ])
        self.tableView.tableHeaderView = headerView
        
        self.tableView.reloadData()

  
    }

    @IBAction func done(_ sender: UIBarButtonItem?) {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chapters.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChapterCell", for: indexPath)
        print("cellForRowAt indexPath: \(indexPath)")
        let chapter = self.chapters[indexPath.row]
        if chapter.index == 0 {
            cell.textLabel?.text = "Intro"
        } else {
            let cleanedTitle = cleanChapterTitle(chapter.title)

            if cleanedTitle.isEmpty {
                cell.textLabel?.text = "Chapter \(chapter.index)"
            } else {
                cell.textLabel?.text = "Chapter \(chapter.index): \(cleanedTitle)"
            }
        }
        let roundedX2 = Double(round(PlayerManager.shared.speed * 10) / 10)
        let adjustedStart = chapter.start / roundedX2
        let duration = chapter.duration / roundedX2

        cell.detailTextLabel?.text = "\(self.formatTime2(adjustedStart)) – \(self.formatDuration(duration, unitsStyle: .abbreviated))"
        cell.accessoryType = .none

        if self.currentChapter.index == chapter.index {
        cell.accessoryType = .checkmark
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didSelectRowAt indexPath: \(indexPath)")
        self.didSelectChapter?(self.chapters[indexPath.row])

        self.done(nil)
    }

    func cleanChapterTitle(_ title: String?) -> String {
        guard let title = title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else {
            return ""
        }

        let lower = title.lowercased()

        // Remove "chapter X" from beginning
        if lower.hasPrefix("chapter") {
            let components = title.split(separator: " ")
            
            // If only "Chapter 1"
            if components.count <= 2 {
                return ""
            }
            
            // Remove first 2 words (Chapter + number)
            let remaining = components.dropFirst(2)
            return remaining.joined(separator: " ")
        }

        return title
    }
}



// Example usage



