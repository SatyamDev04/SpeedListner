//
//  PauseTimerVC.swift
//  SpeedListners
//
//Created by Satyam Dwivedi on 16/06/23.
//

import UIKit
import DropDown

protocol DelegateforPauseTimer {
    func MethodforPop()
    func sendDataToPlayerVC(myData: String,PaustimerStatus:String)
    
}

class PauseTimerVC: UIViewController,UITableViewDelegate,UITableViewDataSource,UITextViewDelegate {
    
    var PaustimerStatus: String!
    var PaustimerStatusFromNowVC: String!
    var counter = 0
    
    @IBOutlet weak var txt_ReminderMsg: UITextView!
    @IBOutlet weak var view_Txt: UIView!
    var delegate1:DelegateforPauseTimer? = nil
    
    @IBOutlet weak var lblToggleStatus: UILabel!
    var a1: String?
    var b1: String?
    var c1: String?
    var time1:String!
    var END_TIME: String! = nil
    var seconds1: String!
    var seconds: Int! = nil
    var totalSecond:String! = nil
    
    
    @IBOutlet weak var lbltime: UILabel!
    @IBOutlet weak var btnToggle_info: UIButton!
    var checked = false
    @IBOutlet weak var tableminutes: UITableView!
    @IBOutlet weak var tablehours: UITableView!

    @IBOutlet weak var txt_minutes: UITextField!
    @IBOutlet weak var txt_hours: UITextField!
    
    var hoursArray = ["0","1", "2","3", "4","5", "6","7", "8","9", "10","11", "12"]
    
    var minutesArray = ["0","1", "2","3", "4","5", "6","7", "8","9", "10","11", "12","13", "14","15", "16","17", "18","19", "20","21", "22","23", "24","25", "26","27", "28","29", "30","31", "32","33", "34","35", "36","37", "38","39", "40","41", "42","43", "44","45", "46","47", "48","49", "50","51", "52","53", "54","55", "56","57", "58","59","60"]
    

    override func viewDidLoad() {
        super.viewDidLoad()
       
        self.checked =  PlayerManager.shared.sleepCheck
        if  PlayerManager.shared.sleepCheck == false {
            btnToggle_info.setImage(UIImage(named:"Group-7"), for: .normal)
            lblToggleStatus.text = "Off"
            PaustimerStatus = "Off"
            lblToggleStatus.textColor = UIColor(named: "BlackColor")
            
        } else {
            
            print(totalSecond ?? "","totalSecond in Pause TimverVC ViewDidLoad")
          
            if totalSecond != nil {
             
                btnToggle_info.setImage(UIImage(named:"fontisto_toggle-off"), for: .normal)
                lblToggleStatus.text = "On"
                lblToggleStatus.textColor = UIColor.red
              
                let b = Int(Double(totalSecond)!)
               
                print(b , "totalSecond")
                seconds = (b)
                print(seconds ?? "","seconds in viewdidload")
         
                print(c1 ?? "","time in hour and minutes")
               

            }

        }
        

        txt_ReminderMsg.textColor = UIColor.gray
   
        self.view_Txt.layer.borderWidth = 1
        self.view_Txt.layer.borderColor = UIColor.lightGray.cgColor

        self.tablehours.register(UINib(nibName: "HoursMinutesCell", bundle: nil), forCellReuseIdentifier: "HoursMinutesCell")
        self.tableminutes.register(UINib(nibName: "HoursMinutesCell", bundle: nil), forCellReuseIdentifier: "HoursMinutesCell")
        tablehours.isHidden = true
        tableminutes.isHidden = true
      
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateSleepTime(_:)), name: Notification.Name.AudiobookPlayer.sleepTime, object: nil)
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print(UserDefaults.standard.object(forKey: "pauseTime") as? String ?? "")
        if let t = UserDefaults.standard.object(forKey: "pauseTime") as? String,t != "",PlayerManager.shared.sleepCheck == true{
            
            let k = t.components(separatedBy: ":")
            let h =  k.first
            let m =  k.last
            txt_minutes.text = (m ?? "0") + " Mins"
            txt_hours.text = (h ?? "0") + " Hours"
            btnToggle_info.setImage(UIImage(named:"fontisto_toggle-off"), for: .normal)
            lblToggleStatus.text = "On"
            lblToggleStatus.textColor = UIColor.red
            
            
        }
      if  PlayerManager.shared.sleepCheck == false  {
          if let t = UserDefaults.standard.object(forKey: "pauseTime") as? String,t != ""{
              let k = t.components(separatedBy: ":")
              let h =  k.first
              let m =  k.last
              txt_minutes.text = (m ?? "0") + " Mins"
              txt_hours.text = (h ?? "0") + " Hours"
            
          }else {
              self.txt_minutes.text =  "0" + " Mins"
              self.txt_hours.text =  "0" + " Hours"
          }

        }
        if let txt = UserDefaults.standard.object(forKey: "pauseTimeRe") as? String{
            self.txt_ReminderMsg.text = txt
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == tablehours {
            return hoursArray.count
        } else {
            return minutesArray.count
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 20
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == tablehours {
            
            let cell = tablehours.dequeueReusableCell(withIdentifier: "HoursMinutesCell") as! HoursMinutesCell
            cell.lbl_hoursminutes.text = hoursArray[indexPath.row]

            return cell
        }
        else {
            let cell = tableminutes.dequeueReusableCell(withIdentifier: "HoursMinutesCell") as! HoursMinutesCell
            cell.lbl_hoursminutes.text = minutesArray[indexPath.row]

           
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {



        if tableView == tablehours {
           
            if  lblToggleStatus.text == "On" {
                let a =  String(indexPath.row)
            txt_hours.text = a + " Hours"
            a1 = String(a)
            c1 = ("\(a1 ?? ""):\(b1 ?? "")")
            time1 = c1!
                print(c1 ?? "","c1")
                
                if c1 == "0:0" {
                    btnToggle_info.setImage( UIImage(named:"Group-7"), for: .normal)
                    lblToggleStatus.text = "Off"
                    PaustimerStatus = "Off"
                    lblToggleStatus.textColor = UIColor(named: "BlackColor")
                    tablehours.isHidden = true
                } else if c1 == "0:" {
                    btnToggle_info.setImage( UIImage(named:"Group-7"), for: .normal)
                    lblToggleStatus.text = "Off"
                    PaustimerStatus = "Off"
                    lblToggleStatus.textColor = UIColor(named: "BlackColor")
                    tablehours.isHidden = true
                } else {
           
            btnToggle_info.setImage(UIImage(named:"fontisto_toggle-off"), for: .normal)
                    
            lblToggleStatus.text = "On"
                PaustimerStatus = "On"
                    PlayerManager.shared.sleepCheck = true
            lblToggleStatus.textColor = UIColor.red
                    tablehours.isHidden = true }

            }
            else {
                let a =  String(indexPath.row)
                    txt_hours.text = a + " Hours"
                    a1 = String(a)
                    c1 = ("\(a1 ?? ""):\(b1 ?? "")")
                    time1 = c1!

                print(c1 as Any,"c1 in table hours")
                    if c1 == "0:0" {
                        btnToggle_info.setImage( UIImage(named:"Group-7"), for: .normal)
                        lblToggleStatus.text = "Off"
                        PaustimerStatus = "Off"
                        lblToggleStatus.textColor = UIColor(named: "BlackColor")
                        tablehours.isHidden = true
                    } else if c1 == "0:" {
                        btnToggle_info.setImage( UIImage(named:"Group-7"), for: .normal)
                        lblToggleStatus.text = "Off"
                        PaustimerStatus = "Off"
                        lblToggleStatus.textColor = UIColor(named: "BlackColor")
                        tablehours.isHidden = true
                    }else {
                    btnToggle_info.setImage(UIImage(named:"fontisto_toggle-off"), for: .normal)
                    lblToggleStatus.text = "On"
                    PaustimerStatus = "On"
                        PlayerManager.shared.sleepCheck = true
                    lblToggleStatus.textColor = UIColor.red
                        tablehours.isHidden = true }
                }
        }else{
            
            if  lblToggleStatus.text == "On" {
                let a =  String(indexPath.row)
            txt_minutes.text = a + " Mins"
            b1 = String(a)
            c1 = ("\(a1 ?? ""):\(b1 ?? "")")
            time1 = c1!
                print(time1 as Any,"time1")
 
                print(c1 as Any,"c1 in minutes tables")
                if c1 == "0:0"  {
                    btnToggle_info.setImage( UIImage(named:"Group-7"), for: .normal)
                    lblToggleStatus.text = "Off"
                    PaustimerStatus = "Off"
                    lblToggleStatus.textColor = UIColor(named: "BlackColor")
                    tableminutes.isHidden = true
                } else if  c1 == ":0"{
                    btnToggle_info.setImage( UIImage(named:"Group-7"), for: .normal)
                    lblToggleStatus.text = "Off"
                    PaustimerStatus = "Off"
                    lblToggleStatus.textColor = UIColor(named: "BlackColor")
                    tableminutes.isHidden = true
                }else {
                btnToggle_info.setImage(UIImage(named:"fontisto_toggle-off"), for: .normal)
                lblToggleStatus.text = "On"
                PaustimerStatus = "On"
                    PlayerManager.shared.sleepCheck = true
                lblToggleStatus.textColor = UIColor.red
                    tableminutes.isHidden = true
                    
                }
            }

            else {
                let a =  String(indexPath.row)
                txt_minutes.text = a + " Mins"
                b1 = String(a)
                c1 = ("\(a1 ?? ""):\(b1 ?? "")")
                time1 = c1!
             
                if c1 == "0:0"{
                    
                    btnToggle_info.setImage( UIImage(named:"Group-7"), for: .normal)
                    lblToggleStatus.text = "Off"
                    PaustimerStatus = "Off"
                    lblToggleStatus.textColor = UIColor(named: "BlackColor")
                    tableminutes.isHidden = true
                    
                } else if c1 == ":0"  {
                    
                    btnToggle_info.setImage( UIImage(named:"Group-7"), for: .normal)
                    lblToggleStatus.text = "Off"
                    PaustimerStatus = "Off"
                    lblToggleStatus.textColor = UIColor(named: "BlackColor")
                    tableminutes.isHidden = true
                    
                }
                else {
                    
                    btnToggle_info.setImage(UIImage(named:"fontisto_toggle-off"), for: .normal)
                    lblToggleStatus.text = "On"
                    PaustimerStatus = "On"
                    PlayerManager.shared.sleepCheck = true
                    lblToggleStatus.textColor = UIColor.red
                    
                    tableminutes.isHidden = true
                }

            }
        }


    }
    
    @objc func updateSleepTime(_ notification:Notification){
        guard let userInfo = notification.userInfo,
              let time = userInfo["time"] as? String,PlayerManager.shared.sleepCheck == true else{return}
        
        self.lbltime.text = time
        
        if self.lbltime.text == "00:00:00"{
            btnToggle_info.setImage( UIImage(named:"Group-7"), for: .normal)
            lblToggleStatus.text = "Off"
            PaustimerStatus = "Off"
            lblToggleStatus.textColor = UIColor(named: "BlackColor")
            UserDefaults.standard.set(nil, forKey: "pauseTime")
            UserDefaults.standard.set(nil, forKey: "pauseTimeRe")
            
           
        }else{
            btnToggle_info.setImage(UIImage(named:"fontisto_toggle-off"), for: .normal)
            lblToggleStatus.text = "On"
            PaustimerStatus = "On"
            lblToggleStatus.textColor = UIColor.red
            
        }
       
    }
    
    @IBAction func btnToggle_Action(_ sender: UIButton) {
        if checked {
            sender.setImage( UIImage(named:"Group-7"), for: .normal)
            lblToggleStatus.text = "Off"
            PaustimerStatus = "Off"
            lblToggleStatus.textColor = UIColor(named: "BlackColor")
            lbltime.text = "00:00:00"
            checked = false
            PlayerManager.shared.sleep(in: nil)
            PlayerManager.shared.sleepCheck = false
            txt_minutes.text = "0" + " Mins"
            txt_hours.text =  "0" + " Hours"
            if let t = UserDefaults.standard.object(forKey: "pauseTime") as? String,t != "",PlayerManager.shared.sleepCheck == true{
                
                let k = t.components(separatedBy: ":")
                let h =  k.first
                let m =  k.last
                txt_minutes.text = (m ?? "0") + " Mins"
                txt_hours.text = (h ?? "0") + " Hours"
                
            }
        } else {
            sender.setImage(UIImage(named:"fontisto_toggle-off"), for: .normal)
            lblToggleStatus.text = "On"
            PaustimerStatus = "On"
            lblToggleStatus.textColor = UIColor.red
            checked = true
            PlayerManager.shared.sleepCheck = true
            
            
            if let t = UserDefaults.standard.object(forKey: "pauseTime") as? String,t != "",PlayerManager.shared.sleepCheck == true{
                
                let k =  t.components(separatedBy: ":")
                let h =  k.first
                let m =  k.last
                txt_minutes.text = (m ?? "0") + " Mins"
                txt_hours.text = (h ?? "0") + " Hours"
                
            }
        }
    
    }
    
    @IBAction func BtnDone_Action(_ sender: Any) {
        
        if c1 == "0:0" {
            if let t = UserDefaults.standard.object(forKey: "pauseTime") as? String,t != ""{
                
                let k = t.components(separatedBy: ":")
                let h = (Int( k.first ?? "0") ?? 0)*60*60
                let m = (Int( k.last ?? "0") ?? 0)*60
                let p = h + m
                
                print(t,"dataToBeSent",p)
           
                PlayerManager.shared.sleepCheck = true
                PlayerManager.shared.sleep(in: p)
                btnToggle_info.setImage(UIImage(named:"fontisto_toggle-off"), for: .normal)
                lblToggleStatus.text = "On"
                UserDefaults.standard.set(self.txt_ReminderMsg.text ?? "", forKey: "pauseTimeRe")
                self.dismiss(animated: true)
            }else{
                btnToggle_info.setImage(UIImage(named:"Group-7"), for: .normal)
                lblToggleStatus.text = "Off"
                lblToggleStatus.textColor = UIColor(named: "BlackColor")
                PaustimerStatus = "Off"
                showAlert("", message: "Please Select Valid Time First.", style: .alert)
            }
            
        }
        else {
            if self.delegate1 != nil && self.c1 != nil   {
                var dataToBeSent = c1
                if PaustimerStatus == "Off"  {
                    dataToBeSent = ""
                } else {
                    END_TIME = dataToBeSent!
                    PaustimerStatus = "On"
                }
                
                let k = dataToBeSent?.components(separatedBy: ":")
                let h = (Int( k?.first ?? "0") ?? 0)*60*60
                let m = (Int( k?.last ?? "0") ?? 0)*60
                let p = h + m
                PlayerManager.shared.sleep(in: p)
                print(dataToBeSent ?? "","dataToBeSent",p)
             
                PlayerManager.shared.sleepCheck = true
                btnToggle_info.setImage(UIImage(named:"fontisto_toggle-off"), for: .normal)
                lblToggleStatus.text = "On"
                UserDefaults.standard.set(dataToBeSent, forKey: "pauseTime")
                self.dismiss(animated: true)
                print(END_TIME ?? "","END_TIME in BtnDone")
                UserDefaults.standard.set(self.txt_ReminderMsg.text ?? "", forKey: "pauseTimeRe")
                self.dismiss(animated: true)
            }
            else {
                if let t = UserDefaults.standard.object(forKey: "pauseTime") as? String,t != ""{
                    
                    let k = t.components(separatedBy: ":")
                    let h = (Int( k.first ?? "0") ?? 0)*60*60
                    let m = (Int( k.last ?? "0") ?? 0)*60
                    let p = h + m
                    
                    print(t,"dataToBeSent",p)
                  
                    PlayerManager.shared.sleepCheck = true
                    PlayerManager.shared.sleep(in: p)
                    btnToggle_info.setImage(UIImage(named:"fontisto_toggle-off"), for: .normal)
                    lblToggleStatus.text = "On"
                    UserDefaults.standard.set(self.txt_ReminderMsg.text ?? "", forKey: "pauseTimeRe")
                    self.dismiss(animated: true)
                } else{
                    showAlert("", message: "Please Select Time First.", style: .alert)
              
                }
                
            }
        }
      
    }
         @objc func timerAction() {
             
                var hours: Int
                 var minutes: Int
                 var seconds1: Int

                 if seconds == 0 {
                    // timer.invalidate()
                 }
                seconds = seconds - 1
                 hours = seconds / 3600
                 minutes = (seconds % 3600) / 60
                 seconds1 = (seconds % 3600) % 60
             if seconds == 0 {
                 seconds1 = 0
               //  timer.invalidate()
                 self.lbltime.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds1)
             } else {
                 self.lbltime.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds1) }
            
        }
    
    
    @IBAction func btnCross_Action(_ sender: Any) {
        
        self.dismiss(animated: true)
      
    }
    @IBAction func btn_SelectHoursAction(_ sender: Any) {
        tablehours.isHidden = false
     
    }
    
    @IBAction func btn_SelectMinutesAction(_ sender: Any) {

        tableminutes.isHidden = false
     
    }
  
}


