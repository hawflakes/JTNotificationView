//
//  JTNotificationView.swift
//  JTForegroundNotificationDemo
//
//  Created by Jack Tihon on 10/22/15.
//  Copyright © 2015 Jack Tihon. All rights reserved.
//

import Foundation
import UIKit

class JTNotificationView : UIView {
    static let notificationWindow = UIWindow(frame: UIScreen.mainScreen().bounds);
    var animationDuration = 0.3;
    
    var text :String!;
    let notifHeight: CGFloat! = 64.0;
    let fontSize: CGFloat! = 14.0;
    let iconWidth = 43.0;
    
    let imageView = UIImageView();
    let label = UILabel();
    let labelTextNumberOfLines = 2;
    let closeButton = UIButton(type: .System);
   
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
                        "closeWidth":25.0
        ];
        
        let vLayout = NSLayoutConstraint.constraintsWithVisualFormat("V:|-vPadding-[textLabel]-vPadding-|", options: .AlignAllCenterX, metrics: metrics, views: views);
        self.addConstraints(vLayout);
        
        let layout = NSLayoutConstraint.constraintsWithVisualFormat("|-(padding)-[icon(iconWidth)]-[textLabel]-[button(closeWidth)]-(padding)-|", options: .AlignAllCenterY, metrics: metrics, views: views);
        self.addConstraints(layout);
        
        super.updateConstraints();
    }
    
    var token: dispatch_once_t = 0

    func show(animated:Bool) {
        JTNotificationView.notificationWindow.hidden = false;
        JTNotificationView.notificationWindow.makeKeyAndVisible();
        JTNotificationView.notificationWindow.addSubview(self);
        
        if animated {
            UIView.animateWithDuration(animationDuration) { () -> Void in
                self.frame.origin.y = 0;
            }
        } else {
            self.frame.origin.y = 0;
        }
        
    }
    
    func dismiss() {
        self.dismiss(true);
    }
    
    func dismiss(animated:Bool = true) {
        print("dismiss");
        
        func completion() {
            self.removeFromSuperview();
            JTNotificationView.notificationWindow.resignKeyWindow();
            JTNotificationView.notificationWindow.hidden = true;
            JTNotificationView.notificationWindow.rootViewController = nil;
        }
        if animated{
            
            UIView.animateWithDuration(animationDuration, animations: { () -> Void in
                self.frame.origin.y = -self.notifHeight;
                }, completion: { (Bool) -> Void in
                    completion();
            });
        } else {
            completion();
        }
        
    }
    
    func runOpenAction() {
        if let openAction = self.openAction {
            openAction();
        }
        self.dismiss(true);
    }
    
    class func setupNotificationWindow() {
//        notificationWindow.windowLevel = UIWindowLevelStatusBar+2; //ensure we're above
        notificationWindow.windowLevel = UIWindowLevelStatusBar;
        notificationWindow.backgroundColor = UIColor(red: 1.0, green: 0, blue: 0, alpha: 0.8);
    }
}