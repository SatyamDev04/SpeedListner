//
//  TermsConditionVC.swift
//  SpeedListners
//
//  Created by ravi on 23/08/22.
//

import UIKit

class TermsConditionVC: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var scrollView: UIScrollView!
    var arrTitle = ["Clause","Clause"]
   var arrDesc = ["Lorem ipsum dolor sit amet, consectetur adipiscing elit. Viverra condimentum eget purus in. Consectetur eget id morbi amet amet,","Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ullamcorper suspendisse aenean leo pharetra in sit semper et. Amet quam placerat sem.Ullamcorper suspendisse aenean leo pharetra in sit semper et.Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ullamcorper suspendisse aenean leo pharetra in sit semper et. Amet quam placerat sem.Ullamcorper suspendisse aenean leo pharetra in sit semper et."]
    
    @IBOutlet weak var tblV: UITableView!
    var indexRow : NSMutableArray = []
    let loading = indicator()
    var getTermConditionArr = [ModelClass]()
    override func viewDidLoad() {
        super.viewDidLoad()
        apiforGetTermConditions()
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
    
    func apiforGetTermConditions() {
         
        // let userid = UserDetail.shared.getUserId()
        
        var params = [String: Any]()
        
       // let jsonDict : [String:Any] = ["user_id": userid ?? ""]
        
        let loginURL = baseURL.baseURL + appEndPoints.terms_conditions
        
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
                    self.getTermConditionArr.removeAll()
                    self.getTermConditionArr = ModelClass.getTermCondition(responseArray: resultData)
                    
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
        return getTermConditionArr.count //arrTitle.count
    }
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return UITableView.automaticDimension
//    }
//
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let data = getTermConditionArr[indexPath.row]
        let cell1 = tblV.dequeueReusableCell(withIdentifier: "CellData", for: indexPath) as! CellData
        cell1.lblDesc.text = data.term_name ?? "" //arrDesc[indexPath.row]
        cell1.lblHeader.text = arrTitle[indexPath.row]
        cell1.lblSerialNumber.text =  "\(indexPath.row + 1)" + "."
       // tblV.isScrollEnabled = false
       cell1.headerLeadingConstraints.constant = -25
//         if indexRow.contains(indexPath.row) {
//                   cell1.img.image = #imageLiteral(resourceName: "akar-icons_circle-minus-fill")
//            // cell1.btnFaqQuestion.setTitle(data.faqsQuestion, for: .normal)
//             cell1.lblHeader.text = "Lorem ipsum dolor sit amet"
//             cell1.lblSerialNumber.isHidden = true
//             cell1.lblDesc.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Viverra condimentum eget purus in. Consectetur eget id morbi amet amet, in. Ipsum viverra pretium tellus neque. Ullamcorper suspendisse aenean leo pharetra in sit semper et. Amet quam placerat sem."//data.faqsAnswer ?? ""
//
//                   //cell.lbl_ques.text = FAQDetais[indexPath.row].question
//                  // cell11.lblDec.text = faq[indexPath.row].answer
//
//               }else{
//                   cell1.lblDesc.text = ""
//                   cell1.img.image = #imageLiteral(resourceName: "Vector-34")
//               }
        return cell1
    }
    

}
extension TermsConditionVC: UIScrollViewDelegate {

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
