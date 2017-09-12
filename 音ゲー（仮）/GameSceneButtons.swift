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
	func setButtons(){
		let width = self.frame.width
		for (index,value) in buttons.enumerated(){
			value.frame = CGRect(x:(width/9)+(width/9)*CGFloat(index) ,y:self.frame.height-width/6 ,width:width/9 ,height:width/9)	  //上下が逆！？
			value.backgroundColor = UIColor.clear
			
			value.tag = index + 1 //1~7
			
			value.layer.borderColor = UIColor.red.cgColor
			value.layer.borderWidth = 2.0
			value.layer.cornerRadius = width/18
			value.insets = UIEdgeInsetsMake(50, 50, 50, 50)	  //認識領域のみを広げる
			self.view!.addSubview(value)
			

			//スワイプした時の動作
			let swipeUp = UISwipeGestureRecognizer()
			swipeUp.direction = UISwipeGestureRecognizerDirection.up
			swipeUp.addTarget(self, action:#selector(GameScene.flick(_:)))
			value.addGestureRecognizer(swipeUp)	  //ボタンをviewとして...
			let swipeRight = UISwipeGestureRecognizer()
			swipeRight.direction = UISwipeGestureRecognizerDirection.right
			swipeRight.addTarget(self, action:#selector(GameScene.flick(_:)))
			value.addGestureRecognizer(swipeRight)
			let swipeDown = UISwipeGestureRecognizer()
			swipeDown.direction = UISwipeGestureRecognizerDirection.down
			swipeDown.addTarget(self, action:#selector(GameScene.flick(_:)))
			value.addGestureRecognizer(swipeDown)
			let swipeLeft = UISwipeGestureRecognizer()
			swipeLeft.direction = UISwipeGestureRecognizerDirection.left
			swipeLeft.addTarget(self, action:#selector(GameScene.flick(_:)))
			value.addGestureRecognizer(swipeLeft)
			
			value.addTarget(self, action: #selector(GameScene.touchDown(_:)), for: .touchDown)
		}
	}
	
	
	func touchDown(_ sender: UIButton){
		if kara1?.isPlaying == false{
			kara1?.play()
		}else if kara2?.isPlaying == false{
			kara2?.play()
		}else if kara3?.isPlaying == false{
			kara3?.play()
		}else if kara4?.isPlaying == false{
			kara4?.play()
		}
	}

	func flick(_ sender:UISwipeGestureRecognizer){
		print("フリック！")
		
		if let button = sender.view as? UIButton{	  //viewをUIButtonとして...
			print(button.tag)
			//1フリックでも1か2、2フリックでも2か3...などと表示（認識）される！
		}
	}
}

class ExpansionButton: UIButton {	//認識領域のみを広げる下準備
	
	var insets = UIEdgeInsetsMake(0, 0, 0, 0)
	
	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		var rect = bounds
		rect.origin.x -= insets.left
		rect.origin.y -= insets.top
		rect.size.width += insets.left + insets.right
		rect.size.height += insets.top + insets.bottom
		
		// 拡大したViewサイズがタップ領域に含まれているかどうかを返します
		return rect.contains(point)
	}
}

