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
        get {
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
            let Button = UIButton()

            Button.setImage(plusImage, for: .normal)
            Button.setImage(plusImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(didTapSPPlusButton(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.midX + Dimensions.iconButtonSize*1.5, y: speedsPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = false
            return Button
        }()

        spPlus10Button = {() -> UIButton in
            let Button = UIButton()

            Button.setImage(plus10Image, for: .normal)
            Button.setImage(plus10ImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(didTapSPPlus10Button(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.midX + Dimensions.iconButtonSize*2.5, y: speedsPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = false
            return Button
        }()

        spMinusButton = {() -> UIButton in
            let Button = UIButton()

            Button.setImage(minusImage, for: .normal)
            Button.setImage(minusImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(didTapSPMinusButton(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.midX - Dimensions.iconButtonSize*2.5, y: speedsPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = false
            return Button
        }()

        spMinus10Button = {() -> UIButton in
            let Button = UIButton()

            Button.setImage(minus10Image, for: .normal)
            Button.setImage(minus10ImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(didTapSPMinus10Button(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.midX - Dimensions.iconButtonSize*3.5, y: speedsPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = false
            return Button
        }()

        siPlusButton = {() -> UIButton in
            let Button = UIButton()

            Button.setImage(plusImage, for: .normal)
            Button.setImage(plusImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(didTapSIPlusButton(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.midX + Dimensions.iconButtonSize*1.5, y: sizesPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = false
            return Button
        }()

        siPlus10Button = {() -> UIButton in
            let Button = UIButton()

            Button.setImage(plus10Image, for: .normal)
            Button.setImage(plus10ImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(didTapSIPlus10Button(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.midX + Dimensions.iconButtonSize*2.5, y: sizesPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = false
            return Button
        }()

        siMinusButton = {() -> UIButton in
            let Button = UIButton()

            Button.setImage(minusImage, for: .normal)
            Button.setImage(minusImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(didTapSIMinusButton(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.midX - Dimensions.iconButtonSize*2.5, y: sizesPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = false
            return Button
        }()

        siMinus10Button = {() -> UIButton in
            let Button = UIButton()

            Button.setImage(minus10Image, for: .normal)
            Button.setImage(minus10ImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(didTapSIMinus10Button(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.midX - Dimensions.iconButtonSize*3.5, y: sizesPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = false
            return Button
        }()

        saveAndBackButton = {() -> UIButton in
            let Button = UIButton()

            Button.setImage(saveAndBackImage, for: .normal)
            Button.setImage(saveAndBackImageSelected, for: .highlighted)
            Button.addTarget(self, action: #selector(didTapSaveAndBackButton(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.width*9.4/10, y: self.frame.height - Dimensions.iconButtonSize, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)
            Button.isHidden = false
            return Button
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
            let Label = SKLabelNode(fontNamed: "HiraginoSans-W6")

            Label.fontSize = self.frame.height/13
            Label.horizontalAlignmentMode = .center //中央寄せ
            Label.position = CGPoint(x:self.frame.midX, y:self.frame.height - settingLabel.fontSize*3/2)
            Label.fontColor = SKColor.black
            Label.isHidden = false
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
            Label.isHidden = false

            self.addChild(Label)
            return Label
        }()

        speedTitleLabel = {() -> SKLabelNode in
            let Label = SKLabelNode(fontNamed: "HiraginoSans-W6")

            Label.fontSize = Dimensions.iconButtonSize * 0.6
            Label.horizontalAlignmentMode = .center //中央寄せ
            Label.position = CGPoint(x:self.frame.midX, y:self.frame.height - speedsPosY)
            Label.fontColor = SKColor.black
            Label.isHidden = false
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
            Label.isHidden = false

            self.addChild(Label)
            return Label
        }()

        noteSizeTitleLabel = {() -> SKLabelNode in
            let Label = SKLabelNode(fontNamed: "HiraginoSans-W6")

            Label.fontSize = Dimensions.iconButtonSize * 0.6
            Label.horizontalAlignmentMode = .center //中央寄せ
            Label.position = CGPoint(x:self.frame.midX, y:self.frame.height - sizesPosY)
            Label.fontColor = SKColor.black
            Label.isHidden = false
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
            Label.isHidden = false
            Label.numberOfLines = 2
            Label.text = "ノーツの大きさを\nレーン幅に合わせる"

            self.addChild(Label)
            return Label
        }()
    }

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)

        speedLabel.text = String(setting.speedRatioInt) + "%"
        noteSizeLabel.text = String(setting.scaleRatioInt) + "%"
    }

    func removeSettingContents() {

        for content in settingContents {
            if let view = content as? UIView {
                view.removeFromSuperview()
            } else if let node = content as? SKNode {
                node.removeFromParent()
            } else {
                print("settingContentsの振り分け漏れ: \(content)")
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
