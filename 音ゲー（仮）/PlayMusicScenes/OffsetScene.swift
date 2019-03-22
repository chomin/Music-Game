//
// Created by Kohei Nakai on 2019-03-19.
// Copyright (c) 2019 NakaiKohei. All rights reserved.
//

import SpriteKit
import AVFoundation

class OffsetScene: PlayMusicScene {

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)

        autoJudgeAllLanes()
    }

    func restartScene() {
        let scene = OffsetScene(size: size, setting: setting, music: music)
        let skView = view as SKView?
        skView?.showsFPS = true
        skView?.showsNodeCount = true
        skView?.ignoresSiblingOrder = true
        scene.scaleMode = .resizeFill
        skView?.presentScene(scene)
    }

    /// AVAudioPlayerの再生終了時の呼び出しメソッド
    override func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {    // playしたクラスと同じクラスに入れる必要あり？
        if player as AVAudioPlayer? == BGM {
            BGM = nil   // 別のシーンでアプリを再開したときに鳴るのを防止
            restartScene()
        }
    }
}
