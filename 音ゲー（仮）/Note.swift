//
//  Note.swift
//  音ゲー（仮）
//
//  Created by 植田暢大 on 2017/10/04.
//  Copyright © 2017年 植田暢大. All rights reserved.
//

import SpriteKit

enum FlickDirection {
    case right, left, any
}

/// Tapノーツ。
/// touchesBeganか呼び出されたときに判定する。
class Tap: Note {
    
    let isLarge: Bool                   // 大ノーツかどうか
    let appearTime: TimeInterval        // 演奏開始から水平線を超えるまでの時間。これ以降にposの計算&更新を行う。
    
    private init(_ beatPos: Double, _ laneIndex: Int, _ isLarge: Bool, _ speed: CGFloat, _ appearTime: TimeInterval) {
        self.isLarge = isLarge
        self.appearTime = appearTime
        super.init(beatPos: beatPos, laneIndex: laneIndex, speed: speed)

        // imageのインスタンス(白円or黄円)を作成
        self.image = SKShapeNode(circleOfRadius: Note.initialSize / 2)
        image.fillColor = isLarge ? UIColor.yellow : UIColor.white
        image.isHidden = true   // 初期状態では隠しておく
    }
    convenience init(noteMaterial: NoteMaterial, speed: CGFloat, appearTime: TimeInterval) {
        self.init(noteMaterial.beat, noteMaterial.laneIndex, noteMaterial.isLarge, speed, appearTime)
    }
    convenience init(tapEnd: TapEnd) {
        self.init(tapEnd.beat, tapEnd.laneIndex, tapEnd.isLarge, tapEnd.speed, 0)
    }
    
    override func update(_ passedTime: TimeInterval) {
        // update不要なときはreturn
        guard passedTime > appearTime else {            // 描画領域外のノーツはreturn
            return
        }
        guard !(image.isHidden && isJudged) else {      // 通過後のノーツはreturn
            return
        }
        
        super.update(passedTime)
        
        // x座標とy座標を計算しpositionを変更
        setPos()
        
        // 縦と横の大きさを計算し、imageのスケールを変更
        setScale()
        
        // ノーツが視点を向くように
        let d = Dimensions.frameMidX - CGFloat(1.5 + Double(laneIndex)) * Dimensions.laneWidth  // 判定線中央から測ったx座標
        image.zRotation = atan(d / (positionOnLane + Dimensions.horizontalDistance * 8))
        
        // image.isHiddenを更新
        if position.y > Dimensions.horizonY || isJudged {       // 水平線より上、判定済みのものは隠す
            image.isHidden = true
        } else {
            image.isHidden = false
        }
    }
}

/// フリックノーツ
/// 原則としてtouchesMovedが呼び出されたときに判定する。
/// 呼び出し時にまだparfectの時間でない場合(before)について、後にparfect判定を行うかもしれないので、時間とUItouch情報を該当LaneインスタンスのstoredFlickJudgeに、レーン情報を該当GSTouchインスタンスのstoredFlickJudgeLaneIndexに格納し、後にこの情報をもとにGameSceneTouchesファイル内に記述されているGameScene.storedFlickJudge関数にて判定を行う。
/// この呼出は情報が残っているときにのみ行われ、該当ノーツの判定後に各情報格納場所にnilが入る。storedFlickJudgeの呼び出しタイミングはtouchesMoved呼び出し時にレーンから指が外れた時、touchesEnded呼び出し時、これ以上待ってもより良い判定が来なくなる時（ノーツの正確なタイミングの時間についてtimeLag予定時間(>0)と対象な時間）である。
class Flick: Note {
    
    let appearTime: TimeInterval        // 演奏開始から水平線を超えるまでの時間。これ以降にposの計算&更新を行う。
    let direction:  FlickDirection
    
    private init(_ beatPos: Double, _ laneIndex: Int, _ speed: CGFloat, _ appearTime: TimeInterval, _ direction: FlickDirection) {
        self.appearTime = appearTime
        self.direction = direction
        super.init(beatPos: beatPos, laneIndex: laneIndex, speed: speed)

        
        let length = Note.initialSize / 2   // 三角形一辺の長さの半分
        
        switch direction {
        case .any:
            // imageのインスタンス(マゼンタ三角形)を作成
            // 始点から終点までの４点を指定(2点を一致させ三角形に).
            var points = [
                CGPoint(x: length,  y: 0.0),
                CGPoint(x: -length, y: 0.0),
                CGPoint(x: 0.0,     y: length),
                CGPoint(x: length,  y: 0.0)
            ]
            self.image = SKShapeNode(points: &points, count: points.count)
            image.fillColor = UIColor.magenta
            
        case .right:
            var points = [
                CGPoint(x: 0.0,     y: 0.0),
                CGPoint(x: -length, y: -length),
                CGPoint(x: length,  y: 0.0),
                CGPoint(x: -length, y: length),
                CGPoint(x: 0.0,     y: 0.0)
            ]
            self.image = SKShapeNode(points: &points, count: points.count)
            image.fillColor = UIColor.cyan
            
        case .left:
            var points = [
                CGPoint(x: 0.0,     y: 0.0),
                CGPoint(x: length,  y: -length),
                CGPoint(x: -length, y: 0.0),
                CGPoint(x: length,  y: length),
                CGPoint(x: 0.0,     y: 0.0)
            ]
            self.image = SKShapeNode(points: &points, count: points.count)
            image.fillColor = UIColor.purple
        }
        image.lineWidth = 3.0
        image.isHidden = true   // 初期状態では隠しておく
        
    }
    convenience init(noteMaterial: NoteMaterial, speed: CGFloat, appearTime: TimeInterval, direction: FlickDirection) {
        self.init(noteMaterial.beat, noteMaterial.laneIndex, speed, appearTime, direction)
    }
    convenience init(flickEnd: FlickEnd) {
        self.init(flickEnd.beat, flickEnd.laneIndex, flickEnd.speed, 0, flickEnd.direction)
    }
    
    override func update(_ passedTime: TimeInterval) {
        // update不要なときはreturn
        guard passedTime > appearTime else {            // 描画領域外のノーツはreturn
            return
        }
        guard !(image.isHidden && isJudged) else {      // 通過後のノーツはreturn
            return
        }
        
        super.update(passedTime)
        
        // x座標とy座標を計算しpositionを変更
        setPos()
        
        // スケールを変更
        setScale()
        
        // image.isHiddenを更新
        if position.y > Dimensions.horizonY || isJudged {       // 水平線より上、判定済みのものは隠す
            image.isHidden = true
        } else {
            image.isHidden = false
        }
    }
}

/// ロング開始ノーツ
/// touchesBegan呼び出し時に判定する。
class TapStart: Note {
    
    var next = Note()                                               // 次のノーツ（仮のインスタンス）
    var longImages = (long: SKShapeNode(), circle: SKShapeNode())   // このノーツを始点とする緑太線の画像と、判定線上に残る緑楕円(将来的にはimageに格納？)
    let isLarge: Bool                                               // 大ノーツかどうか
    let appearTime: TimeInterval                                // 演奏開始から水平線を超えるまでの時間。これ以降にposの計算&更新を行う。
    
    private init(_ beatPos: Double, _ laneIndex: Int, _ isLarge: Bool, _ speed: CGFloat, _ appearTime: TimeInterval) {
        self.isLarge = isLarge
        self.appearTime = appearTime
        super.init(beatPos: beatPos, laneIndex: laneIndex, speed: speed)

        // imageのインスタンス(緑円or黄円)を作成
        image = SKShapeNode(circleOfRadius: Note.initialSize / 2)
        image.fillColor = isLarge ? UIColor.yellow : UIColor.green
        image.isHidden = true	// 初期状態では隠しておく
        
        // longImagesのインスタンスを作成
        self.longImages = (SKShapeNode(path: CGMutablePath()), SKShapeNode(circleOfRadius: Note.initialSize / 2))
        longImages.long.fillColor = UIColor.green
        longImages.long.alpha = 0.8
        longImages.long.zPosition = -1
        longImages.long.isHidden = true
        longImages.circle.fillColor = isLarge ? UIColor.yellow : UIColor.green
        longImages.circle.isHidden = true
    }
    convenience init(noteMaterial: NoteMaterial, speed: CGFloat, appearTime: TimeInterval) {
        self.init(noteMaterial.beat, noteMaterial.laneIndex, noteMaterial.isLarge, speed, appearTime)
    }
    convenience init(middle: Middle) {
        var following = middle.next
        while let middle = following as? Middle { following = middle.next }
        self.init(middle.beat, middle.laneIndex, (following as! TapEnd).isLarge, middle.speed, 0)
        self.next = middle.next
    }
    
    deinit {
        self.longImages.long.removeFromParent()
        self.longImages.circle.removeFromParent()
    }
    
    override func update(_ passedTime: TimeInterval) {
        // update不要なときはreturn
        guard passedTime > appearTime else {            // 描画域より上のノーツはreturn
            return
        }
        
        // 後続ノーツを先にupdate
        next.update(passedTime)
        
        super.update(passedTime)
        
        // update不要なときはreturn
        guard !isJudged || positionOnLane > 0                           // 描画域内にあるか、過ぎていても判定前なら更新
            || (positionOnLane < 0 && 0 < next.positionOnLane)          // ロングノーツが描画域内にあれば更新
            || ((!longImages.circle.isHidden || !longImages.long.isHidden) && (next.isJudged || next.position.y < Dimensions.judgeLineY))   // longImages消し忘れ防止
            else {
                return
        }
        
        // x座標とy座標を計算しpositionを変更
        setPos()
        
        // 縦と横の大きさを計算し、imageのスケールを変更
        setScale()
        
        // ノーツが視点を向くように
        let d = Dimensions.frameMidX - CGFloat(1.5 + Double(laneIndex)) * Dimensions.laneWidth  // 判定線中央から測ったx座標
        image.zRotation = atan(d / (positionOnLane + Dimensions.horizontalDistance * 8))
        
        /* longImage.longを更新 */
        let long: (startPos: CGPoint, endPos: CGPoint, startWidth: CGFloat, endWidth: CGFloat)  // 部分ロングノーツの(始点中心座標, 終点中心座標, 始点幅, 終点幅)
        
        // 終点の情報を代入
        if next.position.y < Dimensions.horizonY {      // 終点ノーツが描画域内にあるとき
            long.endPos = next.position
            long.endWidth = next.size * Note.longScale
        } else {                                        // 終点ノーツが描画域より奥にあるとき
            let posY = Dimensions.horizonY
            let posXOnHorizon     = Dimensions.horizonLeftX + Dimensions.laneWidthOnHorizon * CGFloat(Double(laneIndex) + 1/2)
            let posXOnHorizonNext = Dimensions.horizonLeftX + Dimensions.laneWidthOnHorizon * CGFloat(Double(next.laneIndex) + 1/2)
            let posX = ((Dimensions.laneLength - positionOnLane) * posXOnHorizonNext + (next.positionOnLane - Dimensions.laneLength) * posXOnHorizon)
                / (next.positionOnLane - positionOnLane)            // 始点と終点のx座標を内分
            
            long.endPos = CGPoint(x: posX, y: posY)
            long.endWidth = Dimensions.laneWidthOnHorizon * Note.scale * Note.longScale
        }
        // 始点の情報を代入
        if position.y > Dimensions.judgeLineY {
            if !isJudged {
                // ノーツがレーンの半ばにある時
                long.startPos = position
                long.startWidth = size * Note.longScale
            } else {
                // レーン通過前に判定された時
                long.startPos = CGPoint(x: Dimensions.buttonX[laneIndex], y: Dimensions.judgeLineY)
                long.startWidth = Dimensions.laneWidth * Note.scale * Note.longScale
            }
        } else {
            // ノーツがレーンを通過した時
            let posY = Dimensions.judgeLineY
            let posX = (-positionOnLane * Dimensions.buttonX[next.laneIndex] + next.positionOnLane * Dimensions.buttonX[laneIndex])
                / (next.positionOnLane - positionOnLane)            // 始点と終点のx座標を内分
            
            long.startPos = CGPoint(x: posX, y: posY)
            long.startWidth = Dimensions.laneWidth * Note.scale * Note.longScale
        }
        
        let path = CGMutablePath()          // 台形の外周
        path.move   (to: CGPoint(x: long.startPos.x - long.startWidth/2, y: long.startPos.y))   // 始点、台形の左下
        path.addLine(to: CGPoint(x: long.startPos.x + long.startWidth/2, y: long.startPos.y))   // 右下
        path.addLine(to: CGPoint(x: long.endPos.x   + long.endWidth/2,   y: long.endPos.y))     // 右上
        path.addLine(to: CGPoint(x: long.endPos.x   - long.endWidth/2,   y: long.endPos.y))     // 左上
        path.closeSubpath()
        longImages.long.path = path     // pathを変更(longImage.longの更新完了)
        
        // longImages.circleを更新
        if position.y <= Dimensions.judgeLineY || isJudged {        // 始点ノーツが判定線を通過した後か、判定された後
            // 理想軌道の判定線上に緑円を描く
            // 楕円の縦幅を計算
            let lSquare = pow(Dimensions.horizontalDistance, 2) + pow(Dimensions.frameMidX - long.startPos.x, 2)
            let denomOfAtan = lSquare + pow(Dimensions.verticalDistance, 2) - pow(Note.scale * Dimensions.laneWidth / 2, 2)
            guard 0 < denomOfAtan else {
                return
            }
            let deltaY = Dimensions.R * atan(Note.scale * Dimensions.laneWidth * Dimensions.verticalDistance / denomOfAtan)
            
            longImages.circle.yScale = deltaY / Note.initialSize
            longImages.circle.xScale = Dimensions.laneWidth * Note.scale / Note.initialSize     // 横幅は不変。できれば初期値で指定したい。レーン幅に対しノーツサイズを一定にすれば可能
            longImages.circle.position = long.startPos
            longImages.circle.zRotation = atan((Dimensions.frameMidX - long.startPos.x) / (Dimensions.horizontalDistance * 8))
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

/// ロング通過位置判定ノーツ。ロング中、このノーツが通過する位置に指を置かなければならない。
/// 初期状態ではisJudgeableがfalseであり、判定されない。先行するTapStartまたはMiddle判定後に判定可能になる。
/// GameScene.update呼び出し時にparfect時間ならば判定する。
/// parfect時間が来る前(before)、touchesMoved,touchesEnded関数呼出し時にレーンから外れた場合はその場で判定を行う。
/// 上記のいずれの判定もされず残った場合、miss確定時間が来る前(after)にtouchesMoved,touchesEndedが呼び出され、指がレーンに入った場合はその時間で判定を行う。
class Middle: Note {
    
    var next = Note()                                               // 次のノーツ（仮のインスタンス）
    var longImages = (long: SKShapeNode(), circle: SKShapeNode())   // このノーツを始点とする緑太線の画像と、判定線上に残る緑楕円(将来的にはimageに格納？)
    let appearTime: TimeInterval                                    // 演奏開始から水平線を超えるまでの時間。これ以降にposの計算&更新を行う。
    override var position: CGPoint {                                // positionを左端ではなく線の中点にするためオーバーライド
        get {
            return CGPoint(x: image.position.x + size / 2, y: image.position.y)
        }
        set {
            image.position = CGPoint(x: newValue.x - size / 2, y: newValue.y)
        }
    }
    
    init(noteMaterial: NoteMaterial, speed: CGFloat, appearTime: TimeInterval) {
        self.appearTime = appearTime
        super.init(beatPos: noteMaterial.beat, laneIndex: noteMaterial.laneIndex, speed: speed)

        self.isJudgeable = false
        
        // imageのインスタンス(緑線分)を作成
        var points = [
            CGPoint(x: 0.0, y: 0.0),
            CGPoint(x: Note.initialSize, y: 0.0)
        ]
        self.image = SKShapeNode(points: &points, count: points.count)
        image.lineWidth = 5.0
        image.strokeColor = UIColor.green
        image.isHidden = true   // 初期状態では隠しておく
        
        // longImagesのインスタンスを作成
        self.longImages = (SKShapeNode(path: CGMutablePath()), SKShapeNode(circleOfRadius: Note.initialSize / 2))
        longImages.long.fillColor = UIColor.green
        longImages.long.alpha = 0.8
        longImages.long.zPosition = -1
        longImages.long.isHidden = true
        longImages.circle.isHidden = true
    }
    
    deinit {
        self.longImages.long.removeFromParent()
        self.longImages.circle.removeFromParent()
    }
    
    
    override func update(_ passedTime: TimeInterval) {
        // 水平線より下ならば
        if passedTime > appearTime {
            next.update(passedTime) // 後続ノーツを先にupdate
        }
        
        // 通過後のノーツはreturn
        guard !(isJudged && image.isHidden && longImages.circle.isHidden && longImages.long.isHidden) else {
                return
        }
        
        super.update(passedTime)
        
        // x座標とy座標を計算しpositionを変更
        setPos()
        
        // スケールを変更
        setScale()
        
        /* longImage.longを更新 */
        
        let long: (startPos: CGPoint, endPos: CGPoint, startWidth: CGFloat, endWidth: CGFloat)  // 部分ロングノーツの(始点中心座標, 終点中心座標, 始点幅, 終点幅)
        
        // 終点の情報を代入
        if next.position.y < Dimensions.horizonY {      // 終点ノーツが描画域内にあるとき
            long.endPos = next.position
            long.endWidth = next.size * Note.longScale
        } else {                                        // 終点ノーツが描画域より奥にあるとき
            let posY = Dimensions.horizonY
            let posXOnHorizon     = Dimensions.horizonLeftX + Dimensions.laneWidthOnHorizon * CGFloat(Double(laneIndex) + 1/2)
            let posXOnHorizonNext = Dimensions.horizonLeftX + Dimensions.laneWidthOnHorizon * CGFloat(Double(next.laneIndex) + 1/2)
            let posX = ((Dimensions.laneLength - positionOnLane) * posXOnHorizonNext + (next.positionOnLane - Dimensions.laneLength) * posXOnHorizon)
                / (next.positionOnLane - positionOnLane)            // 始点と終点のx座標を内分
            
            long.endPos = CGPoint(x: posX, y: posY)
            long.endWidth = Dimensions.laneWidthOnHorizon * Note.scale * Note.longScale
        }
        // 始点の情報を代入
        if position.y > Dimensions.judgeLineY {
            if !isJudged {
                // ノーツがレーンの半ばにある時
                long.startPos = position
                long.startWidth = size * Note.longScale
            } else {
                // レーン通過前に判定された時
                long.startPos = CGPoint(x: Dimensions.buttonX[laneIndex], y: Dimensions.judgeLineY)
                long.startWidth = Dimensions.laneWidth * Note.scale * Note.longScale
            }
        } else {
            // ノーツがレーンを通過した時
            let posY = Dimensions.judgeLineY
            let posX = (-positionOnLane * Dimensions.buttonX[next.laneIndex] + next.positionOnLane * Dimensions.buttonX[laneIndex])
                / (next.positionOnLane - positionOnLane)            // 始点と終点のx座標を内分
            
            long.startPos = CGPoint(x: posX, y: posY)
            long.startWidth = Dimensions.laneWidth * Note.scale * Note.longScale
        }
        
        let path = CGMutablePath()      // 台形の外周
        path.move   (to: CGPoint(x: long.startPos.x - long.startWidth/2, y: long.startPos.y))   // 始点、台形の左下
        path.addLine(to: CGPoint(x: long.startPos.x + long.startWidth/2, y: long.startPos.y))   // 右下
        path.addLine(to: CGPoint(x: long.endPos.x   + long.endWidth/2,   y: long.endPos.y))     // 右上
        path.addLine(to: CGPoint(x: long.endPos.x   - long.endWidth/2,   y: long.endPos.y))     // 左上
        path.closeSubpath()
        longImages.long.path = path     // pathを変更(longImage.longの更新完了)
        
        // longImages.circleを更新
        if position.y <= Dimensions.judgeLineY || isJudged {        // 始点ノーツが判定線を通過した後か、判定された後
            // 理想軌道の判定線上に緑円を描く
            // 楕円の縦幅を計算
            let lSquare = pow(Dimensions.horizontalDistance, 2) + pow(Dimensions.frameMidX - long.startPos.x, 2)
            let denomOfAtan = lSquare + pow(Dimensions.verticalDistance, 2) - pow(Note.scale * Dimensions.laneWidth / 2, 2)
            guard 0 < denomOfAtan else {
                return
            }
            let deltaY = Dimensions.R * atan(Note.scale * Dimensions.laneWidth * Dimensions.verticalDistance / denomOfAtan)
            
            longImages.circle.yScale = deltaY / Note.initialSize
            longImages.circle.xScale = Dimensions.laneWidth * Note.scale / Note.initialSize     // 横幅は不変。できれば初期値で指定したい。レーン幅に対しノーツサイズを一定にすれば可能
            longImages.circle.position = long.startPos
            longImages.circle.zRotation = atan((Dimensions.frameMidX - long.startPos.x) / (Dimensions.horizontalDistance * 8))
        }
        
        
        // isHiddenを更新
        if position.y >= Dimensions.horizonY || position.y < Dimensions.judgeLineY || isJudged {    // 水平線より上、判定済みのものは隠す。判定線超えたら引き継ぐ
            image.isHidden = true
        } else {
            image.isHidden = false
        }
        if position.y >= Dimensions.horizonY || next.position.y < Dimensions.judgeLineY || next.isJudged {
            longImages.long.isHidden = true
        } else {
            longImages.long.isHidden = false
        }
        if (position.y >= Dimensions.judgeLineY) || next.position.y < Dimensions.judgeLineY || next.isJudged {
            longImages.circle.isHidden = true
        } else {
            longImages.circle.isHidden = false
        }
    }
}

/// ロング離しノーツ。
/// 初期状態ではisJudgeableがfalseであり、判定されない。先行するTapStartまたはMiddle判定後に判定可能になる。
/// touchesEnded呼び出し時に判定を行う。
class TapEnd: Note {
    
//    unowned var start = Note()  // 循環参照防止の為unowned参照にする
    let isLarge: Bool           // 大ノーツかどうか
    
    init(noteMaterial: NoteMaterial, speed: CGFloat) {
        self.isLarge = noteMaterial.isLarge
        super.init(beatPos: noteMaterial.beat, laneIndex: noteMaterial.laneIndex, speed: speed)

        self.isJudgeable = false
        
        // imageのインスタンス(緑円or黄円)を作成
        image = SKShapeNode(circleOfRadius: Note.initialSize / 2)
        image.fillColor = isLarge ? UIColor.yellow : UIColor.green
        image.isHidden = true   // 初期状態では隠しておく
    }
    
    override func update(_ passedTime: TimeInterval) {
        // update不要なときはreturn
        guard !(image.isHidden && isJudged && positionOnLane < 0) else {      // 通過後のノーツはreturn
            return
        }
        
        super.update(passedTime)
        
        // x座標とy座標を計算しpositionを変更
        setPos()
        
        // 縦と横の大きさを計算し、imageのスケールを変更
        setScale()
        
        // ノーツが視点を向くように
        let d = Dimensions.frameMidX - CGFloat(1.5 + Double(laneIndex)) * Dimensions.laneWidth  // 判定線中央から測ったx座標
        image.zRotation = atan(d / (positionOnLane + Dimensions.horizontalDistance * 8))
        
        // image.isHiddenを更新
        if position.y > Dimensions.horizonY || isJudged {       // 水平線より上、判定済みのものは隠す
            image.isHidden = true
        } else {
            image.isHidden = false
        }
    }
}

/// ロングフリック離しノーツ。
/// 初期状態ではisJudgeableがfalseであり、判定されない。先行するTapStartまたはMiddle判定後に判定可能になる。
/// 原則としてtouchesMovedが呼び出されたときに判定する。
/// 呼び出し時にまだparfectの時間でない場合(before)について、後にparfect判定を行うかもしれないので、時間とUItouch情報を該当LaneインスタンスのstoredFlickJudgeに、レーン情報を該当GSTouchインスタンスのstoredFlickJudgeLaneIndexに格納し、後にこの情報をもとにGameSceneTouchesファイル内に記述されているGameScene.storedFlickJudge関数にて判定を行う。この呼出は情報が残っているときにのみ行われ、該当ノーツの判定後に各情報格納場所にnilが入る。storedFlickJudgeの呼び出しタイミングはtouchesMoved呼び出し時にレーンから指が外れた時、touchesEnded呼び出し時、これ以上待ってもより良い判定が来なくなる時（ノーツの正確なタイミングの時間についてtimeLag予定時間(>0)と対象な時間）である。
class FlickEnd: Note {
    
//    unowned var start = Note()
    let direction: FlickDirection

    init(noteMaterial: NoteMaterial, speed: CGFloat, direction: FlickDirection) {
        self.direction = direction
        super.init(beatPos: noteMaterial.beat, laneIndex: noteMaterial.laneIndex, speed: speed)
        
        self.isJudgeable = false
        
        
        switch direction {
        case .any:
            // imageのインスタンス(マゼンタ三角形)を作成
            let length = Note.initialSize / 2   // 三角形一辺の長さの半分
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
            
        case .right:
            let length = Note.initialSize / 2
            var points = [
                CGPoint(x: 0.0,     y: 0.0),
                CGPoint(x: -length, y: -length),
                CGPoint(x: length,  y: 0.0),
                CGPoint(x: -length, y: length),
                CGPoint(x: 0.0,     y: 0.0)
            ]
            self.image = SKShapeNode(points: &points, count: points.count)
            image.lineWidth = 3.0
            image.fillColor = UIColor.cyan
            
        case .left:
            let length = Note.initialSize / 2
            var points = [
                CGPoint(x: 0.0,     y: 0.0),
                CGPoint(x: length,  y: -length),
                CGPoint(x: -length, y: 0.0),
                CGPoint(x: length,  y: length),
                CGPoint(x: 0.0,     y: 0.0)
            ]
            self.image = SKShapeNode(points: &points, count: points.count)
            image.lineWidth = 3.0
            image.fillColor = UIColor.purple
        }
        image.isHidden = true   // 初期状態では隠しておく
    }
    
    override func update(_ passedTime: TimeInterval) {
        // update不要なときはreturn
        guard !(image.isHidden && isJudged && positionOnLane < 0) else {      // 通過後のノーツはreturn
            return
        }
        
        super.update(passedTime)
        
        // x座標とy座標を計算しpositionを変更
        setPos()
        
        // 縦と横の大きさを計算し、imageのスケールを変更
        setScale()
        
        // image.isHiddenを更新
        if position.y > Dimensions.horizonY || isJudged {		// 水平線より上、判定済みのものは隠す
            image.isHidden = true
        } else {
            image.isHidden = false
        }
    }
}

/// ノーツ基本クラス
/// TODO: protocolとextensionで抽象クラスっぽくできそう？
class Note {
    
    let beat: Double            // "拍"単位！小節ではない！！！
    let laneIndex: Int          // レーンのインデックス(0始まり)
    var image = SKShapeNode()   // ノーツの画像
    var size: CGFloat = 0       // ノーツの横幅
    var isJudged = false        // 判定済みかどうか
    var isJudgeable = true      // 判定可能かどうか。初期状態では始点系のみtrue
    var position: CGPoint {     // ノーツの画面上の座標
        get {
            return image.position
        }
        set {
            image.position = newValue
        }
    }
    fileprivate var positionOnLane: CGFloat = 0.0           // ノーツのレーン上の座標(判定線を0、奥を正の向きとする)
    fileprivate let speed: CGFloat                          // ノーツスピード。ユーザー設定とBPMによって決定される
    static var scale: CGFloat = 1.0                         // ノーツの幅の倍率(ノーツごとの差異はなく、メモリ領域削減のためstatic)。settingのほか、レーン数を踏まえて値を返す
    static var BPMs: [(bpm: Double, startPos: Double)] = [] // GameSceneのBPMsと同じもの
    fileprivate static let longScale: CGFloat = 0.8         // ノーツの幅に対するlongの幅の倍率
    fileprivate static let initialSize = CGFloat(100)       // ノーツの初期サイズ。ノーツ大きさはscaleで調節するのでどんな値でもよい


    /// Noteのイニシャライザ
    ///
    /// - Parameters:
    ///   - beat: 拍
    ///   - laneIndex: laneのindex
    ///   - speed: 3Dレーン上のノーツ秒速
    init(beatPos beat: Double, laneIndex: Int, speed: CGFloat) {
        self.beat = beat
        self.laneIndex = laneIndex
        self.speed = speed
    }
    init() {
        self.beat = 0
        self.laneIndex = 0
        self.speed = 1350
    }
    
    deinit {
        self.image.removeFromParent()
    }
    

    /// ノーツの表示状態の更新、毎フレーム呼ばれる
    /// 各派生クラスでオーバーライドされる
    ///
    /// - Parameter passedTime: プレイ開始からの経過時間(BGMの経過時間とは異なる)
    func update(_ passedTime: TimeInterval) {
        setPositionOnLane(passedTime)
    }
    
    /// 経過時間から3D空間レーン上のノーツ座標を得る
    private func setPositionOnLane(_ passedTime: TimeInterval) {
        
        var remainingTime: TimeInterval = 0.0   // 判定線所雨に乗る時刻 - 現在時刻
        var i = 0
        while i + 1 < Note.BPMs.count && Note.BPMs[i + 1].startPos < beat {
            remainingTime += (Note.BPMs[i + 1].startPos - Note.BPMs[i].startPos) / (Note.BPMs[i].bpm/60)
            
            i += 1
        }
        remainingTime += (beat - Note.BPMs[i].startPos) / (Note.BPMs[i].bpm/60)
        remainingTime -= passedTime
        
        self.positionOnLane = CGFloat(remainingTime) * speed    // 判定線からの水平距離x
    }
    
    /// ノーツの座標を設定
    fileprivate func setPos() {
        
        /* y座標の計算 */
        // 球面?に投写(現状は円柱の側面(曲面))
        let denomOfAtan = pow(Dimensions.R, 2) + Dimensions.horizontalDistance * positionOnLane     // atanの分母(denominator)
        guard 0 < denomOfAtan else {    // atan内の分母が0になるのを防止
            return
        }
        let posY = Dimensions.R * atan(Dimensions.verticalDistance * positionOnLane / denomOfAtan) + Dimensions.judgeLineY
        
        /* x座標の計算 */
        let b = Dimensions.horizonY - Dimensions.judgeLineY                                     // 水平線から判定線までの2D上の距離
        let c = Dimensions.horizonLeftX - Dimensions.laneWidth - (Dimensions.laneWidth - Dimensions.laneWidthOnHorizon) * CGFloat(0.5 + Double(laneIndex)) // 水平線上と判定線上でのx座標のずれ
        var posX = Dimensions.laneWidth * 3/2 + CGFloat(laneIndex) * Dimensions.laneWidth       // 判定線上でのx座標
        posX += (posY - Dimensions.judgeLineY) * (c/b)                                          // 判定線から離れている分補正
        
        // 座標を反映
        self.position = CGPoint(x: posX, y: posY)
    }
    
    /// ノーツのスケールを設定
    fileprivate func setScale() {
        // ノーツの横幅を計算
        let grad = (Dimensions.laneWidthOnHorizon - Dimensions.laneWidth) / (Dimensions.horizonY - Dimensions.judgeLineY)  // 傾き
        self.size = Note.scale * (grad * (position.y - Dimensions.horizonY) + Dimensions.laneWidthOnHorizon)
        
        // ノーツの横幅と縦幅をscaleで設定
        if self is Tap || self is TapStart || self is TapEnd {      // 楕円
            let d = Dimensions.frameMidX - CGFloat(1.5 + Double(laneIndex)) * Dimensions.laneWidth  // 判定線中央から測ったx座標
            let lSquare = pow(Dimensions.horizontalDistance + positionOnLane, 2) + pow(d, 2)
            let denomOfAtan = lSquare + pow(Dimensions.verticalDistance, 2) - pow(Note.scale * Dimensions.laneWidth / 2, 2)         // atan内の分母
            guard 0 < denomOfAtan else {    // atan内の分母が0になるのを防止
                return
            }
            let deltaY = Dimensions.R * atan(Note.scale * Dimensions.laneWidth * Dimensions.verticalDistance / denomOfAtan)
            
            image.xScale = size / Note.initialSize
            image.yScale = deltaY / Note.initialSize
        } else {        // 線と三角形
            image.setScale(size / Note.initialSize)
        }
    }
}

// Noteオブジェクトが==演算子を使えるように
extension Note: Equatable {
    public static func ==(lhs: Note, rhs: Note) -> Bool {
        return lhs === rhs
    }
}
