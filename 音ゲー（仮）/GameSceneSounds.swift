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
		BGM = setSound(fileName: bgmName)
		tapSound1 = setSound(fileName: "タップ")
		tapSound2 = setSound(fileName: "タップ")
		tapSound3 = setSound(fileName: "タップ")
		tapSound4 = setSound(fileName: "タップ")
		flickSound1 = setSound(fileName: "フリック")
		flickSound2 = setSound(fileName: "フリック")
		flickSound3 = setSound(fileName: "フリック")
		flickSound4 = setSound(fileName: "フリック")

		kara1 = setSound(fileName: "空打ち")
		kara2 = setSound(fileName: "空打ち")
		kara3 = setSound(fileName: "空打ち")
		kara4 = setSound(fileName: "空打ち")
		
		BGM!.numberOfLoops = 0	//１度だけ再生
	}
	
	func setSound(fileName:String) -> AVAudioPlayer!{//効果音を設定する関数
		var sound:AVAudioPlayer!
		
		// サウンドファイルのパスを生成
		let Path = Bundle.main.path(forResource: fileName, ofType: "mp3")!    //m4a,oggは不可
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
			}else if tapSound2?.isPlaying == false{
				tapSound2?.play()
			}else if tapSound3?.isPlaying == false{
				tapSound3?.play()
			}else if tapSound4?.isPlaying == false{
				tapSound4?.play()
			}
			
		case .flick:
			if flickSound1?.isPlaying == false{
				flickSound1?.play()
			}else if flickSound2?.isPlaying == false{
				flickSound2?.play()
			}else if flickSound3?.isPlaying == false{
				flickSound3?.play()
			}else if flickSound4?.isPlaying == false{
				flickSound4?.play()
			}
			
		case .kara:
			if kara1?.isPlaying == false{
				kara1?.play()
			}else if kara2?.isPlaying == false{
				kara2?.play()
			}else if kara3?.isPlaying == false{
				kara3?.play()
			}else if kara4?.isPlaying == false{
				kara4?.play()
			}

		}
	}
	
	enum SoundType{
		case tap,flick,kara
	}
	
}
