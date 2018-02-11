
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
	
	//
//	let judgeQueue = DispatchQueue(label: "judge_queue")	//キューに入れた処理内容を順番に実行（updateとtouchesシリーズから呼び出されるjudgeの並列処理防止用）
	
	//タッチ情報
	var allTouches:[(touch:UITouch, isJudgeableFlick:Bool, isJudgeableFlickEnd:Bool)] = []
	
	//ラベル
	var judgeLabel = SKLabelNode(fontNamed: "HiraginoSans-W6")
	var comboLabel = SKLabelNode(fontNamed: "HiraginoSans-W6")
	let JLScale:CGFloat = 1.25	//拡大縮小アニメーションの倍率
	
	//音楽プレイヤー
	static var BGM: AVAudioPlayer?
	let actionSoundSet = ActionSoundPlayers()

	
	//画像(ノーツ以外)
	var judgeLine:SKShapeNode!
	var sameLines:[(note:Note,line:SKShapeNode)] = []	//連動する始点側のノーツと同時押しライン
	
	// 楽曲データ
	var musicName: String
	var notes:[Note] = []	//ノーツの" 始 点 "の集合。参照型！
	static var start:TimeInterval = 0.0	  //シーン移動した時の時間
	static var resignActiveTime:TimeInterval = 0.0
	var musicStartPos = 1.0	  //BGM開始の"拍"！
	var playLebel = 0
	var genre = ""				// ジャンル
	var title = ""				// タイトル
	var artist = ""				// アーティスト
//	static var bpm = 132.0			// Beats per Minute
//	//static var bpm:[(bpm:Double,startPos:Double)] = []	//建築予定地
	var playLevel = 0			// 難易度
	var volWav = 100			// 音量を現段階のn%として出力するか(TODO: 未実装)
	static var variableBPMList: [(bpm: Double, startPos: Double)] = []		// 可変BPM情報
	var lanes:[Lane] = [Lane(laneIndex:0),Lane(laneIndex:1),Lane(laneIndex:2),Lane(laneIndex:3),Lane(laneIndex:4),Lane(laneIndex:5),Lane(laneIndex:6)]		// レーン
	
	static var horizon:CGFloat = 0  	// 水平線の長さ
	static var horizonY:CGFloat = 0 	// 水平線のy座標
	static var laneWidth:CGFloat = 0	// 3D上でのレーン幅(判定線における2D上のレーン幅と一致)
	static var laneLength:CGFloat = 0	// 3D上でのレーン長
	static var judgeLineY: CGFloat = 0	// 判定線のy座標
	// 立体感を出すための定数
	static let horizontalDistance:CGFloat = 250		// 画面から目までの水平距離a（約5000で10cmほど）
	static var verticalDistance:CGFloat!			// 画面を垂直に見たとき、判定線から目までの高さh（実際の水平線の高さでもある）
	
	
	var halfBound:CGFloat! // 判定を汲み取る、ボタン中心からの距離。1/18~1/9の値にすること
	
	var buttonX:[CGFloat] = []
	
	
	init(musicName:String ,size:CGSize) {
		self.musicName = musicName
		super.init(size:size)
		
		// サウンドファイルのパスを生成
		let Path = Bundle.main.path(forResource: "Sounds/" + musicName, ofType: "mp3")!    //m4a,oggは不可
		let soundURL:URL = URL(fileURLWithPath: Path)
		// AVAudioPlayerのインスタンスを作成
		do {
			GameScene.BGM = try AVAudioPlayer(contentsOf: soundURL, fileTypeHint: "public.mp3")
		} catch {
			print("AVAudioPlayerインスタンス作成失敗")
		}
		// バッファに保持していつでも再生できるようにする
		GameScene.BGM?.prepareToPlay()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	
	override func didMove(to view: SKView) {
		
		halfBound = self.frame.width/12	//1/18~1/9の値にすること
		GameScene.laneWidth = self.frame.width/9
		//モデルに合わせるなら水平線は画面上端辺りが丁度いい？モデルに合わせるなら大きくは変えてはならない。
		GameScene.horizonY = self.frame.height*15/16	//モデル値
		GameScene.judgeLineY = self.frame.width/9
		GameScene.verticalDistance = GameScene.horizonY - self.frame.width/14	// GameScene.horizonY - self.frame.width/14
		
		let R = sqrt(pow(GameScene.horizontalDistance, 2) + pow(GameScene.verticalDistance!, 2))	// 視点から判定線までの距離(射影する球の半径)
		let laneHeight = GameScene.horizonY - GameScene.judgeLineY									// レーンの高さ(画面上)
		GameScene.laneLength = pow(R, 2) / (GameScene.verticalDistance / tan(laneHeight/R) - GameScene.horizontalDistance)	// レーン長(3D)
		GameScene.horizon = 2 * GameScene.horizontalDistance * atan(GameScene.laneWidth * 7/2 / (GameScene.horizontalDistance + GameScene.laneLength))
		
		
		//ボタンの位置をセット
		for i in 0...6{
			buttonX.append(self.frame.width/6 + CGFloat(i)*GameScene.laneWidth)
		}
		
		//リザルトの初期化
		ResultScene.parfect = 0
		ResultScene.great = 0
		ResultScene.good = 0
		ResultScene.bad = 0
		ResultScene.miss = 0
		ResultScene.combo = 0
		ResultScene.maxCombo = 0
		
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
		
		// 全ノーツ及び関連画像をGameSceneにaddChild
		for note in notes {
			self.addChild(note.image)			// 始点及び単ノーツをaddChild
			if let start = note as? TapStart {	// ダウンキャスト
				// ロング始点に付随する緑太線と緑円をaddChild
				self.addChild(start.longImages.circle)
				self.addChild(start.longImages.long)
				
				var following = start.next
				while(true) {
					self.addChild(following.image)
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
		//		setAllSounds()
		setImages()
		
		// BGMの再生(時間指定)
		GameScene.start = CACurrentMediaTime()
		GameScene.BGM?.play(atTime: GameScene.start + (musicStartPos/GameScene.variableBPMList[0].bpm)*60)	//建築予定地
		GameScene.BGM?.delegate = self
		
		//各レーンにノーツをセット
		for note in notes{
			lanes[note.lane].laneNotes.append(note)
			
			if let start = note as? TapStart {
				var following = start.next
				while(true) {
					lanes[following.lane].laneNotes.append(following)
					if let middle = following as? Middle {
						following = middle.next
					} else {
						break
					}
				}
			}
		}
		for i in lanes{
			i.isSetLaneNotes = true
		}
		
		//		//bpmのstartTimeを計算してセット
		//		for (index,i) in GameScene.variableBPMList.enumerated(){
		//			if index == 0{
		//				GameScene.variableBPMList[index].startTime = GameScene.start
		//			}else{
		//				GameScene.variableBPMList[index].startTime = GameScene.variableBPMList[index-1].startTime! + (i.startPos - GameScene.variableBPMList[index-1].startPos) / GameScene.variableBPMList[index-1].bpm * 60
		//			}
		//		}
	}
	
	
	override func update(_ currentTime: TimeInterval) {
		
		//ラベルの更新
		comboLabel.text = String(ResultScene.combo)
		
		// 各ノーツの位置や大きさを更新
		for note in notes {
			note.update(currentTime: currentTime)
		}
		
		// 同時押しラインの更新
		for i in sameLines{
			// 同時押しラインを移動
			i.line.position = i.note.position
			i.line.isHidden = i.note.image.isHidden
			
			// 大きさも変更
			i.line.setScale(i.note.image.xScale / i.note.noteScale)
		}
		
		
		//判定関係
		//middleの判定（同じところで長押しのやつ）
		//		judgeQueue.async {
		
		
		for i in self.allTouches{
			var pos = i.touch.location(in: self.view)
			pos.y = self.frame.height - pos.y //上下逆転(画面下からのy座標に変換)
			
			if pos.y < self.frame.width/3{    //上界
				
				for j in 0...6{
					
					let buttonPos = self.frame.width/6 + CGFloat(j)*self.frame.width/9
					
					if pos.x > buttonPos - self.halfBound && pos.x < buttonPos + self.halfBound {//ボタンの範囲
						
						if self.parfectMiddleJudge(laneIndex: j, currentTime: currentTime){//middleの判定
							
							self.actionSoundSet.play(type: .middle)
							break
						}
					}
				}
			}
		}
		//			}
		
		
		
		//レーンの監視(過ぎて行ってないか)とlaneのtimeLag更新
		for lane in lanes {
			lane.update(currentTime: currentTime)
			if lane.timeState == .passed {
				setJudgeLabelText(text: "miss!")
				ResultScene.miss += 1
				ResultScene.combo = 0
				self.removeChildren(in: [lane.laneNotes[lane.nextNoteIndex].image])	//ここで消しても大丈夫なはず
				lane.laneNotes[lane.nextNoteIndex].isJudged = true
				
				//次のノーツを格納
				lane.nextNoteIndex += 1
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
		for i in self.lanes{
			
			if !(i.isTimeLagRenewed){ return }
		}
		
//		judgeQueue.async {
			for i in touches {//すべてのタッチに対して処理する（同時押しなどもあるため）
				
				var pos = i.location(in: self.view)
				
				pos.y = self.frame.height - pos.y //上下逆転(画面下からのy座標に変換)
				
				
				//フリック判定したかを示すBoolを加えてallTouchにタッチ情報を付加
				self.allTouches.append((i,true,true))
				
				if pos.y < self.frame.width/3{    //上界
					
					//判定対象を選ぶため、押された範囲のレーンから最近ノーツを取得
					var nearbyNotes:[(laneIndex:Int, timelag:TimeInterval, note:Note)] = []
					for (index,buttonPos) in self.buttonX.enumerated(){
						
						if pos.x >= buttonPos - self.halfBound && pos.x < buttonPos + self.halfBound {//ボタンの範囲
							
							if (self.lanes[index].timeState == .still)  || (self.lanes[index].timeState == .passed) { continue }
							
							let nextIndex = lanes[index].nextNoteIndex
							if (nextIndex > lanes[index].laneNotes.count-1) { continue }
							let note = lanes[index].laneNotes[nextIndex]
							
							if self.lanes[index].isObserved == .Behind {//middleの判定圏内（後）
								nearbyNotes.append((laneIndex: index, timelag: self.lanes[index].timeLag, note: note))
								continue
							}
							
							
							if (note is Tap) || (note is Flick) || (note is TapStart) {//flickが最近なら他を無視（ここでは判定しない）
								nearbyNotes.append((laneIndex: index, timelag: self.lanes[index].timeLag, note: note))
								continue
							}
						}
					}
					
					if nearbyNotes.isEmpty {
						self.actionSoundSet.play(type: .kara)
					}else{
						nearbyNotes.sort(by: {$0.timelag < $1.timelag})
						if (nearbyNotes[0].note is Tap) || (nearbyNotes[0].note is TapStart) {
							if self.judge(laneIndex: nearbyNotes[0].laneIndex, timeLag: nearbyNotes[0].timelag) {
								self.actionSoundSet.play(type: .tap)
								self.allTouches[self.allTouches.count-1].isJudgeableFlick = false	//このタッチでのフリック判定を禁止
							}else{
								
								print("判定失敗:tap")
							}
						}
					}
						
						
						
					
					
//					var doKara = false
//
//					for (index,buttonPos) in self.buttonX.enumerated(){
//
//						if pos.x >= buttonPos - self.halfBound && pos.x < buttonPos + self.halfBound {//ボタンの範囲
//
//
//
//							if self.lanes[index].isObserved == .Behind {//middleの判定圏内（後）
//
//								//parfect時に該当ボタンにいなければ、入ってきた時間で判定
//								if self.judge(laneIndex: index, type: .middle){
//									self.actionSoundSet.play(type: .middle)
//									doKara = false
//									break
//
//								}
//							}
//
//							if self.judge(laneIndex: index, type: .tap) {//タップの判定
//
//								self.actionSoundSet.play(type: .tap)
//								doKara = false
//								break
//
//							}else if self.judge(laneIndex: index, type: .tapStart) {//始点の判定
//
//								self.actionSoundSet.play(type: .tap)
//								doKara = false
//								break
//
//							}else if self.lanes[index].timeState == .still{
//								doKara = true
//							}
//						}
//					}
					
					
				}
			}
//		}
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		for i in self.lanes{
			if !(i.isTimeLagRenewed){ return }
		}
		
//		judgeQueue.async {
		
			
			for i in touches{
				
				var pos = i.location(in: self.view)
				var ppos = i.previousLocation(in: self.view)
				
				let moveDistance = sqrt(pow(pos.x-ppos.x, 2) + pow(pos.y-ppos.y, 2))
				
				//タッチ情報を更新(不要！)
				//			let ptouchIndex = allTouches.index(where: {$0.touch == i})!
				//			let ptouch = allTouches[ptouchIndex]
				//			let touch = i as! GameSceneTouch
				//			touch.startLocation = ptouch.startLocation
				//			touch.tag = ptouch.tag
				//			allTouches[ptouchIndex] = touch
				
				pos.y = self.frame.height - pos.y //上下逆転(画面下からのy座標に変換)
				ppos.y = self.frame.height - ppos.y
				
				if pos.y < self.frame.width/3{    //上界
					
					//判定対象を選ぶため、押された範囲のレーンから最近ノーツを取得
					var nearbyNotes:[(laneIndex:Int, timelag:TimeInterval, note:Note)] = []
					
					//pposループ
					for (index,buttonPos) in self.buttonX.enumerated(){
						if ppos.x >= buttonPos - self.halfBound && ppos.x < buttonPos + self.halfBound{
							//lane.isTouchedをリセット
							if pos.x < buttonPos - self.halfBound || pos.x > buttonPos + self.halfBound{//移動後にレーンから外れていた場合
								//							lanes[index].isTouched = false
								
								if self.lanes[index].isObserved == .Front {
									//parfect時に該当ボタンにいなければ、入ってきた時間で判定
									if self.judge(laneIndex: index, timeLag: lanes[index].timeLag){
										self.actionSoundSet.play(type: .middle)
										break
									}
								}
								
							}
						}
						
						//フリックの判定
						let nextIndex = lanes[index].nextNoteIndex
						if (nextIndex > lanes[index].laneNotes.count-1) { continue }
						let note = lanes[index].laneNotes[nextIndex]
						if moveDistance > 10 && self.lanes[index].timeState != .still && self.lanes[index].timeState != .passed {
							
							let touchIndex = self.allTouches.index(where: {$0.touch == i})!
							let isJudgeableFlick = self.allTouches[touchIndex].isJudgeableFlick
							let isJudgeableFlickEnd = self.allTouches[touchIndex].isJudgeableFlickEnd

							
//							if isJudgeableFlick {//ただのフリックは一度だけ判定
							if ((note is Flick) && isJudgeableFlick) || ((note is FlickEnd) && isJudgeableFlickEnd) {//flickが最近なら他を無視（ここでは判定しない）
								nearbyNotes.append((laneIndex: index, timelag: self.lanes[index].timeLag, note: note))
								continue
							}
							
//								if self.judge(laneIndex: index, type: .flick) || self.judge(laneIndex: index, type: .flickEnd){
//									self.allTouches[touchIndex].isJudgeableFlick = true
//									self.actionSoundSet.play(type: .flick)
//									break
//								}
//							}else if self.judge(laneIndex: index, type: .flickEnd){
							
//								self.actionSoundSet.play(type: .flick)
//								break
//							}
						}
					}
					
					if !(nearbyNotes.isEmpty) {
					
						nearbyNotes.sort(by: {$0.timelag < $1.timelag})
						if (nearbyNotes[0].note is Flick) || (nearbyNotes[0].note is FlickEnd) {
							if self.judge(laneIndex: nearbyNotes[0].laneIndex, timeLag: nearbyNotes[0].timelag) {
								self.actionSoundSet.play(type: .flick)
								self.allTouches[self.allTouches.count-1].isJudgeableFlick = false	//このタッチでのフリック判定を禁止
								self.allTouches[self.allTouches.count-1].isJudgeableFlickEnd = false
							}else{
								print("判定失敗:flick")
							}
						}
					}
				}

				
			}
//		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		for i in self.lanes{
			if !(i.isTimeLagRenewed){ return }
		}
		
//		judgeQueue.async {
		
			
			for i in touches {
				
				var pos = i.location(in: self.view)
				var ppos = i.previousLocation(in: self.view)
				
				pos.y = self.frame.height - pos.y //上下逆転(画面下からのy座標に変換)
				ppos.y = self.frame.height - ppos.y
				
				self.allTouches.remove(at: self.allTouches.index(where: {$0.touch == i})!)
				
				if pos.y < self.frame.width/3{    //上界
					//pposループ
					for (index,buttonPos) in self.buttonX.enumerated(){
						if ppos.x >= buttonPos - self.halfBound && ppos.x < buttonPos + self.halfBound{
							//lane.isTouchedをリセット(離すので確定)
							//						lanes[index].isTouched = false
							if pos.x < buttonPos - self.halfBound || pos.x > buttonPos + self.halfBound{//移動後にレーンから外れていた場合
								if self.lanes[index].isObserved == .Front {
									if self.judge(laneIndex: index, timeLag: self.lanes[index].timeLag){
										self.actionSoundSet.play(type: .middle)
										break
									}
								}
							}
							
						}
					}
					//posループ
					for (index,buttonPos) in self.buttonX.enumerated(){
						
						if pos.x >= buttonPos - self.halfBound && pos.x < buttonPos + self.halfBound {//ボタンの範囲
							//lane.isTouchedをリセット
							//						lanes[index].isTouched = false
							if self.lanes[index].isObserved == .Front {
								if self.judge(laneIndex: index, timeLag: self.lanes[index].timeLag){
									self.actionSoundSet.play(type: .middle)
									break
								}
								
							}
							
							let nextIndex = lanes[index].nextNoteIndex
							if (nextIndex > lanes[index].laneNotes.count-1) { continue }
							let note = lanes[index].laneNotes[nextIndex]
							if (note is TapEnd){
								if self.judge(laneIndex: index, timeLag: lanes[index].timeLag){//離しの判定
									
									self.actionSoundSet.play(type: .tap)
									break
								}
							}else if ((note is Flick) || (note is FlickEnd)) && abs(lanes[index].timeLag)<0.08{	//flickなのにflickせずに離したらmiss
								setJudgeLabelText(text: "miss!")
								ResultScene.miss += 1
								ResultScene.combo = 0
								self.removeChildren(in: [lanes[index].laneNotes[nextIndex].image])
								lanes[index].laneNotes[nextIndex].isJudged = true
								lanes[index].nextNoteIndex += 1
							}
						}
					}
				}
			}
//		}
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




