
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
	
	//ラベル
	var judgeLabel = SKLabelNode(fontNamed: "HiraginoSans-W6")
	var comboLabel = SKLabelNode(fontNamed: "HiraginoSans-W6")
	
	//音楽プレイヤー
	var BGM:AVAudioPlayer?
	var flickSound1:AVAudioPlayer?    //同時に鳴らせるように2つ作る
	var flickSound2:AVAudioPlayer?
	var flickSound3:AVAudioPlayer?    //同時に鳴らせるように2つ作る
	var flickSound4:AVAudioPlayer?
	var tapSound1:AVAudioPlayer?
	var tapSound2:AVAudioPlayer?
	var tapSound3:AVAudioPlayer?
	var tapSound4:AVAudioPlayer?
	var kara1:AVAudioPlayer?
	var kara2:AVAudioPlayer?
	var kara3:AVAudioPlayer?
	var kara4:AVAudioPlayer?
	
	
	//画像(ノーツ以外)
	var judgeLine:SKShapeNode!
	var sameLines:[(note:Note,line:SKShapeNode)] = []	//連動する始点側のノーツと同時押しライン
	
	// 楽曲データ
	let bmsName = "オラシオン.bms"
	let bgmName = "オラシオン"
	var notes:[Note] = []	//ノーツの" 始 点 "の集合。参照型！
	var fNotes:[Note] = []
	var lNotes:[Note] = []
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
	let horizontalDistance:CGFloat = 10000	//画面から目までの水平距離a（約5000で10cmほど）
	var verticalDistance:CGFloat!	//画面を垂直に見たとき、判定線から目までの高さh（実際の水平線の高さでもある）
	var horizon:CGFloat!  //水平線の長さ
	var horizonY:CGFloat! //水平線のy座標
	var firstDiameter:CGFloat!	//最初の(判定線での)ノーツの直径2r（iphone7で74くらい）
	
	var halfBound:CGFloat! //判定を汲み取る、ボタン中心からの距離
	
	
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
		
		firstDiameter = self.frame.width/9
		
		horizon = self.frame.width*3/32	  //水平線の長さ。iphone7で83くらい
		horizonY = self.frame.height*15/16	//
		
		verticalDistance = self.frame.width/9 + (horizonY-self.frame.width/9)*1.1
		
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
		speed = 27500.0
		
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
		fNotes=notes
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
			
			if remainingBeat > -4{//-4拍以上のものは位置を設定(水平線より上でもロング結びに必要)
				setPos(note: i, currentTime: currentTime)
			}
			if i.image.position.y > horizonY || remainingBeat > 12 || i.isJudged == true{//水平線より上、12拍以上残っている、判定済みのものは隠す
				i.image.isHidden = true
			}else{
				i.image.isHidden = false
			}
			
			
			//つながっているノーツ
			var note:Note? = i
			while note?.next != nil{
				let remainingBeat2 = (note?.next.pos)! - ((currentTime - GameScene.start) * GameScene.bpm/60)
				if remainingBeat2 > -4{//-4拍以上のものは位置を設定(水平線より上でもロング結びに必要)
					setPos(note: (note?.next)!, currentTime: currentTime)
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
					if (note?.next.next.image.position.y)! < self.frame.width/9 && note?.next.longImage != nil{//先ノーツが判定線を通過したあと
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
			
			i.line.setScale(diameter/firstDiameter)
		}
		
		
		//判定関係
		//middleの判定
//		for i in buttons{
//			
//		}
		
		//レーンの監視(過ぎて行ってないか)
		for (index,value) in lanes.enumerated(){
			lanes[index].currentTime = currentTime
			if value.timeState == .passed {
				//				print("miss!")
				judgeLabel.text = "miss!"
				ResultScene.miss += 1
				ResultScene.combo = 0
				self.removeChildren(in: [lanes[index].laneNotes[value.nextNoteIndex].image])
				lanes[index].laneNotes[value.nextNoteIndex].isJudged = true
				
				//次のノーツを格納
				lanes[index].nextNoteIndex += 1
			}
		}
		
		
	}
	
	func setPos (note:Note ,currentTime:TimeInterval)  {	//
		//		var ypos =  self.frame.width/9
		
		var fypos = (CGFloat(60*note.pos/GameScene.bpm)-CGFloat(currentTime - GameScene.start))*CGFloat(speed)	  //判定線からの水平距離
		
		if fypos <= -horizontalDistance{
			fypos = -horizontalDistance+1
		}
		
		let y = (verticalDistance * fypos / (horizontalDistance + fypos)) + self.frame.width/9
		
		
		//大きさの変更
		let a = (horizon/7-self.frame.width/9)/(horizonY - self.frame.width/9)
		let diameter = a*(y-horizonY) + horizon/7
		
		note.image.setScale(1.3*diameter/firstDiameter)
		note.size = diameter
		
		if note.image.position.x < 1000{	//消えてない
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
				xpos -= 1.3*diameter/2
			}
			
			note.image.position = CGPoint(x:xpos ,y:y)
			
		}else{
			note.image.position.y = y
		}
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
	var size:CGFloat = 0
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
