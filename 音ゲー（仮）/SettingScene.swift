//
// Created by Kohei Nakai on 2019-03-22.
// Copyright (c) 2019 NakaiKohei. All rights reserved.
//

import SpriteKit

class SettingScene: SKScene {

    let setting = Setting.instance
    var speedsPosY: CGFloat!
    var sizesPosY:  CGFloat!

    // 設定画面のボタンなど
    var spPlusButton        : UIButton!
    var spPlus10Button      : UIButton!
    var spMinusButton       : UIButton!
    var spMinus10Button     : UIButton!
    var siPlusButton        : UIButton!
    var siPlus10Button      : UIButton!
    var siMinusButton       : UIButton!
    var siMinus10Button     : UIButton!
    var fitSizeToLaneSwitch : UISwitch!
    var saveAndBackButton   : UIButton!
    var settingLabel        : SKLabelNode!  // "設定画面"
    var speedLabel          : SKLabelNode!  // スピードの値（％）
    var speedTitleLabel     : SKLabelNode!  // "速さ"
    var noteSizeLabel       : SKLabelNode!  // ノーツの大きさの値((7レーン時のレーンに対する)%)
    var noteSizeTitleLabel  : SKLabelNode!  // "ノーツの大きさ"
    var fstlSwitchLabel     : SKLabelNode!  // "ノーツの大きさをレーン幅に合わせる"
    var settingContents: [UIResponder] {
        
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

    let plusImage                = UIImage(named: ImageName.plus.rawValue)
    let plusImageSelected        = UIImage(named: ImageName.plusSelected.rawValue)
    let minusImage               = UIImage(named: ImageName.minus.rawValue)
    let minusImageSelected       = UIImage(named: ImageName.minusSelected.rawValue)
    let plus10Image              = UIImage(named: ImageName.plus10.rawValue)
    let plus10ImageSelected      = UIImage(named: ImageName.plus10Selected.rawValue)
    let minus10Image             = UIImage(named: ImageName.minus10.rawValue)
    let minus10ImageSelected     = UIImage(named: ImageName.minus10Selected.rawValue)
    let saveAndBackImage         = UIImage(named: ImageName.saveAndBack.rawValue)
    let saveAndBackImageSelected = UIImage(named: ImageName.saveAndBackSelected.rawValue)

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        backgroundColor = .white

        speedsPosY = Dimensions.iconButtonSize*3
        sizesPosY  = speedsPosY*2

        // 設定画面のボタン
        spPlusButton = {() -> UIButton in
            let button = UIButton()

            button.setImage(plusImage, for: .normal)
            button.setImage(plusImageSelected, for: .highlighted)
            button.addTarget(self, action: #selector(didTapSPPlusButton(_:)), for: .touchUpInside)
            button.frame = CGRect(x: self.frame.midX + Dimensions.iconButtonSize*1.5, y: speedsPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(button)
            button.isHidden = false
            return button
        }()

        spPlus10Button = {() -> UIButton in
            let button = UIButton()

            button.setImage(plus10Image, for: .normal)
            button.setImage(plus10ImageSelected, for: .highlighted)
            button.addTarget(self, action: #selector(didTapSPPlus10Button(_:)), for: .touchUpInside)
            button.frame = CGRect(x: self.frame.midX + Dimensions.iconButtonSize*2.5, y: speedsPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(button)
            button.isHidden = false
            return button
        }()

        spMinusButton = {() -> UIButton in
            let button = UIButton()

            button.setImage(minusImage, for: .normal)
            button.setImage(minusImageSelected, for: .highlighted)
            button.addTarget(self, action: #selector(didTapSPMinusButton(_:)), for: .touchUpInside)
            button.frame = CGRect(x: self.frame.midX - Dimensions.iconButtonSize*2.5, y: speedsPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(button)
            button.isHidden = false
            return button
        }()

        spMinus10Button = {() -> UIButton in
            let button = UIButton()

            button.setImage(minus10Image, for: .normal)
            button.setImage(minus10ImageSelected, for: .highlighted)
            button.addTarget(self, action: #selector(didTapSPMinus10Button(_:)), for: .touchUpInside)
            button.frame = CGRect(x: self.frame.midX - Dimensions.iconButtonSize*3.5, y: speedsPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(button)
            button.isHidden = false
            return button
        }()

        siPlusButton = {() -> UIButton in
            let button = UIButton()

            button.setImage(plusImage, for: .normal)
            button.setImage(plusImageSelected, for: .highlighted)
            button.addTarget(self, action: #selector(didTapSIPlusButton(_:)), for: .touchUpInside)
            button.frame = CGRect(x: self.frame.midX + Dimensions.iconButtonSize*1.5, y: sizesPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(button)
            button.isHidden = false
            return button
        }()

        siPlus10Button = {() -> UIButton in
            let button = UIButton()

            button.setImage(plus10Image, for: .normal)
            button.setImage(plus10ImageSelected, for: .highlighted)
            button.addTarget(self, action: #selector(didTapSIPlus10Button(_:)), for: .touchUpInside)
            button.frame = CGRect(x: self.frame.midX + Dimensions.iconButtonSize*2.5, y: sizesPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(button)
            button.isHidden = false
            return button
        }()

        siMinusButton = {() -> UIButton in
            let button = UIButton()

            button.setImage(minusImage, for: .normal)
            button.setImage(minusImageSelected, for: .highlighted)
            button.addTarget(self, action: #selector(didTapSIMinusButton(_:)), for: .touchUpInside)
            button.frame = CGRect(x: self.frame.midX - Dimensions.iconButtonSize*2.5, y: sizesPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(button)
            button.isHidden = false
            return button
        }()

        siMinus10Button = {() -> UIButton in
            let button = UIButton()

            button.setImage(minus10Image, for: .normal)
            button.setImage(minus10ImageSelected, for: .highlighted)
            button.addTarget(self, action: #selector(didTapSIMinus10Button(_:)), for: .touchUpInside)
            button.frame = CGRect(x: self.frame.midX - Dimensions.iconButtonSize*3.5, y: sizesPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(button)
            button.isHidden = false
            return button
        }()

        saveAndBackButton = {() -> UIButton in
            let button = UIButton()

            button.setImage(saveAndBackImage, for: .normal)
            button.setImage(saveAndBackImageSelected, for: .highlighted)
            button.addTarget(self, action: #selector(didTapSaveAndBackButton(_:)), for: .touchUpInside)
            button.frame = CGRect(x: self.frame.width*9.4/10, y: self.frame.height - Dimensions.iconButtonSize, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(button)
            button.isHidden = false
            return button
        }()

        fitSizeToLaneSwitch = {() -> UISwitch in
            let swicth: UISwitch = UISwitch()
            swicth.layer.position = CGPoint(x: self.frame.midX + Dimensions.iconButtonSize*5.5, y: sizesPosY + Dimensions.iconButtonSize/2)
            swicth.tintColor = .black   // Swicthの枠線を表示する.
            swicth.isOn = setting.isFitSizeToLane
            swicth.addTarget(self, action: #selector(fitSizeToLaneSwitchChanged(_:)), for: .valueChanged)
            swicth.isHidden = false
            self.view?.addSubview(swicth)

            return swicth
        }()


        // ラベルの設定
        settingLabel = {() -> SKLabelNode in
            let label = SKLabelNode(fontNamed: "HiraginoSans-W6")

            label.fontSize = self.frame.height/13
            label.horizontalAlignmentMode = .center //中央寄せ
            label.position = CGPoint(x:self.frame.midX, y:self.frame.height - label.fontSize*3/2)
            label.fontColor = SKColor.black
            label.isHidden = false
            label.text = "設定画面"

            self.addChild(label)
            return label
        }()

        speedLabel = {() -> SKLabelNode in
            let label = SKLabelNode(fontNamed: "HiraginoSans-W6")

            label.fontSize = Dimensions.iconButtonSize * 0.8
            label.horizontalAlignmentMode = .center//中央寄せ
            label.position = CGPoint(x:self.frame.midX, y:self.frame.height - speedsPosY - Dimensions.iconButtonSize*0.8)
            label.fontColor = SKColor.black
            label.isHidden = false

            self.addChild(label)
            return label
        }()

        speedTitleLabel = {() -> SKLabelNode in
            let label = SKLabelNode(fontNamed: "HiraginoSans-W6")

            label.fontSize = Dimensions.iconButtonSize * 0.6
            label.horizontalAlignmentMode = .center //中央寄せ
            label.position = CGPoint(x:self.frame.midX, y:self.frame.height - speedsPosY)
            label.fontColor = SKColor.black
            label.isHidden = false
            label.text = "速さ"

            self.addChild(label)
            return label
        }()

        noteSizeLabel = {() -> SKLabelNode in
            let label = SKLabelNode(fontNamed: "HiraginoSans-W6")

            label.fontSize = Dimensions.iconButtonSize * 0.8
            label.horizontalAlignmentMode = .center  // 中央寄せ
            label.position = CGPoint(x:self.frame.midX, y:self.frame.height - sizesPosY - Dimensions.iconButtonSize*0.8)
            label.fontColor = SKColor.black
            label.isHidden = false

            self.addChild(label)
            return label
        }()

        noteSizeTitleLabel = {() -> SKLabelNode in
            let label = SKLabelNode(fontNamed: "HiraginoSans-W6")

            label.fontSize = Dimensions.iconButtonSize * 0.6
            label.horizontalAlignmentMode = .center  // 中央寄せ
            label.position = CGPoint(x:self.frame.midX, y:self.frame.height - sizesPosY)
            label.fontColor = SKColor.black
            label.isHidden = false
            label.text = "大きさ"

            self.addChild(label)
            return label
        }()

        fstlSwitchLabel = {() -> SKLabelNode in
            let label = SKLabelNode(fontNamed: "HiraginoSans-W6")

            label.fontSize = Dimensions.iconButtonSize * 0.3
            label.horizontalAlignmentMode = .center  // 中央寄せ
            label.position = CGPoint(x: self.frame.midX + Dimensions.iconButtonSize*5.5, y: self.frame.height - sizesPosY)
            label.fontColor = SKColor.black
            label.isHidden = false
            label.numberOfLines = 2
            label.text = "ノーツの大きさを\nレーン幅に合わせる"

            self.addChild(label)
            return label
        }()
    }

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)

        speedLabel.text = String(setting.speedRatioInt) + "%"
        noteSizeLabel.text = String(setting.scaleRatioInt) + "%"
    }

    func removeSettingContents() {

        for content in settingContents {
            
            switch content {
            case let view as UIView: view.removeFromSuperview()
            case let node as SKNode: node.removeFromParent()
            default: print("settingContentsの振り分け漏れ: \(content)")
            }
        }
    }

    override func willMove(from view: SKView) {
        super.willMove(from: view)
        removeSettingContents()
    }

    @objc func didTapSPPlusButton(_ sender : UIButton) {
        setting.speedRatioInt += 1
    }

    @objc func didTapSPPlus10Button(_ sender : UIButton) {
        setting.speedRatioInt += 10
    }

    @objc func didTapSPMinusButton(_ sender : UIButton) {
        if setting.speedRatioInt > 0 { setting.speedRatioInt -= 1 }
    }

    @objc func didTapSPMinus10Button(_ sender : UIButton) {
        if setting.speedRatioInt > 10 { setting.speedRatioInt -= 10 }
        else 			              { setting.speedRatioInt  =  0 }
    }

    @objc func didTapSIPlusButton(_ sender : UIButton) {
        setting.scaleRatioInt += 1
    }

    @objc func didTapSIPlus10Button(_ sender : UIButton) {
        setting.scaleRatioInt += 10
    }

    @objc func didTapSIMinusButton(_ sender : UIButton) {
        if setting.scaleRatioInt > 0 { setting.scaleRatioInt -= 1 }
    }

    @objc func didTapSIMinus10Button(_ sender : UIButton) {
        if setting.scaleRatioInt > 10 { setting.scaleRatioInt -= 10 }
        else                             { setting.scaleRatioInt  =  0 }
    }

    @objc func fitSizeToLaneSwitchChanged(_ sender: UISwitch) {
        setting.isFitSizeToLane = sender.isOn
    }

    func moveToChooseMusicScene() {
        // 移動
        let scene = ChooseMusicScene(size: size)
        let skView = self.view as SKView?    // このviewはGameViewControllerのskView2
        skView?.showsFPS = true
        skView?.showsNodeCount = true
        skView?.ignoresSiblingOrder = true
        scene.scaleMode = .resizeFill
        skView?.presentScene(scene)
    }

    @objc func didTapSaveAndBackButton(_ sender : UIButton) {
        setting.save()
        moveToChooseMusicScene()
    }
}
