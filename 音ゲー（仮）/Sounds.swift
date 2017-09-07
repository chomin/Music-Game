//
//  Sounds.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//

import SpriteKit
import AVFoundation

extension GameScene{
	
	func setAllSounds(){
		BGM = setSound(fileName: "シュガビタ", typeName: "mp3")
		tapSound1 = setSound(fileName: "タップ", typeName: "mp3")
		tapSound2 = setSound(fileName: "タップ", typeName: "mp3")
		flickSound1 = setSound(fileName: "フリック", typeName: "mp3")
		flickSound2 = setSound(fileName: "フリック", typeName: "mp3")
	}
	
	func setSound(fileName:String,typeName:String) -> AVAudioPlayer!{//効果音を設定する関数
		var sound:AVAudioPlayer!
		
		// サウンドファイルのパスを生成
		let Path = Bundle.main.path(forResource: fileName, ofType: typeName)!    //m4aは不可?
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

	
}
