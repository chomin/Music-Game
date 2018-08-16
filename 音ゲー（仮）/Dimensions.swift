//
//  Dimensions.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2018/03/19.
//  Copyright © 2018年 NakaiKohei. All rights reserved.
//

import UIKit

/// rawvalueが音楽ファイル名に対応する列挙型
/// 新曲を追加する際はここに曲名を追加する。
enum MusicName: String, EnumCollection {
    
    case yo_kosoJapariParkHe    = "ようこそジャパリパークへ"
    case oracion                = "オラシオン"
    case thisGame               = "This game"
    case sakuraSkip             = "SAKURAスキップ"
    case zankokuNaTenshiNoThese = "残酷な天使のテーゼ"
    case nimenseiUraomoteLife   = "にめんせい☆ウラオモテライフ！"
    case buonAppetitoS          = "ぼなぺてぃーとS"
    case level5                 = "LEVEL5-Judgelight-"
    
    /*--------ミリシタ楽曲---------*/
    case ready                  = "READY!!"
    case jibunRestart           = "自分REST@RT"
    case thankYou               = "Thank You!"
    case welcome                = "Welcome!!"
    case brandNewTheater        = "Brand New Theater!"
    
    case shootingStars          = "Shooting Stars"
    case twinkleRhythm          = "ZETTAI × BREAK!! トゥインクルリズム"
    case growingStorm           = "Growing Storm!"
    case utaMas                 = "THE IDOLM@STER"
    case marionettesNeverSleep  = "Marionetteは眠らない"
    case machiukePrince         = "待ち受けプリンス"
    
    /*--------バンドリ楽曲---------*/
    case thisGameEx             = "This game(expert)"
    case dreamParade            = "ドリームパレード(expert)"
    case seikaihahitotujanai    = "正解はひとつ！じゃない！！(expert)"
    
    static func getPickerArray() -> [String] {
        
        var pickerArray: [String] = []
        
//        print(MusicName.allValues)
        
        
        for musicName in MusicName.allValues {
            pickerArray.append(musicName.rawValue)
//            print(musicName.rawValue)
            // YouTubeを実装しているものについてはYouTubeモードをピッカーに追加
//            if musicName == .yo_kosoJapariParkHe ||
//                musicName == .oracion ||
//                musicName == .sakuraSkip ||
//                musicName == .nimenseiUraomoteLife ||
//                musicName == .level5 {
//
//                pickerArray.append(musicName.rawValue + "(YouTube)")
//            }
        }
        return pickerArray
    }
    
}

/// rawvalueがYouTubeのvideoIDに対応する列挙型
/// YouTubeを追加する際は MusicName.getPickerArray()のif分岐 への追加も忘れないように
//enum VideoID: String {  // VideoIDの列挙型(https://www.youtube.com/watch?v=************の***********部分)
//    
//    case yo_kosoJapariParkHe  = "xkMdLcB_vNU"
//    case oracion              = "6kQzRm21N_g"
//    case uracion              = "fF6c1gqutjs"
//    case sakuraSkip           = "dBwwipunJcw"
//    case nimenseiUraomoteLife = "TyMx4pu7kA0"
//    case buonAppetitoS        = "LOajYHKEHG8"
//    case level5               = "1NYUKIZCV5k"
//    
//    /*
//     "ぼなぺてぃーとS": 埋め込み許可されているアニメ版が見つからず
//     
//     */
//    
//    
//}

/// rawvalueが画像ファイル名に対応する列挙型
enum ImageName: String {
    
    case setting             = "SettingIcon"
    case settingSelected     = "SettingIconSelected"
    case plus                = "PlusIcon"
    case plusSelected        = "PlusIconSelected"
    case minus               = "MinusIcon"
    case minusSelected       = "MinusIconSelected"
    case plus10              = "Plus10Icon"
    case plus10Selected      = "Plus10IconSelected"
    case minus10             = "Minus10Icon"
    case minus10Selected     = "Minus10IconSelected"
    case saveAndBack         = "SaveAndBackIcon"
    case saveAndBackSelected = "SaveAndBackIconSelected"
    case pause               = "PauseIcon"
    case pauseSelected       = "PauseIconSelected"
}



enum PlayMode {
    case BGM, YouTube, YouTube2
}

extension CGRect {
    var XRange: Range<CGFloat> { return self.minX ..< self.maxX }
    var YRange: Range<CGFloat> { return self.minY ..< self.maxY }
}

/// 寸法に関する定数を提供(シングルトン)。GameSceneのframeをもとに決定される。
class Dimensions {
    // インスタンスが保持し、このクラス内からの記述でのみアクセスできる変数。staticで呼び出されたときにこれらに格納されている値を返す。(frameが不要なものは初期値をここで定義)
    // オプショナルのものはレーン数依存定数
    private let frame: CGRect                       // 画面の大きさ
    private var horizonLeftX: CGFloat?              // 水平線の左端x座標
    private let horizonY: CGFloat                   // 水平線のy座標
    private var laneWidth: CGFloat?                 // 3D上でのレーン幅(判定線における2D上のレーン幅と一致)
    private var laneWidthOnHorizon: CGFloat?        // 画面の水平線上でのレーン幅
    private let laneLength: CGFloat                 // 3D上でのレーン長
    private let judgeLineY: CGFloat                 // 判定線のy座標
    private let iconButtonSize: CGFloat             // アイコンの大きさ
    private var buttonX: [CGFloat]?                 // 各レーンの中心のx座標
    private var judgeRects: [CGRect]?               // 各レーンの判定をする範囲(長方形)
    private let horizontalDistance: CGFloat = 250   // 画面から目までの水平距離a（約5000で10cmほど）
    private let verticalDistance: CGFloat           // 画面を垂直に見たとき、判定線から目までの高さh（実際の水平線の高さでもある）
    private let R: CGFloat                          // 視点から判定線までの距離(射影する球の半径)
    
    private static var instance: Dimensions?        // 唯一のインスタンス
    
    private init(frame: CGRect) {           // インスタンスの作成をこのクラス内のみに限定する
        self.frame = frame
        // モデルに合わせるなら水平線は画面上端辺りが丁度いい？モデルに合わせるなら大きくは変えてはならない。
        self.horizonY = frame.height * 15 / 16              // モデル値
        self.judgeLineY = frame.width / 9
        self.iconButtonSize = frame.width / 16
        self.verticalDistance = horizonY - frame.width / 14
        self.R = sqrt(pow(horizontalDistance, 2) + pow(verticalDistance, 2))
        let laneHeight = horizonY - judgeLineY      // レーンの高さ(画面上)
        self.laneLength = pow(R, 2) / (verticalDistance / tan(laneHeight/R) - horizontalDistance)   // レーン長(3D)
    }
    
    private func update(laneNum: Int) {
        self.laneWidth = frame.width / CGFloat(laneNum + 2) // レーン両サイドの空白はレーン幅と同じ
        let horizonLength = 2 * horizontalDistance * atan(laneWidth! * CGFloat(laneNum)/2 / (horizontalDistance + laneLength))
        self.laneWidthOnHorizon = horizonLength / CGFloat(laneNum)
        self.horizonLeftX = frame.midX - horizonLength / 2
        
        buttonX = []
        // ボタンの位置をセット
        for i in 0..<laneNum {
            buttonX!.append(laneWidth! * (3/2) + CGFloat(i) * laneWidth!)
        }
        
        let halfBound = laneWidth! * (9/10)                  // 判定を汲み取る、ボタン中心からの距離。laneWidth/2 ~ laneWidth の値にすること
        self.judgeRects = buttonX!.map { CGRect(x: $0 - halfBound, y: frame.height / 2, width: halfBound * 2 , height: frame.height / 2) }
    }
    
    // これらクラスプロパティから、定数にアクセスする(createInstanceされてなければ全て0)
    static var frameMidX:          CGFloat         { return Dimensions.instance?.frame.midX         ??  CGFloat(0) }
    static var horizonLeftX:       CGFloat         { return Dimensions.instance?.horizonLeftX       ??  CGFloat(0) }
    static var horizonY:           CGFloat         { return Dimensions.instance?.horizonY           ??  CGFloat(0) }
    static var laneWidth:          CGFloat         { return Dimensions.instance?.laneWidth          ??  CGFloat(0) }
    static var laneWidthOnHorizon: CGFloat         { return Dimensions.instance?.laneWidthOnHorizon ??  CGFloat(0) }
    static var laneLength:         CGFloat         { return Dimensions.instance?.laneLength         ??  CGFloat(0) }
    static var judgeLineY:         CGFloat         { return Dimensions.instance?.judgeLineY         ??  CGFloat(0) }
    static var iconButtonSize:     CGFloat         { return Dimensions.instance?.iconButtonSize     ??  CGFloat(0) }
    static var horizontalDistance: CGFloat         { return Dimensions.instance?.horizontalDistance ??  CGFloat(0) }
    static var verticalDistance:   CGFloat         { return Dimensions.instance?.verticalDistance   ??  CGFloat(0) }
    static var R:                  CGFloat         { return Dimensions.instance?.R                  ??  CGFloat(0) }
    static var buttonX:           [CGFloat]        { return Dimensions.instance?.buttonX            ?? [CGFloat]() }
    static var judgeRects:        [CGRect]         { return Dimensions.instance?.judgeRects         ?? [CGRect]()  }
    
    // この関数のみが唯一Dimensionsクラスをインスタンス化できる
    static func createInstance(frame: CGRect) {
        // 初回のみ有効
        if self.instance == nil {
            self.instance = Dimensions(frame: frame)
        }
    }
    
    /// レーン数依存の定数を設定
    static func updateInstance(laneNum: Int) {
        self.instance?.update(laneNum: laneNum)
    }
}


