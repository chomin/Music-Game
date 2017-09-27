
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
	
	//音楽プレイヤー
	var BGM:AVAudioPlayer?
	var flickSound1:AVAudioPlayer?    //同時に鳴らせるように2つ作る
	var flickSound2:AVAudioPlayer?
	var flickSound3:AVAudioPlayer?    //同時に鳴らせるように2つ作る
	var flickSound4:AVAudioPlayer?
	var flickSound5:AVAudioPlayer?    //同時に鳴らせるように2つ作る
	var flickSound6:AVAudioPlayer?
	var flickSound7:AVAudioPlayer?    //同時に鳴らせるように2つ作る
	var flickSound8:AVAudioPlayer?
	var tapSound1:AVAudioPlayer?
	var tapSound2:AVAudioPlayer?
	var tapSound3:AVAudioPlayer?
	var tapSound4:AVAudioPlayer?
	var tapSound5:AVAudioPlayer?
	var tapSound6:AVAudioPlayer?
	var tapSound7:AVAudioPlayer?
	var tapSound8:AVAudioPlayer?
	var kara1:AVAudioPlayer?
	var kara2:AVAudioPlayer?
	var kara3:AVAudioPlayer?
	var kara4:AVAudioPlayer?
	var kara5:AVAudioPlayer?
	var kara6:AVAudioPlayer?
	var kara7:AVAudioPlayer?
	var kara8:AVAudioPlayer?
	
	
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
	var fNotes:[Note] = []  // firstNotes(最終的にロングノーツの始点の集合)
    var lNotes:[Note] = []  // lastNotes(ロングノーツの終点の集合)
	static var start:TimeInterval = 0.0	  //シーン移動した時の時間
	var musicStartPos = 1.0	  //BGM開始の"拍"！
	var playLebel = 0
	var genre = ""				// ジャンル
	var title = ""				// タイトル
	var artist = ""				// アーティスト
	static var bpm = 132.0				// Beats per Minute
	var playLevel = 0			// 難易度
	var volWav = 100			// 音量を現段階のn%として出力するか
	var lanes:[Lane] = [Lane(),Lane(),Lane(),Lane(),Lane(),Lane(),Lane()]		//レーン
	
	//立体感を出すための定数
	let horizontalDistance:CGFloat = 220	//画面から目までの水平距離a（約5000で10cmほど）
	var verticalDistance:CGFloat!	//画面を垂直に見たとき、判定線から目までの高さh（実際の水平線の高さでもある）
	var horizon:CGFloat!  //水平線の長さ
	var horizonY:CGFloat! //水平線のy座標
	var laneWidth:CGFloat!	//最初の(判定線での)ノーツの直径2r（iphone7で74くらい）
	
	var halfBound:CGFloat! //判定を汲み取る、ボタン中心からの距離
	
	let noteScale = 1.3	//レーン幅に対するノーツの幅の倍率
	
	
	override func didMove(to view: SKView) {
		
		
		//リザルトの初期化
		ResultScene.parfect = 0
		ResultScene.great = 0
		ResultScene.good = 0
		ResultScene.bad = 0
		ResultScene.miss = 0
		ResultScene.combo = 0
		ResultScene.maxCombo = 0
		
		halfBound = self.frame.width/12
		
		laneWidth = self.frame.width/9
		
		horizon = self.frame.width/16	  //
		horizonY = self.frame.height*15/16	//
		
//		verticalDistance = self.frame.width/9 + (horizonY-self.frame.width/9)*1.1
//		verticalDistance = horizonY - self.frame.width/24
		verticalDistance = horizonY //モデルに合わせるなら水平線は画面上端辺りが丁度いい？モデルに合わせるなら大きくは変えてはならない。
		print(horizonY-self.frame.width/9)	//判定線から水平線までの画面上での幅。277くらい
		
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
		
		//スピードの設定
		speed = 1700.0
		
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
		catch                                     { print("未知のエラー") }

		//同時押し探索用
		fNotes = notes
		for i in notes{
			
			if i.next == nil{	//終点なしなら飛ばす
				continue
			}
			
			var note:Note! = i
			while note.next != nil {
				note = note.next
			}
			lNotes.append(note)
		}
		
		//lnotesをposの早い順にソート(してもらう)
		lNotes = lNotes.sorted{$0.pos < $1.pos}
		
		
		//画像、音楽、ラベルの設定
		setAllSounds()
		setImages()
		
		//BGMの再生(時間指定)
		GameScene.start = CACurrentMediaTime()
		BGM!.play(atTime: GameScene.start + (musicStartPos/GameScene.bpm)*60)
		BGM?.delegate = self
		
		//各レーンにノーツをセット
		for i in notes{
			lanes[i.lane-1].laneNotes.append(i)
			
			var note:Note! = i
			while note.next != nil {
				lanes[note.next.lane-1].laneNotes.append(note.next)
				note = note.next
			}
		}
		
		
		
	}
	
	
	override func update(_ currentTime: TimeInterval) {
		
		
		//ラベルの更新
		comboLabel.text = String(ResultScene.combo)
		
		//時間でノーツの位置を設定する(重くなるので近場のみ！)
		for i in notes{
			
			let remainingBeat = i.pos - ((currentTime - GameScene.start) * GameScene.bpm/60)
			
			if (i.isJudged == false || remainingBeat > 0) && remainingBeat < 8{//位置を設定(水平線より上でもロング先に必要、判定後でもロング初めに必要、判定線過ぎても普通に必要)
				setPos(note: i, currentTime: currentTime)
				if i.next != nil{	//つながっている1つ先までは描く
					setPos(note: i.next, currentTime: currentTime)
				}
//				if i.type == .flickEnd || i.type == .tapEnd || i.type == .middle{//先ノーツになりうるものは無条件に描く
//					setPos(note: i, currentTime: currentTime)
//				}else if remainingBeat < 8{
//					setPos(note: i, currentTime: currentTime)
//				}
			}
			if i.image.position.y > horizonY || remainingBeat > 8 || i.isJudged == true{//水平線より上、8拍以上残っている、判定済みのものは隠す
				i.image.isHidden = true
			}else{
				i.image.isHidden = false
			}
			
			
			//つながっているノーツ
			var note:Note? = i
			while note?.next != nil{
				let remainingBeat2 = (note?.next.pos)! - ((currentTime - GameScene.start) * GameScene.bpm/60)
				if (note?.next.isJudged == false || remainingBeat2 > 0) && remainingBeat2 < 8{//-4拍以上のものは位置を設定(水平線より上でもロング結びに必要)
					
					setPos(note: (note?.next)!, currentTime: currentTime)
					
					if note?.next.next != nil{
						setPos(note: (note?.next?.next)!, currentTime: currentTime)
					}
//					if note?.next.type == .flickEnd || note?.next.type == .tapEnd || note?.next.type == .middle{//先ノーツになりうるものは無条件に描く
//						setPos(note: (note?.next)!, currentTime: currentTime)
//					}else if remainingBeat2 < 8{
//						setPos(note: (note?.next)!, currentTime: currentTime)
//					}
				}
				
				if (note?.next.image.position.y)! > horizonY || remainingBeat2 > 12 || note?.next.isJudged == true{//水平線より上、12拍以上残っている、判定済みのものは隠す
					note?.next.image.isHidden = true
				}else{
					note?.next.image.isHidden = false
				}
				
				note = note?.next
			}
		}
		
		//緑太線の描写
		for i in notes{
			
			let remainingBeat = i.pos - ((currentTime - GameScene.start) * GameScene.bpm/60)
			
			if i.next != nil{
				if (i.next.image.position.y < self.frame.width/9 || i.next.isJudged == true) && i.longImage != nil{//先ノーツが判定線を通過したあとか、判定されたあとなら除去
					self.removeChildren(in: [i.longImage])
					i.longImage = nil
				}else if remainingBeat < 4 && i.next.image.position.y > self.frame.width/9 && i.next.isJudged == false && i.image.position.y < horizonY{
					
					//毎フレーム描き直す
					setLong(firstNote: i)
				}
			}
			
			//つながっているノーツ
			var note:Note? = i
			while note?.next != nil{
				let remainingBeat2 = (note?.next.pos)! - ((currentTime - GameScene.start) * GameScene.bpm/60)
				
				if note?.next.next != nil {
					if ((note?.next.next.image.position.y)! < self.frame.width/9 || note?.next.next.isJudged == true) && note?.next.longImage != nil{//先ノーツが判定線を通過したあとか、判定されたあとなら除去
						self.removeChildren(in: [(note?.next.longImage)!])
						note?.next.longImage = nil
					}else if remainingBeat2 < 4 && (note?.next.next.image.position.y)! > self.frame.width/9 && note?.next.next.isJudged == false && (note?.next.image.position.y)! < horizonY!{
						
						//毎フレーム描き直す
						
						setLong(firstNote: (note?.next)!)
					}
				}
				
				note = note?.next
			}
		}
		
		
		for i in sameLines{ //同時押しラインも移動
			i.line.position = i.note.image.position
			i.line.isHidden = i.note.image.isHidden
			//大きさの変更
			let a = (horizon/7-self.frame.width/9)/(horizonY - self.frame.width/9)
			let diameter = a*(i.line.position.y-horizonY) + horizon/7
			
			i.line.setScale(diameter/laneWidth)
		}
		
		
		//判定関係
		//middleの判定（同じところで長押しのやつ）
		for i in allTouchesLocation{
			if i.y < self.frame.width/3{    //上界
				
				for j in 0...6{
					
					let buttonPos = self.frame.width/6 + CGFloat(j)*self.frame.width/9
					
					if i.x > buttonPos - halfBound && i.x < buttonPos + halfBound {//ボタンの範囲
						
						if parfectMiddleJudge(laneNum: j+1){//離しの判定
							
							playSound(type: .tap)
							break
						}
					}
				}
			}
		}
		
		//		for i in 0...6{
		//
		//
		//
		//			let nextIndex = lanes[i].nextNoteIndex
		//
		//			if lanes[i].timeState == .parfect && lanes[i].laneNotes[nextIndex].type == .middle{
		//
		//			}
		//
		//		}
		
		
		//レーンの監視(過ぎて行ってないか)
		for (index,value) in lanes.enumerated(){
			lanes[index].currentTime = currentTime
			if value.timeState == .passed {
				judgeLabel.text = "miss!"
				ResultScene.miss += 1
				ResultScene.combo = 0
				self.removeChildren(in: [lanes[index].laneNotes[value.nextNoteIndex].image])	//ここで消しても大丈夫なはず
				lanes[index].laneNotes[value.nextNoteIndex].isJudged = true
				
				//次のノーツを格納
				lanes[index].nextNoteIndex += 1
			}
		}
		
		
	}
	
	func setPos (note:Note ,currentTime:TimeInterval)  {
		
		//y座標の計算
		let fypos = (CGFloat(60*note.pos/GameScene.bpm)-CGFloat(currentTime - GameScene.start))*CGFloat(speed)	  //判定線からの水平距離x
		
		//鉛直面に投写
//		guard fypos > -horizontalDistance else {//分母が0になるのを防止
//			return
//		}
//
//		let y = (verticalDistance * fypos / (horizontalDistance + fypos)) + self.frame.width/9
		
		//球面？に投写
		guard fypos > -(pow(horizontalDistance, 2) + pow(verticalDistance, 2)) / horizontalDistance else {//atan内の分母が0になるのを防止
			return
		}
		let R = sqrt(pow(horizontalDistance, 2) + pow(verticalDistance, 2))
		let y = R * atan(verticalDistance * fypos / (pow(R, 2) + fypos*horizontalDistance))
		
		
		//大きさと形の変更(楕円は描き直し,その他は拡大のみ)
		
		let grad = (horizon/7-laneWidth)/(horizonY - self.frame.width/9)//傾き
		let diameter = CGFloat(noteScale)*(grad*(y-horizonY) + horizon/7)
		
		note.size = diameter
		
		//楕円の縦幅を計算
		let l = sqrt(pow(horizontalDistance + fypos, 2) + pow(laneWidth*CGFloat(4-note.lane), 2))
//		let aPrime = horizontalDistance * l / (horizontalDistance + fypos)
//		let xPrime = fypos * l / (horizontalDistance + fypos)
//		let deltaY = 1.3 * laneWidth * aPrime * verticalDistance / (pow(aPrime + xPrime, 2) - pow(1.3 * laneWidth, 2))
		let deltaY = R * atan(1.3*laneWidth*verticalDistance / (pow(l, 2) + pow(verticalDistance, 2) - pow(1.3*laneWidth/2, 2)))
		
		
		if note.type == .tap && note.next == nil{
			self.removeChildren(in: [note.image])
			note.image = SKShapeNode(ellipseOf: CGSize(width:diameter, height:deltaY))
			note.image.fillColor = .white
			self.addChild(note.image)
		}else if note.type == .tapEnd || note.type == .tap{
			self.removeChildren(in: [note.image])
			note.image = SKShapeNode(ellipseOf: CGSize(width:diameter, height:deltaY))
			note.image.fillColor = .green
			self.addChild(note.image)
		}else{
			note.image.setScale(diameter/laneWidth)
		}
		
		//向きの変更
		
		
		//座標の設定
		var xpos:CGFloat
		
		if note.lane != 4{  //傾き無限大防止
			var b = (horizonY-self.frame.width/9)   //傾き
			var c = CGFloat(4-note.lane)*self.frame.width/9
			c += CGFloat(note.lane-4)*horizon/7
			b /= c
			xpos = (y - self.frame.width/9)/b
			xpos += self.frame.width/18 + CGFloat(note.lane)*self.frame.width/9
		} else {
			xpos = self.frame.width/2
		}
		
		
		if note.type == .middle{ //線だけずらす(開始点がposition)→長さの半分だけずらすように！
			xpos -= diameter/2
		}
		
		note.image.position = CGPoint(x:xpos ,y:y)
	}
	
	//再生終了時の呼び出しメソッド
	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {//playしたクラスと同じクラスに入れる必要あり？
		if player == BGM!{
			let scene = ResultScene(size: (view?.bounds.size)!)
			let skView = view as! SKView
			skView.showsFPS = true
			skView.showsNodeCount = true
			skView.ignoresSiblingOrder = true
			scene.scaleMode = .resizeFill
			skView.presentScene(scene)  //ResultSceneに移動
		}
	}
}

// 譜面データ(NoteTypeとNoteの定義はおそらくほかのファイルでもするだろうから統合してほしい)
enum NoteType {
	case tap, flick, middle, tapEnd, flickEnd
}

class Note {
	let type: NoteType
	let pos: Double //"拍"単位！小節ではない！！！
	let lane: Int
	var next: Note!
	var image:SKShapeNode!	  //ノーツの画像
	var longImage:SKShapeNode!	//このノーツを始点とする緑太線の画像
	var size:CGFloat = 0	//線の座標をずらすのに必要
//	var firstLongSize:CGFloat = 0
	var isJudged = false
	
	init(type: NoteType, position pos: Double, lane: Int) {
		self.type = type
		self.pos = pos
		self.lane = lane
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
