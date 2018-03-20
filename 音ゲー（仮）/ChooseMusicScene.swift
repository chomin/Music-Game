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
    
    enum Keys: String {
        case speedRatioInt = "SpeedRatioInt"
    }
    
    var picker:PickerKeyboard!
    
    var playButton = UIButton()
    var settingButton = UIButton()
    var plusButton = UIButton()
    var plus10Button = UIButton()
    var minusButton = UIButton()
    var minus10Button = UIButton()
    var saveAndBackButton = UIButton()
    
    let settingImage = UIImage(named: ImageName.setting.rawValue)
    let settingImageSelected = UIImage(named: ImageName.settingSelected.rawValue)
    let plusImage = UIImage(named: ImageName.plus.rawValue)
    let plusImageSelected = UIImage(named: ImageName.plusSelected.rawValue)
    let minusImage = UIImage(named: ImageName.minus.rawValue)
    let minusImageSelected = UIImage(named: ImageName.minusSelected.rawValue)
    let plus10Image = UIImage(named: ImageName.plus10.rawValue)
    let plus10ImageSelected = UIImage(named: ImageName.plus10Selected.rawValue)
    let minus10Image = UIImage(named: ImageName.minus10.rawValue)
    let minus10ImageSelected = UIImage(named: ImageName.minus10Selected.rawValue)
    let saveAndBackImage = UIImage(named: ImageName.saveAndBack.rawValue)
    let saveAndBackImageSelected = UIImage(named: ImageName.saveAndBackSelected.rawValue)
    
    var settingLabel = SKLabelNode(fontNamed: "HiraginoSans-W6")    // "設定画面"
    var speedLabel = SKLabelNode(fontNamed: "HiraginoSans-W6")      // スピードの値（％）
    var speedTitleLabel = SKLabelNode(fontNamed: "HiraginoSans-W6") // "速さ"
    
//    var iconButtonSize:CGFloat!
    var speedsPosY:CGFloat!
    
    let defaults = UserDefaults.standard
    
    var speedRatioInt:UInt = 0
    
    
    
    
    override func didMove(to view: SKView) {
        
        defaults.register(defaults: [Keys.speedRatioInt.rawValue : 100])    // 初期値を設定(値がすでに入ってる場合は無視される)
        
        speedsPosY = Dimensions.iconButtonSize*3
        
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
            Button.addTarget(self, action: #selector(onPlayButton(_:)), for: .touchDown)
            Button.addTarget(self, action: #selector(touchUpOutsideButton(_:)), for: .touchUpOutside)
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
        
        settingButton = {() -> UIButton in
            let Button = UIButton()
            
            Button.setImage(settingImage, for: .normal)
            Button.setImage(settingImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(onClickSettingButton(_:)), for: .touchUpInside)
            Button.addTarget(self, action: #selector(onSettingButton(_:)), for: .touchDown)
            Button.addTarget(self, action: #selector(touchUpOutsideButton(_:)), for: .touchUpOutside)

            Button.frame = CGRect(x: self.frame.width - Dimensions.iconButtonSize, y: 0, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            return Button
        }()
        
        plusButton = {() -> UIButton in
            let Button = UIButton()
            
            Button.setImage(plusImage, for: .normal)
            Button.setImage(plusImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(onClickPlusButton(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.midX + Dimensions.iconButtonSize*1.5, y: speedsPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = true
            return Button
        }()
        
        plus10Button = {() -> UIButton in
            let Button = UIButton()
            
            Button.setImage(plus10Image, for: .normal)
            Button.setImage(plus10ImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(onClickPlus10Button(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.midX + Dimensions.iconButtonSize*2.5, y: speedsPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = true
            return Button
        }()
        
        minusButton = {() -> UIButton in
            let Button = UIButton()
            
            Button.setImage(minusImage, for: .normal)
            Button.setImage(minusImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(onClickMinusButton(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.midX - Dimensions.iconButtonSize*2.5, y: speedsPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = true
            return Button
        }()
        
        minus10Button = {() -> UIButton in
            let Button = UIButton()
            
            Button.setImage(minus10Image, for: .normal)
            Button.setImage(minus10ImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(onClickMinus10Button(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.midX - Dimensions.iconButtonSize*3.5, y: speedsPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = true
            return Button
        }()
        
        saveAndBackButton = {() -> UIButton in
            let Button = UIButton()
            
            Button.setImage(saveAndBackImage, for: .normal)
            Button.setImage(saveAndBackImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(onClickSaveAndBackButton(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.width*9.4/10, y: self.frame.height - Dimensions.iconButtonSize, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = true
            return Button
        }()
        
        
        //ラベルの設定
        settingLabel = {() -> SKLabelNode in
            let Label = SKLabelNode(fontNamed: "HiraginoSans-W6")
            
            Label.fontSize = self.frame.height/13
            Label.horizontalAlignmentMode = .center //中央寄せ
            Label.position = CGPoint(x:self.frame.midX, y:self.frame.height - settingLabel.fontSize*3/2)
            Label.fontColor = SKColor.black
            Label.isHidden = true
            Label.text = "設定画面"
            
            self.addChild(Label)
            return Label
        }()
        
        speedLabel = {() -> SKLabelNode in
            let Label = SKLabelNode(fontNamed: "HiraginoSans-W6")
            
            Label.fontSize = Dimensions.iconButtonSize * 0.8
            Label.horizontalAlignmentMode = .center//中央寄せ
            Label.position = CGPoint(x:self.frame.midX, y:self.frame.height - speedsPosY - Dimensions.iconButtonSize*0.8)
            Label.fontColor = SKColor.black
            Label.isHidden = true
            
            self.addChild(Label)
            return Label
        }()
        
        speedTitleLabel = {() -> SKLabelNode in
            let Label = SKLabelNode(fontNamed: "HiraginoSans-W6")
            
            Label.fontSize = Dimensions.iconButtonSize * 0.6
            Label.horizontalAlignmentMode = .center //中央寄せ
            Label.position = CGPoint(x:self.frame.midX, y:self.frame.height - speedsPosY)
            Label.fontColor = SKColor.black
            Label.isHidden = true
            Label.text = "速さ"
            
            self.addChild(Label)
            return Label
        }()
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        speedLabel.text = String(speedRatioInt) + "%"
    }
    
    @objc func onClickPlayButton(_ sender : UIButton) {
        // 消す
        hideMainContents()
        
        picker.resignFirstResponder()   // FirstResponderを放棄
        
        // 移動
        let scene: GameScene
        if picker.textStore.suffix(9) == "(YouTube)" {
            var playMode = PlayMode.YouTube
            var pickerTextStore = picker.textStore
            pickerTextStore.removeLast(9)
            
            //ネタバレ注意！
            if pickerTextStore == "オラシオン" &&
                (defaults.integer(forKey: Keys.speedRatioInt.rawValue) <= 21 ||
                defaults.integer(forKey: Keys.speedRatioInt.rawValue) >= 201) { playMode = .YouTube2 /* 裏シオン */ }
            
            scene = GameScene(musicName: MusicName(rawValue: pickerTextStore)!, playMode: playMode, size: (view?.bounds.size)!, speedRatioInt:UInt(defaults.integer(forKey: Keys.speedRatioInt.rawValue)))
        }else{
            scene = GameScene(musicName: MusicName(rawValue: picker.textStore)! ,playMode: .BGM ,size: (view?.bounds.size)!, speedRatioInt:UInt(defaults.integer(forKey: Keys.speedRatioInt.rawValue)))
        }
        
       
        
        
        let skView = view as SKView?    // このviewはGameViewControllerのskView2
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
    
    @objc func onClickPlusButton(_ sender : UIButton){
        speedRatioInt += 1
    }
    
    @objc func onClickPlus10Button(_ sender : UIButton){
        speedRatioInt += 10
    }
    
    @objc func onClickMinusButton(_ sender : UIButton){
        if speedRatioInt > 0 { speedRatioInt -= 1 }
    }
    
    @objc func onClickMinus10Button(_ sender : UIButton){
        if speedRatioInt > 10 { speedRatioInt -= 10 }
        else 			    { speedRatioInt =  0  }
    }
    
    @objc func onClickSaveAndBackButton(_ sender : UIButton){
        //保存
        defaults.set(speedRatioInt, forKey: Keys.speedRatioInt.rawValue)
        
        //消して表示
        hideSettingContents()
        showMainContents()
    }
    
    // 同時押し対策
    @objc func onSettingButton(_ sender : UIButton){
        playButton.isEnabled = false
    }
    @objc func onPlayButton(_ sender : UIButton){
        settingButton.isEnabled = false
    }
    @objc func touchUpOutsideButton(_ sender : UIButton){
        playButton.isEnabled = true
        settingButton.isEnabled = true
    }
    
    func showMainContents(){
        picker.isHidden = false
        playButton.isHidden = false
        settingButton.isHidden = false
        
        playButton.isEnabled = true
        settingButton.isEnabled = true
    }
    
    func hideMainContents(){
        picker.isHidden = true
        playButton.isHidden = true
        settingButton.isHidden = true
    }
    
    func showSettingContents(){
        settingLabel.isHidden = false
        speedLabel.isHidden = false
        speedTitleLabel.isHidden = false
        
        saveAndBackButton.isHidden = false
        plusButton.isHidden = false
        plus10Button.isHidden = false
        minusButton.isHidden = false
        minus10Button.isHidden = false
        
        speedRatioInt = UInt(defaults.integer(forKey: Keys.speedRatioInt.rawValue)) //読み出し
    }
    
    func hideSettingContents() {
        settingLabel.isHidden = true
        speedLabel.isHidden = true
        speedTitleLabel.isHidden = true
        
        saveAndBackButton.isHidden = true
        plusButton.isHidden = true
        plus10Button.isHidden = true
        minusButton.isHidden = true
        minus10Button.isHidden = true
    }
}
