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
		tapSound3 = setSound(fileName: "タップ", type: "wav")
		tapSound4 = setSound(fileName: "タップ", type: "wav")
		flickSound1 = setSound(fileName: "フリック", type: "wav")
		flickSound2 = setSound(fileName: "フリック", type: "wav")
		flickSound3 = setSound(fileName: "フリック", type: "wav")
		flickSound4 = setSound(fileName: "フリック", type: "wav")

		kara1 = setSound(fileName: "空打ち", type: "wav")
		kara2 = setSound(fileName: "空打ち", type: "wav")
		kara3 = setSound(fileName: "空打ち", type: "wav")
		kara4 = setSound(fileName: "空打ち", type: "wav")
		
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
