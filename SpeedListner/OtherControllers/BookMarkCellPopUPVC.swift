//
//  BookMarkCellPopUPVC.swift
//  SpeedListners
//
//  Created by ravi on 19/08/22.
//

import UIKit

class BookMarkCellPopUPVC: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    var ArrSort = ["Add/Edit Note","Delete Bookmark"," Cancel"]
    var imgArr = ["watch","calendar","calendar"]
    
   
    @IBOutlet weak var tblSort: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tblSort.register(UINib(nibName: "tableSortCell", bundle: nil), forCellReuseIdentifier: "tableSortCell")
        // Do any additional setup after loading the view.
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return 2
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tblSort.dequeueReusableCell(withIdentifier: "tableSortCell") as! tableSortCell
            cell.img.image = UIImage(named: String(imgArr[indexPath.row]))
            cell.lbltitle.text = ArrSort[indexPath.row]
            self.tblSort.isScrollEnabled = false
            return cell
        }
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            self.tblSort.isHidden = true
        }
}
