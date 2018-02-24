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
	private let middle1:   SoundSource
	private let middle2:   SoundSource
	private let middle3:   SoundSource
	private let middle4:   SoundSource
	

	private let kara1: SoundSource
	private let kara2: SoundSource
	

	enum SoundType{
		case tap, flick, kara, middle
	}
	
	init() {

		alureInitDevice(nil, nil)
		
		// サウンドファイルのパスを生成
		let tapSoundPath    = Bundle.main.path(forResource: "Sounds/タップ",   ofType: "wav")!   // mp3,m4a,ogg は不可
		let flickSoundPath  = Bundle.main.path(forResource: "Sounds/フリック", ofType: "wav")!
		let middleSoundPath = Bundle.main.path(forResource: "Sounds/フリック", ofType: "wav")!	//TODO:いい素材を見つける
		let karaSoundPath   = Bundle.main.path(forResource: "Sounds/空打ち",   ofType: "wav")!
		
		tap1    = SoundSource(fullFilePath: tapSoundPath)    ?? SoundSource()
		tap2    = SoundSource(fullFilePath: tapSoundPath)    ?? SoundSource()
		tap3    = SoundSource(fullFilePath: tapSoundPath)    ?? SoundSource()
		tap4    = SoundSource(fullFilePath: tapSoundPath)    ?? SoundSource()
		flick1  = SoundSource(fullFilePath: flickSoundPath)  ?? SoundSource()
		flick2  = SoundSource(fullFilePath: flickSoundPath)  ?? SoundSource()
		flick3  = SoundSource(fullFilePath: flickSoundPath)  ?? SoundSource()
		flick4  = SoundSource(fullFilePath: flickSoundPath)  ?? SoundSource()
		middle1 = SoundSource(fullFilePath: middleSoundPath) ?? SoundSource()
		middle2 = SoundSource(fullFilePath: middleSoundPath) ?? SoundSource()
		middle3 = SoundSource(fullFilePath: middleSoundPath) ?? SoundSource()
		middle4 = SoundSource(fullFilePath: middleSoundPath) ?? SoundSource()
		kara1   = SoundSource(fullFilePath: karaSoundPath)   ?? SoundSource()
		kara2   = SoundSource(fullFilePath: karaSoundPath)   ?? SoundSource()
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
		case .middle:
			if      !middle1.isPlaying { middle1.play() }
			else if !middle2.isPlaying { middle2.play() }
			else if !middle3.isPlaying { middle3.play() }
			else if !middle4.isPlaying { middle4.play() }
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
		middle1.setVolume(value)
		middle2.setVolume(value)
		middle3.setVolume(value)
		middle4.setVolume(value)
		kara1.setVolume(value)
		kara2.setVolume(value)
	}
	
	func stopAll() {
		tap1.stop()
		tap2.stop()
		tap3.stop()
		tap4.stop()
		flick1.stop()
		flick2.stop()
		flick3.stop()
		flick4.stop()
		middle1.stop()
		middle2.stop()
		middle3.stop()
		middle4.stop()
		kara1.stop()
		kara2.stop()
	}
}
