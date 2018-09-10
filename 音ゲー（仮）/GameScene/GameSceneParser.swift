//
//  ReadBMS.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//
//（9/11の成果が残っている？）

/* チャンネル番号定義
 * 01: 楽曲開始命令(10,20,30)、及び楽曲終了命令(11)
 * 02: 小節長変更命令(bodyに倍率を小数で指定)
 * 03: BPM変更命令
 * 08: インデックス型BPM変更命令(256以上や小数のBPMに対応)
 * 11-15, 18-19: レーン指定(レーン数によっては使わない場所あり)
 * 21: ノーツスピード変更命令(倍率を16倍したものを16進数で記述)
 */

import SpriteKit

extension GameScene {   // bmsファイルを読み込む
    
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
    
    
    /// 渡されたファイルを読んでnotes配列を作成
    /// 投げるエラーはFileError列挙型とParseError列挙型に定義されている
    ///
    /// - Parameter fileName: 譜面データファイルの名前
    /// - Throws: パース時に発生したエラー
    func parse(fileName: String) throws {
        
        // 譜面データファイルを一行ごとに配列で保持
        let bmsData = try readFile(fileName: fileName)
        
        // 譜面データファイルのメインデータ
        var mainData: [(bar: Int, channel: Int, body: [String])] = []
        
        // インデックス型テンポ変更用テーブル
        var BPMTable: [String : Double] = [:]
        //
        //
                // コマンド文字列を命令と結びつける辞書
                let headerInstructionTable: [String: (String) -> ()] = [
//                    "GENRE":     { value in self.music.genre     = value },
//                    "TITLE":     { value in self.music.title     = value },
//                    "ARTIST":    { value in self.music.artist    = value },
                    "VIDEOID":   { value in if self.playMode == .YouTube  { self.music.videoID = value } },
                    "VIDEOID2":  { value in if self.playMode == .YouTube2 { self.music.videoID = value } },
                    "BPM":       { value in if let num = Double(value) { self.music.BPMs = [(num, 0.0)] } },
//                    "PLAYLEVEL": { value in if let num = Int(value) { self.music.playLevel = num } },
//                    "VOLWAV":    { value in if let num = Int(value) { self.music.volWav = num } },
//                    "LANE":      { value in if let num = Int(value) { self.music.laneNum = num } }
                ]
        //
        let headerEx = try! Regex("^#([A-Z][0-9A-Z]*)( .*)?$")   // ヘッダの行にマッチ
        let mainDataEx = try! Regex("^#([0-9]{3})([0-9]{2}):(([0-9A-Z]{2})+)$") // メインデータの小節長変更命令以外にマッチ
        let barLengthEx = try! Regex("^#([0-9]{3})02:(([1-9]\\d*|0)(\\.\\d+)?)$") // メインデータの小節長変更命令にマッチ
        
        // BMS形式のテキストを1行ずつパース
        for bmsLine in bmsData {
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
//                                    print("未定義のヘッダ命令: \(item)")
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
        
        if (playMode == .YouTube || playMode == .YouTube2) &&
            music.videoID == "" {
            throw ParseError.lackOfVideoID("ファイル内にvideoIDが見つかりませんでした。BGMモードで実行します。")
        }
        
        
        /*--- メインデータからノーツを生成 ---*/
        
        // チャンネルとレーンの対応付け(辞書)
        var laneMap: [Int : Int]
        switch music.laneNum {
        case 1: laneMap = [                      14: 0                      ]
        case 2: laneMap = [               13: 0,        15: 1               ]
        case 3: laneMap = [               13: 0, 14: 1, 15: 2               ]
        case 4: laneMap = [        12: 0, 13: 1,        15: 2, 18: 3        ]
        case 5: laneMap = [        12: 0, 13: 1, 14: 2, 15: 3, 18: 4        ]
        case 6: laneMap = [ 11: 0, 12: 1, 13: 2,        15: 3, 18: 4, 19: 5 ]
        case 7: laneMap = [ 11: 0, 12: 1, 13: 2, 14: 3, 15: 4, 18: 5, 19: 6 ]
        default:
            //            music.laneNum = 7
            laneMap = [11: 0, 12: 1, 13: 2, 14: 3, 15: 4, 18: 5, 19: 6]
        }
        
        // ファイル上のノーツ定義
        enum NoteExpression: String {
            case rest      = "00"
            case tap       = "01"
            case flick     = "02"
            case start1    = "03"
            case middle1   = "04"
            case end1      = "05"
            case flickEnd1 = "06"
            case start2    = "07"
            case middle2   = "08"
            case end2      = "09"
            case flickEnd2 = "0A"
            case tapL      = "0B"
            case start1L   = "0C"
            case end1L     = "0D"
            case start2L   = "0E"
            case end2L     = "0F"
            case tapLL     = "0G"
        }
        
        // mainDataを小節毎に分ける
        var barGroup: [Int : [(channel: Int, body: [String])]] = [:]   // 小節と、対応するmainDataの辞書
        for (bar, channel, body) in mainData {
            if barGroup[bar]?.append((channel, body)) == nil {
                barGroup[bar] = [(channel, body)]
            }
        }
        
        var longNotes1: [Note] = []         // ロングノーツ1を一時的に格納
        var longNotes2: [Note] = []         // ロングノーツ2を一時的に格納
        var musicStartPosSet: [PlayMode : Double] = [:] // 各モードのmusicStartPosを一時的に格納
        var musicEndPos: Double?            // 楽曲終了タイミング(拍単位)
        var beatOffset = 0  // その小節の全オブジェクトに対する拍数の調整。4/4以外の拍子があった場合に上下する
        
        // 小節毎に処理
        for (bar, data) in barGroup.sorted(by: { $0.0 < $1.0 } ) {
            
            var barLength = 4       // この小節に含まれる拍数
            var speedRatioTable: [Double : Double] = [:]    // スピード倍率変更命令用テーブル
            // 先に小節全体に影響する命令を処理
            for (channel, body) in data {
                // 小節長命令の処理
                if channel == 2 {
                    guard !(body.isEmpty) else {
                        throw ParseError.lackOfData("変更する小節長が指定されていません: \(bar)小節目")
                    }
                    if let ratio = Double(body.first!) {
                        barLength = Int(ratio * 4)
                    } else {
                        throw ParseError.invalidValue("拍子指定が不正です: \(bar)小節目")
                    }
                } else if channel == 21 {
                    // ノーツスピード倍率命令の処理
                    let unitBeat = Double(barLength) / Double(body.count)   // その小節における1オブジェクトの長さ(拍単位。行内のオブジェクトで共通。)
                    for (index, ob) in body.enumerated() {
                        guard ob != "00" else {
                            continue
                        }
                        if let num = Int(ob, radix: 16) {
                            let beat = Double(bar) * 4.0 + unitBeat * Double(index) + Double(beatOffset)
                            speedRatioTable[beat] = Double(num) / 16
                        } else {
                            throw ParseError.invalidValue("拍子指定が不正です: \(bar)小節目")
                        }
                    }
                }
            }
            
            // 行ごとに処理。bmsには1行あたり1小節分の情報がある
            // ロングノーツは一時配列に、その他はnotesに格納。その他命令も実行
            for (channel, body) in data {
                
                let unitBeat = Double(barLength) / Double(body.count)   // その小節における1オブジェクトの長さ(拍単位。行内のオブジェクトで共通。)
                
                if let lane = laneMap[channel] {
                    // ノーツ指定チャンネルだったとき
                    for (index, ob) in body.enumerated() {  // オブジェクト単位での処理。
                        autoreleasepool {
                            
                            let beat = Double(bar) * 4.0 + unitBeat * Double(index) + Double(beatOffset)
                            let ratio = (speedRatioTable[beat] ?? 1.0) * setting.speedRatio
                            
                            switch NoteExpression(rawValue: ob) ?? NoteExpression.rest {
                            case .rest:
                                break
                            case .tap:
                                notes.append(
                                    Tap     (beatPos: beat, laneIndex: lane, speedRatio: ratio, isLarge: false)
                                )
                            case .flick:
                                notes.append(
                                    Flick   (beatPos: beat, laneIndex: lane, speedRatio: ratio)
                                )
                            case .start1:
                                longNotes1.append(
                                    TapStart(beatPos: beat, laneIndex: lane, speedRatio: ratio, isLarge: false)
                                )
                            case .middle1:
                                longNotes1.append(
                                    Middle  (beatPos: beat, laneIndex: lane, speedRatio: ratio)
                                )
                            case .end1:
                                longNotes1.append(
                                    TapEnd  (beatPos: beat, laneIndex: lane, speedRatio: ratio, isLarge: false)
                                )
                            case .flickEnd1:
                                longNotes1.append(
                                    FlickEnd(beatPos: beat, laneIndex: lane, speedRatio: ratio)
                                )
                            case .start2:
                                longNotes2.append(
                                    TapStart(beatPos: beat, laneIndex: lane, speedRatio: ratio, isLarge: false)
                                )
                            case .middle2:
                                longNotes2.append(
                                    Middle  (beatPos: beat, laneIndex: lane, speedRatio: ratio)
                                )
                            case .end2:
                                longNotes2.append(
                                    TapEnd  (beatPos: beat, laneIndex: lane, speedRatio: ratio, isLarge: false)
                                )
                            case .flickEnd2:
                                longNotes2.append(
                                    FlickEnd(beatPos: beat, laneIndex: lane, speedRatio: ratio)
                                )
                            case .tapL:
                                notes.append(
                                    Tap     (beatPos: beat, laneIndex: lane, speedRatio: ratio, isLarge: true)
                                )
                            case .start1L:
                                longNotes1.append(
                                    TapStart(beatPos: beat, laneIndex: lane, speedRatio: ratio, isLarge: true)
                                )
                            case .end1L:
                                longNotes1.append(
                                    TapEnd  (beatPos: beat, laneIndex: lane, speedRatio: ratio, isLarge: true)
                                )
                            case .start2L:
                                longNotes2.append(
                                    TapStart(beatPos: beat, laneIndex: lane, speedRatio: ratio, isLarge: true)
                                )
                            case .end2L:
                                longNotes2.append(
                                    TapEnd  (beatPos: beat, laneIndex: lane, speedRatio: ratio, isLarge: true)
                                )
                            case .tapLL:
                                notes.append(
                                    Tap     (beatPos: beat, laneIndex: lane, speedRatio: ratio, isLarge: true)
                                )
                            }
                        }
                    }
                } else if channel == 1 {
                    // 楽曲開始及び終了命令の処理
                    for (index, ob) in body.enumerated() {
                        let beat = Double(bar) * 4.0 + unitBeat * Double(index) + Double(beatOffset)
                        
                        switch ob {
                        case "10": musicStartPosSet[.BGM] = beat
                        case "20": musicStartPosSet[.YouTube] = beat
                        case "30": musicStartPosSet[.YouTube2] = beat
                        case "11": musicEndPos = beat
                        default:
                            break
                        }
                    }
                } else if channel == 3 {
                    // BPM変更命令の処理
                    for (index, ob) in body.enumerated() {
                        guard ob != "00" else {
                            continue
                        }
                        if let newBPM = Int(ob, radix: 16) {
                            let beat = Double(bar) * 4.0 + unitBeat * Double(index) + Double(beatOffset)
                            music.BPMs.append((bpm: Double(newBPM), startPos: beat))
                        }
                    }
                } else if channel == 8 {
                    // BPM変更命令の処理(インデックス型テンポ変更)
                    for (index, ob) in body.enumerated() {
                        if let newBPM = BPMTable[ob] {
                            let beat = Double(bar) * 4.0 + unitBeat * Double(index) + Double(beatOffset)
                            music.BPMs.append((bpm: Double(newBPM), startPos: beat))
                        }
                    }
                } else if channel == 14 && music.laneNum == 6 {
                    // ミリシタ譜面の特大ノーツを処理
                    for (index, ob) in body.enumerated() {
                        if NoteExpression(rawValue: ob) == .tapLL {
                            let beat = Double(bar) * 4.0 + unitBeat * Double(index) + Double(beatOffset)
                            let ratio = (speedRatioTable[beat] ?? 1.0) * setting.speedRatio
                            notes.append(Tap(beatPos: beat, laneIndex: 2, speedRatio: ratio, isLarge: true))
                            notes.append(Tap(beatPos: beat, laneIndex: 3, speedRatio: ratio, isLarge: true))
                        }
                    }
                }
            }
            // 小節長の変更があった場合にbeatOffsetを調整
            beatOffset += 4 - barLength
        }
        
        // musicStartPosを格納
        guard musicStartPosSet[.BGM] != nil else {
            throw ParseError.lackOfData("楽曲開始命令がありません")
        }
        switch playMode {
        case .BGM:
            self.musicStartPos = musicStartPosSet[.BGM]!
        case .YouTube:
            self.musicStartPos = musicStartPosSet[.YouTube] ?? musicStartPosSet[.BGM]!
        case .YouTube2:
            self.musicStartPos = musicStartPosSet[.YouTube2] ?? musicStartPosSet[.YouTube] ?? musicStartPosSet[.BGM]!
        }
        // 楽曲継続時間を設定
        self.duration = {
            if let endPos = musicEndPos {
                var i = 0
                var timeInterval: TimeInterval = 0
                while true {
                    if i + 1 < music.BPMs.count {
                        timeInterval += (BPMs[i + 1].startPos - BPMs[i].startPos) / (BPMs[i].bpm/60)
                    } else {
                        timeInterval += (endPos - BPMs[i].startPos) / (BPMs[i].bpm/60)
                        break
                    }
                    i += 1
                }
                return timeInterval
            } else {
                return nil
            }
        }()
        
        // ロングノーツを時間順にソート(同じ場合は TapEnd or FlickEnd < TapStart)
        longNotes1.sort(by: {
            if $0.beat == $1.beat { return $1 is TapStart }
            else { return $0.beat < $1.beat }
        })
        longNotes2.sort(by: {
            if $0.beat == $1.beat { return $1 is TapStart }
            else { return $0.beat < $1.beat }
        })
        
        // 線形リストを作成し、先頭をnotesに格納
        // longNotes1について
        var i = 0
        while i < longNotes1.count {
            if longNotes1[i] is TapStart {
                let start = longNotes1[i]
                notes.append(longNotes1[i])
                while !(longNotes1[i] is TapEnd) && !(longNotes1[i] is FlickEnd) {
                    guard i + 1 < longNotes1.count else {
                        throw ParseError.noLongNoteEnd("ロングノーツ終了命令がありません(\(ParseError.getBeat(of: longNotes1[i])))")
                    }
                    guard longNotes1[i + 1] is Middle || longNotes1[i + 1] is TapEnd || longNotes1[i + 1] is FlickEnd else {
                        throw ParseError.noLongNoteEnd("ロングノーツ終了命令がありません(\(ParseError.getBeat(of: longNotes1[i + 1])))")
                    }
                    if let tapStart = longNotes1[i] as? TapStart {
                        tapStart.next = longNotes1[i + 1]
                        // ガイド円の色を設定
                        if let middle = tapStart.next as? Middle {
                            middle.longImages.circle.fillColor = tapStart.isLarge ? UIColor.yellow : UIColor.green
                        }
                    } else if let middle = longNotes1[i] as? Middle {
                        middle.next = longNotes1[i + 1]
                        // ガイド円の色を設定
                        if let middle2 = middle.next as? Middle {
                            middle2.longImages.circle.fillColor = middle.longImages.circle.fillColor
                        }
                        //						temp.before = longNotes1[i - 1]
                    } else {
                        throw ParseError.unexpected("予期せぬエラー")
                    }
                    
                    i += 1
                }
                if let temp = longNotes1[i] as? TapEnd {
                    temp.start = start
                    //					temp.before = longNotes1[i - 1]
                } else if let temp = longNotes1[i] as? FlickEnd {
                    temp.start = start
                    //					temp.before = longNotes1[i - 1]
                } else {
                    throw ParseError.unexpected("予期せぬエラー")
                }
                i += 1
            } else {
                print("ロングノーツ開始命令がありません(\(ParseError.getBeat(of: longNotes1[i])))")
                throw ParseError.noLongNoteStart("ロングノーツ開始命令がありません(\(ParseError.getBeat(of: longNotes1[i])))")
            }
        }
        // longNotes2について
        i = 0
        while i < longNotes2.count {
            if longNotes2[i] is TapStart {
                let start = longNotes2[i]
                notes.append(longNotes2[i])
                while !(longNotes2[i] is TapEnd) && !(longNotes2[i] is FlickEnd) {
                    guard i + 1 < longNotes2.count else {
                        throw ParseError.noLongNoteEnd("ロングノーツ終了命令がありません(\(ParseError.getBeat(of: longNotes2[i])))")
                    }
                    guard longNotes2[i + 1] is Middle || longNotes2[i + 1] is TapEnd || longNotes2[i + 1] is FlickEnd else {
                        throw ParseError.noLongNoteEnd("ロングノーツ終了命令がありません(\(ParseError.getBeat(of: longNotes2[i + 1])))")
                    }
                    if let tapStart = longNotes2[i] as? TapStart {
                        tapStart.next = longNotes2[i + 1]
                        // ガイド円の色を設定
                        if let middle = tapStart.next as? Middle {
                            middle.longImages.circle.fillColor = tapStart.isLarge ? UIColor.yellow : UIColor.green
                        }
                    } else if let middle = longNotes2[i] as? Middle {
                        middle.next = longNotes2[i + 1]
                        // ガイド円の色を設定
                        if let middle2 = middle.next as? Middle {
                            middle2.longImages.circle.fillColor = middle.longImages.circle.fillColor
                        }
                        //                        temp.before = longNotes1[i - 1]
                    } else {
                        throw ParseError.unexpected("予期せぬエラー")
                    }
                    
                    i += 1
                }
                if let temp = longNotes2[i] as? TapEnd {
                    temp.start = start
                    //					temp.before = longNotes2[i - 1]
                } else if let temp = longNotes2[i] as? FlickEnd {
                    temp.start = start
                    //					temp.before = longNotes2[i - 1]
                } else {
                    throw ParseError.unexpected("予期せぬエラー")
                }
                i += 1
            } else {
                throw ParseError.noLongNoteStart("ロングノーツ開始命令がありません(\(ParseError.getBeat(of: longNotes2[i])))")
            }
        }
        // 時間順にソート
        notes.sort(by: { $0.beat < $1.beat })
    }
    
    
    // ファイルの読み込み
    private func readFile(fileName: String) throws -> [String] {
        
        // ファイル名を名前と拡張子に分割
        guard fileName.contains(".") else {
            throw FileError.invalidName("ファイル名には拡張子を指定してください")
        }
        let splittedName = fileName.components(separatedBy: ".")
        let dataFileName = splittedName[0]
        let dataFileType = splittedName[1]
        
        // 譜面データファイルのパスを取得
        if let path = Bundle.main.path(forResource: "Sounds/" + dataFileName, ofType: dataFileType) {
            do {
                // ファイルの内容を取得する
                let content = try String(contentsOfFile: path, encoding: String.Encoding.shiftJIS)
                
                return content.components(separatedBy: .newlines)
            } catch {
                do {
                    // ファイルの内容を取得する
                    let content = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
                    
                    return content.components(separatedBy: .newlines)
                } catch {
                    throw FileError.readFailed("ファイルの内容取得に失敗")
                }
            }
        } else {
            throw FileError.notFound("指定されたファイルが見つかりません")
        }
    }
}


