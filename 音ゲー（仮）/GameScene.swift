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
	
	
	//画像
	var noteImage:[SKShapeNode] = []
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
	
	static var notes:[Note] = []
	var start:TimeInterval!	  //シーン移動した時の時間
	static var BPM = 132.0
	static var offset = 1.0	  //BGM開始の小節
	
	override func didMove(to view: SKView) {
		
		//スピードの設定
		speed = 500.0
		
		//notesにノーツを入れる(nobuの仕事)
		
		//確認用
		let anote=Note()
		let bnote=Note()
		let cnote=Note()
		let dnote=Note()
		
		anote.lane=2
		anote.next=bnote
		anote.pos=4
		anote.type = .Tap
		GameScene.notes.append(anote)
		
		
		bnote.lane=2
		bnote.next=cnote
		bnote.pos=4.25
		bnote.type = .Middle
		GameScene.notes.append(bnote)
		
		cnote.lane=1
		cnote.next=nil
		cnote.pos=4.5
		cnote.type = .FlickEnd
		GameScene.notes.append(cnote)
		
		dnote.lane=6
		dnote.next=nil
		dnote.pos=4.125
		dnote.type = .Tap
		GameScene.notes.append(dnote)
		
		//画像、音楽、ボタン、ラベルの設定
		setAllSounds()
		setButtons()
		setImages()
		
		//BGMの再生(時間指定)
		start = CACurrentMediaTime()
		BGM!.play(atTime: start + GameScene.offset/GameScene.BPM/240)
		
		
	}
	
	
	override func update(_ currentTime: TimeInterval) {

		//引き算ではなく、時間で位置を設定する
		for (index,value) in noteImage.enumerated(){
			var ypos =  self.frame.width/9
			ypos += (CGFloat(240*GameScene.notes[index].pos/GameScene.BPM)-CGFloat(currentTime - start))*CGFloat(speed)
			value.position.y = ypos
		}
		
		//確認用
//		triangle?.position.y = self.frame.width/9
//		circle?.position.y = self.frame.width/9
//		gcircle?.position.y = self.frame.width/9
//		line?.position.y = self.frame.width/9

		
		
	}
}

class Note{
	var type:NoteType = .Tap
	var next:Note? = nil  //ロングノーツの場合、次のノーツ
	var pos:Double = 0.0  //何小節目か
	var lane:Int = 0
}

enum NoteType{
	case Tap,Flick,Middle,TapEnd,FlickEnd
}
