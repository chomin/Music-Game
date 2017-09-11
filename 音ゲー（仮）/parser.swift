/*
BMSファイルを解析して
プログラム内で扱うオブジェクト配列を作成する
*/

import Foundation

// エラー定義列挙体
enum FileError: Error {
	case NotFound(String)
	case ReadFailed(String)
}

enum ParseError: Error {
	case LackOfData(String)
	case InvalidValue(String)
}

// 譜面データファイルを一行ごとに配列で保持
var bmsData: [String] = []			// 初期化してないよって言われるので一応空配列を代入

// 譜面データファイルのヘッダ
var header: [String] = []
// 譜面データファイルのメインデータ
var rawMainData: [String] = []

// 楽曲データ
var genre = ""			// ジャンル
var title = ""			// タイトル
var artist = ""			// アーティスト
var bpm = 130			// Beats per Minute
var playLevel = 0		// 難易度
var stageFile = ""		// データ読み込み時に表示する画像ファイル
var volWav = 100		// 音量を現段階のn%として出力するか

// 譜面データ(NoteTypeとNoteの定義はおそらくほかのファイルでもするだろうから統合してほしい)
enum NoteType {
	case tap, flick, middle, tapEnd, flickEnd
}

class Note {
	var type: NoteType
	var pos: Double
	var lane: Int
	var next: Note?

	init(type: NoteType, position pos: Double, lane: Int) {
	    self.type = type
		self.pos = pos
		self.lane = lane
		self.next = nil
	}
}

// ノーツの始点の集合
var notes: [Note] = []


// ファイルの読み込み
func ReadFile() throws -> [String] {
	let dataFileName = "シュガーソングとビターステップ"
	let dataFileType = "bms"

	// 譜面データファイルのパスを取得
	// iPhone内のパスを指定するように変えてね
	if let path: String = Bundle.main.path(forResource: dataFileName, ofType: dataFileType) {
		do {
	        // ファイルの内容を取得する
	        let content = try String(contentsOfFile: path, encoding: String.Encoding.shiftJIS)
	        return content.components(separatedBy: "\r\n")
	    } catch  {
			throw FileError.ReadFailed("ファイルの内容取得に失敗")
	    }
	} else {
		throw FileError.NotFound("指定されたファイルが見つかりません")
	}
}

do {
	bmsData = try ReadFile()
} catch FileError.NotFound(let msg) {
	print(msg)
	// 以降で空配列をいじることになってしまうのできちんとreturnかなにかしてね
} catch FileError.ReadFailed(let msg) {
	print(msg)
	// 同上
}

// 先頭が'#'であるものだけを抽出し、'#'を削除
bmsData = bmsData
	.filter { $0.hasPrefix("#") }
	.map { str in str.substring(from: str.index(after: str.startIndex)) }

// ヘッダとメインデータに分割
for bmsLine in bmsData {
	if Int(bmsLine.substring(to: bmsLine.index(after: bmsLine.startIndex))) == nil {
		header.append(bmsLine)
	}
	else {
		rawMainData.append(bmsLine)
	}
}


/*--- ヘッダをパース ---*/

// コマンド文字列を命令と結びつける辞書
let headerInstructionTable: [String: (String) -> ()] = [
	"GENRE":     { value in genre     = value },
	"TITLE":     { value in title     = value },
	"ARTIST":    { value in artist    = value },
	"BPM":       { value in if let num = Int(value) { bpm = num } },
	"PLAYLEVEL": { value in if let num = Int(value) { playLevel = num} },
	"STAGEFILE": { value in stageFile = value },
	"VOLWAV":    { value in if let num = Int(value) { volWav = num } }
]

// 1行ずつ処理
for headerLine in header {
	let components = headerLine.components(separatedBy: " ")
	if components.count >= 2 {
		if let headerInstruction = headerInstructionTable[components[0]] {
			headerInstruction(components[1])
		}
	}
}


/*--- メインデータをパース ---*/

// 利用可能なチャンネル番号
let availableChannels = [1, 11, 12, 13, 14, 15, 18, 19]

// チャンネルとレーンの対応付け
let laneMap: [Int: Int] = [11: 1, 12: 2, 13: 3, 14: 4, 15: 5, 18: 6, 19: 7]

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
}

// メインデータ1行を小節番号・チャンネル・データのタプルに分解
let processedMainData = rawMainData.map { str -> (bar: Int, channel: Int, body: [String]) in
	var ret = (bar: 0, channel: 0, body: [String]())

	let components = str.components(separatedBy: ":")
	if components.count < 2 {
		// TODO: throw ParseError.LackOfData("データが欠損しています")
	}
	else {
		if let num = Int(components[0].substring(to: str.index(str.startIndex, offsetBy: 3))) {
			ret.bar = num
		}
		else {
			print("error")
			// TODO: throw ParseError.InvalidValue("メインデータコマンドが不正です")
		}
		if let num = Int(components[0].substring(from: str.index(str.startIndex, offsetBy: 3))) {
			ret.channel = num
		}
		else {
			print("error")
			// TODO: throw ParseError.InvalidValue("メインデータコマンドが不正です")
		}
		// オブジェクト配列を2文字ずつに分けてdataに格納
		for i in stride(from: 0, to: components[1].characters.count, by: 2) {
			let headIndex = str.index(str.startIndex, offsetBy: i)
			let tailIndex = str.index(str.startIndex, offsetBy: i + 2)
			ret.body.append(components[1].substring(with: headIndex..<tailIndex))
		}
	}
	return ret
}.filter {
	availableChannels.index(of: $0.channel) != nil		// サポート外のチャンネルを利用する命令を除去
}

// 先にロングノーツを処理
var longNotes1: [Note] = []
var longNotes2: [Note] = []
for mainData in processedMainData {
	let unitBeat = 4.0 / Double(mainData.body.count)
	for (index, ob) in mainData.body.enumerated() {
		switch NoteExpression(rawValue: ob) ?? NoteExpression.rest {
		case NoteExpression.start1:
			longNotes1.append(
				Note(
				type: NoteType.tap,
				position: mainData.bar * 4 + unitBeat * index,
				lane: laneMap[mainData.channel]
				)
			)
		case NoteExpression.middle1:
			longNotes1.append(
				Note(
				type: NoteType.middle,
				position: mainData.bar * 4 + unitBeat * index,
				lane: laneMap[mainData.channel]
				)
			)

		default:
			break
		}
	}
}









// for str in rawMainData { print(str) }
