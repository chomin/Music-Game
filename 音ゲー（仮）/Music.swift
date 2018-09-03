//
//  Music.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2018/08/23.
//  Copyright © 2018年 NakaiKohei. All rights reserved.
//

import Foundation
import RealmSwift

/// bmsファイルから読み込まれた音楽情報をまとめたentity。ヘッダ情報とメイン情報を持つ。
struct Music {
    
    var header: Header
    var BPMs: [(bpm: Double, startPos: Double)] = []
    
    var laneNum:   Int    { return header.laneNum   }
    var genre:     String { return header.genre     }   // ジャンル
    var title:     String { return header.title     }   // タイトル(正式名称。ファイル名は文字の制約があるためこっちを正式とする)
    var artist:    String { return header.artist    }   // アーティスト
    var videoID:   String { return header.videoID   }   // YouTubeのvideoID
    var playLevel: Int    { return header.playLevel }   // 難易度
    var volWav:    Int    { return header.volWav    }   // 音量を現段階のn%として出力するか(TODO: 未実装)
    var bmsNameWithExtension: String { return header.bmsNameWithExtension }
//    var BPMs: List<BPMInfo>{        // 可変BPM情報(headerだけでなくmain情報にも記述されるのでget onlyにしない)
//        get { return header.BPMs }
//        set { header.BPMs = newValue }
//    }
//    var musicName: String { return title }       // 曲名
}
