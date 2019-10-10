//
//  FFVideoPlayer.swift
//  FFPlayerSwift
//
//  Created by 曹诚飞 on 2019/9/18.
//  Copyright © 2019 曹诚飞. All rights reserved.
//

import UIKit
import AVFoundation

/// player填充模式
///
/// - gravityResize 非均匀模式。两个维度完全填充至整个视图区域
/// - resizeAspect 等比例填充，直到一个维度到达区域边界
/// - resizeAspectFill: 等比例填充，填充满整个视图区域，其中一个维度的部分区域会被裁剪

enum FFPlayerLayerGravity {
    case gravityResize
    case resizeAspect
    case resizeAspectFill
}

/// 播放器状态
///
/// - buffering: 缓冲
/// - playing: 播放中
/// - stopped: 停止
/// - pause: 暂停
private enum FFPlayerStatus {
    case buffering
    case playing
    case stopped
    case pause
}

class FFVideoPlayer: UIView {
    /// 控制层视图
    public var commandView: FFPlayerCommandView?;
    /// 竖屏坐标
    private var originRect:CGRect?;
    /// 视频连接 public videoURL
    private var _videoURL:NSURL?;
    /// 播放器
    private var player: AVPlayer?;
    /// 播放器的item
    private var playerItem: AVPlayerItem?;
    /// 播放器的layer
    private var playerlayer: AVPlayerLayer?;
    /// 控制交互视图的计时器
    private var autoTimer: Timer?;
    /// 监听播放进度
    private var playerTimeObserver: Any?;
    /// 是否正在交互
    private var isInterAction: Bool = false;
    /// 滑动时间
    private var sumTime: Double = 0;
    /// 手势滑动方向
    private var isHorizontalMove: Bool = false;
    /// 总时长
    private var totalDuration: Double = 0;
    /// 是否用户主动暂停
    private var isPauseByUser: Bool = false;
    /// 播放器状态
    private var playerStatus: FFPlayerStatus = .stopped;
    /// 记录最后slider或手势的滑动值，判断当前是向左还是向右滑动
    private var sliderLastValue : Float = 0;
    
    /// 初始化
    public override init(frame: CGRect) {
        super.init(frame: frame);
        initialize();
    }
    
    /// 初始化
    public init(tableView: UITableView) {
        super.init(frame: CGRect.zero);
        initialize();
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self);
        removeTimer();
    }
    
    public var videoURL:URL? {
        set {
            _videoURL = newValue as NSURL?;
            resetPlayer();
            
            setNeedsLayout();
            onDeviceOrientaitionChange();
            layoutIfNeeded();
            
            if let url = newValue as NSURL? {
                playerItem = AVPlayerItem.init(url: url as URL);
                player?.replaceCurrentItem(with: playerItem);
                addNotification();
                addKVO();
                startToPlayer();
            }
        }
        get {
            return _videoURL as URL?;
        }
    }
    
    func setGravity(gravity: FFPlayerLayerGravity) {
        switch gravity {
        case .gravityResize:
            playerlayer?.videoGravity = AVLayerVideoGravity.resize;
            
        case .resizeAspectFill:
            playerlayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill;
            
        default:
            playerlayer?.videoGravity = AVLayerVideoGravity.resizeAspect;
        }
    }
}

//MARK: - 初始化
extension FFVideoPlayer {
    func initialize() {
        commandView = FFPlayerCommandView.init(frame: self.bounds);
        commandView!.backgroundColor = UIColor.clear;
        commandView!.delegate = self;
        addSubview(commandView!);
        
        self.sumTime = 0;

        player = AVPlayer.init();
        
        playerlayer = AVPlayerLayer.init(player: player);
        playerlayer!.frame = self.bounds;
        playerlayer!.backgroundColor = UIColor.init(white: 0, alpha: 1).cgColor;
        playerlayer!.videoGravity = AVLayerVideoGravity.resizeAspect;
        self.layer.insertSublayer(playerlayer!, at: 0);
        
        // 设置竖屏的坐标
        if  UIScreen.main.bounds.width < UIScreen.main.bounds.height{
            // 竖屏
            self.originRect = self.frame;
        } else {
            self.originRect = self.frame;
            let x = self.frame.origin.x;
            let y = self.frame.origin.y;
            let w = min(self.frame.width, self.frame.height);
            let h = max(self.frame.width, self.frame.height);
            let scale = h / w;
            self.originRect = CGRect.init(x: x, y: y, width: w, height: w / scale);
        }
    }
}

//MARK: - KVO
extension FFVideoPlayer {
    private func addKVO() {
        playerItem?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil);
        playerItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil);
        playerItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: NSKeyValueObservingOptions.new, context: nil);
        playerItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: NSKeyValueObservingOptions.new, context: nil);
    }
    
    private func removeKVO() {
        playerItem?.removeObserver(self, forKeyPath: "status");
        playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges");
        playerItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty");
        playerItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp");
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let playerItem = object as? AVPlayerItem else {
            return;
        }
        if keyPath == "status" {
            if playerItem.status == .readyToPlay {
                // 准备播放
                preparePlay();
            } else {
                // 初始化失败
                playerStatus = .stopped;
            }
            
        } else if keyPath == "loadedTimeRanges" {
            commandView?.progress.setProgress(Float(availableDuration() / CMTimeGetSeconds(playerItem.duration)), animated: false);
            if playerItem.isPlaybackLikelyToKeepUp {
                commandView?.activity.stopAnimating();
            }
        } else if keyPath == "playbackBufferEmpty" {
            playerStatus = .buffering;
            commandView?.activity.startAnimating();
            player?.pause();
        } else if keyPath == "playbackLikelyToKeepUp" {
            commandView?.activity.startAnimating();
            if isPauseByUser == false {
                player?.play();
                commandView?.playBtn.isSelected = true;
            }
        }
    };
    
    private func availableDuration() -> TimeInterval {
        let loadedTimeRanges = player?.currentItem?.loadedTimeRanges;
        let value = loadedTimeRanges?.first;
        let timeRange = value?.timeRangeValue;
        let startSeconds = CMTimeGetSeconds(timeRange?.start ?? CMTime.init());
        let duratSeconds = CMTimeGetSeconds(timeRange?.duration ?? CMTime.init());
        return startSeconds + duratSeconds;
    }
}

//MARK: - Notification
extension FFVideoPlayer {
    private func addNotification() {
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: OperationQueue.main) { (noti) in
            self.onDeviceOrientaitionChange();
        };
        
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: OperationQueue.main) { (noti) in
            self.playerStatus = .pause;
            self.pauseToPlayer();
        };
        
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: OperationQueue.main) { (noti) in
            if self.playerStatus == .pause {
                self.playerStatus = .playing;
                self.startToPlayer();
            }
        };
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem, queue: OperationQueue.main) { (noti) in
            self.playerStatus = .stopped;
            self.commandView?.replayBtn.isHidden = false;
            self.removeTimer();
            
            self.commandView?.bottomView.alpha = 0;
            self.commandView?.replayBtn.isHidden = false;
            self.commandView?.activity.stopAnimating();
        };
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemPlaybackStalled, object: playerItem, queue: OperationQueue.main) { (noti) in
            self.pauseToPlayer();
        };
    }
    
    private func removeNotification() {
        NotificationCenter.default.removeObserver(self);
    }
    
    private func onDeviceOrientaitionChange() {
        let orientation = UIDevice.current.orientation;
        let interfaceOrientation = UIInterfaceOrientation.init(rawValue: orientation.rawValue);
        switch interfaceOrientation {
        case UIInterfaceOrientation.portrait?:
            autoRotateToProtrait();
            
        case UIInterfaceOrientation.landscapeLeft?:
            autoRotateToLandscapeLeft(isLeft: true);
            
        case UIInterfaceOrientation.landscapeRight?:
            autoRotateToLandscapeLeft(isLeft: false);

        default:
            break;
        }
    }
    
    private func autoRotateToLandscapeLeft(isLeft: Bool) {
        let window = UIApplication.shared.keyWindow;
        
        UIView.animate(withDuration: 0, animations: {
            self.frame = window!.frame;
            self.playerlayer?.frame = self.bounds;
            self.commandView?.frame = self.bounds;
            self.commandView?.layoutSubviews();
            
        }) { (finished) in
            self.commandView?.screenBtn.isSelected = true;
            UIApplication.shared.isStatusBarHidden = true;
        };
    }
    private func autoRotateToProtrait() {
        UIView.animate(withDuration: 0, animations: {
            self.frame = self.originRect ?? CGRect.zero;
            self.playerlayer?.frame = self.bounds;
            self.commandView?.frame = self.bounds;
            self.commandView?.layoutSubviews();
            
        }) { (finished) in
            self.commandView?.screenBtn.isSelected = false;
            UIApplication.shared.isStatusBarHidden = false;
        };
    }
    
    private func setInterfaceOrientation(orientation: UIInterfaceOrientation) {
        UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
    }
}

//MARK: - Timer
extension FFVideoPlayer {
    private func addTimer() {
        
        playerTimeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime.init(value: 1, timescale: 1), queue: DispatchQueue.main, using: { [weak self] (time) in
            guard let strongSelf = self else {
                return;
            }
            if strongSelf.isInterAction == false {
                let currentDuration = CMTimeGetSeconds(time);
                let currentText = strongSelf.changeTimeFormat(timeValue: currentDuration);
                let totalText = strongSelf.changeTimeFormat(timeValue: strongSelf.totalDuration);
                
                strongSelf.commandView?.currentTimeLabel.text = currentText + " / " + totalText;
                strongSelf.commandView?.slider.setValue(Float(currentDuration / strongSelf.totalDuration), animated: false);
            }
        });
        
        autoTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { [weak self] (timer) in
            if self?.isInterAction == false {
                self?.commandView?.hide();
            }
        });
    }
    
    private func changeTimeFormat(timeValue: Float64) -> String {
        var string = "";
        let time = Int(timeValue);
        if time < 3600 {
            let minutes = time / 60;
            let seconds = time % 60;
            string = String(format: "%02d:%02d", arguments: [minutes,seconds]);
        } else {
            string = String(format: "%2d:%2d:%2d", [time / 3600, time / 3600 / 60, (time / 3600 / 60) % 60]);
        }
        return string;
    }
    
    private func removeTimer() {
        if let timer = autoTimer {
            timer.invalidate();
        }
        
        if let timerObserver = playerTimeObserver {
            player?.removeTimeObserver(timerObserver);
            playerTimeObserver = nil;
        }
        
    }
}

//MARK: - FFPlayerCommandViewDelegate
extension FFVideoPlayer:FFPlayerCommandViewDelegate {
    func commandViewPlayAction(isPlay: Bool) {
        if isPlay {
            isPauseByUser = false;
            startToPlayer();
        } else {
            isPauseByUser = true;
            pauseToPlayer();
        }
    }
    
    func commandViewSliderAction(value: Int) {
        sliderValueChange();
    }
    
    func commandViewSliderDidChanged(value: Int) {
        sliderDidChanged();
    }
    
    func commandViewFullAction(btn: UIButton) {
        fullScreenPlayer();
    }
    
    func commandViewGestureAction(status: Int) {
        if status == 1 {
            tapSignel();
        } else {
            tapDouble();
        }
    }
    
    func commandViewPanAction(gesture: UIPanGestureRecognizer) {
        panChangePlayerTime(pan: gesture);
    }
    
    func commandViewReplayAction() {
        replayBack();
    }
    
    func commandViewBackAction() {
        backAction();
    }
}

//MARK: - HandleAction
extension FFVideoPlayer {
    
    /// 开始播放
    public func startToPlayer() {
        addTimer();
        if videoURL?.scheme == "file" {
            playerStatus = .playing;
        } else {
            playerStatus = .buffering;
        }
        commandView?.playBtn.isSelected = true;
        player?.play();
    }
    
    /// 暂停播放
    public func pauseToPlayer() {
        removeTimer();
        commandView?.playBtn.isSelected = false;
        commandView?.activity.stopAnimating();
        playerStatus = .pause;
        player?.pause();
    }
    
    /// 准备播放
    public func preparePlay() {
        commandView?.replayBtn.isHidden = true;
        totalDuration = CMTimeGetSeconds(playerItem!.duration);
        commandView?.currentTimeLabel.text = "00:00" + " / " + changeTimeFormat(timeValue: totalDuration);
        if isPauseByUser == false {
            startToPlayer();
        }
    }
    
    /// 重新播放
    public func replayBack() {
        commandView?.progress.progress = 0;
        commandView?.slider.value = 0;
        commandView?.replayBtn.isHidden = true;
        if player?.status == AVPlayer.Status.readyToPlay {
            sliderDidChanged();
            startToPlayer();
            commandView?.show();
        } else {
            videoURL = _videoURL as URL?;
        }
    }
    
    /// 重置
    public func resetPlayer() {
        removeNotification();
        pauseToPlayer();
        playerItem = nil;
        player?.replaceCurrentItem(with: nil);
        
        commandView?.progress.progress = 0;
        commandView?.slider.value = 0;
        commandView?.replayBtn.isHidden = true;
        
        totalDuration = 0;
    }
    
    /// 销毁
    public func destroyPlayer() {
        resetPlayer();
        removeFromSuperview();
    }
    
    /// 进度条拖动中
    private func sliderValueChange()  {
        isInterAction = true;
        removeTimer();
        if playerItem?.duration.timescale != 0 {
            let sliderDuration = Float(totalDuration) * (commandView?.slider.value)!;
            let currentText = changeTimeFormat(timeValue: Float64(sliderDuration));
            let totalText = changeTimeFormat(timeValue: Float64(totalDuration));
            commandView?.currentTimeLabel.text = currentText + " / " + totalText;
            
            let value = (self.commandView?.slider.value)! - self.sliderLastValue;
            let style = value > 0 ? ">>" : "<<";
            sliderLastValue = (self.commandView?.slider.value)!;
            
            commandView?.forwardOrBackward.isHidden = false;
            commandView?.forwardOrBackward.text = style + " " + currentText + " / " + totalText;
        }
    }
    
    /// 进度条拖动结束
    private func sliderDidChanged() {
        var isPlaying: Bool = false;
        if player!.rate > Float(0) {
            isPlaying = true;
            player?.pause();
        }
        
        commandView?.forwardOrBackward.isHidden = true;
        isInterAction = false;
        
        if player?.status == AVPlayer.Status.readyToPlay {
            let dragedSeconds = floorf(Float(totalDuration) * (commandView?.slider.value)!);
            let dragedCMTime = CMTimeMake(value: Int64(dragedSeconds), timescale: 1);
            player?.seek(to: dragedCMTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero, completionHandler: {[weak self] (finished) in
                if isPlaying {
                    self?.startToPlayer();
                }
            });
        }
        
    }
    
    /// 全屏按钮
    private func fullScreenPlayer() {
        if UIDevice.current.orientation.isPortrait {
            setInterfaceOrientation(orientation: UIInterfaceOrientation.landscapeRight);
        } else {
            setInterfaceOrientation(orientation: UIInterfaceOrientation.portrait);
        }
    }

    /// 返回按钮
    private func backAction() {
        if self.commandView?.screenBtn.isSelected == true {
            setInterfaceOrientation(orientation: UIInterfaceOrientation.portrait);
        } else {
            resetPlayer();
            removeKVO();
            if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
                if rootVC.isKind(of: UINavigationController.self) {
                    let navi = rootVC as! UINavigationController;
                    navi.popViewController(animated: true);
                } else {
                    rootVC.dismiss(animated: true, completion: nil);
                }
            }
        }
    }
    
    /// 滑动手势
    private func panChangePlayerTime(pan: UIPanGestureRecognizer) {
        if UIDevice.current.orientation == UIDeviceOrientation.portrait {
            return;
        }
        let localPoint = pan.location(in: self);
        // 在指定视图的坐标系中，以点/秒为单位的平移速度（速率点）
        let velocityPoint = pan.velocity(in: self);
        switch pan.state {
        case UIGestureRecognizer.State.began:
            // 使用绝对值得出pan是水平还是垂直方向
            let x = fabsf(Float(velocityPoint.x));
            let y = fabsf(Float(velocityPoint.y));
            
            if x > y {
                // 水平方向
                if playerStatus != .stopped {
                    sumTime = (player?.currentTime().seconds)!;
                    
                }
                isHorizontalMove = true;
                commandView?.forwardOrBackward.isHidden = false;
            }
            
        case UIGestureRecognizer.State.changed:
            if isHorizontalMove == true {
                sumTime = sumTime + Double(velocityPoint.x / 200);
                if sumTime > totalDuration {
                    sumTime = totalDuration;
                } else if sumTime < 0 {
                    sumTime = 0;
                }
                commandView?.slider.value = Float(sumTime / totalDuration);
                sliderValueChange()
            } else {
                if localPoint.x < UIScreen.main.bounds.size.height * 0.5 {
                    UIScreen.main.brightness = UIScreen.main.brightness - velocityPoint.y / 10000;
                } else {
                    commandView?.volumnSlider.value = (commandView?.volumnSlider.value)! - Float(velocityPoint.y) / 10000;
                }
            }
        
        case UIGestureRecognizer.State.ended:
            if isHorizontalMove == true {
                sumTime = 0;
                sliderDidChanged();
            }
        default:
            break;
        }
    }
    
    /// 单击手势
    private func tapSignel() {
        //TODO: 单击手势额外操作
    }
    
    /// 双击手势
    private func tapDouble() {
        //TODO: 双击手势额外操作
    }
}

