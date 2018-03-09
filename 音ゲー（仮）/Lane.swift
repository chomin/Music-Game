//
//  Lane.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2018/01/04.
//  Copyright © 2018年 NakaiKohei. All rights reserved.
//

import SpriteKit

protocol FlickJudgeDelegate {   //parfect終了時に保存されているflickJudgeを行う
    func storedFlickJudge(lane: Lane)
}

enum TimeState {
    case miss, bad, good, great, parfect, still, passed
}

enum MiddleObsevationTimeState{
    case front, behind, otherwise
}

class Lane{
    
    //判定時間に関する定数群
    private let parfectHalfRange = 0.05
    private let greatHalfRange = 0.08
    private let goodHalfRange = 0.085
    private let badHalfRange = 0.09
    private let missHalfRange = 0.1
    
    var timeLag :TimeInterval = 0.0
    var isTimeLagSet = false
    var laneNotes:[Note] = []   // 最初に全部格納する！
    var isSetLaneNotes = false
    let laneIndex:Int!
    var fjDelegate:FlickJudgeDelegate!
    
    var isJudgeRange:Bool{
        get{
            guard isTimeLagSet else { return false }
            
            switch self.getTimeState(timeLag: timeLag) {
            case .parfect, .great, .good, .bad, .miss : return true
            default                                   : return false
            }
            
        }
    }
    var isObservingMiddle:MiddleObsevationTimeState {   // middleの判定圏内かどうかを返す
        get{
            guard self.isTimeLagSet,
                  laneNotes.count > 0       else { return .otherwise }
            guard laneNotes.first is Middle else { return .otherwise }
            
            switch timeLag {
            case  parfectHalfRange ..<  missHalfRange    : return .front
            case -missHalfRange    ..< -parfectHalfRange : return .behind
            default                                      : return .otherwise
            }
        }
    }
    
    var isWaitForParfectFlickTime:Bool { //parfectまで待つ時間帯かどうかを返す。（もっといい名前あったら変えて）
        get{
            guard self.isTimeLagSet,
                  laneNotes.count > 0         else { return false }
            guard laneNotes.first is Flick ||
                  laneNotes.first is FlickEnd else { return false }
            
            return timeLag > parfectHalfRange &&
                   timeLag < missHalfRange
        }
    }
    
    var storedFlickJudge:(time:TimeInterval?, touch: UITouch?)
    
    var timeState:TimeState{    //このインスタンスのtimeLagについてのTimeStateを取得するためのプロパティ
        get{
            guard self.isTimeLagSet else { return .still }
            
            return self.getTimeState(timeLag: timeLag)
        }
    }
    
    
    
    init(laneIndex: Int){
        self.laneIndex = laneIndex
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(_ passedTime: TimeInterval, _ BPMs: [(bpm: Double, startPos: Double)]){
        
        // timeLagの更新
        if isSetLaneNotes{
            
            if laneNotes.count > 0 {
                
                timeLag = -passedTime
                
                for (index,i) in BPMs.enumerated(){
                    if BPMs.count > index+1 &&
                        laneNotes[0].beat > BPMs[index+1].startPos{
                        
                        timeLag += (BPMs[index+1].startPos - i.startPos)*60/i.bpm
                        
                    }else{
                        
                        timeLag += (laneNotes[0].beat - i.startPos)*60/i.bpm
                        break
                    }
                }
                
                //storedFlickJudgeの判定
                if timeLag < -parfectHalfRange &&
                    self.storedFlickJudge != (nil, nil) {
                    self.fjDelegate?.storedFlickJudge(lane: self)
                }
            }
            
            self.isTimeLagSet = true    // パース前はtimeLagは更新されないので(このレーンが使われない場合でも)通知する必要あり.
        }
    }
    
    func getTimeState(timeLag:TimeInterval) -> TimeState{
        guard self.isTimeLagSet else {
            print("timeLagが不正です")
            return .still
        }
        
        switch abs(timeLag){
        case 0                ..< parfectHalfRange  : return .parfect
        case parfectHalfRange ..< greatHalfRange    : return .great
        case greatHalfRange   ..< goodHalfRange     : return .good
        case goodHalfRange    ..< badHalfRange      : return .bad
        case badHalfRange     ..< missHalfRange     : return .miss
        default                                     : if timeLag > 0 { return .still  }
                                                      else           { return .passed }
        }
    }
}
