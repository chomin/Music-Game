//
//  GDFileManager.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2018/12/12.
//  Copyright © 2018 NakaiKohei. All rights reserved.
//

import GoogleAPIClientForREST
import AVFoundation
import SVProgressHUD

class GDFileManager {
    /// GooleDriveファイル情報リスト
    static var fileInfoList = [GTLRDrive_File]()
    static var mp3FileList  = [GTLRDrive_File]()
    static var bmsFileList  = [GTLRDrive_File]()
    /// 次ページ取得用トークン
    static var nextPageToken: String?
    /// 保存先のディレクトリ(長いので、、、)
    static let cachesDirectoty = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    
    /// GoogleDrive APIで、ファイルデータを取得します。データはDBに格納（予定）
    ///
    /// - Parameters:
    ///   - fileID: fileID
    static func getFileData(fileID: String, group: DispatchGroup?) {
        
        guard let file = GDFileManager.fileInfoList.first(where: {$0.identifier == fileID}) else {
            print("指定されたファイルをリストから見つけられませんでした。リストを更新してください。")
            group?.leave()
            return
        }
        let fileURL = cachesDirectoty.appendingPathComponent("\(file.name!)/")
//        guard !FileManager.default.fileExists(atPath: fileURL.path) else {
//            print("\(file.name!)はすでにダウンロード済みです")
//            group?.leave()
//            return
//        }
        // アニメーション立ち上げ
        SVProgressHUD.show()
        
        // 1. ファイルデータを取得するファイルのIDを指定してURL文字列を作成します。
        let urlString = "https://www.googleapis.com/drive/v3/files/\(fileID)?alt=media"
        
        // 2. 1で作成したURL文字列を指定して、fetcher(GTMSessionFetcherService)オブジェクトを取得します。
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let serviceDrive = appDelegate.googleDriveServiceDrive
        let fetcher = serviceDrive.fetcherService.fetcher(withURLString: urlString)
        
        
        // 3. fetcher(GTMSessionFetcherService)オブジェクトのbeginFetchメソッドを実行して、ファイルデータを取得します。
        fetcher.beginFetch( completionHandler: { (data: Data?, error: Error?) -> Void in // （デリゲートでもできる）
            if let error = error {
                // 4. エラーの場合、処理を終了します。
                // 必要に応じてエラー処理を行ってください。
                print(error)
                SVProgressHUD.showError(withStatus: "\(file.name!)")
                SVProgressHUD.dismiss(withDelay: 1)
                getFileData(fileID: fileID, group: group)
                return
            }
            
            guard let dat = data else {
                // データが取得できない場合、処理を終了します。
                // 必要に応じてエラー処理を行ってください。
                print("GoogleDriveからデータが取得できませんでした。")
                SVProgressHUD.showError(withStatus: "\(file.name!)")
                SVProgressHUD.dismiss(withDelay: 1)
                getFileData(fileID: fileID, group: group)
                return
            }
            
            // 正常終了の場合の処理を記述してください。
            // 取得したファイルデータはData型のため、ファイルの内容に合わせて適切に変換してください。
            // PWEditorでは、
            // 　①ファイルデータがテキストデータかチェックする。
            // 　②テキストデータに変換する。
            // を行なっています。
            //
            
            // 保存
            do{
                try dat.write(to: fileURL, options: .atomic)
            }catch{
                print("保存に失敗しました：\(file.name!)")
                print(error)
                SVProgressHUD.showError(withStatus: "\(file.name!)")
                SVProgressHUD.dismiss(withDelay: 1)
                getFileData(fileID: fileID, group: group)
                return
            }
            
            SVProgressHUD.showSuccess(withStatus: "\(file.name!)")
            SVProgressHUD.dismiss(withDelay: 1)
            
            group?.leave()
        })
    }
}

extension GTLRDrive_File {
    /**
     ディレクトリか判定します。
     
     - Parameter file: ファイルオブジェクト
     - Returns: true:ディレクトリ / false:ファイル
     */
     func isDir() -> Bool {
        var result = false
        if let mimeType = self.mimeType {
            let mimeTypes = mimeType.components(separatedBy: ".")
            let lastIndex = mimeTypes.count - 1
            let type = mimeTypes[lastIndex]
            if type == "folder" {
                result = true
            }
        }
        return result
    }
    
    /**
     削除済みか判定します。
     
     - Parameter file: ファイルオブジェクト
     - Returns: true:削除済み / false:削除されていない
     */
    func isTrashed() -> Bool {
        if let trashed = self.trashed, trashed == 1 {
            return true
        }
        return false
    }
    
    func isDownloaded() -> Bool {
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(atPath: GDFileManager.cachesDirectoty.path)
            return directoryContents.contains("\(self.name!)")
        } catch {
            print(error)
            return self.isDownloaded()
        }
        
    }
    
    /// ローカルファイルと比較して更新されているか
    /// ダウンロードされていなければtrueを返す
    /// 
    /// - Returns: Bool
    func isRenewed() -> Bool {
        
        guard self.isDownloaded() else {
            return true
        }
        
        let cloudFileDate = self.modifiedTime!.date    // クラウド上のファイルのDate
        
        do {
            let filePath = GDFileManager.cachesDirectoty.appendingPathComponent(self.name!).path
            let attr = try FileManager.default.attributesOfItem(atPath: filePath)
            let localFileDate = attr[FileAttributeKey.modificationDate] as! Date
            
            if cloudFileDate.compare(localFileDate) == .orderedDescending { return true  }
            else                                                          { return false }
        } catch {
            print(error)
            return self.isRenewed()
        }
    }
}
