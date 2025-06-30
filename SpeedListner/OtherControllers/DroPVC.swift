//
//  DroPVC.swift
//  SpeedListners
//
//  Created by ravi on 21/08/22.
//

import UIKit
import DropDown

class DroPVC: UIViewController {
    
    let topMenu = DropDown()
    let DownMenu = DropDown()
    
    lazy var dropDowns: [DropDown] = {
        return [
            self.topMenu,
            self.DownMenu
        ]
    }()
    

    @IBOutlet weak var txt2: UITextField!
    @IBOutlet weak var txt1: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

     
    }
    
    @IBAction func btn1(_ sender: UIButton) {
        
        self.topMenu.anchorView = sender
        self.topMenu.bottomOffset = CGPoint(x: 0, y: sender.bounds.height + 8)
        self.topMenu.textColor = .black
        self.topMenu.cornerRadius = 5.0

        self.topMenu.separatorColor = .clear
        self.topMenu.selectionBackgroundColor = .clear
        self.topMenu.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        self.topMenu.dataSource.removeAll()
        
        
        
       self.topMenu.dataSource.append(contentsOf: ["Profile","Settings","Bookmark"])
        
        let imagesArr = ["Vector","Settings","bi_bookmark-fill"]
        
        
        
        topMenu.cellNib = UINib(nibName: "DropDownCell", bundle: nil)
        topMenu.customCellConfiguration = { index, title, cell in
            
            guard let cell = cell as? MyCell1 else {
                return
            }
            cell.img1.image = UIImage(named: imagesArr[index])//
        }
        topMenu.selectionAction = { [unowned self] (index, item) in
            if index == 0 {
                

      
            }else{

            }

        }
       
        self.topMenu.show()
       
    }
    
    @IBAction func btn2(_ sender: UIButton) {
        
        self.DownMenu.anchorView = sender
        self.DownMenu.bottomOffset = CGPoint(x: 0, y: sender.bounds.height + 8)
        self.DownMenu.textColor = .black
        self.DownMenu.cornerRadius = 5.0

        self.DownMenu.separatorColor = .clear
        self.DownMenu.selectionBackgroundColor = .clear
        self.DownMenu.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        self.DownMenu.dataSource.removeAll()
        
       self.DownMenu.dataSource.append(contentsOf: ["Profile","Settings","ravi"])
       
        topMenu.cellNib = UINib(nibName: "DropDownCell", bundle: nil)
        topMenu.customCellConfiguration = { index, title, cell in
            
            guard let cell = cell as? MyCell1 else {
                return
            }
           
        }
        topMenu.selectionAction = { [unowned self] (index, item) in
            if index == 0 {
                
              

      
            }else{

            }

        }
        self.DownMenu.show()
        
        
    }
    
}
