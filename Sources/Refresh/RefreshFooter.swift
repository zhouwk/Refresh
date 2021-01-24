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
                self.pullingPercent = -1
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
        
        if state != .pulling && state != .willRefreshing {
            return
        }
        if scrollView!.contentSize.height <= scrollView!.frame.height - insetTop - insetBottom {
            // 内容不足一页
            if offset.y > -insetTop {
                // 向上拽动，拖动超过自身高度松手即可进入刷新
                pullingPercent = -min(1, (offset.y + insetTop) / frame.height)
            } else {
                // 向下拽动
                pullingPercent = 0
            }
        } else if offset.y >= scrollView!.contentSize.height - (scrollView!.frame.height - insetBottom) {
            // 内容超出一页，且scrollView所有的内容已经拉到底部安全区域之上(比如tabbar、homeIndicatorBar)
            let beyondInsetBottom = offset.y - (scrollView!.contentSize.height - (scrollView!.frame.height - insetBottom))
            pullingPercent = -min(1, beyondInsetBottom / frame.height)
        } else {
            pullingPercent = 0
        }
        if scrollView!.isDragging {
            state = .pulling
        } else if pullingPercent == -1 {
            state = .refreshing
        } else if pullingPercent == 0 {
            state = .idle
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

