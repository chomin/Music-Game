//
//  SoundSource.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/11/12.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//

import Foundation
import OpenAL

final class SoundSource {//AVAudioPlayerの代わり？
	private var buffer: ALuint
	private var source: ALuint
	private let fullFilePath: String
	
	init?(fullFilePath: String) {
		let buffer = alureCreateBufferFromFile(fullFilePath)
		
		if buffer == AL_NONE {
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
		alureStopSource(source, ALboolean(AL_TRUE))
		alDeleteSources(1, &source)
		alDeleteBuffers(1, &buffer)
	}
	
	// MARK: - SoundPlayer
	
	func play() {
		if alurePlaySource(source, nil, nil) != AL_TRUE {
			print("Failed to play source \(self.fullFilePath)")
		}
	}
	
	func stop() {
		if alureStopSource(source, ALboolean(AL_FALSE)) != AL_TRUE {
			print("Failed to stop source \(self.fullFilePath)")
		}
	}
	
	func pause() {
		if alurePauseSource(source) != AL_TRUE {
			print("Failed to pause source \(self.fullFilePath)")
		}
	}
	
	func setOffset(second: Float) {
		alSourcef(source, AL_SEC_OFFSET, second)
	}
	
	func setShouldLooping(_ shouldLoop: Bool) {
		alSourcei(source, AL_LOOPING, shouldLoop ? 1 : 0)
	}
	
	func setVolume(_ value: Float) {
		alSourcef(source, AL_GAIN, value)
	}
}
