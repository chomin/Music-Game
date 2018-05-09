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
    private var timeDiffSamples: [TimeInterval] = []    // 再生開始後3フレーム目までのシステム時刻とYouTubeのcurrentTimeの差を3つ保存。中央値を基準として使用するため
    private var baseline: TimeInterval!                 // currentTimeのずれを検出するための基準。timeDiffSamplesの中央値。ポーズ後に更新される
    
//    var startTime: TimeInterval = TimeInterval(pow(10.0, 308.0))  // ロードが終わり、再生開始された時間を格納する(初期値はDoubleのほぼ最大値).再生されてしばらくしてから同期をとる.
//    var isSetStartTime: Bool = false
    
//    var timeOffset: TimeInterval = 0.0                            // ポーズするたびに差分を足す.
    
    var initialPausedTime: TimeInterval = 0     // 始めの同期待ちポーズの時にオーバーランした時間
    
    var currentTime: TimeInterval {
//        if self.view.playerState() == .paused { return self.pausedTime - self.startTime - self.timeOffset }
//        else { return CACurrentMediaTime() - self.startTime - self.timeOffset }
        
        let currentTime = TimeInterval(view.currentTime())
        
        // 再生開始から4フレーム以降(ポーズ中は除く)
        if timeDiffSamples.count == 3 && baseline != nil {
            let diff = CACurrentMediaTime() - (currentTime + offset)
            // 誤差が大きければ補正
            if abs(diff - baseline!) > 1/150 {      // 閾値はiPhone8による測定値から決定。カクつきが目立たない値にする
                offset += diff - baseline
                print("adjusted")
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
//        self.pausedTime = CACurrentMediaTime()
        self.view.pauseVideo()
        baseline = nil
    }
    
    func playerState() -> YTPlayerState {
        return self.view.playerState()
    }
    
    // 再生開始時に呼ぶこと
    func sample() {
        if timeDiffSamples.count < 3 {
            timeDiffSamples.append(CACurrentMediaTime() - TimeInterval(view.currentTime()))
            if timeDiffSamples.count == 3 {
                baseline = timeDiffSamples.sorted()[1]  // 3つの値の中央値を基準に設定
            }
        }
    }
    
    // ポーズ後、再開時に呼ぶこと
    func updateBaseline() {
        baseline = CACurrentMediaTime() - (TimeInterval(view.currentTime()) + offset)
    }
    
}





