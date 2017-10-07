//
//  Images.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//


import SpriteKit

extension GameScene{
	// GameScene初期化時に呼ばれる画像設定用関数
	func setImages(){
		
		//レーンの境目の線の描写
		for i in 0...7{
			var points = [CGPoint(x:self.frame.width*CGFloat(i+1)/9 ,y:self.frame.width/9) ,CGPoint(x:self.frame.width/2 - horizon/2 + CGFloat(i)*horizon/7 ,y:horizonY)]
			let line = SKShapeNode(points: &points, count: points.count)
			
			line.lineWidth = 1.0
			line.alpha = 0.3
			
			self.addChild(line)
			
		}
		
		//判定ラインの描写
		var jlPoint = [CGPoint(x:0.0 ,y:0.0) ,CGPoint(x:self.frame.width/9*7 ,y:0.0)]
		judgeLine = SKShapeNode(points: &jlPoint, count: jlPoint.count)
		judgeLine.lineWidth = 3.0
		judgeLine.strokeColor = UIColor.white
		judgeLine.position = CGPoint(x:self.frame.width/9, y:self.frame.width/9)
		self.addChild(judgeLine)
		
		// 全ノートを描画し、各Noteのimageメンバに格納する
		for i in notes{   //始点を描く
			
			i.image = paintNote(i: i)    //描き、格納
			
			var note:Note = i
			while note.next != nil {	//つながっている先のノーツを描き、格納
				note = note.next		// 進める
				
				note.image = paintNote(i: note)
			}
		}
		
		//同時押し線の描写
		var i = 0
		while(i+1 < fNotes.count){  //iとi+1を見るため...
			if fNotes[i].pos == fNotes[i+1].pos {//まず始点同士
				paintSameLine(i: fNotes[i], j: fNotes[i+1])
				fNotes.removeSubrange(i...i+1)
				continue
			}
			
			i += 1
		}
		
		i=0
		while i+1 < lNotes.count {
			if lNotes[i].pos == lNotes[i+1].pos {//次に終点同士
				paintSameLine(i: lNotes[i], j: lNotes[i+1])
				lNotes.removeSubrange(i...i+1)
				continue
			}
			
			i += 1
		}
		
		
		for j in fNotes{	  //最後に始点と終点
			i=0
			while i < lNotes.count{
				if j.pos == lNotes[i].pos{
					paintSameLine(i: j, j: lNotes[i])
					break
				}else if j.pos < lNotes[i].pos{
					break
				}
				
				i+=1
			}
		}
		
	}
	
	func paintNote(i:Note) -> SKShapeNode{
		
		var note:SKShapeNode
		
		//形と色
		if i.type == .flick || i.type == .flickEnd{//三角形(endはnotesに入らないから不要)
			let length = self.frame.width/18 //一辺の長さの半分
			
			// 始点から終点までの４点を指定(2点を一致させ三角形に).
			var points = [CGPoint(x:length, y:0),
			              CGPoint(x:-length, y:0),
			              CGPoint(x: 0.0, y: length),
			              CGPoint(x:length, y:0)]
			
			note = SKShapeNode(points: &points, count: points.count)
			note.lineWidth = 3.0
			
			note.fillColor = UIColor.magenta
			
		}else if i.type == .middle{//線
			var points = [CGPoint(x:0.0 ,y:0.0) ,CGPoint(x:self.frame.width/9 ,y:0.0)]
			note = SKShapeNode(points: &points, count: points.count)
			
			note.lineWidth = 5.0
			
			note.strokeColor = UIColor.green
			
		}else if i.type == .tapEnd || i.next != nil{//緑楕円(middleもnextがnilにならないことに注意！)
			note = SKShapeNode(ellipseOf: CGSize(width:self.frame.width/9, height:self.frame.width/20))
			note.fillColor = UIColor.green
		}else{//白楕円
			note = SKShapeNode(ellipseOf: CGSize(width:self.frame.width/9, height:self.frame.width/20))
			note.fillColor = UIColor.white
		}
		
		//		//視点辺りを向くようにする→間違いでした
		//		let point = CGPoint(x:self.frame.midX ,y:-horizontalDistance)
		//		let cons = SKConstraint.orient(to: point,offset: SKRange(constantValue: CGFloat(1/(M_1_PI*2)))) // 姿勢へのConstraintsを作成.
		//		note.constraints = [cons]   // Constraintsを適用.
		
		
		//位置(同時押し線にに必要なため、設定(画面外))（yは現状不要!）
		var xpos = (self.frame.width/6)+(self.frame.width/9)*CGFloat(i.lane)
		if i.type == .middle{ //線だけずらす(開始点がposition)
			xpos -= (self.frame.width/18)
		}
		
		//		var ypos =  self.frame.width/9
		//		ypos += (CGFloat(60*i.pos/GameScene.bpm))*CGFloat(speed)
		
		note.position = CGPoint(x:xpos-1000 ,y:-1000)	//同時押し線の描写に必要！また、後で位置が変わるが、これを消すと途中で隠れなくなり、左下に表示される
		
		note.isHidden = true	//初期状態では隠しておく
		
		self.addChild(note)
		
		return note
		
	}
	
	func paintSameLine(i:Note,j:Note){
		//同時押しラインの描写
		var lPoint = [CGPoint(x:0,y:0) ,CGPoint(x:j.image.position.x-i.image.position.x, y:0)]	//lane情報からも書ける
		let line = SKShapeNode(points: &lPoint, count: lPoint.count)
		line.lineWidth = 3.0
		line.strokeColor = UIColor.white
		line.position.x = i.image.position.x	//ここでは不要？
		line.zPosition = -1
		self.addChild(line)
		sameLines.append((i,line))
		
	}
	
	
	// firstNoteから始まるロングノーツを表す緑太線を描き、firstNoteにlongImageを格納(毎フレーム呼ばれる)
	func setLong(firstNote:Note ,currentTime:TimeInterval)  {
		
		guard firstNote.next != nil else {
			print("先ノーツが無いので描けません")
			return
		}
		if firstNote.longImages.long != nil{//初で無いなら除去
			self.removeChildren(in: [firstNote.longImages.long!])
//			if firstNote.longImages.circle != nil {//拡大とかで実装したほうがよくね？
//
//				self.removeChildren(in: [firstNote.longImages.circle!])
//			}
		}
		
		
		
		let path = CGMutablePath()      // 台形の外周
		
		
		//まず、始点&終点ノーツが円か線かで中心座標が異なるため場合分け
		var startNotepos:CGPoint = firstNote.image.position //中心座標
		if firstNote.type == .middle{	// 線だけずらす(.positionが左端を指すから)
			startNotepos.x += firstNote.size/2
		}
		var endNotepos:CGPoint =  (firstNote.next?.image?.position)! //中心座標
		if firstNote.next!.type == .middle{	//線だけずらす
			endNotepos.x += firstNote.next.size/2
		}
		
		
		
		var longStartPos = CGPoint(x:0 ,y:self.frame.width/9)
		
		
		if startNotepos.y > self.frame.width/9 && !firstNote.isJudged{//始点ノーツが判定線を通過する前で、判定する前(判定後は位置が更新されないので...)
			path.move(to: CGPoint(x:startNotepos.x-firstNote.size/2/noteScale, y:startNotepos.y))  	//始点、台形の左下
			path.addLine(to: CGPoint(x:startNotepos.x+firstNote.size/2/noteScale, y:startNotepos.y))	//右下
			path.addLine(to: CGPoint(x:endNotepos.x+firstNote.next.size/2/noteScale, y:endNotepos.y))	//右上
			path.addLine(to: CGPoint(x:endNotepos.x-firstNote.next.size/2/noteScale, y:endNotepos.y))	//左上
			path.closeSubpath()
		}else{
			
			//ロングの始点の中心位置を計算
			let nowPos = (currentTime - GameScene.start) * GameScene.bpm/60	//y座標で比をとると、途中で発散するためposから比を求める
			let laneDifference:CGFloat = CGFloat(firstNote.lane - firstNote.next.lane)	//レーン差(符号込み)
			let way1 = laneWidth * laneDifference	//判定線でのレーン差分のx座標の差(符号込み)
			let way2:CGFloat = CGFloat((nowPos - firstNote.pos)/(firstNote.next.pos - firstNote.pos))
			let way3 = (CGFloat(firstNote.lane) + 1.5)*self.frame.width/9	//始点レーンの中心のx座標
			longStartPos.x = way3 - way1 * way2
			
			
			path.move(to: CGPoint(x:longStartPos.x - laneWidth/2, y:longStartPos.y))  //始点
			path.addLine(to: CGPoint(x:longStartPos.x + laneWidth/2, y:longStartPos.y))
			path.addLine(to: CGPoint(x:endNotepos.x+firstNote.next.size/2/noteScale, y:endNotepos.y))
			path.addLine(to: CGPoint(x:endNotepos.x-firstNote.next.size/2/noteScale, y:endNotepos.y))
			
			path.closeSubpath()
			
			if firstNote.isJudged{
				//理想軌道の判定線上に緑円を描く
				//楕円の縦幅を計算
				let R = sqrt(pow(horizontalDistance, 2) + pow(verticalDistance, 2))
				let l = sqrt(pow(horizontalDistance , 2) + pow(self.frame.width/2-longStartPos.x, 2))
				let deltaY = R * atan(noteScale*laneWidth*verticalDistance / (pow(l, 2) + pow(verticalDistance, 2) - pow(noteScale*laneWidth/2, 2)))
				
				if let circle = firstNote.longImages.circle{	//縦幅と座標だけ変更
					circle.yScale = deltaY/(noteScale*laneWidth)
					circle.position = longStartPos
				}else{
					let tmpCircle = SKShapeNode(circleOfRadius:noteScale*laneWidth/2)	//まず円
					tmpCircle.position = longStartPos
					tmpCircle.fillColor = .green
					tmpCircle.yScale = deltaY/(noteScale*laneWidth)	//縦幅だけ変更して楕円にする
					
					firstNote.longImages.circle = tmpCircle
					self.addChild(tmpCircle)
				}
			}
			
		}
		
		let tmplong = SKShapeNode(path:path)
		
		tmplong.fillColor = UIColor.green
		
		tmplong.alpha = 0.8
		tmplong.zPosition = -1
		
		
		self.addChild(tmplong)
		firstNote.longImages.long = tmplong
		//		firstNote.firstLongSize = firstNote.size
		
		//		//		位置の変更
		//		firstNote.longImage.position = firstNote.image.position
		//		firstNote.longImage.position.x -= firstNote.size/2
		//		if firstNote.type == .middle{
		//			firstNote.longImage.position.x += firstNote.size/2
		//		}
		
		
		
	}
}
