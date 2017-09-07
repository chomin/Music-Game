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
	static var BPM = 0.0
	static var offset = 0.0	  //BGM開始の小節
	
	override func didMove(to view: SKView) {
		
		//スピードの設定(設定より前)
		speed = 5.0
		
		//notesにノーツを入れる(nobuの仕事)
		
		//画像、音楽、ボタン、ラベルの設定
		setAllSounds()
		setButtons()
		setImages()
		
		
		
		
	}
	
	
	override func update(_ currentTime: TimeInterval) {
		if start == nil{
			start = currentTime
		}
		
		//引き算ではなく、時間で位置を設定する
		for (index,value) in noteImage.enumerated(){
			var ypos =  self.frame.width/9
			ypos += (CGFloat(GameScene.BPM*15*GameScene.notes[index].pos)-CGFloat(currentTime))*CGFloat(speed)
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
