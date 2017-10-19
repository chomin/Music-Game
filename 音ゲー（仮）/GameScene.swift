
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

class GameScene: SKScene, AVAudioPlayerDelegate {//音ゲーをするシーン
	
	//タッチ情報
	var allTouchesLocation:[CGPoint] = []
	
	//ラベル
	var judgeLabel = SKLabelNode(fontNamed: "HiraginoSans-W6")
	var comboLabel = SKLabelNode(fontNamed: "HiraginoSans-W6")
	let JLScale:CGFloat = 1.25	//拡大縮小アニメーションの倍率
	
	
	//音楽プレイヤー
	static var BGM:AVAudioPlayer?
	var flickSound1:AVAudioPlayer?    //同時に鳴らせるように2つ作る。多すぎると（多分）重いので２つにしておく。やっぱり２つだと遅延も起こるので４つ
	var flickSound2:AVAudioPlayer?
	var tapSound1:AVAudioPlayer?
	var tapSound2:AVAudioPlayer?
	var tapSound3:AVAudioPlayer?
	var tapSound4:AVAudioPlayer?
	var kara1:AVAudioPlayer?
	var kara2:AVAudioPlayer?
	var tapSoundResevation = 0
	var flickSoundResevation = 0
	var karaSoundResevation = 0
	var nextPlayTapNumber = 1

	
	
	//画像(ノーツ以外)
	var judgeLine:SKShapeNode!
	var sameLines:[(note:Note,line:SKShapeNode)] = []	//連動する始点側のノーツと同時押しライン
	
	// 楽曲データ
	init(musicName:String ,size:CGSize) {
		super.init(size:size)
		
		switch musicName {
		case "シュガーソングとビターステップ":
			bmsName = "シュガーソングとビターステップ.bms"
			bgmName = "シュガビタ"
		case "ようこそジャパリパークへ":
			bmsName = "ようこそジャパリパークへ.bms"
			bgmName = "ようこそジャパリパークへ"
		case "オラシオン":
			bmsName = "オラシオン.bms"
			bgmName = "オラシオン"
		case "This game":
			bmsName = "This game.bms"
			bgmName = "This game"
		case "SAKURAスキップ":
			bmsName = "SAKURAスキップ.bms"
			bgmName = "SAKURAスキップ"
		default:
			break
		}
	}
	
	
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	var bmsName = "オラシオン.bms"
	var bgmName = "オラシオン"
	var notes:[Note] = []	//ノーツの" 始 点 "の集合。参照型！
	static var start:TimeInterval = 0.0	  //シーン移動した時の時間
	static var resignActiveTime:TimeInterval = 0.0
	var musicStartPos = 1.0	  //BGM開始の"拍"！
	var playLebel = 0
	var genre = ""				// ジャンル
	var title = ""				// タイトル
	var artist = ""				// アーティスト
	static var bpm = 132.0		// Beats per Minute
	var playLevel = 0			// 難易度
	var volWav = 100			// 音量を現段階のn%として出力するか(TODO: 未実装)
	var lanes:[Lane] = [Lane(),Lane(),Lane(),Lane(),Lane(),Lane(),Lane()]		//レーン
	
	static var horizon:CGFloat = 0  	// 水平線の長さ
	static var horizonY:CGFloat = 0 	// 水平線のy座標
	static var laneWidth:CGFloat = 0	// 3D上でのレーン幅(判定線における2D上のレーン幅と一致)
	static var judgeLineY:CGFloat = 0	// 判定線のy座標
	//立体感を出すための定数
	static let horizontalDistance:CGFloat = 250		//画面から目までの水平距離a（約5000で10cmほど）
	static var verticalDistance:CGFloat!//画面を垂直に見たとき、判定線から目までの高さh（実際の水平線の高さでもある）
	
	
	var halfBound:CGFloat! // 判定を汲み取る、ボタン中心からの距離。1/18~1/9の値にすること
	
	var buttonX:[CGFloat] = []
	
	override func didMove(to view: SKView) {
		
		//ボタンの位置をセット
		for i in 0...6{
			buttonX.append(self.frame.width/6 + CGFloat(i)*self.frame.width/9)
		}
		
		//リザルトの初期化
		ResultScene.parfect = 0
		ResultScene.great = 0
		ResultScene.good = 0
		ResultScene.bad = 0
		ResultScene.miss = 0
		ResultScene.combo = 0
		ResultScene.maxCombo = 0
		
		
		halfBound = self.frame.width/12	//1/18~1/9の値にすること
		GameScene.laneWidth = self.frame.width/9
		GameScene.horizonY = self.frame.height*15/16	//モデル値
		
		GameScene.verticalDistance = GameScene.horizonY - self.frame.width/14
		//モデルに合わせるなら水平線は画面上端辺りが丁度いい？モデルに合わせるなら大きくは変えてはならない。
		
		let laneHeight = GameScene.horizonY - self.frame.width/9
		let L = (GameScene.horizontalDistance * laneHeight)/(GameScene.verticalDistance - laneHeight)
		
//		GameScene.horizon = self.frame.width/16	  // TODO: 厳密な公式あり
		GameScene.horizon = 7*GameScene.laneWidth*GameScene.horizontalDistance/(GameScene.horizontalDistance+L)
		
		GameScene.judgeLineY = self.frame.width/9
		
		//		verticalDistance = self.frame.width/9 + (GameScene.horizonY-self.frame.width/9)*1.1
		//		verticalDistance = GameScene.horizonY - self.frame.width/24
		print(GameScene.horizonY-self.frame.width/9)	//判定線から水平線までの画面上での幅。277くらい
		
		//ラベルの設定
		judgeLabel = {() -> SKLabelNode in
			let Label = SKLabelNode(fontNamed: "HiraginoSans-W6")
			
			Label.fontSize = self.frame.width/36
			Label.horizontalAlignmentMode = .center	//中央寄せ
			Label.position = CGPoint(x:self.frame.midX, y:self.frame.width/9*2)
			Label.fontColor=SKColor.yellow
			
			self.addChild(Label)
			return Label
		}()
		comboLabel = {() -> SKLabelNode in
			let Label = SKLabelNode(fontNamed: "HiraginoSans-W6")
			
			Label.fontSize = self.frame.width/18
			Label.horizontalAlignmentMode = .center	//中央寄せ
			Label.position = CGPoint(x:self.frame.width - Label.fontSize*2, y:self.frame.height*3/4)
			Label.fontColor=SKColor.white
			
			self.addChild(Label)
			return Label
		}()
		
		//notesにノーツの"　始　点　"を入れる(nobuの仕事)
		do {
			try parse(fileName: bmsName)
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
		
		// 全ノーツ及び関連画像をGameSceneにaddChild(この全ノーツにアクセスするアルゴリズムは以降しばしば出てくる)
		for note in notes {
			self.addChild(note.image)			// 始点及び単ノーツをaddChild
			if let start = note as? TapStart {	// ダウンキャスト
				// ロング始点に付随する緑太線と緑円をaddChild
				self.addChild(start.longImages.circle)
				self.addChild(start.longImages.long)
				
				var following = start.next
				while(true) {
					self.addChild((following?.image)!)
					if let middle = following as? Middle {	// ダウンキャスト
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
		
		//画像、音楽、ラベルの設定
		setAllSounds()
		setImages()
		
		//BGMの再生(時間指定)
		GameScene.start = CACurrentMediaTime()
		GameScene.BGM!.play(atTime: GameScene.start + (musicStartPos/GameScene.bpm)*60)
		GameScene.BGM?.delegate = self
		
		//各レーンにノーツをセット
		for note in notes{
			lanes[note.lane].laneNotes.append(note)
			
			if let start = note as? TapStart {
				var following = start.next
				while(true) {
					lanes[(following?.lane)!].laneNotes.append(following!)
					if let middle = following as? Middle {
						following = middle.next
					} else {
						break
					}
				}
			}
		}
	}
	
	
	override func update(_ currentTime: TimeInterval) {
		
		//鳴らしそびれた音があれば鳴らす
		if tapSoundResevation > 0{
			print("tap予約発動")
			playSound(type: .tap)
			
			tapSoundResevation -= 1
		}
		if flickSoundResevation > 0{
			playSound(type: .flick)
			flickSoundResevation -= 1
		}
		if karaSoundResevation > 0{
			playSound(type: .kara)
			karaSoundResevation -= 1
		}
		
		//ラベルの更新
		comboLabel.text = String(ResultScene.combo)
		
		
		
		
		
		
		
		
		
		
		/* ここからリファクタリング */
		
		
		//時間でノーツの位置を設定する(重くなるので近場のみ！)
		for note in notes {
			
			let remainingBeat = note.pos - ((currentTime - GameScene.start) * GameScene.bpm/60)    // あと何拍で判定ラインに乗るか
			
			// まずロングノーツと単ノーツで場合分け
			if let start = note as? TapStart {//ロングの始点
				// ロングノーツを更新
//				let remainingBeat2 = start.next.pos - ((currentTime - GameScene.start) * GameScene.bpm/60)    // 次ノーツがあと何拍で判定ラインに乗るか
				// 位置を設定(水平線より上でもロング先に必要、" 判 定 後 で も "ロング初めに必要、判定線過ぎても判定前なら普通に必要)
//				if ((start.isJudged == false || remainingBeat > 0) && remainingBeat < 8) || (remainingBeat2 > 0 && remainingBeat2 < 8) {
					start.update(currentTime: currentTime)		// 大きさや位置を更新
//				}
				
				var following = start.next		// 親を持つノーツ
				while(true) {
					if let middle = following as? Middle {		// 次のノーツがMiddleだったとき
						
//						let remainingBeat2 = middle.next.pos - ((currentTime - GameScene.start) * GameScene.bpm/60)	// ロングに必要なので次ノーツについて判断
//						if (middle.next.isJudged == false || remainingBeat2 > 0) && remainingBeat2 < 8 {	// 次ノーツが描画域内にあるか、過ぎていても判定前なら更新
							middle.update(currentTime: currentTime)		// 更新
//						}
						
						following = middle.next
					} else {									// 次のノーツがTapEndかFlickEndだったとき
						
//						let remainingBeat = (following?.pos)! - ((currentTime - GameScene.start) * GameScene.bpm/60)
//						if (following?.isJudged == false || remainingBeat > 0) && remainingBeat < 8 {	// 描画域内にあるか、過ぎていても判定前なら更新
							following?.update(currentTime: currentTime)		// 更新
//						}
						
						break
					}
				}
			} else {
				// 単ノーツを更新
				// 判定線より上で判定線まで8拍以内のもの及び、判定線を過ぎていても判定前のものについて
				if (note.isJudged == false || remainingBeat > 0) && remainingBeat < 8 {
					note.update(currentTime: currentTime)		// 大きさや位置を更新
				}
			}
		}
		
		
		
		
		
//		//時間でノーツの位置を設定する(重くなるので近場のみ！)
//		for i in notes{
//
//            // 単ノーツと始点を描画
//
//			let remainingBeat = i.pos - ((currentTime - GameScene.start) * GameScene.bpm/60)    // あと何拍で判定ラインに乗るか
//            //位置を設定(水平線より上でもロング先に必要、判定後でもロング初めに必要、判定線過ぎても判定前なら普通に必要)
//			if (i.isJudged == false || remainingBeat > 0) && remainingBeat < 8{
//				setPos(note: i, currentTime: currentTime)
//				if i.next != nil{	//つながっている1つ先までは描く
//					setPos(note: i.next, currentTime: currentTime)
//				}
//				//				if i.type == .flickEnd || i.type == .tapEnd || i.type == .middle{//先ノーツになりうるものは無条件に描く
//				//					setPos(note: i, currentTime: currentTime)
//				//				}else if remainingBeat < 8{
//				//					setPos(note: i, currentTime: currentTime)
//				//				}
//			}
//			if i.image.position.y > GameScene.horizonY || remainingBeat > 8 || i.isJudged == true{//水平線より上、8拍以上残っている、判定済みのものは隠す
//				i.image.isHidden = true
//			}else{
//				i.image.isHidden = false
//			}
//
//
//			// 始点につながっているノーツを描画
//
//			var note:Note = i
//			while note.next != nil{
//                note = note.next
//
//				let remainingBeat2 = note.pos - ((currentTime - GameScene.start) * GameScene.bpm/60)
//				if (note.isJudged == false || remainingBeat2 > 0) && remainingBeat2 < 8{//-4拍以上のものは位置を設定(水平線より上でもロング結びに必要)
//
//					setPos(note: note, currentTime: currentTime)
//
//					if note.next != nil{
//						setPos(note: note.next!, currentTime: currentTime)
//					}
//					//					if note?.next.type == .flickEnd || note?.next.type == .tapEnd || note?.next.type == .middle{//先ノーツになりうるものは無条件に描く
//					//						setPos(note: (note?.next)!, currentTime: currentTime)
//					//					}else if remainingBeat2 < 8{
//					//						setPos(note: (note?.next)!, currentTime: currentTime)
//					//					}
//				}
			
//				if note.image.position.y > GameScene.horizonY || remainingBeat2 > 12 || note.isJudged == true{//水平線より上、12拍以上残っている、判定済みのものは隠す
//					note.image.isHidden = true
//				}else{
//					note.image.isHidden = false
//				}
//			}
//		}
//
		
		
		
		
		
		
		
		
		
		
		
//		//緑太線の描写
//		for i in notes{
//
//			let remainingBeat = i.pos - ((currentTime - GameScene.start) * GameScene.bpm/60)
//
//			if i.next != nil{
//				if (i.next.image.position.y < self.frame.width/9 || i.next.isJudged == true) && i.longImage != nil{//先ノーツが判定線を通過したあとか、判定されたあとなら除去
//					self.removeChildren(in: [i.longImage])
//					i.longImage = nil	//複数回removeされるのを防ぐため、nilにする
//				}else if remainingBeat < 4 && i.next.image.position.y > self.frame.width/9 && i.next.isJudged == false && i.image.position.y < GameScene.horizonY{
//
//					//毎フレーム描き直す
//					setLong(firstNote: i, currentTime: currentTime)
//				}
//			}
//
//			//つながっているノーツ
//			var note:Note = i
//			while note.next != nil{
//                note = note.next
//
//				let remainingBeat2 = note.pos - ((currentTime - GameScene.start) * GameScene.bpm/60)
//
//				if note.next != nil {
//					if (note.next.image.position.y < self.frame.width/9 || note.next.isJudged == true) && note.longImage != nil{//先ノーツが判定線を通過したあとか、判定されたあとなら除去
//						self.removeChildren(in: [note.longImage])
//						note.longImage = nil
//					}else if remainingBeat2 < 4 && note.next.image.position.y > self.frame.width/9 && note.next.isJudged == false && note.image.position.y < GameScene.horizonY!{
//
//						//毎フレーム描き直す
//
//						setLong(firstNote: note, currentTime: currentTime)
//					}
//				}
//			}
//		}
//
		
		
		
		
		
		
		
		
		
		
		
		
		
		/* ここまで */
		
		
		
		
		
		
		
		
		// 同時押しラインの更新
		for i in sameLines{
            // 同時押しラインを移動
			i.line.position = i.note.position
//			i.line.isHidden = i.note.image.isHidden
			if i.note.isJudged || i.note.position.y == 0{//判定後または初期初期位置では隠す
				i.line.isHidden = true
			}else{
				i.line.isHidden = false
			}
			
			// 大きさも変更
			let a = (GameScene.horizon/7 - self.frame.width/9) / (GameScene.horizonY - self.frame.width/9)
			let diameter = a*(i.line.position.y - GameScene.horizonY) + GameScene.horizon/7
			
			i.line.setScale(diameter/GameScene.laneWidth)
		}
		
		
		//判定関係
		//middleの判定（同じところで長押しのやつ）
		for i in allTouchesLocation{
			if i.y < self.frame.width/3{    //上界
				
				for j in 0...6{
					
					let buttonPos = self.frame.width/6 + CGFloat(j)*self.frame.width/9
					
					if i.x > buttonPos - halfBound && i.x < buttonPos + halfBound {//ボタンの範囲
						
						if parfectMiddleJudge(laneIndex: j){//離しの判定(←コメントミス？)
							
							playSound(type: .tap)
							break
						}
					}
				}
			}
		}
		
		
		//レーンの監視(過ぎて行ってないか)
		for (index,value) in lanes.enumerated(){
			lanes[index].currentTime = currentTime
			if value.timeState == .passed {
				setJudgeLabelText(text: "miss!")
				ResultScene.miss += 1
				ResultScene.combo = 0
				self.removeChildren(in: [lanes[index].laneNotes[value.nextNoteIndex].image])	//ここで消しても大丈夫なはず
				lanes[index].laneNotes[value.nextNoteIndex].isJudged = true
				
				//次のノーツを格納
				lanes[index].nextNoteIndex += 1
			}
		}
	}
	
	
	//判定ラベルのテキストを更新（アニメーション付き）
	func setJudgeLabelText(text:String){
		
		judgeLabel.text = text
		
		judgeLabel.removeAllActions()
		
		let set = SKAction.scale(to: 1/JLScale, duration: 0)
		let add = SKAction.unhide()
		let scale = SKAction.scale(to: 1, duration: 0.07)
		let pause = SKAction.wait(forDuration: 3)
		let hide = SKAction.hide()
		let seq = SKAction.sequence([set,add,scale,pause,hide])
		
		judgeLabel.run(seq)
	}
	
	//タッチ関係
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		
		for i in touches {//すべてのタッチに対して処理する（同時押しなどもあるため）
			
			var pos = i.location(in: self.view)
			
			pos.y = self.frame.height - pos.y //上下逆転(画面下からのy座標に変換)
			
			allTouchesLocation.append(pos)
			
			if pos.y < self.frame.width/3{    //上界
				
				var doKara = false
				
				//				switch pos.x{
				//				case self.frame.width/6 - halfBound ... self.frame.width*5/18 - halfBound:
				//
				//				}
				
				for (index,buttonPos) in buttonX.enumerated(){
					
					if pos.x > buttonPos - halfBound && pos.x < buttonPos + halfBound {//ボタンの範囲
						
						if judge(laneIndex: index, type: .tap){//タップの判定
							
							playSound(type: .tap)
							doKara = false
							break
							
						}else if judge(laneIndex: index, type: .tapStart){//始点の判定
							
							playSound(type: .tap)
							doKara = false
							break
							
						}else if lanes[index].timeState == .still{
							doKara = true
						}
					}
				}
				
				if doKara == true{//
					playSound(type: .kara)
				}
			}
		}
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		
		for i in touches{
			
			var pos = i.location(in: self.view)
			var ppos = i.previousLocation(in: self.view)
			let moveDistance = sqrt(pow(pos.x-ppos.x, 2) + pow(pos.y-ppos.y, 2))
			
			pos.y = self.frame.height - pos.y //上下逆転(画面下からのy座標に変換)
			ppos.y = self.frame.height - ppos.y
			
			allTouchesLocation[allTouchesLocation.index(of: ppos)!] = pos
			
			if pos.y < self.frame.width/3{    //上界
				
				for (index,buttonPos) in buttonX.enumerated(){
					
					if pos.x > buttonPos - halfBound && pos.x < buttonPos + halfBound {//ボタンの範囲
						
						//						if parfectMiddleJudge(laneNum: j+1){//途中線の判定
						//
						//							playSound(type: .tap)
						//							break
						//						}
					}
					if ppos.x > buttonPos - halfBound && ppos.x < buttonPos + halfBound{
						if moveDistance > 10{	//フリックの判定
							
							if judge(laneIndex: index, type: .flick) || judge(laneIndex: index, type: .flickEnd){
								
								playSound(type: .flick)
								break
							}
						}
					}
				}
			}
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		
		for i in touches {
			
			var pos = i.location(in: self.view)
			var ppos = i.previousLocation(in: self.view)
			
			pos.y = self.frame.height - pos.y //上下逆転(画面下からのy座標に変換)
			ppos.y = self.frame.height - ppos.y
			
			allTouchesLocation.remove(at: allTouchesLocation.index(of: ppos)!)
			
			if pos.y < self.frame.width/3{    //上界
				
				for (index,buttonPos) in buttonX.enumerated(){
					
					if pos.x > buttonPos - halfBound && pos.x < buttonPos + halfBound {//ボタンの範囲
						
						if judge(laneIndex: index, type: .tapEnd){//離しの判定
							
							playSound(type: .tap)
							break
						}
					}
				}
			}
		}
	}
	
	
	//再生終了時の呼び出しメソッド
	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {//playしたクラスと同じクラスに入れる必要あり？
		if player as AVAudioPlayer! == GameScene.BGM{
			GameScene.BGM = nil	//別のシーンでアプリを再開したときに鳴るのを防止
			let scene = ResultScene(size: (view?.bounds.size)!)
			let skView = view as SKView!
			skView?.showsFPS = true
			skView?.showsNodeCount = true
			skView?.ignoresSiblingOrder = true
			scene.scaleMode = .resizeFill
			skView?.presentScene(scene)  //ResultSceneに移動
		}
	}
	
	func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
		print("\(player)で\(String(describing: error))")
	}
	
	//アプリが閉じそうなときに呼ばれる(AppDelegate.swiftから)
	static func willResignActive(){
		
	}
	
	//アプリを再開したときに呼ばれる
	static func didBecomeActive(){
		
	}
	
}


enum TimeState {
	case miss,bad,good,great,parfect,still,passed
}

struct Lane {
	var timeState:TimeState{
		get{
			if laneNotes.count > 0 && nextNoteIndex < laneNotes.count{
				
				let timeLag = laneNotes[nextNoteIndex].pos*60/GameScene.bpm + GameScene.start - currentTime
				
				switch timeLag>0 ? timeLag : -timeLag {
				case 0..<0.05:
					return .parfect
				case 0.05..<0.1:
					return .great
				case 0.1..<0.125:
					return .good
				case 0.125..<0.15:
					return .bad
				case 0.15..<0.175:
					return .miss
				default:
					if timeLag > 0{
						return .still
					}else{
						return .passed
					}
				}
			}else{
				return .still
			}
		}
	}
	var nextNoteIndex = 0
	var currentTime:TimeInterval = 0.0
	var laneNotes:[Note] = [] //最初に全部格納する！
}

