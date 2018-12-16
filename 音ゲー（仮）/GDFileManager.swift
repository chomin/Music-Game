//
//  GDFileManager.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2018/12/12.
//  Copyright © 2018 NakaiKohei. All rights reserved.
//

import GoogleAPIClientForREST

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
    
    /**
     GoogleDrive APIで、ファイルデータを取得します。
     
     - Parameter fileName: ファイル名(実際はファイルのID)
     */
    static func getFileData(_ fileID: String) -> Data?{
        // 1. ファイルデータを取得するファイルのIDを指定してURL文字列を作成します。
        let urlString = "https://www.googleapis.com/drive/v3/files/\(fileID)?alt=media"
        
        // 2. 1で作成したURL文字列を指定して、fetcher(GTMSessionFetcherService)オブジェクトを取得します。
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let serviceDrive = appDelegate.googleDriveServiceDrive
        let fetcher = serviceDrive.fetcherService.fetcher(withURLString: urlString)
        
        // 3. fetcher(GTMSessionFetcherService)オブジェクトのbeginFetchメソッドを実行して、ファイルデータを取得します。
        fetcher.beginFetch( completionHandler: { (data: Data?, error: Error?) -> Void in
            if let error = error {
                // 4. エラーの場合、処理を終了します。
                // 必要に応じてエラー処理を行ってください。
                print(error)
                return
            }
            
            guard data != nil else {
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
            GDFileManager.mp3FileList = GDFileManager.fileInfoList.filter({$0.fileExtension == "mp3"})
            GDFileManager.bmsFileList = GDFileManager.fileInfoList.filter({$0.fileExtension == "bms"})
        })
        
        return fetcher.downloadedData
    }
}
