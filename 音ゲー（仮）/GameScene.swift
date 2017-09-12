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
	let buttons = [UIButton(),UIButton(),UIButton(),UIButton(),UIButton(),UIButton(),UIButton()]
	
	var notes:[Note] = []	//ノーツの" 始 点 "の集合。参照型！
	var start:TimeInterval!	  //シーン移動した時の時間
	var BPM = 132.0
	var musicStartPos = 1.0	  //BGM開始の小節
	var ganre = ""
	var title = ""
	var artist = ""
	var playLebel = 0
	
	
	override func didMove(to view: SKView) {
		
		//スピードの設定
		speed = 500.0
		
		//notesにノーツの"　始　点　"を入れる(nobuの仕事)
		parse(fineName: "シュガーソングとビターステップ")
		
		//確認用
		let anote=Note()
		let bnote=Note()
		let cnote=Note()
		let dnote=Note()
		
		anote.lane=2
		anote.next=bnote
		anote.pos=4
		anote.type = .Tap
		notes.append(anote)
		
		
		bnote.lane=2
		bnote.next=cnote
		bnote.pos=4.25
		bnote.type = .Middle
//		GameScene.notes.append(bnote)
		
		cnote.lane=1
		cnote.next=nil
		cnote.pos=4.5
		cnote.type = .FlickEnd
//		GameScene.notes.append(cnote)
		
		dnote.lane=6
		dnote.next=nil
		dnote.pos=4.125
		dnote.type = .Tap
		notes.append(dnote)
		
		//画像、音楽、ボタン、ラベルの設定
		setAllSounds()
		setButtons()
		setImages()
		
		//BGMの再生(時間指定)
		start = CACurrentMediaTime()
		BGM!.play(atTime: start + musicStartPos/BPM/240)
		
		
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

class Note{
	var type:NoteType = .Tap
	var next:Note?   //ロングノーツの場合、次のノーツ
	var pos:Double = 0.0  //何小節目か
	var lane:Int = 0
	
	var image:SKShapeNode!	  //ノーツの画像
}

enum NoteType{
	case Tap,Flick,Middle,TapEnd,FlickEnd
}
