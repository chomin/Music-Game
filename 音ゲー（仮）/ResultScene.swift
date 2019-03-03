//
//  ResultScene.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/20.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//

import SpriteKit

struct Result {
    var perfect = 0
    var great = 0
    var good = 0
    var bad = 0
    var miss = 0
    var combo = 0
    var maxCombo = 0
    
    mutating func countUp(judgeType: JudgeType) {
        switch judgeType {
        case .perfect:
            self.perfect += 1
            self.combo += 1
            if self.combo > self.maxCombo {
                self.maxCombo += 1
            }
        case .great:
            self.great += 1
            self.combo += 1
            if self.combo > self.maxCombo {
                self.maxCombo += 1
            }
        case .good:
            self.good += 1
            self.combo = 0
            
        case .bad:
            self.bad += 1
            self.combo = 0

        case .miss:
            self.miss += 1
            self.combo = 0
            
        default:
            break
        }
        
    }
}

class ResultScene: SKScene {
    
    var label: SKLabelNode!
    let labelText: String
    var resultFontSize: CGFloat!
    
    let replayButton = UIButton()
    
    init(size: CGSize, result: Result) {
        self.labelText =  """
        perfect:\(result.perfect)
        great:\(result.great)
        good:\(result.good)
        bad:\(result.bad)
        miss:\(result.miss)
        
        combo:\(result.maxCombo)
        """
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        
        resultFontSize = self.frame.width / 24
        
        label = { () -> SKLabelNode in
            let Label = SKLabelNode(fontNamed: "HiraginoSans-W6")
            
            Label.fontSize = resultFontSize
            Label.horizontalAlignmentMode = .center // 中央寄せ
            Label.position = CGPoint(x: self.frame.midX, y: 0)
            Label.fontColor = SKColor.white
            Label.numberOfLines = 7

            Label.text = labelText
            
            self.addChild(Label)
            return Label
        }()
        
        //ボタンの設定
        replayButton.addTarget(self, action: #selector(onClickReplayButton(_: )), for: .touchUpInside)
        replayButton.frame = CGRect(x: 0, y: 0, width: self.frame.width/5, height: 50)
        replayButton.backgroundColor = UIColor.red
        replayButton.layer.masksToBounds = true
        replayButton.setTitle("曲選択に戻る", for: UIControl.State())
        replayButton.setTitleColor(UIColor.white, for: UIControl.State())
        replayButton.setTitle("曲選択に戻る", for: UIControl.State.highlighted)
        replayButton.setTitleColor(UIColor.black, for: UIControl.State.highlighted)
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
