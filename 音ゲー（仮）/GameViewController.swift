//
//  GameViewController.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//

//（9/11の成果が残っている？）

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
	
	super.viewDidLoad()
	let scene = ChooseMusicScene(size: view.bounds.size)
	let skView = view as! SKView
	skView.showsFPS = true
	skView.showsNodeCount = true
	skView.ignoresSiblingOrder = true
	scene.scaleMode = .resizeFill
	skView.presentScene(scene)  //ChooseMusicSceneに移動

    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
