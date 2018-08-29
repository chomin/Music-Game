//
//  Music.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2018/08/23.
//  Copyright © 2018年 NakaiKohei. All rights reserved.
//

import Foundation

/// bmsファイルから読み込まれた音楽情報をまとめたentity.readerが読み込んで完成する（読み込み前の扱いに注意）。
struct Music {
    var laneNum = 7
    var genre = ""                                      // ジャンル
    var title = ""                                      // タイトル
    var artist = ""                                     // アーティスト
    var videoID = ""                                    // YouTubeのvideoID
    var playLevel = 0                                   // 難易度
    var volWav = 100                                    // 音量を現段階のn%として出力するか(TODO: 未実装)
    var BPMs: [(bpm: Double, startPos: Double)] = []    // 可変BPM情報
    
    var musicName: MusicName {
        return MusicName(rawValue: title)!
    }                  // 曲名
}
