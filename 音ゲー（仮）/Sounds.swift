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
        let buffer = alureCreateBufferFromFile(fullFilePath)

        if buffer == alNone {
            print("Failed to load \(fullFilePath)")
            return nil
        }
		
        var source: ALuint = 0
        alGenSources(1, &source)
		
        alSourcei(source, AL_BUFFER, ALint(buffer))
		
        self.buffer = buffer
        self.source = source
        self.fullFilePath = fullFilePath
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
}






extension GameScene{
	
	func setAllSounds(){
		GameScene.BGM = setSound(fileName: bgmName, type: "mp3")
		tapSound1 = setSound(fileName: "タップlow", type: "wav")
		tapSound2 = setSound(fileName: "タップlow", type: "wav")
		tapSound3 = setSound(fileName: "タップlow", type: "wav")
		tapSound4 = setSound(fileName: "タップlow", type: "wav")
		
		flickSound1 = setSound(fileName: "フリックlow", type: "wav")
		flickSound2 = setSound(fileName: "フリックlow", type: "wav")
		
		kara1 = setSound(fileName: "空打ち", type: "caf")
		
		kara2 = setSound(fileName: "空打ち", type: "caf")
		
		GameScene.BGM!.numberOfLoops = 0	//１度だけ再生
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
		case .tap:	//1ばかりが呼ばれているので、1,2,3,4と呼ばれるようにするとか？
			switch nextPlayTapNumber{
			case 1:
				if tapSound1?.isPlaying == false{
					tapSound1?.currentTime = 0
					if !(tapSound1?.play())!{
						print("tap1でfalse")
						tapSoundResevation += 1
					}else{
//						print("tap1")
						nextPlayTapNumber = 2
						break
						
					}
					
				}else{
					tapSoundResevation += 1
				}
				
			case 2:
				if tapSound2?.isPlaying == false{
					tapSound2?.currentTime = 0
					if !(tapSound2?.play())!{
						print("tap2でfalse")
						tapSoundResevation += 1
					}else{
//						print("tap2")
						nextPlayTapNumber = 3
						break
						
					}
					
				}else{
					tapSoundResevation += 1
				}
				
			case 3:
				if tapSound3?.isPlaying == false{
					tapSound3?.currentTime = 0
					if !(tapSound3?.play())!{
						print("tap3でfalse")
						tapSoundResevation += 1
					}else{
//						print("tap3")
						nextPlayTapNumber = 4
						break
						
					}
					
				}else{
					tapSoundResevation += 1
				}
				
			case 4:
				if tapSound4?.isPlaying == false{
					tapSound4?.currentTime = 0
					if !(tapSound4?.play())!{
						print("tap4でfalse")
						tapSoundResevation += 1
					}else{
//						print("tap4")
						nextPlayTapNumber = 1
						break
						
					}
					
				}else{
					tapSoundResevation += 1
				}
				
			default:
				print("タップ音を鳴らせませんでした")
			}
			
			
//			if tapSound1?.isPlaying == false{
//				tapSound1?.currentTime = 0
//				if !(tapSound1?.play())!{
//					print("tap1でfalse")
//					tapSoundResevation += 1
//				}else{
//					print("tap1")
//				}
//
//			}else if tapSound2?.isPlaying == false{
//				tapSound2?.currentTime = 0
//				if !(tapSound2?.play())!{
//					print("tap2でfalse")
//					tapSoundResevation += 1
//				}else{
//					print("tap2")
//				}
//			}else if tapSound3?.isPlaying == false{
//				tapSound3?.currentTime = 0
//				if !(tapSound3?.play())!{
//					print("tap3でfalse")
//					tapSoundResevation += 1
//				}else{
//					print("tap3")
//				}
//			}else if tapSound4?.isPlaying == false{
//				tapSound4?.currentTime = 0
//				if !(tapSound4?.play())!{
//					print("tap4でfalse")
//					tapSoundResevation += 1
//				}else{
//					print("tap4")
//				}
//			}else{
//				tapSoundResevation += 1
//				print("tap予約")
//			}
			
		case .flick:
			if flickSound1?.isPlaying == false{
				if !(flickSound1?.play())!{
					flickSoundResevation += 1
				}

			}else if flickSound2?.isPlaying == false{
				if !(flickSound2?.play())!{
					flickSoundResevation += 1
				}
			}else{
				flickSoundResevation += 1
			}
			
		case .kara:
			if kara1?.isPlaying == false{
				if !(kara1?.play())!{
					karaSoundResevation += 1
				}
			}else if kara2?.isPlaying == false{
				if !(kara2?.play())!{
					karaSoundResevation += 1
				}
			}else{
				karaSoundResevation += 1
			}
			
		}
	}
	
	enum SoundType{
		case tap,flick,kara
	}
	
}
