//
//  Sounds.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//
//（9/11の成果が残っている？）

import SpriteKit
import AVFoundation
import OpenAL

fileprivate let alTrue: ALboolean = Int8(AL_TRUE)
fileprivate let alFalse: ALboolean = Int8(AL_FALSE)
fileprivate let alNone: ALuint = ALuint(AL_NONE)

final class SoundSource {
    private var buffer: ALuint
    private var source: ALuint
    private let fullFilePath: String
	
    init?(fullFilePath: String) {
		// 音声ファイルからバッファを作成
        let buffer = alureCreateBufferFromFile(fullFilePath)
        if buffer == alNone {
            print("alureCreateBufferFromFile error. Failed to load \(fullFilePath)")
            return nil
        }
		
        var source: ALuint = 0
		
		alGetError()
		// ソースオブジェクトを作成
        alGenSources(1, &source)
		// エラー処理
		var error = alGetError()
		if error != AL_NO_ERROR {
			let er = String(error, radix: 16)	// 16進数に変換

			print("error:\(er)")
			return nil
		}

		// バッファをソースに紐付け
        alSourcei(source, AL_BUFFER, ALint(buffer))
		// エラー処理
		error = alGetError()
		if error != AL_NO_ERROR {
			let er = String(error, radix: 16)	// 16進数に変換
			
			print("error:\(er)")
			return nil
		}

        self.buffer = buffer
        self.source = source
        self.fullFilePath = fullFilePath
    }
	init() {
		self.buffer = 0
		self.source = 0
		self.fullFilePath = ""
	}
	
    deinit {
        alureStopSource(source, alTrue)
        alDeleteSources(1, &source)
        alDeleteBuffers(1, &buffer)
    }
	
    func play() {
        if alurePlaySource(source, nil, nil) != alTrue {
            print("Failed to play source \(self.fullFilePath)")
        }
    }
	
    func stop() {
        if alureStopSource(source, alFalse) != alTrue {
            print("Failed to stop source \(self.fullFilePath)")
        }
    }
	
    func pause() {
        if alurePauseSource(source) != alTrue {
            print("Failed to pause source \(self.fullFilePath)")
        }
    }
	
    func setOffset(second: Float) {
        alSourcef(source, AL_SEC_OFFSET, second)
    }
	
    func setVolume(_ value: Float) {
        alSourcef(source, AL_GAIN, value)
    }
	
	var isPlaying: Bool {
		get {
			var state: ALint = 0
			
			alGetSourcei(source, AL_SOURCE_STATE, &state)
			return state == AL_PLAYING || state == AL_PAUSED
		}
	}
}

class ActionSoundPlayers {
	private let tap1:   SoundSource
	private let tap2:   SoundSource
	private let tap3:   SoundSource
	private let tap4:   SoundSource
	private let flick1: SoundSource
	private let flick2: SoundSource
	private let flick3: SoundSource
	private let flick4: SoundSource

	private let kara1: SoundSource
	private let kara2: SoundSource
	

	enum SoundType{
		case tap, flick, kara
	}
	
	init() {

		alureInitDevice(nil, nil)
		
		// サウンドファイルのパスを生成
		let tapSoundPath = Bundle.main.path(forResource: "Sounds/タップ", ofType: "wav")!    // mp3,m4a,ogg は不可
		let flickSoundPath = Bundle.main.path(forResource: "Sounds/フリック", ofType: "wav")!
		let karaSoundPath = Bundle.main.path(forResource: "Sounds/空打ち", ofType: "wav")!
		
		tap1   = SoundSource(fullFilePath: tapSoundPath)   ?? SoundSource()
		tap2   = SoundSource(fullFilePath: tapSoundPath)   ?? SoundSource()
		tap3   = SoundSource(fullFilePath: tapSoundPath)   ?? SoundSource()
		tap4   = SoundSource(fullFilePath: tapSoundPath)   ?? SoundSource()
		flick1 = SoundSource(fullFilePath: flickSoundPath) ?? SoundSource()
		flick2 = SoundSource(fullFilePath: flickSoundPath) ?? SoundSource()
		flick3 = SoundSource(fullFilePath: flickSoundPath) ?? SoundSource()
		flick4 = SoundSource(fullFilePath: flickSoundPath) ?? SoundSource()
		kara1  = SoundSource(fullFilePath: karaSoundPath)  ?? SoundSource()
		kara2  = SoundSource(fullFilePath: karaSoundPath)  ?? SoundSource()
	}
	
	func play(type: SoundType) {
		switch type {
		case .tap:
			if      !tap1.isPlaying { tap1.play() }
			else if !tap2.isPlaying { tap2.play() }
			else if !tap3.isPlaying { tap3.play() }
			else if !tap4.isPlaying { tap4.play() }
		case .flick:
			if      !flick1.isPlaying { flick1.play() }
			else if !flick2.isPlaying { flick2.play() }
			else if !flick3.isPlaying { flick3.play() }
			else if !flick4.isPlaying { flick4.play() }
		case .kara:
			if      !kara1.isPlaying { kara1.play() }
			else if !kara2.isPlaying { kara2.play() }
		}
	}
	
	func setVolume(_ value: Float) {
		tap1.setVolume(value)
		tap2.setVolume(value)
		tap3.setVolume(value)
		tap4.setVolume(value)
		flick1.setVolume(value)
		flick2.setVolume(value)
		flick3.setVolume(value)
		flick4.setVolume(value)
		kara1.setVolume(value)
		kara2.setVolume(value)
	}
}


extension GameScene{
	
//	func setAllSounds(){
//		GameScene.BGM = setSound(fileName: bgmName, type: "mp3")
//		tapSound1 = setSound(fileName: "タップlow", type: "wav")
//		tapSound2 = setSound(fileName: "タップlow", type: "wav")
//		tapSound3 = setSound(fileName: "タップlow", type: "wav")
//		tapSound4 = setSound(fileName: "タップlow", type: "wav")
//
//		flickSound1 = setSound(fileName: "フリックlow", type: "wav")
//		flickSound2 = setSound(fileName: "フリックlow", type: "wav")
//
//		kara1 = setSound(fileName: "空打ち", type: "caf")
//
//		kara2 = setSound(fileName: "空打ち", type: "caf")
//
//		GameScene.BGM!.numberOfLoops = 0	//１度だけ再生
//	}
//
//	func setSound(fileName:String, type:String) -> AVAudioPlayer!{//効果音を設定する関数
//		var sound:AVAudioPlayer!
//
//		// サウンドファイルのパスを生成
//		let Path = Bundle.main.path(forResource: fileName, ofType: type)!    //m4a,oggは不可
//		let soundURL:URL = URL(fileURLWithPath: Path)
//		// AVAudioPlayerのインスタンスを作成
//		do {
//			sound = try AVAudioPlayer(contentsOf: soundURL, fileTypeHint:nil)
//		} catch {
//			print("AVAudioPlayerインスタンス作成失敗")
//		}
//		// バッファに保持していつでも再生できるようにする
//		sound.prepareToPlay()
//
//		return sound
//	}
//
//

//	func playSound(type:SoundType){
//		switch type {
//		case .tap:	//1ばかりが呼ばれているので、1,2,3,4と呼ばれるようにするとか？
//			switch nextPlayTapNumber{
//			case 1:
//				if tapSound1?.isPlaying == false{
//					tapSound1?.currentTime = 0
//					if !(tapSound1?.play())!{
//						print("tap1でfalse")
//						tapSoundResevation += 1
//					}else{
////						print("tap1")
//						nextPlayTapNumber = 2
//						break
//
//					}
//
//				}else{
//					tapSoundResevation += 1
//				}
//
//			case 2:
//				if tapSound2?.isPlaying == false{
//					tapSound2?.currentTime = 0
//					if !(tapSound2?.play())!{
//						print("tap2でfalse")
//						tapSoundResevation += 1
//					}else{
////						print("tap2")
//						nextPlayTapNumber = 3
//						break
//
//					}
//
//				}else{
//					tapSoundResevation += 1
//				}
//
//			case 3:
//				if tapSound3?.isPlaying == false{
//					tapSound3?.currentTime = 0
//					if !(tapSound3?.play())!{
//						print("tap3でfalse")
//						tapSoundResevation += 1
//					}else{
////						print("tap3")
//						nextPlayTapNumber = 4
//						break
//
//					}
//
//				}else{
//					tapSoundResevation += 1
//				}
//
//			case 4:
//				if tapSound4?.isPlaying == false{
//					tapSound4?.currentTime = 0
//					if !(tapSound4?.play())!{
//						print("tap4でfalse")
//						tapSoundResevation += 1
//					}else{
////						print("tap4")
//						nextPlayTapNumber = 1
//						break
//
//					}
//
//				}else{
//					tapSoundResevation += 1
//				}
//
//			default:
//				print("タップ音を鳴らせませんでした")
//			}
//
//
////			if tapSound1?.isPlaying == false{
////				tapSound1?.currentTime = 0
////				if !(tapSound1?.play())!{
////					print("tap1でfalse")
////					tapSoundResevation += 1
////				}else{
////					print("tap1")
////				}
////
////			}else if tapSound2?.isPlaying == false{
////				tapSound2?.currentTime = 0
////				if !(tapSound2?.play())!{
////					print("tap2でfalse")
////					tapSoundResevation += 1
////				}else{
////					print("tap2")
////				}
////			}else if tapSound3?.isPlaying == false{
////				tapSound3?.currentTime = 0
////				if !(tapSound3?.play())!{
////					print("tap3でfalse")
////					tapSoundResevation += 1
////				}else{
////					print("tap3")
////				}
////			}else if tapSound4?.isPlaying == false{
////				tapSound4?.currentTime = 0
////				if !(tapSound4?.play())!{
////					print("tap4でfalse")
////					tapSoundResevation += 1
////				}else{
////					print("tap4")
////				}
////			}else{
////				tapSoundResevation += 1
////				print("tap予約")
////			}
//
//		case .flick:
//			if flickSound1?.isPlaying == false{
//				if !(flickSound1?.play())!{
//					flickSoundResevation += 1
//				}
//
//			}else if flickSound2?.isPlaying == false{
//				if !(flickSound2?.play())!{
//					flickSoundResevation += 1
//				}
//			}else{
//				flickSoundResevation += 1
//			}
//
//		case .kara:
//			if kara1?.isPlaying == false{
//				if !(kara1?.play())!{
//					karaSoundResevation += 1
//				}
//			}else if kara2?.isPlaying == false{
//				if !(kara2?.play())!{
//					karaSoundResevation += 1
//				}
//			}else{
//				karaSoundResevation += 1
//			}
//
//		}
//	}
//
//	enum SoundType{
//		case tap,flick,kara
//	}
//
}
