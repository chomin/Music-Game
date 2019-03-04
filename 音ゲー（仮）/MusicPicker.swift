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
    
    var collectionView: GeminiCollectionView!
    var mpDelegate: MusicPickerDelegate?
    let musics: [String]
    
    init(headers: [Header]) {
        musics = headers.map { $0.title }
        super.init()
    }
    
    func didMove(to view: SKView) {
        let layout: UICollectionViewPagingFlowLayout = {
            let layout = UICollectionViewPagingFlowLayout()
            layout.scrollDirection = .vertical
            layout.itemSize = CGSize(width: 500, height: 50)
            layout.sectionInset = UIEdgeInsets(top: 10, left: 100, bottom: 10, right: 100)  // cellの上下左右の余白
            layout.minimumLineSpacing = 20
            layout.minimumInteritemSpacing = 20
            return layout
        }()
        self.collectionView = GeminiCollectionView(frame: view.frame, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.white
        collectionView.register(MusicNameCell.self, forCellWithReuseIdentifier: "MusicNameCell")
        collectionView.showsVerticalScrollIndicator = false
        collectionView.allowsSelection = true
        collectionView.decelerationRate = UIScrollView.DecelerationRate.fast
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.gemini
            .scaleAnimation()
            .scale(0.75)
            .scaleEffect(.scaleUp)
            .ease(.easeOutQuart)
        view.addSubview(collectionView)
    }
}

// UIScrollViewDelegate
extension MusicPicker {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        collectionView.animateVisibleCells()
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
    
    // セルの数を返す
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.musics.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MusicNameCell", for: indexPath) as! MusicNameCell
        
        if !collectionView.subviews.contains(cell) {
            cell.setup(title: musics[indexPath.item])
            self.collectionView.addSubview(cell)
            print("cell added")
        }
        self.collectionView.animateCell(cell)
        return cell
    }
    
    // cell選択時の処理
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(collectionView.cellForItem(at: indexPath).debugDescription)
        //        collectionView.cellForItem(at: indexPath)?.isHighlighted = true
    }
}

// Inherite GeminiCell
class MusicNameCell: GeminiCell {
    private let titleLabel = UILabel()
    
    func setup(title: String) {
        titleLabel.text = title
        titleLabel.frame = self.frame
        titleLabel.textColor = UIColor.black
        titleLabel.backgroundColor = .lightGray
        titleLabel.textAlignment = .center
        self.addSubview(titleLabel)
    }
}
