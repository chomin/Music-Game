
//
//  PlayMusicScenes.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation
import youtube_ios_player_helper_swift    // 今後、これを利用するために.xcodeprojではなく、.xcworkspaceを開いて編集すること

/// 判定関係のフラグ付きタッチ情報
class GSTouch { // 参照型として扱いたい
    let touch: UITouch
    var isJudgeableFlick: Bool      // このタッチでのフリック判定を許すor許さない
    var isJudgeableFlickEnd: Bool   // 上記のFlickEndバージョン
    var storedFlickJudgeLaneIndex: Int?
    
    init(touch: UITouch, isJudgeableFlick: Bool, isJudgeableFlickEnd: Bool, storedFlickJudgeLaneIndex: Int?) {
        self.touch = touch
        self.isJudgeableFlick = isJudgeableFlick
        self.isJudgeableFlickEnd = isJudgeableFlickEnd
        self.storedFlickJudgeLaneIndex = storedFlickJudgeLaneIndex
    }
}



/// 音ゲーをするシーン
class GameScene: PlayMusicScene {

    // タッチ情報
    var allGSTouches: [GSTouch] = []

    
//    init(size: CGSize, setting: Setting, header: Header) {
//
//        super.init(size: size, setting: setting, header: header)
//    }
//    init(size: CGSize, setting: Setting, music: Music) {
//
//        super.init(size: size, setting: setting, music: music)
//    }

    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)

        // 判定関係
        // middleの判定（同じところで長押しのやつ）
        for gsTouch in self.allGSTouches {

            let pos = gsTouch.touch.location(in: self.view?.superview)

            for (laneIndex, judgeRect) in Dimensions.judgeRects.enumerated() {

                if judgeRect.contains(pos) {   // ボタンの範囲

                    if self.perfectMiddleJudge(lane: self.lanes[laneIndex], gsTouch: gsTouch) { // middleの判定
                        break   // このタッチでこのフレームでの判定はもう行わない
                    }
                }
            }
        }

        // レーンの監視(過ぎて行ってないか&storedFlickJudgeの時間になっていないか)
        for lane in self.lanes {
            if lane.judgeTimeState == .passed && !(lane.isEmpty) {

                self.missJudge(lane: lane)

            } else if let storedFlickJudgeInformation = lane.storedFlickJudgeInformation {
                if lane.timeLag < -storedFlickJudgeInformation.timeLag {

                    self.storedFlickJudge(lane: lane)
                }
            }
        }

        // ラベルの更新
        comboLabel.text = String(result.combo)
    }
}
