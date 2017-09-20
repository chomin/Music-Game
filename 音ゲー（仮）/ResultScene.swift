//
//  ResultScene.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/20.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//

import SpriteKit
class ResultScene: SKScene {
	static var parfect = 0
	static var great = 0
	static var good = 0
	static var bad = 0
	static var miss = 0
	static var combo = 0
	static var maxCombo = 0
	
	var label:SKLabelNode!
	var resultFontSize:CGFloat!
	
	override func didMove(to view: SKView) {
		
		resultFontSize = self.frame.width/24
		
		label = {() -> SKLabelNode in
			let Label = SKLabelNode(fontNamed: "HiraginoSans-W6")
			
			Label.fontSize = resultFontSize
			Label.horizontalAlignmentMode = .center	//中央寄せ
			Label.position = CGPoint(x:self.frame.midX, y:0)
			Label.fontColor=SKColor.white
			Label.numberOfLines = 7
			
			Label.text =	//swift4からの書き方(改行入りのString)
			"""
			parfect:\(ResultScene.parfect)
			great:\(ResultScene.great)
			good:\(ResultScene.good)
			bad:\(ResultScene.bad)
			miss:\(ResultScene.miss)
			
			combo:\(ResultScene.maxCombo)
			"""
			
			self.addChild(Label)
			return Label
		}()
		
	}
	
	
	override func update(_ currentTime: TimeInterval) {
		// Called before each frame is rendered
	}
}
