//
//  AboutVC.swift
//  SpeedListners
//
//  Created by ravi on 23/08/22.
//

import UIKit

class AboutVC: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    var arrTitle = ["About SpeedListener"]
    var arrDesc = [" SpeedListener Is A Listening Performance Training Application For iPhone.It Is Designed To Help You Increase Your Listening Speed, Strengthen Your Focus And Improve How Quickly You Process Information.Most People Listen At One Times (1x) Speed, After All, That’s How We Talk. There Are Over 300,000 New Books Published In The US Every Year And Over 100,000 Of Those Make It To Audiobooks. It’s Impossible To Keep Up, But SpeedListener Trains You To Go Beyond That. Using Structured Speed Progression And Performance Tracking, The App Helps You Gradually Increase Your Listening Ability Over Time.Whether You’re Commenting, Cooking, Cleaning Or Doing Cardio SpeedListener Helps You Be More Productive. SpeedListener Turns Dead Time Into Gold - Those Boring Stretches Like Washing Dishes, Folding Laundry Or When You’re Stuck In Traffic? They’re Now Your Secret Learning Sessions. For A Change Of Pace, Instead of Zoning Out To Your Usual Tunes, Crank Up An Audiobook 2x 0r 3x (Or Higher Once You’ve Trained) And Suddenly You’re Knocking Out The Chapters While The Sink Is Full Or The Traffic Jam Is Stagnant. No Extra Hours Needed. Just Smarter Use Of What You’ve Already Got. People Do This All The Time - Multitasking Pros Swear By It: Chores Fly By, Commutes Feel Shorter, Stress Drops Because Your Brain Is Engaged, Not Idle. And With SpeedEscalation Gently Pushing You Faster, You Finish More Without Forcing It. SpeedListener Isn’t About Speed For Speed Sake - Its Reclaiming Time. Turn “I don’t Have Time To Read” Into “I Just Finished Three Books This Week”. Music Is Great But Books Build You. And You’re Doing It Anyway.SpeedListener Is Not An Audiobook Platform. It Is A Performance Training Tool - That Just Happens To Be An Amazing Audiobook Player.The Goal Is Simple: Process Information Faster.Stay Focused Longer.  Train Your Brain To Operate At A Higher Level."]
    
    @IBOutlet weak var tblV: UITableView!
    var indexRow : NSMutableArray = []
    let loading = indicator()
    var getAboutUsArr = [ModelClass]()
    override func viewDidLoad() {
        super.viewDidLoad()
       // self.apiforGetAboutUs()
        self.scrollView.delegate = self
        self.tblV.addCorner5()
        self.tblV.layer.borderColor = UIColor.lightGray.cgColor
        self.tblV.layer.borderWidth = 0.2
        self.tblV.layer.masksToBounds = true
        self.tblV.layer.shadowColor = UIColor.black.cgColor
        self.tblV.layer.shadowRadius = 30
        self.tblV.layer.shadowOpacity = 10.0
        self.tblV.layer.shadowOffset = .zero
        self.tblV.layer.masksToBounds = true
        self.tblV.reloadData()
        self.tblV.register(UINib(nibName: "CellData", bundle: nil), forCellReuseIdentifier: "CellData")

    }
    
    
    func apiforGetAboutUs() {
         
        // let userid = UserDetail.shared.getUserId()
        
        var params = [String: Any]()
        
       // let jsonDict : [String:Any] = ["user_id": userid ?? ""]
        
        let loginURL = baseURL.baseURL + appEndPoints.about_us
        
        print(loginURL, "API_URL")
        
        self.loading.showActivityIndicator(uiView: self.view)
        WebService.shared.getService(loginURL, andParameter: params, withCompletion: { (json, statusCode) in
            self.loading.hideActivityIndicator(uiView: self.view)
            let dict = "\(json)"
            var dictData : [String:Any]?
            if let data = dict.data(using: .utf8) {
                do {
                    dictData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                } catch {
                    print(error.localizedDescription)
                }
            }
            if (dictData!["success"] as? Int) == 1 {
               
                if let resultData = dictData!["products"] as? [[String:Any]] {
                    self.getAboutUsArr.removeAll()
                    self.getAboutUsArr = ModelClass.getAllAboutUs(responseArray: resultData)
                    print(self.getAboutUsArr.count,"getAboutUsArr.count")
                    self.tblV.reloadData()
                }
              
                else{
                   
                   
                }
                
            }
         //  hideHud()
        })
    }

    
    @IBAction func btnBack_Action(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrTitle.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        let cell1 = tblV.dequeueReusableCell(withIdentifier: "CellData", for: indexPath) as! CellData
        cell1.lblDesc.text = arrDesc[indexPath.row]
        cell1.lblDesc.textAlignment = .justified
        cell1.lblHeader.text = arrTitle[indexPath.row]
        cell1.lblSerialNumber.isHidden = true
        cell1.headerLeadingConstraints.constant = -40

        return cell1
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//            let i = indexPath.row
//            if indexRow.contains(i) {
//                indexRow.remove(i)
//            }else{
//
//                indexRow.add(i)
//            }
//            tblV.reloadData()
//        }
   

}

extension AboutVC: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        //--- Change Scroll View Indicator Color ---//
        if #available(iOS 13, *) {
            let verticalIndicatorView = (scrollView.subviews[(scrollView.subviews.count - 1)].subviews[0])
            let horizontalIndicatorView = (scrollView.subviews[(scrollView.subviews.count - 2)].subviews[0])
            
            //let colors = [UIColor(named: "#E54F4F")!.cgColor, UIColor(named: "##E61C1C")!.cgColor, UIColor(named: "#8E0202")!.cgColor]
            
            verticalIndicatorView.backgroundColor = UIColor.clear
            verticalIndicatorView.backgroundColor = UIColor(red: 79/255, green: 0/255, blue: 100/255, alpha: 1)
            //verticalIndicatorView.setGradient(colors: colors, angle: 90.0)
            
            horizontalIndicatorView.backgroundColor = UIColor.clear
            horizontalIndicatorView.backgroundColor = UIColor(red: 79/255, green: 0/255, blue: 100/255, alpha: 1)
            
        } else {
            
           // let colors = [UIColor(named: "#E54F4F")!.cgColor, UIColor(named: "##E61C1C")!.cgColor, UIColor(named: "#8E0202")!.cgColor]
            
            if let verticalIndicatorView: UIImageView = (scrollView.subviews[(scrollView.subviews.count - 1)] as? UIImageView) {
                verticalIndicatorView.backgroundColor = UIColor.clear
                verticalIndicatorView.backgroundColor = UIColor(red: 79/255, green: 0/255, blue: 100/255, alpha: 1)
            }

            if let horizontalIndicatorView: UIImageView = (scrollView.subviews[(scrollView.subviews.count - 2)] as? UIImageView) {
                horizontalIndicatorView.backgroundColor = UIColor.clear
                horizontalIndicatorView.backgroundColor = UIColor(red: 79/255, green: 0/255, blue: 100/255, alpha: 1)
            }
        }
   }
}
