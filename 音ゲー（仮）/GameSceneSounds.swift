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
				tapSound1?.play()
				lastPlayingTapSound = .tap1
			}else if tapSound2?.isPlaying == false{
				tapSound2?.play()
				lastPlayingTapSound = .tap2
			}else if lastPlayingTapSound == .tap1{
				tapSound2?.currentTime = 0
				tapSound2?.play()
				lastPlayingTapSound = .tap2
				
			}else if lastPlayingTapSound == .tap2{
				tapSound1?.currentTime = 0
				tapSound1?.play()
				lastPlayingTapSound = .tap1
			}
			
		case .flick:
			if flickSound1?.isPlaying == false{
				flickSound1?.play()
				lastPlayingFlickSound = .flick1
			}else if flickSound2?.isPlaying == false{
				flickSound2?.play()
				lastPlayingFlickSound = .flick2
			}else if lastPlayingFlickSound == .flick1{
				flickSound2?.currentTime = 0
				flickSound2?.play()
				lastPlayingFlickSound = .flick2
				
			}else if lastPlayingFlickSound == .flick2{
				flickSound1?.currentTime = 0
				flickSound1?.play()
				lastPlayingFlickSound = .flick1
			}
			
		case .kara:
			if kara1?.isPlaying == false{
				kara1?.play()
				lastPlayingKaraSound = .kara1
			}else if kara2?.isPlaying == false{
				kara2?.play()
				lastPlayingKaraSound = .kara2
			}else if lastPlayingKaraSound == .kara1{
				kara2?.currentTime = 0
				kara2?.play()
				lastPlayingKaraSound = .kara2
				
			}else if lastPlayingKaraSound == .kara2{
				kara1?.currentTime = 0
				kara1?.play()
				lastPlayingKaraSound = .kara1
			}
			
		}
	}
	
	enum SoundType{
		case tap,flick,kara
	}
	
}
