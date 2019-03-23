//
// Created by Kohei Nakai on 2019-03-19.
// Copyright (c) 2019 NakaiKohei. All rights reserved.
//

import AVFoundation
import SpriteKit
import youtube_ios_player_helper_swift    // 今後、これを利用するために.xcodeprojではなく、.xcworkspaceを開いて編集すること

/// 同時押し線の画像情報
class SameLine {
    unowned var note1: Note
    unowned var note2: Note
    var line: SKShapeNode

    init(note1: Note, note2: Note, line: SKShapeNode) {
        self.note1 = note1
        self.note2 = note2
        self.line = line
    }

    deinit {
        self.line.removeFromParent()
    }
}

/// GameScene, AutoPlayScene, OffsetSceneの親クラス。曲、YouTube、譜面の再生をサポートする。
class PlayMusicScene: SKScene, AVAudioPlayerDelegate, YTPlayerViewDelegate, GSAppDelegate {

    // appの起動、終了等に関するデリゲート
    var appDelegate: AppDelegate!

    let playMode: PlayMode

    // ラベル
    var judgeLabel = SKLabelNode(fontNamed: "HiraginoSans-W6")
    var comboLabel = SKLabelNode(fontNamed: "HiraginoSans-W6")
    let JLScale: CGFloat = 1.25  // 拡大縮小アニメーションの倍率

    // ボタン
    var pauseButton           : UIButton!
    var returnButton          : UIButton!
    var continueButton        : UIButton!
    var switchIsYouTubeButton : UIButton!
    var pauseViewButtons: [UIButton] {
        var buttons: [UIButton] = []
        buttons.append(returnButton)
        buttons.append(continueButton)
        buttons.append(switchIsYouTubeButton)
        return buttons
    }

    // ポーズ時のview
    var pauseView: UIView?

    // 音楽プレイヤー
    var BGM: AVAudioPlayer!
    let actionSoundSet = ActionSoundPlayers()

    // YouTubeプレイヤー
    var playerView : YTPlayerViewHolder!
    var isPrecedingStartValid = true    // YouTubeモードの時、再生開始前にノーツを流すかどうか
    enum YTLaunchState {
        case loading, initialPaused, tryingToPlay, done
    }
    var ytLaunchState = YTLaunchState.loading
    var isSupposedToPausePlayerView = false     // ポーズ予約

    // 画像(ノーツ以外)
    var judgeLine: SKShapeNode!
    var sameLines: [SameLine] = []  // 連動する始点側のノーツと同時押しライン

    // 楽曲データ
    let music: Music
    var notes: [Note] = []      // ノーツの" 始 点 "の集合。
    var BPMs: [(bpm: Double, startPos: Double)] {
        return self.music.BPMs
    }

    private var startTime: TimeInterval = 0.0       // 譜面再生開始時刻
    var passedTime: TimeInterval = 0.0              // 経過時間
    private var mediaOffsetTime: TimeInterval = 0.0 // 経過時間と、BGM.currentTimeまたはplayerView.currentTime()のずれ + (Header.offsetまたはyouTubeoffset)*headerOffsetUnit。一定
    private let headerOffsetUnit = 0.01
    var lanes: [Lane] = []      // レーン

    var setting: Setting
    var result = Result()

    init(size: CGSize, setting: Setting, header: Header) {

        self.playMode = setting.playMode
        self.setting = setting
        self.music = Music(header: header, playMode: setting.playMode)

        super.init(size: size)
    }
    init(size: CGSize, setting: Setting, music: Music) {

        self.playMode = setting.playMode
        self.setting = setting
        self.music = music

        super.init(size: size)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 受け取ったLaneの先頭ノーツを判定する。失敗したらfalseを返す。引数でtimeLagを渡すのは（judge呼び出し時ではなく）タッチされた時のものを使用するため。
    ///受け取ったLaneの先頭ノーツを判定する。
    ///
    /// - Parameters:
    ///   - lane: 判定対象のレーン
    ///   - timeLag: 判定したいノーツの正しい時間と実際に叩かれた時間との差。（judge呼び出し時ではなく）タッチされた時のものを使用する。
    ///   - gsTouch: ノーツを叩いたGSTouchインスタンス。GameSceneから解放されていたらnilを入れること。
    /// - Returns: 成否をBoolで返す
    func judge(lane: Lane, timeLag: TimeInterval, gsTouch: GSTouch?) -> Bool {
        
        guard !(lane.isEmpty),
            lane.isJudgeRange else {
                print("laneが空、あるいは判定時間圏内にノーツがありません. laneIndex: \(lane.laneIndex)")
                return false
        }
        
        guard lane.headNote!.isJudgeable else {
            print("判定対象ノーツ.isJudgeableがfalseです. laneIndex: \(lane.laneIndex)")
            return false
        }
        
        // 以下は判定が確定しているものとする
        
        // 音を鳴らす
        switch lane.headNote! {
        case is Flick, is FlickEnd          : self.actionSoundSet.play(type: .flick)
        case is Middle                      : self.actionSoundSet.play(type: .middle)
        case is Tap, is TapStart, is TapEnd : self.actionSoundSet.play(type: .tap)
        default                             : print("ノーツの型の見落とし")
        }
        
        // 必要ならgsTouch関係の処理
        switch lane.headNote! {
        case is Flick, is FlickEnd:
            gsTouch?.isJudgeableFlick = false    // このタッチでのフリック判定を禁止
            gsTouch?.isJudgeableFlickEnd = false
            
            // storedFlickJudgeに関する処理
            gsTouch?.storedFlickJudgeLaneIndex = nil
            lane.storedFlickJudgeInformation = nil
            
        case is Tap:
            gsTouch?.isJudgeableFlick = false
            gsTouch?.isJudgeableFlickEnd = false
            
        case is TapStart, is Middle:
            gsTouch?.isJudgeableFlick = false
            gsTouch?.isJudgeableFlickEnd = true
            
        default: break
        }
        
        let judgeTimeState = lane.getJudgeTimeState(timeLag: timeLag)
        setJudgeLabelText(judgeType: judgeTimeState)
        result.countUp(judgeType: judgeTimeState)
        lane.setHeadNoteJudged()
        return true
    }

    func autoJudgeAllLanes() {
        for lane in lanes {
            if lane.timeLag <= 0 && !(lane.isEmpty) {
                if !(judge(lane: lane, timeLag: 0, gsTouch: nil)) { print("判定失敗@自動演奏") }
            }
        }
    }

    override func didMove(to view: SKView) {

        appDelegate = (UIApplication.shared.delegate as! AppDelegate) // AppDelegateのインスタンスを取得
        appDelegate.gsDelegate = self   // 子(AppDelegate)の設定しているdelegateに自身をセット

        self.view?.isMultipleTouchEnabled = true    // 恐らくデフォルトではfalseになってる
        self.view?.superview?.isMultipleTouchEnabled = true

        // 寸法に関するレーン数依存の定数をセット
        Dimensions.updateInstance(laneNum: music.laneNum)

        // Laneインスタンスを作成
        for i in 0..<self.music.laneNum {
            self.lanes.append(Lane(laneIndex: i))
        }

        // BGMまたはYouTubeのプレイヤーを作成
        switch playMode {
        case .BGM:
            // サウンドファイルのURLを生成
            let soundURL: URL = {
                if music.group != "BDGP" { return GDFileManager.cachesDirectoty.appendingPathComponent("\(music.title).mp3") }  // m4a,oggは不可
                else                     {
                    var mp3FileName = music.title
                    let startIndex = mp3FileName.index(after:  mp3FileName.lastIndex(of: "(")!)
                    let lastIndex  = mp3FileName.index(before: mp3FileName.lastIndex(of: ")")!)
                    mp3FileName.removeSubrange(startIndex ... lastIndex)                            // "曲名()"になる
                    let insertIndex = mp3FileName.index(after:  mp3FileName.lastIndex(of: "(")!)
                    mp3FileName.insert(contentsOf: "BDGP", at: insertIndex)
                    return GDFileManager.cachesDirectoty.appendingPathComponent("\(mp3FileName).mp3")
                }
            }()

            // AVAudioPlayerのインスタンスを作成
            do {
                BGM = try AVAudioPlayer(contentsOf: soundURL, fileTypeHint: "public.mp3")
            } catch {
                print("AVAudioPlayerインスタンス作成失敗")
                exit(1)
            }
            // バッファに保持していつでも再生できるようにする
            BGM.prepareToPlay()

        case .YouTube, .YouTube2:

            self.playerView = YTPlayerViewHolder(frame: self.frame)
            // 詳しい使い方はJump to Definitionへ
            if !(self.playerView.load(withVideoId: music.videoID, playerVars: ["autoplay": 1, "controls": 0, "playsinline": 1, "rel": 0, "showinfo": 0])) {
                print("ロードに失敗")

                reloadSceneAsBGMMode()
                return
            }
        }

        // Noteクラスのクラスプロパティを設定
        let duration = (playMode == .BGM) ? BGM.duration : playerView.duration      // BGMまたは映像の長さ
        self.notes = music.generateNotes(setting: setting, duration: duration)      // ノーツ生成

        // ボタンの設定
        pauseButton = { () -> UIButton in
            let Button = UIButton()

            Button.setImage(UIImage(named: ImageName.pause.rawValue), for: .normal)
            Button.setImage(UIImage(named: ImageName.pauseSelected.rawValue), for: .highlighted)
            Button.addTarget(self, action: #selector(didTapPauseButton(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.width - Dimensions.iconButtonSize, y: 0, width: Dimensions.iconButtonSize, height: Dimensions.iconButtonSize) // yは上からの座標
            self.view?.addSubview(Button)

            return Button
        }()

        // ラベルの設定
        judgeLabel = { () -> SKLabelNode in
            let Label = SKLabelNode(fontNamed: "HiraginoSans-W6")

            Label.fontSize = self.frame.width / 36
            Label.horizontalAlignmentMode = .center // 中央寄せ
            Label.position = CGPoint(x: self.frame.midX, y: Dimensions.judgeLineY * 2)
            Label.fontColor = SKColor.yellow

            self.addChild(Label)
            return Label
        }()

        comboLabel = { () -> SKLabelNode in
            let Label = SKLabelNode(fontNamed: "HiraginoSans-W6")

            Label.fontSize = self.frame.width / 18
            Label.horizontalAlignmentMode = .center // 中央寄せ
            Label.position = CGPoint(x: self.frame.width - Label.fontSize*2, y: self.frame.height*3/4)
            Label.fontColor = SKColor.white

            self.addChild(Label)
            return Label
        }()

        // 全ノーツ及び関連画像をGameSceneにaddChild
        for note in notes {
            self.addChild(note.image)           // 始点及び単ノーツをaddChild
            if let start = note as? TapStart {  // ダウンキャスト
                // ロング始点に付随する緑太線と緑円をaddChild
                self.addChild(start.longImages.circle)
                self.addChild(start.longImages.long)

                var following = start.next
                while true {
                    self.addChild(following.image)
                    if let middle = following as? Middle {  // ダウンキャスト
                        // middleに付随する緑太線と緑円をaddChild
                        self.addChild(middle.longImages.long)
                        self.addChild(middle.longImages.circle)
                        following = middle.next
                    } else {
                        break
                    }
                }
            }
        }
        // 画像の設定
        setImages()

        self.mediaOffsetTime = (music.musicStartPos / BPMs[0].bpm) * 60
        self.mediaOffsetTime += playMode == .BGM ? Double(music.offset)*headerOffsetUnit : Double(music.youTubeOffset)*headerOffsetUnit

        self.isPrecedingStartValid = {
            for note in notes {
                switch note {
                case let tap      as Tap      where tap.appearTime < mediaOffsetTime      : return true
                case let flick    as Flick    where flick.appearTime < mediaOffsetTime    : return true
                case let tapStart as TapStart where tapStart.appearTime < mediaOffsetTime : return true
                default                                                                   : break
                }
            }
            return false
        }()

        // 再生時間や背景、ビューの前後関係などを指定
        if playMode == .BGM {

            // BGMの再生(時間指定)
            self.startTime = CACurrentMediaTime()
            BGM.play(atTime: startTime + mediaOffsetTime)  // 建築予定地
            BGM.delegate = self
            self.backgroundColor = .black

        } else {
            playerView.delegate = self
            view.superview!.addSubview(playerView.view)
            view.superview!.sendSubviewToBack(playerView.view)
            view.superview!.bringSubviewToFront(self.view!)
            self.backgroundColor = UIColor(white: 0, alpha: 0.5)
            self.view?.backgroundColor = .clear

            self.view?.isUserInteractionEnabled = true
            self.view?.superview?.isUserInteractionEnabled = true
            playerView.isUserInteractionEnabled = false

        }

        // 各レーンにノーツをセット
        for note in notes {
            lanes[note.laneIndex].append(note)

            if let start = note as? TapStart {
                var following = start.next
                while true {
                    lanes[following.laneIndex].append(following)
                    if let middle = following as? Middle {
                        following = middle.next
                    } else {
                        break
                    }
                }
            }
        }
        for lane in lanes {
            lane.sort()
        }
    }

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)


        // 経過時間の更新
        if self.playMode == .BGM {
            if BGM.currentTime > 0 {
                self.passedTime = BGM.currentTime + mediaOffsetTime
            } else {
                if !isSupposedToPausePlayerView {
                    self.passedTime = CACurrentMediaTime() - startTime // シーン移動後からBGM再生開始までノーツを動かす(再生開始後に急にノーツが現れるのを防ぐため)。この時間差がmediaOffsetTimeになったときにBGMの再生が始まる
                }
            }
        } else {
            if isPrecedingStartValid {
                if playerView.playerState() == .playing || playerView.playerState() == .paused {

                    switch ytLaunchState {
                    case .loading:
                        playerView.pauseVideo()         // ロードが終わった瞬間にポーズして、ノーツとの同期を待つ
                        //                        playerView.seek(toSeconds: 0, allowSeekAhead: true) // 0秒にシークするとなぜか再生に時間がかかる
                        self.passedTime = 0
                        self.startTime = CACurrentMediaTime()
                        self.ytLaunchState = .initialPaused
                    case .initialPaused:                            // 0 < passedTime < mediaOffsetTime の時(厳密にはポーズへの移行中(再生中)も含む)
                        self.passedTime = CACurrentMediaTime() - startTime
                        if playerView.playerState() == .paused && passedTime > mediaOffsetTime + playerView.initialPausedTime {
                            playerView.playVideo()
                            self.ytLaunchState = .tryingToPlay
                        }
                    case .tryingToPlay:     // 再生状態へ移行中(ポーズ中)
                        self.passedTime = playerView.currentTime + mediaOffsetTime
                    case .done:                   // mediaOffsettime < passedTime の時
                        self.passedTime = playerView.currentTime + mediaOffsetTime
                        playerView.countFrameForBaseline()
                        if isSupposedToPausePlayerView {
                            playerView.pauseVideo()
                            self.isSupposedToPausePlayerView = false
                        }
                    }
                }
            } else {
                self.passedTime = playerView.currentTime + mediaOffsetTime
                if playerView.playerState() == .playing && isSupposedToPausePlayerView {
                    playerView.pauseVideo()
                    self.isSupposedToPausePlayerView = false
                }
            }
        }


        // 各ノーツの位置や大きさを更新
        for note in notes {
            note.update(passedTime)
        }

        // レーンの更新(ノーツ更新後に実行)
        lanes.filter({ !($0.isEmpty) }).forEach({ lane in
            lane.updateTimeLag(self.passedTime, self.BPMs)
        })

        // 同時押しラインの更新
        for sameLine in sameLines {
            let (note1, note2, line) = (sameLine.note1, sameLine.note2, sameLine.line)
            // 同時押しラインを移動
            line.position = note1.position
            // 表示状態の更新
            line.isHidden = note1.image.isHidden || note2.image.isHidden
            // 大きさも変更
            line.setScale(note1.size / Note.scale / Dimensions.laneWidth)
        }

        // 終了時刻が指定されていればその時刻でシーン移動
        if let duration = music.duration, passedTime > duration {
            BGM = nil
            moveToResultScene(result: result)
        }
    }

    override func willMove(from view: SKView) {
        pauseButton?.removeFromSuperview()
        pauseView?.removeFromSuperview()
        playerView?.stopVideo()
        playerView?.view.removeFromSuperview() // 解放されてない？
    }

    /// 判定ラベルのテキストを更新（アニメーション付き）
    func setJudgeLabelText(judgeType: JudgeType) {

        judgeLabel.text = judgeType.rawValue

        judgeLabel.removeAllActions()

        let set = SKAction.scale(to: 1/JLScale, duration: 0)
        let add = SKAction.unhide()
        let scale = SKAction.scale(to: 1, duration: 0.07)
        let pause = SKAction.wait(forDuration: 3)
        let hide = SKAction.hide()
        let seq = SKAction.sequence([set, add, scale, pause, hide])

        judgeLabel.run(seq)
    }

    func moveToResultScene(result: Result) {
        let scene = ResultScene(size: (view?.bounds.size)!, result: result)
        let skView = view as SKView?
        skView?.showsFPS = true
        skView?.showsNodeCount = true
        skView?.ignoresSiblingOrder = true
        scene.scaleMode = .resizeFill
        skView?.presentScene(scene)     // ResultSceneに移動
    }

    private func reloadScene() {

        let nextMusic = Music(music: music, playMode: setting.playMode) // 譜面を再生成

        var scene = SKScene()
        switch self {
        case is GameScene:
            scene = GameScene(size: (self.view?.bounds.size)!, setting: setting, music: nextMusic)
        case is AutoPlayScene:
            scene = AutoPlayScene(size: (self.view?.bounds.size)!, setting: setting, music: nextMusic)
        case is OffsetScene:
            scene = OffsetScene(size: (self.view?.bounds.size)!, setting: setting, music: nextMusic)
        default: break
        }

        let skView = view as SKView?    // このviewはGameViewControllerのskView2
        skView?.showsFPS = true
        skView?.showsNodeCount = true
        skView?.ignoresSiblingOrder = true
        scene.scaleMode = .resizeFill
        skView?.presentScene(scene)  // GameSceneに移動
    }

    /// BGMモードへ移行
    func reloadSceneAsBGMMode() {
        setting.isYouTube = false
        setting.save()
        reloadScene()
    }

    func reloadSceneAsYouTubeMode() {
        setting.isYouTube = true
        setting.save()
        reloadScene()
    }

    /* -------- ボタン関数群 -------- */

    @objc func didTapPauseButton(_ sender : UIButton) {
        applicationWillResignActive()
    }

    @objc func didTapReturnButton(_ sender : UIButton) {

        let scene = ChooseMusicScene(size: (view?.bounds.size)!)
        let skView = view as SKView?
        skView?.showsFPS = true
        skView?.showsNodeCount = true
        skView?.ignoresSiblingOrder = true
        scene.scaleMode = .resizeFill
        skView?.presentScene(scene)     // ChooseMusicSceneに移動
    }

    @objc func didTapContinueButton(_ sender : UIButton) {

        pauseView?.removeFromSuperview()
        self.isUserInteractionEnabled = true
        self.isSupposedToPausePlayerView = false
        actionSoundSet.stopAll()
        if self.playMode == .BGM {
            BGM?.play()
            BGM?.currentTime -= 3   // 3秒巻き戻し(ずれるので、必ずplay()のあとにずらすこと)
        } else {
            //            let passedTime = playerView.pausedTime - playerView.startTime - playerView.timeOffset - 3
            playerView.playVideo()
            //            playerView.timeOffset += CACurrentMediaTime() - playerView.pausedTime + 3
        }

        setJudgeLabelText(judgeType: .none)

        // 表示されているノーツを非表示に
        for note in notes {
            note.image.isHidden = true
            if let start = note as? TapStart {
                start.longImages.long.isHidden = true
                start.longImages.circle.isHidden = true
                var following = start.next
                while true {
                    if let middle = following as? Middle {
                        middle.image.isHidden = true
                        middle.longImages.long.isHidden = true
                        middle.longImages.circle.isHidden = true
                        following = middle.next
                    } else {
                        following.image.isHidden = true
                        break
                    }
                }
            }
        }
        // 途中まで判定したロングノーツがあれば未判定のノーツを開始ノーツに変換
        for note in notes {
            if let start = note as? TapStart, start.isJudged {
                var following = start.next
                while let middle = following as? Middle, middle.isJudged {
                    following = middle.next
                }
                guard !(following.isJudged) else {
                    continue            // 最後まで判定済みだった場合はcontinue
                }
                following.image.removeFromParent()  // 一応消去(longImagesは放置)

                // 新たな始点ノーツを生成
                var newNote = Note()
                switch following {
                case is TapEnd:   newNote = Tap     (tapEnd:   following as! TapEnd)
                case is FlickEnd: newNote = Flick   (flickEnd: following as! FlickEnd)
                case is Middle:   newNote = TapStart(middle:   following as! Middle)
                default:
                    print("後続ノーツタイプが不正です")
                    continue
                }
                // addChild
                self.addChild(newNote.image)
                if let tapStart = newNote as? TapStart {
                    self.addChild(tapStart.longImages.circle)
                    self.addChild(tapStart.longImages.long)
                }
                // ロングノーツの始点ノーツおよび、それに付随する同時線を削除
                notes.remove(at: notes.index(of: start)!)
                if let i = sameLines.index(where: { $0.note1 == note || $0.note2 == note }) {
                    self.sameLines.remove(at: i)
                }
                // 旧ノーツに付随する同時線を更新
                for i in 0..<sameLines.count {
                    if sameLines[i].note1 == following { self.sameLines[i].note1 = newNote }
                    if sameLines[i].note2 == following { self.sameLines[i].note2 = newNote }
                }
                notes.append(newNote)
                // laneNotesも更新
                let lane = lanes[following.laneIndex]
                lane.remove(following)
                lane.append(newNote)
                lane.sort()
            }
        }
    }

    @objc func didTapSwitchIsYouTubeButton(_ sender : UIButton) {
        if setting.isYouTube { reloadSceneAsBGMMode()     }
        else                 { reloadSceneAsYouTubeMode() }
    }

    /* -------- 同時押し対策 -------- */

    @objc func onButton(_ sender : UIButton) {
        for button in pauseViewButtons {
            guard sender != button else { continue }
            button.isEnabled = false
        }
    }
    @objc func touchUpOutsideButton(_ sender : UIButton) {
        pauseViewButtons.forEach({ $0.isEnabled = true })
    }

    /// AVAudioPlayerの再生終了時の呼び出しメソッド
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {    // playしたクラスと同じクラスに入れる必要あり？
        if player as AVAudioPlayer? == BGM {
            BGM = nil   // 別のシーンでアプリを再開したときに鳴るのを防止
            moveToResultScene(result: result)
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("\(player)で\(String(describing: error))")
    }

    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        switch (state) {
        case .playing:
            if ytLaunchState == .tryingToPlay {     // プレイ開始時
                ytLaunchState = .done
                self.playerView.renewTimeParams()
            } else if ytLaunchState == .done {      // プレイ再開時
                //                self.playerView.setBaseline()
            }
        case .paused:       // ここはポーズ時になぜか2回呼ばれる
            if ytLaunchState == .initialPaused {
                self.playerView.initialPausedTime = self.playerView.currentTime
            }
        case .ended:
            playerView.removeFromSuperview()
            moveToResultScene(result: result)
        case .unknown:
            print("unknown")
        default:
            break
        }
    }

    /// 読み込み完了後に呼び出される
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {

        print("didBecomeReady")

        // play呼び出し→読み込み→再生開始となるが、通信環境によって読み込み時間がバラバラのため、最初だけは少し先読みしてから再生。
        playerView.playVideo()
    }

    /// エラー処理
    func playerView(_ playerView: YTPlayerView, receivedError error: YTPlayerError) {
        print(error)
        reloadSceneAsBGMMode()
    }

    /// アプリが閉じそうなとき、ポーズボタンを押されたときに呼ばれる(AppDelegate.swiftから)
    func applicationWillResignActive() {

        guard view?.scene is PlayMusicScene else { return }

        if self.playMode == .BGM {
            BGM?.pause()
        } else {
            if (isPrecedingStartValid && ytLaunchState == .done) || (!isPrecedingStartValid && playerView.playerState() == .playing) {
                playerView.pauseVideo()
                playerView.seek(toSeconds: Float(playerView.currentTime - 3), allowSeekAhead: true)
            }
        }

        // ポーズが可能な状態じゃない時は予約しておく
        if playMode == .BGM {
            if BGM.currentTime <= 0 {
                self.isSupposedToPausePlayerView = true
            }
        } else {
            if (isPrecedingStartValid && ytLaunchState != .done) || (!isPrecedingStartValid && playerView.playerState() != .playing) {
                self.isSupposedToPausePlayerView = true
            }
        }

        // 選択画面を出す
        if self.pauseView == nil {
            self.pauseView = { () -> UIView in
                let view = UIView(frame: self.frame)
                view.backgroundColor = UIColor(white: 0, alpha: 0.5)
                return view
            }()
            self.returnButton = { () -> UIButton in
                let Button = UIButton()

                Button.addTarget(self, action: #selector(didTapReturnButton(_:)), for: .touchUpInside)
                Button.addTarget(self, action: #selector(onButton(_:)), for: .touchDown)
                Button.addTarget(self, action: #selector(touchUpOutsideButton(_:)), for: .touchUpOutside)
                Button.frame = CGRect(x: 0, y: 0, width: self.frame.width/5, height: 50)
                Button.backgroundColor = .red
                Button.layer.masksToBounds = true
                Button.setTitle("中断する", for: UIControl.State())
                Button.setTitleColor(UIColor.white, for: UIControl.State())
                Button.setTitle("中断する", for: UIControl.State.highlighted)
                Button.setTitleColor(UIColor.black, for: UIControl.State.highlighted)
                Button.isHidden = false
                Button.layer.cornerRadius = 20.0
                Button.layer.position = CGPoint(x: self.frame.midX + Button.frame.width*2/3, y: self.frame.midY - Button.frame.height*0.6)
                self.pauseView?.addSubview(Button)

                return Button
            }()
            self.continueButton = { () -> UIButton in
                let Button = UIButton()

                Button.addTarget(self, action: #selector(didTapContinueButton(_:)), for: .touchUpInside)
                Button.addTarget(self, action: #selector(onButton(_:)), for: .touchDown)
                Button.addTarget(self, action: #selector(touchUpOutsideButton(_:)), for: .touchUpOutside)
                Button.frame = CGRect(x: 0, y: 0, width: self.frame.width/5, height: 50)
                Button.backgroundColor = .green
                Button.layer.masksToBounds = true
                Button.setTitle("続ける", for: UIControl.State())
                Button.setTitleColor(UIColor.white, for: UIControl.State())
                Button.setTitle("続ける", for: UIControl.State.highlighted)
                Button.setTitleColor(UIColor.black, for: UIControl.State.highlighted)
                Button.isHidden = false
                Button.layer.cornerRadius = 20.0
                Button.layer.position = CGPoint(x: self.frame.midX - Button.frame.width*2/3, y: self.frame.midY - Button.frame.height*0.6)
                self.pauseView?.addSubview(Button)

                return Button
            }()

            self.switchIsYouTubeButton = { () -> UIButton in
                let Button = UIButton()

                Button.addTarget(self, action: #selector(didTapSwitchIsYouTubeButton(_:)), for: .touchUpInside)
                Button.addTarget(self, action: #selector(onButton(_:)), for: .touchDown)
                Button.addTarget(self, action: #selector(touchUpOutsideButton(_:)), for: .touchUpOutside)
                Button.frame = CGRect(x: 0, y: 0, width: self.frame.width/4, height: 50)
                Button.backgroundColor = .orange
                Button.layer.masksToBounds = true
                if setting.isYouTube { Button.setTitle("BGMに切り替え"    , for: UIControl.State()) }
                else                 { Button.setTitle("YouTubeに切り替え", for: UIControl.State()) }
                Button.setTitleColor(UIColor.white, for: UIControl.State())
                Button.setTitleColor(UIColor.black, for: UIControl.State.highlighted)
                Button.isHidden = !music.youTubeExists
                Button.layer.cornerRadius = 20.0
                Button.layer.position = CGPoint(x: self.frame.midX, y: self.frame.midY + Button.frame.height*0.6)
                self.pauseView?.addSubview(Button)

                return Button
            }()
        }
        self.view?.superview?.addSubview(pauseView!)
        self.view?.superview?.bringSubviewToFront(pauseView!)

        self.isUserInteractionEnabled = false

        pauseViewButtons.forEach({ $0.isEnabled = true })


    }
}

