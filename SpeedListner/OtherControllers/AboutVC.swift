//
//  AboutVC.swift
//  SpeedListners
//
//  Created by ravi on 23/08/22.
//

import UIKit

class AboutVC: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    var arrTitle = ["About the company","About the company owner"]
    var arrDesc = ["Lorem ipsum dolor sit amet, consectetur adipiscing elit. Viverra condimentum eget purus in. Consectetur eget id morbi amet amet,","Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ullamcorper suspendisse aenean leo pharetra in sit semper et. Amet quam placerat sem.Ullamcorper suspendisse aenean leo pharetra in sit semper et."]
    
    @IBOutlet weak var tblV: UITableView!
    var indexRow : NSMutableArray = []
    let loading = indicator()
    var getAboutUsArr = [ModelClass]()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.apiforGetAboutUs()
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
        return getAboutUsArr.count//arrTitle.count
    }
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return UITableView.automaticDimension
//    }
//
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let data = getAboutUsArr[indexPath.row]
        let cell1 = tblV.dequeueReusableCell(withIdentifier: "CellData", for: indexPath) as! CellData
        cell1.lblDesc.text = data.about_name ?? ""//arrDesc[indexPath.row]
        cell1.lblHeader.text = arrTitle[indexPath.row]
        cell1.lblSerialNumber.isHidden = true
       // tblV.isScrollEnabled = false
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
