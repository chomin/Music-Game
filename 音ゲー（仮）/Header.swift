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
    
    // パースエラー定義列挙型
    enum ParseError: Error {
        case lackOfData(String)
        case lackOfVideoID(String)
        case invalidValue(String)
        case noLongNoteStart(String)
        case noLongNoteEnd(String)
        case unexpected(String)
        
        /// 渡されたnoteのbeatが何小節目何拍目かを返す
        static func getBeat(of note: Note) -> String {
            let bar = Int(note.beat / 4.0)
            let restBeat = note.beat - Double(bar * 4)
            return "\(bar)小節\(restBeat)拍目"
        }
    }
    
    @objc dynamic var bmsNameWithExtension = ""
    @objc dynamic var lastUpdateDate = ""
    @objc dynamic var genre = ""        // ジャンル
    @objc dynamic var title = ""        // タイトル(正式名称。ファイル名は文字の制約があるためこっちを正式とする)
    @objc dynamic var artist = ""       // アーティスト
    @objc dynamic var group = ""        // ソート用のグループ
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
        
        // 譜面データファイルのメインデータ
        var mainData: [(bar: Int, channel: Int, body: [String])] = []
        
        // インデックス型テンポ変更用テーブル
        var BPMTable: [String : Double] = [:]
        
        // コマンド文字列を命令と結びつける辞書
        let headerInstructionTable: [String: (String) -> ()] = [
            "GENRE":     { value in self.genre     = value },   // 構造体だと"Closure cannot implicitly capture a mutating self parameter"が発生する
            "TITLE":     { value in self.title     = value },
            "ARTIST":    { value in self.artist    = value },
//            "VIDEOID":   { value in self.videoID   = value },
//            "VIDEOID2":  { value in self.videoID   = value },
            "GROUP":     { value in self.group     = value },
            "PLAYLEVEL": { value in if let num = Int(value)    { self.playLevel = num } },
            "VOLWAV":    { value in if let num = Int(value)    { self.volWav    = num } },
            "LANE":      { value in if let num = Int(value)    { self.laneNum   = num } }
            ]
        
        let headerEx = try! Regex("^#([A-Z][0-9A-Z]*)( .*)?$")   // ヘッダの行にマッチ
        let mainDataEx = try! Regex("^#([0-9]{3})([0-9]{2}):(([0-9A-Z]{2})+)$") // メインデータの小節長変更命令以外にマッチ
        let barLengthEx = try! Regex("^#([0-9]{3})02:(([1-9]\\d*|0)(\\.\\d+)?)$") // メインデータの小節長変更命令にマッチ
        
        // BMS形式のテキストを1行ずつパース
        for bmsLine in bmsFile.contents {
            if let match = headerEx.firstMatch(bmsLine) {
                let item = match.groups[0]!
                let value = String(match.groups[1]?.dropFirst() ?? "")  // nilでなければ空白を取り除く
                // ヘッダをパース
                if let headerInstruction = headerInstructionTable[item] {   // 辞書に該当する命令がある場合
                    headerInstruction(value)
                } else if let bpmMatch = (try! Regex("^BPM([0-9A-F]{1,2})$")).firstMatch(item) {
                    // BPM指定コマンドの時
                    if let bpm = Double(value) {
                        BPMTable[bpmMatch.groups[0]!] = bpm
                    }
                } else {
//                    print("未定義のヘッダ命令: \(item)")
                }
                
            } else if let match = mainDataEx.firstMatch(bmsLine) {
                // メインデータ(小節長変更命令以外)をパース
                let bar = Int(match.groups[0]!)!        // 正規表現でフィルタしてるので必ずパース成功
                let channel = Int(match.groups[1]!)!    // 同上
                var body = [String]()
                // オブジェクト文字列を2文字ずつに分割
                let obstr = match.groups[2]!
                for i in stride(from: 0, to: obstr.count, by: 2) {
                    let headIndex = obstr.index(obstr.startIndex, offsetBy: i)
                    let tailIndex = obstr.index(obstr.startIndex, offsetBy: i + 2)
                    body.append(String(obstr[headIndex..<tailIndex]))
                }
                mainData.append((bar, channel, body))
                
            } else if let match = barLengthEx.firstMatch(bmsLine) {
                // メインデータの小節長変更命令をパース
                let bar = Int(match.groups[0]!)!
                mainData.append((bar, 2, [match.groups[1]!]))
            } else {
                if bmsLine.hasPrefix("#") {
                    throw ParseError.invalidValue("命令が不正です: \(bmsLine)")
                }
            }
        }
        
        // 保留
        //        if (music.playMode == .YouTube || musicplayMode == .YouTube2) &&
        //            music.videoID == "" {
        //            throw ParseError.lackOfVideoID("ファイル内にvideoIDが見つかりませんでした。BGMモードで実行します。")
        //        }
    }
    
    /// ファイルの読み込み
    ///
    /// - Parameter fileName: ファイル名(拡張子不問)
    /// - Returns: 行ごとに分割されたファイルの内容, ファイルの更新日時
    /// - Throws: エラー
    private func readBMS(fileName: String) throws -> (contents: [String], date: String, fileNameWithExtension: String) {
        
        let fileNameWithEntension = fileName.contains(".") ? fileName : "\(fileName).bms"

        // ファイル名を名前と拡張子に分割
        let splittedName = fileNameWithEntension.components(separatedBy: ".")
        let dataFileName = splittedName[0]
        let dataFileType = splittedName[1]
        
        // 譜面データファイルのパスを取得
        if let path = Bundle.main.path(forResource: "Sounds/" + dataFileName, ofType: dataFileType) {
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
        } else {
            throw FileError.notFound("指定されたファイルが見つかりません")
        }
    }
}
