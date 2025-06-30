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

        self.tableView.tableFooterView = UIView()
        self.tableView.reloadData()
    let asset = AVAsset(url: PlayerManager.shared.currentBook?.fileURL ?? URL(fileURLWithPath: ""))
    for locale in asset.availableChapterLocales {
        let chaptersMetadata = asset.chapterMetadataGroups(withTitleLocale: locale, containingItemsWithCommonKeys: [AVMetadataKey.commonKeyArtwork])

        for (index, chapterMetadata) in chaptersMetadata.enumerated() {
        let titleFromMeta = AVMetadataItem.metadataItems(from: asset.metadata, withKey: AVMetadataKey.commonKeyTitle, keySpace: AVMetadataKeySpace.common).first?.value?.copy(with: nil) as? String
          print(chapterMetadata.items,"hgjkl;'lk")



          
        }
    }
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
        let chapter = self.chapters[indexPath.row]
        if ((chapter.title?.contains("Chapter")) != nil){
    cell.textLabel?.text = chapter.title
    
    }else{
    
        cell.textLabel?.text =  "Chapter \(indexPath.row + 1)" + (chapter.title ?? "")
    
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
        self.didSelectChapter?(self.chapters[indexPath.row])

        self.done(nil)
    }


}



// Example usage

