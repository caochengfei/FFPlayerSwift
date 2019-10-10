//
//  ViewController.swift
//  FFPlayerSwift
//
//  Created by 曹诚飞 on 2019/9/18.
//  Copyright © 2019 曹诚飞. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let url = URL.init(string: "https://douyin2018.oss-cn-shenzhen.aliyuncs.com/d9f94541f5c85847e51416754589e11e.mp4");
        let width = view.bounds.width;
        let player = FFVideoPlayer.init(frame: CGRect.init(x: 0, y: 0, width: width, height: width * 0.6));
        player.videoURL = url;
        view.addSubview(player);
    }
    
    func weak(object :NSObject) -> Void {
        
    }


}

