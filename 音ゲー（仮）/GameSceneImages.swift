//
//  Images.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//
//（9/11の成果が残っている？）

import SpriteKit

extension GameScene{
	func setImages(){
		
		//レーンの境目の線
		for i in 0...7{
			var points = [CGPoint(x:self.frame.width*CGFloat(i+1)/9 ,y:self.frame.width/9) ,CGPoint(x:self.frame.width/2 - horizon/2 + CGFloat(i)*horizon/7 ,y:horizonY)]
			let line = SKShapeNode(points: &points, count: points.count)
			
			line.lineWidth = 1.0
			line.alpha = 0.9
			
			self.addChild(line)

		}
		
		//判定ラインの描写
		var jlPoint = [CGPoint(x:0.0 ,y:0.0) ,CGPoint(x:self.frame.width/9*7 ,y:0.0)]
		judgeLine = SKShapeNode(points: &jlPoint, count: jlPoint.count)
		judgeLine.lineWidth = 3.0
		judgeLine.strokeColor = UIColor.white
		judgeLine.position = CGPoint(x:self.frame.width/9, y:self.frame.width/9)
		self.addChild(judgeLine)

		for i in notes{   //始点を描く

			 i.image = paintNote(i: i)	//描き、格納
			
			var note:Note? = i
			
			while note?.next != nil {  //つながっている先のノーツを描き、格納→つなげる(noteが始点)
				
				note?.next?.image = paintNote(i: (note?.next)!)
				
//				let nextIndex = GameScene.notes.index(where: {$0 === value.next!})
//				
//				let path = CGMutablePath()
//				let path2 = CGMutablePath()//剛体用（重なると変になるため）
//				
//				//まず、始点&終点ノーツが円か線かで中心座標が異なるため場合分け
//				var startNotepos:CGPoint =  (note?.image.position)! //中心座標
//				if note?.type == .middle{//線だけずらす
//					startNotepos.x += (self.frame.width/18)
//				}
//				var endNotepos:CGPoint =  (note?.next?.image?.position)! //中心座標
//				if note?.next!.type == .middle{//線だけずらす
//					endNotepos.x += (self.frame.width/18)
//				}
//				
//				
//				path.move(to: CGPoint(x:startNotepos.x-self.frame.width/22, y:startNotepos.y))  //始点
//				path.addLine(to: CGPoint(x:startNotepos.x+self.frame.width/22, y:startNotepos.y))
//				path.addLine(to: CGPoint(x:endNotepos.x+self.frame.width/22, y:endNotepos.y))
//				path.addLine(to: CGPoint(x:endNotepos.x-self.frame.width/22, y:endNotepos.y))
//				path.closeSubpath()
//				
//				path2.move(to: CGPoint(x:startNotepos.x-self.frame.width/22, y:startNotepos.y+speed/70*5))  //始点
//				path2.addLine(to: CGPoint(x:startNotepos.x+self.frame.width/22, y:startNotepos.y+speed/70*5))
//				path2.addLine(to: CGPoint(x:endNotepos.x+self.frame.width/22, y:endNotepos.y-speed/70*5))
//				path2.addLine(to: CGPoint(x:endNotepos.x-self.frame.width/22, y:endNotepos.y-speed/70*5))
//				path2.closeSubpath()
//	
//				let tmplong = SKShapeNode(path:path)
//				
//				tmplong.fillColor = UIColor.green
//				
//				tmplong.alpha = 0.8
//				tmplong.zPosition = -1
//				
//				tmplong.physicsBody = SKPhysicsBody(polygonFrom :path2)	  //物理演算してしまうが、固定してるから動かない。逆に物理演算しないと連動して動かない！
//				
//				self.addChild(tmplong)
//				longImages.append(((note?.next)!,tmplong))
//				
//				
//				//終点ノーツに物理体を追加
//				note?.next?.image?.physicsBody = SKPhysicsBody(circleOfRadius: self.frame.width/300)  //とりあえず円の剛体
//				note?.next?.image?.physicsBody!.isDynamic = false	  //物理演算させない
//				
//				
//				// ２つのNodeを繋げるジョイントを生成.
//				let Joint = SKPhysicsJointFixed.joint(
//					withBodyA: (tmplong.physicsBody)!,            // BodyA.
//					bodyB: (note?.next?.image?.physicsBody)!,    // BodyB.
//					anchor: endNotepos)      // 繋がる点.
//				self.physicsWorld.add(Joint)

	
				note = note!.next	  //進める
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
			
			// 始点から終点までの４点を指定.
			var points = [CGPoint(x:length, y:0),
			              CGPoint(x:-length, y:0),
			              CGPoint(x: 0.0, y: length),
			              CGPoint(x:length, y:0)]
			
			note = SKShapeNode(points: &points, count: points.count)
			note.lineWidth = 3.0
			
			note.fillColor = UIColor.magenta
			
		}else if i.type == .middle{//線(notesに入らないから不要)
			var points = [CGPoint(x:0.0 ,y:0.0) ,CGPoint(x:self.frame.width/9 ,y:0.0)]
			note = SKShapeNode(points: &points, count: points.count)
			
			note.lineWidth = 5.0
			
			note.strokeColor = UIColor.green
			
		}else if i.type == .tapEnd || i.next != nil{//緑楕円(middleもnextがnilにならないことに注意！)
			note = SKShapeNode(ellipseOf: CGSize(width:self.frame.width/9, height:self.frame.width/18))
			note.fillColor = UIColor.green
		}else{//白楕円
			note = SKShapeNode(ellipseOf: CGSize(width:self.frame.width/9, height:self.frame.width/18))
			note.fillColor = UIColor.white
		}
		
		
		
		
		//位置(ロングノーツに必要なため、ここでyも設定(ただし画面外))
		var xpos = (self.frame.width/6)+(self.frame.width/9)*CGFloat(i.lane-1)
		if i.type == .middle{ //線だけずらす(開始点がposition)
			xpos -= (self.frame.width/18)
		}
		
		var ypos =  self.frame.width/9
		ypos += (CGFloat(60*i.pos/GameScene.bpm))*CGFloat(speed)
		
		note.position = CGPoint(x:xpos-1000 ,y:ypos-100000)
		print(note.position)
		
		note.isHidden = true	//初期状態では隠しておく
		
		self.addChild(note)
		
		return note

	}
	

	
	func paintSameLine(i:Note,j:Note){
		//同時押しラインの描写
		var lPoint = [CGPoint(x:0,y:0) ,CGPoint(x:j.image.position.x-i.image.position.x, y:0)]
		let line = SKShapeNode(points: &lPoint, count: lPoint.count)
		line.lineWidth = 3.0
		line.strokeColor = UIColor.white
		line.position.x = i.image.position.x
		line.zPosition = -1
		self.addChild(line)
		sameLines.append((i,line))

	}
}


