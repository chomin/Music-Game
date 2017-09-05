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
	var noteImage:[SKSpriteNode] = []
	
	//ボタン
	let buttons = [UIButton(),UIButton(),UIButton(),UIButton(),UIButton(),UIButton(),UIButton()]
	
	static var notes:[Note] = []
	var start:TimeInterval!	  //シーン移動した時の時間
	let playSpeed = 10.0
	static var BPM = 0.0
	static var offset = 0.0	  //BGM開始の小節
	
	override func didMove(to view: SKView) {
		
		//notesにノーツを入れる(nobuの仕事)
		
		//画像、音楽、ボタン、ラベルの設定
		setAllSounds()
		
		//
		
		
		
	}
	
	
	override func update(_ currentTime: TimeInterval) {
		if start == nil{
			start = currentTime
		}
		
		
		
	}
}

class Note{
	var type:NoteType = .Tap
	var next:Note? = nil  //ロングノーツの場合、次のノーツ
	var pos:Double = 0.0  //何小節目か
	var lane:Int = 0
}

enum NoteType{
	case Tap,Flick,Start,Middle,TapEnd,FlickEnd
}
