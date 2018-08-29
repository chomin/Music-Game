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
    
    // 初期画面のボタンなど
    var picker: PickerKeyboard!
    var playButton     = UIButton()
    var settingButton  = UIButton()
    var autoPlaySwitch = UISwitch()
    var YouTubeSwitch  = UISwitch()
    var autoPlayLabel  = SKLabelNode(fontNamed: "HiraginoSans-W6")  // "自動演奏"
    var YouTubeLabel   = SKLabelNode(fontNamed: "HiraginoSans-W6")  // "YouTube"
    
    var mainContents: [UIResponder] {
        get{
            var contents: [UIResponder] = []
            contents.append(picker)
            contents.append(playButton)
            contents.append(settingButton)
            contents.append(autoPlaySwitch)
            contents.append(YouTubeSwitch)
            contents.append(autoPlayLabel)
            contents.append(YouTubeLabel)
            return contents
        }
    }
    
    // 設定画面のボタンなど
    var spPlusButton        = UIButton()
    var spPlus10Button      = UIButton()
    var spMinusButton       = UIButton()
    var spMinus10Button     = UIButton()
    var siPlusButton        = UIButton()
    var siPlus10Button      = UIButton()
    var siMinusButton       = UIButton()
    var siMinus10Button     = UIButton()
    var fitSizeToLaneSwitch = UISwitch()
    var saveAndBackButton   = UIButton()
    var settingLabel        = SKLabelNode(fontNamed: "HiraginoSans-W6")  // "設定画面"
    var speedLabel          = SKLabelNode(fontNamed: "HiraginoSans-W6")  // スピードの値（％）
    var speedTitleLabel     = SKLabelNode(fontNamed: "HiraginoSans-W6")  // "速さ"
    var noteSizeLabel       = SKLabelNode(fontNamed: "HiraginoSans-W6")  // ノーツの大きさの値((7レーン時のレーンに対する)%)
    var noteSizeTitleLabel  = SKLabelNode(fontNamed: "HiraginoSans-W6")  // "ノーツの大きさ"
    var fstlSwitchLabel     = SKLabelNode(fontNamed: "HiraginoSans-W6")  // "ノーツの大きさをレーン幅に合わせる"
    var settingContents: [UIResponder] {
        get{
            var contents: [UIResponder] = []
            contents.append(spPlusButton)
            contents.append(spPlus10Button)
            contents.append(spMinusButton)
            contents.append(spMinus10Button)
            contents.append(siPlusButton)
            contents.append(siPlus10Button)
            contents.append(siMinusButton)
            contents.append(siMinus10Button)
            contents.append(fitSizeToLaneSwitch)
            contents.append(saveAndBackButton)
            contents.append(settingLabel)
            contents.append(speedLabel)
            contents.append(speedTitleLabel)
            contents.append(noteSizeLabel)
            contents.append(noteSizeTitleLabel)
            contents.append(fstlSwitchLabel)
            
            return contents
        }
    }
    
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
    
    var speedsPosY:CGFloat!
    var sizesPosY:CGFloat!
    
    var setting = Setting()
    var musics: [Music] = []
    
    override func didMove(to view: SKView) {
        
        speedsPosY = Dimensions.iconButtonSize*3
        sizesPosY  = speedsPosY*2
        
        backgroundColor = .white
        
        // ピッカーキーボードの設置
        let rect = CGRect(origin:CGPoint(x:self.frame.midX - self.frame.width/6,y:self.frame.height/3) ,size:CGSize(width:self.frame.width/3 ,height:50))
        picker = PickerKeyboard(frame: rect, firstText: setting.musicName.rawValue)
        picker.backgroundColor = .gray
        picker.isHidden = false
        picker.addTarget(self, action: #selector(pickerChanged(_:)), for: .valueChanged)
        
        self.view?.addSubview(picker!)
        
        // 将来的にはファイル探索から
        for musicStr in picker.musicNameArray {
            do {
                try musics.append(Reader.readHeadContents(fileName: musicStr + ".bms"))
            } catch {
                print(error)
            }
            
        }
        
        
        /*--------- ボタンなどの設定 ---------*/
        // 初期画面のボタン
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

            Button.frame = CGRect(x: self.frame.width - Dimensions.iconButtonSize, y: 0, width: Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)// yは上からの座標
            Button.isHidden = false
            self.view?.addSubview(Button)
            return Button
        }()
        
        YouTubeSwitch = {() -> UISwitch in
            let swicth: UISwitch = UISwitch()
            swicth.layer.position = CGPoint(x: self.frame.width/4, y: self.frame.height/3)
            swicth.tintColor = .black   // Swicthの枠線を表示する.
            swicth.isOn = setting.isYouTube
            swicth.addTarget(self, action: #selector(youTubeSwitchChanged(_:)), for: .valueChanged)
            self.view?.addSubview(swicth)
            
            return swicth
        }()
        
        autoPlaySwitch = {() -> UISwitch in
            let swicth: UISwitch = UISwitch()
            swicth.layer.position = CGPoint(x: self.frame.width/4, y: self.frame.height/3 + swicth.bounds.height*1.5)
            swicth.tintColor = .black   // Swicthの枠線を表示する.
            swicth.isOn = setting.isAutoPlay
            swicth.addTarget(self, action: #selector(autoPlaySwitchChanged(_:)), for: .valueChanged)
            self.view?.addSubview(swicth)
            
            return swicth
        }()
        
        // スイッチの種類を示すラベル(スイッチに連動させるため、スイッチの設定後に行うこと)
        YouTubeLabel = {() -> SKLabelNode in
            let Label = SKLabelNode(fontNamed: "HiraginoSans-W6")
            
            Label.fontSize = YouTubeSwitch.bounds.height*2/3
            Label.horizontalAlignmentMode = .right // 右寄せ
            Label.position = convertPoint(fromView: YouTubeSwitch.layer.position)   // view形式の座標をscene形式に変換
            Label.position.x -= YouTubeSwitch.bounds.width/2
            Label.position.y -= YouTubeSwitch.bounds.height/5
            Label.fontColor = SKColor.black
            Label.text = "YouTube:"
            
            self.addChild(Label)
            return Label
        }()
        
        autoPlayLabel = {() -> SKLabelNode in
            let Label = SKLabelNode(fontNamed: "HiraginoSans-W6")
            
            Label.fontSize = autoPlaySwitch.bounds.height*2/3
            Label.horizontalAlignmentMode = .right // 右寄せ
            Label.position = convertPoint(fromView: autoPlaySwitch.layer.position)
            Label.position.x -= autoPlaySwitch.bounds.width/2
            Label.position.y -= autoPlaySwitch.bounds.height/5
            Label.fontColor = SKColor.black
            Label.text = "自動演奏:"
            
            self.addChild(Label)
            return Label
        }()
        
        // 設定画面のボタン
        spPlusButton = {() -> UIButton in
            let Button = UIButton()
            
            Button.setImage(plusImage, for: .normal)
            Button.setImage(plusImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(onClickSPPlusButton(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.midX + Dimensions.iconButtonSize*1.5, y: speedsPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = true
            return Button
        }()
        
        spPlus10Button = {() -> UIButton in
            let Button = UIButton()
            
            Button.setImage(plus10Image, for: .normal)
            Button.setImage(plus10ImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(onClickSPPlus10Button(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.midX + Dimensions.iconButtonSize*2.5, y: speedsPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = true
            return Button
        }()
        
        spMinusButton = {() -> UIButton in
            let Button = UIButton()
            
            Button.setImage(minusImage, for: .normal)
            Button.setImage(minusImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(onClickSPMinusButton(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.midX - Dimensions.iconButtonSize*2.5, y: speedsPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = true
            return Button
        }()
        
        spMinus10Button = {() -> UIButton in
            let Button = UIButton()
            
            Button.setImage(minus10Image, for: .normal)
            Button.setImage(minus10ImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(onClickSPMinus10Button(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.midX - Dimensions.iconButtonSize*3.5, y: speedsPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = true
            return Button
        }()
        
        siPlusButton = {() -> UIButton in
            let Button = UIButton()

            Button.setImage(plusImage, for: .normal)
            Button.setImage(plusImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(onClickSIPlusButton(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.midX + Dimensions.iconButtonSize*1.5, y: sizesPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = true
            return Button
        }()

        siPlus10Button = {() -> UIButton in
            let Button = UIButton()

            Button.setImage(plus10Image, for: .normal)
            Button.setImage(plus10ImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(onClickSIPlus10Button(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.midX + Dimensions.iconButtonSize*2.5, y: sizesPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = true
            return Button
        }()

        siMinusButton = {() -> UIButton in
            let Button = UIButton()

            Button.setImage(minusImage, for: .normal)
            Button.setImage(minusImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(onClickSIMinusButton(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.midX - Dimensions.iconButtonSize*2.5, y: sizesPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = true
            return Button
        }()

        siMinus10Button = {() -> UIButton in
            let Button = UIButton()

            Button.setImage(minus10Image, for: .normal)
            Button.setImage(minus10ImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(onClickSIMinus10Button(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.midX - Dimensions.iconButtonSize*3.5, y: sizesPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
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
        
        fitSizeToLaneSwitch = {() -> UISwitch in
            let swicth: UISwitch = UISwitch()
            swicth.layer.position = CGPoint(x: self.frame.midX + Dimensions.iconButtonSize*5.5, y: sizesPosY + Dimensions.iconButtonSize/2)
            swicth.tintColor = .black   // Swicthの枠線を表示する.
            swicth.isOn = setting.isFitSizeToLane
            swicth.addTarget(self, action: #selector(fitSizeToLaneSwitchChanged(_:)), for: .valueChanged)
            swicth.isHidden = true
            self.view?.addSubview(swicth)
            
            return swicth
        }()
        
        
        // ラベルの設定
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
        
        noteSizeLabel = {() -> SKLabelNode in
            let Label = SKLabelNode(fontNamed: "HiraginoSans-W6")
            
            Label.fontSize = Dimensions.iconButtonSize * 0.8
            Label.horizontalAlignmentMode = .center//中央寄せ
            Label.position = CGPoint(x:self.frame.midX, y:self.frame.height - sizesPosY - Dimensions.iconButtonSize*0.8)
            Label.fontColor = SKColor.black
            Label.isHidden = true
            
            self.addChild(Label)
            return Label
        }()
        
        noteSizeTitleLabel = {() -> SKLabelNode in
            let Label = SKLabelNode(fontNamed: "HiraginoSans-W6")
            
            Label.fontSize = Dimensions.iconButtonSize * 0.6
            Label.horizontalAlignmentMode = .center //中央寄せ
            Label.position = CGPoint(x:self.frame.midX, y:self.frame.height - sizesPosY)
            Label.fontColor = SKColor.black
            Label.isHidden = true
            Label.text = "大きさ"
            
            self.addChild(Label)
            return Label
        }()
        
        fstlSwitchLabel = {() -> SKLabelNode in
            let Label = SKLabelNode(fontNamed: "HiraginoSans-W6")
            
            Label.fontSize = Dimensions.iconButtonSize * 0.3
            Label.horizontalAlignmentMode = .center //中央寄せ
            Label.position = CGPoint(x:self.frame.midX + Dimensions.iconButtonSize*5.5, y:self.frame.height - sizesPosY)
            Label.fontColor = SKColor.black
            Label.isHidden = true
            Label.numberOfLines = 2
            Label.text = "ノーツの大きさを\nレーン幅に合わせる"
            
            self.addChild(Label)
            return Label
        }()
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        speedLabel.text = String(setting.speedRatioInt) + "%"
        noteSizeLabel.text = String(setting.scaleRatioInt) + "%"
        
//        self.view?.addSubview(settingButton)
    }
    
    override func willMove(from view: SKView) {
        // 消す
        hideMainContents()
        picker.resignFirstResponder()   // FirstResponderを放棄
    }
    
    @objc func onClickPlayButton(_ sender : UIButton) {
        
        setting.musicName = MusicName(rawValue: picker.textStore)!
        setting.save()
        
        // 移動
        let scene = GameScene(size: (view?.bounds.size)!, setting: setting)
//        if YouTubeSwitch.isOn {
        
//            if picker.textStore == "オラシオン" &&
//                (setting.speedRatioInt <= 21 || setting.speedRatioInt >= 201 ) { setting.playMode = .YouTube2 /* 裏シオン */ }
            
//            scene = GameScene(size: (view?.bounds.size)!)
//        }else{
//            print(picker.textStore)
//            scene = GameScene(musicName: MusicName(rawValue: picker.textStore)! , playMode: .BGM , isAutoPlay: autoPlaySwitch.isOn, size: (view?.bounds.size)!, speedRatioInt:UInt(defaults.integer(forKey: Keys.userSpeedRatioInt.rawValue)))
//        }
        
        let skView = view as SKView?    // このviewはGameViewControllerのskView2
        skView?.showsFPS = true
        skView?.showsNodeCount = true
        skView?.ignoresSiblingOrder = true
        scene.scaleMode = .resizeFill
        skView?.presentScene(scene)  // GameSceneに移動
        
        
    }
    
    func showMainContents(){
        for content in mainContents {
            if let view = content as? UIControl {
                view.isHidden = false
                view.isEnabled = true
            } else if let node = content as? SKNode {
                node.isHidden = false
            } else if let uiswitch = content as? UISwitch {
                uiswitch.isHidden = true
            } else {
                print("mainContentsの振り分け漏れ: \(content)")
            }
        }
    }
    
    func hideMainContents(){
        for content in mainContents {
            if let view = content as? UIView {
                view.isHidden = true
            } else if let node = content as? SKNode {
                node.isHidden = true
            } else if let uiswitch = content as? UISwitch {
                uiswitch.isHidden = true
            } else {
                print("mainContentsの振り分け漏れ: \(content)")
            }
        }
    }
    
    func showSettingContents(){
        
        for content in settingContents {
            if let view = content as? UIView {
                view.isHidden = false
            } else if let node = content as? SKNode {
                node.isHidden = false
            } else {
                print("settingContentsの振り分け漏れ: \(content)")
            }
        }
        
        
       
    }
    
    func hideSettingContents() {
        
        for content in settingContents {
            if let view = content as? UIView {
                view.isHidden = true
            } else if let node = content as? SKNode {
                node.isHidden = true
            } else {
                print("settingContentsの振り分け漏れ: \(content)")
            }
        }
    }
    
    @objc func onClickSettingButton(_ sender : UIButton){
        
        hideMainContents()
        showSettingContents()
    }
    
    @objc func onClickSPPlusButton(_ sender : UIButton){
        setting.speedRatioInt += 1
    }
    
    @objc func onClickSPPlus10Button(_ sender : UIButton){
        setting.speedRatioInt += 10
    }
    
    @objc func onClickSPMinusButton(_ sender : UIButton){
        if setting.speedRatioInt > 0 { setting.speedRatioInt -= 1 }
    }
    
    @objc func onClickSPMinus10Button(_ sender : UIButton){
        if setting.speedRatioInt > 10 { setting.speedRatioInt -= 10 }
        else 			              { setting.speedRatioInt  =  0 }
    }
    
    @objc func onClickSIPlusButton(_ sender : UIButton){
        setting.scaleRatioInt += 1
    }
    
    @objc func onClickSIPlus10Button(_ sender : UIButton){
        setting.scaleRatioInt += 10
    }
    
    @objc func onClickSIMinusButton(_ sender : UIButton){
        if setting.scaleRatioInt > 0 { setting.scaleRatioInt -= 1 }
    }
    
    @objc func onClickSIMinus10Button(_ sender : UIButton){
        if setting.scaleRatioInt > 10 { setting.scaleRatioInt -= 10 }
        else                             { setting.scaleRatioInt  =  0 }
    }
    
    @objc func onClickSaveAndBackButton(_ sender : UIButton){
        //保存
        setting.save()
        
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
    
    // switch
    @objc func youTubeSwitchChanged(_ sender: UISwitch){
        setting.isYouTube = sender.isOn
    }
    @objc func autoPlaySwitchChanged(_ sender: UISwitch){
        setting.isAutoPlay = sender.isOn
    }
    @objc func fitSizeToLaneSwitchChanged(_ sender: UISwitch){
        setting.isFitSizeToLane = sender.isOn
    }
    
    // picker
    @objc func pickerChanged(_ sender: PickerKeyboard){
        setting.musicName = MusicName(rawValue: sender.textStore)!
    }
    
    
}
