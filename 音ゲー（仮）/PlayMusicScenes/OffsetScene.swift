//
// Created by Kohei Nakai on 2019-03-19.
// Copyright (c) 2019 NakaiKohei. All rights reserved.
//

import SpriteKit
import AVFoundation
import RealmSwift

class OffsetScene: PlayMusicScene {

    var plusButton  : UIButton!
    var minusButton : UIButton!
    var plus10Button  : UIButton!
    var minus10Button : UIButton!
    var offsetLabel : SKLabelNode!  // "+1"などmusic.offsetの値
    var buttons: [UIButton] {
        var buttons: [UIButton] = []
        buttons.append(plusButton)
        buttons.append(minusButton)
        buttons.append(plus10Button)
        buttons.append(minus10Button)
        return buttons
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        plusButton = {() -> UIButton in
            let button = UIButton()

            let plusImage         = UIImage(named: ImageName.plus.rawValue)
            let plusImageSelected = UIImage(named: ImageName.plusSelected.rawValue)

            button.setImage(plusImage, for: .normal)
            button.setImage(plusImageSelected, for: .highlighted)
            button.addTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)
            button.addTarget(self, action: #selector(onOffsetButton(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(touchUpOutsideOffsetButton(_:)), for: .touchUpOutside)
            button.frame = CGRect(x: self.frame.maxX - Dimensions.iconButtonSize*2.2, y: self.frame.midY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(button)
            button.isHidden = false
            return button
        }()
        minusButton = {() -> UIButton in
            let button = UIButton()

            let minusImage = UIImage(named: ImageName.minus.rawValue)
            let minusImageSelected = UIImage(named: ImageName.minusSelected.rawValue)

            button.setImage(minusImage, for: .normal)
            button.setImage(minusImageSelected, for: .highlighted)
            button.addTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)
            button.addTarget(self, action: #selector(onOffsetButton(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(touchUpOutsideOffsetButton(_:)), for: .touchUpOutside)
            button.frame = CGRect(x: Dimensions.iconButtonSize*1.5, y: self.frame.midY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(button)
            button.isHidden = false
            return button
        }()
        plus10Button = {() -> UIButton in
            let button = UIButton()
            
            let plusImage         = UIImage(named: ImageName.plus10.rawValue)
            let plusImageSelected = UIImage(named: ImageName.plus10Selected.rawValue)
            
            button.setImage(plusImage, for: .normal)
            button.setImage(plusImageSelected, for: .highlighted)
            button.addTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)
            button.addTarget(self, action: #selector(onOffsetButton(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(touchUpOutsideOffsetButton(_:)), for: .touchUpOutside)
            button.frame = CGRect(x: self.frame.maxX - Dimensions.iconButtonSize*1.2, y: self.frame.midY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(button)
            button.isHidden = false
            return button
        }()
        minus10Button = {() -> UIButton in
            let button = UIButton()
            
            let minusImage = UIImage(named: ImageName.minus10.rawValue)
            let minusImageSelected = UIImage(named: ImageName.minus10Selected.rawValue)
            
            button.setImage(minusImage, for: .normal)
            button.setImage(minusImageSelected, for: .highlighted)
            button.addTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)
            button.addTarget(self, action: #selector(onOffsetButton(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(touchUpOutsideOffsetButton(_:)), for: .touchUpOutside)
            button.frame = CGRect(x: Dimensions.iconButtonSize*0.5, y: self.frame.midY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(button)
            button.isHidden = false
            return button
        }()
        
        offsetLabel = {() -> SKLabelNode in
            let label = SKLabelNode(fontNamed: "HiraginoSans-W6")

            label.fontSize = self.frame.height/13
            label.horizontalAlignmentMode = .center //中央寄せ
            label.position = CGPoint(x:self.frame.midX, y:self.frame.height - label.fontSize*3/2)
            label.fontColor = SKColor.white
            label.isHidden = false
            label.text = setting.isYouTube ? String(music.youTubeOffset) : String(music.offset)

            self.addChild(label)
            return label
        }()
    }

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)

        autoJudgeAllLanes()
    }
    
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        
        buttons.forEach({ $0.removeFromSuperview() })
    }
    
    @objc func didTapButton(_ sender : UIButton) {
        
        do {
            let realm = try Realm()
            let results = realm.objects(Header.self)
            
            if let DBHeader = results.filter({ $0.bmsNameWithExtension == self.music.bmsNameWithExtension }).first { // db発見
                
                try! realm.write {
                    if setting.isYouTube {
                        switch sender {
                        case plusButton    : DBHeader.youTubeOffset += 1
                        case plus10Button  : DBHeader.youTubeOffset += 10
                        case minusButton   : DBHeader.youTubeOffset -= 1
                        case minus10Button : DBHeader.youTubeOffset -= 10
                        default: print("ボタン抜け@OffsetScene")
                        }
                        reloadSceneAsYouTubeMode()
                    } else {
                        switch sender {
                        case plusButton    : DBHeader.offset += 1
                        case plus10Button  : DBHeader.offset += 10
                        case minusButton   : DBHeader.offset -= 1
                        case minus10Button : DBHeader.offset -= 10
                        default: print("ボタン抜け@OffsetScene")
                        }
                        reloadSceneAsBGMMode()
                    }
                }
            } else {
                print("DBが見つかりませんでした")
                exit(1)
            }
        } catch {
            print(error)
            print("エラー終了")
            exit(1)
        }
    }

    // 同時押し対策
    @objc func onOffsetButton(_ sender : UIButton) {
        for button in buttons {
            guard button != sender else { continue }
            button.isEnabled = false
        }
    }
    
    @objc func touchUpOutsideOffsetButton(_ sender : UIButton) {
        buttons.forEach({ $0.isEnabled = true })
    }
    /// AVAudioPlayerの再生終了時の呼び出しメソッド
    override func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {    // playしたクラスと同じクラスに入れる必要あり？
        if player as AVAudioPlayer? == BGM {
            BGM = nil   // 別のシーンでアプリを再開したときに鳴るのを防止

            if setting.isYouTube { reloadSceneAsYouTubeMode() }
            else                 { reloadSceneAsBGMMode()     }
        }
    }
}
