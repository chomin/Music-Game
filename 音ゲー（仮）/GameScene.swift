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
	
	//音楽プレイヤー（成功したんじゃね？?）
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
	
	
	//画像
	//	var noteImage:[SKShapeNode] = []  //notesとの対応は失われた→notesの中に
	var longImages:[SKShapeNode] = []
	var judgeLine:SKShapeNode!
	//	//確認用
	//	var triangle:SKShapeNode? = nil
	//	var line:SKShapeNode? = nil
	//	var circle:SKShapeNode? = nil
	//	var gcircle:SKShapeNode? = nil
	//	var long:SKShapeNode? = nil
	
	
	
	//ボタン
	let buttons = [ExpansionButton(),ExpansionButton(),ExpansionButton(),ExpansionButton(),ExpansionButton(),ExpansionButton(),ExpansionButton()]
	
	var notes:[Note] = []	//ノーツの" 始 点 "の集合。参照型！
	var start:TimeInterval!	  //シーン移動した時の時間
//	var BPM = 132.0
	var musicStartPos = 1.0	  //BGM開始の"拍"！
	var playLebel = 0
	// 楽曲データ
	var genre = ""				// ジャンル
	var title = ""				// タイトル
	var artist = ""				// アーティスト
	var bpm = 132.0				// Beats per Minute
	var playLevel = 0			// 難易度
	var volWav = 100			// 音量を現段階のn%として出力するか
//	var musicStartPos = 0.0		// 楽曲演奏を開始するタイミング(拍単位)
	
	
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
		catch {
			print("未知のエラー")
		}
		
		bpm *= 4.0	//拍を小節だと勘違いしてましたすみません
		

		
		//画像、音楽、ボタン、ラベルの設定
		setAllSounds()
		setButtons()
		setImages()
		
		//BGMの再生(時間指定)
		start = CACurrentMediaTime()
		BGM!.play(atTime: start + (musicStartPos/bpm)*240)
		
		
	}
	
	
	override func update(_ currentTime: TimeInterval) {

		//引き算ではなく、時間で位置を設定する(ノーツが多いと重くなるかも？)
		for i in notes{
			
			setYPos(note: i, currentTime: currentTime)

			var note:Note? = i
			while note?.next != nil{
				setYPos(note: (note?.next)!, currentTime: currentTime)
				
				note = note?.next
			}
		}
		
	
	}
}

//class Note{
//	var type:NoteType = .tap
//	var next:Note?   //ロングノーツの場合、次のノーツ
//	var pos:Double = 0.0  //何小節目か
//	var lane:Int = 0
//	
//	var image:SKShapeNode!	  //ノーツの画像
//}
//
//enum NoteType{
//	case tap,flick,middle,tapEnd,flickEnd
//}
