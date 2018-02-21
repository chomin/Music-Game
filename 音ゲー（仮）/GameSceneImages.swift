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
			var points = [CGPoint(x:self.frame.width*CGFloat(i+1)/9 ,y:self.frame.width/9) ,CGPoint(x:self.frame.width/2 - Dimensions.horizonLength/2 + CGFloat(i)*Dimensions.horizonLength/7 ,y:Dimensions.horizonY)]
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

		
		
		
		var fNotes:[Note] = []  // firstNotes(最終的にロングノーツの始点の集合)
		var lNotes:[Note] = []  // lastNotes(ロングノーツの終点の集合)
		
		fNotes = notes
		// ロングノーツの終点を探索
		for note in notes{
			
			if let start = note as? TapStart {
				var following = start.next
				while(true) {
					if let middle = following as? Middle {
						following = middle.next
					} else {
						lNotes.append(following)
						break
					}
				}
			}
		}
		
		//lnotesをbeatの早い順にソート(してもらう)
		lNotes = lNotes.sorted{$0.beat < $1.beat}

		//同時押し線の描写
		var i = 0
		while(i+1 < fNotes.count){  //iとi+1を見るため...
			if fNotes[i].beat == fNotes[i+1].beat {//まず始点同士
				paintSameLine(i: fNotes[i], j: fNotes[i+1])
				fNotes.removeSubrange(i...i+1)
				continue
			}
			
			i += 1
		}
		
		i=0
		while i+1 < lNotes.count {
			if lNotes[i].beat == lNotes[i+1].beat {//次に終点同士
				paintSameLine(i: lNotes[i], j: lNotes[i+1])
				lNotes.removeSubrange(i...i+1)
				continue
			}
			
			i += 1
		}
		
		
		for j in fNotes{	  //最後に始点と終点
			i=0
			while i < lNotes.count{
				if j.beat == lNotes[i].beat{
					paintSameLine(i: j, j: lNotes[i])
					break
				}else if j.beat < lNotes[i].beat{
					break
				}
				
				i+=1
			}
		}
		
	}

	
	
	
	func paintSameLine(i:Note,j:Note){
		//同時押しラインの描写
		var lPoint = [CGPoint(x:0,y:0), CGPoint(x: CGFloat(j.lane - i.lane) * Dimensions.laneWidth, y :0)]
		let line = SKShapeNode(points: &lPoint, count: lPoint.count)
		line.lineWidth = 3.0
		line.strokeColor = UIColor.white
		line.position.x = i.position.x	//ここでは不要？
		line.zPosition = -1
		self.addChild(line)
		sameLines.append((i,line))
		
	}
	

}
