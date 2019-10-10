//
//  FFBrightnessView.swift
//  FFPlayerSwift
//
//  Created by 曹诚飞 on 2019/9/18.
//  Copyright © 2019 曹诚飞. All rights reserved.
//

import UIKit

class FFBrightnessView: UIView {
    // 创建单例
    static let shareInstance = FFBrightnessView();
    
    var timer: Timer?;

    private init() {
        super.init(frame: CGRect.zero)
        let appWindow = UIApplication.shared.keyWindow;
        appWindow?.addSubview(FFBrightnessView.shareInstance);
        self.frame = CGRect.init(x: UIScreen.main.bounds.width * 0.5, y: UIScreen.main.bounds.height * 0.5, width: 155, height: 155);
        self.layer.cornerRadius = 10;
        self.layer.masksToBounds = true;
        self.backgroundColor = UIColor.white;
        self.alpha = 0;
        
        self.addSubview(self.backImage);
        self.addSubview(self.titleLabel);
        self.addSubview(self.elementBgView);
        
        UIScreen.main.addObserver(self, forKeyPath: "brightness", options: NSKeyValueObservingOptions.new, context: nil);
    };
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // 懒加载属性
    lazy var backImage: UIImageView = {
        let imageView = UIImageView(frame: CGRect.init(x: 0, y: 0, width: 79, height: 76));
        imageView.center = CGPoint.init(x: 155 * 0.5, y: 155 * 0.5);
        imageView.image = UIImage.init(named: "playgesture_BrightnessSun");
        return imageView;
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel.init(frame: CGRect.init(x: 0, y: 5, width: UIScreen.main.bounds.width, height: 30));
        label.font = UIFont.systemFont(ofSize: 16);
        label.textColor = UIColor.init(red: 0.25, green: 0.22, blue: 0.21, alpha: 1);
        label.textAlignment = NSTextAlignment.center;
        label.text = "亮度";
        return label;
    }()
    
    lazy var elementBgView: UIView = {
        let view = UIView.init(frame: CGRect.init(x: 13, y: 132, width: UIScreen.main.bounds.width - 26, height: 7));
        view.backgroundColor = UIColor.init(red: 0.25, green: 0.22, blue: 0.21, alpha: 1);
        return view;
    }()
    
    lazy var elementArray: Array = { [weak self] () -> [UIImageView] in
        var array = Array<UIImageView>();
        let W = Int((self!.elementBgView.bounds.size.width - 17) / 16);
        let H = 5;
        let Y = 1;
        
        for index in 0..<16 {
            let X = index * (Int(W) + 1) + 1;
            var imageView = UIImageView();
            imageView.backgroundColor = UIColor.white;
            imageView.frame = CGRect.init(x: X, y: Y, width: W, height: H);
            self!.elementBgView.addSubview(imageView);
            array.append(imageView);
        }
        
        return array
    }()
}

// func
extension FFBrightnessView {
    
    func addTimer() {
        guard self.timer == nil else {
            return;
        };
        self.timer = Timer.init(timeInterval: 3, repeats: true, block: {[weak self] (timer) in
            if self?.alpha == 1 {
                UIView.animate(withDuration: 0.8, animations: {
                    self?.alpha = 0;
                });
            }
        });
        RunLoop.current.add(self.timer!, forMode: RunLoop.Mode.common);
    }
    
    func removeTimer() {
        self.timer?.invalidate();
    }
    
    func updateTimer() {
        self.removeTimer();
        self.addTimer();
    }
    
    func updateElementProgress(value: Double) {
        let stage = 1.0 / Double((self.elementArray.count - 1));
        let level = value / stage;
        
        var index = 0;
        for imageView in self.elementArray {
            if index <= Int(level) {
                imageView.isHidden = false;
            } else {
                imageView.isHidden = true;
            }
            index += 1;
        }
    }
}

// kvo
extension FFBrightnessView {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let value = change?[NSKeyValueChangeKey.newKey];
        if (self.alpha == 0.0) {
            self.alpha = 1.0;
            
        }
        self.updateTimer();
        guard let doubleValue = value as! Double? else {
            return;
        }
        self.updateElementProgress(value: doubleValue);
    }
}

// copyWithZone
extension FFBrightnessView : NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        return FFBrightnessView.shareInstance;
    }
}


