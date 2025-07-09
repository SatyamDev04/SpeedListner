//
//  PauseTimerVC.swift
//  SpeedListners
//
//Created by Satyam Dwivedi on 16/06/23.
//

//
//  PauseTimerVC.swift
//

import UIKit
import DropDown

protocol DelegateforPauseTimer: AnyObject {
    func MethodforPop()
    func sendDataToPlayerVC(myData: String, PaustimerStatus: String)
}

class PauseTimerVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {

    // MARK: - IBOutlets
    @IBOutlet weak var txt_ReminderMsg: UITextView!
    @IBOutlet weak var view_Txt: UIView!
    @IBOutlet weak var lblToggleStatus: UILabel!
    @IBOutlet weak var btnToggle_info: UIButton!
    @IBOutlet weak var tableminutes: UITableView!
    @IBOutlet weak var tablehours: UITableView!
    @IBOutlet weak var txt_minutes: UITextField!
    @IBOutlet weak var txt_hours: UITextField!
    @IBOutlet weak var lbltime: UILabel!

    // MARK: - Properties
    weak var delegate1: DelegateforPauseTimer?

    var PaustimerStatus: String = "Off"
    var PaustimerStatusFromNowVC: String?
    var counter = 0
    var checked = false

    var a1: String?
    var b1: String?
    var c1: String?
    var time1: String?
    var seconds: Int?
    var totalSecond: String?

    let hoursArray = (0...12).map { "\($0)" }
    let minutesArray = (0...60).map { "\($0)" }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupObservers()
        loadInitialData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSavedValues()
    }

    // MARK: - Setup
    func setupUI() {
        checked = PlayerManager.shared.sleepCheck

        btnToggle_info.setImage(UIImage(named: checked ? "fontisto_toggle-off" : "Group-7"), for: .normal)
        lblToggleStatus.text = checked ? "On" : "Off"
        lblToggleStatus.textColor = checked ? .red : UIColor(named: "BlackColor")

        txt_ReminderMsg.textColor = .gray
        view_Txt.layer.borderWidth = 1
        view_Txt.layer.borderColor = UIColor.lightGray.cgColor

        tablehours.register(UINib(nibName: "HoursMinutesCell", bundle: nil), forCellReuseIdentifier: "HoursMinutesCell")
        tableminutes.register(UINib(nibName: "HoursMinutesCell", bundle: nil), forCellReuseIdentifier: "HoursMinutesCell")

        tablehours.isHidden = true
        tableminutes.isHidden = true
    }

    func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateSleepTime(_:)), name: Notification.Name.AudiobookPlayer.sleepTime, object: nil)
    }

    func loadInitialData() {
        if let totalSecond = totalSecond {
            let b = Int(Double(totalSecond) ?? 0)
            seconds = b
            lblToggleStatus.text = "On"
            lblToggleStatus.textColor = .red
            btnToggle_info.setImage(UIImage(named: "fontisto_toggle-off"), for: .normal)
        }
        if !PlayerManager.shared.sleepCheck {
            btnToggle_info.setImage(UIImage(named: "Group-7"), for: .normal)
            lblToggleStatus.text = "Off"
            PaustimerStatus = "Off"
            lblToggleStatus.textColor = UIColor(named: "BlackColor")
            UserDefaults.standard.removeObject(forKey: "pauseTime")
            UserDefaults.standard.removeObject(forKey: "pauseTimeRe")
            self.txt_ReminderMsg.text = ""
            self.txt_minutes.text = "0 Mins"
            self.txt_hours.text = "0 Hours"
            txt_ReminderMsg.isUserInteractionEnabled = true
            PlayerManager.shared.sleepCheck = false
        }
    }

    func loadSavedValues() {
        if let pauseTime = UserDefaults.standard.string(forKey: "pauseTime"), !pauseTime.isEmpty {
            let components = pauseTime.components(separatedBy: ":")
            txt_hours.text = "\(components.first ?? "0") Hours"
            txt_minutes.text = "\(components.last ?? "0") Mins"
        } else {
            txt_hours.text = "0 Hours"
            txt_minutes.text = "0 Mins"
        }

        txt_ReminderMsg.text = UserDefaults.standard.string(forKey: "pauseTimeRe") ?? ""
    }

    // MARK: - Table View
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableView == tablehours ? hoursArray.count : minutesArray.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 20
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HoursMinutesCell") as! HoursMinutesCell
        cell.lbl_hoursminutes.text = tableView == tablehours ? hoursArray[indexPath.row] : minutesArray[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == tablehours {
            a1 = hoursArray[indexPath.row]
            txt_hours.text = "\(a1 ?? "0") Hours"
        } else {
            b1 = minutesArray[indexPath.row]
            txt_minutes.text = "\(b1 ?? "0") Mins"
        }

        c1 = "\(a1 ?? "0"):\(b1 ?? "0")"
        print(c1 ?? "", "c1")
        if c1 == "0:0" || c1 == ":0" || c1 == "0:" || c1 == ":"{
            checked = false
            PlayerManager.shared.sleepCheck = checked
          
        }else{
            
            checked = true
            PlayerManager.shared.sleepCheck = checked
        }
        
        updateToggleStatusUI()

        tablehours.isHidden = true
        tableminutes.isHidden = true
    }

    func updateToggleStatusUI() {
        if !checked{
            btnToggle_info.setImage(UIImage(named: "Group-7"), for: .normal)
            lblToggleStatus.text = "Off"
            PaustimerStatus = "Off"
            lblToggleStatus.textColor = UIColor(named: "BlackColor")
            checked = false
        } else {
            btnToggle_info.setImage(UIImage(named: "fontisto_toggle-off"), for: .normal)
            lblToggleStatus.text = "On"
            PaustimerStatus = "On"
            PlayerManager.shared.sleepCheck = true
            lblToggleStatus.textColor = .red
            checked = true
        }
    }

    // MARK: - Notification Handler
    @objc func updateSleepTime(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let time = userInfo["time"] as? String,
              PlayerManager.shared.sleepCheck else { return }

        lbltime.text = time
        txt_ReminderMsg.isUserInteractionEnabled = false
        if time == "00:00:00" {
            btnToggle_info.setImage(UIImage(named: "Group-7"), for: .normal)
            lblToggleStatus.text = "Off"
            PaustimerStatus = "Off"
            lblToggleStatus.textColor = UIColor(named: "BlackColor")
            UserDefaults.standard.removeObject(forKey: "pauseTime")
            UserDefaults.standard.removeObject(forKey: "pauseTimeRe")
            self.txt_ReminderMsg.text = ""
            self.txt_minutes.text = "0 Mins"
            self.txt_hours.text = "0 Hours"
            txt_ReminderMsg.isUserInteractionEnabled = true
            PlayerManager.shared.sleepCheck = false
        } else {
            updateToggleStatusUI()
        }
    }

    // MARK: - Actions
    
    @IBAction func btnToggle_Action(_ sender: UIButton) {
        checked.toggle()
        PlayerManager.shared.sleepCheck = checked
        updateToggleStatusUI()

        if !checked {
            lbltime.text = "00:00:00"
            PlayerManager.shared.sleep(in: nil)
            PlayerManager.shared.sleepCheck = false
            txt_hours.text = "0 Hours"
            txt_minutes.text = "0 Mins"
            c1 = "0:0"
        } else {
            if let pauseTime = UserDefaults.standard.string(forKey: "pauseTime"), !pauseTime.isEmpty {
                let components = pauseTime.components(separatedBy: ":")
                txt_hours.text = "\(components.first ?? "0") Hours"
                txt_minutes.text = "\(components.last ?? "0") Mins"
            }
        }
    }

    @IBAction func BtnDone_Action(_ sender: Any) {
        let timeString = c1 ?? UserDefaults.standard.string(forKey: "pauseTime")

        guard let dataToBeSent = timeString,
              !dataToBeSent.isEmpty,
              !["0:0", "0:", ":0"].contains(dataToBeSent) else {
            showAlert("", message: "Please Select Valid Time First.", style: .alert)
            return
        }
        guard  ["00:00","00:00:00","0:0", "0:", ":0"].contains(self.lbltime.text ?? "") else {
            self.dismiss(animated: true)
            return
        }
        let components = dataToBeSent.components(separatedBy: ":")
        let hours = (Int(components.first ?? "0") ?? 0) * 60 * 60
        let minutes = (Int(components.last ?? "0") ?? 0) * 60
        let totalSeconds = hours + minutes

        PlayerManager.shared.sleep(in: totalSeconds)
        PlayerManager.shared.sleepCheck = true
        updateToggleStatusUI()

        UserDefaults.standard.set(dataToBeSent, forKey: "pauseTime")
        UserDefaults.standard.set(txt_ReminderMsg.text ?? "", forKey: "pauseTimeRe")
        delegate1?.sendDataToPlayerVC(myData: dataToBeSent, PaustimerStatus: PaustimerStatus)

        self.dismiss(animated: true)
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

    // MARK: - Timer Action (Optional)
    @objc func timerAction() {
        guard let remaining = seconds, remaining > 0 else { return }
        seconds = remaining - 1

        let hrs = seconds! / 3600
        let mins = (seconds! % 3600) / 60
        let secs = (seconds! % 3600) % 60
        lbltime.text = String(format: "%02d:%02d:%02d", hrs, mins, secs)
    }
}
