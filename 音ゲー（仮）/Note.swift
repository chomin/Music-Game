//
//  Note.swift
//  音ゲー（仮）
//
//  Created by 植田暢大 on 2017/10/04.
//  Copyright © 2017年 植田暢大. All rights reserved.
//

import SpriteKit

class Tap: Note {
	
	override init(beatPos beat: Double, lane: Int) {
		super.init(beatPos: beat, lane: lane)
		
		// imageのインスタンス(白円)を作成
		self.image = SKShapeNode(circleOfRadius: GameScene.laneWidth / 2)
		image.fillColor = UIColor.white
		image.isHidden = true	// 初期状態では隠しておく
	}
	
	override func update(currentTime: TimeInterval) {
		// update不要なときはreturn
		guard !(image.isHidden && isJudged) else {		// 通過後のノーツはreturn
			return
		}
		
//		let remainingBeat = pos - ((currentTime - GameScene.start) * GameScene.bpm/60)		// あと何拍で判定ラインに乗るか
//
//		//建築予定地
//		//建築予定地
//		let nowPos = GameScene.variableBPMList[bpmIndex].startPos + (currentTime - GameScene.variableBPMList[bpmIndex].startTime!) * GameScene.variableBPMList[bpmIndex].bpm/60
//		let remainingBeat = beat - nowPos		// あと何拍で判定ラインに乗るか
		
		let remainingPos = getPositionOnLane(currentTime: currentTime)		// 判定ラインまでの距離(3D)
		
		guard (!isJudged && remainingPos < GameScene.laneLength) || (isJudged && !image.isHidden) else {		// 判定後と判定前で場合分け
			return
		}
		
		// x座標とy座標を計算しpositionを変更
		setPos(currentTime: currentTime)
		
		// 縦と横の大きさを計算し、imageのスケールを変更
		setScale(currentTime: currentTime)
		
		// ノーツが視点を向くように
		image.zRotation = atan(GameScene.laneWidth * CGFloat(3 - lane) / (getPositionOnLane(currentTime: currentTime) + horizontalDistance * 8))
		
		// image.isHiddenを更新
		if position.y > GameScene.horizonY || isJudged {		// 水平線より上、判定済みのものは隠す
			image.isHidden = true
		} else {
			image.isHidden = false
		}
	}
}

class Flick: Note {
	
	override init(beatPos beat: Double, lane: Int) {
		super.init(beatPos: beat, lane: lane)
		
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
		// update不要なときはreturn
		guard !(image.isHidden && isJudged) else {		// 通過後のノーツはreturn
			return
		}
		
//		let remainingBeat = pos - ((currentTime - GameScene.start) * GameScene.bpm/60)    // あと何拍で判定ラインに乗るか
//
//		//建築予定地
//		let nowPos = GameScene.variableBPMList[bpmIndex].startPos + (currentTime - GameScene.variableBPMList[bpmIndex].startTime!) * GameScene.variableBPMList[bpmIndex].bpm/60
//		let remainingBeat = beat - nowPos		// あと何拍で判定ラインに乗るか
		
		let remainingPos = getPositionOnLane(currentTime: currentTime)		// 判定ラインまでの距離(3D)
		
		guard (!isJudged && remainingPos < GameScene.laneLength) || (isJudged && !image.isHidden) else {		// 判定後と判定前で場合分け
			return
		}
		
		// x座標とy座標を計算しpositionを変更
		setPos(currentTime: currentTime)
		
		// スケールを変更
		setScale(currentTime: currentTime)
		
		// image.isHiddenを更新
		if position.y > GameScene.horizonY || isJudged {		// 水平線より上、判定済みのものは隠す
			image.isHidden = true
		} else {
			image.isHidden = false
		}
    }
}

class TapStart: Note {
	
	var next = Note()				// 次のノーツ（仮のインスタンス）
	var longImages = (long: SKShapeNode(), circle: SKShapeNode())	// このノーツを始点とする緑太線の画像と、判定線上に残る緑楕円(将来的にはimageに格納？)
	
	override init(beatPos beat: Double, lane: Int) {
		super.init(beatPos: beat, lane: lane)
		
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
		
		let remainingPos = getPositionOnLane(currentTime: currentTime)				// 判定ラインまでの距離(3D)
		let remainingPos2 = next.getPositionOnLane(currentTime: currentTime)		// 次ノーツの判定ラインまでの距離(3D)

		// 後続ノーツを先にupdate
		if remainingPos <= GameScene.laneLength {
			next.update(currentTime: currentTime)
		}
		
//		let remainingBeat = pos - ((currentTime - GameScene.start) * GameScene.bpm/60)			// あと何拍で判定ラインに乗るか
//		let remainingBeat2 = next.pos - ((currentTime - GameScene.start) * GameScene.bpm/60)    // 次ノーツがあと何拍で判定ラインに乗るか
//
//		//建築予定地
//		//建築予定地
//		let nowPos = GameScene.variableBPMList[bpmIndex].startPos + (currentTime - GameScene.variableBPMList[bpmIndex].startTime!) * GameScene.variableBPMList[bpmIndex].bpm/60
//		let remainingBeat = beat - nowPos		// あと何拍で判定ラインに乗るか
//		let remainingBeat2 = next.beat - nowPos		// あと何拍で判定ラインに乗るか
		
		
		// update不要なときはreturn
		guard ((!isJudged || remainingPos > 0) && remainingPos < GameScene.laneLength)			// 描画域内にあるか、過ぎていても判定前なら更新
			|| (remainingPos2 > 0 && remainingPos2 < GameScene.laneLength)						// 次ノーツが描画域内にあれば更新(ロングのため)
			|| ((!longImages.circle.isHidden || !longImages.long.isHidden) && (next.isJudged || next.position.y < GameScene.judgeLineY))	// longImages消し忘れ防止
			else {
			return
		}
		
		
		// x座標とy座標を計算しpositionを変更
		setPos(currentTime: currentTime)
		
		
		// 縦と横の大きさを計算し、imageのスケールを変更
		setScale(currentTime: currentTime)
		
		
		// ノーツが視点を向くように
		image.zRotation = atan(GameScene.laneWidth * CGFloat(3 - lane) / (getPositionOnLane(currentTime: currentTime) + horizontalDistance * 8))
		
		
		// longImage.longを更新
		var long: (startPos: CGPoint, endPos: CGPoint, startWidth: CGFloat, endWidth: CGFloat)	// 部分ロングノーツの(始点中心座標, 終点中心座標, 始点幅, 終点幅)
		
		// 終点の情報を代入
		if next.position.y < GameScene.horizonY {		// 終点ノーツが描画域内にあるとき
			long.endPos = next.position
			long.endWidth = next.size / noteScale
		} else {										// 終点ノーツが描画域より奥にあるとき
			let posY = GameScene.horizonY
			let posX = ((next.position.y - GameScene.horizonY) * position.x + (GameScene.horizonY - position.y) * next.position.x)
				/ (next.position.y - position.y)			// 始点と終点のx座標を内分
			
			long.endPos = CGPoint(x: posX, y: posY)
			long.endWidth = GameScene.horizon / 7
		}
		// 始点の情報を代入
		if position.y > GameScene.judgeLineY && !isJudged {		// 始点ノーツが判定線を通過する前で、判定する前(判定後は位置が更新されないので...)
			long.startPos = position
			long.startWidth = size / noteScale
		} else {
			let posY = GameScene.judgeLineY
			let posX = ((next.position.y - GameScene.judgeLineY) * position.x + (GameScene.judgeLineY - position.y) * next.position.x)
				/ (next.position.y - position.y)			// 始点と終点のx座標を内分
			
			long.startPos = CGPoint(x: posX, y: posY)
			long.startWidth = GameScene.laneWidth
		}
		
		let path = CGMutablePath()      // 台形の外周
		path.move   (to: CGPoint(x: long.startPos.x - long.startWidth/2, y: long.startPos.y))	// 始点、台形の左下
		path.addLine(to: CGPoint(x: long.startPos.x + long.startWidth/2, y: long.startPos.y))	// 右下
		path.addLine(to: CGPoint(x: long.endPos.x   + long.endWidth/2,   y: long.endPos.y))		// 右上
		path.addLine(to: CGPoint(x: long.endPos.x   - long.endWidth/2,   y: long.endPos.y))		// 左上
		path.closeSubpath()
		longImages.long.path = path		// pathを変更(longImage.longの更新完了)

		
		// longImages.circleを更新
		if position.y <= GameScene.judgeLineY || isJudged {		// 始点ノーツが判定線を通過した後か、判定された後
			// 理想軌道の判定線上に緑円を描く
			// 楕円の縦幅を計算
			let R = sqrt(pow(horizontalDistance, 2) + pow(verticalDistance!, 2))
			let lSquare = pow(horizontalDistance, 2) + pow(GameScene.laneWidth * 9/2 - long.startPos.x, 2)
			let denomOfAtan = lSquare + pow(verticalDistance!, 2) - pow(noteScale * GameScene.laneWidth / 2, 2)
			guard 0 < denomOfAtan else {
				return
			}
			let deltaY = R * atan(noteScale * GameScene.laneWidth * verticalDistance! / denomOfAtan)
			
			longImages.circle.yScale = deltaY / GameScene.laneWidth
			longImages.circle.xScale = noteScale
			longImages.circle.position = long.startPos
			longImages.circle.zRotation = atan(GameScene.laneWidth * CGFloat(3 - lane) / (horizontalDistance * 8))
		}
		
		
		// isHiddenを更新
		if position.y >= GameScene.horizonY || position.y < GameScene.judgeLineY || isJudged {		// 水平線より上、判定済みのものは隠す(判定線超えたら引き継ぐ)
			image.isHidden = true
		} else {
			image.isHidden = false
		}
		if position.y >= GameScene.horizonY || next.position.y < GameScene.judgeLineY || next.isJudged {
			longImages.long.isHidden = true
		} else {
			longImages.long.isHidden = false
		}
		if position.y >= GameScene.judgeLineY || next.position.y < GameScene.judgeLineY || next.isJudged {
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
	
    override init(beatPos beat: Double, lane: Int) {
        super.init(beatPos: beat, lane: lane)
		
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
		
		let remainingPos = getPositionOnLane(currentTime: currentTime)				// 判定ラインまでの距離(3D)
		
		// 後続ノーツを先にupdate
		if remainingPos <= GameScene.laneLength {
			next.update(currentTime: currentTime)
		}

//		//建築予定地//建築予定地
//		let nowPos = GameScene.variableBPMList[bpmIndex].startPos + (currentTime - GameScene.variableBPMList[bpmIndex].startTime!) * GameScene.variableBPMList[bpmIndex].bpm/60
//		let remainingBeat = beat - nowPos		// あと何拍で判定ラインに乗るか
//		let remainingBeat2 = next.beat - nowPos	// あと何拍で判定ラインに乗るか
		
		// update不要なときはreturn
		guard !(isJudged && image.isHidden && longImages.circle.isHidden && longImages.long.isHidden) else {		// 通過後のノーツはreturn
			return
		}
	
		
		// x座標とy座標を計算しpositionを変更
		setPos(currentTime: currentTime)
		
		
		// スケールを変更
		setScale(currentTime: currentTime)
		
		
		// longImage.longを更新
		var long: (startPos: CGPoint, endPos: CGPoint, startWidth: CGFloat, endWidth: CGFloat)	// 部分ロングノーツの(始点中心座標, 終点中心座標, 始点幅, 終点幅)
		
		// 終点の情報を代入
		if next.position.y < GameScene.horizonY {		// 終点ノーツが描画域内にあるとき
			long.endPos = next.position
			long.endWidth = next.size / noteScale
		} else {										// 終点ノーツが描画域より奥にあるとき
			let posY = GameScene.horizonY
			let posX = ((next.position.y - GameScene.horizonY) * position.x + (GameScene.horizonY - position.y) * next.position.x)
				/ (next.position.y - position.y)			// 始点と終点のx座標を内分
			
			long.endPos = CGPoint(x: posX, y: posY)
			long.endWidth = GameScene.horizon / 7
		}
		// 始点の情報を代入
		if position.y > GameScene.judgeLineY && !isJudged {		// 始点ノーツが判定線を通過する前で、判定する前(判定後は位置が更新されないので...)
			long.startPos = position
			long.startWidth = size / noteScale
		} else {
			let posY = GameScene.judgeLineY
			let posX = ((next.position.y - GameScene.judgeLineY) * position.x + (GameScene.judgeLineY - position.y) * next.position.x)
				/ (next.position.y - position.y)			// 始点と終点のx座標を内分
			
			long.startPos = CGPoint(x: posX, y: posY)
			long.startWidth = GameScene.laneWidth
		}
		
		let path = CGMutablePath()      // 台形の外周
		path.move   (to: CGPoint(x: long.startPos.x - long.startWidth/2, y: long.startPos.y))	// 始点、台形の左下
		path.addLine(to: CGPoint(x: long.startPos.x + long.startWidth/2, y: long.startPos.y))	// 右下
		path.addLine(to: CGPoint(x: long.endPos.x   + long.endWidth/2,   y: long.endPos.y))		// 右上
		path.addLine(to: CGPoint(x: long.endPos.x   - long.endWidth/2,   y: long.endPos.y))		// 左上
		path.closeSubpath()
		longImages.long.path = path		// pathを変更(longImage.longの更新完了)
		
		
		// longImages.circleを更新
		if position.y <= GameScene.judgeLineY || isJudged {		// 始点ノーツが判定線を通過した後か、判定された後
			// 理想軌道の判定線上に緑円を描く
			// 楕円の縦幅を計算
			let R = sqrt(pow(horizontalDistance, 2) + pow(verticalDistance!, 2))
			let lSquare = pow(horizontalDistance, 2) + pow(GameScene.laneWidth * 9/2 - long.startPos.x, 2)
			let denomOfAtan = lSquare + pow(verticalDistance!, 2) - pow(noteScale * GameScene.laneWidth / 2, 2)
			guard 0 < denomOfAtan else {
				return
			}
			let deltaY = R * atan(noteScale * GameScene.laneWidth * verticalDistance! / denomOfAtan)
			
			longImages.circle.yScale = deltaY / GameScene.laneWidth
			longImages.circle.xScale = noteScale
			longImages.circle.position = long.startPos
			longImages.circle.zRotation = atan(GameScene.laneWidth * CGFloat(3 - lane) / (horizontalDistance * 8))
		}
		
		
		// isHiddenを更新
		if position.y >= GameScene.horizonY || position.y < GameScene.judgeLineY || isJudged {		// 水平線より上、判定済みのものは隠す。判定線超えたら引き継ぐ
			image.isHidden = true
		} else {
			image.isHidden = false
		}
		if position.y >= GameScene.horizonY || next.position.y < GameScene.judgeLineY || next.isJudged {
			longImages.long.isHidden = true
		} else {
			longImages.long.isHidden = false
		}
		if position.y >= GameScene.judgeLineY || next.position.y < GameScene.judgeLineY || next.isJudged {
			longImages.circle.isHidden = true
		} else {
			longImages.circle.isHidden = false
		}
	}
}

class TapEnd: Note {
	
	override init(beatPos beat: Double, lane: Int) {
		super.init(beatPos: beat, lane: lane)
		
		// imageのインスタンス(緑円)を作成
		image = SKShapeNode(circleOfRadius: GameScene.laneWidth / 2)
		image.fillColor = UIColor.green
		image.isHidden = true	// 初期状態では隠しておく
	}
	
	override func update(currentTime: TimeInterval) {
		// update不要なときはreturn
		guard !(image.isHidden && isJudged) else {		// 通過後のノーツはreturn
			return
		}
		
//		let remainingBeat = pos - ((currentTime - GameScene.start) * GameScene.bpm/60)		// あと何拍で判定ラインに乗るか
//
//		//建築予定地
//		let nowPos = GameScene.variableBPMList[bpmIndex].startPos + (currentTime - GameScene.variableBPMList[bpmIndex].startTime!) * GameScene.variableBPMList[bpmIndex].bpm/60
//		let remainingBeat = beat - nowPos		// あと何拍で判定ラインに乗るか
		
		
		// x座標とy座標を計算しpositionを変更
		setPos(currentTime: currentTime)
		
		// 縦と横の大きさを計算し、imageのスケールを変更
		setScale(currentTime: currentTime)
		
		// ノーツが視点を向くように
		image.zRotation = atan(GameScene.laneWidth * CGFloat(3 - lane) / (getPositionOnLane(currentTime: currentTime) + horizontalDistance * 8))

		// image.isHiddenを更新
		if position.y > GameScene.horizonY || isJudged {		// 水平線より上、判定済みのものは隠す
			image.isHidden = true
		} else {
			image.isHidden = false
		}
	}
}

class FlickEnd: Note {
	
	override init(beatPos beat: Double, lane: Int) {
		super.init(beatPos: beat, lane: lane)
		
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
		// update不要なときはreturn
		guard !(image.isHidden && isJudged) else {		// 通過後のノーツはreturn
			return
		}
//		let remainingBeat = pos - ((currentTime - GameScene.start) * GameScene./60)		// あと何拍で判定ラインに乗るか
//
//		//建築予定地
//		let nowPos = GameScene.variableBPMList[bpmIndex].startPos + (currentTime - GameScene.variableBPMList[bpmIndex].startTime!) * GameScene.variableBPMList[bpmIndex].bpm/60
//		let remainingBeat = beat - nowPos		// あと何拍で判定ラインに乗るか
		
		
		// x座標とy座標を計算しpositionを変更
		setPos(currentTime: currentTime)
		
		// 縦と横の大きさを計算し、imageのスケールを変更
		setScale(currentTime: currentTime)
		
		// image.isHiddenを更新
		if position.y > GameScene.horizonY || isJudged {		// 水平線より上、判定済みのものは隠す
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
//	var bpmIndex:Int{	//建築予定地
//		get{
//			var index = GameScene.variableBPMList.count - 1
//			while beat < GameScene.variableBPMList[index].startPos{
//				index -= 1
//			}
//			return index
//		}
//	}
	var image = SKShapeNode()	// ノーツの画像
	var size: CGFloat = 0		// ノーツの横幅
	var isJudged = false		// 判定済みかどうか
	var position: CGPoint {		// ノーツの座標
		get {
			return image.position
		}
		set {
			image.position = newValue
		}
	}
	
	let noteScale: CGFloat = 1.3	// レーン幅に対するノーツの幅の倍率
	let speed: CGFloat = 1350.0		// スピード
	// 立体感を出すための定数
	let horizontalDistance:CGFloat = GameScene.horizontalDistance		//画面から目までの水平距離a（約5000で10cmほど）
	let verticalDistance = GameScene.verticalDistance	//画面を垂直に見たとき、判定線から目までの高さh（実際の水平線の高さでもある）
														//モデルに合わせるなら水平線は画面上端辺りが丁度いい？モデルに合わせるなら大きくは変えてはならない。

	
    init(beatPos beat: Double, lane: Int) {
        self.beat = beat
        self.lane = lane
    }
	init() {
		self.beat = 0
		self.lane = 0
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
		
		
//		//建築予定地
//		var fypos:CGFloat = 0.0	// 判定線からの水平距離x(bpm変更後のものをちゃんと計算し直すべき？)
//		for i in 0...bpmIndex{
//			if i == bpmIndex{
//				fypos += CGFloat(60*(beat - GameScene.variableBPMList[i].startPos)/GameScene.variableBPMList[i].bpm)
//			}else{
//				fypos += CGFloat(60*(GameScene.variableBPMList[i+1].startPos - GameScene.variableBPMList[i].startPos)/GameScene.variableBPMList[i].bpm)
//			}
//		}
//		fypos -= CGFloat(currentTime - GameScene.start)
//		fypos *= speed
	
		
		let fypos = getPositionOnLane(currentTime: currentTime)	  // 判定線からの水平距離x
		
		// 球面?に投写
		let R = sqrt(pow(horizontalDistance, 2) + pow(verticalDistance!, 2))		// 視点から判定線までの距離(射影する球の半径)
		let denomOfAtan = pow(R, 2) + horizontalDistance * fypos				// atanの分母
		guard 0 < denomOfAtan else {	// atan内の分母が0になるのを防止
			return
		}
		let posY = R * atan(verticalDistance! * fypos / denomOfAtan) + GameScene.judgeLineY
		
		
		/* x座標の計算 */
		
		var posX: CGFloat
		
		let b = GameScene.horizonY - GameScene.judgeLineY   						// 水平線から判定線までの2D上の距離
		let c = CGFloat(3 - lane) * (GameScene.laneWidth - GameScene.horizon/7)		// 水平線上と判定線上でのx座標のずれ
		posX = GameScene.laneWidth * 3/2 + CGFloat(lane) * GameScene.laneWidth		// 判定線上でのx座標
		posX += (posY - GameScene.judgeLineY) * (c/b)								// 判定線から離れている分補正
		
		
		// 座標を反映
		self.position = CGPoint(x: posX, y: posY)
	}
	
	// ノーツのスケールを設定
	fileprivate func setScale(currentTime: TimeInterval) {
		
		// ノーツの横幅を計算(改善点: fyposとRはsetPos関数でも計算されている。上手く計算を1度で済ませたい。)
		let fypos = getPositionOnLane(currentTime: currentTime)									// 判定線からの水平距離x
		let R = sqrt(pow(horizontalDistance, 2) + pow(verticalDistance!, 2))					// 視点から判定線までの距離(射影する球の半径)
		let grad = (GameScene.horizon/7 - GameScene.laneWidth) / (GameScene.horizonY - GameScene.judgeLineY)	// 傾き
		self.size = noteScale * (grad * (position.y - GameScene.horizonY) + GameScene.horizon/7)

		// ノーツの横幅と縦幅をscaleで設定
		if self is Tap || self is TapStart || self is TapEnd {		// 楕円
			let lSquare = pow(horizontalDistance + fypos, 2) + pow(GameScene.laneWidth * CGFloat(3 - lane), 2)
			let denomOfAtan = lSquare + pow(verticalDistance!, 2) - pow(noteScale * GameScene.laneWidth / 2, 2)				// atan内の分母
			guard 0 < denomOfAtan else {	// atan内の分母が0になるのを防止
				return
			}
			let deltaY = R * atan(noteScale * GameScene.laneWidth * verticalDistance! / denomOfAtan)

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

