//
//  GameScene.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation

class GameScene: SKScene {//音ゲーをするシーン
	
	
	//音楽プレイヤー
	var BGM:AVAudioPlayer?
	var flickSound1:AVAudioPlayer?    //同時に鳴らせるように2つ作る
	var flickSound2:AVAudioPlayer?
	var tapSound1:AVAudioPlayer?
	var tapSound2:AVAudioPlayer?
	var tapSound3:AVAudioPlayer?
	var tapSound4:AVAudioPlayer?
	var kara1:AVAudioPlayer?
	var kara2:AVAudioPlayer?
	var kara3:AVAudioPlayer?
	var kara4:AVAudioPlayer?
	
	
	//画像(ノーツ以外)
	var longImages:[SKShapeNode] = []
	var judgeLine:SKShapeNode!
	
	//ボタン
	let buttons = [ExpansionButton(),ExpansionButton(),ExpansionButton(),ExpansionButton(),ExpansionButton(),ExpansionButton(),ExpansionButton()]
	
	// 楽曲データ
	var notes:[Note] = []	//ノーツの" 始 点 "の集合。参照型！
	static var start:TimeInterval!	  //シーン移動した時の時間
	var musicStartPos = 1.0	  //BGM開始の"拍"！
	var playLebel = 0
	var genre = ""				// ジャンル
	var title = ""				// タイトル
	var artist = ""				// アーティスト
	static var bpm = 132.0				// Beats per Minute
	var playLevel = 0			// 難易度
	var volWav = 100			// 音量を現段階のn%として出力するか
	var lanes:[Lane] = [Lane(),Lane(),Lane(),Lane(),Lane(),Lane(),Lane()]		//レーン
	
	
	override func didMove(to view: SKView) {
		
		//スピードの設定
		speed = 700.0
		
		//notesにノーツの"　始　点　"を入れる(nobuの仕事)
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
		catch                                     { print("未知のエラー") }

		//画像、音楽、ボタン、ラベルの設定
		setAllSounds()
		setButtons()
		setImages()
		
		//BGMの再生(時間指定)
		GameScene.start = CACurrentMediaTime()
		BGM!.play(atTime: GameScene.start + (musicStartPos/GameScene.bpm)*60)
		
		//各レーンに最初の判定対象ノーツをセット
		for (index,_) in lanes.enumerated(){
			first: for i in notes{
				if i.lane == index+1 {
					lanes[index].nextNote = i
					break
				}
				
				var note:Note! = i.next
				
				while note != nil {
					if note.next.lane == index+1 {
						lanes[index].nextNote = note.next
						break first
					}
					note = note.next
				}
			}
		}
		
		
	}
	
	
	override func update(_ currentTime: TimeInterval) {
		
		//時間でノーツの位置を設定する(ノーツが多いと重くなるかも？)
		for i in notes{
			
			setYPos(note: i, currentTime: currentTime)
			
			var note:Note? = i
			while note?.next != nil{
				
				setYPos(note: (note?.next)!, currentTime: currentTime)
				
				note = note?.next
			}
		}
		
		//レーンの監視(過ぎて行ってないか)
		for (index,value) in lanes.enumerated(){
			lanes[index].currentTime = currentTime
			if value.timeState == .passed {
				print("miss!")
				lanes[index].nextNote.image.isHidden = true
				
				//次のノーツを格納
				var note:Note! = value.nextNote
				while note != nil {
					break
				}
			}
		}
		
		
	}
}

// 譜面データ(NoteTypeとNoteの定義はおそらくほかのファイルでもするだろうから統合してほしい)
enum NoteType {
	case tap, flick, middle, tapEnd, flickEnd
}

class Note {
	let type: NoteType
	let pos: Double //"拍"単位！小節ではない！！！
	let lane: Int
	var next: Note!
	var image:SKShapeNode!	  //ノーツの画像
	
	init(type: NoteType, position pos: Double, lane: Int) {
		self.type = type
		self.pos = pos
		self.lane = lane
	}
}

enum TimeState {
	case miss,bad,good,great,parfect,still,passed
}

struct Lane {
	var timeState:TimeState{
		get{
			let timeLag = nextNote.pos*60/GameScene.bpm + GameScene.start! - currentTime
			
			switch timeLag>0 ? timeLag : -timeLag {
			case 0..<0.07:
				return .parfect
			case 0.07..<0.1:
				return .great
			case 0.1..<0.15:
				return .good
			case 0.15..<0.2:
				return .bad
			case 0.2..<0.25:
				return .miss
			default:
				if timeLag > 0{
					return .still
				}else{
					return .passed
				}
			}
		}
	}
	var nextNote:Note!
	var currentTime:TimeInterval!
	
}
