//
//  EndPoints.swift
//  SpeedListners
//
//  Created by ravi on 14/12/22.
//


import Foundation


enum baseURL {
    
    static let baseURL = "https://speedlistener.yesitlabs.co/api/"
    
}

enum appEndPoints{
    
    
    static let login = "UserLogin" // UserLogin  ApiNumber 1
    
    static let signup = "signup" // signup  ApiNumber 2
    
    static let verify_otp = "verify_otp" // verify_otp  ApiNumber 3
    
    static let create_password = "create_password" // create_password  ApiNumber 4
    
    static let profile_create = "profile_create" // profile_create  ApiNumber 5
    
    static let all_faq = "all_faq" // all_faq  ApiNumber 6
    
    static let about_us = "about_us" // about_us  ApiNumber 7
    
    static let terms_conditions = "terms_conditions" // terms_conditions  ApiNumber 8
    
    static let privacy_policy = "privacy_policy" // privacy_policy  ApiNumber 9
    
    static let GetUserByID = "GetUserByID" // GetUserByID  ApiNumber 10
    
    static let folder_create_name = "folder_create_name" // folder_create_name  ApiNumber 11
    
    static let insert_chapter = "insert_chapter" // insert_chapter  ApiNumber 12
    
    static let chapter_all_data = "chapter_all_data" // chapter_all_data  ApiNumber 13
    
    static let send_forget_password = "send_forget_password" // send_forget_password  ApiNumber 14
    
    static let reset_password = "reset_password" // reset_password  ApiNumber 15
    
    static let feedback_user = "feedback_user" // feedback_user  ApiNumber 16
    
    static let delete_user = "delete_user" // delete_user  ApiNumber 17
    
    static let chapter_list = "chapter_list" // chapter_list  ApiNumber 18
    
    static let folder_list = "folder_list"
    // folder_list  ApiNumber 19 new project
    
    static let chapter_all_dataaa = "chapter_all_dataaa"
 
}


