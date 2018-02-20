//
//  Note.swift
//  音ゲー（仮）
//
//  Created by 植田暢大 on 2017/10/04.
//  Copyright © 2017年 植田暢大. All rights reserved.
//

import SpriteKit

class Tap: Note {
	
	override init(beatPos beat: Double, lane: Int, speedRatio:CGFloat) {
		super.init(beatPos: beat, lane: lane, speedRatio:speedRatio)
		
		// imageのインスタンス(白円)を作成
		self.image = SKShapeNode(circleOfRadius: Dimensions.laneWidth / 2)
		image.fillColor = UIColor.white
		image.isHidden = true	// 初期状態では隠しておく
	}
	
	override func update(currentTime: TimeInterval) {
		// update不要なときはreturn
		guard !(image.isHidden && isJudged) else {		// 通過後のノーツはreturn
			return
		}
		
		let remainingPos = getPositionOnLane(currentTime: currentTime)		// 判定ラインまでの距離(3D)
		
		guard (!isJudged && remainingPos < Dimensions.laneLength) || (isJudged && !image.isHidden) else {		// 判定後と判定前で場合分け
			return
		}
		
		// x座標とy座標を計算しpositionを変更
		setPos(currentTime: currentTime)
		
		// 縦と横の大きさを計算し、imageのスケールを変更
		setScale(currentTime: currentTime)
		
		// ノーツが視点を向くように
		image.zRotation = atan(Dimensions.laneWidth * CGFloat(3 - lane) / (getPositionOnLane(currentTime: currentTime) + Dimensions.horizontalDistance * 8))
		
		// image.isHiddenを更新
		if position.y > Dimensions.horizonY || isJudged {		// 水平線より上、判定済みのものは隠す
			image.isHidden = true
		} else {
			image.isHidden = false
		}
	}
}

class Flick: Note {
	
	override init(beatPos beat: Double, lane: Int, speedRatio:CGFloat) {
		super.init(beatPos: beat, lane: lane, speedRatio:speedRatio)
		
		// imageのインスタンス(マゼンタ三角形)を作成
		let length = Dimensions.laneWidth / 2 // 三角形一辺の長さの半分
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
		// update不要なときはreturn
		guard !(image.isHidden && isJudged) else {		// 通過後のノーツはreturn
			return
		}
		
		let remainingPos = getPositionOnLane(currentTime: currentTime)		// 判定ラインまでの距離(3D)
		
		guard (!isJudged && remainingPos < Dimensions.laneLength) || (isJudged && !image.isHidden) else {		// 判定後と判定前で場合分け
			return
		}
		
		// x座標とy座標を計算しpositionを変更
		setPos(currentTime: currentTime)
		
		// スケールを変更
		setScale(currentTime: currentTime)
		
		// image.isHiddenを更新
		if position.y > Dimensions.horizonY || isJudged {		// 水平線より上、判定済みのものは隠す
			image.isHidden = true
		} else {
			image.isHidden = false
		}
    }
}

class TapStart: Note {
	
	var next = Note()				// 次のノーツ（仮のインスタンス）
	var longImages = (long: SKShapeNode(), circle: SKShapeNode())	// このノーツを始点とする緑太線の画像と、判定線上に残る緑楕円(将来的にはimageに格納？)
	
	override init(beatPos beat: Double, lane: Int, speedRatio:CGFloat) {
		super.init(beatPos: beat, lane: lane, speedRatio:speedRatio)
		
		// imageのインスタンス(緑円)を作成
		image = SKShapeNode(circleOfRadius: Dimensions.laneWidth / 2)
		image.fillColor = UIColor.green
		image.isHidden = true	// 初期状態では隠しておく
		
		// longImagesのインスタンスを作成
		self.longImages = (SKShapeNode(path: CGMutablePath()), SKShapeNode(circleOfRadius: Dimensions.laneWidth / 2))
		longImages.long.fillColor = UIColor.green
		longImages.long.alpha = 0.8
		longImages.long.zPosition = -1
		longImages.long.isHidden = true
		longImages.circle.fillColor = UIColor.green
		longImages.circle.isHidden = true
	}
	
	override func update(currentTime: TimeInterval) {
		
		let remainingPos = getPositionOnLane(currentTime: currentTime)				// 判定ラインまでの距離(3D)
		let remainingPos2 = next.getPositionOnLane(currentTime: currentTime)		// 次ノーツの判定ラインまでの距離(3D)

		// 後続ノーツを先にupdate
		if remainingPos <= Dimensions.laneLength {
			next.update(currentTime: currentTime)
		}
		
		// update不要なときはreturn
		guard ((!isJudged || remainingPos > 0) && remainingPos < Dimensions.laneLength)			// 描画域内にあるか、過ぎていても判定前なら更新
			|| (remainingPos < 0 && 0 < remainingPos2)											// ロングノーツが描画域内にあれば更新
			|| ((!longImages.circle.isHidden || !longImages.long.isHidden) && (next.isJudged || next.position.y < Dimensions.judgeLineY))	// longImages消し忘れ防止
			else {
			return
		}
		
		
		// x座標とy座標を計算しpositionを変更
		setPos(currentTime: currentTime)
		
		
		// 縦と横の大きさを計算し、imageのスケールを変更
		setScale(currentTime: currentTime)
		
		
		// ノーツが視点を向くように
		image.zRotation = atan(Dimensions.laneWidth * CGFloat(3 - lane) / (getPositionOnLane(currentTime: currentTime) + Dimensions.horizontalDistance * 8))
		
		
		// longImage.longを更新
		let long: (startPos: CGPoint, endPos: CGPoint, startWidth: CGFloat, endWidth: CGFloat)	// 部分ロングノーツの(始点中心座標, 終点中心座標, 始点幅, 終点幅)
		
		// 終点の情報を代入
		if next.position.y < Dimensions.horizonY {		// 終点ノーツが描画域内にあるとき
			long.endPos = next.position
			long.endWidth = next.size / noteScale
		} else {										// 終点ノーツが描画域より奥にあるとき
			let posY = Dimensions.horizonY
			let posX = ((next.position.y - Dimensions.horizonY) * position.x + (Dimensions.horizonY - position.y) * next.position.x)
				/ (next.position.y - position.y)			// 始点と終点のx座標を内分
			
			long.endPos = CGPoint(x: posX, y: posY)
			long.endWidth = Dimensions.horizonLength / 7
		}
		// 始点の情報を代入
		if position.y > Dimensions.judgeLineY && !isJudged {		// 始点ノーツが判定線を通過する前で、判定する前(判定後は位置が更新されないので...)
			long.startPos = position
			long.startWidth = size / noteScale
		} else {
			let posY = Dimensions.judgeLineY
			let posX = ((next.position.y - Dimensions.judgeLineY) * position.x + (Dimensions.judgeLineY - position.y) * next.position.x)
				/ (next.position.y - position.y)			// 始点と終点のx座標を内分
			
			long.startPos = CGPoint(x: posX, y: posY)
			long.startWidth = Dimensions.laneWidth
		}
		
		let path = CGMutablePath()      // 台形の外周
		path.move   (to: CGPoint(x: long.startPos.x - long.startWidth/2, y: long.startPos.y))	// 始点、台形の左下
		path.addLine(to: CGPoint(x: long.startPos.x + long.startWidth/2, y: long.startPos.y))	// 右下
		path.addLine(to: CGPoint(x: long.endPos.x   + long.endWidth/2,   y: long.endPos.y))		// 右上
		path.addLine(to: CGPoint(x: long.endPos.x   - long.endWidth/2,   y: long.endPos.y))		// 左上
		path.closeSubpath()
		longImages.long.path = path		// pathを変更(longImage.longの更新完了)

		
		// longImages.circleを更新
		if position.y <= Dimensions.judgeLineY || isJudged {		// 始点ノーツが判定線を通過した後か、判定された後
			// 理想軌道の判定線上に緑円を描く
			// 楕円の縦幅を計算
			let lSquare = pow(Dimensions.horizontalDistance, 2) + pow(Dimensions.laneWidth * 9/2 - long.startPos.x, 2)
			let denomOfAtan = lSquare + pow(Dimensions.verticalDistance, 2) - pow(noteScale * Dimensions.laneWidth / 2, 2)
			guard 0 < denomOfAtan else {
				return
			}
			let deltaY = Dimensions.R * atan(noteScale * Dimensions.laneWidth * Dimensions.verticalDistance / denomOfAtan)
			
			longImages.circle.yScale = deltaY / Dimensions.laneWidth
			longImages.circle.xScale = noteScale
			longImages.circle.position = long.startPos
			longImages.circle.zRotation = atan(Dimensions.laneWidth * CGFloat(3 - lane) / (Dimensions.horizontalDistance * 8))
		}
		
		
		// isHiddenを更新
		if position.y >= Dimensions.horizonY || position.y < Dimensions.judgeLineY || isJudged {		// 水平線より上、判定済みのものは隠す(判定線超えたら引き継ぐ)
			image.isHidden = true
		} else {
			image.isHidden = false
		}
		if position.y >= Dimensions.horizonY || next.position.y < Dimensions.judgeLineY || next.isJudged {
			longImages.long.isHidden = true
		} else {
			longImages.long.isHidden = false
		}
		if position.y >= Dimensions.judgeLineY || next.position.y < Dimensions.judgeLineY || next.isJudged {
			longImages.circle.isHidden = true
		} else {
			longImages.circle.isHidden = false
		}
	}
}

class Middle: Note {

	var next = Note()				// 次のノーツ（仮のインスタンス）
	var longImages = (long: SKShapeNode(), circle: SKShapeNode())	// このノーツを始点とする緑太線の画像と、判定線上に残る緑楕円(将来的にはimageに格納？)
	override var position: CGPoint {								// positionを左端ではなく線の中点にするためオーバーライド
		get {
			return CGPoint(x: image.position.x + size / 2, y: image.position.y)
		}
		set {
			image.position = CGPoint(x: newValue.x - size / 2, y: newValue.y)
		}
	}
	
    override init(beatPos beat: Double, lane: Int, speedRatio:CGFloat) {
        	super.init(beatPos: beat, lane: lane, speedRatio:speedRatio)
	
		self.isJudgeable = false
	
		// imageのインスタンス(緑線分)を作成
		var points = [
			CGPoint(x: 0.0, y: 0.0),
			CGPoint(x: Dimensions.laneWidth, y: 0.0)
		]
		self.image = SKShapeNode(points: &points, count: points.count)
		image.lineWidth = 5.0
		image.strokeColor = UIColor.green
		image.isHidden = true	// 初期状態では隠しておく
		
		// longImagesのインスタンスを作成
		self.longImages = (SKShapeNode(path: CGMutablePath()), SKShapeNode(circleOfRadius: Dimensions.laneWidth / 2))
		longImages.long.fillColor = UIColor.green
		longImages.long.alpha = 0.8
		longImages.long.zPosition = -1
		longImages.long.isHidden = true
		longImages.circle.fillColor = UIColor.green
		longImages.circle.isHidden = true
    }

	override func update(currentTime: TimeInterval) {
		
		let remainingPos = getPositionOnLane(currentTime: currentTime)				// 判定ラインまでの距離(3D)
		
		// 後続ノーツを先にupdate
		if remainingPos <= Dimensions.laneLength {
			next.update(currentTime: currentTime)
		}
		
		// update不要なときはreturn
		guard !(isJudged && image.isHidden && longImages.circle.isHidden && longImages.long.isHidden) else {		// 通過後のノーツはreturn
			return
		}
	
		
		// x座標とy座標を計算しpositionを変更
		setPos(currentTime: currentTime)
		
		
		// スケールを変更
		setScale(currentTime: currentTime)
		
		
		// longImage.longを更新
		let long: (startPos: CGPoint, endPos: CGPoint, startWidth: CGFloat, endWidth: CGFloat)	// 部分ロングノーツの(始点中心座標, 終点中心座標, 始点幅, 終点幅)
		
		// 終点の情報を代入
		if next.position.y < Dimensions.horizonY {		// 終点ノーツが描画域内にあるとき
			long.endPos = next.position
			long.endWidth = next.size / noteScale
		} else {										// 終点ノーツが描画域より奥にあるとき
			let posY = Dimensions.horizonY
			let posX = ((next.position.y - Dimensions.horizonY) * position.x + (Dimensions.horizonY - position.y) * next.position.x)
				/ (next.position.y - position.y)			// 始点と終点のx座標を内分
			
			long.endPos = CGPoint(x: posX, y: posY)
			long.endWidth = Dimensions.horizonLength / 7
		}
		// 始点の情報を代入
		if position.y > Dimensions.judgeLineY && !isJudged {		// 始点ノーツが判定線を通過する前で、判定する前(判定後は位置が更新されないので...)
			long.startPos = position
			long.startWidth = size / noteScale
		} else {
			let posY = Dimensions.judgeLineY
			let posX = ((next.position.y - Dimensions.judgeLineY) * position.x + (Dimensions.judgeLineY - position.y) * next.position.x)
				/ (next.position.y - position.y)			// 始点と終点のx座標を内分
			
			long.startPos = CGPoint(x: posX, y: posY)
			long.startWidth = Dimensions.laneWidth
		}
		
		let path = CGMutablePath()      // 台形の外周
		path.move   (to: CGPoint(x: long.startPos.x - long.startWidth/2, y: long.startPos.y))	// 始点、台形の左下
		path.addLine(to: CGPoint(x: long.startPos.x + long.startWidth/2, y: long.startPos.y))	// 右下
		path.addLine(to: CGPoint(x: long.endPos.x   + long.endWidth/2,   y: long.endPos.y))		// 右上
		path.addLine(to: CGPoint(x: long.endPos.x   - long.endWidth/2,   y: long.endPos.y))		// 左上
		path.closeSubpath()
		longImages.long.path = path		// pathを変更(longImage.longの更新完了)
		
		
		// longImages.circleを更新
		if position.y <= Dimensions.judgeLineY || isJudged {		// 始点ノーツが判定線を通過した後か、判定された後
			// 理想軌道の判定線上に緑円を描く
			// 楕円の縦幅を計算
			let lSquare = pow(Dimensions.horizontalDistance, 2) + pow(Dimensions.laneWidth * 9/2 - long.startPos.x, 2)
			let denomOfAtan = lSquare + pow(Dimensions.verticalDistance, 2) - pow(noteScale * Dimensions.laneWidth / 2, 2)
			guard 0 < denomOfAtan else {
				return
			}
			let deltaY = Dimensions.R * atan(noteScale * Dimensions.laneWidth * Dimensions.verticalDistance / denomOfAtan)
			
			longImages.circle.yScale = deltaY / Dimensions.laneWidth
			longImages.circle.xScale = noteScale
			longImages.circle.position = long.startPos
			longImages.circle.zRotation = atan(Dimensions.laneWidth * CGFloat(3 - lane) / (Dimensions.horizontalDistance * 8))
		}
		
		
		// isHiddenを更新
		if position.y >= Dimensions.horizonY || position.y < Dimensions.judgeLineY || isJudged {		// 水平線より上、判定済みのものは隠す。判定線超えたら引き継ぐ
			image.isHidden = true
		} else {
			image.isHidden = false
		}
		if position.y >= Dimensions.horizonY || next.position.y < Dimensions.judgeLineY || next.isJudged {
			longImages.long.isHidden = true
		} else {
			longImages.long.isHidden = false
		}
		if position.y >= Dimensions.judgeLineY || next.position.y < Dimensions.judgeLineY || next.isJudged {
			longImages.circle.isHidden = true
		} else {
			longImages.circle.isHidden = false
		}
	}
}

class TapEnd: Note {
	
	override init(beatPos beat: Double, lane: Int, speedRatio:CGFloat) {
		super.init(beatPos: beat, lane: lane, speedRatio:speedRatio)
		
		self.isJudgeable = false
		
		// imageのインスタンス(緑円)を作成
		image = SKShapeNode(circleOfRadius: Dimensions.laneWidth / 2)
		image.fillColor = UIColor.green
		image.isHidden = true	// 初期状態では隠しておく
	}
	
	override func update(currentTime: TimeInterval) {
		// update不要なときはreturn
		guard !(image.isHidden && isJudged) else {		// 通過後のノーツはreturn
			return
		}
		
		// x座標とy座標を計算しpositionを変更
		setPos(currentTime: currentTime)
		
		// 縦と横の大きさを計算し、imageのスケールを変更
		setScale(currentTime: currentTime)
		
		// ノーツが視点を向くように
		image.zRotation = atan(Dimensions.laneWidth * CGFloat(3 - lane) / (getPositionOnLane(currentTime: currentTime) + Dimensions.horizontalDistance * 8))

		// image.isHiddenを更新
		if position.y > Dimensions.horizonY || isJudged {		// 水平線より上、判定済みのものは隠す
			image.isHidden = true
		} else {
			image.isHidden = false
		}
	}
}

class FlickEnd: Note {
	
	override init(beatPos beat: Double, lane: Int, speedRatio:CGFloat) {
		super.init(beatPos: beat, lane: lane, speedRatio:speedRatio)
		
		self.isJudgeable = false
		
		// imageのインスタンス(マゼンタ三角形)を作成
		let length = Dimensions.laneWidth / 2 // 三角形一辺の長さの半分
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
		// update不要なときはreturn
		guard !(image.isHidden && isJudged) else {		// 通過後のノーツはreturn
			return
		}		
		
		// x座標とy座標を計算しpositionを変更
		setPos(currentTime: currentTime)
		
		// 縦と横の大きさを計算し、imageのスケールを変更
		setScale(currentTime: currentTime)
		
		// image.isHiddenを更新
		if position.y > Dimensions.horizonY || isJudged {		// 水平線より上、判定済みのものは隠す
			image.isHidden = true
		} else {
			image.isHidden = false
		}
	}
}


// ノーツ基本クラス
class Note {
	
	let beat: Double				// "拍"単位！小節ではない！！！
	let lane: Int				// レーンのインデックス(0始まり)

	var image = SKShapeNode()	// ノーツの画像
	var size: CGFloat = 0		// ノーツの横幅
	var isJudged = false		// 判定済みかどうか
	var isJudgeable = true		//判定可能かどうか。初期状態では始点系のみtrue
	var position: CGPoint {		// ノーツの座標
		get {
			return image.position
		}
		set {
			image.position = newValue
		}
	}
	
	let noteScale: CGFloat = 1.3	// レーン幅に対するノーツの幅の倍率
	let speed: CGFloat  		// スピード

	
	init(beatPos beat: Double, lane: Int, speedRatio:CGFloat) {
	  self.speed = 1350.0 * speedRatio
        self.beat = beat
        self.lane = lane
    }
	init() {
		self.beat = 0
		self.lane = 0
		self.speed = 1350.0
	}
	
	func update(currentTime: TimeInterval) {}    // ノーツの座標等の更新、毎フレーム呼ばれる
	
	// 時刻から3D空間レーン上のノーツ座標を得る
	fileprivate func getPositionOnLane(currentTime: TimeInterval) -> CGFloat {
	
		var second: TimeInterval = 0.0
		var i = 0
		while(i + 1 < GameScene.variableBPMList.count && GameScene.variableBPMList[i + 1].startPos < beat) {
			second += (GameScene.variableBPMList[i + 1].startPos - GameScene.variableBPMList[i].startPos) / (GameScene.variableBPMList[i].bpm/60)
			
			i += 1
		}
		second += (beat - GameScene.variableBPMList[i].startPos) / (GameScene.variableBPMList[i].bpm/60)
		second -= (currentTime - GameScene.start)
		return CGFloat(second) * speed	// 判定線からの水平距離x
	}
	
	// ノーツの座標を設定
	fileprivate func setPos(currentTime: TimeInterval) {
		
		/* y座標の計算 */
		
		
		let fypos = getPositionOnLane(currentTime: currentTime)	  // 判定線からの水平距離x
		
		// 球面?に投写
		let denomOfAtan = pow(Dimensions.R, 2) + Dimensions.horizontalDistance * fypos		// atanの分母
		guard 0 < denomOfAtan else {	// atan内の分母が0になるのを防止
			return
		}
		let posY = Dimensions.R * atan(Dimensions.verticalDistance * fypos / denomOfAtan) + Dimensions.judgeLineY
		
		
		/* x座標の計算 */
		
		var posX: CGFloat
		
		let b = Dimensions.horizonY - Dimensions.judgeLineY   								// 水平線から判定線までの2D上の距離
		let c = CGFloat(3 - lane) * (Dimensions.laneWidth - Dimensions.horizonLength/7)		// 水平線上と判定線上でのx座標のずれ
		posX = Dimensions.laneWidth * 3/2 + CGFloat(lane) * Dimensions.laneWidth			// 判定線上でのx座標
		posX += (posY - Dimensions.judgeLineY) * (c/b)										// 判定線から離れている分補正
		
		
		// 座標を反映
		self.position = CGPoint(x: posX, y: posY)
	}
	
	// ノーツのスケールを設定
	fileprivate func setScale(currentTime: TimeInterval) {
		
		// ノーツの横幅を計算(改善点: fyposとRはsetPos関数でも計算されている。上手く計算を1度で済ませたい。)
		let fypos = getPositionOnLane(currentTime: currentTime)									// 判定線からの水平距離x
		let grad = (Dimensions.horizonLength/7 - Dimensions.laneWidth) / (Dimensions.horizonY - Dimensions.judgeLineY)	// 傾き
		self.size = noteScale * (grad * (position.y - Dimensions.horizonY) + Dimensions.horizonLength/7)

		// ノーツの横幅と縦幅をscaleで設定
		if self is Tap || self is TapStart || self is TapEnd {		// 楕円
			let lSquare = pow(Dimensions.horizontalDistance + fypos, 2) + pow(Dimensions.laneWidth * CGFloat(3 - lane), 2)
			let denomOfAtan = lSquare + pow(Dimensions.verticalDistance, 2) - pow(noteScale * Dimensions.laneWidth / 2, 2)				// atan内の分母
			guard 0 < denomOfAtan else {	// atan内の分母が0になるのを防止
				return
			}
			let deltaY = Dimensions.R * atan(noteScale * Dimensions.laneWidth * Dimensions.verticalDistance / denomOfAtan)

			image.xScale = size / Dimensions.laneWidth
			image.yScale = deltaY / Dimensions.laneWidth
		} else {		// 線と三角形
			image.setScale(size / Dimensions.laneWidth)
		}
	}
}

