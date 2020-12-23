//
//  RefreshHeader.swift
//  
//
//  Created by 周伟克 on 2020/12/23.
//

import UIKit

public class RefreshHeader: RefreshComponment {
    
    override func stateDidChanage(pre: RefreshState, now: RefreshState) {
        super.stateDidChanage(pre: pre, now: now)
        if now == .refreshing {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.25) {
                    self.pullingPercent = 1
                    self.scrollView!.contentOffset.y -= self.frame.height
                    self.scrollView!.contentInset.top += self.frame.height
                }
            }
            action()
            beginRotation()
            if needFeekBack, #available(iOS 10.0, *) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        } else if now == .willRefreshing {
//            beginRotation()
        } else {
            stopRotation()
            if now == .idle, pre == .refreshing {
                UIView.animate(withDuration: 0.25) {
                    self.pullingPercent = 0
                    self.scrollView!.contentInset.top -= self.frame.height
                }
            }
        }
    }
    
    override func contentOffsetDidChange(_ offset: CGPoint) {
        super.contentOffsetDidChange(offset)
        guard state != .refreshing else {
            return
        }
        let scrolled = -offset.y - insetTop
        if scrolled >= frame.height {
            state = .willRefreshing
            pullingPercent = 1
        } else if scrolled > 0 {
            state = .pulling
            pullingPercent = scrolled / frame.height
        } else {
            state = .idle
        }
    }
    
    var needFeekBack = false
    
    override func panStatusDidChange(_ panState: UIGestureRecognizer.State) {
        super.panStatusDidChange(panState)
        if panState == .ended, state == .willRefreshing {
            needFeekBack = true
            beginRefreshing()
        }
    }
    
    public override var frame: CGRect {
        didSet {
            super.frame.size.height = RefreshDefaultHeight
            super.frame.origin.y = -RefreshDefaultHeight
        }
    }
}
