//
//  MyYTPlayerView.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2018/04/15.
//  Copyright © 2018年 NakaiKohei. All rights reserved.
//

import youtube_ios_player_helper

class YTPlayerViewHolder {
    
    let view: YTPlayerView
    
    private var offset: TimeInterval = 0
    private var baseline: TimeInterval!                 // currentTimeのずれを検出するための基準。timeDiffSamplesの中央値。ポーズ後に更新される
    
    var initialPausedTime: TimeInterval = 0     // 始めの同期待ちポーズの時にオーバーランした時間
    
    var currentTime: TimeInterval {
        
        let currentTime = TimeInterval(view.currentTime())
        
        // 再生開始から4フレーム以降(ポーズ中は除く)
        if baseline != nil {
            let diff = CACurrentMediaTime() - (currentTime + offset)
            // 誤差が大きければ補正
            if abs(diff - baseline!) > 1/150 {      // 閾値はiPhone8による測定値から決定。カクつきが目立たない値にする
                offset += diff - baseline
//                print("adjusted")
            }
        }
        
        return currentTime + offset
    }
    
    var duration: TimeInterval { return self.view.duration() }
    
    var delegate: YTPlayerViewDelegate? {
        get {
            return self.view.delegate
        }
        set {
            self.view.delegate = newValue
        }
    }
    
    var isUserInteractionEnabled: Bool {
        get {
            return self.view.isUserInteractionEnabled
        }
        set {
            self.view.isUserInteractionEnabled = newValue
        }
    }
    
    init(frame: CGRect) {
        self.view = YTPlayerView(frame: frame)
    }
    
    func load(withVideoId: String, playerVars: [AnyHashable: Any]?) -> Bool {
        return self.view.load(withVideoId: withVideoId, playerVars: playerVars)
    }
    
    func seek(toSeconds: Float, allowSeekAhead: Bool) {
        self.view.seek(toSeconds: toSeconds, allowSeekAhead: allowSeekAhead)
    }
    
    func playVideo() {
        self.view.playVideo()
    }
    
    func pauseVideo() {
        self.view.pauseVideo()
        baseline = nil
//        print("paused")
    }
    
    func playerState() -> YTPlayerState {
        return self.view.playerState()
    }

    private var frame = 0
    // 毎フレームに1度呼ぶこと
    func countFrameForBaseline() {
        if view.playerState() == .playing && baseline == nil {
            frame += 1
            if frame == 60 {
                renewTimeParams()
            }
        } else if view.playerState() == .paused {
            frame = 0
        }
    }
    
    // 再生開始時に呼ぶこと
    func renewTimeParams() {
        offset = 0
        baseline = CACurrentMediaTime() - (TimeInterval(view.currentTime()) + offset)
        print("baseline set")
    }

    
}





