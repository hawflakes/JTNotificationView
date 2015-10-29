//
//  ViewController.swift
//  JTForegroundNotificationDemo
//
//  Created by Jack Tihon on 10/22/15.
//  Copyright © 2015 Jack Tihon. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    let button = UIButton();
    
    // NOTE(tihon) 2015-10-22: This window is used to present notifications and alerts.

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        button.translatesAutoresizingMaskIntoConstraints = false;
        
        let titleLabel = button.titleLabel as UILabel!;
        
        titleLabel.text = "Show Notification";
        titleLabel.font = UIFont.systemFontOfSize(24.0);
        titleLabel.textColor = UIColor.blackColor();
        
        button.frame = CGRectMake(0, 0, 200, 100);
        
        
        button.addTarget(self, action: "presentNotification", forControlEvents: .TouchUpInside);
    }
    
    override func viewWillAppear(animated: Bool) {
        JTNotificationViewController.setupWindow();
        self.view.addSubview(button);
        self.view.backgroundColor = UIColor.blueColor();
 
        button.backgroundColor = UIColor.grayColor();
        button.setTitle("Show Notification", forState: .Normal);
        button.setTitleColor(UIColor.blackColor(), forState: .Highlighted);
       
        let metrics = ["spacing": 20.0,
                        "buttonHeight": 40.0,
                        "hPadding": 40.0 ];
        let spacer = UIView();
        spacer.translatesAutoresizingMaskIntoConstraints = false;
        self.view.addSubview(spacer);
        
        let spacer2 = UIView();
        spacer2.translatesAutoresizingMaskIntoConstraints = false;
        self.view.addSubview(spacer2);
        
        let views = ["button": button,
                    "spacer": spacer,
                    "spacer2": spacer2];
        
        
        let verticalLayout = NSLayoutConstraint.constraintsWithVisualFormat("V:|-[spacer]-[button(buttonHeight)]-[spacer2(==spacer)]-|", options: .AlignAllLeft, metrics: metrics, views: views);
        self.view.addConstraints(verticalLayout);
        
        let hLayout = NSLayoutConstraint.constraintsWithVisualFormat("|-hPadding-[button]-hPadding-|", options: .AlignAllCenterX, metrics: metrics, views: views);
        self.view.addConstraints(hLayout);
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func presentNotification() {
        print("present notifcation");
        let image = ViewController.imageFromText("🐼",font:UIFont.systemFontOfSize(60), maxWidth: 40.0, color: UIColor.blueColor());
        let notif = JTNotificationView(text: "Steve Holm Assigned the lead Brian Crushing to you.", icon:image) {
            print("done.");
        };
        notif.show(true);
    }
   
    
    class func sizeOfAttributeString(str: NSAttributedString, maxWidth: CGFloat) -> CGSize {
        let size = str.boundingRectWithSize(CGSizeMake(maxWidth, 1000), options:(NSStringDrawingOptions.UsesLineFragmentOrigin), context:nil).size
        return size
    }
    
    class func imageFromText(text:String, font:UIFont, maxWidth:CGFloat, color:UIColor) -> UIImage {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraph.alignment = .Center // potentially this can be an input param too, but i guess in most use cases we want center align
        
        let attributedString = NSAttributedString(string: text, attributes: [NSFontAttributeName: font, NSForegroundColorAttributeName: color, NSParagraphStyleAttributeName:paragraph])
        
        let size = sizeOfAttributeString(attributedString, maxWidth: maxWidth)
        UIGraphicsBeginImageContextWithOptions(size, false , 0.0)
        attributedString.drawInRect(CGRectMake(0, 0, size.width, size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
