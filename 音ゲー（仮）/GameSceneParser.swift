//
//  ReadBMS.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//
//（9/11の成果が残っている？）


// parse 関数はいろいろエラー投げるので
// こんな感じで使ってね
/*
do {
	try parse(fileName: "シュガーソングとビターステップ.bms")
}
catch FileError.invalidName     (let msg) { print(msg) }
catch FileError.notFound        (let msg) { print(msg) }
catch FileError.readFailed      (let msg) { print(msg) }
catch ParseError.lackOfData     (let msg) { print(msg) }
catch ParseError.invalidValue   (let msg) { print(msg) }
catch ParseError.noLongNoteStart(let msg) { print(msg) }
catch ParseError.noLongNoteEnd  (let msg) { print(msg) }
*/

import SpriteKit

extension GameScene{//bmsファイルを読み込む(nobu-gがつくってくれる)

	// ファイルエラー定義列挙体
	enum FileError: Error {
		case invalidName(String)
		case notFound(String)
		case readFailed(String)
	}

	// パースエラー定義列挙体
	enum ParseError: Error {
		case lackOfData(String)
		case invalidValue(String)
		case noLongNoteStart(String)
		case noLongNoteEnd(String)
	}






	// ファイルの読み込み
	func readFile(fileName: String) throws -> [String] {

		// ファイル名を名前と拡張子に分割
		guard fileName.contains(".") else {
		    throw FileError.invalidName("ファイル名には拡張子を指定してください")
		}
		let splittedName = fileName.components(separatedBy: ".")
		let dataFileName = splittedName[0]
		let dataFileType = splittedName[1]

		// 譜面データファイルのパスを取得
		// iPhone内のパスを指定するように変えてね
		if let path = Bundle.main.path(forResource: dataFileName, ofType: dataFileType) {
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

	// 渡されたファイルを読んでnotes配列を作成
	func parse(fileName: String) throws {

		// 譜面データファイルを一行ごとに配列で保持
		var bmsData: [String] = []

		// 譜面データファイルのヘッダ
		var header: [String] = []
		// 譜面データファイルのメインデータ
		var rawMainData: [String] = []

		// ファイルの内容をbmsDataに格納
		bmsData = try readFile(fileName: fileName)

		// 先頭が'#'であるものだけを抽出し、'#'を削除
		bmsData = bmsData
			.filter { $0.hasPrefix("#") }
			.map { str in String(str.suffix(str.count - 1)) }

		// ヘッダとメインデータに分割
		for bmsLine in bmsData {
			if Int(bmsLine.prefix(1)) == nil {
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
			"BPM":       { value in if let num = Double(value) { GameScene.bpm    = num } },
			"PLAYLEVEL": { value in if let num = Int(value) { self.playLevel = num } },
			"VOLWAV":    { value in if let num = Int(value) { self.volWav    = num } }
		]

		// 1行ずつ処理
		for headerLine in header {
			let components = headerLine.components(separatedBy: " ")
			if components.count >= 2 {
				if let headerInstruction = headerInstructionTable[components[0]] {
					var value = components[1]
					let splittedValue = components.dropFirst(2)
					for str in splittedValue {
						value += (" " + str)
					}
					headerInstruction(value)
				}
			}
		}


		/*--- メインデータをパース ---*/

		// 利用可能なチャンネル番号
		let availableChannels = [1, 11, 12, 13, 14, 15, 18, 19]

		// チャンネルとレーンの対応付け
		let laneMap = [11: 1, 12: 2, 13: 3, 14: 4, 15: 5, 18: 6, 19: 7]

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
			case bgm       = "10"
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
			// オブジェクト配列を2文字ずつに分けてdataに格納
			for i in stride(from: 0, to: components[1].count, by: 2) {
				let headIndex = str.index(str.startIndex, offsetBy: i)
				let tailIndex = str.index(str.startIndex, offsetBy: i + 2)
				ret.body.append(String(components[1][headIndex..<tailIndex]))
			}
			return ret
		}.filter {
			availableChannels.index(of: $0.channel) != nil		// サポート外のチャンネルを利用する命令を除去
		}

		// ロングノーツは一時配列に、その他はnotesに格納
		var longNotes1: [Note] = []		// ロングノーツ1を一時的に格納
		var longNotes2: [Note] = []		// ロングノーツ2を一時的に格納
		for mainData in processedMainData {
			let unitBeat = 4.0 / Double(mainData.body.count)	// 1オブジェクトの長さ(拍単位)
			for (index, ob) in mainData.body.enumerated() {
				switch NoteExpression(rawValue: ob) ?? NoteExpression.rest {
				case .rest:
					break
				case .tap:
					notes.append(
						Note(
							type: .tap,
							position: Double(mainData.bar) * 4.0 + unitBeat * Double(index),
							lane: laneMap[mainData.channel] ?? 0	// あり得ないけどnilのときは0(できればthrowしたい)
						)
					)
				case .flick:
					notes.append(
						Note(
							type: .flick,
							position: Double(mainData.bar) * 4.0 + unitBeat * Double(index),
							lane: laneMap[mainData.channel] ?? 0
						)
					)
				case .start1:
					longNotes1.append(
						Note(
							type: .tap,
							position: Double(mainData.bar) * 4.0 + unitBeat * Double(index),
							lane: laneMap[mainData.channel] ?? 0
						)
					)
				case .middle1:
					longNotes1.append(
						Note(
							type: .middle,
							position: Double(mainData.bar) * 4.0 + unitBeat * Double(index),
							lane: laneMap[mainData.channel] ?? 0
						)
					)
				case .end1:
					longNotes1.append(
						Note(
							type: .tapEnd,
							position: Double(mainData.bar) * 4.0 + unitBeat * Double(index),
							lane: laneMap[mainData.channel] ?? 0
						)
					)
				case .flickEnd1:
					longNotes1.append(
						Note(
							type: .flickEnd,
							position: Double(mainData.bar) * 4.0 + unitBeat * Double(index),
							lane: laneMap[mainData.channel] ?? 0
						)
					)
				case .start2:
					longNotes2.append(
						Note(
							type: .tap,
							position: Double(mainData.bar) * 4.0 + unitBeat * Double(index),
							lane: laneMap[mainData.channel] ?? 0
						)
					)
				case .middle2:
					longNotes2.append(
						Note(
							type: .middle,
							position: Double(mainData.bar) * 4.0 + unitBeat * Double(index),
							lane: laneMap[mainData.channel] ?? 0
						)
					)
				case .end2:
					longNotes2.append(
						Note(
							type: .tapEnd,
							position: Double(mainData.bar) * 4.0 + unitBeat * Double(index),
							lane: laneMap[mainData.channel] ?? 0
						)
					)
				case .flickEnd2:
					longNotes2.append(
						Note(
							type: .flickEnd,
							position: Double(mainData.bar) * 4.0 + unitBeat * Double(index),
							lane: laneMap[mainData.channel] ?? 0
						)
					)
				case .bgm:
					// 楽曲開始命令の処理
					if mainData.channel == 1 {
						musicStartPos = Double(mainData.bar) * 4.0 + unitBeat * Double(index)
					}
				}
			}
		}

		// ロングノーツを時間順にソート(同じ場合は.tapEnd or .flickEnd < .tap)
		longNotes1.sort(by: {
			if $0.pos == $1.pos { return $1.type == .tap }
			else { return $0.pos < $1.pos }
		})
		longNotes2.sort(by: {
			if $0.pos == $1.pos { return $1.type == .tap }
			else { return $0.pos < $1.pos }
		})

		// 線形リストを作成し、先頭をnotesに格納
		// longNotes1について
		var i = 0
		while i < longNotes1.count {
			if longNotes1[i].type == .tap {
				notes.append(longNotes1[i])
				while longNotes1[i].type != .tapEnd &&
					  longNotes1[i].type != .flickEnd {
					guard i + 1 < longNotes1.count else {
						throw ParseError.noLongNoteEnd("ロングノーツ終了命令がありません")
					}
					if longNotes1[i + 1].type == .tap || longNotes1[i + 1].type == .flick {
						throw ParseError.noLongNoteEnd("ロングノーツ終了命令がありません")
					}
					longNotes1[i].next = longNotes1[i + 1]

					i += 1
				}
				i += 1
			} else {
				throw ParseError.noLongNoteStart("ロングノーツ開始命令がありません")
			}
		}
		// longNotes2について
		i = 0
		while i < longNotes2.count {
			if longNotes2[i].type == .tap {
				notes.append(longNotes2[i])
				while longNotes2[i].type != .tapEnd &&
					  longNotes2[i].type != .flickEnd {
					guard i + 1 < longNotes2.count else {
						throw ParseError.noLongNoteEnd("ロングノーツ終了命令がありません")
					}
					if longNotes2[i + 1].type == .tap || longNotes2[i + 1].type == .flick {
						throw ParseError.noLongNoteEnd("ロングノーツ終了命令がありません")
					}
					longNotes2[i].next = longNotes2[i + 1]

					i += 1
				}
				i += 1
			} else {
				throw ParseError.noLongNoteStart("ロングノーツ開始命令がありません")
			}
		}

		// 時間順にソート
		notes.sort(by: { $0.pos < $1.pos })
	}
}
