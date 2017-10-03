//
//  Sounds.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//
//（9/11の成果が残っている？）

import SpriteKit
import AVFoundation

extension GameScene{
	
	func setAllSounds(){
		BGM = setSound(fileName: bgmName, type: "mp3")
		tapSound1 = setSound(fileName: "タップ", type: "wav")
		tapSound2 = setSound(fileName: "タップ", type: "wav")
		
		flickSound1 = setSound(fileName: "フリック", type: "wav")
		flickSound2 = setSound(fileName: "フリック", type: "wav")
		
		kara1 = setSound(fileName: "空打ち", type: "wav")
		kara2 = setSound(fileName: "空打ち", type: "wav")
		
		BGM!.numberOfLoops = 0	//１度だけ再生
	}
	
	func setSound(fileName:String, type:String) -> AVAudioPlayer!{//効果音を設定する関数
		var sound:AVAudioPlayer!
		
		// サウンドファイルのパスを生成
		let Path = Bundle.main.path(forResource: fileName, ofType: type)!    //m4a,oggは不可
		let soundURL:URL = URL(fileURLWithPath: Path)
		// AVAudioPlayerのインスタンスを作成
		do {
			sound = try AVAudioPlayer(contentsOf: soundURL, fileTypeHint:nil)
		} catch {
			print("AVAudioPlayerインスタンス作成失敗")
		}
		// バッファに保持していつでも再生できるようにする
		sound.prepareToPlay()
		
		return sound
	}
	
	func playSound(type:SoundType){
		switch type {
		case .tap:
			if tapSound1?.isPlaying == false{
				tapSound1?.currentTime = 0
				tapSound1?.play()
				print("tap1")
			}else if tapSound2?.isPlaying == false{
				tapSound2?.currentTime = 0
				tapSound2?.play()
				print("tap2")
			}else{
				tapSoundResevation += 1
				print("tap予約")
			}
			
		case .flick:
			if flickSound1?.isPlaying == false{
				flickSound1?.play()
			}else if flickSound2?.isPlaying == false{
				flickSound2?.play()
			}else{
				flickSoundResevation += 1
			}
			
		case .kara:
			if kara1?.isPlaying == false{
				kara1?.play()
			}else if kara2?.isPlaying == false{
				kara2?.play()
			}else{
				karaSoundResevation += 1
			}
			
		}
	}
	
	enum SoundType{
		case tap,flick,kara
	}
	
}
