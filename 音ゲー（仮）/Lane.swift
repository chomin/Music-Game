//
//  Lane.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2018/01/04.
//  Copyright © 2018年 NakaiKohei. All rights reserved.
//

import SpriteKit

enum TimeState {
    case miss, bad, good, great, parfect, still, passed
}

enum MiddleObsevationTimeState{
    case front, behind, otherwise
}

class Lane{ 
    var timeLag :TimeInterval = 0.0
    var isTimeLagRenewed = false
    var laneNotes:[Note] = []   // 最初に全部格納する！
    var isSetLaneNotes = false
    let laneIndex:Int!
    
    var isJudgeRange:Bool{
        get{
            guard isTimeLagRenewed else { return false }
            
            switch self.getTimeState(timeLag: timeLag) {
            case .parfect, .great, .good, .bad, .miss : return true
            default                                   : return false
            }
            
        }
    }
    var isObservingMiddle:MiddleObsevationTimeState {   // middleの判定圏内かどうかを返す
        get{
            guard self.isTimeLagRenewed,
                  laneNotes.count > 0       else { return .otherwise }
            guard laneNotes.first is Middle else { return .otherwise }
            
            switch timeLag {
            case  Dimensions.parfectHalfRange ..<  Dimensions.missHalfRange    : return .front
            case -Dimensions.missHalfRange    ..< -Dimensions.parfectHalfRange : return .behind
            default                                                            : return .otherwise
            }
        }
    }
    
    var isObservingFlick:Bool { //フリックの判定を我慢しなければならない時間帯
        get{
            guard self.isTimeLagRenewed,
                  laneNotes.count > 0         else { return false }
            guard laneNotes.first is Flick ||
                  laneNotes.first is FlickEnd else { return false }
            
            return timeLag > Dimensions.parfectHalfRange &&
                   timeLag < Dimensions.missHalfRange
        }
    }
    
    
    var timeState:TimeState{    //このインスタンスのtimeLagについてのtimeStateを取得するためのプロパティ
        get{
            guard self.isTimeLagRenewed else { return .still }
            
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
                    if BPMs.count > index+1 && laneNotes[0].beat > BPMs[index+1].startPos{
                        timeLag += (BPMs[index+1].startPos - i.startPos)*60/i.bpm
                    }else{
                        timeLag += (laneNotes[0].beat - i.startPos)*60/i.bpm
                        break
                    }
                }
            }
            
            self.isTimeLagRenewed = true    // パース前はtimeLagは更新されないので(このレーンが使われない場合でも)通知する必要あり.
        }
    }
    
    func getTimeState(timeLag:TimeInterval) -> TimeState{
        guard self.isTimeLagRenewed else {
            print("timeLagが不正です")
            return .still
        }
        
        switch abs(timeLag){
        case 0                              ..< Dimensions.parfectHalfRange  : return .parfect
        case Dimensions.parfectHalfRange    ..< Dimensions.greatHalfRange    : return .great
        case Dimensions.greatHalfRange      ..< Dimensions.goodHalfRange     : return .good
        case Dimensions.goodHalfRange       ..< Dimensions.badHalfRange      : return .bad
        case Dimensions.badHalfRange        ..< Dimensions.missHalfRange     : return .miss
        default                                                              : if timeLag > 0 { return .still  }
                                                                               else           { return .passed }
        }
    }
}
