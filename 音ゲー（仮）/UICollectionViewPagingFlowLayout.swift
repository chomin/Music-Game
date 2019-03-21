//
//  UICollectionViewPagingFlowLayout.swift
//  Gemini
//
//  Created by shoheoyokoyama on 2017/07/02.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//
import UIKit

final class UICollectionViewPagingFlowLayout: UICollectionViewFlowLayout {
//    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
//        guard let collectionView = collectionView else { return proposedContentOffset }
//
//        let offset = isVertical ? collectionView.contentOffset.y : collectionView.contentOffset.x
//        let velocity = isVertical ? velocity.y : velocity.x
//
//        let flickVelocityThreshold: CGFloat = 0.2
//        let currentPage = offset / pageSize
//
//        if abs(velocity) > flickVelocityThreshold {
//            print(currentPage)
//            let nextPage = velocity > 0.0 ? ceil(currentPage) : floor(currentPage)
//            let nextPosition = nextPage * pageSize
//            return isVertical ? CGPoint(x: proposedContentOffset.x, y: nextPosition) : CGPoint(x: nextPosition, y: proposedContentOffset.y)
//        } else {
//            let nextPosition = round(currentPage) * pageSize
//            return isVertical ? CGPoint(x: proposedContentOffset.x, y: nextPosition) : CGPoint(x: nextPosition, y: proposedContentOffset.y)
//        }
//    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        if let collectionViewBounds = self.collectionView?.bounds {
            let halfHeightOfVC = collectionViewBounds.size.height * 0.5
            let proposedContentOffsetCenterY = proposedContentOffset.y + halfHeightOfVC
            
            if let attributesForVisibleCells = self.layoutAttributesForElements(in: collectionViewBounds) {
                var candidateAttribute : UICollectionViewLayoutAttributes?
                
                for attributes in attributesForVisibleCells {
                    let candAttr : UICollectionViewLayoutAttributes? = candidateAttribute
                    if candAttr != nil {
                        let a = abs(attributes.center.y - proposedContentOffsetCenterY)
                        let b = abs(candAttr!.center.y - proposedContentOffsetCenterY)
                        if a < b {
                            candidateAttribute = attributes
                        }
                    } else {
                        candidateAttribute = attributes
                        continue
                    }
                }
                
                if candidateAttribute != nil {
                    return CGPoint(x: proposedContentOffset.x, y: candidateAttribute!.center.y - halfHeightOfVC);
                }
            }
        }
        return CGPoint.zero
    }
    
    private var isVertical: Bool {
        return scrollDirection == .vertical
    }
    
    private var pageSize: CGFloat {
        if isVertical {
            return itemSize.height + minimumInteritemSpacing
        } else {
            return itemSize.width + minimumLineSpacing
        }
    }
}
