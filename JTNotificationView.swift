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
    var presentedNotification: JTNotificationView? = nil; // the one currently showing
    var notificationQueue: [JTNotificationView] = []; //items to present
    let notificationController = JTNotificationViewController();
    
    func setupWindow() {
        notificationController.setupWindow();
    }
    
    
    func show(notification: JTNotificationView,  animated: Bool = true) {
        if (presentedNotification != nil) {
            notificationQueue.append(notification);
        } else {
            presentedNotification = notification;
            notification.notificationManager = self; //NOTE:(tihon) 2015-10-29 maybe this should be in the controller?
            notificationController.show(notification, animated: animated);
        }
        
    }
    
    func dismiss(notification: JTNotificationView, animated: Bool = true) {
        //if presenting, tear it down. then present the next one in the queue.
        if notification == presentedNotification {
            notificationController.dismiss(notification, animated: animated);
            presentedNotification = nil;
        } else if let index = notificationQueue.indexOf(notification) {
            notificationQueue.removeAtIndex(index);
            print ("removed notification from queue");
        } else {
            print ("notification not in queue!");
        }
        //now handle any other pending ones...
        processNextNotification(animated);
    }
    
    func dismissAll(animated: Bool = true) {
        if let notification = presentedNotification {
            notificationController.dismiss(notification, animated: animated);
            presentedNotification = nil;
        }
        notificationQueue.removeAll();
        print ("removed all pending notifications");
    }
    
    //checks for pending notifications and presents the next one in the queue
    internal func processNextNotification(animated: Bool) {
        if (presentedNotification != nil) {
            // don't do anything
            return;
        } else if (notificationQueue.count > 0) {
            // pop the top notif and present it
            let topNotification = notificationQueue.removeFirst();
            self.show(topNotification, animated: animated);
        } else {
            print ("nothing to show.");
        }
    }
}


// This class is only responsible for presenting itself. It is not responsible for dealing with multiple presentations
class JTNotificationViewController : UIViewController {
    var passThroughView: JTPassThroughView?;
    let notificationWindow = JTOverlayWindow(frame: UIScreen.mainScreen().bounds);
    
    var animationDuration = 0.3;
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent;
    }
    
    func setupWindow() {
        notificationWindow.windowLevel = UIWindowLevelStatusBar;
        notificationWindow.rootViewController = self;
    }
    
    func teardownWindow() {
        notificationWindow.resignKeyWindow();
        notificationWindow.rootViewController = nil;
        //send an update to the parent view controller...
        if let topRootViewController = UIApplication.sharedApplication().keyWindow?.rootViewController {
            topRootViewController.setNeedsStatusBarAppearanceUpdate();
        }
    }
    
    func show(notification:JTNotificationView, animated:Bool) -> Void {
        if passThroughView == nil {
            // add the pass-through view
            let passThrough = JTPassThroughView(frame: UIScreen.mainScreen().bounds);
            passThrough.hidden = false;
            passThrough.autoresizingMask = [.FlexibleWidth, .FlexibleHeight];
            
            passThroughView = passThrough;
            notificationWindow.addSubview(passThrough);
        }
        notificationWindow.hidden = false;
        
        //add self to visible errors
        
        notificationWindow.addSubview(notification);
        
        
        let animationBlock = { () -> Void in
            notification.frame.origin.y = 0
        };
        
        // NOTE(tihon) 2015-10-29: work-around Swift compiler bug where it can't infer the type of the closure.
        let completionBlock: (Bool) -> Void = { (Bool) -> Void in
        };
        
        if animated {
            UIView.animateWithDuration(animationDuration, animations:{ () -> Void in
                animationBlock();
                self.setNeedsStatusBarAppearanceUpdate();
                },
                completion:completionBlock);
        } else {
            animationBlock();
            completionBlock(true);
        }
    }
    
    
    func dismiss(notification:JTNotificationView, animated:Bool = true) {
        // check if presenting it. if so, go through this. otherwise just remove from the queue
        
        print("dismiss");
        func completion() {
            notification.removeFromSuperview();
            teardownWindow();
        }
        if animated{
            UIView.animateWithDuration(animationDuration, animations: { () -> Void in
                notification.frame.origin.y = -notification.notifHeight;
                }, completion: { (Bool) -> Void in
                    completion();
            });
        } else {
            completion();
        }
    }
}

class JTNotificationView : UIView {
    var text :String!;
    let notifHeight: CGFloat! = 64.0 + 20;
    let fontSize: CGFloat! = 14.0;
    let iconWidth = 43.0;
    
    let imageView = UIImageView();
    let label = UILabel();
    let labelTextNumberOfLines = 2;
    let closeButton = UIButton(type: .System);
    weak var notificationManager: JTNotificationManager? = nil; //NOTE:(tihon) 2015-10-29 this must be set if presenting. This should conform to a protocol instead.
   
    var openAction: (()->Void)? = nil;
    
    override init(frame: CGRect) {
        super.init(frame: frame);
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
    }
    
    init(text:String!, icon:UIImage!, openAction:()->Void) {
        let frame = CGRectMake(0, -notifHeight, UIScreen.mainScreen().bounds.width, notifHeight);
        super.init(frame: frame);
        
        self.translatesAutoresizingMaskIntoConstraints = true;
        self.text = text;
        
        let closeTitle = "✕";
        self.closeButton.setTitle(closeTitle, forState: .Normal);
        self.closeButton.setTitleColor(UIColor.whiteColor(), forState: .Normal);
        self.closeButton.setTitle(closeTitle, forState: .Highlighted);
        self.closeButton.titleLabel!.font = UIFont.boldSystemFontOfSize(22.0);
        self.closeButton.titleLabel!.sizeToFit();
        self.closeButton.translatesAutoresizingMaskIntoConstraints = false;
        self.closeButton.addTarget(self, action: "dismiss", forControlEvents: .TouchUpInside);
        
        self.imageView.image = icon;
        self.imageView.translatesAutoresizingMaskIntoConstraints = false;
        
      
        self.label.adjustsFontSizeToFitWidth = true;
        self.label.numberOfLines = labelTextNumberOfLines;
        self.label.font = UIFont.systemFontOfSize(fontSize);
        self.label.textColor = UIColor.whiteColor();
        self.label.text = text;
        self.label.sizeToFit();
        self.label.translatesAutoresizingMaskIntoConstraints = false;
        
        self.addSubview(self.imageView);
        self.addSubview(self.label);
        self.addSubview(self.closeButton);
        
        self.openAction = openAction;
        
        
        self.userInteractionEnabled = true;
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "runOpenAction");
        self.addGestureRecognizer(tapRecognizer);
        
        backgroundColor = UIColor(white: 0.0, alpha: 0.75);
        
        self.setNeedsUpdateConstraints();
    }
   
    override func updateConstraints() {
       //add the layout constraints
        
        let views = [
            "icon": self.imageView,
            "button": self.closeButton,
            "textLabel": self.label];
        
        let metrics = ["padding": 20.0,
                        "iconWidth": iconWidth,
                        "vPadding":3.0,
                        "closeWidth":25.0,
                        "statusBarHeight": 20.0,
        ];
        
        
        let vLayout = NSLayoutConstraint.constraintsWithVisualFormat("V:|-statusBarHeight-[textLabel]-vPadding-|", options: .AlignAllCenterX, metrics: metrics, views: views);
        self.addConstraints(vLayout);
        
        let layout = NSLayoutConstraint.constraintsWithVisualFormat("|-(padding)-[icon(iconWidth)]-[textLabel]-[button(closeWidth)]-(padding)-|", options: .AlignAllCenterY, metrics: metrics, views: views);
        self.addConstraints(layout);
        
        super.updateConstraints();
    }
    
    func runOpenAction() {
        if let openAction = self.openAction {
            openAction();
        }
        dismiss();
    }
   
    internal func dismiss() {
        if let manager = self.notificationManager {
            manager.dismiss(self);
        }
    }
}

internal class JTOverlayWindow : UIWindow {
    
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, withEvent: event);
        if let _ = result as? JTPassThroughView {
            // NOTE(tihon) 2015-10-25: call the manager to dismiss
            print("passthrough view");
//            JTNotificationViewController.notificationController.dismissTopError(true);
            return nil;
        }
        return result;
    }
}

internal class JTPassThroughView : UIView {
    
}