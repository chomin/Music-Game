//
//  GameViewController.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//


import UIKit
import SpriteKit
import GameplayKit
import GTMAppAuth
import GoogleAPIClientForREST

class GameViewController: UIViewController {
    
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    func moveToCMScene(){
        let scene = ChooseMusicScene(size: view.bounds.size)
        let skView2 = SKView(frame: view.frame)
        skView2.showsFPS = true
        skView2.showsNodeCount = true
        skView2.showsDrawCount = true
        
        skView2.ignoresSiblingOrder = true
        scene.scaleMode = .resizeFill
        
        view.addSubview(skView2)
        
        skView2.presentScene(scene)  // ChooseMusicSceneに移動
    }
    
    /**
     ブラウザ経由のGoogleDrive認証を行います。
     参考: https://github.com/google/GTMAppAuth
     http://qiita.com/doki_k/items/fc317dafd714967809cd
     */
    func authGoogleDriveInBrowser() {
        // issuerのURLを生成します。
        guard let issuer = URL(string: "https://accounts.google.com") else {
            // URLが生成できない場合、処理を終了します。
            // 念のためのチェックです。
            // 必要に応じてエラー処理を行っていください。
            return
        }
        
        // リダイレクト先URLを生成します。
        // <GoogleDriveのクライアントID>には、"SwiftでGoogleDrive APIを使用する準備を行う"で取得した
        // クライアントIDを設定してください。 BundleIdentifier依存なので端末ごとに変更する必要あり？
        let redirectUriString = String(format: "com.googleusercontent.apps.%@:/oauthredirect", "724041097326-ti30u6m8583k6bkql2d9fs0tmt67cm18")
        guard let redirectURI = URL(string: redirectUriString) else {
            // URLが生成できない場合、処理を終了します。
            // 念のためのチェックです。
            // 必要に応じてエラー処理を行っていください。
            print("redirectURI生成に失敗")
            return
        }
        
        // エンドポイントを検索します。
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { configuration, error in
            guard let configuration = configuration else {
                self.appDelegate.setGtmAuthorization(nil)
                return
            }
            
            // 認証要求オブジェクトを作成します。
            // クライアントIDを設定してください。 BundleIdentifier依存なので端末ごとに変更する必要あり？
            let request = OIDAuthorizationRequest(
                configuration: configuration,
                clientId: "724041097326-ti30u6m8583k6bkql2d9fs0tmt67cm18",
                scopes: ["https://www.googleapis.com/auth/drive"],
                redirectURL: redirectURI,
                responseType: OIDResponseTypeCode,
                additionalParameters: nil)
            
            self.appDelegate.googleDriveCurrentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: self) { authState, error in
                if let authState = authState {
                    let gauthorization: GTMAppAuthFetcherAuthorization = GTMAppAuthFetcherAuthorization(authState: authState)
                    self.appDelegate.setGtmAuthorization(gauthorization)
                    
                } else {
                    self.appDelegate.setGtmAuthorization(nil)
                }
                
                if let authorizer = self.appDelegate.googleDriveServiceDrive.authorizer, let canAuth = authorizer.canAuthorize, canAuth {
                    // サインイン済みの場合
                    // 必要な処理を記述してください。
//                    print("サインイン完了")
//                    print(authorizer.userEmail) // これはなぜかnilになる、、、
                    // ファイル情報リストを取得します。
                    self.getFileInfoList()
                }
            }
        }
    }
    
    /**
     GoogleDrive APIで、ファイル情報リストを取得します。
     */
    func getFileInfoList() {
        // 1.　クエリオブジェクトを取得します。
        let query = GTLRDriveQuery_FilesList.query()
        
        // 2．クエリオブジェクトに検索条件を設定します。
        
        // 2-1. 1回の検索で取得する件数を指定します。
        //    ドキュメントには1000件まで指定できるとあります。
        //    しかし実際1000に指定して実行しても、1回で1000件は取得できませんでした。
        //    そのためデフォルトの100を指定して、何回かに分けて取得するようにしました。
        query.pageSize = 100
        
        // 2-2. 検索で取得する項目を指定します。
        query.fields = "nextPageToken, files(id, name, size, mimeType, fileExtension, createdTime, modifiedTime, starred, trashed, iconLink, parents, properties, permissions)"
        
        // 2-3. 検索するディレクトリのIDを指定します。
        // ルートディレクトリの場合は"root"を指定してください。
        // サブディレクトリの場合は、ファイル一覧取得処理で取得したディレクトリのIDを指定してください。
        // ディレクトリのIDは後述の"driveFile.identifier"で取得できます。
        query.q = "'root' in parents"
        
        // 2-4．取得順を指定します。
        query.orderBy = "folder,name"
        
        // 2-5. 次ページのトークンをセットします。
        //    nextPageTokenがnilならば、無視されます。
        query.pageToken = GDFileManager.nextPageToken
        GDFileManager.nextPageToken = nil
        
        // 2-6. クエリを実行した結果を処理するコールバックメソッドを登録します。
        let selector = #selector(displayResultWithTicket(_:finishedWithObject:error:))
//        let appDelegate = EnvUtils.getAppDelegate()
        let serviceDrive = appDelegate.googleDriveServiceDrive
        
        // 3. クエリを実行します。
        serviceDrive.executeQuery(query, delegate: self, didFinish: selector)
    }
    
    /**
     4. GoogleDriveファイルの取得結果を表示します。
     
     - Parameter ticket: チケット
     - Parameter response: レスポンス
     - Parameter error: エラー情報
     */
    @objc func displayResultWithTicket(_ ticket: GTLRServiceTicket, finishedWithObject response: GTLRDrive_FileList, error: Error?) {
        if error != nil {
            print(error!)
            // エラーの場合、処理を終了します。
            // 必要に応じてエラー処理を行ってください。
            return
        }
        
        // GoogleDriveファイルリストを更新します。
        // 今回取得した分のファイルリストを取得します。
        var tempDriveFileList = [GTLRDrive_File]()
        if let driveFiles = response.files, !driveFiles.isEmpty {
            tempDriveFileList = driveFiles
            
        }
        
        // 取得済みのファイル情報を一時ファイルリストに追加します。
        for driveFile in GDFileManager.fileInfoList {
            tempDriveFileList.append(driveFile)
        }
        
        // ファイル情報リストをクリアします。
        GDFileManager.fileInfoList.removeAll(keepingCapacity: false)
        
        // 全ファイル情報分繰り返します。
        for driveFile in tempDriveFileList {
            // 名称を取得します。
            guard driveFile.name != nil else {
                // 名称が取得できない場合、次のファイルを処理します。
                print("ファイル名の取得に失敗")
                continue
            }
            
            // IDを取得します。
            guard driveFile.identifier != nil else {
                // IDが取得できない場合、次のファイルを処理します。
                print("ファイルidの取得に失敗")
                continue;
            }
            
            // 削除済みか判定します。
            if GDFileManager.isTrashed(driveFile) {
                // 削除済みの場合、次のファイルを処理します。
                continue
            }
            
            if GDFileManager.isDir(driveFile) {
                // ディレクトリの場合

            } else {
                // ファイルの場合
                GDFileManager.fileInfoList.append(driveFile)
//                print(driveFile)
            }
        }
        
        // 次ページのトークンがある場合
        if let token = response.nextPageToken {
            // 次ページのファイル一覧を取得します。
            GDFileManager.nextPageToken = token
            getFileInfoList()
        }
        
        
        // 種類によって振り分け
        GDFileManager.mp3FileList = GDFileManager.fileInfoList.filter({$0.fileExtension == "mp3"})
        GDFileManager.bmsFileList = GDFileManager.fileInfoList.filter({$0.fileExtension == "bms"})
        
        
        
        
        moveToCMScene()
    }
    
 
    
    override func viewDidLoad() {
        // ファイル情報リストをクリアします。
        GDFileManager.fileInfoList.removeAll(keepingCapacity: false)
        
        authGoogleDriveInBrowser()
        
        
        // 寸法に関する定数をセット
        Dimensions.createInstance(frame: view.frame)
        
        super.viewDidLoad()
       
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
