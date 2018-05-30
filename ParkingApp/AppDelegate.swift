//
//  AppDelegate.swift
//  ParkingApp
//
//  Copyright © 2017 Benjamin Hardesty. All Rights Reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import MMDrawerController

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var centerContainer: MMDrawerController?
    
    var ipAddress:String = ""
    
    let colorPrimaryLight = UIColor.init(red: 230/255, green: 242/255, blue: 255/255, alpha: 1.0)
    let colorPrimary = UIColor.init(red: 51/255, green: 153/255, blue: 255/255, alpha: 1.0)
    let colorPrimaryDark = UIColor.init(red: 0/255, green: 89/255, blue: 179/255, alpha: 1.0)
    let colorAccent = UIColor.init(red: 51/255, green: 204/255, blue: 51/255, alpha: 1.0)
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Google Services API Keys.
        GMSServices.provideAPIKey("")
        GMSPlacesClient.provideAPIKey("")
        
        
        // Check if the user was logged in last time they closed their app.
        let isUserLoggedIn = UserDefaults.standard.bool(forKey: "isUserLoggedIn")
        
        // If the user was logged in, validate their session id against the server.
        if isUserLoggedIn {
            
            var sessionid = UserDefaults.standard.object(forKey: "sessionid")
            
            if sessionid == nil {
                sessionid = "0"
            }
            
            let myURL = URL(string: "https://" + ipAddress + "")
            let request = NSMutableURLRequest(url: myURL!)
            request.httpMethod = "POST"
            let postString = "sessionid=\(String(describing: sessionid!))"
            request.httpBody = postString.data(using: String.Encoding.utf8)
            
            let task = URLSession.shared.dataTask(with: request as URLRequest) {
                data, response, error in
                
                // If the server doesn't respond, bring the user to the login screen.
                if data == nil {
                    DispatchQueue.main.async(execute: {
                        self.switchToLoginViewController()
                    })
                    return
                }
                
                do{
                    let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
                    
                    if let parseJSON = json {
                        let resultValue = parseJSON["status"] as? String
                        
                        if(resultValue == "Success") {
                            
                            // If the session is valid, bring the user to the map screen.
                            DispatchQueue.main.async(execute: {
                                _ = self.window!.rootViewController
                                
                                let mainStoryBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                                
                                let centerViewController = mainStoryBoard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
                                
                                let leftViewController = mainStoryBoard.instantiateViewController(withIdentifier: "LeftSideViewController") as! LeftSideViewController
                                
                                let leftSideNav = UINavigationController(rootViewController: leftViewController)
                                let centerNav = UINavigationController(rootViewController: centerViewController)
                                
                                self.centerContainer = MMDrawerController(center: centerNav, leftDrawerViewController: leftSideNav)
                                
                                self.centerContainer!.openDrawerGestureModeMask = MMOpenDrawerGestureMode.panningCenterView
                                self.centerContainer!.closeDrawerGestureModeMask = MMCloseDrawerGestureMode.panningCenterView
                                
                                self.window!.rootViewController = self.centerContainer
                                self.window!.makeKeyAndVisible()
                            })
                        } else {
                            
                            // If the session is not valid, bring the user to the login screen.
                            DispatchQueue.main.async(execute: {
                                self.switchToLoginViewController()
                            })
                        }
                    } else {
                        
                        // If the data returned is corrupted, bring the user to the login screen.
                        DispatchQueue.main.async(execute: {
                            self.switchToLoginViewController()
                        })
                    }
                } catch _ as NSError {
                    
                    // If the server returns an error, bring the user to the login screen.
                    DispatchQueue.main.async(execute: {
                        self.switchToLoginViewController()
                    })
                }
            }
            task.resume()
        } else {
            
            // If the user was not logged in the last time they closed the app, bring them to the login screen.
            DispatchQueue.main.async(execute: {
                self.switchToLoginViewController()
            })
        }
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    /**
        Logs the user out on the client and server side. User is brought to the login screen.
    */
    func logoutFunction() {
        var sessionid = UserDefaults.standard.object(forKey: "sessionid")
        
        if sessionid == nil {
            sessionid = "0"
        }
        
        let myURL = URL(string: "https://" + ipAddress + "")
        let request = NSMutableURLRequest(url: myURL!)
        request.httpMethod = "POST"
        
        let postString = "sessionid=\(String(describing: sessionid!))"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if data == nil {
                return
            }
            
            do{
                let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
                
                if let parseJSON = json {
                    let resultValue = parseJSON["status"] as? String
                    
                    // Bring the user to the login screen.
                    DispatchQueue.main.async(execute: {
                        
                        let mainStoryBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        
                        UserDefaults.standard.set(false, forKey: "isUserLoggedIn")
                        UserDefaults.standard.synchronize()
                        let loginViewController = mainStoryBoard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
                        self.window?.rootViewController = loginViewController
                    })
                }
            } catch _ as NSError {
                
                // If session logout fails on the server, still log the user out on the app and delete session id on client side. Error will be logged on the server for review.
                DispatchQueue.main.async(execute: {
                    let mainStoryBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    UserDefaults.standard.set(false, forKey: "isUserLoggedIn")
                    UserDefaults.standard.synchronize()
                    let loginViewController = mainStoryBoard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
                    self.window!.rootViewController = loginViewController
                })
            }
        }
        task.resume()
    }
    
    // Bring the user to the login screen.
    func switchToLoginViewController(){
        
        let mainStoryBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let centerViewController = mainStoryBoard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        let centerNav = UINavigationController(rootViewController: centerViewController)
        self.centerContainer = MMDrawerController(center: centerNav, leftDrawerViewController: nil)
        
        self.window!.rootViewController = self.centerContainer
        self.window!.makeKeyAndVisible()
    }


}

