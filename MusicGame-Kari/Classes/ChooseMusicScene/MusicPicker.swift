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
    func selectedMusicDidChange(to selectedHeader: Header)
}


class MusicPicker: NSObject {
    
    private var collectionView: GeminiCollectionView!
    private let headers: [Header]
    private let numMusics: Int
    private let initialIndex: Int
    private var isFirstCell = true
    private var centerCell: UICollectionViewCell?
    private var dupFactor = 4              // 無限スクロールのために実際の数の何倍のセルを用意するか
    private var cellItemsHeight: CGFloat!  // 複製前のセル集合の高さ
    var mpDelegate: MusicPickerDelegate?

    init(headers: [Header], initialIndex: Int) {
        let numVisibleCells = 7  // 表示されているセルの数。layout.itemSizeの変更などで変わる可能性あり
        let dup = Int(ceil(Double(numVisibleCells) / Double(headers.count)))  // 画面を埋めるためにheaderを何倍に複製するか
        // 曲が少ない場合、_headersを複製して水増し
        self.headers = {
            var hs: [Header] = []
            for _ in 0..<dup {
                hs += headers
            }
            return hs
        }()
        self.numMusics = headers.count * dup
        self.initialIndex = initialIndex
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
    
    func update() {
        let contentOffsetCenterY = collectionView.contentOffset.y + collectionView.frame.midY
        // 中央に最も近いセルが入れ替わっていたら選択曲を更新
        if let cell = collectionView.visibleCells.min(by: {
            abs($0.center.y - contentOffsetCenterY) < abs($1.center.y - contentOffsetCenterY)
        }), cell != centerCell {
            if let indexPath = collectionView.indexPath(for: cell), centerCell != nil {
                mpDelegate?.selectedMusicDidChange(to: headers[indexPath.item % numMusics])
            }
            self.centerCell = cell
        }
    }

    func removeFromParent() {
        collectionView.removeFromSuperview()
    }
    
    func fix() {
        collectionView.isScrollEnabled = false
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


// UIScrollViewDelegate を実装 (UICollectionViewDelegate が UIScrollViewDelegate を継承している)
extension MusicPicker {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        collectionView.animateVisibleCells()
        guard cellItemsHeight != nil else {
            return
        }
        // スクロールした位置がしきい値を超えたら中央に戻す
        if (scrollView.contentOffset.y <= cellItemsHeight) {
            scrollView.contentOffset.y += cellItemsHeight
        } else if (scrollView.contentOffset.y > cellItemsHeight * 3.0) {
            scrollView.contentOffset.y -= cellItemsHeight
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
        return numMusics * dupFactor  // 無限スクロールのために実際の数の数倍のセルを用意
    }
    
    // セルを作成
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MusicNameCell", for: indexPath) as! MusicNameCell
        cell.configure(header: headers[indexPath.item % numMusics])
        self.collectionView.animateCell(cell)

        // Cell が一つでも生成されてないと scrollToItem() が使えないみたいなのでフラグで制御
        if isFirstCell {
            let indexPath = IndexPath(row: numMusics + initialIndex, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)  // セルの初期位置を補正
            self.cellItemsHeight = floor(collectionView.contentSize.height / CGFloat(dupFactor))  // 表示したい要素群のheightを計算
            isFirstCell = false
        }

        return cell
    }
    
    // cell選択時の処理
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
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
        self.titleLabel = UILabel(frame: self.contentView.frame)
        titleLabel.textColor = UIColor.black
        titleLabel.textAlignment = .center
        self.contentView.addSubview(titleLabel)
    }

    fileprivate func configure(header: Header) {
        titleLabel.text = header.title

        switch header.group {
        case "BDGP": titleLabel.backgroundColor = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.5)
        case "CGSS": titleLabel.backgroundColor = UIColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 0.5)
        case "MLTD": titleLabel.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 0.7)
        case "ORIG": titleLabel.backgroundColor = UIColor(red: 0.5, green: 1.0, blue: 0.3, alpha: 0.7)
        default:
            print("unknown group")
        }

    }
}
