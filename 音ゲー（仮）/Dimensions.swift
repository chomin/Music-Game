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
/// YouTube付きのものを追加する際は、getPickerArray()内のif分岐　及び　VideoID列挙型　への追加を忘れずに
enum MusicName: String, EnumCollection {
    
    case shugabita              = "シュガーソングとビターステップ"
    case yo_kosoJapariParkHe    = "ようこそジャパリパークへ"
    case oracion                = "オラシオン"
    case thisGame               = "This game"
    case sakuraSkip             = "SAKURAスキップ"
    case zankokuNaTenshiNoThese = "残酷な天使のテーゼ"
    case nimenseiUraomoteLife   = "にめんせい☆ウラオモテライフ！"
    case ready                  = "READY!!"
    case jibunRestart           = "自分REST@RT"
    case thankYou               = "Thank You!"
    case welcome                = "Welcome!!"
    case brandNewTheater        = "Brand New Theater!"
    case buonAppetitoS          = "ぼなぺてぃーとS"
    case level5                 = "LEVEL5-Judgelight-"
    
    static func getPickerArray() -> [String] {
        
        var pickerArray: [String] = []
        
        for musicName in MusicName.allValues {
            pickerArray.append(musicName.rawValue)
            
            // YouTubeを実装しているものについてはYouTubeモードをピッカーに追加
            if musicName == .yo_kosoJapariParkHe ||
                musicName == .oracion ||
                musicName == .sakuraSkip ||
                musicName == .nimenseiUraomoteLife ||
                musicName == .level5 {
                
                pickerArray.append(musicName.rawValue + "(YouTube)")
            }
        }
        return pickerArray
    }
}

/// rawvalueがYouTubeのvideoIDに対応する列挙型
/// YouTubeを追加する際は MusicName.getPickerArray()のif分岐 への追加も忘れないように
enum VideoID: String {  // VideoIDの列挙型(https://www.youtube.com/watch?v=************の***********部分)
    
    case yo_kosoJapariParkHe  = "xkMdLcB_vNU"
    case oracion              = "6kQzRm21N_g"
    case uracion              = "fF6c1gqutjs"
    case sakuraSkip           = "dBwwipunJcw"
    case nimenseiUraomoteLife = "TyMx4pu7kA0"
    case buonAppetitoS        = "LOajYHKEHG8"
    case level5               = "1NYUKIZCV5k"
    
    /*
     "ぼなぺてぃーとS": 埋め込み許可されているアニメ版が見つからず
     
     */
    
    
}

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

/// 寸法に関する定数を提供(シングルトン)。GameSceneのframeをもとに決定される。
class Dimensions {
    //インスタンスが保持し、このクラス内からの記述でのみアクセスできる変数。staticで呼び出されたときにこれらに格納されている値を返す。(frameが不要なものは初期値をここで定義)
    private let horizonLength: CGFloat              // 水平線の長さ
    private let horizonY: CGFloat                   // 水平線のy座標
    private let laneWidth: CGFloat                  // 3D上でのレーン幅(判定線における2D上のレーン幅と一致)
    private let laneLength: CGFloat                 // 3D上でのレーン長
    private let judgeLineY: CGFloat                 // 判定線のy座標
    private let buttonHeight: CGFloat               // ボタンの高さ(上の境界のy座標)
    private var buttonX: [CGFloat] = []             // 各レーンの中心のx座標
    private var judgeXRanges: [Range<CGFloat>] = [] // 各レーンの判定をするx座標についての範囲
    // 立体感を出すための定数
    private let horizontalDistance: CGFloat = 250   // 画面から目までの水平距離a（約5000で10cmほど）
    private let verticalDistance: CGFloat           // 画面を垂直に見たとき、判定線から目までの高さh（実際の水平線の高さでもある）
    private let R: CGFloat                          // 視点から判定線までの距離(射影する球の半径)
    
    private static var instance: Dimensions?        // 唯一のインスタンス
    
    private init(frame: CGRect) {   // インスタンスの作成をこのクラス内のみに限定する
        let halfBound = frame.width / 10   // 判定を汲み取る、ボタン中心からの距離。1/18~1/9の値にすること
        self.laneWidth = frame.width / 9
        // モデルに合わせるなら水平線は画面上端辺りが丁度いい？モデルに合わせるなら大きくは変えてはならない。
        self.horizonY = frame.height * 15 / 16  // モデル値
        self.judgeLineY = frame.width / 9
        self.buttonHeight = self.judgeLineY * 2
        self.verticalDistance = horizonY - frame.width / 14
        self.R = sqrt(pow(horizontalDistance, 2) + pow(verticalDistance, 2))
        
        let laneHeight = horizonY - judgeLineY              // レーンの高さ(画面上)
        self.laneLength = pow(R, 2) / (verticalDistance / tan(laneHeight/R) - horizontalDistance)   // レーン長(3D)
        self.horizonLength = 2 * horizontalDistance * atan(laneWidth * 7/2 / (horizontalDistance + laneLength))
        
        // ボタンの位置をセット
        for i in 0...6 {
            buttonX.append(frame.width/6 + CGFloat(i)*laneWidth)
        }
        
        self.judgeXRanges = buttonX.map({ $0 - halfBound ..< $0 + halfBound })
    }
    
    // これらクラスプロパティから、定数にアクセスする(createInstanceされてなければ全て0)
    static var horizonLength:      CGFloat         { return Dimensions.instance?.horizonLength      ??  CGFloat(0)        }
    static var horizonY:           CGFloat         { return Dimensions.instance?.horizonY           ??  CGFloat(0)        }
    static var laneWidth:          CGFloat         { return Dimensions.instance?.laneWidth          ??  CGFloat(0)        }
    static var laneLength:         CGFloat         { return Dimensions.instance?.laneLength         ??  CGFloat(0)        }
    static var judgeLineY:         CGFloat         { return Dimensions.instance?.judgeLineY         ??  CGFloat(0)        }
    static var buttonHeight:       CGFloat         { return Dimensions.instance?.buttonHeight       ??  CGFloat(0)        }
    static var horizontalDistance: CGFloat         { return Dimensions.instance?.horizontalDistance ??  CGFloat(0)        }
    static var verticalDistance:   CGFloat         { return Dimensions.instance?.verticalDistance   ??  CGFloat(0)        }
    static var R:                  CGFloat         { return Dimensions.instance?.R                  ??  CGFloat(0)        }
    static var buttonX:           [CGFloat]        { return Dimensions.instance?.buttonX            ?? [CGFloat]()        }
    static var judgeXRanges:      [Range<CGFloat>] { return Dimensions.instance?.judgeXRanges       ?? [Range<CGFloat>]() }
    // この関数のみが唯一Dimensionsクラスをインスタンス化できる
    static func createInstance(frame: CGRect) {
        // 初回のみ有効
        if self.instance == nil {
            self.instance = Dimensions(frame: frame)
        }
    }
}

