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
	var playButton = UIButton()
	var settingButton = UIButton()
	let settingImage = UIImage(named: "SettingIcon")
	let settingImageSelected = UIImage(named: "SettingIconSelected")
	var settingLabel = SKLabelNode(fontNamed: "HiraginoSans-W6")
	var plusButton = UIButton()
	var plus10Button = UIButton()
	var minusButton = UIButton()
	var minus10Button = UIButton()
	
	
	override func didMove(to view: SKView) {
		
		backgroundColor = .white
		
		//ピッカーキーボードの設置
		let rect = CGRect(origin:CGPoint(x:self.frame.midX - self.frame.width/6,y:self.frame.height/3) ,size:CGSize(width:self.frame.width/3 ,height:50))
		picker = PickerKeyboard(frame:rect)
		picker.backgroundColor = .gray
		picker.isHidden = false
		self.view?.addSubview(picker!)
		
		
		//ボタンの設定
		playButton = {() -> UIButton in
			let Button = UIButton()
			
			Button.addTarget(self, action: #selector(onClickPlayButton(_:)), for: .touchUpInside)
			Button.frame = CGRect(x: 0,y: 0, width:self.frame.width/5, height: 50)
			Button.backgroundColor = UIColor.red
			Button.layer.masksToBounds = true
			Button.setTitle("この曲で遊ぶ", for: UIControlState())
			Button.setTitleColor(UIColor.white, for: UIControlState())
			Button.setTitle("この曲で遊ぶ", for: UIControlState.highlighted)
			Button.setTitleColor(UIColor.black, for: UIControlState.highlighted)
			Button.isHidden = false
			Button.layer.cornerRadius = 20.0
			Button.layer.position = CGPoint(x: self.frame.midX + self.frame.width/3, y:self.frame.height*29/72)
			self.view?.addSubview(Button)
			
			return Button
		}()
		
		
		
		settingButton.setImage(settingImage, for: .normal)
		settingButton.setImage(settingImageSelected, for: .highlighted)
		settingButton.addTarget(self, action: #selector(onClickSettingButton(_:)), for: .touchUpInside)
		settingButton.frame = CGRect(x: self.frame.width*9.4/10,y: self.frame.width*0.1/10, width:self.frame.width/16, height: self.frame.width/16)//yは上からの座標
		self.view?.addSubview(settingButton)
		
		//ラベルの設定
		settingLabel = {() -> SKLabelNode in
			let Label = SKLabelNode(fontNamed: "HiraginoSans-W6")
			
			Label.fontSize = self.frame.height/13
			Label.horizontalAlignmentMode = .center	//中央寄せ
			Label.position = CGPoint(x:self.frame.midX, y:self.frame.height - settingLabel.fontSize*3/2)
			Label.fontColor = SKColor.black
			Label.isHidden = true
			Label.text = "設定画面"
			
			self.addChild(Label)
			return Label
		}()
		
	}
	
	override func update(_ currentTime: TimeInterval) {
		
	}
	
	@objc func onClickPlayButton(_ sender : UIButton){
		//消す
		hideMainContents()
		
		picker.resignFirstResponder()	//FirstResponderを放棄
		
		//移動
		let scene = GameScene(musicName:picker.textStore ,size: (view?.bounds.size)!)
		let skView = view as SKView!
		skView?.showsFPS = true
		skView?.showsNodeCount = true
		skView?.ignoresSiblingOrder = true
		scene.scaleMode = .resizeFill
		skView?.presentScene(scene)  // GameSceneに移動

	}
	
	@objc func onClickSettingButton(_ sender : UIButton){
		//消す
		hideMainContents()
		
		//表示
		showSettingContents()
	}
	
	func showMainContents(){
		picker.isHidden = false
		playButton.isHidden = false
		settingButton.isHidden = false
	}
	
	func hideMainContents(){
		picker.isHidden = true
		playButton.isHidden = true
		settingButton.isHidden = true
	}
	
	func showSettingContents(){
		settingLabel.isHidden = false
	}
	
	func hideSettingContents() {
		settingLabel.isHidden = true
	}
}
