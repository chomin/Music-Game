
//
//  GameScene.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//



import SpriteKit
import GameplayKit
import AVFoundation
import youtube_ios_player_helper    // 今後、これを利用するために.xcodeprojではなく、.xcworkspaceを開いて編集すること



// 判定関係のフラグ付きタッチ情報
class GSTouch { // 参照型として扱いたい
    let touch: UITouch
    var isJudgeableFlick: Bool      // このタッチでのフリック判定を許すor許さない
    var isJudgeableFlickEnd: Bool   // 上記のFlickEndバージョン
    var storedFlickJudgeLaneIndex: Int?
    
    init(touch: UITouch, isJudgeableFlick: Bool, isJudgeableFlickEnd: Bool, storedFlickJudgeLaneIndex: Int?) {
        self.touch = touch
        self.isJudgeableFlick = isJudgeableFlick
        self.isJudgeableFlickEnd = isJudgeableFlickEnd
        self.storedFlickJudgeLaneIndex = storedFlickJudgeLaneIndex
    }
}

// 同時押し線の画像情報
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



class GameScene: SKScene, AVAudioPlayerDelegate, YTPlayerViewDelegate, GSAppDelegate {    // 音ゲーをするシーン
    
    
//    var tmpCounter = 0  //デバッグ用
    
    
    var playMode: PlayMode
    
    let judgeQueue = DispatchQueue(label: "judge_queue")    // キューに入れた処理内容を順番に実行(FPS落ち対策)
    
    // appの起動、終了等に関するデリゲート
    var appDelegate: AppDelegate!
    
    // タッチ情報
    var allGSTouches: [GSTouch] = []
    
    // ラベル
    var judgeLabel = SKLabelNode(fontNamed: "HiraginoSans-W6")
    var comboLabel = SKLabelNode(fontNamed: "HiraginoSans-W6")
    let JLScale: CGFloat = 1.25  // 拡大縮小アニメーションの倍率
    
    // ボタン
    var pauseButton: UIButton!
    var returnButton: UIButton!
    var continueButton: UIButton!
    
    // ポーズ時のview
    var pauseView: UIView?
    
    // 音楽プレイヤー
    var BGM: AVAudioPlayer!
    let actionSoundSet = ActionSoundPlayers()
    
    // YouTubeプレイヤー
    var playerView : YTPlayerView!
    var isReadyPlayerView = false
    
    // 画像(ノーツ以外)
    var judgeLine: SKShapeNode!
    var sameLines: [SameLine] = []  // 連動する始点側のノーツと同時押しライン
    
    // 楽曲データ
    var musicName: MusicName    // 曲名
    var notes: [Note] = []      // ノーツの" 始 点 "の集合。
    var musicStartPos = 1.0     // BGM開始の"拍"！
    var genre = ""              // ジャンル
    var title = ""              // タイトル
    var artist = ""             // アーティスト
    var playLevel = 0           // 難易度
    var volWav = 100            // 音量を現段階のn%として出力するか(TODO: 未実装)
    var BPMs: [(bpm: Double, startPos: Double)] = []        // 可変BPM情報
    
    private var startTime: TimeInterval = 0.0       // シーン移動した時の時間
    var passedTime: TimeInterval = 0.0              // 経過時間
    private var mediaOffsetTime: TimeInterval = 0.0 // 経過時間と、BGM.currentTimeまたはplayerView.currentTime()のずれ。一定
    let lanes = [Lane(laneIndex: 0), Lane(laneIndex: 1), Lane(laneIndex: 2), Lane(laneIndex: 3), Lane(laneIndex: 4), Lane(laneIndex: 5), Lane(laneIndex: 6)]     // レーン
    
    private let speedRatio: CGFloat
    
    
    init(musicName: MusicName, playMode: PlayMode, size: CGSize, speedRatioInt: UInt) {   // YouTube用

        self.musicName = musicName
        self.playMode = playMode
        self.speedRatio = CGFloat(speedRatioInt) / 100
        
        
        super.init(size: size)
        
        switch playMode {
        case .BGM:
            // サウンドファイルのパスを生成
            let Path = Bundle.main.path(forResource: "Sounds/" + musicName.rawValue, ofType: "mp3")!     // m4a,oggは不可
            let soundURL = URL(fileURLWithPath: Path)
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
            let videoID = getVideoID(musicName: musicName, playMode: playMode)!
            
            self.playerView = YTPlayerView(frame: self.frame)
            // 詳しい使い方はJump to Definitionへ
            if !(self.playerView.load(withVideoId: videoID.rawValue, playerVars: ["autoplay": 1, "controls": 0, "playsinline": 1, "rel": 0, "showinfo": 0])) {
                print("ロードに失敗")
                
                // BGMモードへ移行
                let scene = GameScene(musicName: self.musicName, playMode: .BGM, size: (view?.bounds.size)!, speedRatioInt: UInt(self.speedRatio*100))
                let skView = view as SKView?    // このviewはGameViewControllerのskView2
                skView?.showsFPS = true
                skView?.showsNodeCount = true
                skView?.ignoresSiblingOrder = true
                scene.scaleMode = .resizeFill
                skView?.presentScene(scene)  // GameSceneに移動
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func didMove(to view: SKView) {
        
        // ボタンの設定
        pauseButton = {() -> UIButton in
            let Button = UIButton()

            Button.setImage(UIImage(named: ImageName.pause.rawValue), for: .normal)
            Button.setImage(UIImage(named: ImageName.pauseSelected.rawValue), for: .highlighted)
            Button.addTarget(self, action: #selector(onClickPauseButton(_:)), for: .touchUpInside)
            Button.frame = CGRect(x: self.frame.width - Dimensions.iconButtonSize, y: 0, width: Dimensions.iconButtonSize, height: Dimensions.iconButtonSize)//yは上からの座標
            self.view?.addSubview(Button)

            return Button
        }()
        
        appDelegate = UIApplication.shared.delegate as! AppDelegate // AppDelegateのインスタンスを取得
        appDelegate.gsDelegate = self   // 子(AppDelegate)の設定しているdelegateに自身をセット
        
        self.view?.isMultipleTouchEnabled = true    // 恐らくデフォルトではfalseになってる
        self.view?.superview?.isMultipleTouchEnabled = true
        
        
        
        // notesにノーツの"　始　点　"を入れる(必ずcreateInstanceの後に実行)
        do {
            try parse(fileName: musicName.rawValue + ".bms")
        }
        catch FileError.invalidName     (let msg) { print(msg) }
        catch FileError.notFound        (let msg) { print(msg) }
        catch FileError.readFailed      (let msg) { print(msg) }
        catch ParseError.lackOfData     (let msg) { print(msg) }
        catch ParseError.invalidValue   (let msg) { print(msg) }
        catch ParseError.noLongNoteStart(let msg) { print(msg) }
        catch ParseError.noLongNoteEnd  (let msg) { print(msg) }
        catch ParseError.unexpected     (let msg) { print(msg) }
        catch                                     { print("未知のエラー") }
        
        // Noteクラスのクラスプロパティを設定
        let duration = (playMode == .BGM) ? BGM.duration : playerView.duration()    // BGMまたは映像の長さ
        Note.setConstants(BPMs, speedRatio, duration)
        
        //リザルトの初期化
        ResultScene.parfect = 0
        ResultScene.great = 0
        ResultScene.good = 0
        ResultScene.bad = 0
        ResultScene.miss = 0
        ResultScene.combo = 0
        ResultScene.maxCombo = 0
        
        // ラベルの設定
        judgeLabel = { () -> SKLabelNode in
            let Label = SKLabelNode(fontNamed: "HiraginoSans-W6")
            
            Label.fontSize = self.frame.width / 36
            Label.horizontalAlignmentMode = .center // 中央寄せ
            Label.position = CGPoint(x: self.frame.midX, y: self.frame.width/9*2)
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
                while(true) {
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
        
        
        mediaOffsetTime = (musicStartPos / BPMs[0].bpm) * 60

        if playMode == .BGM {
            self.startTime = CACurrentMediaTime()
            // BGMの再生(時間指定)
            BGM.play(atTime: startTime + mediaOffsetTime)  // 建築予定地
            BGM.delegate = self
            self.backgroundColor = .black
        } else {
            self.startTime = TimeInterval(pow(10.0, 308.0))  // Doubleのほぼ最大値。ロードが終わるまで。
            
            playerView.delegate = self
            view.superview!.addSubview(playerView)
            
            
            view.superview!.sendSubview(toBack: playerView)
            view.superview!.bringSubview(toFront: self.view!)
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
                while(true) {
                    lanes[following.laneIndex].append(following)
                    if let middle = following as? Middle {
                        following = middle.next
                    } else {
                        break
                    }
                }
            }
        }
        for lane in lanes { // レーンの設定
            lane.isSetLaneNotes = true
        }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        
        // 経過時間の更新
        if self.playMode == .BGM {
            if BGM.currentTime > 0 {
                self.passedTime = BGM.currentTime + mediaOffsetTime
            } else {
                self.passedTime = CACurrentMediaTime() - startTime
            }
        } else {
            if isReadyPlayerView  { // currentTime>0は最初から成り立つ？
                if playerView.currentTime() > 0 {
//                    print(playerView.currentTime())
                    self.passedTime = TimeInterval(playerView.currentTime()) + mediaOffsetTime
                } else {
                    self.passedTime = 0
                }
            } else {
                self.passedTime = 0
            }
        }
        // ラベルの更新
        comboLabel.text = String(ResultScene.combo)
        
        // 各ノーツの位置や大きさを更新
        for note in notes {
            note.update(passedTime)
        }
        
        // レーンの更新
        for lane in lanes {
             lane.update(passedTime, self.BPMs)
        }
        
        // 同時押しラインの更新
        for sameLine in sameLines {
            let (note1, note2, line) = (sameLine.note1, sameLine.note2, sameLine.line)
            // 同時押しラインを移動
            line.position = note1.position
            // 表示状態の更新
            line.isHidden = note1.image.isHidden || note2.image.isHidden
            // 大きさも変更
            line.setScale(note1.image.xScale / Note.scale)
        }
        
        
        // 判定関係
        // middleの判定（同じところで長押しのやつ）
        judgeQueue.sync {
            
            
            for gsTouch in self.allGSTouches {
                
                let pos = gsTouch.touch.location(in: self.view?.superview)
                
                guard Dimensions.judgeYRange.contains(pos.y) else {     // 以下、ボタンの判定圏内にあるtouchのみを処理する
                    continue
                }
                
                for (laneIndex, judgeXRange) in Dimensions.judgeXRanges.enumerated() {
                    
                    if judgeXRange.contains(pos.x) {   // ボタンの範囲
                        
                        if self.parfectMiddleJudge(lane: self.lanes[laneIndex]) { // middleの判定
                            
                            self.actionSoundSet.play(type: .middle)
                            gsTouch.isJudgeableFlickEnd = true
                            break
                        }
                    }
                }
            }
            
            
            
            // レーンの監視(過ぎて行ってないか&storedFlickJudgeの時間になっていないか)
            for lane in self.lanes {
                if lane.judgeTimeState == .passed && !(lane.isEmpty) {
                    
                    self.missJudge(lane: lane)
                    
                } else if let storedFlickJudgeInformation = lane.storedFlickJudgeInformation {
                    if lane.timeLag < -storedFlickJudgeInformation.timeLag {
                        
                        self.storedFlickJudge(lane: lane)
                    }
                }
            }
        }
        
        // レーンの更新(再)(判定後、laneNotes[0]が入れ替わるので、それを反映させる)
        for lane in lanes {
            lane.update(passedTime, self.BPMs)
        }
    }
    
    
    // 判定ラベルのテキストを更新（アニメーション付き）
    func setJudgeLabelText(text:String) {
        
        judgeLabel.text = text
        
        judgeLabel.removeAllActions()
        
        let set = SKAction.scale(to: 1/JLScale, duration: 0)
        let add = SKAction.unhide()
        let scale = SKAction.scale(to: 1, duration: 0.07)
        let pause = SKAction.wait(forDuration: 3)
        let hide = SKAction.hide()
        let seq = SKAction.sequence([set, add, scale, pause, hide])
        
        judgeLabel.run(seq)
    }
    
    /// videoIDを獲得する関数
    ///
    /// - Parameters:
    ///   - musicName: MusicName型で指定
    ///   - playMode: PlayMode型で指定（.YouTube　または　.YouTube2）
    /// - Returns: VideoID型
    private func getVideoID(musicName: MusicName, playMode: PlayMode) -> VideoID? {
        
        guard playMode != .BGM else {
            print("playModeは .YouTube か .YouTube2 のみ指定可能です")
            return nil
        }
        
        
        switch musicName {
        case .yo_kosoJapariParkHe  : return .yo_kosoJapariParkHe
        case .oracion             : if playMode == .YouTube { return .oracion }
                                     else                    { return .uracion }
        case .sakuraSkip           : return .sakuraSkip
        case .nimenseiUraomoteLife : return .nimenseiUraomoteLife
        case .buonAppetitoS        : return .buonAppetitoS
        case .level5               : return .level5
        default:
            print("videoIDが存在しません")
            return nil
        }
    }
    
    func moveToResultScene() {
        pauseButton.removeFromSuperview()
        let scene = ResultScene(size: (view?.bounds.size)!)
        let skView = view as SKView?
        skView?.showsFPS = true
        skView?.showsNodeCount = true
        skView?.ignoresSiblingOrder = true
        scene.scaleMode = .resizeFill
        skView?.presentScene(scene)     // ResultSceneに移動
    }
    
    @objc func onClickPauseButton(_ sender : UIButton){
        applicationWillResignActive()
    }
    
    @objc func onClickReturnButton(_ sender : UIButton){
        pauseButton.removeFromSuperview()
        pauseView?.removeFromSuperview()
        let scene = ChooseMusicScene(size: (view?.bounds.size)!)
        let skView = view as SKView?
        skView?.showsFPS = true
        skView?.showsNodeCount = true
        skView?.ignoresSiblingOrder = true
        scene.scaleMode = .resizeFill
        skView?.presentScene(scene)     // ChooseMusicSceneに移動
    }
    
    @objc func onClickContinueButton(_ sender : UIButton){
        pauseView?.removeFromSuperview()
        self.isUserInteractionEnabled = true
        actionSoundSet.stopAll()
        if self.playMode == .BGM{
            BGM?.currentTime -= 3   // 3秒巻き戻し
            BGM?.play()
        }else{
            playerView.seek(toSeconds: playerView.currentTime()-3, allowSeekAhead: true)
            playerView.playVideo()
        }
    }
    
    //同時押し対策
    @objc func onReturnButton(_ sender : UIButton){
        self.continueButton.isEnabled = false
    }
    @objc func onContinueButton(_ sender : UIButton){
        self.returnButton.isEnabled = false
    }
    @objc func touchUpOutsideButton(_ sender : UIButton){
        enableAllButtonsOnPauseView()
    }
    func enableAllButtonsOnPauseView() {
        self.returnButton.isEnabled = true
        self.continueButton.isEnabled = true
    }
    // 再生終了時の呼び出しメソッド
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {    // playしたクラスと同じクラスに入れる必要あり？
        if player as AVAudioPlayer? == BGM {
            BGM = nil   // 別のシーンでアプリを再開したときに鳴るのを防止
            moveToResultScene()
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("\(player)で\(String(describing: error))")
    }
    
    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        switch (state) {
        case .playing:
            isReadyPlayerView = true
        case .ended:
            playerView.removeFromSuperview()
            moveToResultScene()
        case .unknown:
            print("unknown")
        default:
            break
        }
    }
    
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) { // 読み込み完了後に呼び出される
        
//        self.isReadyPlayerView = true
//        startTime = CACurrentMediaTime()
//        DispatchQueue.main.asyncAfter(deadline: .now() + mediaOffsetTime) {
            playerView.playVideo()
//        }
    }
    
    func playerView(_ playerView: YTPlayerView, receivedError error: YTPlayerError) {   //エラー処理
        print(error)
        
        //BGMモードへ移行
        let scene = GameScene(musicName:self.musicName, playMode: .BGM ,size: (view?.bounds.size)!, speedRatioInt:UInt(self.speedRatio*100))
        let skView = view as SKView?    //このviewはGameViewControllerのskView2
        skView?.showsFPS = true
        skView?.showsNodeCount = true
        skView?.ignoresSiblingOrder = true
        scene.scaleMode = .resizeFill
        skView?.presentScene(scene)  // GameSceneに移動
        
    }
    
    
    
    
    // アプリが閉じそうなときに呼ばれる(AppDelegate.swiftから)
    func applicationWillResignActive() {
        if self.playMode == .BGM{
            BGM?.pause()
        }else{
            playerView.pauseVideo()
        }
        setJudgeLabelText(text: "")
        
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
        // 途中まで判定したロングノーツがあれば最後まで判定済みに
        for note in notes {
            if let start = note as? TapStart, start.isJudged {
                var following = start.next
                while let middle = following as? Middle {
                    middle.isJudged = true
                    following = middle.next
                }
                following.isJudged = true
            }
        }
        
        // 選択画面を出す
        if self.pauseView == nil {
            self.pauseView = { () -> UIView in
                let view = UIView(frame: self.frame)
                view.backgroundColor = UIColor(white: 0, alpha: 0.5)
                return view
            }()
            self.returnButton = {() -> UIButton in
                let Button = UIButton()
                
                Button.addTarget(self, action: #selector(onClickReturnButton(_:)), for: .touchUpInside)
                Button.addTarget(self, action: #selector(onReturnButton(_:)), for: .touchDown)
                Button.addTarget(self, action: #selector(touchUpOutsideButton(_:)), for: .touchUpOutside)
                Button.frame = CGRect(x: 0, y: 0, width: self.frame.width/5, height: 50)
                Button.backgroundColor = .red
                Button.layer.masksToBounds = true
                Button.setTitle("中断する", for: UIControlState())
                Button.setTitleColor(UIColor.white, for: UIControlState())
                Button.setTitle("中断する", for: UIControlState.highlighted)
                Button.setTitleColor(UIColor.black, for: UIControlState.highlighted)
                Button.isHidden = false
                Button.layer.cornerRadius = 20.0
                Button.layer.position = CGPoint(x: self.frame.midX + Button.frame.width*2/3, y: self.frame.midY)
                self.pauseView?.addSubview(Button)
                
                return Button
                }()
            self.continueButton = {() -> UIButton in
                let Button = UIButton()
                
                Button.addTarget(self, action: #selector(onClickContinueButton(_:)), for: .touchUpInside)
                Button.addTarget(self, action: #selector(onContinueButton(_:)), for: .touchDown)
                Button.addTarget(self, action: #selector(touchUpOutsideButton(_:)), for: .touchUpOutside)
                Button.frame = CGRect(x: 0, y: 0, width: self.frame.width/5, height: 50)
                Button.backgroundColor = .green
                Button.layer.masksToBounds = true
                Button.setTitle("続ける", for: UIControlState())
                Button.setTitleColor(UIColor.white, for: UIControlState())
                Button.setTitle("続ける", for: UIControlState.highlighted)
                Button.setTitleColor(UIColor.black, for: UIControlState.highlighted)
                Button.isHidden = false
                Button.layer.cornerRadius = 20.0
                Button.layer.position = CGPoint(x: self.frame.midX - Button.frame.width*2/3, y: self.frame.midY)
                self.pauseView?.addSubview(Button)
                
                return Button
            }()
        }
        self.view?.superview?.addSubview(pauseView!)
        self.view?.superview?.bringSubview(toFront: pauseView!)
        
        self.isUserInteractionEnabled = false
        
        enableAllButtonsOnPauseView()
    }
    
   
    
}








