//
// Created by Kohei Nakai on 2019-03-19.
// Copyright (c) 2019 NakaiKohei. All rights reserved.
//

import Foundation

class AutoPlayScene: PlayMusicScene {

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)

        autoJudgeAllLanes()

        // ラベルの更新
        comboLabel.text = String(result.combo)

//        pauseButton.isEnabled = true
    }
}
