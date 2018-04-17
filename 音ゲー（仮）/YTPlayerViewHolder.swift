//
//  MyYTPlayerView.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2018/04/15.
//  Copyright © 2018年 NakaiKohei. All rights reserved.
//

import youtube_ios_player_helper

class YTPlayerViewHolder {
    
    var view: YTPlayerView
    
    var startTime: TimeInterval = TimeInterval(pow(10.0, 308.0))  // ロードが終わり、再生開始された時間を格納する(初期値はDoubleのほぼ最大値).ポーズするたびに差分を足す.
    
    var timeOffset: TimeInterval = 0.0                            // ポーズするたびに差分を足す.
    
    var pausedTime: TimeInterval = 0.0
    
    var currentTime: TimeInterval {
        if self.view.playerState() == .paused { return self.pausedTime - self.startTime - self.timeOffset }
        else { return CACurrentMediaTime() - self.startTime - self.timeOffset }
    }
    
    var duration: TimeInterval { return self.view.duration() }
    
    var delegate: YTPlayerViewDelegate? {
        get{
            return self.view.delegate
        }
        
        set(tmp) {
            self.view.delegate = tmp
        }
    }
    
    var isUserInteractionEnabled: Bool {
        get {
            return self.view.isUserInteractionEnabled
        }
        set(tmp) {
            self.view.isUserInteractionEnabled = tmp
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
        self.pausedTime = CACurrentMediaTime()
    }
    
    
        
}
