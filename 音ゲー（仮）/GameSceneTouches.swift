//
//  Buttons.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//

import SpriteKit

extension GameScene: FlickJudgeDelegate {
    
    // タッチ関係
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //        print("began start")
        for i in self.lanes {
            
            guard i.isTimeLagSet else { return }
        }
        
        judgeQueue.sync {
            
            for touch in touches {  // すべてのタッチに対して処理する（同時押しなどもあるため）
                
                var pos = touch.location(in: self.view?.superview)
                
                pos.y = self.frame.height - pos.y   // 上下逆転(画面下からのy座標に変換)
                
                // フリック判定したかを示すBoolを加えてallTouchにタッチ情報を付加
                self.allTouches.append(GSTouch(touch: touch, isJudgeableFlick: true, isJudgeableFlickEnd: false, storedFlickJudgeLaneIndex: nil))
                
                guard pos.y < Dimensions.buttonHeight else {     // 以下、ボタンの判定圏内にあるtouchのみを処理する
                    continue
                }

                
                // 判定対象を選ぶため、押された範囲のレーンから最近ノーツを取得
                var nearbyNotes: [(laneIndex: Int, timelag: TimeInterval, note: Note, distanceToButton: CGFloat)] = []
                for (index, judgeXRange) in Dimensions.judgeXRanges.enumerated() {
                    
                    if judgeXRange.contains(pos.x) {    // ボタンの範囲
                        
                        if (self.lanes[index].timeState == .still) ||
                            (self.lanes[index].timeState == .passed) { continue }
                        
                        if self.lanes[index].laneNotes.count == 0 { continue }
                        
                        let note = self.lanes[index].laneNotes[0]
                        let distanceToButton = sqrt(pow(pos.x - Dimensions.buttonX[index], 2) + pow(pos.y - Dimensions.judgeLineY, 2))
                        
                        if self.lanes[index].middleObservationTimeState == .after {    // middleの判定圏内（後）
                            nearbyNotes.append((laneIndex: index, timelag: self.lanes[index].timeLag, note: note, distanceToButton: distanceToButton))
                            continue
                        }
                        
                        
                        if (note is Tap) || (note is Flick) || (note is TapStart) { // flickが最近なら他を無視（ここでは判定しない）
                            nearbyNotes.append((laneIndex: index, timelag: self.lanes[index].timeLag, note: note, distanceToButton: distanceToButton))
                            continue
                        }
                    }
                }
                
                if nearbyNotes.isEmpty {
                    self.actionSoundSet.play(type: .kara)
                } else {
                    nearbyNotes.sort { (A,B) -> Bool in
                        if A.timelag == B.timelag { return A.distanceToButton < B.distanceToButton }
                        
                        return A.timelag < B.timelag
                    }
                    
                    if (nearbyNotes[0].note is Tap) ||
                        (nearbyNotes[0].note is TapStart) ||
                        (nearbyNotes[0].note is Middle) {
                        if self.judge(lane: self.lanes[nearbyNotes[0].laneIndex], timeLag: nearbyNotes[0].timelag, touch: self.allTouches[self.allTouches.count-1]) {
                            self.actionSoundSet.play(type: .tap)
                        } else {
                            print("判定失敗:tap")
                        }
                    }
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for i in self.lanes {
            guard i.isTimeLagSet else { return }
        }
        
        judgeQueue.sync {
            
            for touch in touches {
                
                let touchIndex = self.allTouches.index(where: { $0.touch == touch } )!  // ここでnil発生!?
                
                var pos = touch.location(in: self.view?.superview)
                var ppos = touch.previousLocation(in: self.view?.superview)
                
                let moveDistance = sqrt(pow(pos.x-ppos.x, 2) + pow(pos.y-ppos.y, 2))
                
                pos.y = self.frame.height - pos.y   // 上下逆転(画面下からのy座標に変換)
                ppos.y = self.frame.height - ppos.y
                
               

                
                // 判定対象を選ぶため、押された範囲のレーンから最近ノーツを取得
                var nearbyNotes: [(laneIndex: Int, timelag: TimeInterval, note: Note, distanceToButton: CGFloat)] = []
                
                // pposループ
                for (index, judgeXRange) in Dimensions.judgeXRanges.enumerated() {
                    if judgeXRange.contains(ppos.x) && ppos.y < Dimensions.buttonHeight {
                        if !(judgeXRange.contains(pos.x)) || pos.y >= Dimensions.buttonHeight { // 移動後にレーンから外れていた場合は、外れる直前にいた時間で判定
                            
                            if self.lanes[index].middleObservationTimeState == .before {
                                if self.judge(lane: self.lanes[index], timeLag: self.lanes[index].timeLag, touch: self.allTouches[touchIndex]) {
                                    self.actionSoundSet.play(type: .middle)
                                    break
                                }
                            }
                        }
                    }
                    
                    guard pos.y < Dimensions.buttonHeight else {     // 以下、ボタンの判定圏内にあるtouchのみを処理する
                        continue
                    }
                    
                    // フリックの判定
                    guard !(self.lanes[index].laneNotes.isEmpty) else { continue }
                    
                    let judgeNote = self.lanes[index].laneNotes[0]
                    if moveDistance > 10 && self.lanes[index].timeState != .still &&
                        self.lanes[index].timeState != .passed {
                        
                        
                        let touch = self.allTouches[touchIndex] // エイリアス
                        
                        if ((judgeNote is Flick) && touch.isJudgeableFlick) ||
                            ((judgeNote is FlickEnd) && touch.isJudgeableFlickEnd) {
                            // ソート開始!
                            let distanceToButton = sqrt(pow(ppos.x - Dimensions.buttonX[index], 2) + pow(ppos.y - Dimensions.judgeLineY, 2))
                            
                            nearbyNotes.append((laneIndex: index, timelag: self.lanes[index].timeLag, note: judgeNote, distanceToButton: distanceToButton))
                            continue
                        }
                    }
                }
                
                if !(nearbyNotes.isEmpty) {
                    
                    nearbyNotes.sort { (A,B) -> Bool in
                        if A.timelag == B.timelag { return A.distanceToButton < B.distanceToButton }
                        
                        return A.timelag < B.timelag
                    }
                    if (nearbyNotes[0].note is Flick) || (nearbyNotes[0].note is FlickEnd) {    // nearbyNotesにはFlickかFlickEndしか入ってない。念のため
                        
                        if self.lanes[nearbyNotes[0].laneIndex].isFlickAndBefore {      // judgeするにはまだ早いんだ！！可能性の芽を摘むな！
                            
                            self.lanes[nearbyNotes[0].laneIndex].storedFlickJudge = (nearbyNotes[0].timelag, touch)  // parfect前までは、後にperfectになるかもしれないので保持
                            
                        } else if self.judge(lane: self.lanes[nearbyNotes[0].laneIndex], timeLag: nearbyNotes[0].timelag, touch: self.allTouches[touchIndex]) {
                            
                            self.actionSoundSet.play(type: .flick)
                            
                            
                        } else {
                            print("判定失敗: flick")     // 二重判定防止に成功した時とか
                        }
                    }
                }
                
                
                // middleの話。afterで、外から中に入ってきた時は、その時判定する
               for (index, judgeXRange) in Dimensions.judgeXRanges.enumerated() {
                    if judgeXRange.contains(pos.x) && pos.y < Dimensions.buttonHeight {
                        
                        if self.lanes[index].middleObservationTimeState == .after {    // 入った先のレーンの最初がmiddleで、それがparfect時刻を過ぎても判定されずに残っている場合
                            if self.judge(lane: self.lanes[index], timeLag: self.lanes[index].timeLag, touch: self.allTouches[touchIndex]) {
                                self.actionSoundSet.play(type: .middle)
                                break
                            }
                        }
                    }
                }
                
                // storedFlickについて、指がレーンから外れていた場合、これ以上待っても決してperfectにはならないので、即判定してしまう。
                if let buttonXAndLaneIndex = self.allTouches[touchIndex].storedFlickJudgeLaneIndex {
                    if !(Dimensions.judgeXRanges[buttonXAndLaneIndex].contains(pos.x)) || pos.y >= Dimensions.buttonHeight {
                        
                        storedFlickJudge(lane: lanes[buttonXAndLaneIndex])
                    }
                }
            }
        }
    }
    
    // touchMovedと似てる。TapEndの判定をするかだけが違う
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for lane in self.lanes {
            if !(lane.isTimeLagSet) { return }
        }
        
        judgeQueue.sync {
            
            
            for touch in touches {
                
                let touchIndex = self.allTouches.index(where: { $0.touch == touch } )!
                
                var pos = touch.location(in: self.view?.superview)
                var ppos = touch.previousLocation(in: self.view?.superview)
                
                pos.y = self.frame.height - pos.y   // 上下逆転(画面下からのy座標に変換)
                ppos.y = self.frame.height - ppos.y
                
                
                
                // pposループ
                for (index, judgeXRange) in Dimensions.judgeXRanges.enumerated() {
                    if  judgeXRange.contains(ppos.x) && ppos.y < Dimensions.buttonHeight {
                        if !(judgeXRange.contains(pos.x)) || pos.y >= Dimensions.buttonHeight {   //  移動後にレーンから外れていた場合
                            if self.lanes[index].middleObservationTimeState == .before {
                                if self.judge(lane: self.lanes[index], timeLag: self.lanes[index].timeLag, touch: self.allTouches[touchIndex]) {
                                    self.actionSoundSet.play(type: .middle)
                                    
                                    break
                                }
                            }
                        }
                        
                    }
                }
                
                guard pos.y < Dimensions.buttonHeight else { continue }   // 以下、移動後の座標がボタン内である場合のみ処理を行う
                
                // posループ
                for (index, judgeXRange) in Dimensions.judgeXRanges.enumerated()  {
                    
                    if judgeXRange.contains(pos.x) {  // ボタンの範囲
                        if self.lanes[index].middleObservationTimeState == .before { // 早めに指を離した場合
                            if self.judge(lane: self.lanes[index], timeLag: self.lanes[index].timeLag, touch: self.allTouches[touchIndex]) {
                                self.actionSoundSet.play(type: .middle)
                                break
                            }
                        } else if self.lanes[index].middleObservationTimeState == .after { // 入った先のレーンの最初がmiddleで、それがparfect時刻を過ぎても判定されずに残っている場合
                            if self.judge(lane: self.lanes[index], timeLag: self.lanes[index].timeLag, touch: self.allTouches[touchIndex]) {
                                self.actionSoundSet.play(type: .middle)
                                break
                            }
                        }
                        
                        if self.lanes[index].laneNotes.count == 0 { continue }
                        let note = self.lanes[index].laneNotes[0]
                        if note is TapEnd {
                            if self.judge(lane: self.lanes[index], timeLag: self.lanes[index].timeLag, touch: self.allTouches[touchIndex]) {    // 離しの判定
                                
                                self.actionSoundSet.play(type: .tap)
                                break
                            }
                        } else if ((note is Flick && self.allTouches[touchIndex].isJudgeableFlick) ||
                            (note is FlickEnd && self.allTouches[touchIndex].isJudgeableFlickEnd)) &&
                            self.lanes[index].isJudgeRange  {   // flickなのにflickせずに離したらmiss
                            
                            self.missJudge(lane: self.lanes[index])
                        }
                    }
                }
                
                
                //storedFlickが残っていないか確認
                if let laneIndex = self.allTouches[touchIndex].storedFlickJudgeLaneIndex {
                    storedFlickJudge(lane: lanes[laneIndex])
                }
                
                self.allTouches.remove(at: self.allTouches.index(where: { $0.touch == touch } )!)
            }
        }
    }
    
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("cancelされました")
    }
    
    override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {
        print("touchesEstimatedPropertiesUpdated")
    }
    
    
    enum NoteType {
        case tap, flick, tapStart, middle, tapEnd, flickEnd
    }
    
    
    
    // 受け取ったLaneの先頭ノーツを判定する。失敗したらfalseを返す。引数でtimeLagを渡すのは（judge呼び出し時ではなく）タッチされた時のものを使用するため。
    ///受け取ったLaneの先頭ノーツを判定する。
    ///
    /// - Parameters:
    ///   - lane: 判定対象のレーン
    ///   - timeLag: 判定したいノーツの正しい時間と実際に叩かれた時間との差。（judge呼び出し時ではなく）タッチされた時のものを使用する。
    ///   - touch: ノーツを叩いたGSTouchインスタンス。GameSceneから解放されていたらnilを入れること。
    /// - Returns: 成否をBoolで返す
    func judge(lane: Lane, timeLag: TimeInterval, touch: GSTouch?) -> Bool {
        
        guard !(lane.laneNotes.isEmpty) else { return false }
        
        let judgeNote = lane.laneNotes.first!
        
        guard judgeNote.isJudgeable else { return false }
        
        
        switch judgeNote {
        case is Flick, is FlickEnd:
            touch?.isJudgeableFlick = false    // このタッチでのフリック判定を禁止
            touch?.isJudgeableFlickEnd = false
            
            // storedFlickJudgeに関する処理
            touch?.storedFlickJudgeLaneIndex = nil
            lane.storedFlickJudge = nil
        case is Tap:
            touch?.isJudgeableFlick = false
            touch?.isJudgeableFlickEnd = false
            
        case is TapStart, is Middle:
            touch?.isJudgeableFlick = false
            touch?.isJudgeableFlickEnd = true
       
        default: break
            
        }
       
       
        
        
        switch lane.getTimeState(timeLag: timeLag) {
        case .parfect:
            setJudgeLabelText(text: "parfect!!")
            ResultScene.parfect += 1
            ResultScene.combo += 1
            if ResultScene.combo > ResultScene.maxCombo {
                ResultScene.maxCombo += 1
            }
            judgeNote.isJudged = true
            setNextIsJudgeable(judgeNote: judgeNote)
            releaseNote(lane: lane)
            return true
        case .great:
            setJudgeLabelText(text: "great!")
            ResultScene.great += 1
            ResultScene.combo += 1
            if ResultScene.combo > ResultScene.maxCombo {
                ResultScene.maxCombo += 1
            }
            judgeNote.isJudged = true
            setNextIsJudgeable(judgeNote: judgeNote)
            releaseNote(lane: lane)
            return true
        case .good:
            setJudgeLabelText(text: "good")
            ResultScene.good += 1
            ResultScene.combo = 0
            judgeNote.isJudged = true
            setNextIsJudgeable(judgeNote: judgeNote)
            releaseNote(lane: lane)
            return true
        case .bad:
            setJudgeLabelText(text: "bad")
            ResultScene.bad += 1
            ResultScene.combo = 0
            judgeNote.isJudged = true
            setNextIsJudgeable(judgeNote: judgeNote)
            releaseNote(lane: lane)
            return true
        case .miss:
            setJudgeLabelText(text: "miss!")
            ResultScene.miss += 1
            ResultScene.combo = 0
            judgeNote.isJudged = true
            setNextIsJudgeable(judgeNote: judgeNote)
            releaseNote(lane: lane)
            return true
        default:
            return false
            
        }
        
        
    }
    
    // parfect終了時(laneからのdelegate)または指が外れた時に呼び出される。
    func storedFlickJudge(lane: Lane) {
        
        guard lane.storedFlickJudge != nil else { return }
        
       
        if judge(lane: lane, timeLag: lane.storedFlickJudge!.time,
                 touch: self.allTouches.first(where: { $0.touch == lane.storedFlickJudge!.touch })) { //（laneから呼び出され、すでに指が離れている場合はtouchはnilになる）
            
            self.actionSoundSet.play(type: .flick)
        } else {
            
            print("storedFlickJudgeに失敗")
        }
    }
    
    // 受け取ったLaneの先頭ノーツを判定する。失敗したらfalseを返す。middleのperfect専用
    func parfectMiddleJudge(lane: Lane) -> Bool {
        
        guard !(lane.laneNotes.isEmpty),
              lane.laneNotes[0] is Middle,
              lane.laneNotes[0].isJudgeable else { return false }
        
        lane.update(passedTime, BPMs)
        
        switch lane.timeState {
        case .parfect:
            setJudgeLabelText(text: "parfect!!")
            ResultScene.parfect += 1
            ResultScene.combo += 1
            if ResultScene.combo > ResultScene.maxCombo {
                ResultScene.maxCombo += 1
            }
            lane.laneNotes[0].isJudged = true
            setNextIsJudgeable(judgeNote: lane.laneNotes[0])
            releaseNote(lane: lane)
            return true
        default:
            break
        }
        
        return false
    }
    
    @discardableResult
    func missJudge(lane: Lane) -> Bool {
        guard lane.laneNotes[0].isJudgeable else { return false }
        
        setJudgeLabelText(text: "miss!")
        ResultScene.miss += 1
        ResultScene.combo = 0
        lane.laneNotes[0].isJudged = true
        setNextIsJudgeable(judgeNote: lane.laneNotes[0])
        releaseNote(lane: lane)
        return true
    }
    
    func setNextIsJudgeable(judgeNote: Note)  {
        if judgeNote is TapStart {
            let note = judgeNote as! TapStart
            note.next.isJudgeable = true
        } else if judgeNote is Middle {
            let note = judgeNote as! Middle
            note.next.isJudgeable = true
        }
    }
    
    func releaseNote(lane: Lane) {  // ノーツや同時押し線、関連ノードを開放する
        
        if let i = sameLines.index(where: { $0.note1 === lane.laneNotes.first! } ) {    //同時押し線を解放
            
            sameLines.remove(at: i)
        } else if let i = sameLines.index(where: { $0.note2 === lane.laneNotes.first! } ) { //同時押し線を解放
            
            sameLines.remove(at: i)
        }
        if let note = lane.laneNotes.first! as? TapEnd {        //始点から終点まで、連鎖的に参照を削除
            let index = notes.index(where: { $0 === note.start } )
            notes.remove(at: index!)
        } else if let note = lane.laneNotes.first! as? FlickEnd {
            let index = notes.index(where: { $0 === note.start } )
            notes.remove(at: index!)
        } else if lane.laneNotes.first! is Tap || lane.laneNotes.first! is Flick {
            let index = notes.index(where: { $0 === lane.laneNotes.first! } )
            notes.remove(at: index!)
        }
        lane.laneNotes.removeFirst()                // レーンからの参照を削除
        
    }
}
