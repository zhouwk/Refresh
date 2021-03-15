//
//  RefreshComponment.swift
//  
//
//  Created by 周伟克 on 2020/12/23.
//

import UIKit

let RefreshKVOPanKeyPath = "state"
let RefreshKVOContenOffsetKeyPath = "contentOffset"
let RefreshKVOContentSizeKeyPath = "contentSize"
let RefreshDefaultHeight = CGFloat(30)

enum RefreshState {
    case idle, pulling, willRefreshing, refreshing
}

public typealias RefreshAction = () -> ()

public class RefreshComponment: UIView {
    
    let action: RefreshAction
    
    public var isRefreshing: Bool {
        state == .refreshing
    }
    
    var state = RefreshState.idle {
        didSet {
            guard oldValue != state else {
                return
            }
            DispatchQueue.main.async {
                self.stateDidChanage(pre: oldValue, now: self.state)
            }
        }
    }
    var insetTop: CGFloat {
        if #available(iOS 11.0, *) {
            return scrollView!.adjustedContentInset.top
        } else {
            return scrollView!.contentInset.top
        }
    }
    var insetBottom: CGFloat {
        if #available(iOS 11.0, *) {
            return scrollView!.adjustedContentInset.bottom
        }
        return scrollView!.contentInset.bottom
    }
    
    var pullingPercent = CGFloat(0) {
        didSet {
            imageView.layer.transform = CATransform3DMakeRotation(CGFloat.pi * 2 * pullingPercent, 0, 0, 1)
        }
    }
    
    var pan: UIPanGestureRecognizer?
    weak var scrollView: UIScrollView?

    let rotationAnimKey = "transform.rotation.z"
    let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
    


    public init(_ action: @escaping RefreshAction) {
        self.action = action
        super.init(frame: .zero)
        imageView.image = UIImage(named: "refresh", in: .module, compatibleWith: nil)
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        autoresizingMask = [.flexibleWidth]
        
    }

        
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        assert(superview == nil || superview is UIScrollView)
        if let superview = superview as? UIScrollView {
            scrollView = superview
            pan = superview.panGestureRecognizer
            kvo()
            frame.size.width = superview.frame.width
        }
    }
    
    public override func removeFromSuperview() {
        unkvo()
        // 免得scrollView无法释放
        scrollView = nil
        pan = nil
        super.removeFromSuperview()
    }
    
    func kvo() {
        scrollView?.addObserver(self,
                                forKeyPath: RefreshKVOContenOffsetKeyPath,
                                options: [.new, .old],
                                context: nil)
        pan?.addObserver(self, forKeyPath: RefreshKVOPanKeyPath,
                         options: .new,
                         context: nil)
        scrollView?.addObserver(self,
                                forKeyPath: RefreshKVOContentSizeKeyPath,
                                options: [.new, .old, .initial],
                                context: nil)
    }
        
    func unkvo() {
        // 注意： MJRefresh中kvo的建立与移除逻辑是弱引用了scrollView变量和强引用了pan = scrollView.pan,
        // 但是MJRefresh从父组件中移除的时候，弱引用的scrollview已经为nil, superview还在，
        // (superview as scrollView).pan是nil，所以保留了pan的强引用，且不使用scrollView变量移除kvo，
        // 感觉可能会触发野指针异常，但是MJRefresh确实没有crash过，可能是因为superview指向的地址没有被覆盖。
        
        // Refresh的kvo的建立和移除完全参考了MJRefresh的逻辑，如果尝试强引用scrollView，那么
        // 由于父子控件的相互强引用，导致refresh不能执行removeFromSuperView等一系列方法，从而无法确定
        // 移除kvo的时机
        superview?.removeObserver(self, forKeyPath: RefreshKVOContenOffsetKeyPath,
                                   context: nil)
        pan?.removeObserver(self, forKeyPath: RefreshKVOPanKeyPath, context: nil)
        superview?.removeObserver(self, forKeyPath: RefreshKVOContentSizeKeyPath)
    }
    
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == RefreshKVOContenOffsetKeyPath {
            let old = change![.newKey] as! CGPoint
            let new = change![.oldKey] as? CGPoint
            if old != new {
                contentOffsetDidChange(change![.newKey] as! CGPoint)
            }
        } else if keyPath == RefreshKVOPanKeyPath {
            panStatusDidChange(UIGestureRecognizer.State(rawValue: change![.newKey] as! Int)!)
        } else if keyPath == RefreshKVOContentSizeKeyPath {
            let old = change![.newKey] as! CGSize
            let new = change![.oldKey] as? CGSize
            if old != new {
                contentSizeDidChange(change![.newKey] as! CGSize)
            }
        }
    }
    
    public func beginRefreshing() {
        state = .refreshing
    }
    
    public func endRefreshing() {
        self.state = .idle
    }
    
    func stateDidChanage(pre: RefreshState, now: RefreshState) {}
    func contentOffsetDidChange(_ offset: CGPoint) {}
    func panStatusDidChange(_ state: UIGestureRecognizer.State) {}
    func contentSizeDidChange(_ contentSize: CGSize) {}
    func beginRotation() {
        guard imageView.layer.animation(forKey: rotationAnimKey) == nil else {
            return;
        }
        let anim = CABasicAnimation(keyPath: rotationAnimKey)
        anim.fromValue = imageView.layer.presentation()?.value(forKeyPath: rotationAnimKey)
        anim.toValue = CGFloat.pi * 2 + (anim.fromValue as? CGFloat ?? 0)
        anim.duration = 1
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        anim.repeatCount = .infinity
        imageView.layer.add(anim, forKey: rotationAnimKey)
    }
    
    func stopRotation() {
        if imageView.layer.animation(forKey: rotationAnimKey) != nil {
            imageView.layer.removeAnimation(forKey: rotationAnimKey)
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        imageView.center = CGPoint(x: frame.width * 0.5, y: frame.height * 0.5)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

