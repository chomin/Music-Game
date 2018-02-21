//
//  Buttons.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//

import SpriteKit

extension GameScene{
	
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		print("cancelされました")
	}

	override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {
		print("touchesEstimatedPropertiesUpdated")
	}

	
	enum NoteType {
	    case tap, flick, tapStart, middle, tapEnd, flickEnd
	}
	
	
	func judge(laneIndex:Int, timeLag:TimeInterval) -> Bool{	  //対象ノーツが実在し、判定したかを返す.timeLagは（judge呼び出し時ではなく）タッチされた時のものを使用。

		let nextIndex = lanes[laneIndex].nextNoteIndex
		let judgeNote = lanes[laneIndex].laneNotes[nextIndex]

		guard judgeNote.isJudgeable else {
			return false
		}
		
		guard nextIndex < lanes[laneIndex].laneNotes.count else {//最後まで判定が終わってる
			return false
		}

		
		
		
		
		
		switch lanes[laneIndex].getTimeState(timeLag: timeLag) {
		case .parfect:
			setJudgeLabelText(text: "parfect!!")
			ResultScene.parfect += 1
			ResultScene.combo += 1
			if ResultScene.combo > ResultScene.maxCombo{
				ResultScene.maxCombo += 1
			}
			self.removeChildren(in: [judgeNote.image])
			judgeNote.isJudged = true
			setNextIsJudgeable(judgeNote: judgeNote)
			lanes[laneIndex].nextNoteIndex += 1
			return true
		case .great:
			setJudgeLabelText(text: "great!")
			ResultScene.great += 1
			ResultScene.combo += 1
			if ResultScene.combo > ResultScene.maxCombo{
				ResultScene.maxCombo += 1
			}
			self.removeChildren(in: [judgeNote.image])
			judgeNote.isJudged = true
			setNextIsJudgeable(judgeNote: judgeNote)
			lanes[laneIndex].nextNoteIndex += 1
			return true
		case .good:
			setJudgeLabelText(text: "good")
			ResultScene.good += 1
			ResultScene.combo = 0
			self.removeChildren(in: [judgeNote.image])
			judgeNote.isJudged = true
			setNextIsJudgeable(judgeNote: judgeNote)
			lanes[laneIndex].nextNoteIndex += 1
			return true
		case .bad:
			setJudgeLabelText(text: "bad")
			ResultScene.bad += 1
			ResultScene.combo = 0
			self.removeChildren(in: [judgeNote.image])
			judgeNote.isJudged = true
			setNextIsJudgeable(judgeNote: judgeNote)
			lanes[laneIndex].nextNoteIndex += 1
			return true
		case .miss:
			setJudgeLabelText(text: "miss!")
			ResultScene.miss += 1
			ResultScene.combo = 0
			self.removeChildren(in: [judgeNote.image])
			judgeNote.isJudged = true
			setNextIsJudgeable(judgeNote: judgeNote)
			lanes[laneIndex].nextNoteIndex += 1
			return true
		default:
			return false
		
		}


	}
	
	func parfectMiddleJudge(laneIndex:Int, currentTime: TimeInterval) -> Bool{	  //対象ノーツが実在し、判定したかを返す(middleのparfect専用)
		
		let nextIndex = lanes[laneIndex].nextNoteIndex
		
		if nextIndex >= lanes[laneIndex].laneNotes.count{//最後まで判定が終わってる
			return false
		}else if !(lanes[laneIndex].laneNotes[nextIndex] is Middle){//種類が違う
			return false
		}
		
		lanes[laneIndex].update(passedTime: currentTime - startTime, BPMs)
		switch lanes[laneIndex].timeState {
		case .parfect:	//タップ直後とかでも入ってしまう？（updateとtouchesシリーズは並列処理されている？）
			setJudgeLabelText(text: "parfect!!")
			ResultScene.parfect += 1
			ResultScene.combo += 1
			if ResultScene.combo > ResultScene.maxCombo{
				ResultScene.maxCombo += 1
			}
			self.removeChildren(in: [lanes[laneIndex].laneNotes[nextIndex].image])
			lanes[laneIndex].laneNotes[nextIndex].isJudged = true
			setNextIsJudgeable(judgeNote: lanes[laneIndex].laneNotes[nextIndex])
			lanes[laneIndex].nextNoteIndex += 1
			return true
		default: break
		}
		
		return false
		
	}
	
	func setNextIsJudgeable(judgeNote:Note)  {
		if judgeNote is TapStart {
			let note = judgeNote as! TapStart
			note.next.isJudgeable = true
		}else if judgeNote is Middle {
			let note = judgeNote as! Middle
			note.next.isJudgeable = true
		}
	}
}
