//
//  Images.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//

import SpriteKit

extension GameScene{
	func setImages(){
		var jlPoint = [CGPoint(x:0.0 ,y:0.0) ,CGPoint(x:self.frame.width/9*7 ,y:0.0)]
		judgeLine = SKShapeNode(points: &jlPoint, count: jlPoint.count)
		judgeLine.lineWidth = 3.0
		judgeLine.strokeColor = UIColor.white
		judgeLine.position = CGPoint(x:self.frame.width/9, y:self.frame.width/9)
		self.addChild(judgeLine)

		
		
		for i in GameScene.notes{
			var note:SKShapeNode
			
			//形と色
			if i.type == .Flick || i.type == .FlickEnd{//三角形
				let length = self.frame.width/18 //一辺の長さの半分
				
				// 始点から終点までの４点を指定.
				var points = [CGPoint(x:length, y:0),
				              CGPoint(x:-length, y:0),
				              CGPoint(x: 0.0, y: length),
				              CGPoint(x:length, y:0)]
				
				note = SKShapeNode(points: &points, count: points.count)
				
				note.fillColor = UIColor.magenta
				
			}else if i.type == .Middle{//線
				var points = [CGPoint(x:0.0 ,y:0.0) ,CGPoint(x:self.frame.width/9 ,y:0.0)]
				note = SKShapeNode(points: &points, count: points.count)
				
				note.lineWidth = 5.0
				
				note.strokeColor = UIColor.green
				
			}else if i.type == .TapEnd || i.next != nil{//緑円(middleもnextがnilにならないことに注意！)
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
			noteImage.append(note)
			
		}
		
		//ロングノーツをつなげる（つなげる先のノーツの位置が決まっている必要があるためこの位置）
		for (index,value) in GameScene.notes.enumerated(){
			if value.next != nil{
				let nextIndex = GameScene.notes.index(where: {$0 === value.next!})
				
				let path = CGMutablePath()
				let path2 = CGMutablePath()//剛体用（重なると変になるため）
				
				//まず、始点&終点ノーツが円か線かで中心座標が異なるため場合分け
				var startNotepos:CGPoint =  noteImage[index].position //中心座標
				if value.type == .Middle{//線だけずらす
					startNotepos.x += (self.frame.width/18)
				}
				var endNotepos:CGPoint =  noteImage[nextIndex!].position //中心座標
				if value.next!.type == .Middle{//線だけずらす
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
				noteImage[nextIndex!].physicsBody = SKPhysicsBody(circleOfRadius: self.frame.width/18)  //とりあえず円の剛体
				noteImage[nextIndex!].physicsBody!.isDynamic = false	  //物理演算させない
				
				
				// ２つのNodeを繋げるジョイントを生成.
				let Joint = SKPhysicsJointFixed.joint(
					withBodyA: (tmplong.physicsBody)!,            // BodyA.
					bodyB: (noteImage[nextIndex!].physicsBody)!,    // BodyB.
					anchor: endNotepos)      // 繋がる点.
				self.physicsWorld.add(Joint)

				
			}
		}
//		
//		//以下は確認用
//		let length = self.frame.width/20
//		
//		// 始点から終点までの４点を指定.
//		var points = [CGPoint(x:length, y:-length / 2.0),
//		              CGPoint(x:-length, y:-length / 2.0),
//		              CGPoint(x: 0.0, y: length),
//		              CGPoint(x:length, y:-length / 2.0)]
//		
//		triangle = SKShapeNode(points: &points, count: points.count)
//		triangle?.fillColor = UIColor.magenta
//		triangle?.position = CGPoint(x:self.frame.midX-self.frame.width/9 ,y:self.frame.midY)
//		self.addChild(triangle!)
//
//		
//		points = [CGPoint(x:0.0 ,y:0.0) ,CGPoint(x:self.frame.width/10 ,y:0.0)]
//		line = SKShapeNode(points: &points, count: points.count)
//		
//		line?.lineWidth = 5.0
//		line?.strokeColor = UIColor.green
//		line?.position = CGPoint(x:self.frame.midX+self.frame.width/9-length ,y:self.frame.midY+self.frame.width/9*2)
//		self.addChild(line!)
//
//		circle = SKShapeNode(circleOfRadius: self.frame.width/20)
//		circle?.fillColor = UIColor.white
//		circle?.position = CGPoint(x:self.frame.midX ,y:self.frame.midY)
//		self.addChild(circle!)
//		
//		gcircle = SKShapeNode(circleOfRadius: self.frame.width/20)
//		gcircle?.fillColor = UIColor.green
//		gcircle?.position = CGPoint(x:self.frame.midX+self.frame.width/9*2 ,y:self.frame.midY)
//		
//		gcircle?.physicsBody = SKPhysicsBody(circleOfRadius: self.frame.width/20)   //剛体を作成
//		gcircle?.physicsBody?.isDynamic = false //物理演算させない
//		self.addChild(gcircle!)
//		
//		//太すぎるからlineではだめ？
//		let path = CGMutablePath()
//		
//		path.move(to: CGPoint(x:(gcircle?.position.x)!-self.frame.width/22, y:(gcircle?.position.y)!))  //始点
//		path.addLine(to: CGPoint(x:(gcircle?.position.x)!+self.frame.width/22, y:(gcircle?.position.y)!))
//		path.addLine(to: CGPoint(x:(line?.position.x)!+length+self.frame.width/22, y:(line?.position.y)!))
//		path.addLine(to: CGPoint(x:(line?.position.x)!+length-self.frame.width/22, y:(line?.position.y)!))
//		path.closeSubpath()
//		
//		
//		long = SKShapeNode(path:path)
//		
//		long?.fillColor = UIColor.green
//
//		long?.alpha = 0.8
//		long?.zPosition = -1
//		
//		long?.physicsBody = SKPhysicsBody(polygonFrom :path)	  //物理演算してしまうが、固定してるから動かない。逆に物理演算しないと連動して動かない！
//		
//		self.addChild(long!)
//		
//		
//		// ２つのNodeを繋げるジョイントを生成.
//		let Joint = SKPhysicsJointFixed.joint(
//			withBodyA: (gcircle?.physicsBody)!,            // BodyA.
//			bodyB: (long?.physicsBody)!,    // BodyB.
//			anchor: (gcircle?.position)!)      // 繋がる点.
//		self.physicsWorld.add(Joint)


	}
}
