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
    
    private var collectionView: GeminiCollectionView!
    private let headers: [Header]
    var selectedHeader: Header
    var mpDelegate: MusicPickerDelegate?
    
    init(headers: [Header]) {
        self.headers = headers
        self.selectedHeader = headers.first!
        super.init()
    }
    
    func didMove(to view: SKView) {
        self.collectionView = {
            let layout = UICollectionViewPagingFlowLayout()
            layout.scrollDirection = .vertical
            layout.itemSize = CGSize(width: 300, height: 50)
            layout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)  // cellの上下左右の余白
//            layout.minimumLineSpacing = 10
            layout.minimumInteritemSpacing = 10
            
            let frame = CGRect(x: 0, y: 0, width: view.frame.width / 2, height: view.frame.height)
            return GeminiCollectionView(frame: frame, collectionViewLayout: layout)
        }()
        collectionView.backgroundColor = .white
        collectionView.register(MusicNameCell.self, forCellWithReuseIdentifier: "MusicNameCell")
        collectionView.showsVerticalScrollIndicator = false
        collectionView.allowsSelection = true
//        collectionView.decelerationRate = UIScrollView.DecelerationRate.fast
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.gemini
            .scaleAnimation()
            .scale(0.5)
            .scaleEffect(.scaleUp)
            .ease(.easeOutQuart)
        view.addSubview(collectionView)
    }
    
    func removeFromParent() {
        collectionView.removeFromSuperview()
    }
}


// UIScrollViewDelegate
extension MusicPicker {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        collectionView.animateVisibleCells()
        let cellItemsHeight = floor(scrollView.contentSize.height / 3.0)  // 表示したい要素群のwidthを計算
        if (scrollView.contentOffset.y <= 0.0) || (scrollView.contentOffset.y > cellItemsHeight * 2.0) {  // スクロールした位置がしきい値を超えたら中央に戻す
            scrollView.contentOffset.y = cellItemsHeight
        }
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
        return self.headers.count * 3  // 無限スクロールのために実際の数の3倍のセルを用意
    }
    
    // セルを作成
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MusicNameCell", for: indexPath) as! MusicNameCell

        cell.titleLabel.text = self.headers[indexPath.item % headers.count].title

        self.collectionView.animateCell(cell)
        return cell
    }
    
    // cell選択時の処理
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = indexPath.item % self.headers.count
        self.selectedHeader = headers[index]
        self.collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredVertically, animated: true)
    }
}


//// Inherite GeminiCell
class MusicNameCell: GeminiCell {
    var titleLabel: UILabel!

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        titleLabel = UILabel(frame: self.contentView.frame)
        titleLabel.textColor = UIColor.black
        titleLabel.backgroundColor = .lightGray
        titleLabel.textAlignment = .center
        self.contentView.addSubview(titleLabel)
    }
}
