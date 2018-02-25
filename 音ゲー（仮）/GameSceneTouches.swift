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
	
	
	
	
	func judge(lane:Lane, timeLag:TimeInterval) -> Bool{	  //対象ノーツが実在し、判定したかを返す.timeLagは（judge呼び出し時ではなく）タッチされた時のものを使用。
		
		
		guard lane.laneNotes.count > 0 else {
			return false
		}
		
		let judgeNote = lane.laneNotes[0]

		guard judgeNote.isJudgeable else {
			return false
		}
		
	
		switch lane.getTimeState(timeLag: timeLag) {
		case .parfect:
			setJudgeLabelText(text: "parfect!!")
			ResultScene.parfect += 1
			ResultScene.combo += 1
			if ResultScene.combo > ResultScene.maxCombo{
				ResultScene.maxCombo += 1
			}
			judgeNote.isJudged = true
			setNextIsJudgeable(judgeNote: judgeNote)
			releaseNote(lane: lane)
			return true
		case .great:
			setJudgeLabelText(text: "great!")
			ResultScene.great += 1
			ResultScene.combo += 1
			if ResultScene.combo > ResultScene.maxCombo{
				ResultScene.maxCombo += 1
			}
			judgeNote.isJudged = true
			setNextIsJudgeable(judgeNote: judgeNote)
			releaseNote(lane: lane)
			return true
		case .good:
			setJudgeLabelText(text: "good")
			ResultScene.good += 1
			ResultScene.combo = 0
			judgeNote.isJudged = true
			setNextIsJudgeable(judgeNote: judgeNote)
			releaseNote(lane: lane)
			return true
		case .bad:
			setJudgeLabelText(text: "bad")
			ResultScene.bad += 1
			ResultScene.combo = 0
			judgeNote.isJudged = true
			setNextIsJudgeable(judgeNote: judgeNote)
			releaseNote(lane: lane)
			return true
		case .miss:
			setJudgeLabelText(text: "miss!")
			ResultScene.miss += 1
			ResultScene.combo = 0
			judgeNote.isJudged = true
			setNextIsJudgeable(judgeNote: judgeNote)
			releaseNote(lane: lane)
			return true
		default:
			return false
		
		}

		
	}
	
	func parfectMiddleJudge(lane:Lane, currentTime: TimeInterval) -> Bool{	  //対象ノーツが実在し、判定したかを返す(middleのparfect専用)
		
		if lane.laneNotes.count == 0 {//最後まで判定が終わってる
			return false
		}else if !(lane.laneNotes[0] is Middle){//種類が違う
			return false
		}else if !(lane.laneNotes[0].isJudgeable){
			return false
		}

		lane.update(passedTime: BGM.currentTime + BGMOffsetTime, BPMs)
		switch lane.timeState {

		case .parfect:
			setJudgeLabelText(text: "parfect!!")
			ResultScene.parfect += 1
			ResultScene.combo += 1
			if ResultScene.combo > ResultScene.maxCombo{
				ResultScene.maxCombo += 1
			}
			lane.laneNotes[0].isJudged = true
			setNextIsJudgeable(judgeNote: lane.laneNotes[0])
			releaseNote(lane: lane)
			return true
		default: break
		}
		return false
		
	}
	
	@discardableResult
	func missJudge(lane: Lane) -> Bool{
		guard lane.laneNotes[0].isJudgeable else {
			return false
		}
		
		setJudgeLabelText(text: "miss!")
		ResultScene.miss += 1
		ResultScene.combo = 0
		lane.laneNotes[0].isJudged = true
		setNextIsJudgeable(judgeNote: lane.laneNotes[0])
		releaseNote(lane: lane)
		return true
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
	
	func releaseNote(lane: Lane){//ノーツや同時押し線、関連ノードを開放する

		if let i = sameLines.index(where: {$0.note1 === lane.laneNotes.first!}){	//同時押し線を解放

			sameLines.remove(at: i)
		}else if let i = sameLines.index(where: {$0.note2 === lane.laneNotes.first!}){	//同時押し線を解放

			sameLines.remove(at: i)
		}
		if let note = lane.laneNotes.first! as? TapEnd{		//始点から終点まで、連鎖的に参照を削除
			let index = notes.index(where: {$0 === note.start})
			notes.remove(at: index!)
		}else if let note = lane.laneNotes.first! as? FlickEnd{
			let index = notes.index(where: {$0 === note.start})
			notes.remove(at: index!)
		}else if lane.laneNotes.first! is Tap || lane.laneNotes.first! is Flick{
			let index = notes.index(where: {$0 === lane.laneNotes.first!})
			notes.remove(at: index!)
		}
		lane.laneNotes.removeFirst()					//レーンからの参照を削除
		
	}
}
