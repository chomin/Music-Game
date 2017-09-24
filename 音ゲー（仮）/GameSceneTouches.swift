//
//  Buttons.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//

import SpriteKit

extension GameScene{
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		
		
		for i in touches {//すべてのタッチに対して処理する（同時押しなどもあるため）
			
			
			var pos = i.location(in: self.view)
			
			pos.y = self.frame.height - pos.y //上下逆転(画面下からのy座標に変換)
			
			allTouchesLocation.append(pos)
			
			if pos.y < self.frame.width/3{    //上界
				
				var doKara = false
				
				for j in 0...6{
					
					let buttonPos = self.frame.width/6 + CGFloat(j)*self.frame.width/9
					
					if pos.x > buttonPos - halfBound && pos.x < buttonPos + halfBound {//ボタンの範囲
						
						if judge(laneNum: j+1, type: .tap){//タップの判定
							
							playSound(type: .tap)
							break
							
						}else if lanes[j].timeState == .still{
							if doKara == true || j == 6{
								playSound(type: .kara)
								break
							} else {  //次のレーンまで確認
								doKara = true
							}
						}
					}
				}
			}
		}
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {//ボタン外でスタートした時にしか起動しない
		
		
		
		for i in touches{
			
			var pos = i.location(in: self.view)
			var ppos = i.previousLocation(in: self.view)
			let moveDistance = sqrt(pow(pos.x-ppos.x, 2) + pow(pos.y-ppos.y, 2))
			
			pos.y = self.frame.height - pos.y //上下逆転(画面下からのy座標に変換)
			ppos.y = self.frame.height - ppos.y
			
			allTouchesLocation[allTouchesLocation.index(of: ppos)!] = pos
		
			
	
			
			if pos.y < self.frame.width/3{    //上界
				
				for j in 0...6{
					
					let buttonPos = self.frame.width/6 + CGFloat(j)*self.frame.width/9
					
					if pos.x > buttonPos - halfBound && pos.x < buttonPos + halfBound {//ボタンの範囲
						
//						if parfectMiddleJudge(laneNum: j+1){//途中線の判定
//
//							playSound(type: .tap)
//							break
//						}
					}
					if ppos.x > buttonPos - halfBound && ppos.x < buttonPos + halfBound{
						if moveDistance > 10{	//フリックの判定
							
							if judge(laneNum: j+1, type: .flick) || judge(laneNum: j+1, type: .flickEnd){
								
								playSound(type: .flick)
								break
							}
						}
					}
				}
			}
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {//ボタン外でスタートした時にしか起動しない
		
		for i in touches {
			
			var pos = i.location(in: self.view)
			var ppos = i.previousLocation(in: self.view)
			
			pos.y = self.frame.height - pos.y //上下逆転(画面下からのy座標に変換)
			ppos.y = self.frame.height - ppos.y
			
			allTouchesLocation.remove(at: allTouchesLocation.index(of: ppos)!)
			
			if pos.y < self.frame.width/3{    //上界
				
				for j in 0...6{
					
					let buttonPos = self.frame.width/6 + CGFloat(j)*self.frame.width/9
					
					if pos.x > buttonPos - halfBound && pos.x < buttonPos + halfBound {//ボタンの範囲
						
						if judge(laneNum: j+1, type: .tapEnd){//離しの判定
							
							playSound(type: .tap)
							break
						}
					}
				}
			}
		}
	}
	
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		print("cancelされました")
	}

	override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {
		print("touchesEstimatedPropertiesUpdated")
	}



	
	func judge(laneNum:Int,type:NoteType) -> Bool{	  //対象ノーツが実在し、判定したかを返す
		
		let nextIndex = lanes[laneNum-1].nextNoteIndex
		
		if nextIndex >= lanes[laneNum-1].laneNotes.count{//最後まで判定が終わってる
			return false
		}else if lanes[laneNum-1].laneNotes[nextIndex].type != type{//種類が違う
			return false
		}
		
		switch lanes[laneNum-1].timeState {
		case .parfect:
			judgeLabel.text = "parfect!!"
			ResultScene.parfect += 1
			ResultScene.combo += 1
			if ResultScene.combo > ResultScene.maxCombo{
				ResultScene.maxCombo += 1
			}
			self.removeChildren(in: [lanes[laneNum-1].laneNotes[nextIndex].image])
			lanes[laneNum-1].laneNotes[nextIndex].isJudged = true
			lanes[laneNum-1].nextNoteIndex += 1
			return true
		case .great:
			judgeLabel.text = "great!"
			ResultScene.great += 1
			ResultScene.combo += 1
			if ResultScene.combo > ResultScene.maxCombo{
				ResultScene.maxCombo += 1
			}
			self.removeChildren(in: [lanes[laneNum-1].laneNotes[nextIndex].image])
			lanes[laneNum-1].laneNotes[nextIndex].isJudged = true
			lanes[laneNum-1].nextNoteIndex += 1
			return true
		case .good:
			judgeLabel.text = "good"
			ResultScene.good += 1
			ResultScene.combo = 0
			self.removeChildren(in: [lanes[laneNum-1].laneNotes[nextIndex].image])
			lanes[laneNum-1].laneNotes[nextIndex].isJudged = true
			lanes[laneNum-1].nextNoteIndex += 1
			return true
		case .bad:
			judgeLabel.text = "bad"
			ResultScene.bad += 1
			ResultScene.combo = 0
			self.removeChildren(in: [lanes[laneNum-1].laneNotes[nextIndex].image])
			lanes[laneNum-1].laneNotes[nextIndex].isJudged = true
			lanes[laneNum-1].nextNoteIndex += 1
			return true
		case .miss:
			judgeLabel.text = "miss!"
			ResultScene.miss += 1
			ResultScene.combo = 0
			self.removeChildren(in: [lanes[laneNum-1].laneNotes[nextIndex].image])
			lanes[laneNum-1].laneNotes[nextIndex].isJudged = true
			lanes[laneNum-1].nextNoteIndex += 1
			return true
		default: break
		}
		
		return false
		
	}
	
	func parfectMiddleJudge(laneNum:Int) -> Bool{	  //対象ノーツが実在し、判定したかを返す(middleのparfect専用)
		
		let nextIndex = lanes[laneNum-1].nextNoteIndex
		
		if nextIndex >= lanes[laneNum-1].laneNotes.count{//最後まで判定が終わってる
			return false
		}else if lanes[laneNum-1].laneNotes[nextIndex].type != .middle{//種類が違う
			return false
		}
		
		switch lanes[laneNum-1].timeState {
		case .parfect:
			judgeLabel.text = "parfect!!"
			ResultScene.parfect += 1
			ResultScene.combo += 1
			if ResultScene.combo > ResultScene.maxCombo{
				ResultScene.maxCombo += 1
			}
			self.removeChildren(in: [lanes[laneNum-1].laneNotes[nextIndex].image])
			lanes[laneNum-1].laneNotes[nextIndex].isJudged = true
			lanes[laneNum-1].nextNoteIndex += 1
			return true
		default: break
		}
		
		return false
		
	}
}
