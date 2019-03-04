//
//  Header.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2018/08/31.
//  Copyright © 2018年 NakaiKohei. All rights reserved.
//

import Foundation
import RealmSwift

class Header: Object {
    
    // ファイルエラー定義列挙型
    enum FileError: Error {
        case invalidName(String)
        case notFound(String)
        case readFailed(String)
    }
    
    @objc dynamic var bmsNameWithExtension = ""
    @objc dynamic var lastUpdateDate = "" // 例: ""
    @objc dynamic var genre = ""        // ジャンル
    @objc dynamic var title = ""        // タイトル(正式名称。ファイル名は文字の制約があるためこっちを正式とする)
    @objc dynamic var artist = ""       // アーティスト
    @objc dynamic var group = ""        // ソート用のグループ
    @objc dynamic var videoID = ""
    @objc dynamic var videoID2 = ""
    @objc dynamic var playLevel = 0     // 難易度
    @objc dynamic var volWav = 100      // 音量を現段階のn%として出力するか(TODO: 未実装)
    @objc dynamic var laneNum = 7
    
    /// DB上に存在しない場合にBMSから読み込み生成し、dbに保存する。db上に存在するときは作成しないこと。
    ///
    /// - Parameter fileName: bmsファイルのファイル名(拡張子の有無は不問)
    /// - Throws: エラー
    convenience init(fileName: String) throws { // Realm使う都合上、convenieneceが必須
        
        self.init()
        
        do {
            try setPropaties(fileName: fileName)
            
            let realm = try Realm()
            
            try! realm.write {
                realm.add(self)
            }
        } catch {
            print(error)
            print("@Header.init()")
            exit(1)
        }
    }
    
    /// ファイルからHeaderのプロパティを設定する
    ///
    /// - Parameter fileName: bmsファイルのファイル名(拡張子の有無は不問)
    /// - Throws: エラー
    func setPropaties(fileName: String) throws {
        
        // 譜面データファイルを一行ごとに配列で保持
        let bmsFile = try readBMS(fileName: fileName)
        self.lastUpdateDate = bmsFile.date
        self.bmsNameWithExtension = bmsFile.fileNameWithExtension

        // コマンド文字列を命令と結びつける辞書
        let headerInstructionTable: [String: (String) -> ()] = [
            "GENRE":     { value in self.genre     = value },   // 構造体だと"Closure cannot implicitly capture a mutating self parameter"が発生する
            "TITLE":     { value in self.title     = value },
            "ARTIST":    { value in self.artist    = value },
            "GROUP":     { value in self.group     = value },
            "VIDEOID":   { value in self.videoID   = value },
            "VIDEOID2":  { value in self.videoID2  = value },
            "PLAYLEVEL": { value in if let num = Int(value) { self.playLevel = num } },
            "VOLWAV":    { value in if let num = Int(value) { self.volWav    = num } },
            "LANE":      { value in if let num = Int(value) { self.laneNum   = num } }
        ]
        
        let headerEx = try! Regex("^#([A-Z][0-9A-Z]*)( .*)?$")  // ヘッダの行にマッチ
        let mainDataEx = try! Regex("^#[0-9]{5}:.+$")           // メインデータの行にマッチ

        // BMS形式のテキストを1行ずつパース(ヘッダのみ)
        for bmsLine in bmsFile.contents {
            if let match = headerEx.firstMatch(bmsLine) {
                let item = match.groups[0]!
                let value = String(match.groups[1]?.dropFirst() ?? "")  // nilでなければ空白を取り除く
                // ヘッダをパース
                if let headerInstruction = headerInstructionTable[item] {   // 辞書に該当する命令がある場合
                    headerInstruction(value)
                }
            } else if mainDataEx.matches(bmsLine) {
                break       // メインデータの部分に入れば終了
            }
        }
    }
    
    /// ファイルの読み込み
    ///
    /// - Parameter fileName: ファイル名(拡張子不問)
    /// - Returns: 行ごとに分割されたファイルの内容, ファイルの更新日時
    /// - Throws: エラー
    private func readBMS(fileName: String) throws -> (contents: [String], date: String, fileNameWithExtension: String) {
        
        let fileNameWithEntension = fileName.hasSuffix(".bms") ? fileName : "\(fileName).bms"
        
        // 譜面データファイルのパスを取得
        let path = GDFileManager.cachesDirectoty.appendingPathComponent(fileName).path
        do {
            // ファイルの内容と更新日時を取得する
            let content = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
            let attr = try FileManager.default.attributesOfItem(atPath: path)
            //                let date = NSDictionary.fileModificationDate(NSDictionary(dictionary: attr))
            let date = attr[FileAttributeKey.modificationDate] as! Date
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            formatter.timeStyle = .full
            formatter.locale = Locale(identifier: "ja_JP")
            
            return (content.components(separatedBy: .newlines), formatter.string(from: date), fileNameWithEntension)
        } catch {
            throw FileError.readFailed("ファイルの内容取得に失敗(pathが不正、あるいはファイルのエンコードがutf8ではありません)")
        }
    }
}
