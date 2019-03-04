//
//  MusicPicker.swift
//  音ゲー（仮）
//
//  Created by 植田暢大 on 2019/02/26.
//  Copyright © 2019 NakaiKohei. All rights reserved.
//

import UIKit
import SpriteKit
import Gemini

protocol MusicPickerDelegate {
    
}

class MusicPicker: NSObject {
    
//    let collectionView = GeminiCollectionView(frame: CGRect(x: 100, y: 200, width: 500, height: 500))  // TODO: fix hard coding
    var collectionView: GeminiCollectionView!
    var mpDelegate: MusicPickerDelegate?
    
    let musics = ["one", "two", "three", "four", "five"]
    
    func didMove(to view: SKView) {
        let layout: UICollectionViewLayout = {
            let layout = UICollectionViewFlowLayout()
            layout.itemSize = CGSize(width: 150, height: 150)
            layout.sectionInset = UIEdgeInsets(top: 15,
                                               left: (view.bounds.width - 150) / 2,
                                               bottom: 15,
                                               right: (view.bounds.width - 150) / 2)
            layout.minimumLineSpacing = 15
            layout.scrollDirection = .vertical
            return layout
        }()
        self.collectionView = GeminiCollectionView(frame: view.frame, collectionViewLayout: layout)
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
//        self.collectionView.collectionViewLayout = {
//            let layout = UICollectionViewFlowLayout()
//            layout.itemSize = CGSize(width: 150, height: 150)
//            layout.sectionInset = UIEdgeInsets(top: 15,
//                                               left: (view.bounds.width - 150) / 2,
//                                               bottom: 15,
//                                               right: (view.bounds.width - 150) / 2)
//            layout.minimumLineSpacing = 15
//            layout.scrollDirection = .vertical
//            return layout
//        }()
        
        self.collectionView.gemini
            .customAnimation()
            .backgroundColor(startColor: UIColor(red: 38 / 255, green: 194 / 255, blue: 129 / 255, alpha: 1),
                             endColor: UIColor(red: 89 / 255, green: 171 / 255, blue: 227 / 255, alpha: 1))
            .ease(.easeOutSine)
            .cornerRadius(75)
        self.collectionView.animateVisibleCells()
        view.addSubview(collectionView)
    }
    
}

// UIScrollViewDelegate
extension MusicPicker {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.collectionView.animateVisibleCells()
    }
}

// Delegate を実装
extension MusicPicker: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? GeminiCell {
            self.collectionView.animateCell(cell)
        }
    }
}

// DataSourceを実装
extension MusicPicker: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.musics.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        cell.backgroundColor = .red
        
//        // Set image only when animation type is custom1
//        if animationType == .custom1 {
//            cell.configure(with: images[indexPath.row])
//        }
        
        self.collectionView.animateCell(cell as! GeminiCell)
        return cell
    }
}
