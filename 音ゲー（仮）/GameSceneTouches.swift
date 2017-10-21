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
	
	func judge(laneIndex:Int, type:NoteType) -> Bool{	  //対象ノーツが実在し、判定したかを返す
		
		let nextIndex = lanes[laneIndex].nextNoteIndex
		
		if nextIndex >= lanes[laneIndex].laneNotes.count{//最後まで判定が終わってる
			return false
		} else {
			// 種類が違う場合を弾く(型で判別)
			let note = lanes[laneIndex].laneNotes[nextIndex]
			switch type {
			case .tap:      if !(note is Tap)      { return false }
			case .flick:    if !(note is Flick)    { return false }
			case .tapStart: if !(note is TapStart) { return false }
			case .middle:   if !(note is Middle)   { return false }
			case .tapEnd:   if !(note is TapEnd)   { return false }
			case .flickEnd: if !(note is FlickEnd) { return false }
			}
		}
		
		switch lanes[laneIndex].timeState {
		case .parfect:
			setJudgeLabelText(text: "parfect!!")
			ResultScene.parfect += 1
			ResultScene.combo += 1
			if ResultScene.combo > ResultScene.maxCombo{
				ResultScene.maxCombo += 1
			}
			self.removeChildren(in: [lanes[laneIndex].laneNotes[nextIndex].image])
			lanes[laneIndex].laneNotes[nextIndex].isJudged = true
			lanes[laneIndex].nextNoteIndex += 1
			return true
		case .great:
			setJudgeLabelText(text: "great!")
			ResultScene.great += 1
			ResultScene.combo += 1
			if ResultScene.combo > ResultScene.maxCombo{
				ResultScene.maxCombo += 1
			}
			self.removeChildren(in: [lanes[laneIndex].laneNotes[nextIndex].image])
			lanes[laneIndex].laneNotes[nextIndex].isJudged = true
			lanes[laneIndex].nextNoteIndex += 1
			return true
		case .good:
			setJudgeLabelText(text: "good")
			ResultScene.good += 1
			ResultScene.combo = 0
			self.removeChildren(in: [lanes[laneIndex].laneNotes[nextIndex].image])
			lanes[laneIndex].laneNotes[nextIndex].isJudged = true
			lanes[laneIndex].nextNoteIndex += 1
			return true
		case .bad:
			setJudgeLabelText(text: "bad")
			ResultScene.bad += 1
			ResultScene.combo = 0
			self.removeChildren(in: [lanes[laneIndex].laneNotes[nextIndex].image])
			lanes[laneIndex].laneNotes[nextIndex].isJudged = true
			lanes[laneIndex].nextNoteIndex += 1
			return true
		case .miss:
			setJudgeLabelText(text: "miss!")
			ResultScene.miss += 1
			ResultScene.combo = 0
			self.removeChildren(in: [lanes[laneIndex].laneNotes[nextIndex].image])
			lanes[laneIndex].laneNotes[nextIndex].isJudged = true
			lanes[laneIndex].nextNoteIndex += 1
			return true
		default: break
		}
		
		return false
		
	}
	
	func parfectMiddleJudge(laneIndex:Int) -> Bool{	  //対象ノーツが実在し、判定したかを返す(middleのparfect専用)
		
		let nextIndex = lanes[laneIndex].nextNoteIndex
		
		if nextIndex >= lanes[laneIndex].laneNotes.count{//最後まで判定が終わってる
			return false
		}else if !(lanes[laneIndex].laneNotes[nextIndex] is Middle){//種類が違う
			return false
		}
		
		switch lanes[laneIndex].timeState {
		case .parfect:
			setJudgeLabelText(text: "parfect!!")
			ResultScene.parfect += 1
			ResultScene.combo += 1
			if ResultScene.combo > ResultScene.maxCombo{
				ResultScene.maxCombo += 1
			}
			self.removeChildren(in: [lanes[laneIndex].laneNotes[nextIndex].image])
			lanes[laneIndex].laneNotes[nextIndex].isJudged = true
			lanes[laneIndex].nextNoteIndex += 1
			return true
		default: break
		}
		
		return false
		
	}
}
