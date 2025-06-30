//
//  ListeningSpeedVC.swift
//  SpeedListners
//
//Created by Satyam Dwivedi on 16/06/23.
//

import UIKit
import DropDown

protocol DelegateforListeningSpeedVC {
    func MethodforPop()
    func sendDataToFirstViewController(myData: Float)
    
}


class ListeningSpeedVC: UIViewController {
    
    func MethodforPop() {
        if self.children.count > 0 {
            let viewControllers:[UIViewController] = self.children
            for viewContoller in viewControllers{
                self.tabBarController?.tabBar.isHidden = false
                viewContoller.willMove(toParent: nil)
                viewContoller.view.removeFromSuperview()
                viewContoller.removeFromParent()
            }
        }
        
        
    }
    @IBOutlet weak var speedSlider_Set: UISlider!
    @IBOutlet weak var bookChapterArtWork: UIImageView!
    var delegateSpeedListeningVC:DelegateforListeningSpeedVC? = nil
    @IBOutlet weak var lblValue: UILabel!
    var v1 : String!
    let topMenu = DropDown()
    var checked = false
    @IBOutlet weak var btn_Toggle: UIButton!
    @IBOutlet weak var btnToggle_info: UIButton!
    @IBOutlet weak var lblToggle_Title: UILabel!
    @IBOutlet weak var view_player: UIView!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var pyramidStackBg: UIView!
    lazy var dropDowns: [DropDown] = {
        return [
            self.topMenu
        ]
    }()
    @IBOutlet weak var scrollView: UIScrollView!
    var currentValue: Float = 1.0
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.scrollView.delegate = self
        let c = (currentValue)
        print(currentValue,"c currentValue")
        self.currentValue = PlayerManager.shared.speed
        
        if  c == 0.0 {
            let v = 1.0
            lblValue.text = "\(PlayerManager.shared.speed) x"
            speedSlider_Set.setValue(Float(v), animated: true)
        } else {
            
            lblValue.text = "\(PlayerManager.shared.speed) x"
            speedSlider_Set.setValue(Float(currentValue), animated: true)
        }
        lblValue.text = "\(PlayerManager.shared.speed) x"
        
        setupPyramidUI()
    }
    override func viewWillAppear(_ animated: Bool) {
        lblValue.textColor = UIColor(named: "VoilatColor")
        self.bookChapterArtWork.image = PlayerManager.shared.currentBook?.artwork
        self.currentValue = PlayerManager.shared.speed
        lblValue.text = "\(PlayerManager.shared.speed) x"
    }
    
    func setupPyramidUI() {
        let pyramidValues: [[String]] = [
            ["15.0x"],
            ["13.0x", "14.0x"],
            ["10.0x", "11.0x", "12.0x"],
            ["6.0x", "7.0x", "8.0x", "9.0x"],
            ["1.0x", "2.0x", "3.0x", "4.0x", "5.0x"]
        ]
        
        let pyramidStack = UIStackView()
        pyramidStack.axis = .vertical
        pyramidStack.alignment = .center
        pyramidStack.spacing = 8
        pyramidStack.translatesAutoresizingMaskIntoConstraints = false
        pyramidStackBg.addSubview(pyramidStack)
        NSLayoutConstraint.activate([
            pyramidStack.topAnchor.constraint(equalTo: speedSlider_Set.bottomAnchor, constant: 10),
            pyramidStack.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        for row in pyramidValues {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 8
            
            for value in row {
                let button = UIButton(type: .system)
                button.setTitle(value, for: .normal)
                button.setTitleColor(UIColor(named: "whitecolor"), for: .normal)
                button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
                
                button.backgroundColor = UIColor(named: "VoilatColor") /*UIColor.systemPurple.withAlphaComponent(0.3)*/
                button.layer.cornerRadius = 0
                button.clipsToBounds = true
                button.widthAnchor.constraint(equalToConstant: 65).isActive = true
                button.heightAnchor.constraint(equalToConstant: 45).isActive = true
                button.addTarget(self, action: #selector(pyramidButtonTapped(_:)), for: .touchUpInside)
                rowStack.addArrangedSubview(button)
            }
            
            pyramidStack.addArrangedSubview(rowStack)
        }
        
    }
    
    @objc func pyramidButtonTapped(_ sender: UIButton) {
        guard let title = sender.currentTitle else { return }
        print("Tapped: \(title)")
        let cleanValue = title.replacingOccurrences(of: "x", with: "").trimmingCharacters(in: .whitespaces)
        guard let value = Float(cleanValue) else { return }
        
        currentValue = value
        lblValue.text = "\(currentValue) x"
        speedSlider_Set.setValue(value, animated: true)
        sender.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.6)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            sender.backgroundColor = UIColor(named: "VoilatColor")
          
        }
    }
    
    @IBAction func speedSlider(_ sender: UISlider) {
        currentValue = Float(Int(speedSlider_Set.value))
        print("Slider changing to \(currentValue) ?")
        lblValue.text = "\(currentValue) x"
    }
    
    @IBAction func btnDecrease_Action(_ sender: Any) {
        currentValue =  currentValue - 0.1
        var currentValue1 = round(currentValue * 100) / 100.0
        if currentValue >= 0 {
            speedSlider_Set.setValue(currentValue1, animated: true)
            print(currentValue1,"currentValue1")
            lblValue.text = "\(currentValue1) x" } else {
                currentValue1 = 0.0
                speedSlider_Set.setValue(currentValue1, animated: true)
                print(currentValue,"currentValue")
                lblValue.text = "\(currentValue1) x"
                print("you cant.")
            }
    }
    @IBAction func btnIncrease_Action(_ sender: Any) {
        currentValue =  currentValue + 0.1
        var currentValue1 = round(currentValue * 100) / 100.0
        if currentValue <= 15 {
            speedSlider_Set.setValue(currentValue1, animated: true)
            print(currentValue1,"currentValue")
            lblValue.text = "\(currentValue1) x"
        } else {
            currentValue1 = 15.0
            speedSlider_Set.setValue(currentValue1, animated: true)
            print(currentValue1,"currentValue")
            lblValue.text = "\(currentValue1) x"
            print("you cant.")
        }
    }
    @IBAction func btnCross_Action(_ sender: Any) {
        self.delegateSpeedListeningVC?.MethodforPop()
        self.dismiss(animated: true)
    }
    @IBAction func btnDone_Action(_ sender: Any) {
        
        if self.delegateSpeedListeningVC != nil && self.lblValue.text != nil {
            let currentValue1 = round(currentValue * 100) / 100.0
            let dataToBeSent = currentValue1
            self.delegateSpeedListeningVC?.sendDataToFirstViewController(myData: dataToBeSent)
            self.dismiss(animated: true)
            
        }
        
    }
   
    @IBAction func btnDot_Action(_ sender: UIButton) {
  
    }
    
    
    
}


