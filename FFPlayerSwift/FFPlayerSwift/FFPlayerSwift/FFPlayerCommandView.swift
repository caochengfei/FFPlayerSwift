//
//  FFPlayerCommandView.swift
//  FFPlayerSwift
//
//  Created by 曹诚飞 on 2019/9/18.
//  Copyright © 2019 曹诚飞. All rights reserved.
//

import UIKit
import MediaPlayer

protocol FFPlayerCommandViewDelegate {
    func commandViewPlayAction(isPlay: Bool);
    func commandViewSliderAction(value: Int);
    func commandViewSliderDidChanged(value: Int);
    func commandViewFullAction(btn: UIButton);
    func commandViewGestureAction(status: Int);
    func commandViewPanAction(gesture: UIPanGestureRecognizer);
    func commandViewReplayAction();
    func commandViewBackAction();
}

class FFPlayerCommandView: UIView {
    var delegate: FFPlayerCommandViewDelegate?
    /// 顶部操作栏
    var topView = UIView();
    /// 底部操作栏
    var bottomView = UIView();
    /// 播放进度
    var progress = UIProgressView();
    /// 拖拽进度
    var slider = UISlider();
    /// 当前播放时间
    var currentTimeLabel = UILabel();
    /// 播放按钮
    var playBtn = UIButton();
    /// 全屏按钮
    var screenBtn = UIButton();
    /// 重新播放按钮
    var replayBtn = UIButton();
    /// 后退按钮
    var backBtn = UIButton();
    /// 音量slider
    var volumnSlider = UISlider();
    /// 快进快退用
    var forwardOrBackward = UILabel();
    /// loding
    var activity = UIActivityIndicatorView();
    /// 点击手势
    var tapGesture = UITapGestureRecognizer();
    /// 双击手势
    var doubleTapGesture = UITapGestureRecognizer();
    /// 滑动手势
    var panGesture = UIPanGestureRecognizer();
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        // 设置UI
        setupUI();
        
        topView.addSubview(backBtn);
        self.addSubview(topView);
        
        bottomView.addSubview(playBtn);
        bottomView.addSubview(progress);
        bottomView.addSubview(slider);
        bottomView.addSubview(currentTimeLabel);
        bottomView.addSubview(screenBtn);
        self.addSubview(bottomView);
        
        self.addSubview(replayBtn);
        self.addSubview(forwardOrBackward);
        self.addSubview(activity);
        
        self.addGestureRecognizer(tapGesture);
        self.addGestureRecognizer(doubleTapGesture);
        self.addGestureRecognizer(panGesture);
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews();
        let orientation = UIDevice.current.orientation;
        let interfaceOrientation = UIInterfaceOrientation.init(rawValue: orientation.rawValue);
        switch interfaceOrientation {
        case UIInterfaceOrientation.portrait?:
            portraitLayout();
        case UIInterfaceOrientation.landscapeLeft?:
            landscapeLayout();
        case UIInterfaceOrientation.landscapeRight?:
            landscapeLayout();
        default:
            portraitLayout();
        }
    }
}

//MARK: - KVO
extension FFPlayerCommandView {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        changeCurrentTimeLabelLayout();
    }
}

//MARK: - handleAction
extension FFPlayerCommandView {
    @objc func playBtnAction(btn: UIButton) {
        btn.isSelected = !btn.isSelected;
        self.delegate?.commandViewPlayAction(isPlay: btn.isSelected);
    }
    
    @objc func sliderProgressChange(slider: UISlider) {
        self.delegate?.commandViewSliderAction(value: Int(slider.value));
    }
    
    @objc func sliderDidChanged(slider: UISlider) {
        self.delegate?.commandViewSliderDidChanged(value: Int(slider.value));
    }
    
    @objc func replayBtnAction(btn: UIButton) {
        self.delegate?.commandViewReplayAction();
    }
    
    @objc func screenBtnAction(btn: UIButton) {
        self.delegate?.commandViewFullAction(btn: btn);
    }
    
    @objc func backBtnAcction(btn: UIButton) {
        self.delegate?.commandViewBackAction();
    }
}

//MARK: - 手势
extension FFPlayerCommandView : UIGestureRecognizerDelegate {
    @objc func tapAction(tap:UITapGestureRecognizer) {
        if tap.numberOfTapsRequired == 1 {
            self.delegate?.commandViewGestureAction(status: 1);
            self.topView.alpha == 0 ? show() : hide();

        }
        if tap.numberOfTapsRequired == 2 {
            self.delegate?.commandViewGestureAction(status: 2);
            self.playBtnAction(btn: self.playBtn);
            if self.playBtn.isSelected == false {
                show();
            }
        }
    }
    
    @objc func panAction(pan:UIPanGestureRecognizer)  {
        self.delegate?.commandViewPanAction(gesture: pan);
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let point = touch.location(in: self);
        if point.y > bottomView.frame.origin.y {
            return false;
        }
        return true;
    }
}

//MARK: - 显示隐藏
extension FFPlayerCommandView {
    func show() {
        UIView.animate(withDuration: 0.3) {
            self.topView.alpha = 1;
            self.bottomView.alpha = 1;
        };
    }
    
    func hide() {
        UIView.animate(withDuration: 0.3) {
            self.topView.alpha = 0;
            self.bottomView.alpha = 0;
        };
    }
}

//MARK: - layout
extension FFPlayerCommandView {
    func changeCurrentTimeLabelLayout() {
        currentTimeLabel.sizeToFit();
        let labelW = currentTimeLabel.bounds.size.width;
        currentTimeLabel.frame = CGRect.init(x: screenBtn.frame.origin.x - labelW , y: 10, width: labelW, height: 20);
        
        let sliderW = self.frame.size.width - playBtn.frame.maxX - currentTimeLabel.frame.size.width - screenBtn.frame.size.width - 10 - 15;
        progress.frame = CGRect.init(x: playBtn.frame.maxX + 5, y: 19, width: sliderW, height: 10);
        slider.frame = CGRect.init(x:progress.frame.origin.x - 2, y: 0, width: progress.bounds.size.width + 4 ,height: bottomView.frame.size.height - 10);
    }
    
    func portraitLayout() {
        self.topView.frame = CGRect.init(x: 0, y: 0, width: self.frame.size.width, height: 50);
        self.backBtn.frame = CGRect.init(x: 5, y: 0, width: 50, height: 50);
        
        let bottomH:CGFloat = 50;
        bottomView.frame = CGRect.init(x: 0, y: self.frame.size.height - bottomH, width: self.frame.size.width, height: bottomH);
        playBtn.frame = CGRect.init(x: 5, y: 0, width: 40, height: 40);
        screenBtn.frame = CGRect.init(x: self.frame.size.width - 45, y: 0, width: 40, height: 40);
        changeCurrentTimeLabelLayout();
        
        replayBtn.frame = CGRect.init(x: 0, y: 0, width: 40, height: 40);
        replayBtn.center = CGPoint.init(x: self.frame.size.width / 2, y: self.frame.size.height / 2);
        
        forwardOrBackward.frame = CGRect.init(x: 0, y: 0, width: 160, height: 40);
        forwardOrBackward.center = replayBtn.center;
        FFBrightnessView.shareInstance.center = UIApplication.shared.keyWindow?.center ?? CGPoint.init(x: 0, y: 0);
    }
    
    func landscapeLayout() {
        topView.frame = CGRect.init(x: 0, y: 0, width: self.frame.size.width, height: 40);
        backBtn.frame = CGRect.init(x: 5, y: 0, width: 40, height: 40);
        
        let bottomH:CGFloat = 50;
        bottomView.frame = CGRect.init(x: 0, y: self.frame.size.height - bottomH, width: self.frame.size.width, height: bottomH);
        playBtn.frame = CGRect.init(x: 10, y: 0, width: 40, height: 40);
        screenBtn.frame = CGRect.init(x: self.frame.size.width - 50, y: 0, width: 40, height: 40);
        changeCurrentTimeLabelLayout();
        
        replayBtn.frame = CGRect.init(x: 0, y: 0, width: 40, height: 40);
        replayBtn.center = CGPoint.init(x: self.frame.size.width / 2, y: self.frame.size.height / 2);
        
        forwardOrBackward.frame = CGRect.init(x: 0, y: 0, width: 160, height: 40);
        forwardOrBackward.center = replayBtn.center;
        FFBrightnessView.shareInstance.center = UIApplication.shared.keyWindow?.center ?? CGPoint.init(x: 0, y: 0);
    }
}

//MARK: - UI
extension FFPlayerCommandView {
    func setupUI() {
        topView.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.3);
        
        bottomView.backgroundColor = topView.backgroundColor;
        
        playBtn.setImage(UIImage.init(named: "play_play"), for: UIControl.State.normal);
        playBtn.setImage(UIImage.init(named: "play_pause"), for: UIControl.State.selected);
        playBtn.setImage(UIImage.init(named: "play_pause"), for: UIControl.State.highlighted);
        playBtn.imageEdgeInsets = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10);
        playBtn.adjustsImageWhenHighlighted = false;
        playBtn.addTarget(self, action: #selector(playBtnAction(btn:)), for: UIControl.Event.touchUpInside);
        
        progress.trackTintColor = UIColor.darkGray;
        progress.progressTintColor = UIColor.gray;
        
        slider.setThumbImage(UIImage.init(named: "play_slider"), for: UIControl.State.normal);
        slider.maximumTrackTintColor = UIColor.clear;
        slider.addTarget(self, action: #selector(sliderProgressChange(slider:)), for: UIControl.Event.valueChanged);
        slider.addTarget(self, action: #selector(sliderDidChanged(slider:)), for: UIControl.Event.touchUpInside);
        slider.addTarget(self, action: #selector(sliderDidChanged(slider:)), for: UIControl.Event.touchUpOutside);
        slider.addTarget(self, action: #selector(sliderDidChanged(slider:)), for: UIControl.Event.touchCancel);
        
        currentTimeLabel.text = "00:00 / 00:00";
        currentTimeLabel.textColor = UIColor.white;
        currentTimeLabel.font = UIFont.systemFont(ofSize: 12);
        currentTimeLabel.addObserver(self, forKeyPath: "text", options: NSKeyValueObservingOptions.new, context: nil);
        
        screenBtn.setImage(UIImage.init(named: "play_full_screen"), for: UIControl.State.normal);
        screenBtn.setImage(UIImage.init(named: "play_full_screen"), for: UIControl.State.selected);
        screenBtn.adjustsImageWhenHighlighted = false;
        screenBtn.imageEdgeInsets = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10);
        screenBtn.addTarget(self, action: #selector(screenBtnAction(btn:)), for: UIControl.Event.touchUpInside);
        
        replayBtn.setImage(UIImage.init(named: "play_replay"), for: UIControl.State.normal);
        replayBtn.adjustsImageWhenHighlighted = false;
        replayBtn.isHidden = true;
        replayBtn.addTarget(self, action: #selector(replayBtnAction(btn:)), for: UIControl.Event.touchUpInside);
        
        backBtn.setImage(UIImage.init(named: "play_back"), for: UIControl.State.normal);
        backBtn.adjustsImageWhenHighlighted = false;
        backBtn.imageEdgeInsets = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10);
        backBtn.addTarget(self, action: #selector(backBtnAcction(btn:)), for: UIControl.Event.touchUpInside);
        
        tapGesture.addTarget(self, action: #selector(tapAction(tap:)));
        tapGesture.numberOfTapsRequired = 1;
        tapGesture.numberOfTouchesRequired = 1;
        tapGesture.require(toFail: doubleTapGesture);
        
        panGesture.addTarget(self, action: #selector(panAction(pan:)));
        panGesture.maximumNumberOfTouches = 1;
        panGesture.minimumNumberOfTouches = 1;
        panGesture.delegate = self;
        
        doubleTapGesture.addTarget(self, action: #selector(tapAction(tap:)));
        doubleTapGesture.numberOfTapsRequired = 2;
        
        forwardOrBackward.textColor = UIColor.white;
        forwardOrBackward.textAlignment = NSTextAlignment.center;
        forwardOrBackward.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.5);
        forwardOrBackward.isHidden = true;
        
        activity.style = UIActivityIndicatorView.Style.whiteLarge;
        
        let volumeView = MPVolumeView.init();
        for view in volumeView.subviews {
            if view.description == "MPVolumeSlider" {
                volumnSlider = view as! UISlider;
                break;
            }
        }
    }
}
