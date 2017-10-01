//
//  Buttons.swift
//  音ゲー（仮）
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



	
	func judge(laneIndex:Int,type:NoteType) -> Bool{	  //対象ノーツが実在し、判定したかを返す
		
		let nextIndex = lanes[laneIndex].nextNoteIndex
		
		if nextIndex >= lanes[laneIndex].laneNotes.count{//最後まで判定が終わってる
			return false
		}else if lanes[laneIndex].laneNotes[nextIndex].type != type{//種類が違う
			return false
		}
		
		switch lanes[laneIndex].timeState {
		case .parfect:
			judgeLabel.text = "parfect!!"
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
			judgeLabel.text = "great!"
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
			judgeLabel.text = "good"
			ResultScene.good += 1
			ResultScene.combo = 0
			self.removeChildren(in: [lanes[laneIndex].laneNotes[nextIndex].image])
			lanes[laneIndex].laneNotes[nextIndex].isJudged = true
			lanes[laneIndex].nextNoteIndex += 1
			return true
		case .bad:
			judgeLabel.text = "bad"
			ResultScene.bad += 1
			ResultScene.combo = 0
			self.removeChildren(in: [lanes[laneIndex].laneNotes[nextIndex].image])
			lanes[laneIndex].laneNotes[nextIndex].isJudged = true
			lanes[laneIndex].nextNoteIndex += 1
			return true
		case .miss:
			judgeLabel.text = "miss!"
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
		}else if lanes[laneIndex].laneNotes[nextIndex].type != .middle{//種類が違う
			return false
		}
		
		switch lanes[laneIndex].timeState {
		case .parfect:
			judgeLabel.text = "parfect!!"
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
