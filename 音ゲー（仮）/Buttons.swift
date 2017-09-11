//
//  Buttons.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//

import SpriteKit

extension GameScene{
	func setButtons(){
		let width = self.frame.width
		for (index,value) in buttons.enumerated(){
			value.frame = CGRect(x:(width/9)+(width/9)*CGFloat(index) ,y:self.frame.height-width/6 ,width:width/9 ,height:width/9)	  //上下が逆！？
			value.backgroundColor = UIColor.clear
			
			value.layer.borderColor = UIColor.red.cgColor
			value.layer.borderWidth = 2.0
			value.layer.cornerRadius = width/18
			self.view!.addSubview(value)
		}
	}
	
}
