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
//    var randomSelectButton: UIButton!
    var settingButton:      UIButton!
    var autoPlaySwitch:     UISwitch!
    var youtubeSwitch:      UISwitch!
    var selectedMusicLabel: SKLabelNode!
    var autoPlayLabel:      SKLabelNode!  // "自動演奏"
    var youtubeLabel:       SKLabelNode!  // "YouTube"
    var difficultyLabel:    SKLabelNode!  // "地獄級"
    var mainButtons: [UIButton] {
        var contents: [UIButton] = []
        contents.append(playButton)
//        contents.append(randomSelectButton)
        contents.append(settingButton)
        return contents
    }
    var mainContents: [UIResponder] {
        
        var contents: [UIResponder] = []
        mainButtons.forEach({contents.append($0)})
        contents.append(autoPlaySwitch)
        contents.append(youtubeSwitch)
        contents.append(selectedMusicLabel)
        contents.append(autoPlayLabel)
        contents.append(youtubeLabel)
        contents.append(difficultyLabel)
        return contents
    }
    
    let settingImage             = UIImage(named: ImageName.setting.rawValue)
    let settingImageSelected     = UIImage(named: ImageName.settingSelected.rawValue)
    
    var setting = Setting.instance
    var headers: [Header] = []
    var selectedHeader: Header!
    let musicSelectSoundPlayer = MusicSelectSoundPlayer()
    var mp3FilesToDownload: [GTLRDrive_File] = []
    
    override func didMove(to view: SKView) {

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
        let selectedHeaderIndex = headers.firstIndex(where: { $0.title == setting.musicName }) ?? 0
        self.selectedHeader = headers[selectedHeaderIndex]
        self.musicPicker = MusicPicker(headers: headers, initialIndex: selectedHeaderIndex)
        self.musicPicker.mpDelegate = self
        self.musicPicker.didMove(to: view)
        
        
        /*--------- ボタンなどの設定 ---------*/
        // 初期画面のボタン
        playButton = {() -> UIButton in
            let button = UIButton()
            
            button.addTarget(self, action: #selector(didTapPlayButton(_:)), for: .touchUpInside)
            button.addTarget(self, action: #selector(onButton(_:)), for: .touchDown)
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
        
//        randomSelectButton = {() -> UIButton in
//            let button = UIButton()
//
//            button.addTarget(self, action: #selector(didTapRandomSelectButton(_:)), for: .touchUpInside)
//            button.addTarget(self, action: #selector(onButton(_:)), for: .touchDown)
//            button.addTarget(self, action: #selector(touchUpOutsideButton(_:)), for: .touchUpOutside)
//            button.frame = CGRect(x: 0,y: 0, width:self.frame.width/4, height: 60)
//            button.backgroundColor = UIColor.green
//            button.layer.masksToBounds = true
//            button.setTitle("おまかせ選曲", for: UIControl.State())
//            button.setTitleColor(UIColor.white, for: UIControl.State())
//            button.setTitleColor(UIColor.black, for: UIControl.State.highlighted)
//            button.isHidden = false
//            button.layer.cornerRadius = 20.0
//            button.layer.position = CGPoint(x: self.frame.midX + self.frame.width/3, y:self.frame.height*29/72 + Button.frame.height*1.2)
//            self.view?.addSubview(button)
//
//            return button
//        }()
        
        settingButton = {() -> UIButton in
            let button = UIButton()
            
            button.setImage(settingImage, for: .normal)
            button.setImage(settingImageSelected, for: .highlighted)
            button.addTarget(self, action: #selector(didTapSettingButton(_:)), for: .touchUpInside)
            button.addTarget(self, action: #selector(onButton(_:)), for: .touchDown)
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
    }
    
    override func update(_ currentTime: TimeInterval) {
        musicPicker.update()
    }

    func removeMainContents() {
        for content in mainContents {
            switch content {
            case let view     as UIView   : view.removeFromSuperview()
            case let node     as SKNode   : node.removeFromParent()
            case let uiswitch as UISwitch : uiswitch.removeFromSuperview()
            default: print("mainContentsの振り分け漏れ: \(content)")
            }
        }
    }
    
    func saveSetting() {
        setting.musicName = selectedHeader.title
        setting.isYouTube = youtubeSwitch.isOn
        setting.isAutoPlay = autoPlaySwitch.isOn
        setting.save()
    }

    override func willMove(from view: SKView) {
        saveSetting()
        // 消す
        removeMainContents()
        musicPicker.removeFromParent()
    }
    
    @objc func didTapPlayButton(_ sender : UIButton) {
        
        let dispatchGroup = DispatchGroup()
        // 直列キュー / attibutes指定なし
//        let dispatchQueue = DispatchQueue.main
        
        let moveToGameScene = {
            // 移動
            let scene = GameScene(size: (self.view?.bounds.size)!, header: self.selectedHeader)
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
    
//    @objc func didTapRandomSelectButton(_ sender : UIButton) {
//        if let pickerView = picker.inputView as? UIPickerView {
//            pickerView.selectRow(Int.random(in: 0..<picker.musicNameArray.count), inComponent: 0, animated: false)
//        } else {
//            print("ダウンキャスト失敗")
//        }
//    }
    
//    func showMainContents() {
//            for content in mainContents {
//                if let view = content as? UIControl {
//                    view.isHidden = false
//                    view.isEnabled = true
//                } else if let node = content as? SKNode {
//                    node.isHidden = false
//                } else if let uiswitch = content as? UISwitch {
//                    uiswitch.isHidden = true
//                } else {
//                    print("mainContentsの振り分け漏れ: \(content)")
//                }
//            }
//    }
//

    func moveToSettingScene() {
        // 移動
        let scene = SettingScene(size: size)
        let skView = self.view as SKView?    // このviewはGameViewControllerのskView2
        skView?.showsFPS = true
        skView?.showsNodeCount = true
        skView?.ignoresSiblingOrder = true
        scene.scaleMode = .resizeFill
        skView?.presentScene(scene)
    }

    @objc func didTapSettingButton(_ sender : UIButton) {
        
        moveToSettingScene()
    }

    // 同時押し対策
    @objc func onButton(_ sender : UIButton) {
        for button in mainButtons {
            guard button != sender else { continue }
            button.isEnabled = false
        }
    }
    
    @objc func touchUpOutsideButton(_ sender : UIButton) {
        mainButtons.forEach({$0.isEnabled = true})
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
        musicSelectSoundPlayer.play()

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
