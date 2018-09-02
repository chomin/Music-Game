//
//  Setting.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2018/08/21.
//  Copyright © 2018年 NakaiKohei. All rights reserved.
//

import Foundation

/// ユーザー設定のほか、難易度やYouTubeの有無などをまとめたentity
class Setting {
    
    enum Keys: String {
        case userSpeedRatioInt
        case userNoteSizeRatioInt
        case userIsYouTube
        case userIsAutoPlay
        case userIsFitToLane
        case userLastChosenMusicStr
    }
    
    private var speedRatioIntP:  UInt    // privateのP
    private var speedRatioP:     Double
    private var scaleRatioIntP:  UInt
    private var scaleRatioP:     Double
    var isYouTube:       Bool
    var isAutoPlay:      Bool
    var isFitSizeToLane: Bool
    private var musicNameStr:    String
    
    var playMode: PlayMode {
        get {
            if !isYouTube                                      { return .BGM      }
            else if musicName == .oracion &&
                (speedRatioInt <= 21 || speedRatioInt >= 201 ) { return .YouTube2 }
            else                                               { return .YouTube  }
        }
    }
    
    let defaults = UserDefaults.standard
    
    init() {
        // 設定をロード
        defaults.register(defaults: [ Keys.userSpeedRatioInt.rawValue      : 100                       ])    // 初期値を設定(値がすでに入ってる場合は無視される)
        defaults.register(defaults: [ Keys.userNoteSizeRatioInt.rawValue   : 100                       ])
        defaults.register(defaults: [ Keys.userIsYouTube.rawValue          : true                      ])
        defaults.register(defaults: [ Keys.userIsAutoPlay.rawValue         : false                     ])
        defaults.register(defaults: [ Keys.userIsFitToLane.rawValue        : true                      ])
        defaults.register(defaults: [ Keys.userLastChosenMusicStr.rawValue : MusicName.first!.rawValue ])
        
        speedRatioIntP = UInt(defaults.integer(forKey: Keys.userSpeedRatioInt.rawValue)) //読み出し
        scaleRatioIntP = UInt(defaults.integer(forKey: Keys.userNoteSizeRatioInt.rawValue))
        isYouTube = defaults.bool(forKey: Keys.userIsYouTube.rawValue)
        isAutoPlay = defaults.bool(forKey: Keys.userIsAutoPlay.rawValue)
        isFitSizeToLane = defaults.bool(forKey: Keys.userIsFitToLane.rawValue)
        musicNameStr = defaults.string(forKey: Keys.userLastChosenMusicStr.rawValue)!
        
        speedRatioP = Double(speedRatioIntP)/100
        scaleRatioP = Double(scaleRatioIntP)/100
    }
    
    func save(){
        defaults.set(speedRatioInt, forKey: Keys.userSpeedRatioInt.rawValue)
        defaults.set(scaleRatioInt, forKey: Keys.userNoteSizeRatioInt.rawValue)
        defaults.set(isYouTube, forKey: Keys.userIsYouTube.rawValue)
        defaults.set(isAutoPlay, forKey: Keys.userIsAutoPlay.rawValue)
        defaults.set(isFitSizeToLane, forKey: Keys.userIsFitToLane.rawValue)
        defaults.set(musicNameStr, forKey: Keys.userLastChosenMusicStr.rawValue)
        
        speedRatio = Double(speedRatioInt)/100
    }
    
    /* ----- getter, setter -----*/
    var speedRatioInt: UInt {
        get {
            return speedRatioIntP
        }
        set {
            speedRatioIntP = newValue
            speedRatioP = Double(newValue)/100
        }
    }
    var speedRatio: Double {
        get {
            return speedRatioP
        }
        set {
            speedRatioP = newValue
            speedRatioIntP = UInt(newValue*100)
        }
    }
    var scaleRatioInt: UInt {
        get {
            return scaleRatioIntP
        }
        set {
            scaleRatioIntP = newValue
            scaleRatioP = Double(newValue)/100
        }
    }
    var scaleRatio: Double {
        get {
            return scaleRatioP
        }
        set {
            scaleRatioP = newValue
            scaleRatioIntP = UInt(newValue*100)
        }
    }
    var musicName: MusicName {
        get {
            return MusicName(rawValue: musicNameStr)!
        }
        set {
            musicNameStr = newValue.rawValue
        }
    }
}
