//
//  AppDelegate.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//

import UIKit
import RealmSwift
import GoogleAPIClientForREST
import AppAuth
import GTMAppAuth

protocol GSAppDelegate {//子（呼び出し元)がAppDelegateクラス、親がGameSceneクラス
    func applicationWillResignActive()
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var gsDelegate: GSAppDelegate?
    var window: UIWindow?
    /// GoogleDriveサービスドライブ
    let googleDriveServiceDrive = GTLRDriveService()
    /// 認証
    var googleDriveAuthorization: GTMAppAuthFetcherAuthorization?
    /// 現在の認証フロー
    var googleDriveCurrentAuthorizationFlow: OIDExternalUserAgentSession?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let config = Realm.Configuration(deleteRealmIfMigrationNeeded: true)
        Realm.Configuration.defaultConfiguration = config
        initGoogleDrive()
        
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        // 現在のGoogleDriveの認証フローが有効な場合
        if let googleDriveCurrentAuthorizationFlow = googleDriveCurrentAuthorizationFlow {
            if googleDriveCurrentAuthorizationFlow.resumeExternalUserAgentFlow(with: url) {
                self.googleDriveCurrentAuthorizationFlow = nil
                return true
            }
        }
        return false
    }
    
    /**
     GoogleDriveの初期化を行います。
     */
    func initGoogleDrive() {
        // GoogleDriveのサインイン状態をキーチェーンからロードします。
        if let authorization = GTMAppAuthFetcherAuthorization(fromKeychainForName: "GDKeyChane") {
            //
            // GTM認証結果を設定します。
            self.setGtmAuthorization(authorization)
        }
        
        googleDriveServiceDrive.shouldFetchNextPages = true 
    }
    
    /**
     GTM認証結果を設定します。
     
     - Parameter authorization: 認証結果
     */
    func setGtmAuthorization(_ authorization: GTMAppAuthFetcherAuthorization?) {
        if googleDriveAuthorization == authorization {
            return
        }
        
        // クロージャーで返却されたオブジェクトをインスタンス変数に保存します。
        googleDriveAuthorization = authorization
        googleDriveServiceDrive.authorizer = googleDriveAuthorization
        // GoogleDriveサインイン状態を変更する。
        googleDriveSignInStateChanged()
        
    }
    
    /**
     GoogleDriveサインイン状態を変更します。
     */
    func googleDriveSignInStateChanged() {
        // GoogleDriveのサインイン状態を保存します。
        saveGoogleDriveSignInState()
    }
    
    /**
     GoogleDriveのサインイン状態をキーチェーンに保存します。
     */
    func saveGoogleDriveSignInState() {
        if let authorization = googleDriveAuthorization, authorization.canAuthorize() {
            // 認証済みの場合
            GTMAppAuthFetcherAuthorization.save(authorization, toKeychainForName: "GDKeyChane")
            
        } else {
            // 未認証の場合
            GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: "GDKeyChane")
        }
    }
    
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
        print("move from active to inactive state")
        
        
        self.gsDelegate?.applicationWillResignActive()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        print("DidEnterBackground")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        print("WillEnterForeground")
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("DidBecomeActive")
        
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("WillTerminate")
    }
    
    
}
