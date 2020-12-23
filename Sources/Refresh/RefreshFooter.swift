//
//  RefreshFooter.swift
//  
//
//  Created by 周伟克 on 2020/12/23.
//

import UIKit

public class RefreshFooter: RefreshComponment {
    
    override func stateDidChanage(pre: RefreshState, now: RefreshState) {
        super.stateDidChanage(pre: pre, now: now)
        if now == .refreshing {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.25) {
                    self.scrollView!.contentInset.bottom += self.frame.height
                }
                self.action()
                self.pullingPercent = 1
                self.beginRotation()
            }
        } else if now == .willRefreshing {
//            beginRotation()
        } else {
            self.stopRotation()
            if now == .idle, pre == .refreshing {
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.25) {
                        self.pullingPercent = 0
                        self.scrollView!.contentInset.bottom -= self.frame.height
                    }
                }
            }
        }
    }
    
    
    override func contentOffsetDidChange(_ offset: CGPoint) {
        if isHidden {
            return
        }
        super.contentOffsetDidChange(offset)
        // 拦截 .idle： 当内容超出scrollView的frame, endRefreshing 之后，scrollView在回弹的过程中重新触发.refreshing状态，大致原因是
        //             刷新结束，增加cellCount，reloadData(内部应该是有异步逻辑)之后立即访问contentSize，可能得到的是相对于reloadData之前更小的值(所以如果要想访问到正确的值
        //             最好异步访问，等待reloadData之后)， 从而导致convertY < scrollView!.frame.maxY - insetBottom，再次触发刷新
        
        guard state != .refreshing, state != .idle else {
            return
        }
        if scrollView!.contentSize.height <= scrollView!.frame.height - insetTop - insetBottom {
            if offset.y > -insetTop {
                state = scrollView!.isDragging ? .willRefreshing : .refreshing
                pullingPercent = -min(1, (offset.y + insetTop) / frame.height)
            } else {
                state = scrollView!.isDragging ? .pulling : .idle
            }
        } else if offset.y >= scrollView!.contentSize.height - (scrollView!.frame.height - insetBottom) {
            let beyondInsetBottom = offset.y - (scrollView!.contentSize.height - (scrollView!.frame.height - insetBottom))
            if beyondInsetBottom >= frame.height {
                state = scrollView!.isDragging ? .willRefreshing : .refreshing
                pullingPercent = -1
            } else {
                state = scrollView!.isDragging ? .pulling : .idle
                pullingPercent = -min(1, beyondInsetBottom / frame.height)
            }
        } else {
            state = scrollView!.isDragging ? .pulling : .idle
        }
    }
    
    override func contentSizeDidChange(_ contentSize: CGSize) {
        super.contentSizeDidChange(contentSize)
        frame.origin.y = contentSize.height
    }
    
    
    override func panStatusDidChange(_ panState: UIGestureRecognizer.State) {
        if isHidden {
            return
        }
        super.panStatusDidChange(panState)
        if panState == .began, state != .refreshing {
            state = .pulling
        }
    }
        
    public override var frame: CGRect {
        didSet {
            super.frame.size.height = RefreshDefaultHeight
        }
    }
}

