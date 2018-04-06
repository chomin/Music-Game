//
//  ReadBMS.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//
//（9/11の成果が残っている？）


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
        var bmsData: [String] = []
        
        // 譜面データファイルのヘッダ
        var header: [String] = []
        // 譜面データファイルのメインデータ
        var rawMainData: [String] = []
        
        // インデックス型テンポ変更用テーブル
        var BPMTable: [String : Double] = [:]
        
        // ファイルの内容をbmsDataに格納
        bmsData = try readFile(fileName: fileName)
        
        // 先頭が'#'であるものだけを抽出し、'#'を削除
        bmsData = bmsData
            .filter { $0.hasPrefix("#") }
            .map { str in String(str.dropFirst()) }
        
        
        // ヘッダとメインデータに分割
        for bmsLine in bmsData {
            if Int(bmsLine.prefix(1)) == nil {  // 1文字目が数字じゃないならヘッダ
                header.append(bmsLine)
            } else {
                rawMainData.append(bmsLine)
            }
        }
        
        
        /*--- ヘッダをパース ---*/
        
        // コマンド文字列を命令と結びつける辞書
        let headerInstructionTable: [String: (String) -> ()] = [
            "GENRE":     { value in self.genre     = value },
            "TITLE":     { value in self.title     = value },
            "ARTIST":    { value in self.artist    = value },
            "VIDEOID":   { value in if self.playMode == .YouTube  { self.videoID = value } },
            "VIDEOID2":  { value in if self.playMode == .YouTube2 { self.videoID = value } },
            "BPM":       { value in if let num = Double(value) { self.BPMs = [(num, 0.0)] } },
            "PLAYLEVEL": { value in if let num = Int(value) { self.playLevel = num } },
            "VOLWAV":    { value in if let num = Int(value) { self.volWav = num } }
            
        ]
        
        // 1行ずつ処理
        for headerLine in header {
            let components = headerLine.components(separatedBy: " ")
            if components.count >= 2 {
                if let headerInstruction = headerInstructionTable[components[0]] {  // 辞書に該当する命令がある場合
                    var value = components[1]
                    let splittedValue = components.dropFirst(2) // 3つ目以降(名前の中に半角スペースがある場合)
                    for str in splittedValue {
                        value += (" " + str)
                    }
                    headerInstruction(value)
                } else if components[0].hasPrefix("BPM") {
                    // BPM指定コマンドのとき
                    if let bpm = Double(components[1]) {
                        BPMTable[String(components[0].dropFirst(3))] = bpm
                    }
                }
            }
        }
        
        
        /*--- メインデータをパース ---*/
        
        // 利用可能なチャンネル番号
        let availableChannels = [1, 2, 3, 8, 11, 12, 13, 14, 15, 18, 19, 21]
        
        // チャンネルとレーンの対応付け(辞書)
        let laneMap = [11: 0, 12: 1, 13: 2, 14: 3, 15: 4, 18: 5, 19: 6]
        
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
        
        // メインデータ1行を小節番号・チャンネル・データのタプルに分解
        let processedMainData = try rawMainData.map {
            (str: String) throws -> (bar: Int, channel: Int, body: [String]) in
            
            var ret = (bar: 0, channel: 0, body: [String]())
            
            let components = str.components(separatedBy: ":")
            
            guard components.count >= 2 && components[0].count == 5 else {
                throw ParseError.lackOfData("データが欠損しています: #\(str)")
            }
            
            if let num = Int(components[0].prefix(3)) {
                ret.bar = num
            } else {
                throw ParseError.invalidValue("小節番号指定が不正です: #\(str)")
            }
            if let num = Int(components[0].suffix(2)) {
                ret.channel = num
            } else {
                throw ParseError.invalidValue("チャンネル指定が不正です: #\(str)")
            }
            
            if ret.channel == 2 {   // 小節を指定数倍する
                ret.body.append(components[1])

            } else {
                // オブジェクト配列を2文字ずつに分けてdataに格納
                for i in stride(from: 0, to: components[1].count, by: 2) {
                    let headIndex = str.index(str.startIndex, offsetBy: i)
                    let tailIndex = str.index(str.startIndex, offsetBy: i + 2)
                    ret.body.append(String(components[1][headIndex..<tailIndex]))
                }
            }
            return ret
            
        }.filter {
            availableChannels.index(of: $0.channel) != nil      // サポート外のチャンネルを利用する命令を除去
        }
        
        
        var longNotes1: [Note] = []         // ロングノーツ1を一時的に格納
        var longNotes2: [Note] = []         // ロングノーツ2を一時的に格納
        var musicStartPosSet: [Double] = [] // musicStartPosを一時的に格納
        var beatOffset = 0  // その小節の全オブジェクトに対する拍数の調整。4/4以外の拍子があった場合に上下する

        // processedMainDataを小節毎に分ける
        var barGroup: [Int : [(channel: Int, body: [String])]] = [:]   // 小節と、対応するprocessedMainDataの辞書
        for (bar, channel, body) in processedMainData {
            if barGroup[bar]?.append((channel, body)) == nil {
                barGroup[bar] = [(channel, body)]
            }
        }
        
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
                            let noteSpeedRatio = speedRatioTable[beat] ?? 1.0
                            
                            switch NoteExpression(rawValue: ob) ?? NoteExpression.rest {
                            case .rest:
                                break
                            case .tap:
                                notes.append(
                                    Tap     (beatPos: beat, laneIndex: lane, isLarge: false, appearTime: getAppearTime(beat), noteSpeedRatio: noteSpeedRatio)
                                )
                            case .flick:
                                notes.append(
                                    Flick   (beatPos: beat, laneIndex: lane,                 appearTime: getAppearTime(beat), noteSpeedRatio: noteSpeedRatio)
                                )
                            case .start1:
                                longNotes1.append(
                                    TapStart(beatPos: beat, laneIndex: lane, isLarge: false, appearTime: getAppearTime(beat), noteSpeedRatio: noteSpeedRatio)
                                )
                            case .middle1:
                                longNotes1.append(
                                    Middle  (beatPos: beat, laneIndex: lane,                                                  noteSpeedRatio: noteSpeedRatio)
                                )
                            case .end1:
                                longNotes1.append(
                                    TapEnd  (beatPos: beat, laneIndex: lane, isLarge: false,                                  noteSpeedRatio: noteSpeedRatio)
                                )
                            case .flickEnd1:
                                longNotes1.append(
                                    FlickEnd(beatPos: beat, laneIndex: lane,                                                  noteSpeedRatio: noteSpeedRatio)
                                )
                            case .start2:
                                longNotes2.append(
                                    TapStart(beatPos: beat, laneIndex: lane, isLarge: false, appearTime: getAppearTime(beat), noteSpeedRatio: noteSpeedRatio)
                                )
                            case .middle2:
                                longNotes2.append(
                                    Middle  (beatPos: beat, laneIndex: lane,                                                  noteSpeedRatio: noteSpeedRatio)
                                )
                            case .end2:
                                longNotes2.append(
                                    TapEnd  (beatPos: beat, laneIndex: lane, isLarge: false,                                  noteSpeedRatio: noteSpeedRatio)
                                )
                            case .flickEnd2:
                                longNotes2.append(
                                    FlickEnd(beatPos: beat, laneIndex: lane,                                                  noteSpeedRatio: noteSpeedRatio)
                                )
                            case .tapL:
                                notes.append(
                                    Tap     (beatPos: beat, laneIndex: lane, isLarge: true, appearTime: getAppearTime(beat),  noteSpeedRatio: noteSpeedRatio)
                                )
                            case .start1L:
                                longNotes1.append(
                                    TapStart(beatPos: beat, laneIndex: lane, isLarge: true, appearTime: getAppearTime(beat),  noteSpeedRatio: noteSpeedRatio)
                                )
                            case .end1L:
                                longNotes1.append(
                                    TapEnd  (beatPos: beat, laneIndex: lane, isLarge: true,                                   noteSpeedRatio: noteSpeedRatio)
                                )
                            case .start2L:
                                longNotes2.append(
                                    TapStart(beatPos: beat, laneIndex: lane, isLarge: true, appearTime: getAppearTime(beat),  noteSpeedRatio: noteSpeedRatio)
                                )
                            case .end2L:
                                longNotes2.append(
                                    TapEnd  (beatPos: beat, laneIndex: lane, isLarge: true,                                   noteSpeedRatio: noteSpeedRatio)
                                )
                            case .tapLL:
                                notes.append(
                                    Tap     (beatPos: beat, laneIndex: lane, isLarge: true, appearTime: getAppearTime(beat),  noteSpeedRatio: noteSpeedRatio)
                                )
                            }
                        }
                    }
                } else if channel == 1 {
                    // 楽曲開始命令の処理
                    for (index, ob) in body.enumerated() {
                        if ob == "10" {
                            let beat = Double(bar) * 4.0 + unitBeat * Double(index) + Double(beatOffset)
                            musicStartPosSet.append(beat)
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
                            BPMs.append((bpm: Double(newBPM), startPos: beat))
                        }
                    }
                } else if channel == 8 {
                    // BPM変更命令の処理(インデックス型テンポ変更)
                    for (index, ob) in body.enumerated() {
                        if let newBPM = BPMTable[ob] {
                            let beat = Double(bar) * 4.0 + unitBeat * Double(index) + Double(beatOffset)
                            BPMs.append((bpm: Double(newBPM), startPos: beat))
                        }
                    }
                }
            }
            
            // 小節長の変更があった場合にbeatOffsetを調整
            beatOffset += 4 - barLength
        }
        
        // musicStartPosを格納
        switch self.playMode {
        case .BGM:
            self.musicStartPos = musicStartPosSet[0]
        case .YouTube:
            self.musicStartPos = musicStartPosSet[1]
        case .YouTube2:
            self.musicStartPos = musicStartPosSet[2]
        }
        
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
                    if let temp = longNotes1[i] as? TapStart {
                        temp.next = longNotes1[i + 1]
                        longNotes1[i] = temp
                    } else if let temp = longNotes1[i] as? Middle {
                        temp.next = longNotes1[i + 1]
                        //						temp.before = longNotes1[i - 1]
                        longNotes1[i] = temp
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
                    if let temp = longNotes2[i] as? TapStart {
                        temp.next = longNotes2[i + 1]
                        longNotes2[i] = temp
                    } else if let temp = longNotes2[i] as? Middle {
                        temp.next = longNotes2[i + 1]
                        //						temp.before = longNotes2[i - 1]
                        longNotes2[i] = temp
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
                throw FileError.readFailed("ファイルの内容取得に失敗")
            }
        } else {
            throw FileError.notFound("指定されたファイルが見つかりません")
        }
    }
    
    
    /// ノーツが画面上に現れる時刻を返す(updateするかの判定に使用)
    private func getAppearTime(_ beat: Double) -> TimeInterval {
        var appearTime = TimeInterval(-Dimensions.laneLength / self.speed)   // レーン端から端までかかる時間
        
        for (index, bpm) in BPMs.enumerated() {
            if BPMs.count > index + 1 && beat > BPMs[index + 1].startPos {
                appearTime += (BPMs[index + 1].startPos - bpm.startPos) * 60 / bpm.bpm
            } else {
                appearTime += (beat - bpm.startPos) * 60 / bpm.bpm
                break
            }
        }
        
        return appearTime
    }
}
    

