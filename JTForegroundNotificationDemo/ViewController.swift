//
//  ViewController.swift
//  JTForegroundNotificationDemo
//
//  Created by Jack Tihon on 10/22/15.
//  Copyright © 2015 Jack Tihon. All rights reserved.
//

import UIKit

let notificationManager = JTNotificationManager();

class ViewController: UIViewController {
    let button = UIButton();
    var count = 0;
    // NOTE(tihon) 2015-10-22: This window is used to present notifications and alerts.

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        button.translatesAutoresizingMaskIntoConstraints = false;
        
        let titleLabel = button.titleLabel as UILabel!;
        
        titleLabel?.text = "Show Notification";
        titleLabel?.font = UIFont.systemFont(ofSize: 24.0);
        titleLabel?.textColor = UIColor.black;
        
        button.frame = CGRect(x: 0, y: 0, width: 200, height: 100);
        
        
        button.addTarget(self, action: #selector(ViewController.presentNotification), for: .touchUpInside);
    }
   
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        notificationManager.setupWindow();
        self.view.addSubview(button);
        self.view.backgroundColor = UIColor.blue;
 
        button.backgroundColor = UIColor.gray;
        button.setTitle("Show Notification", for: UIControlState());
        button.setTitleColor(UIColor.black, for: .highlighted);
       
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
        
        
        let verticalLayout = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[spacer]-[button(buttonHeight)]-[spacer2(==spacer)]-|", options: .alignAllLeft, metrics: metrics, views: views);
        self.view.addConstraints(verticalLayout);
        
        let hLayout = NSLayoutConstraint.constraints(withVisualFormat: "|-hPadding-[button]-hPadding-|", options: .alignAllCenterX, metrics: metrics, views: views);
        self.view.addConstraints(hLayout);
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func presentNotification() {

        print("present notifcation");
        let image = ViewController.imageFromText("🐼",font:UIFont.systemFont(ofSize: 60), maxWidth: 40.0, color: UIColor.blue);
        let notif = JTNotificationView(text: "Steve Holm Assigned the lead Brian Crushing to you. \(count)", icon:image) {
            print("done.");
            self.count += 1
        };
        notificationManager.show(notif, animated: true);
    }
   
    class func sizeOfAttributeString(_ str: NSAttributedString, maxWidth: CGFloat) -> CGSize {
        let size = str.boundingRect(with: CGSize(width: maxWidth, height: 1000), options:(NSStringDrawingOptions.usesLineFragmentOrigin), context:nil).size
        return size
    }
    
    class func imageFromText(_ text:String, font:UIFont, maxWidth:CGFloat, color:UIColor) -> UIImage {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraph.alignment = .center // potentially this can be an input param too, but i guess in most use cases we want center align
        
        let attributedString = NSAttributedString(string: text, attributes: [NSFontAttributeName: font, NSForegroundColorAttributeName: color, NSParagraphStyleAttributeName:paragraph])
        
        let size = sizeOfAttributeString(attributedString, maxWidth: maxWidth)
        UIGraphicsBeginImageContextWithOptions(size, false , 0.0)
        attributedString.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}
