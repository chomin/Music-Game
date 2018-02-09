//
//  Lane.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2018/01/04.
//  Copyright © 2018年 NakaiKohei. All rights reserved.
//

import SpriteKit

enum MiddleObsevationBool{
	case Front, Behind, False
}

class Lane{
	var nextNoteIndex = 0
	//	var currentTime:TimeInterval = 0.0
	var timeLag :TimeInterval = 0.0
	var laneNotes:[Note] = [] //最初に全部格納する！
	let laneIndex:Int!
	//	var isTouched = false
	var isObserved:MiddleObsevationBool {	//middleの判定圏内
		get{
			if laneNotes.count > 0 && nextNoteIndex < laneNotes.count{
				guard laneNotes[nextNoteIndex] is Middle else {
					return .False
				}
				
				switch timeLag {
				case 0..<0.07:
					return .Front
				case -0.07..<0:
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
			if laneNotes.count > 0 && nextNoteIndex < laneNotes.count{
				
				//				var timeLag = (laneNotes[nextNoteIndex].pos)*60/GameScene.bpm + GameScene.start - currentTime
				
				//建築予定地
//				var timeLag = GameScene.start - currentTime
//				for (index,i) in GameScene.variableBPMList.enumerated(){//timeLag計算
//					if GameScene.variableBPMList.count > index+1 && laneNotes[nextNoteIndex].beat > GameScene.variableBPMList[index+1].startPos{
//						timeLag += (GameScene.variableBPMList[index+1].startPos - i.startPos)*60/i.bpm
//					}else{
//						timeLag += (laneNotes[nextNoteIndex].beat - i.startPos)*60/i.bpm
//						break
//					}
//				}
				
				switch timeLag>0 ? timeLag : -timeLag {
				case 0..<0.05:
					return .parfect
				case 0.05..<0.06:
					return .great
				case 0.06..<0.065:
					return .good
				case 0.065..<0.07:
					return .bad
//				case 0.1..<0.125:
//					return .miss
				default:
					if timeLag > 0{
						return .still
					}else{
						return .passed
					}
				}
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
	
	func update(currentTime: TimeInterval){
		
		//timeLagの更新
		if laneNotes.count > 0 && nextNoteIndex < laneNotes.count{
			timeLag = GameScene.start - currentTime
			for (index,i) in GameScene.variableBPMList.enumerated(){
				if GameScene.variableBPMList.count > index+1 && laneNotes[nextNoteIndex].beat > GameScene.variableBPMList[index+1].startPos{
					timeLag += (GameScene.variableBPMList[index+1].startPos - i.startPos)*60/i.bpm
				}else{
					timeLag += (laneNotes[nextNoteIndex].beat - i.startPos)*60/i.bpm
					break
				}
			}
			
		}
	}
	
	
}
