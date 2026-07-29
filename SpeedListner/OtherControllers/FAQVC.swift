//
//  FAQVC.swift
//  SpeedListners
//
//  Created by ravi on 24/08/22.
//

import UIKit

class FAQVC: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    
    let arrTitle = [
        "What Is SpeedListener?",
        "Is This An Audiobook App?",
        "How Is This Different From Normal Playback Speed?",
        "What is SpeedTrack?",
        "What are Total Hours Listened (THL)?",
        "What Is A Streak?",
        "How Fast Should I Listen?",
        "What Is SpeedEscalation?",
        "Why Does SpeedEscalation Matter?",
        "What Happens If I Jump To A Very High Speed Too Quickly?",
        "How Does Faster Listening Improve Focus?",
        "What Are The Long-Term Benefits Of Training Listening Speed?",
        "Can I Use SpeedListener Offline?",
        "Do You Guarantee Results?",
        "Can I Cancel Anytime?",
        "If I Understand Everything At My Current Speed, Should I Increase It?",
        "How Do I Know If I Increased The Speed Too Much?",
        "Is It Normal To Feel Mentally Tired After Training With SpeedListener?",
        "How Long Should A Daily Training Session Be?",
        "What Is 3MRAS?",
        "What is 3MRAT?",
        "Why Does SpeedListener Track My Data?",
        "Should I Train At The Same Speed Every Day?",
        "Will Faster Listening Reduce Comprehension Long-Term?",
        "How Long Does It Take To See Improvement?",
        "If You Want to Get Very Good",
        "Why Does Morning Speed Feel Too Fast?"
    ]

    let arrDesc = [
    """
    SpeedListener is a listening performance training application for your iPhone designed to improve your listening speed, focus, and processing ability to take in more information faster.

    SmartNotes is its AI-powered note feature that captures important concepts as you listen. When the bookmark button is pressed, it bookmarks key sections, transcribes exact words, and generates clear summaries—so you don’t need to take physical notes.

    SpeedEscalation gradually increases your listening speed in controlled increments, helping your brain process information faster without feeling overwhelmed.
    """,

    "SpeedListener is not an audiobook platform. It is a performance training tool that also works as a powerful audiobook player.",

    "SpeedListener uses incremental progress and performance tracking. It trains your brain, not just speeds up audio.",

    "SpeedTrack displays your listening/training data, including total hours, streaks, and performance metrics.",

    "THL tracks every hour you spend listening or training inside SpeedListener.",

    "A streak counts how many consecutive days you have trained for more than 5 minutes.",

    "Start at a speed that challenges you while still allowing comprehension. Use SpeedEscalation to improve gradually.",

    "SpeedEscalation helps you increase listening speed over time in a controlled and effective way.",

    "It trains your brain to process information faster without losing comprehension, improving focus and efficiency.",

    "You may lose comprehension. Going too fast can make audio feel like noise. Build speed gradually.",

    "Faster audio reduces mental drift and increases active focus.",

    """
    • Faster information processing
    • Stronger focus
    • Better time efficiency
    • Improved mental stamina
    • Increased learning capacity
    • Ability to consume more books
    """,

    "Yes, SpeedListener works offline once audio is downloaded.",

    "No. This is a skill that takes time. Consistency brings results.",

    "Yes, you can cancel anytime via your App Store settings.",

    "Yes. If it feels easy, increase speed to challenge your brain.",

    "If you lose the main idea or feel overwhelmed, reduce speed slightly.",

    "Yes. Mental fatigue means your brain is training harder.",

    "Consistency matters more than duration. 15–30 minutes daily is effective.",

    "3MRAS (3-Month Rolling Average Speed) tracks your average listening speed over 3 months, showing true progress.",

    "3MRAT (3-Month Rolling Average Time) tracks your average daily listening time over 3 months.",

    "It helps motivate you and provides feedback for improvement.",

    "No. Increase speed gradually based on your progress and goals.",

    "Initially yes, but over time your brain adapts and comprehension improves.",

    "Most users notice improvement within days with consistent training.",

    """
    Simple formula:
    • Train daily
    • Use SpeedEscalation
    • Track your data
    • Maintain your streak
    • Stay consistent
    """,

    "Your brain needs time to warm up. Start your first 5 to 10 minutes at a slightly lower speed, then step up gradually. Morning focus is usually lower at first, but after a short ramp-up your brain adapts and higher speeds feel normal again."
    ]
    
   
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tblV: UITableView!
   var indexRow : NSMutableArray = []
    let loading = indicator()
   // NOTE: Not used currently since FAQs are static (arrTitle & arrDesc)
   var getAllFAQArr = [ModelClass]()
   override func viewDidLoad() {
       super.viewDidLoad()
       //self.apiforGetAllFAQ()
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
       configureFAQSupportHeader()
       self.tblV.reloadData()
       self.tblV.register(UINib(nibName: "CellData", bundle: nil), forCellReuseIdentifier: "CellData")

   }

   private func configureFAQSupportHeader() {
       let headerContainer = UIView(frame: CGRect(x: 0, y: 0, width: tblV.bounds.width, height: 64))
       headerContainer.backgroundColor = .systemBackground

       let supportTextView = UITextView(frame: CGRect(x: 12, y: 8, width: max(0, tblV.bounds.width - 24), height: 48))
       supportTextView.backgroundColor = .clear
       supportTextView.isEditable = false
       supportTextView.isScrollEnabled = false
       supportTextView.textContainerInset = .zero
       supportTextView.textContainer.lineFragmentPadding = 0
       supportTextView.textAlignment = .center
       supportTextView.font = .systemFont(ofSize: 14, weight: .semibold)
       supportTextView.linkTextAttributes = [
           .foregroundColor: UIColor.systemBlue,
           .underlineStyle: NSUnderlineStyle.single.rawValue
       ]

       let text = "Please Visit Us As SpeedListener.com For More Support."
       let attributed = NSMutableAttributedString(
           string: text,
           attributes: [
               .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
               .foregroundColor: UIColor.label
           ]
       )

       let linkText = "SpeedListener.com"
       let nsText = text as NSString
       let linkRange = nsText.range(of: linkText)
       if linkRange.location != NSNotFound {
           attributed.addAttribute(.link, value: "https://speedlistener.com", range: linkRange)
       }

       supportTextView.attributedText = attributed
       headerContainer.addSubview(supportTextView)
       tblV.tableHeaderView = headerContainer
   }

   override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
       super.traitCollectionDidChange(previousTraitCollection)

       if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
           configureFAQSupportHeader()
       }
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
       return arrTitle.count
   }
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return UITableView.automaticDimension
//    }
//
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
      // let data = getAllFAQArr[indexPath.row]
       
       let cell1 = tblV.dequeueReusableCell(withIdentifier: "CellData", for: indexPath) as! CellData
       cell1.lblDesc.text =  arrDesc[indexPath.row]
       cell1.lblHeader.text = arrTitle[indexPath.row]
       cell1.lblSerialNumber.text =  "\(indexPath.row + 1)" + "."
       cell1.lblSerialNumber.isHidden = true
      // tblV.isScrollEnabled = false
      cell1.headerLeadingConstraints.constant = -40
         if indexRow.contains(indexPath.row) {
                   cell1.img.image = #imageLiteral(resourceName: "Vector-40")
            // cell1.btnFaqQuestion.setTitle(data.faqsQuestion, for: .normal)
             
             cell1.lblSerialNumber.isHidden = true
             cell1.lblDesc.text = arrDesc[indexPath.row]
             cell1.lblHeader.text = arrTitle[indexPath.row]
            
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
