//
//  Buttons.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//

//（9/11の成果が残っている？）

import SpriteKit

extension GameScene{
//	func setButtons(){
//		let width = self.frame.width
//		for (index,value) in buttons.enumerated(){
//			value.frame = CGRect(x:(width*29/288)+(width/9)*CGFloat(index) ,y:self.frame.height-width*5/36 ,width:width*19/144 ,height:width/18)	  //上下が逆！？
//			value.backgroundColor = UIColor.clear
//			
//			value.tag = index + 1 //1~7
//			
//			value.layer.borderColor = UIColor.red.cgColor
//			value.layer.borderWidth = 2.0
//			value.layer.cornerRadius = width/18
//			value.insets = UIEdgeInsetsMake(70, 0, 70 ,0)  //認識領域のみを広げる(top,left,bottom,right)
//			self.view!.addSubview(value)
//			
//
////			//スワイプした時の動作
////			let swipeUp = UISwipeGestureRecognizer()
////			swipeUp.direction = UISwipeGestureRecognizerDirection.up
////			swipeUp.addTarget(self, action:#selector(GameScene.flick(_:)))
////			value.addGestureRecognizer(swipeUp)	  //ボタンをviewとして...
////			let swipeRight = UISwipeGestureRecognizer()
////			swipeRight.direction = UISwipeGestureRecognizerDirection.right
////			swipeRight.addTarget(self, action:#selector(GameScene.flick(_:)))
////			value.addGestureRecognizer(swipeRight)
////			let swipeDown = UISwipeGestureRecognizer()
////			swipeDown.direction = UISwipeGestureRecognizerDirection.down
////			swipeDown.addTarget(self, action:#selector(GameScene.flick(_:)))
////			value.addGestureRecognizer(swipeDown)
////			let swipeLeft = UISwipeGestureRecognizer()
////			swipeLeft.direction = UISwipeGestureRecognizerDirection.left
////			swipeLeft.addTarget(self, action:#selector(GameScene.flick(_:)))
////			value.addGestureRecognizer(swipeLeft)
//			
//			value.addTarget(self, action: #selector(GameScene.touchDown(_:forEvent:)), for: .touchDown)
//			value.addTarget(self, action: #selector(GameScene.touchDragInside(_:forEvent:)), for: .touchDragInside)//...Insideはタップでも反応する
////			value.addTarget(self, action: #selector(GameScene.touchDragExit(_:)), for: .touchDragInside)//縦長押しmiddleにしようとしたけど、保留
//
//		}
//	}
	
//	
//	func touchDown(_ sender: ExpansionButton, forEvent:UIEvent){
//		
//		sender.touchDownPoint = (forEvent.touches(for: sender)?.first?.location(in: sender))!
//		
//		if judge(laneNum: sender.tag, type: .tap) == true{
//			if tapSound1?.isPlaying == false{
//				tapSound1?.play()
//			}else if tapSound2?.isPlaying == false{
//				tapSound2?.play()
//			}else if tapSound3?.isPlaying == false{
//				tapSound3?.play()
//			}else if tapSound4?.isPlaying == false{
//				tapSound4?.play()
//			}
//		}else if lanes[sender.tag-1].timeState == .still{//他の種類の判定対象にもなってない場合
//			if kara1?.isPlaying == false{
//				kara1?.play()
//			}else if kara2?.isPlaying == false{
//				kara2?.play()
//			}else if kara3?.isPlaying == false{
//				kara3?.play()
//			}else if kara4?.isPlaying == false{
//				kara4?.play()
//			}
//		}
//		
//		
//	}
//	
//	func touchDragInside(_ sender: ExpansionButton, forEvent: UIEvent){
//
//		let nowPoint = forEvent.touches(for: sender)?.first?.location(in: sender)
//		let distance = sqrt(pow((nowPoint?.x)! - sender.touchDownPoint.x,2) + pow((nowPoint?.y)! - sender.touchDownPoint.y,2))
//		
//		if distance > 10{
//			
//			if judge(laneNum: sender.tag, type: .flick) == true{
//				if flickSound1?.isPlaying == false{
//					flickSound1?.play()
//				}else if flickSound2?.isPlaying == false{
//					flickSound2?.play()
//				}else if flickSound3?.isPlaying == false{
//					flickSound3?.play()
//				}else if flickSound4?.isPlaying == false{
//					flickSound4?.play()
//				}
//			}else if judge(laneNum: sender.tag, type: .flickEnd) == true{
//				if flickSound1?.isPlaying == false{
//					flickSound1?.play()
//				}else if flickSound2?.isPlaying == false{
//					flickSound2?.play()
//				}else if flickSound3?.isPlaying == false{
//					flickSound3?.play()
//				}else if flickSound4?.isPlaying == false{
//					flickSound4?.play()
//				}
//			}
//		}
//		
//	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		// 最初にタッチした指のみ取得
		if let touch = touches.first {
			
			var pos = touch.location(in: self.view)
			
			pos.y = self.frame.height - pos.y //上下逆転(画面下からのy座標に変換)
			
			if pos.y < self.frame.width/3{    //上界
				
				for i in 0...6{
					
					let buttonPos = self.frame.width/6 + CGFloat(i)*self.frame.width/9
					
					if pos.x > buttonPos - halfBound && pos.x < buttonPos + halfBound {//ボタンの範囲
						
						if judge(laneNum: i+1, type: .tap){//タップの判定
							
							playSound(type: .tap)
							break
							
						}else if lanes[i].timeState == .still{
						
							playSound(type: .kara)
							break
						}
					}
				}
			}
		}
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {//ボタン外でスタートした時にしか起動しない
		// 最初にタッチした指のみ取得
		if let touch = touches.first {
			
			var pos = touch.location(in: self.view)
			
			pos.y = self.frame.height - pos.y //上下逆転(画面下からのy座標に変換)
			
			if pos.y < self.frame.width/3{    //上界
				
				for i in 0...6{
					
					let buttonPos = self.frame.width/6 + CGFloat(i)*self.frame.width/9
					
					if pos.x > buttonPos - halfBound && pos.x < buttonPos + halfBound {//ボタンの範囲
						
						if parfectMiddleJudge(laneNum: i+1){//途中線の判定
							
							playSound(type: .tap)
							break
						}
					}
				}
			}
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {//ボタン外でスタートした時にしか起動しない
		// 最初にタッチした指のみ取得
		if let touch = touches.first {
			
			var pos = touch.location(in: self.view)
			
			pos.y = self.frame.height - pos.y //上下逆転(画面下からのy座標に変換)
			
			if pos.y < self.frame.width/3{    //上界
				
				for i in 0...6{
					
					let buttonPos = self.frame.width/6 + CGFloat(i)*self.frame.width/9
					
					if pos.x > buttonPos - halfBound && pos.x < buttonPos + halfBound {//ボタンの範囲
						
						if judge(laneNum: i+1, type: .tapEnd){//離しの判定
							
							playSound(type: .tap)
							break
						}
					}
				}
			}
		}
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
//			lanes[laneNum-1].laneNotes[nextIndex].image.position.x = 2000
			lanes[laneNum-1].laneNotes[nextIndex].image.isHidden = true
			lanes[laneNum-1].nextNoteIndex += 1
			return true
		case .great:
			judgeLabel.text = "great!"
//			lanes[laneNum-1].laneNotes[nextIndex].image.position.x = 2000
			lanes[laneNum-1].laneNotes[nextIndex].image.isHidden = true
			lanes[laneNum-1].nextNoteIndex += 1
			return true
		case .good:
			judgeLabel.text = "good"
//			lanes[laneNum-1].laneNotes[nextIndex].image.position.x = 2000
			lanes[laneNum-1].laneNotes[nextIndex].image.isHidden = true
			lanes[laneNum-1].nextNoteIndex += 1
			return true
		case .bad:
			judgeLabel.text = "bad"
//			lanes[laneNum-1].laneNotes[nextIndex].image.position.x = 2000
			lanes[laneNum-1].laneNotes[nextIndex].image.isHidden = true
			lanes[laneNum-1].nextNoteIndex += 1
			return true
		case .miss:
			judgeLabel.text = "miss!"
//			lanes[laneNum-1].laneNotes[nextIndex].image.position.x = 2000
			lanes[laneNum-1].laneNotes[nextIndex].image.isHidden = true
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
			lanes[laneNum-1].laneNotes[nextIndex].image.position.x = 2000
			lanes[laneNum-1].nextNoteIndex += 1
			return true
		default: break
		}
		
		return false
		
	}
}

//class ExpansionButton: UIButton {	//認識領域のみを広げる下準備
//	
//	var isInside = false  //ボタンの領域に指が入っているか(始点がこのボタンでなくてもtrue)
//	
//	var touchDownPoint = CGPoint(x:0, y:0)
//	
//	var insets = UIEdgeInsetsMake(0, 0, 0, 0)
//	
//	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
//		var rect = bounds
//		rect.origin.x -= insets.left
//		rect.origin.y -= insets.top
//		rect.size.width += insets.left + insets.right
//		rect.size.height += insets.top + insets.bottom
//		
//		// 拡大したViewサイズがタップ領域に含まれているかどうかを返します
//		return rect.contains(point)
//	}
//}
//
