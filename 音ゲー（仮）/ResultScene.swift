//
//  ResultScene.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/20.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//

import SpriteKit
class ResultScene: SKScene {
    static var parfect = 0
    static var great = 0
    static var good = 0
    static var bad = 0
    static var miss = 0
    static var combo = 0
    static var maxCombo = 0
    
    var label: SKLabelNode!
    var resultFontSize: CGFloat!
    
    let replayButton = UIButton()
    
    override func didMove(to view: SKView) {
        
        resultFontSize = self.frame.width / 24
        
        label = { () -> SKLabelNode in
            let Label = SKLabelNode(fontNamed: "HiraginoSans-W6")
            
            Label.fontSize = resultFontSize
            Label.horizontalAlignmentMode = .center // 中央寄せ
            Label.position = CGPoint(x: self.frame.midX, y: 0)
            Label.fontColor = SKColor.white
            Label.numberOfLines = 7
            
            
            Label.text =    // swift4からの書き方(改行入りのString)
            """
            parfect:\(ResultScene.parfect)
            great:\(ResultScene.great)
            good:\(ResultScene.good)
            bad:\(ResultScene.bad)
            miss:\(ResultScene.miss)
            
            combo:\(ResultScene.maxCombo)
            """
            
            
            self.addChild(Label)
            return Label
                
        }()
        
        
        //ボタンの設定
        replayButton.addTarget(self, action: #selector(onClickReplayButton(_: )), for: .touchUpInside)
        replayButton.frame = CGRect(x: 0, y: 0, width: self.frame.width/5, height: 50)
        replayButton.backgroundColor = UIColor.red
        replayButton.layer.masksToBounds = true
        replayButton.setTitle("曲選択に戻る", for: UIControlState())
        replayButton.setTitleColor(UIColor.white, for: UIControlState())
        replayButton.setTitle("曲選択に戻る", for: UIControlState.highlighted)
        replayButton.setTitleColor(UIColor.black, for: UIControlState.highlighted)
        replayButton.isHidden = false
        replayButton.layer.cornerRadius = 20.0
        replayButton.layer.position = CGPoint(x: self.frame.midX + self.frame.width/3, y: 50)
        self.view?.addSubview(replayButton)
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    @objc func onClickReplayButton(_ sender: UIButton){
        
        replayButton.isHidden = true
        
        let scene = ChooseMusicScene(size: (view?.bounds.size)!)
        let skView = view as SKView?
        skView?.showsFPS = true
        skView?.showsNodeCount = true
        skView?.ignoresSiblingOrder = true
        scene.scaleMode = .resizeFill
        skView?.presentScene(scene)     // ChooseMusicSceneに移動
        
    }
}
