//
//  ChooseSoundScene.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//

import SpriteKit
import GameplayKit
import RealmSwift
import GoogleAPIClientForREST

class ChooseMusicScene: SKScene {
    
    enum Difficulty: String {
        case cho           = "超級(4)"
        case jigoku        = "地獄級(5)"
        case chojigoku     = "超地獄級(6)"
        case zetujigoku    = "絶地獄級(7)"
        case chozetujigoku = "超絶地獄級(8)"
        case kaimetu       = "壊滅級(9)"
        case chokaimetu    = "超壊滅級(10)"
        
        static func getDifficulty(garupaPlayLevel: Int) -> Difficulty { // ガルパのレベルをこのゲームの難易度に変換（ミリシタとかは任せます）
            switch garupaPlayLevel {
            case 29:
                return Difficulty.kaimetu
            case 28:
                return Difficulty.chozetujigoku
            case 27:
                return Difficulty.zetujigoku
            case 26:
                return Difficulty.chojigoku
            case 25:
                return Difficulty.jigoku
            default:
                if garupaPlayLevel > 29 { return Difficulty.chokaimetu }
                else                    { return Difficulty.cho        }
            }
        }
    }
    
    var musicPicker: MusicPicker!

    // 初期画面のボタンなど
    var playButton:         UIButton!
    var settingButton:      UIButton!
    var autoPlaySwitch:     UISwitch!
    var youtubeSwitch:      UISwitch!
    var selectedMusicLabel: SKLabelNode!
    var autoPlayLabel:      SKLabelNode!  // "自動演奏"
    var youtubeLabel:       SKLabelNode!  // "YouTube"
    var difficultyLabel:    SKLabelNode!  // "地獄級"
    var mainContents: [UIResponder] {
        get {
            var contents: [UIResponder] = []
            contents.append(playButton)
            contents.append(settingButton)
            contents.append(autoPlaySwitch)
            contents.append(youtubeSwitch)
            contents.append(selectedMusicLabel)
            contents.append(autoPlayLabel)
            contents.append(youtubeLabel)
            contents.append(difficultyLabel)
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
    
    let settingImage             = UIImage(named: ImageName.setting.rawValue)
    let settingImageSelected     = UIImage(named: ImageName.settingSelected.rawValue)
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
    
    var speedsPosY: CGFloat!
    var sizesPosY:  CGFloat!
    
    var setting = Setting()
    var headers: [Header] = []
    var selectedHeader: Header!
    var mp3FilesToDownload: [GTLRDrive_File] = []
    
    override func didMove(to view: SKView) {
        
        speedsPosY = Dimensions.iconButtonSize * 3
        sizesPosY  = speedsPosY * 2
        
        backgroundColor = .white
        
        do {
            // クラウドストレージの更新確認(mp3)
            mp3FilesToDownload += GDFileManager.mp3FileList.filter { file in
                !file.isDownloaded() || file.isRenewed()
            }
            
            // Headerについて、/Library/Cachesのbmsファイル探索→db更新→読み込み
            let realm = try Realm()
            
//            try! realm.write {
//                realm.deleteAll()
//            }

            let results = realm.objects(Header.self)
            
            // fileに対応するdbが存在するか確認
            let directoryContents = try FileManager.default.contentsOfDirectory(atPath: GDFileManager.cachesDirectoty.path)
            let bmsNamesWithExtension = directoryContents.filter { $0.hasSuffix(".bms") }
            for fileName in bmsNamesWithExtension {

                if let DBHeader = results.filter({ $0.bmsNameWithExtension == fileName }).first { // ファイルに対応するdb発見

                    let filePath = GDFileManager.cachesDirectoty.appendingPathComponent(fileName).path
                    let attr = try FileManager.default.attributesOfItem(atPath: filePath)
                    let date = attr[FileAttributeKey.modificationDate] as! Date
                    let formatter = DateFormatter()
                    formatter.dateStyle = .full // longかmediumでもいいかも
                    formatter.timeStyle = .full
                    formatter.locale = Locale(identifier: "ja_JP")
                    
                    if formatter.string(from: date) != DBHeader.lastUpdateDate {            // ファイルの更新日とDB上の更新日を比較。異なればdbを更新
                        try! realm.write {   // (取り出されたものはmanaged objectなので。。。)
                            try DBHeader.setPropaties(fileName: fileName)                   // ファイルの更新日時が異なればdbを更新
                            print(fileName + "のDBを更新しました")
                        }
                    }
                    headers.append(DBHeader)
                    
                } else {
                    try headers.append(Header(fileName: fileName))                          // ファイルから新たなdbを作成&保存
                    print(fileName + "を追加しました")
                }
            }
            
        } catch {
            print(error)
            print("エラー終了")
            exit(1)
        }
        
        // ソート
        headers.sort(by: {
            if ($0.group == $1.group) { return $0.playLevel < $1.playLevel }
            return $0.group < $1.group
        })
        let selectedHeaderIndex = headers.firstIndex(where: { $0.title == setting.musicName })!
        self.selectedHeader = headers[selectedHeaderIndex]
        self.musicPicker = MusicPicker(headers: headers, initialIndex: selectedHeaderIndex)
        self.musicPicker.mpDelegate = self
        self.musicPicker.didMove(to: view)
        
        
        /*--------- ボタンなどの設定 ---------*/
        // 初期画面のボタン
        playButton = {() -> UIButton in
            let button = UIButton()
            
            button.addTarget(self, action: #selector(onClickPlayButton(_:)), for: .touchUpInside)
            button.addTarget(self, action: #selector(onPlayButton(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(touchUpOutsideButton(_:)), for: .touchUpOutside)
            button.frame = CGRect(x: 0,y: 0, width:self.frame.width/4, height: 60)
            button.backgroundColor = UIColor.red
            button.layer.masksToBounds = true
            button.setTitleColor(UIColor.white, for: UIControl.State())
            button.setTitleColor(UIColor.black, for: UIControl.State.highlighted)
            button.isHidden = false
            button.layer.cornerRadius = 20.0
            button.layer.position = CGPoint(x: self.frame.midX + self.frame.width/4, y: self.frame.height * 4/5)
            self.view?.addSubview(button)
            
            return button
        }()
        
        settingButton = {() -> UIButton in
            let button = UIButton()
            
            button.setImage(settingImage, for: .normal)
            button.setImage(settingImageSelected, for: .highlighted)
            button.addTarget(self, action: #selector(onClickSettingButton(_:)), for: .touchUpInside)
            button.addTarget(self, action: #selector(onSettingButton(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(touchUpOutsideButton(_:)), for: .touchUpOutside)
            button.frame = CGRect(x: self.frame.width - Dimensions.iconButtonSize,
                                  y: 0,
                                  width: Dimensions.iconButtonSize,
                                  height: Dimensions.iconButtonSize)  // yは上からの座標
            button.isHidden = false
            self.view?.addSubview(button)
            return button
        }()
        
        youtubeSwitch = {() -> UISwitch in
            let swicth: UISwitch = UISwitch()
            swicth.layer.position = CGPoint(x: self.frame.width * 4/5, y: self.frame.height * 1/2)
            swicth.tintColor = .black   // Swicthの枠線を表示する.
            swicth.isOn = setting.isYouTube
            swicth.addTarget(self, action: #selector(youTubeSwitchChanged(_:)), for: .valueChanged)
            self.view?.addSubview(swicth)
            
            return swicth
        }()
        
        autoPlaySwitch = {() -> UISwitch in
            let swicth: UISwitch = UISwitch()
            swicth.layer.position = CGPoint(x: self.frame.width * 4/5, y: self.frame.height * 1/2 + swicth.bounds.height * 1.5)
            swicth.tintColor = .black   // Swicthの枠線を表示する.
            swicth.isOn = setting.isAutoPlay
            swicth.addTarget(self, action: #selector(autoPlaySwitchChanged(_:)), for: .valueChanged)
            self.view?.addSubview(swicth)
            
            return swicth
        }()
        
        // スイッチの種類を示すラベル(スイッチに連動させるため、スイッチの設定後に行うこと)
        youtubeLabel = {() -> SKLabelNode in
            let label = SKLabelNode(fontNamed: "HiraginoSans-W6")
            
            label.fontSize = youtubeSwitch.bounds.height * 2/3
            label.horizontalAlignmentMode = .right // 右寄せ
            label.position = convertPoint(fromView: youtubeSwitch.layer.position)   // view形式の座標をscene形式に変換
            label.position.x -= youtubeSwitch.bounds.width/2
            label.position.y -= youtubeSwitch.bounds.height/5
            label.fontColor = SKColor.black
            label.text = "YouTube:"
            
            self.addChild(label)
            return label
        }()
        
        autoPlayLabel = {() -> SKLabelNode in
            let label = SKLabelNode(fontNamed: "HiraginoSans-W6")
            
            label.fontSize = autoPlaySwitch.bounds.height * 2/3
            label.horizontalAlignmentMode = .right // 右寄せ
            label.position = convertPoint(fromView: autoPlaySwitch.layer.position)
            label.position.x -= autoPlaySwitch.bounds.width/2
            label.position.y -= autoPlaySwitch.bounds.height/5
            label.fontColor = SKColor.black
            label.text = "自動演奏:"
            
            self.addChild(label)
            return label
        }()
        
        difficultyLabel = {() -> SKLabelNode in
            let label = SKLabelNode(fontNamed: "HiraginoSans-W6")
            
            label.fontSize = self.frame.height/10
            label.horizontalAlignmentMode = .center
            label.position = CGPoint(x: self.frame.width * 3/4, y: self.frame.height - label.fontSize * 3/2)
            label.fontColor = SKColor.green
            label.text = Difficulty.getDifficulty(garupaPlayLevel: selectedHeader.playLevel).rawValue
            
            self.addChild(label)
            return label
        }()
        
        selectedMusicLabel = {() -> SKLabelNode in
            let label = SKLabelNode(fontNamed: "HiraginoSans-W6")
            
            label.fontSize = self.frame.midX / CGFloat(selectedHeader.title.count)
            label.horizontalAlignmentMode = .center
            label.position = CGPoint(x: self.frame.width * 3/4, y: self.frame.height * 2/3)
            label.fontColor = SKColor.black
            label.text = selectedHeader.title
            
            self.addChild(label)
            return label
        }()
        
        // 設定画面のボタン
        spPlusButton = {() -> UIButton in
            let button = UIButton()
            
            button.setImage(plusImage, for: .normal)
            button.setImage(plusImageSelected, for: .highlighted)
            button.addTarget(self, action: #selector(onClickSPPlusButton(_:)), for: .touchUpInside)
            button.frame = CGRect(x: self.frame.midX + Dimensions.iconButtonSize*1.5, y: speedsPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(button)
            button.isHidden = true
            return button
        }()
        
        spPlus10Button = {() -> UIButton in
            let button = UIButton()
            
            button.setImage(plus10Image, for: .normal)
            button.setImage(plus10ImageSelected, for: .highlighted)
            button.addTarget(self, action: #selector(onClickSPPlus10Button(_:)), for: .touchUpInside)
            button.frame = CGRect(x: self.frame.midX + Dimensions.iconButtonSize*2.5, y: speedsPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(button)
            button.isHidden = true
            return button
        }()
        
        spMinusButton = {() -> UIButton in
            let button = UIButton()
            
            button.setImage(minusImage, for: .normal)
            button.setImage(minusImageSelected, for: .highlighted)
            button.addTarget(self, action: #selector(onClickSPMinusButton(_:)), for: .touchUpInside)
            button.frame = CGRect(x: self.frame.midX - Dimensions.iconButtonSize*2.5, y: speedsPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(button)
            button.isHidden = true
            return button
        }()
        
        spMinus10Button = {() -> UIButton in
            let button = UIButton()
            
            button.setImage(minus10Image, for: .normal)
            button.setImage(minus10ImageSelected, for: .highlighted)
            button.addTarget(self, action: #selector(onClickSPMinus10Button(_:)), for: .touchUpInside)
            button.frame = CGRect(x: self.frame.midX - Dimensions.iconButtonSize*3.5, y: speedsPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(button)
            button.isHidden = true
            return button
        }()
        
        siPlusButton = {() -> UIButton in
            let button = UIButton()
            
            button.setImage(plusImage, for: .normal)
            button.setImage(plusImageSelected, for: .highlighted)
            button.addTarget(self, action: #selector(onClickSIPlusButton(_:)), for: .touchUpInside)
            button.frame = CGRect(x: self.frame.midX + Dimensions.iconButtonSize*1.5, y: sizesPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(button)
            button.isHidden = true
            return button
        }()
        
        siPlus10Button = {() -> UIButton in
            let button = UIButton()
            
            button.setImage(plus10Image, for: .normal)
            button.setImage(plus10ImageSelected, for: .highlighted)
            button.addTarget(self, action: #selector(onClickSIPlus10Button(_:)), for: .touchUpInside)
            button.frame = CGRect(x: self.frame.midX + Dimensions.iconButtonSize*2.5, y: sizesPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(button)
            button.isHidden = true
            return button
        }()
        
        siMinusButton = {() -> UIButton in
            let button = UIButton()
            
            button.setImage(minusImage, for: .normal)
            button.setImage(minusImageSelected, for: .highlighted)
            button.addTarget(self, action: #selector(onClickSIMinusButton(_:)), for: .touchUpInside)
            button.frame = CGRect(x: self.frame.midX - Dimensions.iconButtonSize*2.5, y: sizesPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(button)
            button.isHidden = true
            return button
        }()
        
        siMinus10Button = {() -> UIButton in
            let button = UIButton()
            
            button.setImage(minus10Image, for: .normal)
            button.setImage(minus10ImageSelected, for: .highlighted)
            button.addTarget(self, action: #selector(onClickSIMinus10Button(_:)), for: .touchUpInside)
            button.frame = CGRect(x: self.frame.midX - Dimensions.iconButtonSize*3.5, y: sizesPosY, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(button)
            button.isHidden = true
            return button
        }()
        
        saveAndBackButton = {() -> UIButton in
            let button = UIButton()
            
            button.setImage(saveAndBackImage, for: .normal)
            button.setImage(saveAndBackImageSelected, for: .highlighted)
            button.addTarget(self, action: #selector(onClickSaveAndBackButton(_:)), for: .touchUpInside)
            button.frame = CGRect(x: self.frame.width*9.4/10, y: self.frame.height - Dimensions.iconButtonSize, width:Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(button)
            button.isHidden = true
            return button
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
            let label = SKLabelNode(fontNamed: "HiraginoSans-W6")
            
            label.fontSize = self.frame.height/13
            label.horizontalAlignmentMode = .center //中央寄せ
            label.position = CGPoint(x:self.frame.midX, y:self.frame.height - settingLabel.fontSize*3/2)
            label.fontColor = SKColor.black
            label.isHidden = true
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
            label.isHidden = true
            
            self.addChild(label)
            return label
        }()
        
        speedTitleLabel = {() -> SKLabelNode in
            let label = SKLabelNode(fontNamed: "HiraginoSans-W6")
            
            label.fontSize = Dimensions.iconButtonSize * 0.6
            label.horizontalAlignmentMode = .center //中央寄せ
            label.position = CGPoint(x:self.frame.midX, y:self.frame.height - speedsPosY)
            label.fontColor = SKColor.black
            label.isHidden = true
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
            label.isHidden = true
            
            self.addChild(label)
            return label
        }()
        
        noteSizeTitleLabel = {() -> SKLabelNode in
            let label = SKLabelNode(fontNamed: "HiraginoSans-W6")
            
            label.fontSize = Dimensions.iconButtonSize * 0.6
            label.horizontalAlignmentMode = .center  // 中央寄せ
            label.position = CGPoint(x:self.frame.midX, y:self.frame.height - sizesPosY)
            label.fontColor = SKColor.black
            label.isHidden = true
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
            label.isHidden = true
            label.numberOfLines = 2
            label.text = "ノーツの大きさを\nレーン幅に合わせる"
            
            self.addChild(label)
            return label
        }()
    }
    
    override func update(_ currentTime: TimeInterval) {
        musicPicker.update()
        
        speedLabel.text = String(setting.speedRatioInt) + "%"
        noteSizeLabel.text = String(setting.scaleRatioInt) + "%"
    }
    
    override func willMove(from view: SKView) {
        // 消す
        hideMainContents()
        musicPicker.removeFromParent()
//        picker.resignFirstResponder()   // FirstResponderを放棄
    }
    
    @objc func onClickPlayButton(_ sender : UIButton) {
        setting.musicName = selectedHeader.title
        setting.isYouTube = youtubeSwitch.isOn
        setting.isAutoPlay = autoPlaySwitch.isOn
        setting.save()
        
        let dispatchGroup = DispatchGroup()
        // 直列キュー / attibutes指定なし
//        let dispatchQueue = DispatchQueue.main
        
        let moveToGameScene = {
            // 移動
            let scene = GameScene(size: (self.view?.bounds.size)!, setting: self.setting, header: self.selectedHeader)
            let skView = self.view as SKView?    // このviewはGameViewControllerのskView2
            skView?.showsFPS = true
            skView?.showsNodeCount = true
            skView?.ignoresSiblingOrder = true
            scene.scaleMode = .resizeFill
            skView?.presentScene(scene)  // GameSceneに移動
        }
        
        if let mp3File = mp3FilesToDownload.first(where: {$0.name == selectedHeader.mp3FileName}) {  // ダウンロード
            dispatchGroup.enter()
            GDFileManager.getFileData(fileID: mp3File.identifier!, group: dispatchGroup)
            dispatchGroup.notify(queue: .main, execute: moveToGameScene)
        } else {
            moveToGameScene()
        }
    }
    
    func showMainContents() {
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
    
    func hideMainContents() {
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
    
    func showSettingContents() {
        
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
    
    @objc func onClickSettingButton(_ sender : UIButton) {
        
        hideMainContents()
        showSettingContents()
    }
    
    @objc func onClickSPPlusButton(_ sender : UIButton) {
        setting.speedRatioInt += 1
    }
    
    @objc func onClickSPPlus10Button(_ sender : UIButton) {
        setting.speedRatioInt += 10
    }
    
    @objc func onClickSPMinusButton(_ sender : UIButton) {
        if setting.speedRatioInt > 0 { setting.speedRatioInt -= 1 }
    }
    
    @objc func onClickSPMinus10Button(_ sender : UIButton) {
        if setting.speedRatioInt > 10 { setting.speedRatioInt -= 10 }
        else 			              { setting.speedRatioInt  =  0 }
    }
    
    @objc func onClickSIPlusButton(_ sender : UIButton) {
        setting.scaleRatioInt += 1
    }
    
    @objc func onClickSIPlus10Button(_ sender : UIButton) {
        setting.scaleRatioInt += 10
    }
    
    @objc func onClickSIMinusButton(_ sender : UIButton) {
        if setting.scaleRatioInt > 0 { setting.scaleRatioInt -= 1 }
    }
    
    @objc func onClickSIMinus10Button(_ sender : UIButton) {
        if setting.scaleRatioInt > 10 { setting.scaleRatioInt -= 10 }
        else                             { setting.scaleRatioInt  =  0 }
    }
    
    @objc func onClickSaveAndBackButton(_ sender : UIButton) {
        //保存
        setting.save()
        
        //消して表示
        hideSettingContents()
        showMainContents()
    }
    
    // 同時押し対策
    @objc func onSettingButton(_ sender : UIButton) {
        playButton.isEnabled = false
    }
    @objc func onPlayButton(_ sender : UIButton) {
        settingButton.isEnabled = false
    }
    @objc func touchUpOutsideButton(_ sender : UIButton) {
        playButton.isEnabled = true
        settingButton.isEnabled = true
    }
    
    // switch
    @objc func youTubeSwitchChanged(_ sender: UISwitch) {
        setting.isYouTube = sender.isOn
    }
    @objc func autoPlaySwitchChanged(_ sender: UISwitch) {
        setting.isAutoPlay = sender.isOn
    }
    @objc func fitSizeToLaneSwitchChanged(_ sender: UISwitch) {
        setting.isFitSizeToLane = sender.isOn
    }
}


extension ChooseMusicScene: MusicPickerDelegate {
    func selectedMusicDidChange(to selectedHeader: Header) {
        self.selectedHeader = selectedHeader

        difficultyLabel.text = Difficulty.getDifficulty(garupaPlayLevel: selectedHeader.playLevel).rawValue
        selectedMusicLabel.text = selectedHeader.title
        selectedMusicLabel.fontSize = self.frame.midX / CGFloat(selectedHeader.title.count)

        if selectedHeader.videoID.isEmpty && selectedHeader.videoID2.isEmpty {
            youtubeSwitch.isOn = false
            youtubeSwitch.isEnabled = false
        } else {
            youtubeSwitch.isOn = setting.isYouTube
            youtubeSwitch.isEnabled = true
        }

        let title: String = {
            if mp3FilesToDownload.contains(where: { $0.name == selectedHeader.mp3FileName }) {
                return "ダウンロード\nして遊ぶ"
            } else {
                return "この曲で遊ぶ"
            }
        }()
        playButton.titleLabel?.numberOfLines = 2
        playButton.setTitle(title, for: UIControl.State())
        playButton.setTitle(title, for: UIControl.State.highlighted)
    }
}
