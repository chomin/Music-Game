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
        case userSpeedRatioInt    = "userSpeedRatioInt"
        case userNoteSizeRatioInt = "userNoteSizeRatioInt"
        case userIsYouTube        = "userIsYouTube"
        case userIsAutoPlay       = "userIsAutoPlay"
        case userIsFitToLane      = "userIsFitToLane"
    }
    
    private var speedRatioIntP:  UInt    // privateのP
    private var speedRatioP:     Double
    private var scaleRatioIntP:  UInt
    private var scaleRatioP:     Double
            var isYouTube:       Bool
            var isAutoPlay:      Bool
            var isFitSizeToLane: Bool
    
    var musicName = MusicName.first!
    
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
        defaults.register(defaults: [ Keys.userSpeedRatioInt.rawValue    : 100   ])    // 初期値を設定(値がすでに入ってる場合は無視される)
        defaults.register(defaults: [ Keys.userNoteSizeRatioInt.rawValue : 100   ])
        defaults.register(defaults: [ Keys.userIsYouTube.rawValue        : true  ])
        defaults.register(defaults: [ Keys.userIsAutoPlay.rawValue       : false ])
        defaults.register(defaults: [ Keys.userIsFitToLane.rawValue      : true  ])
        
        
        speedRatioIntP = UInt(defaults.integer(forKey: Keys.userSpeedRatioInt.rawValue)) //読み出し
        scaleRatioIntP = UInt(defaults.integer(forKey: Keys.userNoteSizeRatioInt.rawValue))
        isYouTube = defaults.bool(forKey: Keys.userIsYouTube.rawValue)
        isAutoPlay = defaults.bool(forKey: Keys.userIsAutoPlay.rawValue)
        isFitSizeToLane = defaults.bool(forKey: Keys.userIsFitToLane.rawValue)
        
        speedRatioP = Double(speedRatioIntP)/100
        scaleRatioP = Double(scaleRatioIntP)/100
    }
    
    func save(){
        defaults.set(speedRatioInt, forKey: Keys.userSpeedRatioInt.rawValue)
        defaults.set(scaleRatioInt, forKey: Keys.userNoteSizeRatioInt.rawValue)
        defaults.set(isYouTube, forKey: Keys.userIsYouTube.rawValue)
        defaults.set(isAutoPlay, forKey: Keys.userIsAutoPlay.rawValue)
        defaults.set(isFitSizeToLane, forKey: Keys.userIsFitToLane.rawValue)
        
        speedRatio = Double(speedRatioInt)/100
    }
    
    /* ----- getter, setter -----*/
    var speedRatioInt: UInt {
        get{
            return speedRatioIntP
        }
        set(value){
            speedRatioIntP = value
            speedRatioP = Double(value)/100
        }
    }
    var speedRatio: Double {
        get{
            return speedRatioP
        }
        set(value){
            speedRatioP = value
            speedRatioIntP = UInt(value*100)
        }
    }
    var scaleRatioInt: UInt {
        get{
            return scaleRatioIntP
        }
        set(value){
            scaleRatioIntP = value
            scaleRatioP = Double(value)/100
        }
    }
    var scaleRatio: Double {
        get{
            return scaleRatioP
        }
        set(value){
            scaleRatioP = value
            scaleRatioIntP = UInt(value*100)
        }
    }
    
}
