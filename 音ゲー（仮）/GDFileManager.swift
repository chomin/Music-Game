//
//  GDFileManager.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2018/12/12.
//  Copyright © 2018 NakaiKohei. All rights reserved.
//

import GoogleAPIClientForREST
import AVFoundation

class GDFileManager {
    /// GooleDriveファイル情報リスト
    static var fileInfoList = [GTLRDrive_File]()
    static var mp3FileList  = [GTLRDrive_File]()
    static var bmsFileList  = [GTLRDrive_File]()
    /// 次ページ取得用トークン
    static var nextPageToken: String?
    
    
    /**
     ディレクトリか判定します。
     
     - Parameter file: ファイルオブジェクト
     - Returns: true:ディレクトリ / false:ファイル
     */
    static func isDir(_ file: GTLRDrive_File) -> Bool {
        var result = false
        if let mimeType = file.mimeType {
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
    static func isTrashed(_ file: GTLRDrive_File) -> Bool {
        if let trashed = file.trashed, trashed == 1 {
            return true
        }
        return false
    }
    
    
    /// GoogleDrive APIで、ファイルデータを取得します。データはDBに格納（予定）
    ///
    /// - Parameters:
    ///   - fileID: fileID
    static func getFileData(_ fileID: String) {
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
                return
            }
            
            guard let dat = data else {
                // データが取得できない場合、処理を終了します。
                // 必要に応じてエラー処理を行ってください。
                print("GoogleDriveからデータが取得できませんでした。")
                return
            }
            
            // 正常終了の場合の処理を記述してください。
            // 取得したファイルデータはData型のため、ファイルの内容に合わせて適切に変換してください。
            // PWEditorでは、
            // 　①ファイルデータがテキストデータかチェックする。
            // 　②テキストデータに変換する。
            // を行なっています。
            //
            
            guard let file = GDFileManager.fileInfoList.first(where: {$0.identifier == fileID}) else {
                print("指定されたファイルをリストから見つけられませんでした。（ドライブ上には存在します）")
                return
            }
            
            
            // 保存
            
//            if !FileManager.default.createFile(atPath: "\(NSHomeDirectory())/Library/Application Support/\(file.name!)", contents: data, attributes: nil){
//                print("保存に失敗しました：\(file.name!)")
//            }
            
//            let dirURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
//            if !FileManager.default.fileExists(atPath: dirURL.absoluteString){
//                do {
//                    try FileManager.default.createDirectory( atPath: dirURL.absoluteString, withIntermediateDirectories: true, attributes: nil)
//
//                } catch {
//                    print(error)
//                    return
//                }
//            }
            
            let fileURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0].appendingPathComponent("\(file.name!)/")
            do{
                try dat.write(to: fileURL, options: .atomic)
            }catch{
                print("保存に失敗しました：\(file.name!)")
                print(error)
            }
        })
    }
}
