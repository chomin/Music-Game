//
//  Music.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2018/08/23.
//  Copyright © 2018年 NakaiKohei. All rights reserved.
//

/* BMSチャンネル番号定義
 * 01: 楽曲開始命令(10,20,30)、及び楽曲終了命令(11)
 * 02: 小節長変更命令(bodyに倍率を小数で指定)
 * 03: BPM変更命令
 * 08: インデックス型BPM変更命令(256以上や小数のBPMに対応)
 * 11-15, 18-19: レーン指定(レーン数によっては使わない場所あり)
 * 21: ノーツスピード変更命令(倍率を16倍したものを16進数で記述)
 */

import SpriteKit


enum NoteType {
    case tap, flick, right, left, tapStart, middle, tapEnd, flickEnd, rightEnd, leftEnd

    var isEnd: Bool {
        return self == NoteType.tapEnd || self == NoteType.flickEnd || self == NoteType.rightEnd || self == NoteType.leftEnd
    }
}

/// BMSのメインデータから得られるノーツ情報。このオブジェクトから最終的にノーツを生成する
class NoteMaterial {
    let type: NoteType
    let beat: Double
    let laneIndex: Int
    let speedRatio: Double
    let isLarge: Bool
    fileprivate(set) var next: NoteMaterial?

    init(type: NoteType, beatPos beat: Double, laneIndex: Int, speedRatio: Double, isLarge: Bool = false) {
        self.type = type
        self.beat = beat
        self.laneIndex = laneIndex
        self.speedRatio = speedRatio
        self.isLarge = isLarge
    }
}


/// bmsファイルから読み込まれた音楽情報をまとめたentity。ヘッダ情報とメイン情報を持つ。
class Music {

    // ファイルエラー定義列挙型
    enum FileError: Error {
//        case invalidName(String)
        case notFound(String)
        case readFailed(String)
    }

    // パースエラー定義列挙型
    enum ParseError: Error {
        case lackOfData(String)
//        case lackOfVideoID(String)
        case invalidValue(String)
        case noLongNoteStart(String)
        case noLongNoteEnd(String)
        case unexpected(String)

        /// 渡されたnoteのbeatが何小節目何拍目かを返す
        static func getBeat(of nmat: NoteMaterial) -> String {
            let bar = Int(nmat.beat / 4.0)
            let restBeat = nmat.beat - Double(bar * 4)
            return "\(bar)小節\(restBeat)拍目"
        }
    }


    private let header: Header                          // 楽曲のメタデータ
    private var noteMaterials: [NoteMaterial] = []      // ノーツの中間表現。BMSの譜面部分と1対1に対応
    var BPMs: [(bpm: Double, startPos: Double)] = []    // 楽曲中のBPMをその開始地点(拍)とともに格納
    var videoID: String = ""                            // YouTubeのvideoID
    var musicStartPos: Double = 0                       // BGM開始の拍
    var duration: TimeInterval?                         // 楽曲継続時間(楽曲終了命令があれば設定される)
    
    var laneNum:              Int    { return header.laneNum              }   // レーン数(デフォルトは7)
    var genre:                String { return header.genre                }   // ジャンル
    var title:                String { return header.title                }   // タイトル(正式名称。ファイル名は文字の制約があるためこっちを正式とする)
    var artist:               String { return header.artist               }   // アーティスト
    var group:                String { return header.group                }
    var playLevel:            Int    { return header.playLevel            }   // 難易度
    var volWav:               Int    { return header.volWav               }   // 音量を現段階のn%として出力するか(TODO: 未実装)
    var bmsNameWithExtension: String { return header.bmsNameWithExtension }
    var offset:               Int    { return header.offset               }
    var youTubeOffset:        Int    { return header.youTubeOffset        }

    init(header: Header, playMode: PlayMode) {
        self.header = header

        if playMode == .YouTube {
            videoID = header.videoID
        } else if playMode == .YouTube2 {
            videoID = header.videoID2
        }
        /* BMSファイルのメインデータをパース */
        do {
            try parse(playMode)
        }
//        catch FileError.invalidName     (let msg) { print(msg) }
        catch FileError.notFound        (let msg) { print(msg) }
        catch FileError.readFailed      (let msg) { print(msg) }
        catch ParseError.lackOfData     (let msg) { print(msg) }
        catch ParseError.invalidValue   (let msg) { print(msg) }
        catch ParseError.noLongNoteStart(let msg) { print(msg) }
        catch ParseError.noLongNoteEnd  (let msg) { print(msg) }
        catch ParseError.unexpected     (let msg) { print(msg) }
//        catch Music.ParseError.lackOfVideoID(let msg) {
//            print(msg)
//            reloadSceneAsBGMMode()
//            return
//        }
        catch { print("未知のエラー") }
    }


    /// BMSファイルから得たノーツの中間表現からNoteオブジェクトを生成
    ///
    /// - Parameter userSpeedRatio: ユーザー設定によるスピード倍率
    /// - Returns: 単ノーツ及びロングノーツの始点にあたるNoteオブジェクトの配列
    func generateNotes(setting: Setting, duration: TimeInterval) -> [Note] {

        guard !BPMs.isEmpty else {
            print("空のBPM配列")
            return []
        }

        Note.BPMs = BPMs    // Noteクラスから頻繁にアクセスされるのでクラス変数にしておく(Musicのクラス変数にするorノーツのupdateの時に引数でわたしてもいい)

        if !setting.isFitSizeToLane {
            Note.scale = CGFloat(setting.scaleRatio/7*Double(laneNum))
        } else {
            Note.scale = CGFloat(setting.scaleRatio)
        }

        // 楽曲の基本BPM。BPM配列の中から最も持続時間が長いもの。
        let majorBPM = { () -> Double in
            var BPMIntervals: [(bpm: Double, interval: TimeInterval)] = []
            var timeSum: TimeInterval = 0
            var i = 0
            while true {
                if i + 1 < BPMs.count {
                    let interval = TimeInterval((BPMs[i + 1].startPos - BPMs[i].startPos) / (BPMs[i].bpm/60))
                    BPMIntervals.append((BPMs[i].bpm, interval))
                    timeSum += interval
                } else {
                    let interval = (self.duration ?? duration) - timeSum
                    BPMIntervals.append((BPMs[i].bpm, interval))
                    break
                }
                i += 1
            }
            return BPMIntervals.max { $0.interval < $1.interval }!.bpm
        }()

        /// ノーツが画面上に現れる時刻を返す(updateするかの判定に使用)
        func getAppearTime(_ beat: Double, _ speed: CGFloat) -> TimeInterval {
            var judgeTime: TimeInterval = 0.0   // 判定線上に乗る時刻
            var i = 0
            while i + 1 < Note.BPMs.count && Note.BPMs[i + 1].startPos < beat {
                judgeTime += (Note.BPMs[i + 1].startPos - Note.BPMs[i].startPos) / (Note.BPMs[i].bpm/60)

                i += 1
            }
            judgeTime += (beat - Note.BPMs[i].startPos) / (Note.BPMs[i].bpm/60)
            let appearTime = judgeTime - TimeInterval(Dimensions.laneLength / speed)   // judgeTime - レーン端から端までかかる時間

            return appearTime
        }

        /// Noteオブジェクトを生成。ロングノーツは始点から再帰的に生成
        func generate(_ noteMaterial: NoteMaterial, _ color: UIColor = UIColor.green) -> Note {
            var note = Note()
            let bpm = BPMs.filter { $0.startPos <= noteMaterial.beat } .last!.bpm   // このノーツが判定線に乗った時のBPM
            let speed = CGFloat(1350 * noteMaterial.speedRatio * setting.speedRatio * bpm / majorBPM)
            autoreleasepool {
                switch noteMaterial.type {
                case .tap:      note = Tap     (noteMaterial: noteMaterial, speed: speed, appearTime: getAppearTime(noteMaterial.beat, speed))
                case .flick:    note = Flick   (noteMaterial: noteMaterial, speed: speed, appearTime: getAppearTime(noteMaterial.beat, speed), direction: .any   )
                case .right:    note = Flick   (noteMaterial: noteMaterial, speed: speed, appearTime: getAppearTime(noteMaterial.beat, speed), direction: .right )
                case .left:     note = Flick   (noteMaterial: noteMaterial, speed: speed, appearTime: getAppearTime(noteMaterial.beat, speed), direction: .left  )
                case .tapStart: note = TapStart(noteMaterial: noteMaterial, speed: speed, appearTime: getAppearTime(noteMaterial.beat, speed))
                case .middle:   note = Middle  (noteMaterial: noteMaterial, speed: speed, appearTime: getAppearTime(noteMaterial.beat, speed))
                case .tapEnd:   note = TapEnd  (noteMaterial: noteMaterial, speed: speed)
                case .flickEnd: note = FlickEnd(noteMaterial: noteMaterial, speed: speed, direction: .any   )
                case .rightEnd: note = FlickEnd(noteMaterial: noteMaterial, speed: speed, direction: .right )
                case .leftEnd:  note = FlickEnd(noteMaterial: noteMaterial, speed: speed, direction: .left  )
                }
            }

            // 後続ノーツを再帰的に生成
            if let tapStart = note as? TapStart {
                if let next = noteMaterial.next {
                    tapStart.next = generate(next, tapStart.longImages.circle.fillColor)  // 再帰
                } else {
                    print("tapStartタイプのnoteMaterialにnextが設定されていません。")
                }
            } else if let middle = note as? Middle {
                if let next = noteMaterial.next {
                    middle.longImages.circle.fillColor = color      // ガイド円の色を設定
                    middle.next = generate(next, middle.longImages.circle.fillColor)    // 再帰
                } else {
                    print("middleタイプのnoteMaterialにnextが設定されていません。")
                }
            }
            return note
        }
        return noteMaterials.map { generate($0) }
    }

    /// 渡されたファイルを読んで譜面データを作成
    /// 投げるエラーはFileError列挙型とParseError列挙型に定義されている
    ///
    /// - Throws: パース時に発生したエラー
    private func parse(_ playMode: PlayMode) throws {

        // 譜面データファイルを一行ごとに配列で保持
        let bmsData = try readFile(fileName: header.bmsNameWithExtension)

        // 譜面データファイルのメインデータ
        var mainData: [(bar: Int, channel: Int, body: [String])] = []

        // インデックス型テンポ変更用テーブル
        var BPMTable: [String : Double] = [:]

        // コマンド文字列を命令と結びつける辞書
        let headerInstructionTable: [String: (String) -> ()] = [
            "BPM":       { value in if let num = Double(value) { self.BPMs = [(num, 0.0)] } },
            "VIDEOID":   { _ in () },
            "VIDEOID2":  { _ in () },
            "GENRE":     { _ in () },   // NOP
            "TITLE":     { _ in () },
            "ARTIST":    { _ in () },
            "GROUP":     { _ in () },
            "PLAYLEVEL": { _ in () },
            "VOLWAV":    { _ in () },
            "LANE":      { _ in () }
        ]

        let headerEx = try! Regex("^#([A-Z][0-9A-Z]*)( .*)?$")   // ヘッダの行にマッチ
        let mainDataEx = try! Regex("^#([0-9]{3})([0-9]{2}):(([0-9A-Z]{2})+)$")   // メインデータの小節長変更命令以外にマッチ
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
                    print("未定義のヘッダ命令: \(item)")
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

//        if (playMode == .YouTube || playMode == .YouTube2) && videoID == "" {
//            throw ParseError.lackOfVideoID("ファイル内にvideoIDが見つかりませんでした。BGMモードで実行します。")
//        }


        /*--- メインデータからノーツの中間表現を生成 ---*/

        // チャンネルとレーンの対応付け(辞書)
        let laneMap = { () -> [Int: Int] in
            switch header.laneNum {
            case 1: return [                      14: 0                      ]
            case 2: return [               13: 0,        15: 1               ]
            case 3: return [               13: 0, 14: 1, 15: 2               ]
            case 4: return [        12: 0, 13: 1,        15: 2, 18: 3        ]
            case 5: return [        12: 0, 13: 1, 14: 2, 15: 3, 18: 4        ]
            case 6: return [ 11: 0, 12: 1, 13: 2,        15: 3, 18: 4, 19: 5 ]
            case 7: return [ 11: 0, 12: 1, 13: 2, 14: 3, 15: 4, 18: 5, 19: 6 ]
            default:
                header.laneNum = 7
                return [11: 0, 12: 1, 13: 2, 14: 3, 15: 4, 18: 5, 19: 6]
            }
        }()

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
            case right     = "0H"
            case left      = "0I"
            case rightEnd1 = "0J"
            case leftEnd1  = "0K"
            case rightEnd2 = "0L"
            case leftEnd2  = "0M"
        }

        // mainDataを小節毎に分ける
        var barGroup: [Int : [(channel: Int, body: [String])]] = [:]   // 小節と、対応するmainDataの辞書
        for (bar, channel, body) in mainData {
            if barGroup[bar]?.append((channel, body)) == nil {
                barGroup[bar] = [(channel, body)]
            }
        }

        var longNotes1: [NoteMaterial] = []         // ロングノーツ1を一時的に格納
        var longNotes2: [NoteMaterial] = []         // ロングノーツ2を一時的に格納
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

                        let beat = Double(bar) * 4.0 + unitBeat * Double(index) + Double(beatOffset)
                        let ratio = speedRatioTable[beat] ?? 1.0

                        switch NoteExpression(rawValue: ob) ?? NoteExpression.rest {
                        case .rest:
                            break
                        case .tap:
                            noteMaterials.append(NoteMaterial(type: .tap,      beatPos: beat, laneIndex: lane, speedRatio: ratio, isLarge: false))
                        case .flick:
                            noteMaterials.append(NoteMaterial(type: .flick,    beatPos: beat, laneIndex: lane, speedRatio: ratio))
                        case .right:
                            noteMaterials.append(NoteMaterial(type: .right,    beatPos: beat, laneIndex: lane, speedRatio: ratio))
                        case .left:
                            noteMaterials.append(NoteMaterial(type: .left,     beatPos: beat, laneIndex: lane, speedRatio: ratio))
                        case .start1:
                            longNotes1   .append(NoteMaterial(type: .tapStart, beatPos: beat, laneIndex: lane, speedRatio: ratio, isLarge: false))
                        case .middle1:
                            longNotes1   .append(NoteMaterial(type: .middle,   beatPos: beat, laneIndex: lane, speedRatio: ratio))
                        case .end1:
                            longNotes1   .append(NoteMaterial(type: .tapEnd,   beatPos: beat, laneIndex: lane, speedRatio: ratio, isLarge: false))
                        case .flickEnd1:
                            longNotes1   .append(NoteMaterial(type: .flickEnd, beatPos: beat, laneIndex: lane, speedRatio: ratio))
                        case .rightEnd1:
                            longNotes1   .append(NoteMaterial(type: .rightEnd, beatPos: beat, laneIndex: lane, speedRatio: ratio))
                        case .leftEnd1:
                            longNotes1   .append(NoteMaterial(type: .leftEnd,  beatPos: beat, laneIndex: lane, speedRatio: ratio))
                        case .start2:
                            longNotes2   .append(NoteMaterial(type: .tapStart, beatPos: beat, laneIndex: lane, speedRatio: ratio, isLarge: false))
                        case .middle2:
                            longNotes2   .append(NoteMaterial(type: .middle,   beatPos: beat, laneIndex: lane, speedRatio: ratio))
                        case .end2:
                            longNotes2   .append(NoteMaterial(type: .tapEnd,   beatPos: beat, laneIndex: lane, speedRatio: ratio, isLarge: false))
                        case .flickEnd2:
                            longNotes2   .append(NoteMaterial(type: .flickEnd, beatPos: beat, laneIndex: lane, speedRatio: ratio))
                        case .rightEnd2:
                            longNotes2   .append(NoteMaterial(type: .rightEnd, beatPos: beat, laneIndex: lane, speedRatio: ratio))
                        case .leftEnd2:
                            longNotes2   .append(NoteMaterial(type: .leftEnd,  beatPos: beat, laneIndex: lane, speedRatio: ratio))
                        case .tapL:
                            noteMaterials.append(NoteMaterial(type: .tap,      beatPos: beat, laneIndex: lane, speedRatio: ratio, isLarge: true))
                        case .start1L:
                            longNotes1   .append(NoteMaterial(type: .tapStart, beatPos: beat, laneIndex: lane, speedRatio: ratio, isLarge: true))
                        case .end1L:
                            longNotes1   .append(NoteMaterial(type: .tapEnd,   beatPos: beat, laneIndex: lane, speedRatio: ratio, isLarge: true))
                        case .start2L:
                            longNotes2   .append(NoteMaterial(type: .tapStart, beatPos: beat, laneIndex: lane, speedRatio: ratio, isLarge: true))
                        case .end2L:
                            longNotes2   .append(NoteMaterial(type: .tapEnd,   beatPos: beat, laneIndex: lane, speedRatio: ratio, isLarge: true))
                        case .tapLL:
                            noteMaterials.append(NoteMaterial(type: .tap,      beatPos: beat, laneIndex: lane, speedRatio: ratio, isLarge: true))
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
                } else if channel == 14 && laneNum == 6 {
                    // ミリシタ譜面の特大ノーツを処理
                    for (index, ob) in body.enumerated() {
                        if NoteExpression(rawValue: ob) == .tapLL {
                            let beat = Double(bar) * 4.0 + unitBeat * Double(index) + Double(beatOffset)
                            let ratio = speedRatioTable[beat] ?? 1.0
                            noteMaterials.append(NoteMaterial(type: .tap, beatPos: beat, laneIndex: 2, speedRatio: ratio, isLarge: true))
                            noteMaterials.append(NoteMaterial(type: .tap, beatPos: beat, laneIndex: 3, speedRatio: ratio, isLarge: true))
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
            if musicStartPosSet[.YouTube] == nil {
                print("YouTube用の楽曲開始命令がありません.BGM用の楽曲開始命令を使用します.")
            } else {
//                print("BGM: \(musicStartPosSet[.BGM]!)")
//                print("YouTube: \(musicStartPosSet[.YouTube]!)")
            }
            
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
                    if i + 1 < BPMs.count {
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
            if $0.beat == $1.beat { return $1.type == .tapStart }
            else { return $0.beat < $1.beat }
        })
        longNotes2.sort(by: {
            if $0.beat == $1.beat { return $1.type == .tapStart }
            else { return $0.beat < $1.beat }
        })

        // 線形リストを作成し、先頭をnotesに格納
        for longNotes in [longNotes1, longNotes2] {
            var i = 0
            while i < longNotes.count {
                if longNotes[i].type == .tapStart {
                    noteMaterials.append(longNotes[i])
                    while !(longNotes[i].type.isEnd) {
                        guard i + 1 < longNotes.count else {
                            throw ParseError.noLongNoteEnd("ロングノーツ終了命令がありません(\(ParseError.getBeat(of: longNotes[i])))")
                        }
                        guard longNotes[i + 1].type == .middle || longNotes[i + 1].type.isEnd else {
                            throw ParseError.noLongNoteEnd("ロングノーツ終了命令がありません(\(ParseError.getBeat(of: longNotes[i + 1])))")
                        }
                        if longNotes[i].type == .tapStart || longNotes[i].type == .middle {
                            longNotes[i].next = longNotes[i + 1]
                        } else {
                            throw ParseError.unexpected("予期せぬエラー")
                        }

                        i += 1
                    }

                    i += 1
                } else {
                    throw ParseError.noLongNoteStart("ロングノーツ開始命令がありません(\(ParseError.getBeat(of: longNotes[i])))")
                }
            }
        }

        // 時間順にソート
        noteMaterials.sort(by: { $0.beat < $1.beat })
    }

    // ファイルの読み込み
    private func readFile(fileName: String) throws -> [String] {

        // 譜面データファイルのパスを取得
        let path = GDFileManager.cachesDirectoty.appendingPathComponent(fileName).path
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
    }
}
