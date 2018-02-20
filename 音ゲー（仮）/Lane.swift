//
//  Lane.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2018/01/04.
//  Copyright © 2018年 NakaiKohei. All rights reserved.
//

import SpriteKit

enum TimeState {
	case miss,bad,good,great,parfect,still,passed
}

enum MiddleObsevationBool{
	case Front, Behind, False
}

class Lane{
	var nextNoteIndex = 0
	//	var currentTime:TimeInterval = 0.0
	var timeLag :TimeInterval = 0.0
	var isTimeLagRenewed = false
	var laneNotes:[Note] = [] //最初に全部格納する！
	var isSetLaneNotes = false
	let laneIndex:Int!
	//	var isTouched = false
	
	var isJudgeRange:Bool{
		get{
			guard isTimeLagRenewed else {
				return false
			}
			switch self.getTimeState(timeLag: timeLag) {
			case .parfect, .great, .good, .bad, .miss:
				return true
			default:
				return false
			}
			
		}
	}
	var isObserved:MiddleObsevationBool {	//middleの判定圏内
		get{
			if self.isTimeLagRenewed{
				guard nextNoteIndex < laneNotes.count else{
					return .False
				}
				
				guard laneNotes[nextNoteIndex] is Middle else {
					return .False
				}
				
				switch timeLag {
				case 0..<0.1:
					return .Front
				case -0.1..<0:
					return .Behind
				default:
					return .False
				}
				
			}else{
					return .False
			}
		}
	}
	
	
	var timeState:TimeState{
		get{
			if self.isTimeLagRenewed{
				
				return self.getTimeState(timeLag: timeLag)
				
			}else{
				return .still
			}
		}
	}
	
	
	
	init(laneIndex: Int){
		self.laneIndex = laneIndex
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func update(_ currentTime: TimeInterval, _ BPMs: [(bpm: Double, startPos: Double)]){
		
		//timeLagの更新
		if isSetLaneNotes{
			if laneNotes.count > 0 && nextNoteIndex < laneNotes.count{
				
				timeLag = GameScene.start - currentTime
				for (index,i) in BPMs.enumerated(){
					if BPMs.count > index+1 && laneNotes[nextNoteIndex].beat > BPMs[index+1].startPos{
						timeLag += (BPMs[index+1].startPos - i.startPos)*60/i.bpm
					}else{
						timeLag += (laneNotes[nextNoteIndex].beat - i.startPos)*60/i.bpm
						break
					}
				}
				
				self.isTimeLagRenewed = true	//パース前はtimeLagは更新されないので通知する必要あり
				
			}else{//このレーンが使われない場合
				
				self.isTimeLagRenewed = true
				
			}
		}
	}
	
	func getTimeState(timeLag:TimeInterval) -> TimeState{
		guard self.isTimeLagRenewed else {
			print("timeLagが不正です")
			return .still
		}
		
		switch abs(timeLag){
		case 0..<0.05:
			return .parfect
		case 0.05..<0.08:
			return .great
		case 0.08..<0.085:
			return .good
		case 0.085..<0.09:
			return .bad
		case 0.09..<0.1:
			return .miss
		default:
			if timeLag > 0{
				return .still
			}else{
				return .passed
			}
		}
	}
	
	
}
