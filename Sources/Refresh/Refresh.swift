
import UIKit

var RefreshHeaderObjcKey = 0
var RefreshFooterObjcKey = 0


extension UIScrollView {
    public var header: RefreshHeader? {
        get {
            objc_getAssociatedObject(self, &RefreshHeaderObjcKey) as? RefreshHeader
        }
        set {
            guard header == nil else {
                return
            }
            if let newValue = newValue {
                insertSubview(newValue, at: 0)
            }
            objc_setAssociatedObject(self,
                                     &RefreshHeaderObjcKey, newValue,
                                     .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    
    public var footer: RefreshFooter? {
        get {
            objc_getAssociatedObject(self, &RefreshFooterObjcKey) as? RefreshFooter
        }
        set {
            guard footer == nil else {
                return
            }
            if let newValue = newValue {
                insertSubview(newValue, at: 0)
            }
            objc_setAssociatedObject(self,
                                     &RefreshFooterObjcKey,
                                     newValue,
                                     .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}
