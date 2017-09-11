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
		
		//判定ラインの描写
		var jlPoint = [CGPoint(x:0.0 ,y:0.0) ,CGPoint(x:self.frame.width/9*7 ,y:0.0)]
		judgeLine = SKShapeNode(points: &jlPoint, count: jlPoint.count)
		judgeLine.lineWidth = 3.0
		judgeLine.strokeColor = UIColor.white
		judgeLine.position = CGPoint(x:self.frame.width/9, y:self.frame.width/9)
		self.addChild(judgeLine)

		for i in GameScene.notes{   //始点を描く

			 i.image = paintNote(i: i)	//描き、格納
			
			var note:Note? = i
			
			while note?.next != nil {  //つながっている先のノーツを描き、格納→つなげる(noteが始点)
				
				note?.next?.image = paintNote(i: (note?.next)!)
				
//				let nextIndex = GameScene.notes.index(where: {$0 === value.next!})
				
				
				
				let path = CGMutablePath()
				let path2 = CGMutablePath()//剛体用（重なると変になるため）
				
				//まず、始点&終点ノーツが円か線かで中心座標が異なるため場合分け
				var startNotepos:CGPoint =  (note?.image.position)! //中心座標
				if note?.type == .Middle{//線だけずらす
					startNotepos.x += (self.frame.width/18)
				}
				var endNotepos:CGPoint =  (note?.next?.image?.position)! //中心座標
				if note?.next!.type == .Middle{//線だけずらす
					endNotepos.x += (self.frame.width/18)
				}
				
				
				path.move(to: CGPoint(x:startNotepos.x-self.frame.width/22, y:startNotepos.y))  //始点
				path.addLine(to: CGPoint(x:startNotepos.x+self.frame.width/22, y:startNotepos.y))
				path.addLine(to: CGPoint(x:endNotepos.x+self.frame.width/22, y:endNotepos.y))
				path.addLine(to: CGPoint(x:endNotepos.x-self.frame.width/22, y:endNotepos.y))
				path.closeSubpath()
				
				path2.move(to: CGPoint(x:startNotepos.x-self.frame.width/22, y:startNotepos.y+40))  //始点
				path2.addLine(to: CGPoint(x:startNotepos.x+self.frame.width/22, y:startNotepos.y+40))
				path2.addLine(to: CGPoint(x:endNotepos.x+self.frame.width/22, y:endNotepos.y-40))
				path2.addLine(to: CGPoint(x:endNotepos.x-self.frame.width/22, y:endNotepos.y-40))
				path2.closeSubpath()
	
				let tmplong = SKShapeNode(path:path)
				
				tmplong.fillColor = UIColor.green
				
				tmplong.alpha = 0.8
				tmplong.zPosition = -1
				
				tmplong.physicsBody = SKPhysicsBody(polygonFrom :path2)	  //物理演算してしまうが、固定してるから動かない。逆に物理演算しないと連動して動かない！
				//				tmplong.physicsBody?.isDynamic=false
				
				
				self.addChild(tmplong)
				
				
				//終点ノーツに物理体を追加
				note?.next?.image?.physicsBody = SKPhysicsBody(circleOfRadius: self.frame.width/18)  //とりあえず円の剛体
				note?.next?.image?.physicsBody!.isDynamic = false	  //物理演算させない
				
				
				// ２つのNodeを繋げるジョイントを生成.
				let Joint = SKPhysicsJointFixed.joint(
					withBodyA: (tmplong.physicsBody)!,            // BodyA.
					bodyB: (note?.next?.image?.physicsBody)!,    // BodyB.
					anchor: endNotepos)      // 繋がる点.
				self.physicsWorld.add(Joint)

				
				
				note = note!.next	  //進める
			}
			
		}
		
//		//ロングノーツをつなげる（つなげる先のノーツの位置が決まっている必要があるためこの位置）
//		for (index,value) in GameScene.notes.enumerated(){
//			if value.next != nil{
//				
//				
//			}
//		}


	}
	
	func paintNote(i:Note) -> SKShapeNode{
		
		var note:SKShapeNode
		
		//形と色
		if i.type == .Flick || i.type == .FlickEnd{//三角形(endはnotesに入らないから不要)
			let length = self.frame.width/18 //一辺の長さの半分
			
			// 始点から終点までの４点を指定.
			var points = [CGPoint(x:length, y:0),
			              CGPoint(x:-length, y:0),
			              CGPoint(x: 0.0, y: length),
			              CGPoint(x:length, y:0)]
			
			note = SKShapeNode(points: &points, count: points.count)
			
			note.fillColor = UIColor.magenta
			
		}else if i.type == .Middle{//線(notesに入らないから不要)
			var points = [CGPoint(x:0.0 ,y:0.0) ,CGPoint(x:self.frame.width/9 ,y:0.0)]
			note = SKShapeNode(points: &points, count: points.count)
			
			note.lineWidth = 5.0
			
			note.strokeColor = UIColor.green
			
		}else if i.type == .TapEnd || i.next != nil{//緑円(middleもnextがnilにならないことに注意！)(notesに入らないから不要)
			note = SKShapeNode(circleOfRadius: self.frame.width/18)
			note.fillColor = UIColor.green
		}else{//白円
			note = SKShapeNode(circleOfRadius: self.frame.width/18)
			note.fillColor = UIColor.white
		}
		
		
		//位置(ロングノーツに必要なため、ここでyも設定)
		var xpos = (self.frame.width/6)+(self.frame.width/9)*CGFloat(i.lane-1)
		if i.type == .Middle{ //線だけずらす(開始点がposition)
			xpos -= (self.frame.width/18)
		}
		
		var ypos =  self.frame.width/9
		ypos += (CGFloat(240*i.pos/GameScene.BPM))*CGFloat(speed)
		
		note.position = CGPoint(x:xpos ,y:ypos)
		
		
		self.addChild(note)
		
		return note

	}
	
	func setYPos (note:Note ,currentTime:TimeInterval)  {
		var ypos =  self.frame.width/9
		ypos += (CGFloat(240*note.pos/GameScene.BPM)-CGFloat(currentTime - start))*CGFloat(speed)
		note.image?.position.y = ypos
	}
}
