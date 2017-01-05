//
//  JTNotificationView.swift
//  JTForegroundNotificationDemo
//
//  Created by Jack Tihon on 10/22/15.
//  Copyright © 2015 Jack Tihon. All rights reserved.
//

import Foundation
import UIKit

//MARK: JTNotificationManager class to manage presentation of toasts, notifications, and modals
class JTNotificationManager {
    weak var presentedNotification: JTNotificationView? = nil // the one currently showing
    var notificationQueue: [JTNotificationView] = [] //items to present
    let notificationController = NotificationViewController()
    
    func setupWindow() {
        notificationController.setupWindow()
    }
    
    
    func show(_ notification: JTNotificationView,  animated: Bool = true) {
        if (presentedNotification != nil) {
            notificationQueue.append(notification)
        } else {
            presentedNotification = notification
            notification.notificationManager = self //NOTE:(tihon) 2015-10-29 maybe this should be in the controller?
            notificationController.show(notification, animated: animated)
        }
        
    }
    
    func dismiss(_ notification: JTNotificationView, animated: Bool = true) {
        //if presenting, tear it down. then present the next one in the queue.
        if notification == presentedNotification {
            let teardownWhenDone = notificationQueue.count == 0
            notificationController.dismiss(notification, animated: animated, teardown: teardownWhenDone)
            presentedNotification = nil
        } else if let index = notificationQueue.index(of: notification) {
            notificationQueue.remove(at: index)
            print ("removed notification from queue")
        } else {
            print ("notification not in queue!")
        }
        //now handle any other pending ones...
        processNextNotification(animated)
    }
    
    func dismissAll(_ animated: Bool = true) {
        if let notification = presentedNotification {
            notificationController.dismiss(notification, animated: animated, teardown: true)
            presentedNotification = nil
        }
        notificationQueue.removeAll()
        print ("removed all pending notifications")
    }
    
    //checks for pending notifications and presents the next one in the queue
    internal func processNextNotification(_ animated: Bool) {
        if (presentedNotification != nil) {
            // don't do anything
            return
        } else if (notificationQueue.count > 0) {
            // pop the top notif and present it
            let topNotification = notificationQueue.removeFirst()
            self.show(topNotification, animated: animated)
        } else {
            print ("nothing to show.")
        }
    }
}


// This class is only responsible for presenting itself. It is not responsible for dealing with multiple presentations
internal class NotificationViewController : UIViewController {
    var passThroughView: PassThroughView?
    let notificationWindow = OverlayWindow(frame: UIScreen.main.bounds)
    
    var animationDuration = 0.3
    
    func setupWindow() {
        notificationWindow.windowLevel = UIWindowLevelStatusBar
        notificationWindow.rootViewController = self
        notificationWindow.isHidden = true
    }
    
    func teardownWindow() {
        notificationWindow.rootViewController = nil
        notificationWindow.isHidden = true
        //send an update to the parent view controller...
        if let topRootViewController = UIApplication.shared.keyWindow?.rootViewController {
            topRootViewController.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    func show(_ notification:JTNotificationView, animated:Bool) -> Void {
        self.view.isHidden = true //NOTE:(tihon) 2015-11-3 This HAX is here until we use the view itself as the passthrough.
        // without hiding the view, you have to dismiss the notification the first time.
        
        if passThroughView == nil {
            // add the pass-through view
            let passThrough = PassThroughView(frame: UIScreen.main.bounds)
            passThrough.isHidden = false
            passThrough.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            passThroughView = passThrough
            notificationWindow.addSubview(passThrough)
        }
        notificationWindow.isHidden = false
        
        //add self to visible errors
        
        notificationWindow.addSubview(notification)
        
        
        let animationBlock = { () -> Void in
            notification.frame.origin.y = 0
        }
        
        // NOTE(tihon) 2015-10-29: work-around Swift compiler bug where it can't infer the type of the closure.
        let completionBlock: (Bool) -> Void = { (Bool) -> Void in
        }
        
        if animated {
            UIView.animate(withDuration: animationDuration, animations:{ () -> Void in
                animationBlock()
                self.setNeedsStatusBarAppearanceUpdate()
                },
                completion:completionBlock)
        } else {
            animationBlock()
            completionBlock(true)
        }
    }
    
    
    func dismiss(_ notification:JTNotificationView, animated:Bool = true, teardown:Bool = true) {
        // check if presenting it. if so, go through this. otherwise just remove from the queue
        
        print("dismiss")
        func completion() {
            notification.removeFromSuperview()
            if (teardown) {
                teardownWindow()
            }
        }
        if animated{
            UIView.animate(withDuration: animationDuration, animations: { () -> Void in
                notification.frame.origin.y = -notification.notifHeight
                }, completion: { (Bool) -> Void in
                    completion()
            })
        } else {
            completion()
        }
    }

    class func topViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.keyWindow
        return topViewControllerWithRoot(keyWindow?.rootViewController)
    }
    
    // NOTE: (tihon) 2015-11-2: borrowed from `RaisinToast`
    class func topViewControllerWithRoot(_ root:UIViewController?) -> UIViewController? {
        if let navRoot = root as? UINavigationController {
            return topViewControllerWithRoot(navRoot.visibleViewController)
        } else if let root = root {
            if (root.presentedViewController != nil) && !(root.presentedViewController != nil) {
                return topViewControllerWithRoot(root.presentedViewController)
            }
        }
        return root
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        //check that we're not showing anything right now
        let presenting = self.view.subviews.contains{ (view) -> Bool in
            if view.isKind(of: JTNotificationView.self) {
                return true
            }
            return false
        }
        
        if presenting {
            return .lightContent // we're onscreen, so show our own
        }
        
        if let topVC = NotificationViewController.topViewController() {
            return topVC.preferredStatusBarStyle
        }
        return .lightContent
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        if let topVC = NotificationViewController.topViewController() {
            return topVC.supportedInterfaceOrientations
        }
        return super.supportedInterfaceOrientations
    }
    
}

let statusBarHeight = 0.0
class JTNotificationView : UIView {
    var text :String!
    var notifHeight: CGFloat! = 64.0 + CGFloat(statusBarHeight)
    let fontSize: CGFloat! = 14.0
    let iconWidth = 43.0
    
    let imageView = UIImageView()
    let label = UILabel()
    let labelTextNumberOfLines = 0
    let closeButton = UIButton(type: .system)
    weak var notificationManager: JTNotificationManager? = nil //NOTE:(tihon) 2015-10-29 this must be set if presenting. This should conform to a protocol instead.
   
    var openAction: (()->Void)? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(text:String!, icon:UIImage!, openAction:@escaping ()->Void) {
        let frame = CGRect(x: 0, y: -notifHeight, width: UIScreen.main.bounds.width, height: notifHeight)
        super.init(frame: frame)
        
        self.translatesAutoresizingMaskIntoConstraints = true
        self.text = text
        
        let closeTitle = "✕"
        self.closeButton.setTitle(closeTitle, for: UIControlState())
        self.closeButton.setTitleColor(UIColor.white, for: UIControlState())
        self.closeButton.setTitle(closeTitle, for: .highlighted)
        self.closeButton.titleLabel!.font = UIFont.boldSystemFont(ofSize: 22.0)
        self.closeButton.titleLabel!.sizeToFit()
        self.closeButton.translatesAutoresizingMaskIntoConstraints = false
        self.closeButton.addTarget(self, action: #selector(JTNotificationView.dismiss), for: .touchUpInside)
        
        self.imageView.image = icon
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        
      
        self.label.adjustsFontSizeToFitWidth = true
        self.label.numberOfLines = labelTextNumberOfLines
        self.label.font = UIFont.systemFont(ofSize: fontSize)
        self.label.textColor = UIColor.white
        self.label.text = text
        self.label.sizeToFit()
        self.label.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(self.imageView)
        self.addSubview(self.label)
        self.addSubview(self.closeButton)
        
        self.openAction = openAction
        
        
        self.isUserInteractionEnabled = true
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(JTNotificationView.runOpenAction))
        self.addGestureRecognizer(tapRecognizer)
        
        backgroundColor = UIColor(white: 0.0, alpha: 0.75)
        
        self.setNeedsUpdateConstraints()
    }
   
    override func updateConstraints() {
       //add the layout constraints
        
        let views = [
            "icon": self.imageView,
            "button": self.closeButton,
            "textLabel": self.label]
      
        let padding = 20.0
        let closeWidth = 25.0
        let closePadding = closeWidth + padding
        
        let metrics = ["padding": padding,
                        "iconWidth": iconWidth,
                        "vPadding":3.0,
                        "closeWidth":closeWidth,
                        "closePadding": closePadding,
                        "statusBarHeight": statusBarHeight,
        ]
        
        self.addConstraint(NSLayoutConstraint(item:closeButton, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1.0, constant: 0))
        
        let vLayout = NSLayoutConstraint.constraints(withVisualFormat: "V:|-statusBarHeight-[textLabel]-vPadding-|", options: .alignAllCenterX, metrics: metrics, views: views)
        self.addConstraints(vLayout)
        
        let layout = NSLayoutConstraint.constraints(withVisualFormat: "|-(padding)-[icon(iconWidth)]-[textLabel]-[button(closePadding)]-|", options: .alignAllCenterY, metrics: metrics, views: views)
        self.addConstraints(layout)
        
        super.updateConstraints()
    }
    
    internal func runOpenAction() {
        if let openAction = self.openAction {
            openAction()
        }
        dismiss()
    }
   
    internal func dismiss() {
        if let manager = self.notificationManager {
            manager.dismiss(self)
        }
    }
}

internal class OverlayWindow : UIWindow {
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        if let _ = result as? PassThroughView {
            // NOTE(tihon) 2015-10-25: call the manager to dismiss
            print("passthrough view")
            return nil
        }
        return result
    }
}

internal class PassThroughView : UIView {
    
}
