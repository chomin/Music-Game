//
//  ChooseSoundScene.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//



import SpriteKit
import GameplayKit

class ChooseMusicScene: SKScene {
	
	var picker:PickerKeyboard!
	let playButton = UIButton()
	
	
	override func didMove(to view: SKView) {
		
		backgroundColor = .white
		
		//ピッカーキーボードの設置
		let rect = CGRect(origin:CGPoint(x:self.frame.midX - self.frame.width/6,y:self.frame.height/3) ,size:CGSize(width:self.frame.width/3 ,height:50))
		picker = PickerKeyboard(frame:rect)
		picker.backgroundColor = .gray
		picker.isHidden = false
		self.view?.addSubview(picker!)
		
		
		//ボタンの設定
		playButton.addTarget(self, action: #selector(onClickPlayButton(_:)), for: .touchUpInside)
		playButton.frame = CGRect(x: 0,y: 0,width:self.frame.width/5 ,height: 50)
		playButton.backgroundColor = UIColor.red
		playButton.layer.masksToBounds = true
		playButton.setTitle("この曲で遊ぶ", for: UIControlState())
		playButton.setTitleColor(UIColor.white, for: UIControlState())
		playButton.setTitle("この曲で遊ぶ", for: UIControlState.highlighted)
		playButton.setTitleColor(UIColor.black, for: UIControlState.highlighted)
		playButton.isHidden = false
		playButton.layer.cornerRadius = 20.0
		playButton.layer.position = CGPoint(x: self.frame.midX + self.frame.width/3, y:self.frame.height*29/72)
		self.view?.addSubview(playButton)
	}
	
	override func update(_ currentTime: TimeInterval) {
		
	}
	
	@objc func onClickPlayButton(_ sender : UIButton){
		
		picker.isHidden = true
		picker.resignFirstResponder()
		playButton.isHidden = true
		
		
		let scene = GameScene(musicName:picker.textStore ,size: (view?.bounds.size)!)
		let skView = view as SKView!
		skView?.showsFPS = true
		skView?.showsNodeCount = true
		skView?.ignoresSiblingOrder = true
		scene.scaleMode = .resizeFill
		skView?.presentScene(scene)  // GameSceneに移動

	}
	
}
