//
//  Note.swift
//  音ゲー（仮）
//
//  Created by 植田暢大 on 2017/10/04.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//

import SpriteKit

enum NoteType {
    case tap, flick, tapStart, middle, tapEnd, flickEnd
}

class Tap: Note {
	
	init(position pos: Double, lane: Int) {
        super.init(type: .tap, position: pos, lane: lane)
		
		// imageのインスタンス(白円)を作成
		self.image = SKShapeNode(circleOfRadius: GameScene.laneWidth / 2)
		image.fillColor = UIColor.white
		image.isHidden = true	// 初期状態では隠しておく
    }
    
    override func update(currentTime: TimeInterval) {
		
        // x座標とy座標を計算しimage.positionを変更
		setPos(currentTime: currentTime)
		
		// 縦と横の大きさを計算し、imageのスケールを変更
		setScale(currentTime: currentTime)
		
		// image.isHiddenを更新
		if image.position.y > GameScene.horizonY || isJudged == true {		// 水平線より上、判定済みのものは隠す
			image.isHidden = true
		}else{
			image.isHidden = false
		}
    }
}

class Flick: Note {

    init(position pos: Double, lane: Int) {
        super.init(type: .flick, position: pos, lane: lane)
		
		// imageのインスタンス(マゼンタ三角形)を作成
		let length = GameScene.laneWidth / 2 // 三角形一辺の長さの半分
		// 始点から終点までの４点を指定(2点を一致させ三角形に).
		var points = [
			CGPoint(x: length,  y: 0.0),
			CGPoint(x: -length, y: 0.0),
			CGPoint(x: 0.0,     y: length),
			CGPoint(x: length,  y: 0.0)
		]
		self.image = SKShapeNode(points: &points, count: points.count)
		image.lineWidth = 3.0
		image.fillColor = UIColor.magenta
		image.isHidden = true	// 初期状態では隠しておく
    }

    override func update(currentTime: TimeInterval) {
		// x座標とy座標を計算しimage.positionを変更
		setPos(currentTime: currentTime)
		
		// スケールを変更
		setScale(currentTime: currentTime)
		
		// image.isHiddenを更新
		if image.position.y > GameScene.horizonY || isJudged == true {		// 水平線より上、判定済みのものは隠す
			image.isHidden = true
		}else{
			image.isHidden = false
		}
    }
}

class TapStart: Note {
	
	var next = Note()				// 次のノーツ
	var longImages = (long: SKShapeNode(), circle: SKShapeNode())	// このノーツを始点とする緑太線の画像と、判定線上に残る緑楕円(将来的にはimageに格納？)
	
	init(position pos: Double, lane: Int) {
		super.init(type: .tapStart, position: pos, lane: lane)
		
		// imageのインスタンス(緑円)を作成
		image = SKShapeNode(circleOfRadius: GameScene.laneWidth / 2)
		image.fillColor = UIColor.green
		image.isHidden = true	// 初期状態では隠しておく
		
		// longImagesのインスタンスを作成
		self.longImages = (SKShapeNode(path: CGMutablePath()), SKShapeNode(circleOfRadius: GameScene.laneWidth / 2))
		longImages.long.fillColor = UIColor.green
		longImages.long.alpha = 0.8
		longImages.long.zPosition = -1
		longImages.long.isHidden = true
		longImages.circle.fillColor = UIColor.green
		longImages.circle.isHidden = true
	}
	
	override func update(currentTime: TimeInterval) {
		// x座標とy座標を計算しimage.positionを変更
		setPos(currentTime: currentTime)
		
		// 縦と横の大きさを計算し、imageのスケールを変更
		setScale(currentTime: currentTime)
		
	
		// longImageを更新
		let path = CGMutablePath()      // 台形の外周
		
		let startNotePos = image.position 		// 中心座標
		var endNotePos = next.image.position	// 中心座標
		// 終点ノーツが円か線かで中心座標が異なるため場合分け
		if next is Middle {
			endNotePos.x += next.size / 2		// 線だけずらす
		}
		
		if startNotePos.y > GameScene.judgeLineY && isJudged == false {	// 始点ノーツが判定線を通過する前で、判定する前(判定後は位置が更新されないので...)
			path.move   (to: CGPoint(x: startNotePos.x - size/2/noteScale, y: startNotePos.y))  // 始点、台形の左下
			path.addLine(to: CGPoint(x: startNotePos.x + size/2/noteScale, y: startNotePos.y))	// 右下
			path.addLine(to: CGPoint(x: endNotePos.x + next.size/2/noteScale, y: endNotePos.y))	// 右上
			path.addLine(to: CGPoint(x: endNotePos.x - next.size/2/noteScale, y: endNotePos.y))	// 左上
			path.closeSubpath()
		} else {
			// ロングの始点の中心位置を計算
			var longStartPos = CGPoint(x: 0 ,y: GameScene.judgeLineY)
			
			let nowPos = (currentTime - GameScene.start) * GameScene.bpm/60		// y座標で比をとると、途中で発散するためposから比を求める
			let laneDifference:CGFloat = CGFloat(lane - next.lane)				// レーン差(符号込み)
			let way1 = GameScene.laneWidth * laneDifference						// 判定線でのレーン差分のx座標の差(符号込み)
			let way2 = CGFloat((nowPos - pos) / (next.pos - pos))
			let way3 = (CGFloat(lane) + 1.5) * GameScene.laneWidth				// 始点レーンの中心のx座標
			longStartPos.x = way3 - way1 * way2
			
			path.move   (to: CGPoint(x: longStartPos.x - GameScene.laneWidth/2, y: longStartPos.y))	// 始点、台形の左下
			path.addLine(to: CGPoint(x: longStartPos.x + GameScene.laneWidth/2, y: longStartPos.y))	// 右下
			path.addLine(to: CGPoint(x: endNotePos.x + next.size/2/noteScale, y: endNotePos.y))		// 右上
			path.addLine(to: CGPoint(x: endNotePos.x - next.size/2/noteScale, y: endNotePos.y))		// 左上
			path.closeSubpath()
			
			
			// longImages.circleを更新
			// 理想軌道の判定線上に緑円を描く
			// 楕円の縦幅を計算
			let R = sqrt(pow(horizontalDistance, 2) + pow(verticalDistance, 2))
			let lSquare = pow(horizontalDistance, 2) + pow(GameScene.laneWidth * 9/2 - longStartPos.x, 2)
			let denomOfAtan = lSquare + pow(verticalDistance, 2) - pow(noteScale * GameScene.laneWidth / 2, 2)
			guard 0 < denomOfAtan else {
				return
			}
			let deltaY = R * atan(noteScale * GameScene.laneWidth * verticalDistance / denomOfAtan)
			
			longImages.circle.yScale = deltaY / GameScene.laneWidth
			longImages.circle.position = longStartPos
		}
		
		// longImage.longを更新(pathを変更)
		longImages.long.path = path
		
		
		// isHiddenを更新
		if image.position.y >= GameScene.horizonY || isJudged {		// 水平線より上、判定済みのものは隠す
			image.isHidden = true
		}else{
			image.isHidden = false
		}
		if image.position.y >= GameScene.horizonY || next.image.position.y <= GameScene.judgeLineY || next.isJudged {
			longImages.long.isHidden = true
		} else {
			longImages.long.isHidden = false
		}
		if image.position.y >= GameScene.judgeLineY || next.isJudged {
			longImages.circle.isHidden = true
		} else {
			longImages.circle.isHidden = false
		}
	}
}

class Middle: Note {

	var next = Note()				// 次のノーツ
	var longImages = (long: SKShapeNode(), circle: SKShapeNode())	// このノーツを始点とする緑太線の画像と、判定線上に残る緑楕円(将来的にはimageに格納？)
	
    init(position pos: Double, lane: Int) {
        super.init(type: .middle, position: pos, lane: lane)
		
		// imageのインスタンス(緑線分)を作成
		var points = [
			CGPoint(x: 0.0, y: 0.0),
			CGPoint(x: GameScene.laneWidth, y: 0.0)
		]
		self.image = SKShapeNode(points: &points, count: points.count)
		image.lineWidth = 5.0
		image.strokeColor = UIColor.green
		image.isHidden = true	// 初期状態では隠しておく
		
		// longImagesのインスタンスを作成
		self.longImages = (SKShapeNode(path: CGMutablePath()), SKShapeNode(circleOfRadius: GameScene.laneWidth / 2))
		longImages.long.fillColor = UIColor.green
		longImages.long.alpha = 0.8
		longImages.long.zPosition = -1
		longImages.long.isHidden = true
		longImages.circle.fillColor = UIColor.green
		longImages.circle.isHidden = true
    }

    override func update(currentTime: TimeInterval) {
		// x座標とy座標を計算しimage.positionを変更
		setPos(currentTime: currentTime)
		image.position.x -= size / 2	// 線のときだけずらす(開始点がposition)→長さの半分だけずらすように！

		
		// スケールを変更
		setScale(currentTime: currentTime)
		
		
		// longImageをpathのみ更新
		let path = CGMutablePath()      // 台形の外周
		
		var startNotePos = image.position 		// 中心座標
		startNotePos.x += size / 2				// 幅の半分ずらす(.positionが左端を指すから)
		var endNotePos = next.image.position	// 中心座標
		// 終点ノーツが円か線かで中心座標が異なるため場合分け
		if next is Middle {
			endNotePos.x += next.size / 2		// 線だけずらす
		}
		
		if startNotePos.y > GameScene.judgeLineY && isJudged == false {	// 始点ノーツが判定線を通過する前で、判定する前(判定後は位置が更新されないので...)
			path.move   (to: CGPoint(x: startNotePos.x - size/2/noteScale, y: startNotePos.y))  // 始点、台形の左下
			path.addLine(to: CGPoint(x: startNotePos.x + size/2/noteScale, y: startNotePos.y))	// 右下
			path.addLine(to: CGPoint(x: endNotePos.x + next.size/2/noteScale, y: endNotePos.y))	// 右上
			path.addLine(to: CGPoint(x: endNotePos.x - next.size/2/noteScale, y: endNotePos.y))	// 左上
			path.closeSubpath()
		} else {
			// ロングの始点の中心位置を計算
			var longStartPos = CGPoint(x: 0 ,y: GameScene.judgeLineY)
			
			let nowPos = (currentTime - GameScene.start) * GameScene.bpm/60		// y座標で比をとると、途中で発散するためposから比を求める
			let laneDifference:CGFloat = CGFloat(lane - next.lane)				// レーン差(符号込み)
			let way1 = GameScene.laneWidth * laneDifference						// 判定線でのレーン差分のx座標の差(符号込み)
			let way2 = CGFloat((nowPos - pos) / (next.pos - pos))
			let way3 = (CGFloat(lane) + 1.5) * GameScene.laneWidth				// 始点レーンの中心のx座標
			longStartPos.x = way3 - way1 * way2
			
			path.move   (to: CGPoint(x: longStartPos.x - GameScene.laneWidth/2, y: longStartPos.y))	// 始点、台形の左下
			path.addLine(to: CGPoint(x: longStartPos.x + GameScene.laneWidth/2, y: longStartPos.y))	// 右下
			path.addLine(to: CGPoint(x: endNotePos.x + next.size/2/noteScale, y: endNotePos.y))		// 右上
			path.addLine(to: CGPoint(x: endNotePos.x - next.size/2/noteScale, y: endNotePos.y))		// 左上
			path.closeSubpath()
			
			
			// longImages.circleを更新
			// 理想軌道の判定線上に緑円を描く
			// 楕円の縦幅を計算
			let R = sqrt(pow(horizontalDistance, 2) + pow(verticalDistance, 2))
			let lSquare = pow(horizontalDistance, 2) + pow(GameScene.laneWidth * 9/2 - longStartPos.x, 2)
			let denomOfAtan = lSquare + pow(verticalDistance, 2) - pow(noteScale * GameScene.laneWidth / 2, 2)
			guard 0 < denomOfAtan else {
				return
			}
			let deltaY = R * atan(noteScale * GameScene.laneWidth * verticalDistance / denomOfAtan)
			
			longImages.circle.yScale = deltaY / GameScene.laneWidth
			longImages.circle.position = longStartPos
		}
		
		// longImages.longを更新(pathを変更)
		longImages.long.path = path
		
		
		// isHiddenを更新
		if image.position.y >= GameScene.horizonY || isJudged {		// 水平線より上、判定済みのものは隠す
			image.isHidden = true
		}else{
			image.isHidden = false
		}
		if image.position.y >= GameScene.horizonY || next.image.position.y <= GameScene.judgeLineY || next.isJudged {
			longImages.long.isHidden = true
		} else {
			longImages.long.isHidden = false
		}
		if image.position.y >= GameScene.judgeLineY || next.isJudged {
			longImages.circle.isHidden = true
		} else {
			longImages.circle.isHidden = false
		}
    }
}

class TapEnd: Note {

    init(position pos: Double, lane: Int) {
        super.init(type: .tapEnd, position: pos, lane: lane)
		
		// imageのインスタンス(緑円)を作成
		image = SKShapeNode(circleOfRadius: GameScene.laneWidth / 2)
		image.fillColor = UIColor.green
		image.isHidden = true	// 初期状態では隠しておく
    }

    override func update(currentTime: TimeInterval) {
		
		// x座標とy座標を計算しimage.positionを変更
		setPos(currentTime: currentTime)
		
		// 縦と横の大きさを計算し、imageのスケールを変更
		setScale(currentTime: currentTime)
		
		// image.isHiddenを更新
		if image.position.y > GameScene.horizonY || isJudged == true {		// 水平線より上、判定済みのものは隠す
			image.isHidden = true
		}else{
			image.isHidden = false
		}
	}
}

class FlickEnd: Note {
	
    init(position pos: Double, lane: Int) {
        super.init(type: .flickEnd, position: pos, lane: lane)
		
		// imageのインスタンス(マゼンタ三角形)を作成
		let length = GameScene.laneWidth / 2 // 三角形一辺の長さの半分
		// 始点から終点までの４点を指定(2点を一致させ三角形に).
		var points = [
			CGPoint(x: length,  y: 0.0),
			CGPoint(x: -length, y: 0.0),
			CGPoint(x: 0.0,     y: length),
			CGPoint(x: length,  y: 0.0)
		]
		image = SKShapeNode(points: &points, count: points.count)
		image.lineWidth = 3.0
		image.fillColor = UIColor.magenta
		image.isHidden = true	// 初期状態では隠しておく
    }

    override func update(currentTime: TimeInterval) {
		
		// x座標とy座標を計算しimage.positionを変更
		setPos(currentTime: currentTime)
		
		// 縦と横の大きさを計算し、imageのスケールを変更
		setScale(currentTime: currentTime)
		
		// image.isHiddenを更新
		if image.position.y > GameScene.horizonY || isJudged == true {		// 水平線より上、判定済みのものは隠す
			image.isHidden = true
		}else{
			image.isHidden = false
		}
	}
}


// ノーツ基本クラス
class Note {
	
	let type: NoteType			// ノートの種類(タップかフリックかなど)
	let pos: Double				// "拍"単位！小節ではない！！！
	let lane: Int				// レーンのインデックス(0始まり)
	var image = SKShapeNode()	// ノーツの画像
	var size: CGFloat = 0		// ノーツの横幅
	var isJudged = false		// 判定済みかどうか
	
	let noteScale: CGFloat = 1.3	// レーン幅に対するノーツの幅の倍率
	let speed: CGFloat = 1700.0		// スピード
	//立体感を出すための定数
	let horizontalDistance:CGFloat = 470		//画面から目までの水平距離a（約5000で10cmほど）
	let verticalDistance = GameScene.horizonY	//画面を垂直に見たとき、判定線から目までの高さh（実際の水平線の高さでもある）
												//モデルに合わせるなら水平線は画面上端辺りが丁度いい？モデルに合わせるなら大きくは変えてはならない。

	
    init(type: NoteType, position pos: Double, lane: Int) {
        self.type = type
        self.pos = pos
        self.lane = lane
    }
	init() {
		self.type = .tap
		self.pos = 0
		self.lane = 0
	}
	
	func update(currentTime: TimeInterval) {}    // ノーツの座標等の更新、毎フレーム呼ばれる
	
	
	// ノーツの座標を設定
	fileprivate func setPos(currentTime: TimeInterval) {
		
		/* y座標の計算 */
		
		let fypos = (CGFloat(60*pos/GameScene.bpm) - CGFloat(currentTime - GameScene.start)) * speed	  // 判定線からの水平距離x
		// 球面?に投写
		let R = sqrt(pow(horizontalDistance, 2) + pow(verticalDistance, 2))		// 視点から判定線までの距離(射影する球の半径)
		let denomOfAtan = pow(R, 2) + horizontalDistance * fypos				// atanの分母
		guard 0 < denomOfAtan else {	// atan内の分母が0になるのを防止
			return
		}
		let posY = R * atan(verticalDistance * fypos / denomOfAtan) + GameScene.judgeLineY
		
		
		/* x座標の計算 */
		
		var posX: CGFloat
		
		let b = GameScene.horizonY - GameScene.judgeLineY   						// 水平線から判定線までの2D上の距離
		let c = CGFloat(3 - lane) * (GameScene.laneWidth - GameScene.horizon/7)		// 水平線上と判定線上でのx座標のずれ
		posX = GameScene.laneWidth * 3/2 + CGFloat(lane) * GameScene.laneWidth		// 判定線上でのx座標
		posX += (posY - GameScene.judgeLineY) * (c/b)								// 判定線から離れている分補正
		
		
		// 座標を反映
		self.image.position = CGPoint(x: posX, y: posY)
	}
	
	// ノーツのスケールを設定
	fileprivate func setScale(currentTime: TimeInterval) {
		
		// ノーツの横幅を計算(改善点: fyposとRはsetPos関数でも計算されている。上手く計算を1度で済ませたい。)
		let fypos = (CGFloat(60*pos/GameScene.bpm) - CGFloat(currentTime - GameScene.start)) * speed	// 判定線からの水平距離x
		let R = sqrt(pow(horizontalDistance, 2) + pow(verticalDistance, 2))								// 視点から判定線までの距離(射影する球の半径)
		let grad = (GameScene.horizon/7 - GameScene.laneWidth) / (GameScene.horizonY - GameScene.judgeLineY)	// 傾き
		self.size = noteScale * (grad * (image.position.y - GameScene.horizonY) + GameScene.horizon/7)

		// ノーツの横幅と縦幅をscaleで設定
		if self is Tap || self is TapStart || self is TapEnd {		// 楕円
			let lSquare = pow(horizontalDistance + fypos, 2) + pow(GameScene.laneWidth * CGFloat(3 - lane), 2)
			let denomOfAtan = lSquare + pow(verticalDistance, 2) - pow(noteScale * GameScene.laneWidth / 2, 2)				// atan内の分母
			guard 0 < denomOfAtan else {	// atan内の分母が0になるのを防止
				return
			}
			let deltaY = R * atan(noteScale * GameScene.laneWidth * verticalDistance / denomOfAtan)

			image.xScale = size / GameScene.laneWidth
			image.yScale = deltaY / GameScene.laneWidth
		} else {		// 線と三角形
			image.setScale(size / GameScene.laneWidth)
		}
	}

	
	
//	// 各noteの座標と画像をセット
//		func setPosOld (note:Note, currentTime: TimeInterval)  {
//
//		//スピードの設定
//		var speed: CGFloat = 1700.0
//
//
//		//立体感を出すための定数
//		let horizontalDistance:CGFloat = 470	//画面から目までの水平距離a（約5000で10cmほど）
//		let verticalDistance = GameScene.horizonY	//画面を垂直に見たとき、判定線から目までの高さh（実際の水平線の高さでもある）
//													//モデルに合わせるなら水平線は画面上端辺りが丁度いい？モデルに合わせるなら大きくは変えてはならない。
//
//
//
//
//
//
//
//		// y座標の計算
//
//		let fypos = (CGFloat(60*note.pos/GameScene.bpm) - CGFloat(currentTime - GameScene.start)) * speed	  //判定線からの水平距離x
//
//		// 球面?に投写
//		let R = sqrt(pow(horizontalDistance, 2) + pow(verticalDistance, 2))		// 視点から判定線までの距離(射影する球の半径)
//		let denomOfAtan = pow(R, 2) + horizontalDistance * fypos				// atanの分母
//		guard 0 < denomOfAtan else {	// atan内の分母が0になるのを防止
//			return
//		}
//		let y = R * atan(verticalDistance * fypos / denomOfAtan) + GameScene.judgeLineY
//
//
//		// 大きさと形の変更(楕円は描き直し,その他は拡大のみ)
//
//		// 楕円の横幅を計算
//		let grad = (GameScene.horizon/7 - GameScene.laneWidth) / (GameScene.horizonY - GameScene.judgeLineY)	// 傾き
//		let diameter = noteScale * (grad * (y - GameScene.horizonY) + GameScene.horizon/7)
//
//		note.size = diameter
//
//		//画面に現れるノーツの、描き直し（楕円）及び拡大（線、三角形）
//		if y < GameScene.horizonY && note.isJudged == false{//判定後はremoveされている(エラーになる)。その後もlongImageの計算に位置だけ必要なので、呼び出されうる。
//			if note.type == .tap || note.type == .tapEnd {//楕円
//				//楕円の縦幅を計算
//				let lSquare = pow(horizontalDistance + fypos, 2) + pow(GameScene.laneWidth*CGFloat(3-note.lane), 2)
//
//				let deltaY = R * atan(noteScale * GameScene.laneWidth * verticalDistance / (lSquare + pow(verticalDistance, 2) - pow(noteScale*GameScene.laneWidth/2, 2)))
//
//
//				// ノーツイメージをセット
//				if note.type == .tapStart {
//
//					self.removeChildren(in: [note.image])
//					note.image = SKShapeNode(ellipseOf: CGSize(width:diameter, height:deltaY))
//					note.image.fillColor = .white
//					self.addChild(note.image)
//				}else if note.type == .tapEnd || note.type == .tap{
//					self.removeChildren(in: [note.image])
//					note.image = SKShapeNode(ellipseOf: CGSize(width:diameter, height:deltaY))
//					note.image.fillColor = .green
//					self.addChild(note.image)
//				}
//			}else{//線と三角形
//				note.image.setScale(diameter/GameScene.laneWidth)
//			}
//		}
		
		//向きの変更
		
//
//		//座標の設定
//		var xpos:CGFloat
//
//		let b = GameScene.horizonY - GameScene.judgeLineY   							// 水平線から判定線までの2D上の距離
//		let c = CGFloat(3 - note.lane) * (GameScene.laneWidth - GameScene.horizon/7)	// 水平線上と判定線上でのx座標のずれ
//		let a = c / b
//		xpos = GameScene.laneWidth * 3/2 + CGFloat(note.lane) * GameScene.laneWidth		// 判定線上でのx座標
//		xpos += (y - GameScene.judgeLineY) * a										// 判定線から離れている分補正
//
//
//
//		if note.type == .middle{ // 線のときだけずらす(開始点がposition)→長さの半分だけずらすように！
//			xpos -= diameter/2
//		}
//
//		note.image.position = CGPoint(x:xpos ,y:y)//描写した後でないと反映されない
//	}


}

