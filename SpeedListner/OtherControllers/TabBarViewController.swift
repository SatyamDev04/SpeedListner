//
//  TabBarViewController.swift
//  SpeedListners
//
//  Created by ravi on 9/08/22.
//

import UIKit

class TabBarVC: UIViewController , UITabBarControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.pushViewController(self.tabbarFunc(), animated: false)
        self.navigationController?.isNavigationBarHidden = true
    }
    private func tabbarFunc() ->UITabBarController{
        
        //self delagting
       // self.delegate = self
        
        //library tab
        let tabBarCon = UITabBarController()
        let libraryVC = self.storyboard?.instantiateViewController(withIdentifier: "ListBooksViewController") as? ListBooksViewController
        var nav1 : UINavigationController? = nil
        if let aVC = libraryVC {
            nav1 = UINavigationController(rootViewController: aVC)
        }
        nav1?.navigationBar.isHidden = true
         
        // nowPlaying tab
        
        let nowPlayingVC = self.storyboard?.instantiateViewController(withIdentifier: "PlayerViewController") as? PlayerViewController
        let nowPlayingVC2 = self.storyboard?.instantiateViewController(withIdentifier: "PlayerViewController2") as? PlayerViewController
        var nav2 :UINavigationController? = nil
        nav2?.navigationBar.isHidden = true
         let d = UserDefaults.standard.object(forKey: "desable") as? Bool ?? false
        if d {
            if let aVC = nowPlayingVC2 {
                nav2 = UINavigationController(rootViewController: aVC)
            }
           
        }else{
            if let aVC = nowPlayingVC {
                nav2 = UINavigationController(rootViewController: aVC)
            }
           
        }
        nav2?.navigationBar.isHidden = true
       
        //offers tab
      
        let uploadVC = self.storyboard?.instantiateViewController(withIdentifier: "UploadBookVC") as? UploadBookVC
        var nav3 :UINavigationController? = nil
        if let aVC = uploadVC {
            nav3 = UINavigationController(rootViewController: aVC)
        }
        nav3?.navigationBar.isHidden = true
        tabBarCon.viewControllers = [nav1 , nav2 , nav3 ] as? [UIViewController]
//        let tabBarItemsAll: UITabBar = tabBarCon.tabBar
        tabBarCon.tabBar.barTintColor = #colorLiteral(red: 0.5810584426, green: 0.1285524964, blue: 0.5745313764, alpha: 1)
        tabBarCon.tabBar.backgroundColor = #colorLiteral(red: 0.3880267739, green: 0.088985838, blue: 0.4682590961, alpha: 1)
        tabBarCon.tabBar.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        //setting buttons
      //  tabBarItemsAll.unselectedItemTintColor = .gray
       
        //buttons images
        let libraryImage = UIImage(named: "9")
        let nowPlyImage = UIImage(named : "10")
        let uploadImage = UIImage(named: "11")
     
        
        
        // buttons shakhsiyan
        let libraryButton = UITabBarItem(title: "Library", image: libraryImage, selectedImage: libraryImage)
        let nowPlyButton = UITabBarItem(title: "Now Playing", image: nowPlyImage, selectedImage: nowPlyImage)
        let uploadButton = UITabBarItem(title: "Upload", image: uploadImage, selectedImage: uploadImage)
     
        
        nav1?.tabBarItem = libraryButton
        nav2?.tabBarItem = nowPlyButton
        nav3?.tabBarItem = uploadButton
       
       return tabBarCon
    }
}
