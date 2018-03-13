
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

enum PlayMode {
    case BGM, YouTube, YouTube2
}

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
    unowned var note1:Note
    unowned var note2:Note
    var line:SKShapeNode
    
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
    
    var playMode: PlayMode
    
    //
    let judgeQueue = DispatchQueue(label: "judge_queue")    // キューに入れた処理内容を順番に実行(FPS落ち対策)
    
    // appの起動、終了等に関するデリゲート
    var appDelegate: AppDelegate!
    
    // タッチ情報
    var allTouches: [GSTouch] = []
    
    // ラベル
    var judgeLabel = SKLabelNode(fontNamed: "HiraginoSans-W6")
    var comboLabel = SKLabelNode(fontNamed: "HiraginoSans-W6")
    let JLScale: CGFloat = 1.25  // 拡大縮小アニメーションの倍率
    
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
    var musicName: String       // 曲名
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
    private var BGMOffsetTime: TimeInterval = 0.0   // 経過時間とBGM.currentTimeのずれ。一定
    let lanes = [Lane(laneIndex: 0), Lane(laneIndex: 1), Lane(laneIndex: 2), Lane(laneIndex: 3), Lane(laneIndex: 4), Lane(laneIndex: 5), Lane(laneIndex: 6)]     // レーン
    
    private let speedRatio: CGFloat
    
    
    init(musicName: String, videoID: String, size: CGSize, speedRatioInt: UInt) {   // YouTube用
        if musicName == "ウラシオン" {
            self.musicName = "オラシオン"
            self.playMode = .YouTube2
        } else {
            self.musicName =  musicName
            self.playMode = .YouTube
        }
        self.speedRatio = CGFloat(speedRatioInt) / 100
        
        
        super.init(size: size)
        
        self.playerView = YTPlayerView(frame: self.frame)
        // 詳しい使い方はJump to Definitionへ
        if !(self.playerView.load(withVideoId: videoID, playerVars: ["autoplay": 1, "controls": 0, "playsinline": 1, "rel": 0, "showinfo": 0])) {
            print("ロードに失敗")
            
            // BGMモードへ移行
            let scene = GameScene(musicName: self.musicName, size: (view?.bounds.size)!, speedRatioInt: UInt(self.speedRatio*100))
            let skView = view as SKView?    // このviewはGameViewControllerのskView2
            skView?.showsFPS = true
            skView?.showsNodeCount = true
            skView?.ignoresSiblingOrder = true
            scene.scaleMode = .resizeFill
            skView?.presentScene(scene)  // GameSceneに移動
        }
        
    }
    
    init(musicName: String, size: CGSize, speedRatioInt: UInt) {    // BGM用
        self.musicName = musicName
        self.speedRatio = CGFloat(speedRatioInt) / 100
        self.playMode = .BGM
        
        
        super.init(size: size)
        
        // サウンドファイルのパスを生成
        let Path = Bundle.main.path(forResource: "Sounds/" + musicName, ofType: "mp3")!     // m4a,oggは不可
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
        
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func didMove(to view: SKView) {
        
        appDelegate = UIApplication.shared.delegate as! AppDelegate // AppDelegateのインスタンスを取得
        appDelegate.gsDelegate = self   // 子(AppDelegate)の設定しているdelegateに自身をセット
        
        self.view?.isMultipleTouchEnabled = true    // 恐らくデフォルトではfalseになってる
        self.view?.superview?.isMultipleTouchEnabled = true
        
        // 寸法に関する定数をセット
        Dimensions.createInstance(frame: self.frame)
        
        // notesにノーツの"　始　点　"を入れる(必ずcreateInstanceの後に実行)
        do {
            try parse(fileName: musicName + ".bms")
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
        
        
        BGMOffsetTime = (musicStartPos / BPMs[0].bpm) * 60

        if self.playMode == .BGM {
            startTime = CACurrentMediaTime()
            // BGMの再生(時間指定)
            BGM.play(atTime: CACurrentMediaTime() + BGMOffsetTime)  // 建築予定地
            BGM.delegate = self
            self.backgroundColor = .black
        } else {
            startTime = TimeInterval(pow(10.0, 308.0))  // Doubleのほぼ最大値。ロードが終わるまで。
            
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
            lanes[note.laneIndex].laneNotes.append(note)
            
            if let start = note as? TapStart {
                var following = start.next
                while(true) {
                    lanes[following.laneIndex].laneNotes.append(following)
                    if let middle = following as? Middle {
                        following = middle.next
                    } else {
                        break
                    }
                }
            }
        }
        for i in lanes { // レーンの設定
            i.isSetLaneNotes = true
            i.fjDelegate = self
        }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        
        // 経過時間の更新
        if self.playMode == .BGM {
            if BGM.currentTime > 0 {
                self.passedTime = BGM.currentTime + BGMOffsetTime
            } else {
                self.passedTime = CACurrentMediaTime() - startTime
            }
        } else {
            if isReadyPlayerView  { // currentTime>0は最初から成り立つ？
                self.passedTime = TimeInterval(playerView.currentTime()) + BGMOffsetTime
            } else {
                self.passedTime = CACurrentMediaTime() - startTime
            }
        }
        // ラベルの更新
        comboLabel.text = String(ResultScene.combo)
        
        // 各ノーツの位置や大きさを更新
        for note in notes {
            note.update(passedTime)
        }
        
        // 同時押しラインの更新
        for sameLine in sameLines {
            let (note1, note2, line) = (sameLine.note1, sameLine.note2, sameLine.line)
            // 同時押しラインを移動
            line.position = note1.position
            line.isHidden = note1.image.isHidden || note2.image.isHidden
            
            // 大きさも変更
            line.setScale(note1.image.xScale / Note.scale)
        }
        
        
        // 判定関係
        // middleの判定（同じところで長押しのやつ）
        judgeQueue.sync {
            
            
            for (touchIndex,value) in self.allTouches.enumerated() {
                
                var pos = value.touch.location(in: self.view?.superview)
                pos.y = self.frame.height - pos.y   // 上下逆転(画面下からのy座標に変換)
                
                guard pos.y < Dimensions.buttonHeight else {     // 以下、ボタンの判定圏内にあるtouchのみを処理する
                    continue
                }
                
                for (laneIndex,judgeXRange) in Dimensions.judgeXRanges.enumerated() {
                    
                    if judgeXRange.contains(pos.x) {   // ボタンの範囲
                        
                        if self.parfectMiddleJudge(lane: self.lanes[laneIndex]) { // middleの判定
                            
                            self.actionSoundSet.play(type: .middle)
                            self.allTouches[touchIndex].isJudgeableFlickEnd = true
                            break
                        }
                    }
                }
            }
            
            
            
            // レーンの監視(過ぎて行ってないか)とlaneのtimeLag更新
            for lane in self.lanes {
                lane.update(passedTime, self.BPMs)          // TODO: parfectMiddleJudgeとか他のところでも呼ばれてるから統一した方がいい？
                if lane.timeState == .passed && !(lane.laneNotes.isEmpty) {
                    
                    self.missJudge(lane: lane)
                }
            }
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
    
    
    
    
    // 再生終了時の呼び出しメソッド
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {    // playしたクラスと同じクラスに入れる必要あり？
        if player as AVAudioPlayer? == BGM {
            BGM = nil   // 別のシーンでアプリを再開したときに鳴るのを防止
            let scene = ResultScene(size: (view?.bounds.size)!)
            let skView = view as SKView?
            skView?.showsFPS = true
            skView?.showsNodeCount = true
            skView?.ignoresSiblingOrder = true
            scene.scaleMode = .resizeFill
            skView?.presentScene(scene)     // ResultSceneに移動
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("\(player)で\(String(describing: error))")
    }
    
    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        switch (state) {
            
        case .ended:
            playerView.removeFromSuperview()
            let scene = ResultScene(size: (view?.bounds.size)!)
            let skView = view as SKView?
            skView?.showsFPS = true
            skView?.showsNodeCount = true
            skView?.ignoresSiblingOrder = true
            scene.scaleMode = .resizeFill
            skView?.presentScene(scene)     // ResultSceneに移動
            
        case .unknown:
            print("unknown")
        default:
            break
        }
    }
    
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) { //読み込み完了後に呼び出される
        
        self.isReadyPlayerView = true
        DispatchQueue.main.asyncAfter(deadline: .now() + BGMOffsetTime) {
            playerView.playVideo()
        }
        startTime = CACurrentMediaTime()
    }
    
    func playerView(_ playerView: YTPlayerView, receivedError error: YTPlayerError) {   //エラー処理
        print(error)
        
        //BGMモードへ移行
        let scene = GameScene(musicName:self.musicName ,size: (view?.bounds.size)!, speedRatioInt:UInt(self.speedRatio*100))
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
    }
    
    //アプリを再開したときに呼ばれる
    func applicationDidBecomeActive() {
        actionSoundSet.stopAll()
        if self.playMode == .BGM{
            BGM?.currentTime -= 3   // 3秒巻き戻し
            BGM?.play()
        }else{
            playerView.seek(toSeconds: playerView.currentTime()-3, allowSeekAhead: true)
            playerView.playVideo()
        }
    }
    
}


// 寸法に関する定数を提供(シングルトン)。GameSceneのframeをもとに決定される。
class Dimensions {
    //インスタンスが保持し、このクラス内からの記述でのみアクセスできる変数。staticで呼び出されたときにこれらに格納されている値を返す。(frameが不要なものは初期値をここで定義)
    private let horizonLength: CGFloat              // 水平線の長さ
    private let horizonY: CGFloat                   // 水平線のy座標
    private let laneWidth: CGFloat                  // 3D上でのレーン幅(判定線における2D上のレーン幅と一致)
    private let laneLength: CGFloat                 // 3D上でのレーン長
    private let judgeLineY: CGFloat                 // 判定線のy座標
    private let buttonHeight: CGFloat          // ボタンの高さ(上の境界のy座標)
    private var buttonX: [CGFloat] = []             // 各レーンの中心のx座標
    private var judgeXRanges: [Range<CGFloat>] = [] // 各レーンの判定をするx座標についての範囲
    // 立体感を出すための定数
    private let horizontalDistance: CGFloat = 250   // 画面から目までの水平距離a（約5000で10cmほど）
    private let verticalDistance: CGFloat           // 画面を垂直に見たとき、判定線から目までの高さh（実際の水平線の高さでもある）
    private let R: CGFloat                          // 視点から判定線までの距離(射影する球の半径)
   
    private static var instance: Dimensions?        // 唯一のインスタンス
    
    private init(frame: CGRect) {   // インスタンスの作成をこのクラス内のみに限定する
        let halfBound = frame.width / 10   // 判定を汲み取る、ボタン中心からの距離。1/18~1/9の値にすること
        self.laneWidth = frame.width / 9
        // モデルに合わせるなら水平線は画面上端辺りが丁度いい？モデルに合わせるなら大きくは変えてはならない。
        self.horizonY = frame.height * 15 / 16  // モデル値
        self.judgeLineY = frame.width / 9
        self.buttonHeight = frame.height / 3
        self.verticalDistance = horizonY - frame.width / 14
        self.R = sqrt(pow(horizontalDistance, 2) + pow(verticalDistance, 2))
        
        let laneHeight = horizonY - judgeLineY              // レーンの高さ(画面上)
        self.laneLength = pow(R, 2) / (verticalDistance / tan(laneHeight/R) - horizontalDistance)   // レーン長(3D)
        self.horizonLength = 2 * horizontalDistance * atan(laneWidth * 7/2 / (horizontalDistance + laneLength))
        
        // ボタンの位置をセット
        for i in 0...6 {
            buttonX.append(frame.width/6 + CGFloat(i)*laneWidth)
        }
        
        self.judgeXRanges = buttonX.map({ $0 - halfBound ..< $0 + halfBound })
    }
    
    // これらクラスプロパティから、定数にアクセスする(createInstanceされてなければ全て0)
    static var horizonLength:      CGFloat         { return Dimensions.instance?.horizonLength      ??  CGFloat(0)        }
    static var horizonY:           CGFloat         { return Dimensions.instance?.horizonY           ??  CGFloat(0)        }
    static var laneWidth:          CGFloat         { return Dimensions.instance?.laneWidth          ??  CGFloat(0)        }
    static var laneLength:         CGFloat         { return Dimensions.instance?.laneLength         ??  CGFloat(0)        }
    static var judgeLineY:         CGFloat         { return Dimensions.instance?.judgeLineY         ??  CGFloat(0)        }
    static var buttonHeight:       CGFloat         { return Dimensions.instance?.buttonHeight  ??  CGFloat(0)        }
    static var horizontalDistance: CGFloat         { return Dimensions.instance?.horizontalDistance ??  CGFloat(0)        }
    static var verticalDistance:   CGFloat         { return Dimensions.instance?.verticalDistance   ??  CGFloat(0)        }
    static var R:                  CGFloat         { return Dimensions.instance?.R                  ??  CGFloat(0)        }
    static var buttonX:           [CGFloat]        { return Dimensions.instance?.buttonX            ?? [CGFloat]()        }
    static var judgeXRanges:      [Range<CGFloat>] { return Dimensions.instance?.judgeXRanges       ?? [Range<CGFloat>]() }
    // この関数のみが唯一Dimensionsクラスをインスタンス化できる
    static func createInstance(frame: CGRect) {
        // 初回のみ有効
        if self.instance == nil {
            self.instance = Dimensions(frame: frame)
        }
    }
}








