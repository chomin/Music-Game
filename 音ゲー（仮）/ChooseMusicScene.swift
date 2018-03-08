//
//  ChooseSoundScene.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//



import SpriteKit
import GameplayKit

enum Keys:String {
    case speedRatioInt = "SpeedRatioInt"
}




class ChooseMusicScene: SKScene {
    
    //VideoIDの辞書(https://www.youtube.com/watch?v=************の***********部分)
    let videoIDDictionary = ["LEVEL5-Judgelight-":"1NYUKIZCV5k", "ぼなぺてぃーとS":"LOajYHKEHG8", "SAKURAスキップ":"dBwwipunJcw", "オラシオン":"6kQzRm21N_g", "ウラシオン":"fF6c1gqutjs", "にめんせい☆ウラオモテライフ！":"TyMx4pu7kA0", "ようこそジャパリパークへ":"xkMdLcB_vNU"]
    /*
     "ぼなぺてぃーとS": 埋め込み許可されているアニメ版が見つからず
     
    */
    
    var picker:PickerKeyboard!
    
    var playButton = UIButton()
    var settingButton = UIButton()
    var plusButton = UIButton()
    var plus10Button = UIButton()
    var minusButton = UIButton()
    var minus10Button = UIButton()
    var saveAndBackButton = UIButton()
    
    let settingImage = UIImage(named: "SettingIcon")
    let settingImageSelected = UIImage(named: "SettingIconSelected")
    let plusImage = UIImage(named: "PlusIcon")
    let plusImageSelected = UIImage(named: "PlusIconSelected")
    let minusImage = UIImage(named: "MinusIcon")
    let minusImageSelected = UIImage(named: "MinusIconSelected")
    let plus10Image = UIImage(named: "Plus10Icon")
    let plus10ImageSelected = UIImage(named: "Plus10IconSelected")
    let minus10Image = UIImage(named: "Minus10Icon")
    let minus10ImageSelected = UIImage(named: "Minus10IconSelected")
    let saveAndBackImage = UIImage(named: "SaveAndBackIcon")
    let saveAndBackImageSelected = UIImage(named: "SaveAndBackIconSelected")
    
    var settingLabel = SKLabelNode(fontNamed: "HiraginoSans-W6")    // "設定画面"
    var speedLabel = SKLabelNode(fontNamed: "HiraginoSans-W6")      // スピードの値（％）
    var speedTitleLabel = SKLabelNode(fontNamed: "HiraginoSans-W6") // "速さ"
    
    var iconButtonSize:CGFloat!
    var speedsPosY:CGFloat!
    
    let defaults = UserDefaults.standard
    
    var speedRatioInt:UInt = 0
    
    
    
    
    override func didMove(to view: SKView) {
        
        defaults.register(defaults: [Keys.speedRatioInt.rawValue : 100])    // 初期値を設定(値がすでに入ってる場合は無視される)
        
        iconButtonSize = self.frame.width/16
        speedsPosY = iconButtonSize*3
        
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
        
        settingButton = {() -> UIButton in
            let Button = UIButton()
            
            Button.setImage(settingImage, for: .normal)
            Button.setImage(settingImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(onClickSettingButton(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.width - iconButtonSize, y: 0, width:iconButtonSize, height: iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            return Button
        }()
        
        plusButton = {() -> UIButton in
            let Button = UIButton()
            
            Button.setImage(plusImage, for: .normal)
            Button.setImage(plusImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(onClickPlusButton(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.midX + iconButtonSize*1.5, y: speedsPosY, width:iconButtonSize, height: iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = true
            return Button
        }()
        
        plus10Button = {() -> UIButton in
            let Button = UIButton()
            
            Button.setImage(plus10Image, for: .normal)
            Button.setImage(plus10ImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(onClickPlus10Button(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.midX + iconButtonSize*2.5, y: speedsPosY, width:iconButtonSize, height: iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = true
            return Button
        }()
        
        minusButton = {() -> UIButton in
            let Button = UIButton()
            
            Button.setImage(minusImage, for: .normal)
            Button.setImage(minusImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(onClickMinusButton(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.midX - iconButtonSize*2.5, y: speedsPosY, width:iconButtonSize, height: iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = true
            return Button
        }()
        
        minus10Button = {() -> UIButton in
            let Button = UIButton()
            
            Button.setImage(minus10Image, for: .normal)
            Button.setImage(minus10ImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(onClickMinus10Button(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.midX - iconButtonSize*3.5, y: speedsPosY, width:iconButtonSize, height: iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = true
            return Button
        }()
        
        saveAndBackButton = {() -> UIButton in
            let Button = UIButton()
            
            Button.setImage(saveAndBackImage, for: .normal)
            Button.setImage(saveAndBackImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(onClickSaveAndBackButton(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.width*9.4/10, y: self.frame.height - iconButtonSize, width:iconButtonSize, height: iconButtonSize)//yは上からの座標
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
            
            Label.fontSize = iconButtonSize * 0.8
            Label.horizontalAlignmentMode = .center//中央寄せ
            Label.position = CGPoint(x:self.frame.midX, y:self.frame.height - speedsPosY - iconButtonSize*0.8)
            Label.fontColor = SKColor.black
            Label.isHidden = true
            //          Label.text = "設定画面"
            
            self.addChild(Label)
            return Label
        }()
        
        speedTitleLabel = {() -> SKLabelNode in
            let Label = SKLabelNode(fontNamed: "HiraginoSans-W6")
            
            Label.fontSize = iconButtonSize * 0.6
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
    
    @objc func onClickPlayButton(_ sender : UIButton){
        //消す
        hideMainContents()
        
        picker.resignFirstResponder()   //FirstResponderを放棄
        
        //移動
        let scene: GameScene
        if picker.textStore.suffix(9) == "(YouTube)"{
            var musicName = picker.textStore
            musicName.removeLast(9)
            
            //ネタバレ注意！
            if musicName == "オラシオン" &&
                (defaults.integer(forKey: Keys.speedRatioInt.rawValue) <= 21 ||
                defaults.integer(forKey: Keys.speedRatioInt.rawValue) >= 201) { musicName = "ウラシオン" }
            
            scene = GameScene(musicName:musicName, videoID: videoIDDictionary[musicName]!, size: (view?.bounds.size)!, speedRatioInt:UInt(defaults.integer(forKey: Keys.speedRatioInt.rawValue)))
        }else{
            scene = GameScene(musicName:picker.textStore ,size: (view?.bounds.size)!, speedRatioInt:UInt(defaults.integer(forKey: Keys.speedRatioInt.rawValue)))
        }
        
       
        
        
        let skView = view as SKView?    //このviewはGameViewControllerのskView2
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
