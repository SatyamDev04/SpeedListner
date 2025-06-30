//
//  FAQVC.swift
//  SpeedListners
//
//  Created by ravi on 24/08/22.
//

import UIKit

class FAQVC: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    
    var arrTitle = ["Lorem Ipsum is simply dummy?","Lorem Ipsum is simply dummy text of the printing?","Lorem Ipsum is simply dummy text of the printing?"]
    var arrDesc = ["Nibh quisque suscipit fermentum netus nulla cras porttitor euismod nulla. Orci, dictumst nec aliquet id ullamcorper venenatis. Fermentum sulla craspor ttitore  ismod nulla. Elit adipiscing proin quis est consectetur. Felis ultricies nisi, quis malesuada sem odio. Potenti nibh natoque amet amet, tincidunt ultricies et. Et nam rhoncus sit nullam diam tincidunt condimentum nullam.","Nibh quisque suscipit fermentum netus nulla cras porttitor euismod nulla. Orci, dictumst nec aliquet id ullamcorper venenatis. Fermentum sulla craspor ttitore  ismod nulla. Elit adipiscing proin quis est consectetur. Felis ultricies nisi, quis malesuada sem odio. Potenti nibh natoque amet amet, tincidunt ultricies et. Et nam rhoncus sit nullam diam tincidunt condimentum nullam.","Nibh quisque suscipit fermentum netus nulla cras porttitor euismod nulla. Orci, dictumst nec aliquet id ullamcorper venenatis. Fermentum sulla craspor ttitore  ismod nulla. Elit adipiscing proin quis est consectetur. Felis ultricies nisi, quis malesuada sem odio. Potenti nibh natoque amet amet, tincidunt ultricies et. Et nam rhoncus sit nullam diam tincidunt condimentum nullam."]
   
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tblV: UITableView!
   var indexRow : NSMutableArray = []
    let loading = indicator()
    var getAllFAQArr = [ModelClass]()
   override func viewDidLoad() {
       super.viewDidLoad()
       self.apiforGetAllFAQ()
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
    
    func apiforGetAllFAQ() {
         
        
        var params = [String: Any]()
        
        
        let loginURL = baseURL.baseURL + appEndPoints.all_faq
        
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
               
                if let resultData = dictData!["products"] as? [[String:Any]]{
                    self.getAllFAQArr.removeAll()
                    self.getAllFAQArr = ModelClass.getAllFAQ(responseArray: resultData)
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
       return getAllFAQArr.count// arrTitle.count
   }
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return UITableView.automaticDimension
//    }
//
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
       let data = getAllFAQArr[indexPath.row]
       
       let cell1 = tblV.dequeueReusableCell(withIdentifier: "CellData", for: indexPath) as! CellData
       cell1.lblDesc.text = data.faq_answer ?? "" //arrDesc[indexPath.row]
       cell1.lblHeader.text = data.faq_question ?? "" //arrTitle[indexPath.row]
       cell1.lblSerialNumber.text =  "\(indexPath.row + 1)" + "."
       cell1.lblSerialNumber.isHidden = true
      // tblV.isScrollEnabled = false
      cell1.headerLeadingConstraints.constant = -40
         if indexRow.contains(indexPath.row) {
                   cell1.img.image = #imageLiteral(resourceName: "Vector-40")
            // cell1.btnFaqQuestion.setTitle(data.faqsQuestion, for: .normal)
             
             cell1.lblSerialNumber.isHidden = true
             cell1.lblDesc.text = data.faq_answer ?? "" //arrDesc[indexPath.row]
             cell1.lblHeader.text = data.faq_question ?? "" //arrTitle[indexPath.row]
            
                   //cell.lbl_ques.text = FAQDetais[indexPath.row].question
                  // cell11.lblDec.text = faq[indexPath.row].answer

               }else{
                   cell1.lblDesc.text = ""
                   cell1.img.image = #imageLiteral(resourceName: "plus")
               }
       return cell1
   }
   
   
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let i = indexPath.row
            if indexRow.contains(i) {
                indexRow.remove(i)
            }else{

                indexRow.add(i)
            }
            tblV.reloadData()
        }
  

}

extension FAQVC: UIScrollViewDelegate {

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
